# Exemplos de SimpleApp e App

O [simple_counter.gleam](simple_counter.gleam) é um contador com `SimpleApp`:
`init` retorna `Int`, e `update` calcula o próximo `Int` diretamente. Ele tem
botões para diminuir, aumentar e zerar, sem tarefas ou impressão na lógica do
modelo. Compare-o com `app_counter.gleam`, que usa tarefas para imprimir.

Os exemplos com prefixo `app_` utilizam `sgleam/ui/app`: `init` e `update` retornam
`Task(model)`, e o executor da aplicação executa essas tarefas.

| Exemplo | O que demonstra |
| --- | --- |
| [app_counter.gleam](app_counter.gleam) | Impressão na inicialização e ao incrementar/decrementar; reset com `task.done` sem impressão. |
| [app_notes.gleam](app_notes.gleam) | Edição sem I/O e gravação explícita ao salvar, com sucesso ou erro no modelo e no console. |
| [app_http.gleam](app_http.gleam) | GET ao clicar, tratamento de erros e prévia textual de até 500 caracteres da resposta. |

## Como verificar e executar

Na raiz do repositório, confira os exemplos sem executar seus efeitos:

```sh
cargo run -- check examples/simple_counter.gleam
cargo run -- check examples/app_counter.gleam
cargo run -- check examples/app_notes.gleam
cargo run -- check examples/app_http.gleam
```

Para executar a inicialização de um exemplo no CLI:

```sh
cargo run -- examples/simple_counter.gleam
```

O host nativo atual imprime o HTML e encerra o loop: **não abre uma janela e
não recebe cliques ou digitação**. A interação exige um host com suporte aos
eventos de UI, como a integração web, usando uma versão atualizada deste engine.
O simplecode não foi atualizado junto com estes exemplos.

O contador usa apenas impressão como efeito e não precisa de HTTP ou arquivos.
Já os exemplos de notas e HTTP combinam UI com capacidades que, atualmente,
existem apenas no host nativo. No host WASM, salvar ou consultar retorna `Error`,
e esses exemplos mostram a mensagem na interface. Portanto, a combinação de
UI interativa com sucesso de HTTP/gravação ainda depende de integrar essas
capacidades no mesmo host; os exemplos não adicionam essa integração.

As tarefas são síncronas. A consulta não mostra um estado intermediário de
carregamento: o próximo modelo é renderizado após a operação terminar.
Nenhum dos exemplos de notas ou HTTP grava arquivos ou acessa a rede em `init`.
Salvar substitui o arquivo escolhido, com caminho relativo ao diretório atual
do processo, e não cria diretórios intermediários.

## Roteiro de leitura

1. Comece pelo contador para acompanhar `init → Task(Int)`, `view` e `update`.
2. No bloco de notas, compare `Edit`, que usa apenas `task.done`, com `Save`,
   que encadeia `write_file` e `println` antes de devolver o modelo.
3. Na consulta HTTP, observe como cada ramo de `Result` termina em `Task(Model)`.
   O corpo remoto é renderizado como texto escapado, não inserido como HTML.

A explicação completa da implementação está em
[Task, SimpleApp e App](../docs/pt-br/tasks.md).
