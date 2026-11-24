from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
COD = ROOT / 'codigos'
ALUNOS = ROOT / 'alunos'

def testes_essenciais(name, content):
    if name not in {'login.gleam', 'lista.gleam', 'efeitos.gleam'}:
        return content
    content = re.sub(r'(?ms)^pub fn \w+_examples\(\).*?^}\n*', '', content)
    if name == 'efeitos.gleam':
        return content.replace('import sgleam/check\n', '').replace('import sgleam/task/fake\n', '')
    if name == 'login.gleam':
        return content + '''
pub fn init_examples() {
  check.eq(init(), Model("", "uem.br"))
}

pub fn update_examples() {
  let model = Model("Ana", "din.uem.br")
  check.eq(update(model, NomeAlterado("Bia")), Model("Bia", "din.uem.br"))
  check.eq(update(model, DominioAlterado("uem.br")), Model("Ana", "uem.br"))
}
'''
    return content + '''
pub fn init_examples() {
  check.eq(init(), Model("", "uem.br", [], ""))
}

pub fn update_examples() {
  let model = Model("Ana", "uem.br", [], "")
  let adicionado = update(model, Adicionar)
  check.eq(adicionado.emails, ["ana@uem.br"])
  check.eq(update(adicionado, Adicionar).emails, ["ana@uem.br"])
  check.eq(update(adicionado, Adicionar).aviso, "E-mail já existente.")
  check.eq(update(adicionado, NomeAlterado("Bia")).emails, ["ana@uem.br"])
}
'''

def save(name, content):
    if '--bases' not in sys.argv:
        (COD / name).write_text(testes_essenciais(name, content).strip() + '\n', encoding='utf-8')

counter = '''
import gleam/int
import sgleam/check
import sgleam/show/button
import sgleam/show/element.{type Element}
import sgleam/show/layout
import sgleam/show/simple_app
import sgleam/show/text

type Msg { Incrementar Decrementar Zerar }

fn init() -> Int { 0 }

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
    text.new("Contador: " <> int.to_string(model)) |> text.done,
    layout.row([
      button.new("-1") |> button.on_press(Decrementar) |> button.done,
      button.new("+1") |> button.on_press(Incrementar) |> button.done,
      button.new("Zerar") |> button.on_press(Zerar) |> button.done,
    ]) |> layout.done,
  ]) |> layout.done
}

pub fn main() {
  simple_app.create(init, view, update) |> simple_app.run
}
'''
save('contador.gleam', counter)

text_example = '''
import gleam/string
import sgleam/check
import sgleam/show/checkbox
import sgleam/show/element.{type Element}
import sgleam/show/layout
import sgleam/show/radio_group
import sgleam/show/simple_app
import sgleam/show/text
import sgleam/show/text_input

type Caixa { Original Maiusculas Minusculas }
type Model { Model(entrada: String, inverter: Bool, caixa: Caixa) }
type Msg {
  TextoAlterado(String)
  InversaoAlterada(Bool)
  CaixaAlterada(Caixa)
}

fn init() -> Model { Model("Gleam", False, Original) }

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
    TextoAlterado(entrada) -> Model(..model, entrada:)
    InversaoAlterada(inverter) -> Model(..model, inverter:)
    CaixaAlterada(caixa) -> Model(..model, caixa:)
  }
}

pub fn update_examples() {
  check.eq(update(init(), InversaoAlterada(True)), Model("Gleam", True, Original))
  check.eq(update(init(), CaixaAlterada(Minusculas)), Model("Gleam", False, Minusculas))
  check.eq(update(init(), TextoAlterado("Oi")), Model("Oi", False, Original))
}

fn view(model: Model) -> Element(Msg) {
  layout.column([
    text_input.new(model.entrada)
      |> text_input.on_input(TextoAlterado) |> text_input.done,
    layout.row([
      checkbox.new(model.inverter)
        |> checkbox.on_change(InversaoAlterada) |> checkbox.done,
      text.new("Inverter texto") |> text.done,
    ]) |> layout.done,
    radio_group.new()
      |> radio_group.label("Caixa")
      |> radio_group.select(model.caixa)
      |> radio_group.option(Original, "Nenhuma alteração de caixa")
      |> radio_group.option(Maiusculas, "Maiúsculas")
      |> radio_group.option(Minusculas, "Minúsculas")
      |> radio_group.on_select(CaixaAlterada) |> radio_group.done,
    text.new(transformar(model.entrada, model.inverter, model.caixa)) |> text.done,
  ]) |> layout.done
}

pub fn main() {
  simple_app.create(init, view, update) |> simple_app.run
}
'''
save('texto.gleam', text_example)

