///|
fn parse_gui_manifest_json(
  input : String,
) -> GuiManifestDoc raise HtmlRenderError {
  let json = try @json.parse(input) catch {
    err => raise HtmlRenderError::InvalidGuiJson(err.to_string())
  } noraise {
    value => value
  }
  parse_gui_manifest_root(json)
}

///|
fn parse_gui_manifest_root(json : Json) -> GuiManifestDoc raise HtmlRenderError {
  let root = expect_gui_object(json, "gui")
  let entities_json = require_gui_array(root, "entities", "gui.entities")
  let entities : Array[GuiManifestEntity] = []
  for i, entity_json in entities_json {
    entities.push(parse_gui_entity(entity_json, "gui.entities[\{i}]"))
  }
  GuiManifestDoc::{ entities, }
}

///|
fn parse_gui_entity(
  json : Json,
  path : String,
) -> GuiManifestEntity raise HtmlRenderError {
  let obj = expect_gui_object(json, path)
  let states_json = require_gui_array(obj, "states", "\{path}.states")
  let views_json = require_gui_array(obj, "views", "\{path}.views")
  let rules_json = require_gui_array(obj, "rules", "\{path}.rules")
  let states : Array[GuiManifestState] = []
  let views : Array[GuiManifestView] = []
  let rules : Array[GuiManifestRule] = []
  for i, state_json in states_json {
    states.push(parse_gui_state(state_json, "\{path}.states[\{i}]"))
  }
  for i, view_json in views_json {
    views.push(parse_gui_view(view_json, "\{path}.views[\{i}]"))
  }
  for i, rule_json in rules_json {
    rules.push(parse_gui_rule(rule_json, "\{path}.rules[\{i}]"))
  }
  GuiManifestEntity::{
    name: require_gui_string(obj, "name", "\{path}.name"),
    label: require_gui_string(obj, "label", "\{path}.label"),
    states,
    views,
    rules,
  }
}

///|
fn parse_gui_state(
  json : Json,
  path : String,
) -> GuiManifestState raise HtmlRenderError {
  let obj = expect_gui_object(json, path)
  GuiManifestState::{
    name: require_gui_string(obj, "name", "\{path}.name"),
    label: require_gui_string(obj, "label", "\{path}.label"),
  }
}

///|
fn parse_gui_view(
  json : Json,
  path : String,
) -> GuiManifestView raise HtmlRenderError {
  let obj = expect_gui_object(json, path)
  let fields_json = require_gui_array(obj, "fields", "\{path}.fields")
  let actions_json = require_gui_array(obj, "actions", "\{path}.actions")
  let fields : Array[GuiManifestField] = []
  let actions : Array[GuiManifestAction] = []
  for i, field_json in fields_json {
    fields.push(parse_gui_field(field_json, "\{path}.fields[\{i}]"))
  }
  for i, action_json in actions_json {
    actions.push(parse_gui_action(action_json, "\{path}.actions[\{i}]"))
  }
  GuiManifestView::{
    name: require_gui_string(obj, "name", "\{path}.name"),
    fields,
    actions,
  }
}

///|
fn parse_gui_field(
  json : Json,
  path : String,
) -> GuiManifestField raise HtmlRenderError {
  let obj = expect_gui_object(json, path)
  GuiManifestField::{
    name: require_gui_string(obj, "name", "\{path}.name"),
    label: optional_gui_string(obj, "label", "\{path}.label").unwrap_or(
      require_gui_string(obj, "name", "\{path}.name"),
    ),
    component: require_gui_string(obj, "component", "\{path}.component"),
    mode: require_gui_string(obj, "mode", "\{path}.mode"),
  }
}

