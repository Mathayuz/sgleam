# Exemplos de SimpleApp, App e efeitos web simulados

| Exemplo | Comportamento |
| --- | --- |
| [simple_counter.gleam](simple_counter.gleam) | Contador sem tarefas. |
| [app_counter.gleam](app_counter.gleam) | Contador com botão para solicitar um incremento após 1000 ms; o fake confirma imediatamente. |
| [app_http.gleam](app_http.gleam) | GET com sucesso inicial, falha de rede em `https://erro.exemplo` e aviso para URLs desconhecidas. |
| [app_notes.gleam](app_notes.gleam) | POST de uma anotação. Na URL inicial, `Minha anotação` simula 201, `erro` simula 500 e outros corpos são desconhecidos. |
| [app_wake_up.gleam](app_wake_up.gleam) | Contagem de 3 até 0, com três wake-ups simulados de 1000 ms, encerrando com stop_when. |
| [task_web.gleam](task_web.gleam) | GET -> POST -> wake_up, com resultado final 0 ou 1 e sem I/O. Substitui task_download. |
| [task_fake.gleam](task_fake.gleam) | Doze verificações com asserções sobre pedidos, erros, composição e mensagens. |

Na raiz do projeto:

```sh
cargo run -- check examples/app_counter.gleam
cargo run -- check examples/app_notes.gleam
cargo run -- check examples/app_http.gleam
cargo run -- check examples/app_wake_up.gleam
cargo run -- examples/task_web.gleam
cargo run -- examples/task_fake.gleam
```

`task_web` termina silenciosamente. `task_fake` entrega uma lista de resultados
OK ao ambiente por meio de `smain`. O fake não imprime esse relatório.

Nos Apps, init/update retornam `#(Model, Task(Msg))`. `task.done(msg)` produz uma
mensagem para update; `task.none()` termina sem mensagem. `fake.messages` é o
adaptador simples de run_with; `fake.run_messages` permite tratar falhas de
configuração e examinar o histórico. Falhas de configuração do fake são distintas
de erros HTTP simulados.

Para interagir, copie o exemplo completo para o playground, carregue e execute
`main()`. Após atualizar a biblioteca, reconstrua o WASM do SimpleCode e
recarregue a página. A execução nativa apresenta HTML, sem janela interativa.

**Somente o fake está implementado:** nenhum GET ou POST acessa a rede e wake_up
não aguarda o relógio. A contagem pode chegar a zero antes de o navegador pintar
as telas intermediárias. O intervalo é registrado e exige uma resposta exata.
Não use uma repetição infinita de wake_up com o fake imediato.

Mais detalhes e comparação com Elm, Fetch e reqwest em
[Task e efeitos web](../docs/pt-br/tasks.md).

## Galeria visual completa

[ui_gallery.gleam](ui_gallery.gleam) reúne Text, Button, TextInput, TextArea,
Checkbox, RadioGroup, Picker, Link e layouts Row/Column. Inclui controles
desabilitados, placeholders, botões com textos curtos e longos e um status
da última interação. Usa SimpleApp e atualizações diretas do modelo.

Copie o arquivo completo para o editor do playground, carregue-o e execute
`main()` no REPL. Compare botões em linha e em coluna, teste Enter no campo
de nome, seleção e digitação. O link externo abre o site do Gleam em uma nova aba (`link.new_tab(True)`).
O botão de restaurar devolve todos os valores ao estado inicial.

A galeria utiliza os estilos existentes do host, sem acrescentar CSS próprio,
para que diferenças de largura, alinhamento e espaçamento fiquem visíveis.

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
No App, a mesma opção funciona com run e run_with. A tarefa associada ao
modelo final não é interpretada.

## Radios com builder

[radio_groups.gleam](radio_groups.gleam) demonstra valores tipados, dois grupos
independentes e um botão para limpar as seleções. `radio_group.new(None)` inicia
sem seleção; `radio_group.new(Some(value))` seleciona uma opção. Adicione opções
com `option(value, label)` e finalize com `done`. A galeria também usa essa API.
Veja [o guia](../docs/pt-br/radio-group.md).

## Alinhamento padrão de column

`layout.column` alinha os filhos ao início e preserva a largura natural dos
componentes, sem esticá-los horizontalmente. Não é necessário usar uma row
apenas para evitar que um botão, input ou picker preencha a coluna.
