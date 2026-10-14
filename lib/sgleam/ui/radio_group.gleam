import gleam/option.{type Option}
import sgleam/ui/element.{type Element, type RadioGroup}

/// None starts with no selection; Some(value) selects a matching option.
pub fn new(selected: Option(value)) -> RadioGroup(value, msg) {
  element.new_radio_group(selected)
}

/// Adds an option. Options appear in the order they are added.
pub fn option(
  group: RadioGroup(value, msg),
  value: value,
  label: String,
) -> RadioGroup(value, msg) {
  element.radio_group_option(group, value, label)
}

pub fn on_select(
  group: RadioGroup(value, msg),
  handler: fn(value) -> msg,
) -> RadioGroup(value, msg) {
  element.radio_group_on_select(group, handler)
}

pub fn enabled(
  group: RadioGroup(value, msg),
  enabled: Bool,
) -> RadioGroup(value, msg) {
  element.radio_group_enabled(group, enabled)
}

/// An accessible name for the group; each option already has its own label.
pub fn label(
  group: RadioGroup(value, msg),
  label: String,
) -> RadioGroup(value, msg) {
  element.radio_group_label(group, label)
}

pub fn done(group: RadioGroup(value, msg)) -> Element(msg) {
  element.radio_group_done(group)
}
