pub type Task(a) {
  Done(value: a)
  Get(url: String, next: fn(Result(String, String)) -> Task(a))
  WriteFile(
    path: String,
    content: String,
    next: fn(Result(Nil, String)) -> Task(a),
  )
  Println(message: String, next: fn(Nil) -> Task(a))
}

pub fn done(value: a) -> Task(a) {
  Done(value)
}

pub fn then(first: Task(a), next: fn(a) -> Task(b)) -> Task(b) {
  case first {
    Done(value) -> next(value)
    Get(url, continue) -> Get(url, fn(result) { then(continue(result), next) })
    WriteFile(path, content, continue) ->
      WriteFile(path, content, fn(result) { then(continue(result), next) })
    Println(message, continue) ->
      Println(message, fn(result) { then(continue(result), next) })
  }
}

pub fn println(message: String, next: fn(Nil) -> Task(a)) -> Task(a) {
  Println(message, next)
}

pub fn get(
  url: String,
  next: fn(Result(String, String)) -> Task(a),
) -> Task(a) {
  Get(url, next)
}

pub fn write_file(
  path: String,
  content: String,
  next: fn(Result(Nil, String)) -> Task(a),
) -> Task(a) {
  WriteFile(path, content, next)
}
