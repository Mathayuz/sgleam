use std::process::Command;
use tempfile::TempDir;

fn run(source: &str, number_mode: bool) -> (TempDir, std::process::Output) {
    let dir = tempfile::tempdir().expect("temporary task directory");
    std::fs::write(dir.path().join("program.gleam"), source).expect("write program");
    std::fs::write(dir.path().join("arquivo.txt"), "original").expect("existing file");
    let mut command = Command::new(env!("CARGO_BIN_EXE_sgleam"));
    command.current_dir(dir.path());
    if number_mode {
        command.arg("-n");
    }
    let output = command.arg("program.gleam").output().expect("run sgleam");
    assert_eq!(
        std::fs::read_to_string(dir.path().join("arquivo.txt")).expect("existing file"),
        "original"
    );
    assert!(!dir.path().join("new.txt").exists());
    (dir, output)
}

fn success(source: &str, number_mode: bool) {
    let (_, output) = run(source, number_mode);
    assert!(
        output.status.success(),
        "{}{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        output.stdout.is_empty(),
        "Task println must not print: {}",
        String::from_utf8_lossy(&output.stdout)
    );
}

#[test]
fn task_main_simulates_download_without_touching_files_or_printing() {
    for number_mode in [false, true] {
        success(
            include_str!("../../examples/task_download.gleam"),
            number_mode,
        );
    }
}

#[test]
fn fake_reports_success_and_each_error_branch() {
    let program = include_str!("../../examples/task_download.gleam")
        .replace("pub fn main()", "fn download()");
    let scenarios = [
        (
            r#"fake.demo_responses()"#,
            r#"Ok(0)"#,
            r#"[
            fake.Get("https://malbarbo.pro.br"),
            fake.WriteFile("arquivo.txt", "conteúdo de demonstração"),
            fake.Println("Sucesso")
        ]"#,
        ),
        (
            r#"[
            fake.GetResponse("https://malbarbo.pro.br", Error("offline")),
            fake.PrintlnResponse("erro no get")
        ]"#,
            "Ok(1)",
            r#"[fake.Get("https://malbarbo.pro.br"), fake.Println("erro no get")]"#,
        ),
        (
            r#"[
            fake.GetResponse("https://malbarbo.pro.br", Ok("body")),
            fake.WriteFileResponse("arquivo.txt", "body", Error("denied")),
            fake.PrintlnResponse("erro no write_file")
        ]"#,
            "Ok(1)",
            r#"[
            fake.Get("https://malbarbo.pro.br"), fake.WriteFile("arquivo.txt", "body"),
            fake.Println("erro no write_file")
        ]"#,
        ),
    ];
    for (responses, expected, requests) in scenarios {
        success(
            &format!(
                r#"
import sgleam/task/fake
{program}
pub fn main() {{
    let report = fake.run(download(), {responses})
    let assert {expected} = report.result
    let assert True = report.requests == {requests}
}}
"#
            ),
            false,
        );
    }
}

#[test]
fn unknown_requests_stop_without_running_the_continuation() {
    for (request, fixtures, expected) in [
        (
            r#"task.get("https://unknown.invalid", fn(_) { panic })"#,
            "[]",
            r#"fake.Get("https://unknown.invalid")"#,
        ),
        (
            r#"task.write_file("new.txt", "different", fn(_) { panic })"#,
            r#"[fake.WriteFileResponse("new.txt", "expected", Ok(Nil))]"#,
            r#"fake.WriteFile("new.txt", "different")"#,
        ),
        (
            r#"task.println("unknown", fn(_) { panic })"#,
            "[]",
            r#"fake.Println("unknown")"#,
        ),
    ] {
        success(
            &format!(
                r#"
import sgleam/task
import sgleam/task/fake
pub fn main() {{
    let report = fake.run({request}, {fixtures})
    let assert Error(fake.UnexpectedRequest({expected})) = report.result
    let assert True = report.requests == [{expected}]
}}
"#
            ),
            false,
        );
    }
}

#[test]
fn descriptions_compose_and_fake_is_repeatable() {
    success(
        r#"
import sgleam/task
import sgleam/task/fake
pub fn main() {
  let description = {
    use _ <- task.println("first")
    use _ <- task.write_file("new.txt", "content")
    task.done(20)
  }
  let assert task.Println("first", _) = description
  let composed = {
    use n <- task.then(description)
    use _ <- task.println("last")
    task.done(n + 22)
  }
  let replies = [fake.PrintlnResponse("first"), fake.WriteFileResponse("new.txt", "content", Ok(Nil)), fake.PrintlnResponse("last")]
  let first = fake.run(composed, replies)
  let second = fake.run(composed, replies)
  let assert Ok(42) = first.result
  let assert True = first == second
  let assert True = first.requests == [fake.Println("first"), fake.WriteFile("new.txt", "content"), fake.Println("last")]
  let assert Ok(10) = fake.run(task.then(task.done(5), fn(n) { task.done(n * 2) }), []).result
}
"#,
        false,
    );
}

#[test]
fn function_return_is_not_mistaken_for_task_main() {
    success("pub fn main() -> fn() -> Int { fn() { panic } }", false);
}

#[test]
fn unknown_main_request_fails_instead_of_doing_real_io() {
    let (_, output) = run(
        r#"
import sgleam/task.{type Task}
pub fn main() -> Task(Int) {
  use _ <- task.write_file("new.txt", "data")
  task.done(0)
}
"#,
        false,
    );
    assert!(!output.status.success());
    assert!(
        String::from_utf8_lossy(&output.stdout).contains("unexpected request")
            || String::from_utf8_lossy(&output.stderr).contains("unexpected request")
    );
}
