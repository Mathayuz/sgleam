# Exemplos de SimpleApp, App e pedidos simulados

| Exemplo | Comportamento |
| --- | --- |
| [simple_counter.gleam](simple_counter.gleam) | Contador com init e update retornando Int diretamente. |
| [app_counter.gleam](app_counter.gleam) | Contador que descreve pedidos de impressão; o fake reconhece as três mensagens e não imprime nada. |
| [app_notes.gleam](app_notes.gleam) | Simula salvar `Minha anotação` em `anotacoes.txt`, sem tocar no disco. Outros pedidos são mostrados como desconhecidos. |
| [app_http.gleam](app_http.gleam) | Simula uma resposta para `https://malbarbo.pro.br` e uma falha para `https://erro.exemplo`, sem rede. Outras URLs são desconhecidas. |
| [task_download.gleam](task_download.gleam) | O main descreve GET, gravação e impressão. O ambiente usa o fake padrão e não produz saída nem arquivo. |
| [task_fake.gleam](task_fake.gleam) | Executa dez verificações com asserções e devolve um resumo de sucesso ao ambiente. |

Na raiz do projeto:

```sh
cargo run -- check examples/app_counter.gleam
cargo run -- check examples/app_notes.gleam
cargo run -- check examples/app_http.gleam
cargo run -- examples/task_download.gleam
cargo run -- examples/task_fake.gleam
```

`task_download` termina silenciosamente. `task_fake` usa `smain`: o ambiente
exibe a lista de verificações aprovadas. Cada verificação compara resultados e históricos
ou valida regras de composição. Uma asserção interrompe o programa em caso de falha. Isso não executa o pedido `Println("Sucesso")`;
a impressão de relatórios é uma capacidade do ambiente de apresentação.

Os exemplos de App usam `app.run_with` para fornecer configurações explícitas
para o fake. A lógica de `init` e `update` constrói descrições e não realiza I/O.
A configuração da simulação pertence à composição com o ambiente em `main`.

O host nativo de UI ainda mostra HTML e encerra o loop, sem janela interativa.
Cliques e digitação exigem o host de eventos web. O fake é escrito em Gleam puro
e não depende de capacidades de HTTP ou arquivo do host. Não houve atualização
do repositório simplecode nesta alteração.

No bloco de notas, os dados iniciais correspondem exatamente à resposta
configurada. Alterar o caminho ou conteúdo demonstra a rejeição de pedidos
desconhecidos; nenhum conteúdo é gravado, mesmo quando a simulação tem sucesso.

Mais detalhes em [Task, SimpleApp e App](../docs/pt-br/tasks.md).

## Galeria visual completa

[ui_gallery.gleam](ui_gallery.gleam) reúne Text, Button, TextInput, TextArea,
Checkbox, Radio, Picker, Link e layouts Row/Column. Inclui controles
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
No App, a mesma opção funciona com run e run_with.
