// Verificações puras: uma asserção interrompe o exemplo se houver divergência.
// smain devolve o resumo; somente o ambiente apresenta esse resumo.
import gleam/int
import sgleam/task.{type Task}
import sgleam/task/fake

fn program() -> Task(Int) {
  use get <- task.get("https://malbarbo.pro.br")
  case get {
    Ok(content) -> {
      use write <- task.write_file("arquivo.txt", content)
      case write {
        Ok(_) -> {
          use _ <- task.println("Sucesso")
          task.done(0)
        }
        Error(_) -> {
          use _ <- task.println("erro no write_file")
          task.done(1)
        }
      }
    }
    Error(_) -> {
      use _ <- task.println("erro no get")
      task.done(1)
    }
  }
}

// Compara o relatório inteiro: resultado, argumentos e ordem dos pedidos.
fn success() -> String {
  let expected =
    fake.Report(Ok(0), [
      fake.Get("https://malbarbo.pro.br"),
      fake.WriteFile("arquivo.txt", "conteúdo de demonstração"),
      fake.Println("Sucesso"),
    ])
  let assert True = fake.run(program(), fake.demo_responses()) == expected
  "OK: sucesso e histórico completo"
}

fn get_error() -> String {
  let report =
    fake.run(program(), [
      fake.GetResponse("https://malbarbo.pro.br", Error("offline")),
      fake.PrintlnResponse("erro no get"),
    ])
  let assert True =
    report
    == fake.Report(Ok(1), [
      fake.Get("https://malbarbo.pro.br"),
      fake.Println("erro no get"),
    ])
  "OK: erro de GET não solicita gravação"
}

fn write_error() -> String {
  let report =
    fake.run(program(), [
      fake.GetResponse("https://malbarbo.pro.br", Ok("texto")),
      fake.WriteFileResponse("arquivo.txt", "texto", Error("sem permissão")),
      fake.PrintlnResponse("erro no write_file"),
    ])
  let assert True =
    report
    == fake.Report(Ok(1), [
      fake.Get("https://malbarbo.pro.br"),
      fake.WriteFile("arquivo.txt", "texto"),
      fake.Println("erro no write_file"),
    ])
  "OK: erro de gravação segue o ramo correto"
}

// panic funciona como sentinela: se o fake chamar next, o exemplo falha.
fn unknown_get() -> String {
  let description: Task(Int) = {
    use _ <- task.get("https://desconhecido.invalid")
    panic as "A continuação de um pedido desconhecido não deve ser chamada"
  }
  let request = fake.Get("https://desconhecido.invalid")
  let assert True =
    fake.run(description, [])
    == fake.Report(Error(fake.UnexpectedRequest(request)), [request])
  "OK: GET desconhecido interrompe sem chamar next"
}

fn unknown_write() -> String {
  let description: Task(Int) = {
    use _ <- task.write_file("arquivo.txt", "conteúdo diferente")
    panic as "Não deveria continuar"
  }
  let request = fake.WriteFile("arquivo.txt", "conteúdo diferente")
  // Mesmo caminho não basta: o conteúdo também precisa corresponder.
  let assert True =
    fake.run(description, [
      fake.WriteFileResponse("arquivo.txt", "conteúdo esperado", Ok(Nil)),
    ])
    == fake.Report(Error(fake.UnexpectedRequest(request)), [request])
  "OK: gravação exige caminho e conteúdo conhecidos"
}

fn unknown_println() -> String {
  let description: Task(Int) = {
    use _ <- task.println("Conhecida")
    use _ <- task.println("Desconhecida")
    panic as "Não deveria continuar"
  }
  let request = fake.Println("Desconhecida")
  let assert True =
    fake.run(description, [fake.PrintlnResponse("Conhecida")])
    == fake.Report(Error(fake.UnexpectedRequest(request)), [
      fake.Println("Conhecida"),
      request,
    ])
  "OK: impressão desconhecida preserva o histórico anterior"
}

fn done_and_then() -> String {
  let assert True = fake.run(task.done(42), []) == fake.Report(Ok(42), [])
  // O resultado muda de Int para String.
  let converted = {
    use number <- task.then(task.done(42))
    task.done(int.to_string(number))
  }
  let assert True = fake.run(converted, []) == fake.Report(Ok("42"), [])
  "OK: done e then com mudança de tipo"
}

fn composed_requests() -> String {
  let first = {
    use response <- task.get("https://malbarbo.pro.br")
    case response {
      Ok(content) -> {
        use _ <- task.write_file("arquivo.txt", content)
        use _ <- task.println("Sucesso")
        task.done(10)
      }
      Error(_) -> task.done(0)
    }
  }
  // then deve preservar GET, gravação e impressão antes da próxima etapa.
  let composed = {
    use number <- task.then(first)
    use _ <- task.println("Fim")
    task.done(int.to_string(number + 5))
  }
  let report =
    fake.run(composed, [fake.PrintlnResponse("Fim"), ..fake.demo_responses()])
  let assert True =
    report
    == fake.Report(Ok("15"), [
      fake.Get("https://malbarbo.pro.br"),
      fake.WriteFile("arquivo.txt", "conteúdo de demonstração"),
      fake.Println("Sucesso"),
      fake.Println("Fim"),
    ])
  "OK: then preserva todos os pedidos e encadeia a próxima tarefa"
}

fn repeatable() -> String {
  let description = program()
  let replies = fake.demo_responses()
  let assert True =
    fake.run(description, replies) == fake.run(description, replies)
  let repeated = {
    use _ <- task.println("Mesma mensagem")
    use _ <- task.println("Mesma mensagem")
    task.done(Nil)
  }
  let assert True =
    fake.run(repeated, [fake.PrintlnResponse("Mesma mensagem")])
    == fake.Report(Ok(Nil), [
      fake.Println("Mesma mensagem"),
      fake.Println("Mesma mensagem"),
    ])
  "OK: simulação repetível e respostas reutilizáveis"
}

fn first_response_wins() -> String {
  let description = {
    use response <- task.get("url")
    task.done(response)
  }
  let assert Ok(Ok("primeira")) =
    fake.run(description, [
      fake.GetResponse("outra", Ok("ignorada")),
      fake.GetResponse("url", Ok("primeira")),
      fake.GetResponse("url", Ok("segunda")),
    ]).result
  let assert 0 = fake.value(program(), fake.demo_responses())
  let assert 0 = fake.demo_value(program())
  "OK: primeira resposta correspondente e adaptadores value/demo_value"
}

pub fn smain() -> List(String) {
  [
    success(),
    get_error(),
    write_error(),
    unknown_get(),
    unknown_write(),
    unknown_println(),
    done_and_then(),
    composed_requests(),
    repeatable(),
    first_response_wins(),
  ]
}
