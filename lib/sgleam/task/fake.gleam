import gleam/list
import sgleam/task.{type Task}

pub type Request {
  Get(url: String)
  WriteFile(path: String, content: String)
  Println(message: String)
}

pub type Response {
  GetResponse(url: String, result: Result(String, String))
  WriteFileResponse(path: String, content: String, result: Result(Nil, String))
  PrintlnResponse(message: String)
}

pub type Failure {
  UnexpectedRequest(request: Request)
}

pub type Report(a) {
  Report(result: Result(a, Failure), requests: List(Request))
}

pub fn run(program: Task(a), responses: List(Response)) -> Report(a) {
  loop(program, responses, [])
}

fn loop(
  program: Task(a),
  responses: List(Response),
  history: List(Request),
) -> Report(a) {
  case program {
    task.Done(value) -> Report(Ok(value), list.reverse(history))
    task.Get(url, next) -> {
      let request = Get(url)
      case get_response(responses, url) {
        Ok(result) -> loop(next(result), responses, [request, ..history])
        Error(_) -> unexpected(request, history)
      }
    }
    task.WriteFile(path, content, next) -> {
      let request = WriteFile(path, content)
      case write_response(responses, path, content) {
        Ok(result) -> loop(next(result), responses, [request, ..history])
        Error(_) -> unexpected(request, history)
      }
    }
    task.Println(message, next) -> {
      let request = Println(message)
      case list.contains(responses, PrintlnResponse(message)) {
        True -> loop(next(Nil), responses, [request, ..history])
        False -> unexpected(request, history)
      }
    }
  }
}

fn unexpected(request: Request, history: List(Request)) -> Report(a) {
  Report(Error(UnexpectedRequest(request)), list.reverse([request, ..history]))
}

fn get_response(
  responses: List(Response),
  url: String,
) -> Result(Result(String, String), Nil) {
  case responses {
    [] -> Error(Nil)
    [GetResponse(known, result), ..rest] ->
      case known == url {
        True -> Ok(result)
        False -> get_response(rest, url)
      }
    [_, ..rest] -> get_response(rest, url)
  }
}

fn write_response(
  responses: List(Response),
  path: String,
  content: String,
) -> Result(Result(Nil, String), Nil) {
  case responses {
    [] -> Error(Nil)
    [WriteFileResponse(known_path, known_content, result), ..rest] ->
      case known_path == path && known_content == content {
        True -> Ok(result)
        False -> write_response(rest, path, content)
      }
    [_, ..rest] -> write_response(rest, path, content)
  }
}

pub fn demo_responses() -> List(Response) {
  [
    GetResponse("https://malbarbo.pro.br", Ok("conteúdo de demonstração")),
    WriteFileResponse("arquivo.txt", "conteúdo de demonstração", Ok(Nil)),
    PrintlnResponse("Sucesso"),
  ]
}

pub fn value(program: Task(a), responses: List(Response)) -> a {
  case run(program, responses).result {
    Ok(value) -> value
    Error(_) ->
      panic as "Fake executor: unexpected request; configure an exact response"
  }
}

pub fn demo_value(program: Task(a)) -> a {
  value(program, demo_responses())
}
