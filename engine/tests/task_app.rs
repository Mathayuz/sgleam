use engine::{
    engine::{Engine, MainFunction},
    gleam::Project,
    quickjs::QuickJsEngine,
};

#[test]
fn app_interprets_descriptions_without_printing_and_renders_updated_model() {
    let mut project = Project::default();
    project.write_source(
        "task_app.gleam",
        r#"
import gleam/int
import sgleam/task
import sgleam/task/fake
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
  }) |> app.run_with(fn(program) {
    fake.value(program, [fake.PrintlnResponse("init"), fake.PrintlnResponse("update")])
  })
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
    if (log.length !== 2 || !log[0].includes(">0</button>") ||
        !log[1].includes(">2</button>")) {
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

#[test]
fn stop_when_checks_initial_and_updated_models_without_draining_extra_events() {
    for effectful in [false, true] {
        for initial in [0, 1] {
            let module = if effectful { "app" } else { "simple_app" };
            let init = if effectful {
                format!("task.done({initial})")
            } else {
                initial.to_string()
            };
            let update = if effectful {
                "task.done(n + 1)"
            } else {
                "n + 1"
            };
            let imports = if effectful { "import sgleam/task" } else { "" };
            let mut project = Project::default();
            project.write_source(
                "stop_app.gleam",
                &format!(
                    r#"
import gleam/int
import sgleam/ui/{module} as app
import sgleam/ui/button
{imports}
@external(javascript, "./stop_mock.mjs", "setup")
fn setup() -> Nil
@external(javascript, "./stop_mock.mjs", "verify")
fn verify() -> Nil
pub fn main() {{
  setup()
  app.create(fn() {{ {init} }}, fn(n) {{
    button.new(int.to_string(n)) |> button.on_press(Nil) |> button.done
  }}, fn(n, _) {{ {update} }})
  |> app.stop_when(fn(n) {{ n >= 1 }})
  |> app.run
  verify()
}}
"#
                ),
            );
            project.compile(false).expect("compile stop_when example");
            project.write_out(
                "stop_mock.mjs",
                &format!(
                    r#"
let views = [], reads = 0, waits = 0;
export function setup() {{
  sgleam.draw_view = html => views.push(html);
  sgleam.wait_event = () => {{
    if (++waits > 1 || {initial} === 1) throw new Error("Waited after stopping");
    return 1;
  }};
  sgleam.next_event = () => {{
    if (++reads > 1) throw new Error("Consumed another queued event after stopping");
    return JSON.stringify({{kind: "ui", h: 0, e: "click"}});
  }};
}}
export function verify() {{
  if (views.length !== 2 - {initial} || reads !== 1 - {initial} ||
      !views[views.length - 1].includes(">1</button>")) {{
    throw new Error("Wrong final view or event count");
  }}
}}
"#
                ),
            );
            QuickJsEngine::new(project.fs)
                .expect("runtime")
                .run_main("stop_app", MainFunction::Main)
                .expect("stops and returns");
        }
    }
}
