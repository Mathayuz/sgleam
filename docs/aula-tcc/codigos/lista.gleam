import gleam/list
import gleam/string
import sgleam/check
import sgleam/show/element.{type Element}
import sgleam/show/layout
import sgleam/show/text
import sgleam/show/text_input

import sgleam/show/button
import sgleam/show/simple_app

type Model {
  Model(nome: String, dominio: String, emails: List(String), aviso: String)
}

type Msg {
  NomeAlterado(String)
  DominioAlterado(String)
  Adicionar
}

fn init() -> Model {
  Model("", "uem.br", [], "")
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    NomeAlterado(nome) -> Model(..model, nome:, aviso: "")
    DominioAlterado(dominio) -> Model(..model, dominio:, aviso: "")
    Adicionar -> cadastrar(model)
  }
}

pub fn update_examples() {
  let model = Model("Ana", "uem.br", [], "")
  let adicionado = update(model, Adicionar)
  check.eq(adicionado.emails, ["ana@uem.br"])
  check.eq(update(adicionado, Adicionar).emails, ["ana@uem.br"])
  check.eq(update(adicionado, Adicionar).aviso, "E-mail já existente.")
  check.eq(update(adicionado, NomeAlterado("Bia")).emails, ["ana@uem.br"])
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

/// Acrescenta o e-mail ao final da lista se não consta nos cadastrados
/// nem nos reservados. Compara endereços após trim e lowercase.
/// Requer um candidato válido produzido por email.
fn adicionar(
  candidato: String,
  cadastrados: List(String),
  reservados: List(String),
) -> Result(List(String), String) {
  let candidato = normalizar(candidato)
  let ocupados = list.append(cadastrados, reservados) |> list.map(normalizar)
  case list.contains(ocupados, candidato) {
    True -> Error("E-mail já existente.")
    False -> Ok(list.append(cadastrados, [candidato]))
  }
}

fn normalizar(endereco: String) -> String {
  endereco
  |> string.trim
  |> string.lowercase
}

fn cadastrar(model: Model) -> Model {
  let resultado = case email(model.nome, model.dominio) {
    Error(motivo) -> Error(motivo)
    Ok(endereco) -> adicionar(endereco, model.emails, [])
  }
  case resultado {
    Ok(emails) -> Model(..model, emails:, aviso: "E-mail adicionado.")
    Error(aviso) -> Model(..model, aviso:)
  }
}

fn campo_nome(model: Model) -> Element(Msg) {
  text_input.new(model.nome)
  |> text_input.placeholder("Nome completo")
  |> text_input.on_input(NomeAlterado)
  |> text_input.done
}

fn campo_dominio(model: Model) -> Element(Msg) {
  text_input.new(model.dominio)
  |> text_input.placeholder("Domínio sem @")
  |> text_input.on_input(DominioAlterado)
  |> text_input.done
}

fn previa(model: Model) -> String {
  case email(model.nome, model.dominio) {
    Ok(endereco) -> endereco
    Error(motivo) -> motivo
  }
}

fn view(model: Model) -> Element(Msg) {
  layout.column([
    campo_nome(model),
    campo_dominio(model),
    text.new(previa(model))
      |> text.done,
    button.new("Adicionar")
      |> button.on_press(Adicionar)
      |> button.done,
    text.new(model.aviso)
      |> text.done,
    text.new("Cadastrados nesta sessão:")
      |> text.done,
    layout.column(
      list.map(model.emails, fn(endereco) {
        text.new(endereco)
        |> text.done
      }),
    )
      |> layout.done,
  ])
  |> layout.done
}

pub fn main() {
  simple_app.create(init, view, update)
  |> simple_app.run
}
