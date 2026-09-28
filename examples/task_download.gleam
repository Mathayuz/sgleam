import sgleam/task.{type Task}

pub fn main() -> Task(Int) {
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
