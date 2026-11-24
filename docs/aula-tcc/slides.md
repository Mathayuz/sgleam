## Uma interface também é um programa funcional

Como fazer uma tela reagir a entradas utilizando o projeto de funções?

- Representar o que muda usando dados.
- Transformar esses dados com funções.
- Descrever a interface e os efeitos externos.

Hoje vamos construir uma aplicação em etapas e avaliar a experiência com a SHOW.

## O trabalho e a aula de hoje

**SHOW: uma biblioteca educativa para interfaces gráficas interativas no Sgleam.**

A biblioteca oferece componentes para construir interfaces usando modelos, mensagens e funções de atualização.

Nesta aula, vamos experimentar essa abordagem na prática.

Ao final, as respostas de vocês sobre a experiência contribuirão para a avaliação do meu TCC.

## O que vocês já sabem continua valendo

- Tipos de dados representam informações.
- Funções recebem valores e produzem novos valores.
- `case` acompanha as alternativas dos tipos.
- Listas e funções de transformação ajudam a decompor problemas.
- Propósito, assinatura e exemplos orientam a implementação.

A novidade é organizar essas peças para responder a eventos de uma interface.

## Da World à SHOW

As duas organizam a interação a partir de um estado e de funções.

| Aspecto | World | SHOW |
|---|---|---|
| Uso típico | Jogos e animações | Interfaces gráficas |
| Apresentação | Estado produz uma `Image` | Model produz um `Element(Msg)` |
| Eventos | Teclado e passagem do tempo | Componentes produzem mensagens |
| Atualização | Funções como `on_key_press` e `on_tick` | Função `update(model, msg)` |

Na SHOW, botões, inputs, checkbox e radio já são componentes da interface.

Nas duas, podemos projetar e testar as funções que transformam o estado.

## Model, Msg, update e view

**Model** representa as informações que a aplicação precisa lembrar.

**Msg** representa algo que aconteceu: um clique, uma edição ou uma resposta externa.

`update(model, msg)` calcula o próximo modelo.

`view(model)` descreve a interface correspondente ao modelo.

O ambiente apresenta a interface e encaminha eventos como mensagens.

## Um ciclo de interação

```text
               evento da interface
                       |
                       v
Model -------> view -> interface -> Msg
  ^                                  |
  |                                  v
  +------------ update(Model, Msg) ---+
```

O modelo antigo continua sendo um valor. A atualização produz outro modelo.

## Como projetar cada aplicação

1. **Esboçar a tela, identificar o que muda e criar o Model.**
2. **Identificar as mensagens e definir a função update.**
3. **Criar a função view.**

Em cada função relevante: analisar, definir os tipos, especificar propósito e exemplos, implementar, verificar e revisar.

Escrever exemplos vem antes de confiar na implementação.

## Exemplo 1 — um contador

```text
Contador: 0
[ -1 ]  [ +1 ]  [ Zerar ]
```

**O que muda?** O número exibido.

**Modelo inicial:** `0`, representado por `Int`.

**O que acontece?** Incrementar, decrementar ou zerar.

Pergunta: quais seriam as mensagens para o nosso contador?

## Contador — mensagens e atualização

```gleam
type Msg { Incrementar Decrementar Zerar }

fn update(model: Int, msg: Msg) -> Int {
  case msg {
    Incrementar -> model + 1
    Decrementar -> model - 1
    Zerar -> 0
  }
}
```

Antes de executar: quanto vale `update(0, Decrementar)`?

## Contador — exemplos executáveis

```gleam
pub fn update_examples() {
  check.eq(update(0, Incrementar), 1)
  check.eq(update(0, Decrementar), -1)
  check.eq(update(12, Zerar), 0)
}
```

O requisito permite valores negativos. Se isso mudar, precisamos rever o propósito, os exemplos e a implementação.

No terminal, dentro da pasta do arquivo:

```sh
sgleam test contador.gleam
```

## Contador — a interface descreve os eventos

```gleam
button.new("+1")
  |> button.on_press(Incrementar)
  |> button.done
```

O clique produz uma mensagem. O botão não altera o modelo diretamente.

```gleam
pub fn main() {
  simple_app.create(init, view, update)
    |> simple_app.run
}
```

