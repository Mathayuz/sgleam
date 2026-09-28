// Contador com SimpleApp: init e update retornam o modelo diretamente.
import gleam/int
import sgleam/ui/button
import sgleam/ui/element.{type Element}
import sgleam/ui/layout
import sgleam/ui/simple_app
import sgleam/ui/text

type Msg {
  Increment
  Decrement
  Reset
}

fn init() -> Int {
  0
}

fn update(model: Int, message: Msg) -> Int {
  case message {
    Increment -> model + 1
    Decrement -> model - 1
    Reset -> 0
  }
}

fn view(model: Int) -> Element(Msg) {
  layout.column([
    text.new("Contador: " <> int.to_string(model)) |> text.done,
    layout.row([
      button.new("-1") |> button.on_press(Decrement) |> button.done,
      button.new("+1") |> button.on_press(Increment) |> button.done,
      button.new("Zerar") |> button.on_press(Reset) |> button.done,
    ])
      |> layout.done,
  ])
  |> layout.done
}

pub fn main() {
  simple_app.create(init, view, update) |> simple_app.run
}
