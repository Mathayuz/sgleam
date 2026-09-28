// Digitar só muda o modelo; salvar executa a gravação e registra o resultado.
// write_file requer o host nativo e substitui o arquivo indicado.
import sgleam/task.{type Task}
import sgleam/ui/app
import sgleam/ui/button
import sgleam/ui/element.{type Element}
import sgleam/ui/layout
import sgleam/ui/text
import sgleam/ui/text_area
import sgleam/ui/text_input

type Model {
  Model(path: String, content: String, status: String)
}

type Msg {
  ChangePath(String)
  Edit(String)
  Save
}

fn init() -> Task(Model) {
  task.done(Model("anotacoes.txt", "", "Escreva uma anotação e salve."))
}

fn update(model: Model, message: Msg) -> Task(Model) {
  case message {
    ChangePath(path) ->
      task.done(Model(..model, path:, status: "Destino alterado."))
    Edit(content) ->
      task.done(Model(..model, content:, status: "Alterações não salvas."))
    Save -> {
      use result <- task.write_file(model.path, model.content)
      let status = case result {
        Ok(_) -> "Salvo em " <> model.path
        Error(reason) -> "Não foi possível salvar: " <> reason
      }
      use _ <- task.println(status)
      task.done(Model(..model, status:))
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  layout.column([
    text.new("Bloco de notas") |> text.done,
    text_input.new(model.path)
      |> text_input.placeholder("Caminho do arquivo")
      |> text_input.on_input(ChangePath)
      |> text_input.done,
    text_area.new(model.content)
      |> text_area.rows(8)
      |> text_area.placeholder("Digite sua anotação")
      |> text_area.on_input(Edit)
      |> text_area.done,
    button.new("Salvar") |> button.on_press(Save) |> button.done,
    text.new(model.status) |> text.done,
  ])
  |> layout.done
}

pub fn main() {
  app.create(init, view, update) |> app.run
}