Vamos executar o exemplo completo `contador.gleam` no ambiente web.

## Exemplo 2 — transformar um texto

```text
Texto: [Gleam    ]
[x] Inverter texto
( ) Nenhuma alteração de caixa
(x) Maiúsculas     
( ) Minúsculas
Resultado: MAELG
```

O checkbox decide se o texto será invertido.

O grupo de radio permite exatamente uma opção de caixa.

## Texto — dados independentes e alternativas

```gleam
type Caixa { Original Maiusculas Minusculas }
type Model {
  Model(entrada: String, inverter: Bool, caixa: Caixa)
}
type Msg {
  TextoAlterado(String)
  InversaoAlterada(Bool)
  CaixaAlterada(Caixa)
}
```

O resultado é calculado a partir do modelo. Guardá-lo também exigiria manter duas representações sincronizadas.

## Texto — projetar a transformação

```gleam
fn transformar(entrada: String, inverter: Bool,
  caixa: Caixa) -> String
```

**Propósito:** inverter quando solicitado e aplicar a caixa escolhida.

| Entrada | Inverter | Caixa | Resultado |
|---|---|---|---|
| Gleam | False | Original | Gleam |
| Gleam | True | Original | maelG |
| Gleam | True | Maiusculas | MAELG |
| Gleam | False | Minusculas | gleam |
| string vazia | True | Maiusculas | string vazia |

## Texto — update e componentes

```gleam
InversaoAlterada(inverter) -> Model(..model, inverter:)
CaixaAlterada(caixa) -> Model(..model, caixa:)
```

Esses são dois ramos da função `update` do exemplo.

- `checkbox.on_change` recebe `fn(Bool) -> Msg`.
- `radio_group.on_select` recebe `fn(Caixa) -> Msg`.
- `text_input.on_input` recebe `fn(String) -> Msg`.

Vamos testar as seis combinações de inversão e caixa, além da entrada vazia.

## Exercício 1 — gerador de login e e-mail

Dois campos: nome completo e domínio, informado sem `@`.

Exibir uma prévia do e-mail a cada edição.

```text
Nome:    [ Ana Maria Silva ]
Domínio: [ uem.br          ]
Prévia: amsilva@uem.br
```

Base: `exercicio_1.gleam`. Completem `init`, `update` e `view`.

`login`, `email` e `previa` já estão implementadas.

## Exercício 1 — regras já fornecidas

A função `login` já calcula as iniciais e o último nome em minúsculas,
limitando o resultado inteiro a oito caracteres.

Usem `previa(model)` para obter o e-mail ou a orientação ao usuário.

| Nome | Login |
|---|---|
| Ana Maria Silva | amsilva |
| Ana | ana |
| Ana Maria Nascimento | amnascim |
| Marco Aurelio Lopes Barbosa | malbarbo |

## Exercício 1 — projetar e verificar

**Model e init:** quais entradas precisam ser lembradas? Iniciem o nome vazio e o domínio com `uem.br`.

**Msg e update:** como cada edição chega ao modelo?

**view:** construam os inputs, associem `on_input` às Msgs e exibam a prévia.

Testem o estado inicial e a edição de um campo preservando o outro. Confiram a interação no playground.

Campos vazios devem produzir uma orientação ao usuário.

## Exercício 2 — uma lista de e-mails

Acrescentem um botão **Adicionar** e uma lista dos e-mails cadastrados.

- Cada inclusão mantém os endereços anteriores na tela.
- Um e-mail completo não pode aparecer duas vezes.
- A duplicação deve exibir uma mensagem e preservar a lista.
- Comparar endereços em minúsculas e sem espaços nas pontas.

“Salvo” significa guardado no modelo durante a sessão. Recarregar a página reinicia a lista.

## Exercício 2 — o que precisa mudar?

Model e init: acrescentar lista de e-mails e aviso, inicialmente vazios.

Msg: acrescentar `Adicionar`.

update: tratar as edições e usar `cadastrar(model)` ao receber `Adicionar`. As regras de validação e duplicação estão prontas.

view: construir o botão com `on_press(Adicionar)`, mostrar o aviso e os endereços.

Testes: primeira inclusão, segunda inclusão, repetição, domínio diferente e campos vazios.

