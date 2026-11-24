import gleam/string
import sgleam/check
import sgleam/show/checkbox
import sgleam/show/element.{type Element}
import sgleam/show/layout
import sgleam/show/radio_group
import sgleam/show/simple_app
import sgleam/show/text
import sgleam/show/text_input

type Caixa {
  Original
  Maiusculas
  Minusculas
}

type Model {
  Model(entrada: String, inverter: Bool, caixa: Caixa)
}

type Msg {
  TextoAlterado(String)
  InversaoAlterada(Bool)
  CaixaAlterada(Caixa)
}

fn init() -> Model {
  Model("Gleam", False, Original)
}

/// Inverte a entrada se solicitado e aplica a caixa selecionada.
/// Original preserva a caixa, mas ainda respeita a opção de inversão.
fn transformar(entrada: String, inverter: Bool, caixa: Caixa) -> String {
  let resultado = case inverter {
    True -> string.reverse(entrada)
    False -> entrada
  }
  case caixa {
    Original -> resultado
    Maiusculas -> string.uppercase(resultado)
    Minusculas -> string.lowercase(resultado)
  }
}

pub fn transformar_examples() {
  check.eq(transformar("Gleam", False, Original), "Gleam")
  check.eq(transformar("Gleam", True, Original), "maelG")
  check.eq(transformar("Gleam", False, Maiusculas), "GLEAM")
  check.eq(transformar("Gleam", True, Maiusculas), "MAELG")
  check.eq(transformar("Gleam", False, Minusculas), "gleam")
  check.eq(transformar("Gleam", True, Minusculas), "maelg")
  check.eq(transformar("", True, Maiusculas), "")
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    TextoAlterado(entrada) -> Model(..model, entrada: entrada)
    InversaoAlterada(inverter) -> Model(..model, inverter: inverter)
    CaixaAlterada(caixa) -> Model(..model, caixa: caixa)
  }
}

pub fn update_examples() {
  check.eq(
    update(init(), InversaoAlterada(True)),
    Model("Gleam", True, Original),
  )
  check.eq(
    update(init(), CaixaAlterada(Minusculas)),
    Model("Gleam", False, Minusculas),
  )
  check.eq(update(init(), TextoAlterado("Oi")), Model("Oi", False, Original))
}

fn view(model: Model) -> Element(Msg) {
  layout.column([
    text_input.new(model.entrada)
      |> text_input.on_input(TextoAlterado)
      |> text_input.done,
    layout.row([
      checkbox.new(model.inverter)
        |> checkbox.on_change(InversaoAlterada)
        |> checkbox.done,
      text.new("Inverter texto") |> text.done,
    ])
      |> layout.done,
    radio_group.new()
      |> radio_group.label("Caixa")
      |> radio_group.select(model.caixa)
      |> radio_group.option(Original, "Nenhuma alteração de caixa")
      |> radio_group.option(Maiusculas, "Maiúsculas")
      |> radio_group.option(Minusculas, "Minúsculas")
      |> radio_group.on_select(CaixaAlterada)
      |> radio_group.done,
    text.new(transformar(model.entrada, model.inverter, model.caixa))
      |> text.done,
  ])
  |> layout.done
}

pub fn main() {
  simple_app.create(init, view, update)
  |> simple_app.run
}
