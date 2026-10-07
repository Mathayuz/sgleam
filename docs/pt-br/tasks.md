# Task como descrição pura e executor fake

## 1. Objetivo e correção da implementação anterior

O programa descreve os efeitos que deseja solicitar. O ambiente interpreta
essas descrições. Nesta versão existe somente um interpretador **fake**, que
responde a pedidos conhecidos com valores predefinidos e devolve um histórico.
Ele não acessa rede, não grava arquivos e não imprime mensagens.

A versão anterior usava `Task(a) = fn() -> a` e colocava chamadas reais de I/O
dentro dessas funções. Isso apenas adiava os efeitos. Essa representação foi
substituída por dados que representam pedidos e suas continuações.
As funções Rust de GET/gravação, seus registros no QuickJS, a ponte FFI dessas
operações e a dependência direta de reqwest foram removidos.

A semelhança com `Cmd` de Elm está na separação entre descrição e interpretação.
Esta API não é uma reprodução de `Cmd`: uma `Task(a)` descreve uma sequência que
produz `a`, com dependências expressas por continuações, e o fake a interpreta
sincronamente. Não existe agendador, concorrência ou executor real nesta versão.

## 2. Representação de Task

Arquivo: [task.gleam](../../lib/sgleam/task.gleam).

```gleam
pub type Task(a) {
  Done(value: a)
  Get(url: String, next: fn(Result(String, String)) -> Task(a))
  WriteFile(path: String, content: String, next: fn(Result(Nil, String)) -> Task(a))
  Println(message: String, next: fn(Nil) -> Task(a))
}
```

É um tipo nominal com quatro variantes. Uma tarefa não é mais uma função
executável: é um valor que pode ser inspecionado pelo interpretador usando `case`.
Os construtores são públicos para permitir interpretadores separados em Gleam.
Nenhuma variante contém uma função de I/O fornecida pela biblioteca.

| Variante | Significado |
| --- | --- |
| `Done(valor)` | A computação terminou com esse valor. |
| `Get(url, next)` | Pedido de consulta; next descreve como continuar com a resposta. |
| `WriteFile(path, content, next)` | Pedido de gravação; não abre nem modifica arquivo. |
| `Println(message, next)` | Pedido de impressão; não chama gleam/io. |

As continuações são funções da lógica do programa. Elas recebem respostas e
produzem as próximas descrições. Isso permite que o conteúdo de um pedido de
gravação dependa da resposta de um GET sem fazer a consulta durante a construção.

## 3. Funções públicas e use

`done(value)` constrói `Done(value)`. `get`, `write_file` e `println` constroem
suas variantes correspondentes. Não há `task.run` nem funções externas no módulo.

```gleam
use resposta <- task.get(url)
case resposta {
  Ok(texto) -> task.done(texto)
  Error(_) -> task.done("Falha")
}
```

O trecho pressupõe o import de task e uma variável url. O `use` passa o restante
do bloco como último argumento, sendo equivalente a:

```gleam
task.get(url, fn(resposta) {
  case resposta {
    Ok(texto) -> task.done(texto)
    Error(_) -> task.done("Falha")
  }
})
```

Construir esse valor não avalia a continuação. O fake a chama somente após
localizar uma resposta configurada para o pedido.

Todos os ramos devem retornar `Task(a)` do mesmo tipo de resultado. Por isso,
o exemplo termina cada ramo com `task.done(0)` ou `task.done(1)`.
`done` não executa pedidos, não encerra o processo e não altera seu exit status.
Se um argumento de `done` for uma expressão, ela é avaliada normalmente antes
da construção de `Done`; `done` não transforma funções impuras em puras.

### Composição com then

`then(first, next)` percorre a descrição para conectar a conclusão da primeira
computação à próxima. Em `Done(value)`, devolve `next(value)`. Nos outros casos,
reconstrói o mesmo pedido com uma continuação que faz essa composição.
Não interpreta GET, gravação ou impressão.

```gleam
let composta = {
  use numero <- task.then(task.done(20))
  task.done(numero + 22)
}
```

O trecho constrói uma descrição com resultado 42, sem I/O. As continuações
podem ser avaliadas durante a composição de um `Done`, pois são lógica pura.

## 4. Executor fake

Arquivo: [task/fake.gleam](../../lib/sgleam/task/fake.gleam).

```gleam
fake.run(programa, respostas) -> Report(a)
```

