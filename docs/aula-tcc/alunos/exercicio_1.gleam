import gleam/list
import gleam/string
import sgleam/check
import sgleam/show/element.{type Element}
import sgleam/show/layout
import sgleam/show/text
import sgleam/show/text_input

import sgleam/show/simple_app

type Model {
  Model(nome: String, dominio: String)
}

type Msg {
  NomeAlterado(String)
  DominioAlterado(String)
}

fn init() -> Model {
  // EXERCÍCIO: nome vazio, domínio uem.br; lista e aviso vazios quando houver.
  todo
}

fn update(model: Model, msg: Msg) -> Model {
  // EXERCÍCIO: trate cada Msg e preserve os outros campos.
  todo
}

pub fn update_examples() {
  let model = Model("Ana", "din.uem.br")
  check.eq(update(model, NomeAlterado("Bia")), Model("Bia", "din.uem.br"))
  check.eq(update(model, DominioAlterado("uem.br")), Model("Ana", "uem.br"))
}

/// Produz as iniciais de todos os nomes anteriores ao último, seguidas
/// pelo último nome; converte para minúsculas e conserva os 8 primeiros
/// caracteres do resultado completo. Um nome só é usado por inteiro.
fn login(nome: String) -> String {
  let partes =
    nome
    |> string.lowercase
    |> string.split(" ")
    |> list.filter(fn(parte) { parte != "" })
  let candidato = case list.reverse(partes) {
    [] -> ""
    [ultimo, ..anteriores] -> {
      let iniciais =
        anteriores
        |> list.reverse
        |> list.map(fn(parte) { string.slice(parte, 0, 1) })
        |> string.join("")
      iniciais <> ultimo
    }
  }
  string.slice(candidato, 0, 8)
}

/// Produz login@dominio normalizado ou erro quando um campo está vazio
/// ou o domínio contém espaço ou @. O domínio é fornecido sem @.
fn email(nome: String, dominio: String) -> Result(String, String) {
  let usuario = login(nome)
  let dominio = dominio |> string.trim |> string.lowercase
  case
    usuario == "",
    dominio == ""
    || string.contains(dominio, " ")
    || string.contains(dominio, "@")
  {
    True, _ -> Error("Informe o nome.")
    _, True -> Error("Informe um domínio sem espaços e sem @.")
    _, _ -> Ok(usuario <> "@" <> dominio)
  }
}

fn previa(model: Model) -> String {
  case email(model.nome, model.dominio) {
    Ok(endereco) -> endereco
    Error(motivo) -> motivo
  }
}

fn view(model: Model) -> Element(Msg) {
  // EXERCÍCIO: construa os inputs com on_input e mostre previa(model).
  text.new("Implemente a interface aqui.")
  |> text.done
}

pub fn main() {
  todo
}
