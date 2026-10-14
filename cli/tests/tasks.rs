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
        "The fake must not print: {}",
        String::from_utf8_lossy(&output.stdout)
    );
}

#[test]
fn task_main_simulates_web_sequence_without_io() {
    for number_mode in [false, true] {
        success(include_str!("../../examples/task_web.gleam"), number_mode);
    }
}

#[test]
fn fake_web_scenarios_in_both_number_modes() {
    let source =
        include_str!("../../examples/task_fake.gleam").replace("pub fn smain()", "fn checks()");
    for number_mode in [false, true] {
        success(
            &format!("{source}\npub fn main() {{ let _ = checks() Nil }}"),
            number_mode,
        );
    }
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
  use _ <- task.post("https://unknown.invalid", task.empty_body())
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

#[test]
fn removed_effects_and_string_errors_are_rejected() {
    for source in [
        "import sgleam/task\npub fn main() { task.write_file(\"new.txt\", \"text\", fn(_) { task.done(0) }) }",
        "import sgleam/task\npub fn main() { task.println(\"text\", fn(_) { task.done(0) }) }",
        "import sgleam/task/fake\npub fn main() { fake.GetResponse(\"url\", Error(\"string error\")) }",
    ] {
        let (_, output) = run(source, false);
        assert!(!output.status.success(), "obsolete API must not compile");
    }
}