A operação é uma transformação de dados: recebe a descrição e respostas e
retorna resultado e histórico. Não depende do relógio, do disco ou da rede.

### Respostas configuradas

```gleam
[
  fake.GetResponse("https://malbarbo.pro.br", Ok("conteúdo de demonstração")),
  fake.WriteFileResponse("arquivo.txt", "conteúdo de demonstração", Ok(Nil)),
  fake.PrintlnResponse("Sucesso"),
]
```

As comparações são exatas. GET compara a URL; gravação compara caminho **e
conteúdo**; impressão compara a mensagem. A primeira resposta correspondente
vence. As respostas são reutilizáveis, não são consumidas como uma fila.
O histórico permite conferir separadamente a ordem e o número de pedidos.

`PrintlnResponse` fornece a resposta `Nil`. Não imprime o texto: a ocorrência é
registrada como `fake.Println(mensagem)` nos dados do relatório.

### Resultado e histórico

```gleam
pub type Report(a) {
  Report(result: Result(a, Failure), requests: List(Request))
}
```

O relatório de sucesso do exemplo contém:

```text
result: Ok(0)
requests:
  Get("https://malbarbo.pro.br")
  WriteFile("arquivo.txt", "conteúdo de demonstração")
  Println("Sucesso")
```

`requests` segue a ordem de interpretação. O fake acumula a lista internamente
em ordem inversa e a inverte ao terminar, usando recursão em cauda no loop.

### Dois tipos diferentes de falha

1. **Resposta de erro configurada:** `GetResponse(url, Error("offline"))` é uma
   resposta conhecida. O fake entrega esse `Error` à continuação e o próprio
   programa escolhe o ramo de erro. O resultado final pode ser `Ok(1)` no relatório.
2. **Pedido desconhecido:** o fake retorna
   `Error(UnexpectedRequest(pedido))` no relatório. Não chama a continuação,
   não inventa uma resposta e não tenta realizar I/O real. O pedido rejeitado
   aparece no histórico, junto com todos os anteriores.

Para simular erro de GET no main de download, configure a resposta de erro e
`PrintlnResponse("erro no get")`. Para simular erro de gravação, configure GET
com sucesso, WriteFileResponse com erro e `PrintlnResponse("erro no write_file")`.

### Adaptadores do ambiente

`fake.value(programa, respostas)` devolve o valor final quando o relatório é
bem-sucedido. Se houver pedido desconhecido, gera um panic explicando que falta
uma resposta. Ele não realiza os efeitos solicitados; é um adaptador para
ambientes que precisam obter um modelo diretamente. Para tratar falhas como
dados ou examinar o histórico, use `fake.run`.

`demo_responses()` fornece exatamente os três pedidos conhecidos do download
bem-sucedido. `demo_value(programa)` usa essas respostas. Essa configuração é
uma demonstração, não uma simulação genérica de qualquer programa.

## 5. O main de download

O [programa original](../../examples/task_download.gleam) mantém a sintaxe com
`use` e a assinatura `main() -> Task(Int)`. Seu corpo é:

```gleam
import sgleam/task.{type Task}

pub fn main() -> Task(Int) {
  use get <- task.get("https://malbarbo.pro.br")
  case get {
    Ok(content) -> {
      use write <- task.write_file("arquivo.txt", content)
      case write {
        Ok(_) -> {
          use _ <- task.println("Sucesso")
          task.done(0)
        }
        Error(_) -> {
          use _ <- task.println("erro no write_file")
          task.done(1)
        }
      }
    }
    Error(_) -> {
      use _ <- task.println("erro no get")
      task.done(1)
    }
  }
}
```

Interpretação com a configuração padrão:

```text
main constrói Get
  → fake encontra a URL e fornece conteúdo predefinido
  → continuação constrói WriteFile com esse conteúdo
  → fake reconhece caminho e conteúdo e fornece Ok(Nil)
  → continuação constrói Println("Sucesso")
  → fake reconhece a mensagem e fornece Nil
  → continuação retorna Done(0)
  → relatório contém Ok(0) e três pedidos
```

Não existe acesso ao site, criação ou substituição de arquivo, nem impressão
de `Sucesso`. O conteúdo retornado é o da fixture, não o conteúdo atual do site.

## 6. Integração com o ambiente sgleam

