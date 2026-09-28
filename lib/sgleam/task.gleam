import gleam/io

/// A deferred computation. Constructing a task does not execute it.
/// Running it twice repeats its effects. This is synchronous, not a Promise.
pub type Task(a) =
  fn() -> a

pub fn done(value: a) -> Task(a) {
  fn() { value }
}

pub fn run(task: Task(a)) -> a {
  task()
}

/// Chains tasks; also usable with `use value <- task.then(first)`.
pub fn then(first: Task(a), next: fn(a) -> Task(b)) -> Task(b) {
  fn() { run(next(run(first))) }
}

pub fn println(message: String, next: fn(Nil) -> Task(a)) -> Task(a) {
  then(fn() { io.println(message) }, next)
}

/// Performs an HTTP(S) GET when run. HTTP 4xx and 5xx status codes are errors.
pub fn get(
  url: String,
  next: fn(Result(String, String)) -> Task(a),
) -> Task(a) {
  then(fn() { get_raw(url) }, next)
}

/// Writes UTF-8 text, replacing an existing file, when run.
pub fn write_file(
  path: String,
  content: String,
  next: fn(Result(Nil, String)) -> Task(a),
) -> Task(a) {
  then(fn() { write_file_raw(path, content) }, next)
}

@external(javascript, "../sgleam/sgleam_ffi.mjs", "task_get")
fn get_raw(url: String) -> Result(String, String)

@external(javascript, "../sgleam/sgleam_ffi.mjs", "task_write_file")
fn write_file_raw(path: String, content: String) -> Result(Nil, String)
