use engine::{
    engine::{Engine, MainFunction},
    gleam::Project,
    quickjs::QuickJsEngine,
};

#[test]
fn radio_groups_preserve_typed_messages_optional_selection_and_group_isolation() {
    let mut project = Project::default();
    project.write_source("radio_test.gleam", r#"
import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import sgleam/ui/element
import sgleam/ui/event
import sgleam/ui/html
import sgleam/ui/layout
import sgleam/ui/radio_group

type Size { Small Large }
type Msg { Picked(Size) }
type Parent { Wrapped(Msg) }
fn group(selected) {
  radio_group.new(selected)
  |> radio_group.option(Small, "Small <&>")
  |> radio_group.option(Large, "Large")
  |> radio_group.on_select(Picked)
}
pub fn main() {
  let #(markup, handlers) = group(None) |> radio_group.done |> html.render
  let assert False = string.contains(markup, " checked")
  let assert True = string.contains(markup, "<label><input")
  let assert True = string.contains(markup, "Small &lt;&amp;&gt;")
  let assert 2 = dict.size(handlers)
  let assert Ok(handler) = dict.get(handlers, 2)
  let assert Ok(Picked(Large)) = event.apply(handler, event.StringValue("1"))
  let assert Error(_) = event.apply(handler, event.BoolValue(True))

  let #(selected, _) = group(Some(Large)) |> radio_group.done |> html.render
  let assert True = string.contains(selected, "value=\"1\" checked")
  let #(missing, _) = radio_group.new(Some(Large)) |> radio_group.option(Small, "Small") |> radio_group.done |> html.render
  let assert False = string.contains(missing, " checked")

  let #(disabled, handlers) = group(Some(Small)) |> radio_group.enabled(False) |> radio_group.done |> html.render
  let assert 0 = dict.size(handlers)
  let assert True = string.contains(disabled, " disabled")
  let assert False = string.contains(disabled, "data-sgleam-selection")

  let #(mapped, handlers) = group(Some(Small)) |> radio_group.done |> element.map(Wrapped) |> html.render
  let assert True = string.contains(mapped, " checked")
  let assert Ok(handler) = dict.get(handlers, 1)
  let assert Ok(Wrapped(Picked(Small))) = event.apply(handler, event.StringValue("0"))

  let passive = radio_group.new(None) |> radio_group.option(Small, "Passive") |> radio_group.done
  let empty = radio_group.new(None) |> radio_group.done
  let markup = layout.column([empty, passive, passive, group(None) |> radio_group.done]) |> layout.done |> html.to_html
  let assert True = string.contains(markup, "name=\"sgleam-radio-group-1\"")
  let assert True = string.contains(markup, "name=\"sgleam-radio-group-2\"")
  let assert True = string.contains(markup, "name=\"sgleam-radio-group-3\"")
  // Repeated values never render two checked options.
  let duplicate = radio_group.new(Some(Small)) |> radio_group.option(Small, "A") |> radio_group.option(Small, "B") |> radio_group.done |> html.to_html
  let assert 2 = list.length(string.split(duplicate, " checked"))
}
"#);
    project
        .compile(false)
        .expect("compile radio group assertions");
    QuickJsEngine::new(project.fs)
        .expect("runtime")
        .run_main("radio_test", MainFunction::Main)
        .expect("radio group assertions");
}
