# Implementação de Task, SimpleApp e App

Este documento explica a implementação de tarefas com efeitos no **sgleam**:
a representação dos tipos, a composição com `use`, a integração com o executor,
a execução de HTTP e arquivos e a separação das aplicações de interface.
Descreve o comportamento atual, incluindo suas limitações.

As alterações desta implementação pertencem ao repositório sgleam. O projeto
simplecode e sua cópia em `engines/sgleam` não foram atualizados automaticamente.

## 1. Objetivo e conceitos

Um efeito colateral é uma interação observável além do valor retornado por uma
função: imprimir, gravar um arquivo ou fazer uma requisição HTTP, por exemplo.
O objetivo é representar essas operações como valores que possam ser compostos
antes de sua execução.

A proposta tem duas partes:

- `Task(a)` representa uma computação adiada que produz um valor do tipo `a`.
- `App(model, msg)` recebe tarefas para inicializar e atualizar seu modelo.

A API anterior, com inicialização e atualização retornando diretamente o modelo,
foi preservada no módulo `sgleam/ui/simple_app`, com o tipo `SimpleApp`.

A separação é um contrato de organização do programa. Gleam não verifica a
pureza dessas funções: uma função que retorna `Int` ainda pode chamar I/O.
Além disso, o próprio executor de `SimpleApp` realiza efeitos para mostrar a
interface e receber eventos. O termo “sem efeitos” se refere ao estilo esperado
para a lógica de inicialização e atualização do modelo.

## 2. Representação de Task como função

Arquivo: [lib/sgleam/task.gleam](../../lib/sgleam/task.gleam).

```gleam
pub type Task(a) =
  fn() -> a
```

Esse tipo é um **alias**, e não um tipo opaco ou uma estrutura com construtor.
Por isso, `Task(Int)` e `fn() -> Int` são o mesmo tipo para o compilador.
Uma função sem argumentos é suficiente para guardar uma computação e executá-la
posteriormente. Essa representação também é conhecida como *thunk*.

```gleam
fn() { 10 }
```

A expressão acima cria uma função; seu corpo só é avaliado quando ela é chamada.
Uma tarefa pode capturar valores do contexto, como a URL de uma requisição ou o
conteúdo de um arquivo, por meio de uma closure.

### 2.1. Construir, executar e repetir

```gleam
import sgleam/task

pub fn main() {
  let tarefa = {
    use _ <- task.println("Executando")
    task.done(42)
  }

  // Até aqui, a mensagem não foi impressa.
  let assert 42 = task.run(tarefa)
  let assert 42 = task.run(tarefa)
}
```

A mensagem aparece duas vezes. Não há cache do resultado, execução automática
na criação ou restrição que impeça executar uma tarefa mais de uma vez.

### 2.2. O adiamento depende de onde o código fica

Gleam avalia os argumentos de uma chamada antes de entrar na função. Portanto,
`done(expressao)` não adia a avaliação de `expressao`; guarda o valor já calculado.

```gleam
// A impressão acontece agora, ao avaliar o argumento de done.
let tarefa = task.done(io.println("agora"))
```

O trecho acima pressupõe os imports de `gleam/io` e `sgleam/task`.
Para adiar um efeito, ele precisa ficar dentro da função da tarefa, como acontece
nas operações públicas deste módulo. Também é possível construir diretamente
`fn() { io.println("depois") }`, pois Task é um alias de função.

## 3. Operações fundamentais

### 3.1. done: concluir com um valor

```gleam
pub fn done(value: a) -> Task(a) {
  fn() { value }
}
```

`done(0)` devolve uma função que retorna `0`. Não encerra o processo, não dispara
as tarefas anteriores e não indica por si só sucesso ao sistema operacional.
É a conclusão de uma sequência de tarefas com um resultado.

### 3.2. run: executar uma tarefa

```gleam
pub fn run(task: Task(a)) -> a {
  task()
}
```

`run` chama a função. Não cria threads, não agenda trabalho em segundo plano e
não transforma exceções em `Result`.

### 3.3. then: compor duas etapas

```gleam
pub fn then(first: Task(a), next: fn(a) -> Task(b)) -> Task(b) {
  fn() { run(next(run(first))) }
}
```

