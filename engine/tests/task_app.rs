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
import sgleam/show/app
import sgleam/show/button
@external(javascript, "./mock.mjs", "setup")
fn setup() -> Nil
@external(javascript, "./mock.mjs", "verify")
fn verify() -> Nil
@external(javascript, "./mock.mjs", "before_execute")
fn before_execute() -> Nil
type Msg { Initialized Click Completed }
pub fn main() {
  setup()
  app.create(fn() {
    let command = {
      use _ <- task.wake_up(0)
      task.done(Initialized)
    }
    #(10, command)
  }, fn(model) {
    button.new(int.to_string(model)) |> button.on_press(Click) |> button.done
  }, fn(model, message) {
    case message {
      Initialized -> #(model + 1, task.none())
      Click -> {
        let command = {
          use _ <- task.wake_up(10)
          task.done(Completed)
        }
        #(model + 10, command)
      }
      Completed -> #(model + 1, task.none())
    }
  }) |> app.run_with(fn(program) {
    before_execute()
    fake.messages(program, [fake.WakeUpResponse(0), fake.WakeUpResponse(10)])
  })
  verify()
}
"#,
    );
    project.compile(false).expect("compile task app");
    project.write_out(
        "mock.mjs",
        r#"
let log = [], executions = 0;
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
export function before_execute() {
    executions++;
    if (log.length !== executions) throw new Error("Task ran before its model was rendered");
}
export function verify() {
    const models = [10, 11, 21, 22, 32, 33];
    if (log.length !== models.length || executions !== models.length ||
        models.some((n, i) => !log[i].includes(">" + n + "</button>"))) {
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
            let init = if effectful && initial == 0 {
                "#(0, task.none())".to_string()
            } else if effectful {
                format!("#({initial}, task.get(\"must-not-execute\", fn(_) {{ task.done(Nil) }}))")
            } else {
                initial.to_string()
            };
            let update = if effectful {
                "#(n + 1, task.get(\"must-not-execute\", fn(_) { task.done(Nil) }))"
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
import sgleam/show/{module} as app
import sgleam/show/button
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

#[test]
fn task_messages_are_fifo_and_use_the_latest_model() {
    let mut project = Project::default();
    project.write_source(
        "fifo.gleam",
        r#"
import gleam/int
import sgleam/task
import sgleam/task/fake
import sgleam/show/app
import sgleam/show/text
type Msg { Start First Second Third }
@external(javascript, "./fifo_mock.mjs", "setup")
fn setup() -> Nil
@external(javascript, "./fifo_mock.mjs", "verify")
fn verify() -> Nil
pub fn main() {
  setup()
  app.create(fn() { #(0, task.done(Start)) }, fn(n) {
    text.new(int.to_string(n)) |> text.done
  }, fn(n, message) {
    case message {
      Start -> panic as "The interpreter expands Start"
      First -> #(n * 10 + 1, task.done(Third))
      Second -> #(n * 10 + 2, task.none())
      Third -> #(n * 10 + 3, task.none())
    }
  })
  |> app.stop_when(fn(n) { n == 123 })
  |> app.run_with(fn(program) {
    case program {
      task.Done(Start) -> [First, Second]
      _ -> fake.messages(program, [])
    }
  })
  verify()
}
"#,
    );
    project.compile(false).expect("compile FIFO example");
    project.write_out(
        "fifo_mock.mjs",
        r#"
let views = [];
export function setup() {
  sgleam.draw_view = html => views.push(html);
  sgleam.next_event = () => { throw new Error("Read UI before draining task messages"); };
  sgleam.wait_event = () => { throw new Error("Unexpected wait"); };
}
export function verify() {
  if (views.length !== 4 || [0, 1, 12, 123].some((n, i) =>
      !views[i].includes(">" + n + "<"))) throw new Error(JSON.stringify(views));
}
"#,
    );
    QuickJsEngine::new(project.fs)
        .expect("runtime")
        .run_main("fifo", MainFunction::Main)
        .expect("FIFO task messages");
}

#[test]
fn simple_app_batches_events_using_the_rendered_handlers() {
    let mut project = Project::default();
    project.write_source(
        "batch.gleam",
        r#"
import gleam/int
import sgleam/show/simple_app
import sgleam/show/button
@external(javascript, "./batch_mock.mjs", "setup")
fn setup() -> Nil
@external(javascript, "./batch_mock.mjs", "verify")
fn verify() -> Nil
pub fn main() {
  setup()
  simple_app.create(fn() { 0 }, fn(n) {
    button.new(int.to_string(n)) |> button.on_press(n + 1) |> button.done
  }, fn(n, amount) { n + amount }) |> simple_app.run
  verify()
}
"#,
    );
    project.compile(false).expect("compile batched SimpleApp");
    project.write_out("batch_mock.mjs", r#"
let views = [], waits = 0;
export function setup() {
  let events = [
    {kind: "invalid"},
    {kind: "ui", h: 99, e: "click"},
    {kind: "ui", h: 0, e: "check", checked: true},
    {kind: "ui", h: 0, e: "click"},
    {kind: "ui", h: 0, e: "click"},
  ];
  sgleam.draw_view = html => views.push(html);
  sgleam.wait_event = () => ++waits === 1 ? 1 : -1;
  sgleam.next_event = () => events.length ? JSON.stringify(events.shift()) : "";
}
export function verify() {
  if (waits !== 2 || views.length !== 2 ||
      !views[0].includes(">0</button>") || !views[1].includes(">2</button>")) {
    throw new Error("Expected one render per batch with original handlers: " + JSON.stringify(views));
  }
}
"#);
    QuickJsEngine::new(project.fs)
        .expect("runtime")
        .run_main("batch", MainFunction::Main)
        .expect("batched events");
}

#[test]
fn next_event_handles_empty_queue_and_preserves_valid_events() {
    let mut project = Project::default();
    project.write_source(
        "event_queue.gleam",
        r#"
import gleam/dynamic/decode
import sgleam/system
@external(javascript, "./event_queue_mock.mjs", "setup")
fn setup() -> Nil
pub fn main() {
  setup()
  let assert Error(Nil) = system.next_event()
  let assert Error(Nil) = system.next_event()
  let assert Ok(raw) = system.next_event()
  let assert Ok("ui") = decode.run(raw, decode.field("kind", decode.string, decode.success))
  let assert Error(Nil) = system.next_event()
}
"#,
    );
    project
        .compile(false)
        .expect("compile event queue regression");
    project.write_out(
        "event_queue_mock.mjs",
        r#"
export function setup() {
  // Rust Option::None becomes undefined in the JavaScript runtime.
  const events = [undefined, "", JSON.stringify({kind: "ui", h: 0, e: "click"})];
  sgleam.next_event = () => events.shift();
}
"#,
    );
    QuickJsEngine::new(project.fs)
        .expect("runtime")
        .run_main("event_queue", MainFunction::Main)
        .expect("empty queue returns Error without parsing undefined");
}