imports = '''
import gleam/list
import gleam/string
import sgleam/check
import sgleam/show/element.{type Element}
import sgleam/show/layout
import sgleam/show/text
import sgleam/show/text_input
'''
rules = '''
/// Produz as iniciais de todos os nomes anteriores ao último, seguidas
/// pelo último nome; converte para minúsculas e conserva os 8 primeiros
/// caracteres do resultado completo. Um nome só é usado por inteiro.
/// Ignora espaços comuns extras; entrada vazia produz "".
/// Escopo da oficina: nomes com letras ASCII e espaços comuns.
fn login(nome: String) -> String {
  let partes = nome |> string.lowercase |> string.split(" ")
    |> list.filter(fn(parte) { parte != "" })
  let candidato = case list.reverse(partes) {
    [] -> ""
    [ultimo, ..anteriores] -> {
      let iniciais = anteriores |> list.reverse
        |> list.map(fn(parte) { string.slice(parte, 0, 1) })
        |> string.join("")
      iniciais <> ultimo
    }
  }
  string.slice(candidato, 0, 8)
}

/// Produz login@dominio normalizado ou erro quando um campo está vazio
/// ou o domínio contém espaço ou @. O domínio é fornecido sem @.
/// Esta é uma validação didática, não um validador geral de e-mail.
fn email(nome: String, dominio: String) -> Result(String, String) {
  let usuario = login(nome)
  let dominio = dominio |> string.trim |> string.lowercase
  case usuario == "", dominio == "" || string.contains(dominio, " ")
    || string.contains(dominio, "@") {
    True, _ -> Error("Informe o nome.")
    _, True -> Error("Informe um domínio sem espaços e sem @.")
    _, _ -> Ok(usuario <> "@" <> dominio)
  }
}

pub fn login_examples() {
  check.eq(login("Ana Maria Silva"), "amsilva")
  check.eq(login("Ana"), "ana")
  check.eq(login("  Ana   Silva  "), "asilva")
  check.eq(login("Ana de Souza"), "adsouza")
  check.eq(login("Ana Maria Nascimento"), "amnascim")
  check.eq(login(""), "")
  check.eq(login("    "), "")
}

pub fn email_examples() {
  check.eq(email("Ana Maria Silva", " UEM.BR "), Ok("amsilva@uem.br"))
  check.eq(email("", "uem.br"), Error("Informe o nome."))
  check.eq(email("Ana", ""), Error("Informe um domínio sem espaços e sem @."))
  check.eq(email("Ana", "@uem.br"), Error("Informe um domínio sem espaços e sem @."))
}
'''
form = '''
fn campo_nome(model: Model) -> Element(Msg) {
  text_input.new(model.nome) |> text_input.placeholder("Nome completo")
    |> text_input.on_input(NomeAlterado) |> text_input.done
}

fn campo_dominio(model: Model) -> Element(Msg) {
  text_input.new(model.dominio) |> text_input.placeholder("Domínio sem @")
    |> text_input.on_input(DominioAlterado) |> text_input.done
}

fn previa(model: Model) -> String {
  case email(model.nome, model.dominio) {
    Ok(endereco) -> endereco
    Error(motivo) -> motivo
  }
}
'''
login_app = imports + '''
import sgleam/show/simple_app

type Model { Model(nome: String, dominio: String) }
type Msg { NomeAlterado(String) DominioAlterado(String) }
fn init() -> Model { Model("", "uem.br") }

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    NomeAlterado(nome) -> Model(..model, nome:)
    DominioAlterado(dominio) -> Model(..model, dominio:)
  }
}

pub fn update_examples() {
  check.eq(update(init(), NomeAlterado("Ana")), Model("Ana", "uem.br"))
  check.eq(update(init(), DominioAlterado("din.uem.br")), Model("", "din.uem.br"))
}
''' + rules + form + '''
fn view(model: Model) -> Element(Msg) {
  layout.column([
    text.new("Gerador de login e e-mail") |> text.done,
    campo_nome(model), campo_dominio(model),
    text.new(previa(model)) |> text.done,
  ]) |> layout.done
}

pub fn main() {
  simple_app.create(init, view, update) |> simple_app.run
}
'''
save('login.gleam', login_app)

