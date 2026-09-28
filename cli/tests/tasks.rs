use std::io::{BufRead, BufReader, Write};
use std::net::TcpListener;
use std::process::Command;
use tempfile::TempDir;

fn run(source: &str, number_mode: bool) -> (TempDir, String) {
    let dir = tempfile::tempdir().expect("temporary task directory");
    std::fs::write(dir.path().join("program.gleam"), source).expect("write program");
    let mut command = Command::new(env!("CARGO_BIN_EXE_sgleam"));
    command.current_dir(dir.path());
    if number_mode {
        command.arg("-n");
    }
    let output = command.arg("program.gleam").output().expect("run sgleam");
    assert!(
        output.status.success(),
        "{}",
        String::from_utf8_lossy(&output.stderr)
    );
    (dir, String::from_utf8(output.stdout).expect("UTF-8 output"))
}

fn server(status: &str) -> (String, std::thread::JoinHandle<()>) {
    let listener = TcpListener::bind("127.0.0.1:0").expect("bind HTTP server");
    let url = format!("http://{}", listener.local_addr().expect("server address"));
    let response =
        format!("HTTP/1.1 {status}\r\nContent-Length: 5\r\nConnection: close\r\n\r\nhello");
    listener
        .set_nonblocking(true)
        .expect("nonblocking listener");
    let handle = std::thread::spawn(move || {
        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(30);
        loop {
            match listener.accept() {
                Ok((mut stream, _)) => {
                    stream
                        .set_read_timeout(Some(std::time::Duration::from_secs(5)))
                        .expect("read timeout");
                    let mut reader = BufReader::new(&mut stream);
                    loop {
                        let mut line = String::new();
                        let count = reader.read_line(&mut line).expect("read request");
                        assert!(count > 0, "request ended before its headers");
                        if line == "\r\n" {
                            break;
                        }
                    }
                    stream
                        .write_all(response.as_bytes())
                        .expect("write response");
                    return;
                }
                Err(error) if error.kind() == std::io::ErrorKind::WouldBlock => {
                    assert!(std::time::Instant::now() < deadline, "HTTP task never ran");
                    std::thread::sleep(std::time::Duration::from_millis(10));
                }
                Err(error) => panic!("accept: {error}"),
            }
        }
    });
    (url, handle)
}

#[test]
fn download_main_runs_in_both_integer_modes() {
    for number_mode in [false, true] {
        let (url, server) = server("200 OK");
        let source = include_str!("../../examples/task_download.gleam")
            .replace("https://malbarbo.pro.br", &url);
        let (dir, output) = run(&source, number_mode);
        server.join().expect("HTTP server finished");
        assert_eq!(output.trim(), "Sucesso");
        assert_eq!(
            std::fs::read_to_string(dir.path().join("arquivo.txt")).expect("downloaded file"),
            "hello"
        );
    }
}

#[test]
fn download_errors_follow_the_right_branch() {
    for (status, path, expected) in [
        ("404 Not Found", "arquivo.txt", "erro no get"),
        ("200 OK", "missing/arquivo.txt", "erro no write_file"),
    ] {
        let (url, server) = server(status);
        let source = include_str!("../../examples/task_download.gleam")
            .replace("https://malbarbo.pro.br", &url)
            .replace("arquivo.txt", path);
        let (dir, output) = run(&source, false);
        server.join().expect("HTTP server finished");
        assert_eq!(output.trim(), expected);
        assert!(!dir.path().join("arquivo.txt").exists());
    }
}

#[test]
fn effects_are_deferred_and_repeat_only_when_run() {
    let (dir, output) = run(
        r#"
import gleam/io
import sgleam/task
pub fn main() {
  let unused = {
    use _ <- task.write_file("unused.txt", "must not exist")
    task.done(0)
  }
  let assert _ = unused
  let action = {
    use _ <- task.println("effect")
    task.done(42)
  }
  io.println("constructed")
  let assert 42 = task.run(action)
  let assert 42 = task.run(action)
  let failure = {
    use response <- task.get("invalid://url")
    let assert Error(_) = response
    task.done(1)
  }
  let assert 1 = task.run(failure)
}
"#,
        false,
    );
    assert_eq!(output.trim(), "constructed\neffect\neffect");
    assert!(!dir.path().join("unused.txt").exists());
}

#[test]
fn simple_and_effectful_apps_compile_and_initialize() {
    let (_, output) = run(
        r#"
import sgleam/task
import sgleam/ui/app
import sgleam/ui/simple_app
import sgleam/ui/element
pub fn main() {
  simple_app.create(fn() { 0 }, fn(_) { element.Text(element.new_text("simple")) }, fn(n, _) { n })
  |> simple_app.run
  app.create(fn() {
    use _ <- task.println("init")
    task.done(0)
  }, fn(_) { element.Text(element.new_text("effectful")) }, fn(n, _) {
    use _ <- task.println("update")
    task.done(n + 1)
  })
  |> app.run
}
"#,
        false,
    );
    assert!(output.contains("simple"));
    assert!(output.contains("init"));
    assert!(output.contains("effectful"));
    assert!(!output.contains("update"));
}