///|
fn parse_gui_action(
  json : Json,
  path : String,
) -> GuiManifestAction raise HtmlRenderError {
  let obj = expect_gui_object(json, path)
  let inputs_json = require_gui_array(obj, "inputs", "\{path}.inputs")
  let inputs : Array[GuiManifestActionInput] = []
  for i, input_json in inputs_json {
    inputs.push(parse_gui_action_input(input_json, "\{path}.inputs[\{i}]"))
  }
  GuiManifestAction::{
    name: require_gui_string(obj, "name", "\{path}.name"),
    to: require_gui_string(obj, "to", "\{path}.to"),
    inputs,
    enabled_when: optional_gui_string(obj, "enabledWhen", "\{path}.enabledWhen"),
    role: optional_gui_string(obj, "role", "\{path}.role"),
  }
}

///|
fn parse_gui_action_input(
  json : Json,
  path : String,
) -> GuiManifestActionInput raise HtmlRenderError {
  let obj = expect_gui_object(json, path)
  GuiManifestActionInput::{
    name: require_gui_string(obj, "name", "\{path}.name"),
    label: optional_gui_string(obj, "label", "\{path}.label").unwrap_or(
      require_gui_string(obj, "name", "\{path}.name"),
    ),
    kind: require_gui_string(obj, "kind", "\{path}.kind"),
    component: require_gui_string(obj, "component", "\{path}.component"),
    required: require_gui_bool(obj, "required", "\{path}.required"),
  }
}

///|
fn parse_gui_rule(
  json : Json,
  path : String,
) -> GuiManifestRule raise HtmlRenderError {
  let obj = expect_gui_object(json, path)
  GuiManifestRule::{
    name: require_gui_string(obj, "name", "\{path}.name"),
    when_expr: require_gui_string(obj, "when", "\{path}.when"),
  }
}

///|
fn expect_gui_object(
  json : Json,
  path : String,
) -> Map[String, Json] raise HtmlRenderError {
  match json {
    Json::Object(obj) => obj
    _ =>
      raise HtmlRenderError::InvalidGuiManifest(
        path~,
        "expected object in gui manifest",
      )
  }
}

///|
fn expect_gui_array(
  json : Json,
  path : String,
) -> Array[Json] raise HtmlRenderError {
  match json {
    Json::Array(items) => items
    _ =>
      raise HtmlRenderError::InvalidGuiManifest(
        path~,
        "expected array in gui manifest",
      )
  }
}

///|
fn require_gui_array(
  obj : Map[String, Json],
  key : String,
  path : String,
) -> Array[Json] raise HtmlRenderError {
  match obj.get(key) {
    Some(json) => expect_gui_array(json, path)
    None =>
      raise HtmlRenderError::InvalidGuiManifest(
        path~,
        "missing required key \{key}",
      )
  }
}

///|
fn require_gui_string(
  obj : Map[String, Json],
  key : String,
  path : String,
) -> String raise HtmlRenderError {
  match obj.get(key) {
    Some(Json::String(text)) => text
    Some(_) =>
      raise HtmlRenderError::InvalidGuiManifest(
        path~,
        "expected string for key \{key}",
      )
    None =>
      raise HtmlRenderError::InvalidGuiManifest(
        path~,
        "missing required key \{key}",
      )
  }
}

///|
fn require_gui_bool(
  obj : Map[String, Json],
  key : String,
  path : String,
) -> Bool raise HtmlRenderError {
  match obj.get(key) {
    Some(Json::True) => true
    Some(Json::False) => false
    Some(_) =>
      raise HtmlRenderError::InvalidGuiManifest(
        path~,
        "expected bool for key \{key}",
      )
    None =>
      raise HtmlRenderError::InvalidGuiManifest(
        path~,
        "missing required key \{key}",
      )
  }
}

///|
fn optional_gui_string(
  obj : Map[String, Json],
  key : String,
  path : String,
) -> String? raise HtmlRenderError {
  match obj.get(key) {
    None => None
    Some(Json::Null) => None
    Some(Json::String(text)) => Some(text)
    Some(_) =>
      raise HtmlRenderError::InvalidGuiManifest(
        path~,
        "expected optional string for key \{key}",
      )
  }
}
