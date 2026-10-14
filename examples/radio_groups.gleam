import gleam/option.{type Option, None, Some}
import sgleam/ui/button
import sgleam/ui/element.{type Element}
import sgleam/ui/layout
import sgleam/ui/radio_group
import sgleam/ui/simple_app
import sgleam/ui/text

type Model {
  Model(first: Option(String), second: Option(String))
}

type Msg {
  First(String)
  Second(String)
  Clear
}

fn init() -> Model {
  Model(None, Some("medio"))
}

fn update(model: Model, message: Msg) -> Model {
  case message {
    First(value) -> Model(..model, first: Some(value))
    Second(value) -> Model(..model, second: Some(value))
    Clear -> Model(None, None)
  }
}

fn view(model: Model) -> Element(Msg) {
  layout.column([
    text.new("Primeiro: " <> option.unwrap(model.first, "Nenhum"))
      |> text.done,
    radio_group.new(model.first)
      |> radio_group.label("Primeiro tamanho")
      |> radio_group.option("pequeno", "Pequeno")
      |> radio_group.option("medio", "Médio")
      |> radio_group.option("grande", "Grande")
      |> radio_group.on_select(First)
      |> radio_group.done,
    text.new("Segundo: " <> option.unwrap(model.second, "Nenhum"))
      |> text.done,
    radio_group.new(model.second)
      |> radio_group.label("Segundo tamanho")
      |> radio_group.option("pequeno", "Pequeno")
      |> radio_group.option("medio", "Médio")
      |> radio_group.option("grande", "Grande")
      |> radio_group.on_select(Second)
      |> radio_group.done,
    button.new("Limpar seleções")
      |> button.on_press(Clear)
      |> button.done,
  ])
  |> layout.done
}

pub fn main() {
  simple_app.create(init, view, update) |> simple_app.run
}