Base: `exercicio_2.gleam`. Completem `init`, `update` e `view`; as funções auxiliares estão prontas.

## Discussão — por que testar update?

Considere duas mensagens `Adicionar` para o mesmo endereço.

O que deve acontecer com a lista após cada mensagem?

- A primeira acrescenta um elemento.
- A segunda mantém a mesma lista e informa a duplicação.
- Editar o nome depois disso preserva os e-mails cadastrados.

Essas propriedades podem ser verificadas sem clicar na interface.

## E quando precisamos de informação externa?

Uma lista externa informa e-mails que já existem.

O conteúdo pode mudar e a obtenção pode falhar.

```text
update -> descrição da tarefa -> ambiente
                                  |
                                  v
update <- Msg com Ok(texto) ou Error(erro)
```

A aplicação descreve o pedido e decide como tratar a resposta.

## De SimpleApp para App

| Função | Sem tarefas | Com tarefas |
|---|---|---|
| init | Model | #(Model, Task(Msg)) |
| update | Model | #(Model, Task(Msg)) |
| view | Element(Msg) | Element(Msg) |

`task.none()` significa que não há tarefa a executar.

Uma tarefa pode produzir uma nova mensagem, que volta para `update`.

## Descrever a obtenção do TXT

```gleam
fn carregar() -> Task(Msg) {
  use resultado <- task.get(url)
  task.done(Recebidos(resultado))
}
```

`resultado` tem tipo `Result(String, task.HttpError)`.

**No playground integrado, `app.run` executa o pedido HTTP real.**

Usem `emails-existentes.txt`, servido junto à página do playground.

## Modelar o carregamento

```gleam
type Estado {
  Carregando
  Pronto(List(String))
  Falhou
}
```

- Durante o carregamento, impedir inclusões.
- Em sucesso, interpretar o TXT e liberar a verificação.
- Em falha, informar o problema e permitir nova tentativa.

Uma lista carregada vazia é diferente de uma lista ainda indisponível.

## Exercício 3 — verificar a lista externa

1. Em `init`, devolver o modelo e a tarefa `carregar()`.
2. Em `update`, tratar sucesso, falha e nova tentativa.
3. Em `view`, habilitar os botões e exibir o estado do carregamento.

TXT fornecido: um e-mail por linha, com `amsilva@uem.br` e `ana@uem.br`.

A base fornece `carregar`, `ler_emails`, as regras de cadastro e a interface anterior. Completem somente as lacunas de integração com a SHOW.

## Exercício 3 — conferir no playground

1. Ao iniciar, carregar o TXT e mostrar seus endereços.
2. Tentar cadastrar Ana/uem.br: deve ser rejeitado.
3. Cadastrar Bia/uem.br e tentar repetir: só uma inclusão é permitida.
4. Conferir os avisos e os botões durante carregamento, sucesso e falha.

Para demonstrar uma falha, usem uma URL de arquivo inexistente e reiniciem a aplicação.

Depois, restaurem a URL correta e executem novamente.

## O que construímos

De um contador a um cadastro com uma fonte externa:

- O Model representa o que precisa ser lembrado.
- As Msgs representam acontecimentos.
- `update` concentra as transições do modelo.
- `view` descreve a interface.
- As tarefas descrevem operações interpretadas pelo ambiente.

O projeto de funções orienta a construção; os testes essenciais verificam as atualizações puras.

## Material de referência

Notas da disciplina e template: **Marco A. L. Barbosa**.

\small

- [Notas de Programação Funcional](https://github.com/malbarbo/na-progfun)
- [Sgleam no navegador](https://malbarbo.pro.br/sgleam/)
- Código e documentação local: `sgleam/show` e `sgleam/task`.

\normalsize

Material adaptado do template da disciplina, sob CC BY-SA 4.0.

## Avaliação da experiência

Escaneiem o QR code para responder ao formulário.

\begin{center}
\href{https://forms.gle/qXBpH3SE7rtH1E4NA}{\includegraphics[width=4cm]{qr-avaliacao.png}}

\small
\href{https://forms.gle/qXBpH3SE7rtH1E4NA}{forms.gle/qXBpH3SE7rtH1E4NA}
\normalsize
\end{center}

Avaliações críticas também são bem-vindas.

Obrigado pela participação!