A chamada a `then` constrói uma nova tarefa. Quando essa tarefa é executada:

1. `run(first)` executa a primeira etapa e obtém um valor `a`.
2. `next(valor)` constrói a tarefa seguinte a partir desse valor.
3. `run(...)` executa a tarefa seguinte e devolve seu resultado `b`.

Os tipos `a` e `b` podem ser diferentes. `then` também é chamado de operação
*bind* em apresentações de mônadas. Aqui, sua implementação é somente composição
de funções; não foi necessário adicionar uma construção nova à linguagem.

```gleam
import sgleam/task

pub fn main() {
  let primeira = task.done(20)
  let segunda = {
    use valor <- task.then(primeira)
    task.done(valor + 22)
  }
  let assert 42 = task.run(segunda)
}
```

`then` não interpreta `Ok` ou `Error`. Se o resultado da primeira tarefa for um
`Result`, ele é entregue inteiro à continuação. O programa decide como tratar
cada caso.

## 4. Como use representa a continuação

O `use` já existia no Gleam. Ele transforma o restante do bloco em uma função e
passa essa função como último argumento da chamada.

```gleam
use resposta <- task.get(url)
case resposta {
  Ok(conteudo) -> task.done(conteudo)
  Error(_) -> task.done("Falhou")
}
```

É equivalente a:

```gleam
task.get(url, fn(resposta) {
  case resposta {
    Ok(conteudo) -> task.done(conteudo)
    Error(_) -> task.done("Falhou")
  }
})
```

Os dois trechos são expressões que pressupõem `url` e o import de `task`.
A função recebida é a **continuação**: o código a executar depois da operação.
O `use` não executa tarefas sozinho e não equivale a `await`.

Nesta API, `task.get(url)` aparece com um único argumento na linha do `use`
porque o compilador fornece o argumento restante. Fora desse contexto,
`task.get(url)` não é uma chamada completa: é necessário fornecer a continuação.

## 5. API de efeitos

| Função | Argumentos explícitos antes da continuação | Valor entregue à continuação | Retorno |
| --- | --- | --- | --- |
| `println` | `message: String` | `Nil` | `Task(a)` |
| `get` | `url: String` | `Result(String, String)` | `Task(a)` |
| `write_file` | `path: String`, `content: String` | `Result(Nil, String)` | `Task(a)` |

O `a` do retorno é escolhido pelo resultado final da continuação, não pela
operação de I/O. Por exemplo, um GET pode participar de uma tarefa que termina
retornando um inteiro, um texto ou o modelo de uma aplicação.

### 5.1. println

```gleam
pub fn println(message: String, next: fn(Nil) -> Task(a)) -> Task(a) {
  then(fn() { io.println(message) }, next)
}
```

A impressão fica dentro da função passada a `then`. Depois dela, a continuação
recebe `Nil`. O padrão usual descarta esse valor:

```gleam
use _ <- task.println("Sucesso")
task.done(0)
```

`println` utiliza `gleam/io`; não utiliza as funções nativas novas de HTTP e
arquivo. Ela também não expõe falhas de impressão como `Result`.

### 5.2. get

A assinatura é:

```gleam
pub fn get(
  url: String,
  next: fn(Result(String, String)) -> Task(a),
) -> Task(a)
```

O corpo usa `then(fn() { get_raw(url) }, next)`. A função privada `get_raw`
atravessa a interface de funções externas para chegar ao host.

No host nativo, a operação usa `reqwest::blocking::Client` com suporte a TLS via
Rustls. Um cliente é criado a cada execução. O código configura um timeout de
30 segundos, envia GET, verifica o status com `error_for_status()` e lê o corpo
como texto com `text()`.

- A URL deve conter o esquema, como `https://malbarbo.pro.br`.
- Redirecionamentos seguem a política padrão da biblioteca.
- Status HTTP 4xx e 5xx são erros.
- Falhas de URL, conexão e leitura também chegam como `Error(mensagem)`.
- O resultado contém o corpo textual, não status, cabeçalhos ou bytes brutos.
- Não há retry automático implementado pela camada Task.

### 5.3. write_file

A assinatura é:

```gleam
pub fn write_file(
  path: String,
  content: String,
  next: fn(Result(Nil, String)) -> Task(a),
) -> Task(a)
```

