import gleam/int
import sgleam/check
import sgleam/show/button
import sgleam/show/element.{type Element}
import sgleam/show/layout
import sgleam/show/simple_app
import sgleam/show/text

type Msg {
  Incrementar
  Decrementar
  Zerar
}

fn init() -> Int {
  0
}

/// Produz o próximo valor do contador para a mensagem recebida.
fn update(model: Int, msg: Msg) -> Int {
  case msg {
    Incrementar -> model + 1
    Decrementar -> model - 1
    Zerar -> 0
  }
}

pub fn update_examples() {
  check.eq(update(0, Incrementar), 1)
  check.eq(update(0, Decrementar), -1)
  check.eq(update(12, Zerar), 0)
}

fn view(model: Int) -> Element(Msg) {
  layout.column([
    text.new("Contador: " <> int.to_string(model))
      |> text.done,
    layout.row([
      button.new("-1")
        |> button.on_press(Decrementar)
        |> button.done,
      button.new("+1")
        |> button.on_press(Incrementar)
        |> button.done,
      button.new("Zerar")
        |> button.on_press(Zerar)
        |> button.done,
    ])
      |> layout.done,
  ])
  |> layout.done
}

pub fn main() {
  simple_app.create(init, view, update)
  |> simple_app.run
}