add_rule = '''
/// Acrescenta o e-mail ao final da lista se não consta nos cadastrados
/// nem nos reservados. Compara endereços após trim e lowercase.
/// Requer um candidato válido produzido por email.
fn adicionar(candidato: String, cadastrados: List(String), reservados: List(String))
  -> Result(List(String), String) {
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

pub fn adicionar_examples() {
  check.eq(adicionar("ana@uem.br", [], []), Ok(["ana@uem.br"]))
  check.eq(adicionar("bia@uem.br", ["ana@uem.br"], []), Ok(["ana@uem.br", "bia@uem.br"]))
  check.eq(adicionar("ANA@uem.br", ["ana@uem.br"], []), Error("E-mail já existente."))
  check.eq(adicionar("ana@uem.br", [], [" ANA@UEM.BR "]), Error("E-mail já existente."))
  check.eq(adicionar("ana@outro.br", ["ana@uem.br"], []), Ok(["ana@uem.br", "ana@outro.br"]))
}
'''
local_add = '''
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
'''
list_app = imports + '''
import sgleam/show/simple_app
import sgleam/show/button

type Model {
  Model(nome: String, dominio: String, emails: List(String), aviso: String)
}
type Msg { NomeAlterado(String) DominioAlterado(String) Adicionar }
fn init() -> Model { Model("", "uem.br", [], "") }

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    NomeAlterado(nome) -> Model(..model, nome:, aviso: "")
    DominioAlterado(dominio) -> Model(..model, dominio:, aviso: "")
    Adicionar -> cadastrar(model)
  }
}
''' + rules + add_rule + local_add + form + '''
pub fn update_examples() {
  let preenchido = Model("Ana", "uem.br", [], "")
  let um = update(preenchido, Adicionar)
  check.eq(um.emails, ["ana@uem.br"])
  check.eq(update(um, Adicionar).emails, ["ana@uem.br"])
  check.eq(update(um, Adicionar).aviso, "E-mail já existente.")
  check.eq(update(um, NomeAlterado("Bia")).emails, ["ana@uem.br"])
  check.eq(update(init(), Adicionar).emails, [])
}

fn view(model: Model) -> Element(Msg) {
  layout.column([
    campo_nome(model), campo_dominio(model),
    text.new(previa(model)) |> text.done,
    button.new("Adicionar") |> button.on_press(Adicionar) |> button.done,
    text.new(model.aviso) |> text.done,
    text.new("Cadastrados nesta sessão:") |> text.done,
    layout.column(list.map(model.emails, fn(endereco) {
      text.new(endereco) |> text.done
    })) |> layout.done,
  ]) |> layout.done
}

pub fn main() {
  simple_app.create(init, view, update) |> simple_app.run
}
'''
save('lista.gleam', list_app)