A operação adiada chama `write_file_raw`. No host nativo, ela utiliza
`std::fs::write` para gravar os bytes UTF-8 da string.

Um caminho relativo é resolvido a partir do diretório de trabalho do processo,
e não do diretório do arquivo `.gleam`. Um arquivo existente é substituído.
Diretórios intermediários não são criados. Não há escrita atômica, transação ou
restauração automática do conteúdo anterior em caso de falha.

O sucesso é `Ok(Nil)`; uma falha de I/O é `Error(mensagem)`.

## 6. Exemplo completo do download

Arquivo: [examples/task_download.gleam](../../examples/task_download.gleam).

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

Em relação à proposta original, o exemplo usa o caminho de módulo do projeto,
`import sgleam/task.{type Task}`, e declara `pub fn main` para o executor.
A URL contém o esquema HTTPS. Também foi acrescentado o `use _ <-` que faltava
no ramo de erro de `write_file`.

Sem esse último ajuste, `task.println("erro no write_file")` não fornece a
continuação exigida pela função e não compila com essa API.

### 6.1. Fluxo de sucesso e erro

```text
main() constrói a tarefa
  → executor chama a tarefa
    → HTTP GET
      → Error: imprimir erro no get → retornar 1
      → Ok: write_file
        → Error: imprimir erro no write_file → retornar 1
        → Ok: imprimir Sucesso → retornar 0
```

O `Result` determina o ramo executado. Um erro de HTTP impede que a gravação
seja sequer alcançada. Um erro de gravação impede a impressão de sucesso.
Cada ramo encerra com `Task(Int)`, mantendo o mesmo tipo de resultado.

Para executar, na raiz do repositório:

```sh
cargo run -- examples/task_download.gleam
```

Em caso de sucesso, o comando imprime `Sucesso` e cria ou substitui
`arquivo.txt` no diretório atual. O acesso ao site depende da rede e do serviço;
os testes automatizados usam um servidor local para não depender desse site.

## 7. Integração de main com o executor

Somente retornar uma função de `main` não executaria seu corpo. Por isso, a
implementação também altera a seleção e a execução do ponto de entrada.

### 7.1. Identificação pelo tipo

Em [engine/src/run.rs](../../engine/src/run.rs), `get_main` mantém a seleção
pré-existente de `smain`. Quando o ponto de entrada é `main`, examina seu tipo
de retorno com `fn_types()`.

Se o retorno for uma função sem argumentos cujo resultado é `Int`, escolhe
`MainFunction::TaskMain`. Caso contrário, escolhe `MainFunction::Main`.

A identificação é estrutural. Como `Task` é um alias, tanto a anotação
`Task(Int)` quanto `fn() -> Int` levam ao mesmo comportamento. Não há uma marca
em tempo de execução que distinga uma tarefa de outra função com esse tipo.

### 7.2. Execução no JavaScript

[engine/src/engine.rs](../../engine/src/engine.rs) define a variante `TaskMain`.
Ela continua importando a função chamada `main` e não solicita impressão
automática do resultado.

[engine/src/quickjs.rs](../../engine/src/quickjs.rs) passa a identificação do
ponto de entrada para `try_main`, na FFI JavaScript. O fluxo relevante é:

```javascript
r = main();
if (input_kind === "TaskMain") {
  r = r();
}
```

A primeira chamada obtém a tarefa; a segunda realiza a computação adiada.
A execução continua dentro do tratamento de erros existente em `try_main`.

### 7.3. Alcance e código de saída

A execução automática foi adicionada para `main` retornando `Task(Int)`.
Não foi generalizada para `Task(String)`, `Task(Nil)`, `smain` ou qualquer valor
exibido no REPL. Para outras situações, execute `task.run` explicitamente.

O inteiro final **não é convertido em código de saída do processo**. Retornar
`task.done(1)` é um resultado normal da tarefa e, por si só, não faz o processo
sair com status 1. Esse comportamento preserva o tratamento atual do retorno
de `main`. Erros de compilação e falhas de execução continuam seguindo o
tratamento de erros já existente no executor.

## 8. Caminho entre Gleam, JavaScript e Rust

