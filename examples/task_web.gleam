// Descrição web: GET -> POST -> wake_up. O ambiente padrão usa apenas o fake.
import sgleam/task.{type Task}

pub fn main() -> Task(Int) {
  use response <- task.get("https://example.com/text")
  case response {
    Ok(content) -> {
      use sent <- task.post(
        "https://example.com/notes",
        task.string_body("text/plain", content),
      )
      case sent {
        Ok(_) -> {
          use _ <- task.wake_up(1000)
          task.done(0)
        }
        Error(_) -> task.done(1)
      }
    }
    Error(_) -> task.done(1)
  }
}
