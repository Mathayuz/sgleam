import gleam/dict.{type Dict}
import gleam/dynamic/decode.{type Decoder}
import gleam/list
import gleam/result

import sgleam/system
import sgleam/task.{type Task}
import sgleam/task/fake
import sgleam/ui/element.{type Element}
import sgleam/ui/event.{type Event, type Handler}
import sgleam/ui/html

/// Pure init/update return the current model and a task producing messages.
/// The environment renders the model, interprets the task, and routes each
/// returned message through update. The default interpreter is synchronous.
pub opaque type App(model, msg) {
  App(
    init: fn() -> #(model, Task(msg)),
    view: fn(model) -> Element(msg),
    update: fn(model, msg) -> #(model, Task(msg)),
    should_stop: fn(model) -> Bool,
  )
}

pub fn create(
  init: fn() -> #(model, Task(msg)),
  view: fn(model) -> Element(msg),
  update: fn(model, msg) -> #(model, Task(msg)),
) -> App(model, msg) {
  App(init:, view:, update:, should_stop: fn(_) { False })
}

/// Renders the final model and stops before its task or queued messages/events.
pub fn stop_when(
  app: App(model, msg),
  predicate: fn(model) -> Bool,
) -> App(model, msg) {
  App(..app, should_stop: predicate)
}

pub fn run(app: App(model, msg)) -> Nil {
  run_with(app, fake.demo_messages)
}

/// Supplies a synchronous interpreter returning messages, never a model.
/// none() produces no messages; done(message) produces one.
pub fn run_with(
  app: App(model, msg),
  execute: fn(Task(msg)) -> List(msg),
) -> Nil {
  loop(app, app.init(), [], execute)
}

fn loop(
  app: App(model, msg),
  state: #(model, Task(msg)),
  pending: List(msg),
  execute: fn(Task(msg)) -> List(msg),
) -> Nil {
  let #(model, task) = state
  let #(markup, handlers) = app.view(model) |> html.render
  system.show_view(markup)

  case app.should_stop(model) {
    True -> Nil
    False -> {
      let messages = list.append(pending, execute(task))
      case messages {
        [message, ..rest] ->
          loop(app, app.update(model, message), rest, execute)
        [] -> await_event(app, handlers, model, execute)
      }
    }
  }
}

fn await_event(
  app: App(model, msg),
  handlers: Dict(Int, Handler(msg)),
  model: model,
  execute: fn(Task(msg)) -> List(msg),
) -> Nil {
  case system.next_event() {
    Ok(raw) -> {
      let decoded = {
        use incoming <- result.try(
          decode.run(raw, incoming_decoder()) |> result.replace_error(Nil),
        )
        let Ui(handler: handler_id, event: incoming_event) = incoming
        use handler <- result.try(dict.get(handlers, handler_id))
        event.apply(handler, incoming_event)
      }
      case decoded {
        Ok(message) -> loop(app, app.update(model, message), [], execute)
        Error(_) -> await_event(app, handlers, model, execute)
      }
    }
    Error(_) ->
      case system.wait_event(-1) {
        system.Stopped -> Nil
        system.HasEvent | system.Timeout ->
          await_event(app, handlers, model, execute)
      }
  }
}

type Incoming {
  Ui(handler: Int, event: Event)
}

fn incoming_decoder() -> Decoder(Incoming) {
  use kind <- decode.field("kind", decode.string)

  case kind {
    "ui" -> {
      use handler <- decode.field("h", decode.int)
      use incoming_event <- decode.then(event_decoder())

      decode.success(Ui(handler: handler, event: incoming_event))
    }

    _ ->
      decode.failure(Ui(handler: 0, event: event.NoValue), expected: "Incoming")
  }
}

fn event_decoder() -> Decoder(Event) {
  use event_kind <- decode.field("e", decode.string)

  case event_kind {
    "click" -> decode.success(event.NoValue)

    "input" | "submit" | "select" -> {
      use value <- decode.field("value", decode.string)
      decode.success(event.StringValue(value))
    }

    "check" -> {
      use checked <- decode.field("checked", decode.bool)
      decode.success(event.BoolValue(checked))
    }

    _ -> decode.failure(event.NoValue, expected: "Event")
  }
}