```text
Programa Gleam
    |
    | task.get / task.write_file: constroem funções
    v
Task executada por run ou pelo executor de main
    |
    v
get_raw / write_file_raw (@external)
    |
    v
sgleam_ffi.mjs: task_get / task_write_file
    |
    v
Objeto sgleam registrado pelo QuickJS
    |
    v
Host nativo Rust
    |
    +-- reqwest: HTTP
    +-- std::fs::write: arquivo
```

As funções Rust devolvem `(bool, String)`: sucesso com valor ou falha com uma
mensagem. O adaptador de QuickJS usa `rquickjs::convert::List` para transferir a
tupla como uma sequência JavaScript; isso não é uma `List` da API Gleam.

A FFI converte a resposta para os construtores de `Result` usados pelo código
Gleam compilado:

| Operação | Resposta Rust | Resposta Gleam |
| --- | --- | --- |
| GET bem-sucedido | `(true, corpo)` | `Ok(corpo)` |
| Gravação bem-sucedida | `(true, "")` | `Ok(Nil)` |
| Falha | `(false, mensagem)` | `Error(mensagem)` |

No JavaScript, o `Nil` dessa resposta é representado por `undefined`.

### 8.1. Host nativo e WASM

As funções de HTTP e gravação são registradas somente quando o alvo não é
`wasm32`. A dependência `reqwest` também foi adicionada apenas para esse alvo.

No host WASM atual, a FFI verifica a ausência das funções e retorna:

- `Error("HTTP tasks are not supported by this host")`;
- `Error("File tasks are not supported by this host")`.

Esses resultados chegam à continuação normalmente. Não há implementação de
`fetch`, download de arquivo no navegador ou persistência no simplecode nesta
alteração. A compilação WASM passa, mas isso não significa que os efeitos de
rede e arquivo estejam disponíveis nele.

## 9. SimpleApp e App

Os dois módulos seguem o padrão modelo–visualização–atualização (MVU):
`model` representa o estado; `view` o transforma em elementos; `msg` representa
uma mensagem gerada por um evento; `update` calcula o próximo estado.

| Aspecto | `SimpleApp(model, msg)` | `App(model, msg)` |
| --- | --- | --- |
| Módulo | `sgleam/ui/simple_app` | `sgleam/ui/app` |
| `init` | `fn() -> model` | `fn() -> Task(model)` |
| `view` | `fn(model) -> Element(msg)` | `fn(model) -> Element(msg)` |
| `update` | `fn(model, msg) -> model` | `fn(model, msg) -> Task(model)` |
| Resultado de `run` | `Nil` | `Nil` |

Ambos são tipos opacos: o programa os cria por `create` e inicia por `run`.
`create` guarda as funções fornecidas, sem iniciar a aplicação.

### 9.1. Inicialização

No `SimpleApp`, o executor começa com `loop(app, app.init())`.
No `App`, começa com:

```gleam
loop(app, task.run(app.init()))
```

Primeiro `init` constrói a tarefa, depois o executor a executa e recebe o modelo
inicial. A primeira visualização só ocorre após a conclusão dessa tarefa.

### 9.2. Eventos e atualização

O loop transforma `view(model)` em HTML e um dicionário de handlers, exibe o
HTML e espera eventos. Quando há eventos disponíveis, `drain`:

1. Lê o próximo evento bruto do host.
2. Decodifica o tipo de evento e seu identificador de handler.
3. Procura o handler na interface renderizada.
4. Aplica o evento ao handler para obter uma mensagem.
5. Chama `update(model, mensagem)`.
6. No `App`, executa a tarefa devolvida e usa o resultado como próximo modelo.
7. Continua consumindo os eventos disponíveis.

O trecho central do `App` é:

```gleam
Ok(task.run(app.update(model, message)))
```

Eventos que não podem ser decodificados ou associados a um handler mantêm o
modelo atual. Isso não constitui um tratamento genérico de falhas nas tarefas:
um `panic` durante a execução não é convertido automaticamente em modelo.

### 9.3. Renderização após o lote de eventos

A renderização acontece depois que `drain` termina. Portanto, se dois eventos
estiverem disponíveis, as duas atualizações podem ocorrer antes da próxima
renderização. Elas usam os handlers da última interface renderizada.

