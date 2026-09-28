use engine::{
    engine::{Engine, MainFunction},
    gleam::Project,
    quickjs::QuickJsEngine,
};

#[test]
fn app_runs_initialization_and_each_update_before_rendering() {
    let mut project = Project::default();
    project.write_source(
        "task_app.gleam",
        r#"
import gleam/int
import sgleam/task
import sgleam/ui/app
import sgleam/ui/button
@external(javascript, "./mock.mjs", "setup")
fn setup() -> Nil
@external(javascript, "./mock.mjs", "verify")
fn verify() -> Nil
pub fn main() {
  setup()
  app.create(fn() {
    use _ <- task.println("init")
    task.done(0)
  }, fn(model) {
    button.new(int.to_string(model)) |> button.on_press(Nil) |> button.done
  }, fn(model, _) {
    use _ <- task.println("update")
    task.done(model + 1)
  }) |> app.run
  verify()
}
"#,
    );
    project.compile(false).expect("compile task app");
    project.write_out(
        "mock.mjs",
        r#"
let log = [];
export function setup() {
    console.log = value => log.push(value);
    let waits = 0;
    let events = [
        JSON.stringify({kind: "ui", h: 0, e: "click"}),
        JSON.stringify({kind: "ui", h: 0, e: "click"}),
    ];
    sgleam.draw_view = html => log.push(html);
    sgleam.wait_event = () => waits++ === 0 ? 1 : -1;
    sgleam.next_event = () => events.shift() ?? "";
}
export function verify() {
    if (log.length !== 5 || log[0] !== "init" ||
        !log[1].includes(">0</button>") || log[2] !== "update" ||
        log[3] !== "update" || !log[4].includes(">2</button>")) {
        throw new Error("Wrong effect/render order: " + JSON.stringify(log));
    }
}
"#,
    );
    QuickJsEngine::new(project.fs)
        .expect("create runtime")
        .run_main("task_app", MainFunction::Main)
        .expect("run and verify task app");
}