[run.rs](../../engine/src/run.rs) reconhece o retorno nominal
`sgleam/task.Task(Int)` e seleciona `MainFunction::TaskMain`. Um retorno
`fn() -> Int` não é mais considerado uma tarefa. A precedência existente de
`smain` foi preservada.

O executor JavaScript chama `main()` para obter a descrição. Para `TaskMain`,
passa esse valor a `fake.demo_value`, escrito em Gleam e compilado para JS.
Ele não chama o valor como função e não despacha operações ao sistema operacional.

A execução padrão do exemplo termina silenciosamente. O inteiro final não é
convertido em código de saída do processo. Um pedido não previsto nas fixtures
padrão causa erro do interpretador, que o ambiente apresenta como falha de execução.

A regra automática permanece específica para `main -> Task(Int)`. Outros
resultados podem ser interpretados explicitamente por um ambiente ou por
`fake.run`. Não há autoexecução de tarefas arbitrárias no REPL.

### Ver a demonstração

```sh
cargo run -- examples/task_download.gleam
cargo run -- examples/task_fake.gleam
```

O primeiro comando não imprime `Sucesso`. O segundo executa
[task_fake.gleam](../../examples/task_fake.gleam), cujo `smain` executa dez verificações com asserções e devolve uma lista de resultados
"OK". O exemplo cobre sucesso, erros simulados, pedidos desconhecidos, `then`,
mudança de tipo, repetibilidade e seleção de respostas. Ele interrompe na primeira
asserção que falhar.
O ambiente imprime o valor de `smain` pela sua capacidade normal de apresentação.
Isso é diferente de executar o pedido `Println`: o fake continua sem efeitos.

O interpretador usa apenas Gleam e funciona com os alvos nativo e WASM, sem
registro de funções de HTTP ou arquivo. Não existe fallback para I/O real.

## 7. SimpleApp e App

| Função | SimpleApp | App |
| --- | --- | --- |
| init | `fn() -> model` | `fn() -> Task(model)` |
| view | `fn(model) -> Element(msg)` | `fn(model) -> Element(msg)` |
| update | `fn(model, msg) -> model` | `fn(model, msg) -> Task(model)` |

`SimpleApp` permanece igual. No `App`, init e update constroem descrições.
O executor do ambiente obtém o modelo interpretando essas descrições.

```gleam
app.create(init, view, update)
|> app.run_with(fn(programa) {
  fake.value(programa, respostas)
})
```

O trecho pressupõe as funções e respostas definidas. `run_with` recebe a
interpretação como parâmetro, separando a lógica da aplicação da configuração
do ambiente. O próprio loop não contém código de GET ou gravação.
`app.run` é um atalho que usa o fake da demonstração de download; para programas
com outros pedidos, forneça respostas explícitas com `run_with`.

Após interpretar init, o ambiente desenha a primeira view. Para cada evento
válido, chama update, interpreta a descrição e recebe o novo modelo. A fila de
eventos disponíveis é drenada antes da próxima renderização. Dois cliques podem
produzir duas atualizações e apenas uma renderização com o modelo final.

A renderização e a leitura de eventos são responsabilidades do ambiente de UI
e continuam sendo interações reais do host. O fake de tarefas não simula essa
infraestrutura de UI; ele simula apenas os pedidos representados por Task.
No CLI, o host imprime HTML e encerra o loop, sem janela interativa.

### Exemplos atualizados

- [Contador](../../examples/app_counter.gleam): três mensagens reconhecidas pelo
  fake; nenhum println real. Incrementar e decrementar usam mensagens fixas.
- [Notas](../../examples/app_notes.gleam): uma gravação exata conhecida; alterações
  no caminho ou conteúdo demonstram pedido desconhecido, apresentado no modelo.
- [HTTP](../../examples/app_http.gleam): uma URL de sucesso e uma URL de falha
  conhecidas; nenhuma conexão é aberta.
- [SimpleApp](../../examples/simple_counter.gleam): contador sem pedidos.

Veja o [guia dos exemplos](../../examples/README.md) para executar cada caso.

## 8. Pureza e limites da garantia

Os módulos task e task/fake não importam I/O, não usam FFI, não consultam o mundo
externo e não mantêm estado mutável. Para continuações puras, a construção,
composição e interpretação são puras: as mesmas entradas produzem os mesmos dados.
Uma simulação repetida devolve o mesmo relatório sem repetir efeitos reais.