```text
Executar init → modelo 0 → renderizar 0
                              |
                         dois eventos
                              |
                  executar update → modelo 1
                              |
                  executar update → modelo 2
                              |
                         renderizar 2
```

Os efeitos são sequenciais. Não há tarefas concorrentes, fila separada de
comandos nem mensagens de conclusão assíncrona. Uma tarefa lenta bloqueia o
avanço do loop enquanto executa.

### 9.4. Exemplo de App com efeito na atualização

```gleam
import gleam/int
import sgleam/task.{type Task}
import sgleam/ui/app
import sgleam/ui/button
import sgleam/ui/element.{type Element}

type Msg {
  Incrementar
}

fn init() -> Task(Int) {
  use _ <- task.println("Inicializando")
  task.done(0)
}

fn update(model: Int, message: Msg) -> Task(Int) {
  case message {
    Incrementar -> {
      use _ <- task.println("Incrementando")
      task.done(model + 1)
    }
  }
}

fn view(model: Int) -> Element(Msg) {
  button.new("Contador: " <> int.to_string(model))
  |> button.on_press(Incrementar)
  |> button.done
}

pub fn main() {
  app.create(init, view, update)
  |> app.run
}
```

Esse exemplo utiliza o host de UI já existente. No host nativo, sem a integração
de eventos de interface, o fallback mostra o HTML e encerra o loop; ele não
abre uma janela interativa. A interação depende do host que fornece os eventos.


### 9.5. Outros exemplos completos

Há três programas adicionais em `examples/`:

- [Contador](../../examples/app_counter.gleam): impressão na inicialização e nas atualizações.
- [Bloco de notas](../../examples/app_notes.gleam): edição do modelo e gravação com tratamento de erro.
- [Consulta HTTP](../../examples/app_http.gleam): GET e prévia textual da resposta.

O [guia dos exemplos](../../examples/README.md) explica como verificar os programas
e quais recursos estão disponíveis em cada host.

## 10. Migração de aplicações existentes

### 10.1. Manter inicialização e atualização diretas

Troque:

```gleam
import sgleam/ui/app
```

por:

```gleam
import sgleam/ui/simple_app as app
```

Assim, chamadas `app.create(...)` e `app.run(...)` continuam com os mesmos nomes.
Se o código importar ou anotar explicitamente o tipo `App`, será necessário
ajustar a referência para `SimpleApp` também.

### 10.2. Migrar para tarefas

Mantenha `sgleam/ui/app`, importe `sgleam/task` e faça `init` e `update`
retornarem tarefas. Uma transformação sem efeitos pode começar assim:

```gleam
fn init() -> Task(Int) {
  task.done(0)
}

fn update(model: Int, _message: Nil) -> Task(Int) {
  task.done(model + 1)
}
```

Esse trecho pressupõe `import sgleam/task.{type Task}`. Depois, efeitos podem
ser encadeados antes de `task.done(novo_modelo)`. A assinatura de `view` não muda.

Não há adaptação automática de chamadas antigas a `app.create`: funções que
retornam modelos diretamente precisam migrar ou utilizar `simple_app`.

## 11. Arquivos envolvidos

Os links abaixo são relativos a este documento.

| Arquivo | Responsabilidade |
| --- | --- |
| [task.gleam](../../lib/sgleam/task.gleam) | Alias Task, composição e operações públicas |
| [simple_app.gleam](../../lib/sgleam/ui/simple_app.gleam) | API anterior com modelos diretos |
| [app.gleam](../../lib/sgleam/ui/app.gleam) | Execução de tarefas de init e update |
| [sgleam_ffi.mjs](../../lib/sgleam/sgleam_ffi.mjs) | Execução de TaskMain e tradução dos resultados do host |
| [run.rs](../../engine/src/run.rs) | Reconhecimento do tipo de retorno de main |
| [engine.rs](../../engine/src/engine.rs) | Variante MainFunction::TaskMain |
| [quickjs.rs](../../engine/src/quickjs.rs) | Registro das funções nativas e chamada do executor |
| [host.rs](../../engine/src/host.rs) | Exportação das operações do host nativo |
| [host/native.rs](../../engine/src/host/native.rs) | Implementação de HTTP e gravação |
| [engine/Cargo.toml](../../engine/Cargo.toml) | Dependência reqwest para o alvo nativo |
| [Cargo.lock](../../Cargo.lock) | Versões resolvidas das dependências |
| [task_download.gleam](../../examples/task_download.gleam) | Programa completo do download |
| [tasks.rs](../../cli/tests/tasks.rs) | Testes de ponta a ponta da CLI |
| [task_app.rs](../../engine/tests/task_app.rs) | Teste da ordem de efeitos e renderização |

