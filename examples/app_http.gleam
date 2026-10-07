// Consulta simulada por respostas predefinidas, sem rede.
import gleam/string
import sgleam/task.{type Task}
import sgleam/task/fake
import sgleam/ui/app
import sgleam/ui/button
import sgleam/ui/element.{type Element}
import sgleam/ui/layout
import sgleam/ui/text
import sgleam/ui/text_input

type Model {
  Model(url: String, preview: String, status: String)
}

type Msg {
  ChangeUrl(String)
  Fetch
}

fn init() -> Task(Model) {
  task.done(Model("https://malbarbo.pro.br", "", "Informe uma URL e consulte."))
}

fn update(model: Model, message: Msg) -> Task(Model) {
  case message {
    ChangeUrl(url) -> task.done(Model(url, "", "URL alterada."))
    Fetch -> {
      use response <- task.get(model.url)
      case response {
        Ok(body) -> {
          task.done(
            Model(
              ..model,
              preview: string.slice(body, 0, 500),
              status: "Resposta simulada. Exibindo até 500 caracteres.",
            ),
          )
        }
        Error(reason) -> {
          task.done(Model(..model, preview: "", status: "Erro: " <> reason))
        }
      }
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  layout.column([
    text.new("Consulta HTTP") |> text.done,
    text_input.new(model.url)
      |> text_input.placeholder("https://exemplo.com")
      |> text_input.on_input(ChangeUrl)
      |> text_input.done,
    button.new("Consultar") |> button.on_press(Fetch) |> button.done,
    text.new(model.status) |> text.done,
    // O conteúdo remoto é mostrado como texto, não como HTML executável.
    text.new(model.preview) |> text.done,
  ])
  |> layout.done
}

pub fn main() {
  app.create(init, view, update)
  |> app.run_with(fn(program) {
    let report =
      fake.run(program, [
        fake.GetResponse(
          "https://malbarbo.pro.br",
          Ok("Conteúdo predefinido do fake."),
        ),
        fake.GetResponse("https://erro.exemplo", Error("Falha simulada")),
      ])
    case report.result {
      Ok(model) -> model
      Error(fake.UnexpectedRequest(fake.Get(url))) ->
        Model(url, "", "URL desconhecida no fake.")
      Error(_) -> Model("", "", "Pedido desconhecido no fake.")
    }
  })
}