effects = imports + '''
import sgleam/show/app
import sgleam/show/button
import sgleam/task.{type Task}
import sgleam/task/fake

// TXT servido junto ao playground; a URL é relativa à página do editor.
const url = "emails-existentes.txt"

type Estado { Carregando Pronto(List(String)) Falhou }
type Model {
  Model(nome: String, dominio: String, emails: List(String), estado: Estado, aviso: String)
}
type Msg {
  NomeAlterado(String) DominioAlterado(String) Adicionar Recarregar
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
/// Ignora linhas vazias e normaliza espaços e caixa; aceita LF e CRLF.
/// A validade de cada endereço é uma pré-condição da fonte didática.
fn ler_emails(conteudo: String) -> List(String) {
  conteudo |> string.split("\\n") |> list.map(normalizar)
    |> list.filter(fn(endereco) { endereco != "" })
}

fn update(model: Model, msg: Msg) -> #(Model, Task(Msg)) {
  case msg {
    NomeAlterado(nome) -> #(Model(..model, nome:, aviso: ""), task.none())
    DominioAlterado(dominio) -> #(Model(..model, dominio:, aviso: ""), task.none())
    Recarregar -> #(Model(..model, estado: Carregando, aviso: ""), carregar())
    Recebidos(Ok(conteudo)) -> #(
      Model(..model, estado: Pronto(ler_emails(conteudo)), aviso: "Lista disponível."),
      task.none(),
    )
    Recebidos(Error(_)) -> #(
      Model(..model, estado: Falhou, aviso: "Falha ao obter lista. Tente novamente."),
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
''' + rules + add_rule + form + '''
fn view(model: Model) -> Element(Msg) {
  let pronto = case model.estado { Pronto(_) -> True _ -> False }
  let carregando = model.estado == Carregando
  layout.column([
    text.new("Cadastro com lista externa") |> text.done,
    campo_nome(model), campo_dominio(model),
    text.new(previa(model)) |> text.done,
    button.new("Adicionar") |> button.enabled(pronto)
      |> button.on_press(Adicionar) |> button.done,
    button.new("Carregar novamente") |> button.enabled(!carregando)
      |> button.on_press(Recarregar) |> button.done,
    text.new(case model.estado {
      Carregando -> "Carregando..."
      Pronto(_) -> "Lista externa disponível."
      Falhou -> "Lista externa indisponível."
    }) |> text.done,
    text.new(model.aviso) |> text.done,
    text.new("E-mails existentes no TXT:") |> text.done,
    layout.column(case model.estado {
      Pronto(reservados) ->
        list.map(reservados, fn(endereco) { text.new(endereco) |> text.done })
      _ -> []
    }) |> layout.done,
    text.new("Cadastrados nesta sessão:") |> text.done,
    layout.column(list.map(model.emails, fn(endereco) {
      text.new(endereco) |> text.done
    })) |> layout.done,
  ]) |> layout.done
}

pub fn ler_emails_examples() {
  check.eq(ler_emails(""), [])
  check.eq(ler_emails(" ANA@UEM.BR \\r\\n\\r\\n bia@uem.br\\n"), ["ana@uem.br", "bia@uem.br"])
}

pub fn carregar_examples() {
  let report = fake.run_messages(carregar(), [fake.GetResponse(url, Ok("ana@uem.br\\n"))])
  check.eq(report.requests, [fake.Get(url)])
  check.eq(report.result, Ok([Recebidos(Ok("ana@uem.br\\n"))]))
  let falha = fake.run_messages(carregar(), [fake.GetResponse(url, Error(task.NetworkError))])
  check.eq(falha.result, Ok([Recebidos(Error(task.NetworkError))]))
}

pub fn update_examples() {
  let #(inicio, pedido) = init()
  check.eq(inicio.estado, Carregando)
  check.eq(fake.run_messages(pedido, [fake.GetResponse(url, Ok(""))]).requests, [fake.Get(url)])
  let #(preenchido, _) = update(inicio, NomeAlterado("Ana"))
  let #(bloqueado, _) = update(preenchido, Adicionar)
  check.eq(bloqueado.emails, [])
  let #(pronto, sem_tarefa) = update(preenchido, Recebidos(Ok("ana@uem.br\\n")))
  check.eq(pronto.estado, Pronto(["ana@uem.br"]))
  check.eq(fake.run_messages(sem_tarefa, []).requests, [])
  let #(repetido, _) = update(pronto, Adicionar)
  check.eq(repetido.emails, [])
  check.eq(repetido.aviso, "E-mail já existente.")
  let #(bia, _) = update(pronto, NomeAlterado("Bia"))
  let #(cadastrado, _) = update(bia, Adicionar)
  check.eq(cadastrado.emails, ["bia@uem.br"])
  let #(duplicado, _) = update(cadastrado, Adicionar)
  check.eq(duplicado.emails, ["bia@uem.br"])
  let #(falhou, _) = update(bia, Recebidos(Error(task.Timeout)))
  check.eq(falhou.estado, Falhou)
  check.eq(cadastrar(falhou).emails, [])
  let #(tentando, tarefa) = update(falhou, Recarregar)
  check.eq(tentando.estado, Carregando)
  check.eq(fake.run_messages(tarefa, [fake.GetResponse(url, Ok(""))]).requests, [fake.Get(url)])
  let #(vazio, _) = update(bia, Recebidos(Ok("")))
  check.eq(cadastrar(vazio).emails, ["bia@uem.br"])
}

pub fn main() {
  app.create(init, view, update) |> app.run
}
'''
save('efeitos.gleam', effects)

def replace_function(source, name, body):
    match = re.search(r'(?m)^(?:pub )?fn ' + name + r'\(', source)
    if not match:
        raise ValueError(name)
    opening = source.index('{', match.start())
    depth = 1
    end = opening + 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[:opening+1] + '\n  // EXERCÍCIO: substitua esta base pela sua implementação.\n  ' + body + '\n' + source[end-1:]