## 12. Testes e reprodução da validação

### 12.1. CLI

`cli/tests/tasks.rs` cobre:

- Execução automática do main de download, com servidor HTTP local e diretório
  temporário, nos modos padrão de inteiros e `-n`.
- Conferência da mensagem de sucesso e do conteúdo gravado.
- Resposta HTTP 404, que seleciona o ramo de erro de GET.
- Gravação em diretório inexistente, que seleciona o ramo de erro de arquivo.
- Construção de uma tarefa de gravação que nunca é executada: o arquivo não surge.
- Execução repetida de uma tarefa de impressão, verificando ordem e resultado 42.
- Tratamento de uma URL com esquema inválido.
- Compilação e inicialização de SimpleApp e App.

### 12.2. Loop do App

`engine/tests/task_app.rs` compila um programa Gleam e fornece um host simulado
em JavaScript. O host envia dois eventos de clique. O teste verifica a ordem:

```text
impressão de init
renderização do modelo 0
impressão da primeira atualização
impressão da segunda atualização
renderização do modelo 2
```

Esse teste verifica a execução real do código compilado em QuickJS. Não é um
teste de interação com um navegador ou do servidor simplecode.

### 12.3. Comandos

Execute na raiz do repositório:

```sh
# Testes específicos desta implementação
cargo test -p sgleam --test tasks
cargo test -p engine --test task_app

# Suíte Rust padrão
cargo test

# Análise estática nativa e do alvo WASM
cargo clippy --all-targets -- -D warnings
cargo clippy --target wasm32-wasip1 -p wasm -- -D warnings

# Formatação
cargo fmt --all -- --check
cargo run -- format --check lib/sgleam/task.gleam lib/sgleam/ui/app.gleam lib/sgleam/ui/simple_app.gleam examples/task_download.gleam
deno fmt --check lib/sgleam/sgleam_ffi.mjs
```

A checagem WASM requer o alvo `wasm32-wasip1` instalado. A checagem JavaScript
requer Deno. Na validação inicial desta implementação, a suíte Rust padrão
registrou 273 testes aprovados e 136 ignorados; os comandos de Clippy nativo,
Clippy WASM e formatação também passaram. Essa contagem é um registro daquela
execução, não uma garantia para versões futuras do projeto. Não foi realizada
uma execução interativa no navegador como parte dessa validação.

## 13. Limitações e possíveis evoluções

| Comportamento atual | Consequência |
| --- | --- |
| Task é um alias de função | Não há distinção nominal ou garantia de pureza |
| Execução síncrona | I/O bloqueia a tarefa e o loop de UI |
| Sem memoização | Executar novamente repete os efeitos |
| Sem agendador ou cancelamento próprio | Task não gerencia concorrência nem interrupção de I/O |
| HTTP e arquivos apenas no host nativo | Esses efeitos retornam Error no WASM atual |
| TaskMain reconhece fn() -> Int | Outros retornos exigem run explícito |
| Resultado inteiro não define exit status | done(1) não equivale a encerrar o processo com erro |
| Erros de I/O representados por String | Não há categorias tipadas de erro nessa API |
| Sem captura geral de exceções em run | Panic e falhas inesperadas seguem o tratamento existente |
| Composição por chamadas de função | Não há trampoline nem garantia de pilha constante para cadeias arbitrariamente longas |
| API de App alterada | Consumidores precisam migrar ou usar SimpleApp |

Evoluções possíveis incluem implementar efeitos no host do navegador, definir
uma política para códigos de saída, introduzir erros estruturados e estudar uma
execução assíncrona com mensagens de conclusão. Essas possibilidades não estão
implementadas nesta versão e podem exigir mudanças na API e no host.
