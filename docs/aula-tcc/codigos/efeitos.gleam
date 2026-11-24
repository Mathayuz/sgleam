import gleam/list
import gleam/string
import sgleam/show/element.{type Element}
import sgleam/show/layout
import sgleam/show/text
import sgleam/show/text_input

import sgleam/show/app
import sgleam/show/button
import sgleam/task.{type Task}

// TXT da internet.
const url =
  "https://raw.githubusercontent.com/Mathayuz/sgleam/refs/heads/tcc/docs/aula-tcc/emails-existentes.txt"

type Estado {
  Carregando
  Pronto(List(String))
  Falhou
}

type Model {
  Model(
    nome: String,
    dominio: String,
    emails: List(String),
    estado: Estado,
    aviso: String,
  )
}

type Msg {
  NomeAlterado(String)
  DominioAlterado(String)
  Adicionar
  Recarregar
  Recebidos(Result(String, task.HttpError))
}

fn init() -> #(Model, Task(Msg)) {
  #(Model("", "uem.br", [], Carregando, ""), carregar())
}

/// Descreve a obtenção do TXT e transforma o resultado em mensagem.
fn carregar() -> Task(Msg) {
  use resultado <- task.get(url)
  task.done(Recebidos(resultado))
}

/// Interpreta um TXT confiável, com um e-mail por linha.
fn ler_emails(conteudo: String) -> List(String) {
  conteudo
  |> string.split("\n")
  |> list.map(normalizar)
  |> list.filter(fn(endereco) { endereco != "" })
}

fn update(model: Model, msg: Msg) -> #(Model, Task(Msg)) {
  case msg {
    NomeAlterado(nome) -> #(Model(..model, nome:, aviso: ""), task.none())
    DominioAlterado(dominio) -> #(
      Model(..model, dominio:, aviso: ""),
      task.none(),
    )
    Recarregar -> #(Model(..model, estado: Carregando, aviso: ""), carregar())
    Recebidos(Ok(conteudo)) -> #(
      Model(
        ..model,
        estado: Pronto(ler_emails(conteudo)),
        aviso: "Lista disponível.",
      ),
      task.none(),
    )
    Recebidos(Error(_)) -> #(
      Model(
        ..model,
        estado: Falhou,
        aviso: "Falha ao obter lista. Tente novamente.",
      ),
      task.none(),
    )
    Adicionar -> #(cadastrar(model), task.none())
  }
}

fn cadastrar(model: Model) -> Model {
  case model.estado {
    Carregando -> Model(..model, aviso: "Aguarde a lista.")
    Falhou -> Model(..model, aviso: "Carregue a lista antes de cadastrar.")
    Pronto(reservados) -> {
      let resultado = case email(model.nome, model.dominio) {
        Error(motivo) -> Error(motivo)
        Ok(endereco) -> adicionar(endereco, model.emails, reservados)
      }
      case resultado {
        Ok(emails) -> Model(..model, emails:, aviso: "E-mail adicionado.")
        Error(aviso) -> Model(..model, aviso:)
      }
    }
  }
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
  endereco |> string.trim |> string.lowercase
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
  let pronto = case model.estado {
    Pronto(_) -> True
    _ -> False
  }
  let carregando = model.estado == Carregando
  layout.column([
    text.new("Cadastro com lista externa") |> text.done,
    campo_nome(model),
    campo_dominio(model),
    text.new(previa(model)) |> text.done,
    button.new("Adicionar")
      |> button.enabled(pronto)
      |> button.on_press(Adicionar)
      |> button.done,
    button.new("Carregar novamente")
      |> button.enabled(!carregando)
      |> button.on_press(Recarregar)
      |> button.done,
    text.new(case model.estado {
      Carregando -> "Carregando..."
      Pronto(_) -> "Lista externa disponível."
      Falhou -> "Lista externa indisponível."
    })
      |> text.done,
    text.new(model.aviso) |> text.done,
    text.new("E-mails existentes no TXT:") |> text.done,
    layout.column(case model.estado {
      Pronto(reservados) ->
        list.map(reservados, fn(endereco) { text.new(endereco) |> text.done })
      _ -> []
    })
      |> layout.done,
    text.new("Cadastrados nesta sessão:") |> text.done,
    layout.column(
      list.map(model.emails, fn(endereco) { text.new(endereco) |> text.done }),
    )
      |> layout.done,
  ])
  |> layout.done
}

pub fn main() {
  app.create(init, view, update)
  |> app.run
}