# As bases são derivadas dos gabaritos atuais. --bases preserva os exemplos
# editados manualmente e regenera somente o material dos alunos.
for numero, arquivo in enumerate(['login.gleam', 'lista.gleam', 'efeitos.gleam'], 1):
    source = (COD / arquivo).read_text(encoding='utf-8')
    source = '// FOCO: init, update e view. As regras auxiliares estão prontas.\n' + source
    if numero < 3:
        # Os alunos escrevem os componentes e seus callbacks dentro de view.
        # Remover os helpers de UI evita entregar essa ligação já resolvida.
        for name in ['campo_nome', 'campo_dominio']:
            source = replace_function(source, name, 'text.new("") |> text.done')
            source = re.sub(r'(?ms)^fn ' + name + r'\(.*?^}\n\n', '', source, count=1)
        init_body = 'Model("", "")' if numero == 1 else 'Model("", "", [], "")'
        source = replace_function(source, 'init', init_body)
        source = replace_function(source, 'update', 'model')
        source = replace_function(source, 'view', 'text.new("Implemente a interface aqui.") |> text.done')
        expected = 'Model("", "uem.br")' if numero == 1 else 'Model("", "uem.br", [], "")'
        if 'pub fn init_examples()' not in source:
            source += '\npub fn init_examples() {\n  check.eq(init(), ' + expected + ')\n}\n'
        source = source.replace('// EXERCÍCIO: substitua esta base pela sua implementação.\n  Model(', '// EXERCÍCIO: nome vazio, domínio uem.br; lista e aviso vazios quando houver.\n  Model(', 1)
        update_hint = '\n  // Use cadastrar(model) ao receber Adicionar.' if numero == 2 else ''
        view_hint = '\n  // Inclua botão com on_press, aviso e lista de e-mails.' if numero == 2 else ''
        source = source.replace('// EXERCÍCIO: substitua esta base pela sua implementação.\n  model', '// EXERCÍCIO: trate cada Msg e preserve os outros campos.' + update_hint + '\n  model', 1)
        source = source.replace('// EXERCÍCIO: substitua esta base pela sua implementação.\n  text.new', '// EXERCÍCIO: construa os inputs com on_input e mostre previa(model).' + view_hint + '\n  text.new', 1)
    else:
        # Reutilizar o exercício 2 deixa tempo para o novo ciclo com tarefas.
        source = replace_function(source, 'init', '#(Model("", "uem.br", [], Carregando, ""), task.none())')
        for pattern, replacement in [
            ('Recarregar -> #(Model(..model, estado: Carregando, aviso: ""), carregar())', 'Recarregar -> #(model, task.none()) // EXERCÍCIO: voltar a Carregando e solicitar carregar().'),
            ('estado: Pronto(ler_emails(conteudo)),', 'estado: Pronto([]), // EXERCÍCIO: guardar ler_emails(conteudo).'),
            ('estado: Falhou,', 'estado: Carregando, // EXERCÍCIO: representar a falha. '),
        ]:
            source, count = re.subn(re.escape(pattern), lambda _: replacement, source)
            if count != 1:
                raise ValueError(f'Base 3: trecho não encontrado exatamente uma vez: {pattern}')
        source = source.replace('let pronto = case model.estado {\n    Pronto(_) -> True\n    _ -> False\n  }', 'let pronto = False // EXERCÍCIO: habilitar Adicionar somente em Pronto.')
        source = source.replace('let pronto = case model.estado { Pronto(_) -> True _ -> False }', 'let pronto = False // EXERCÍCIO: habilitar Adicionar somente em Pronto.')
        source = source.replace('let carregando = model.estado == Carregando', 'let carregando = True // EXERCÍCIO: impedir nova tentativa enquanto carrega.')
        source = source.replace('// EXERCÍCIO: substitua esta base pela sua implementação.', '// EXERCÍCIO: devolver o modelo inicial e a tarefa carregar().', 1)
        source = source.replace('Carregando -> "Carregando..."\n      Pronto(_) -> "Lista externa disponível."\n      Falhou -> "Lista externa indisponível."', '_ -> "EXERCÍCIO: mostrar o estado do carregamento."')
    (ALUNOS / f'exercicio_{numero}.gleam').write_text(source.strip() + '\n', encoding='utf-8')
(ROOT / 'emails-existentes.txt').write_text('amsilva@uem.br\nana@uem.br\n', encoding='utf-8')
print('3 bases focadas em init/update/view e TXT gerados; soluções preservadas com --bases.')