Isso não transforma toda a linguagem Gleam em uma linguagem com verificação de
efeitos. Um usuário ainda pode escrever uma continuação que chama diretamente
`gleam/io`, `@external` ou outras APIs impuras. O fake avalia continuações e não
é um sandbox contra esse código. A garantia desta biblioteca é a separação
arquitetural e a ausência de I/O nas operações implementadas, sob o contrato de
continuações puras. Uma garantia global exigiria restrições adicionais de linguagem.

Task contém funções, então não se deve comparar tarefas estruturalmente para
verificar equivalência. Compare o resultado e histórico de `fake.run`, que são
dados. O tipo público permite construir interpretadores alternativos, mas nenhum
executor real faz parte desta implementação.

## 9. Migração da versão anterior

- Remova chamadas a `task.run`: a função não existe mais.
- Para demonstração, use `fake.run(tarefa, respostas)` e examine seu relatório.
- Para App, forneça seu ambiente com `app.run_with` e fixtures explícitas.
- Não trate Task como `fn() -> a`; use os construtores e funções do módulo.
- Não espere arquivo, resposta HTTP real ou saída de println ao interpretar.
- Mantenha o `use` em cada println encadeado; sua continuação continua obrigatória.
- `done` agora constrói um dado `Done`, em vez de uma função retornando um valor.

A implementação foi alterada somente no sgleam. O simplecode e sua cópia do
engine não são sincronizados automaticamente por essas mudanças.

## 10. Testes e arquivos

[cli/tests/tasks.rs](../../cli/tests/tasks.rs) verifica o main nos dois modos de
inteiros, os três caminhos de sucesso/erro, o histórico exato, a rejeição de
pedidos desconhecidos, composição, repetibilidade e identificação nominal de Task.
Um arquivo com conteúdo sentinela precisa permanecer intacto e nenhum `new.txt`
pode surgir. A saída padrão dos casos de sucesso deve permanecer vazia.

[engine/tests/task_app.rs](../../engine/tests/task_app.rs) fornece dois eventos
em um host de UI simulado e verifica a evolução de 0 para 2 sem impressão das
mensagens descritas pelas tarefas. A UI ainda deve renderizar o estado atualizado.

```sh
cargo test -p sgleam --test tasks
cargo test -p engine --test task_app
cargo test
cargo clippy --all-targets -- -D warnings
cargo clippy --target wasm32-wasip1 -p wasm -- -D warnings
cargo fmt --all -- --check
```

| Arquivo | Responsabilidade |
| --- | --- |
| [task.gleam](../../lib/sgleam/task.gleam) | Descrições e composição |
| [task/fake.gleam](../../lib/sgleam/task/fake.gleam) | Respostas predefinidas, interpretação e histórico |
| [ui/app.gleam](../../lib/sgleam/ui/app.gleam) | Loop parametrizado pelo interpretador do ambiente |
| [run.rs](../../engine/src/run.rs) | Reconhecimento nominal de Task(Int) |
| [engine.rs](../../engine/src/engine.rs) | Identificação TaskMain |
| [sgleam_ffi.mjs](../../lib/sgleam/sgleam_ffi.mjs) | Seleção do fake pelo ambiente de execução |

Possíveis evoluções incluem um executor real separado, fixtures consumidas em
ordem, erros mais estruturados e execução assíncrona. Nenhuma dessas evoluções
é necessária para a demonstração pura atual e nenhuma foi implementada aqui.

## Parar a aplicação com stop_when

`simple_app.stop_when` e `app.stop_when` recebem `fn(model) -> Bool`.
Sem essa configuração, o comportamento anterior é preservado.

```gleam
simple_app.create(init, view, update)
|> simple_app.stop_when(fn(model) { model.count >= 5 })
|> simple_app.run
```

O predicado deve ser puro. Ele é verificado no estado inicial e após cada
atualização, inclusive entre eventos do mesmo lote. Quando retorna True,
a view final é renderizada e run retorna Nil, sem esperar ou consumir outro
evento. A aplicação não fecha a aba nem o processo. A view final permanece;
se quiser mostrar botões desabilitados, faça isso em view, como no exemplo
`examples/simple_stop_when.gleam`. A condição não interrompe uma atualização
ou interpretação já em andamento. Um stop_when posterior substitui o anterior.
No App, a mesma opção funciona com run e run_with.
