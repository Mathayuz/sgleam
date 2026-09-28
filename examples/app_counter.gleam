// Efeitos na inicialização e nas atualizações; reset sem efeito.
import gleam/int
import sgleam/task.{type Task}
import sgleam/ui/app
import sgleam/ui/button
import sgleam/ui/element.{type Element}
import sgleam/ui/layout
import sgleam/ui/text

type Msg {
  Increment
  Decrement
  Reset
}

fn init() -> Task(Int) {
  use _ <- task.println("Contador iniciado")
  task.done(0)
}

fn update(model: Int, message: Msg) -> Task(Int) {
  case message {
    Reset -> task.done(0)
    Increment -> change(model, 1)
    Decrement -> change(model, -1)
  }
}

// Uma tarefa pode ser reutilizada para compor diferentes atualizações.
fn change(model: Int, amount: Int) -> Task(Int) {
  let next = model + amount
  use _ <- task.println("Novo valor: " <> int.to_string(next))
  task.done(next)
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
  app.create(init, view, update) |> app.run
}
