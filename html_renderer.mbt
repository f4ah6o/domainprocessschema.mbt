///|
fn render_gui_manifest_html(manifest : GuiManifestDoc) -> String {
  let sections : Array[String] = []
  for entity in manifest.entities {
    sections.push(render_manifest_entity_html(entity))
  }
  let body = sections.join("\n")
  let title = "Generated GUI Preview"
  render_html_document(title, body, lang=detect_document_lang(title, body))
}

///|
fn render_manifest_entity_html(entity : GuiManifestEntity) -> String {
  let states : Array[String] = []
  let views : Array[String] = []
  let rules : Array[String] = []
  for state in entity.states {
    states.push(
      "<li class=\"state-list-item\">\{render_state_badge_html(state.name, state.label, false)}</li>",
    )
  }
  for view in entity.views {
    views.push(render_manifest_view_html(entity, view))
  }
  for rule in entity.rules {
    rules.push(render_manifest_rule_html(rule))
  }
  let header = "<header class=\"page-header\"><h1>\{html_escape(entity.label)}</h1><p class=\"entity-name\">\{html_escape(entity.name)}</p></header>"
  let states_block = render_list_block("States", "state-list", states)
  let rules_block = render_list_block("Rules", "rule-list", rules)
  let views_block = views.join("\n")
  "<section class=\"entity-page\">\n\{header}\n\{states_block}\n\{rules_block}\n\{views_block}\n</section>"
}

///|
fn render_manifest_view_html(
  entity : GuiManifestEntity,
  view : GuiManifestView,
) -> String {
  let state_label = find_manifest_state_label(entity, view.name)
  let fields : Array[String] = []
  let actions : Array[String] = []
  for field in view.fields {
    if field.mode != "hidden" {
      fields.push(render_manifest_field_html(field))
    }
  }
  for action in view.actions {
    actions.push(render_manifest_action_html(action))
  }
  let tabs = "<div class=\"state-heading\"><span class=\"state-title\">\{html_escape(state_label)}</span><span class=\"state-code\">\{html_escape(view.name)}</span></div>"
  let fields_block = render_div_block("field-grid", fields)
  let actions_block = render_div_block("action-list", actions)
  "<section class=\"view-card\" data-view=\"\{html_escape_attr(view.name)}\">\n\{tabs}\n\{fields_block}\n\{actions_block}\n</section>"
}

///|
fn render_manifest_field_html(field : GuiManifestField) -> String {
  let control = render_html_control(
    field.name,
    field.component,
    field.mode,
    None,
  )
  "<label class=\"field field--\{html_escape_attr(field.mode)}\"><span class=\"field-label\">\{html_escape(field.name)}</span>\{control}</label>"
}

///|
fn render_manifest_action_html(action : GuiManifestAction) -> String {
  let inputs : Array[String] = []
  for input in action.inputs {
    inputs.push(render_manifest_action_input_html(input))
  }
  let notes : Array[String] = []
  match action.enabled_when {
    Some(expr) => notes.push("<li>when: <code>\{html_escape(expr)}</code></li>")
    None => ()
  }
  match action.role {
    Some(role) => notes.push("<li>role: <code>\{html_escape(role)}</code></li>")
    None => ()
  }
  let note_block = if notes.length() == 0 {
    ""
  } else {
    let note_items = notes.join("\n")
    "<ul class=\"action-notes\">\n\{note_items}\n</ul>"
  }
  let inputs_block = render_div_block("action-inputs", inputs)
  "<section class=\"action-card\"><button type=\"button\" class=\"action-button\">\{html_escape(action.name)}</button><p class=\"action-target\">to \{html_escape(action.to)}</p>\{note_block}\n\{inputs_block}\n</section>"
}

///|
fn render_manifest_action_input_html(input : GuiManifestActionInput) -> String {
  let required_badge = if input.required {
    "<span class=\"required\">required</span>"
  } else {
    ""
  }
  let control = render_html_control(
    input.name,
    input.component,
    "editable",
    None,
  )
  "<label class=\"field action-input\"><span class=\"field-label\">\{html_escape(input.name)}</span><span class=\"field-meta\">\{html_escape(input.kind)} \{required_badge}</span>\{control}</label>"
}

///|
fn render_manifest_rule_html(rule : GuiManifestRule) -> String {
  "<li class=\"rule\"><span class=\"rule-name\">\{html_escape(rule.name)}</span><code>\{html_escape(rule.when_expr)}</code></li>"
}

///|
fn render_runtime_gui_view_html(
  schema : Schema,
  view : RuntimeGuiView,
) -> String {
  let entity = runtime_schema_entity(schema, view.entity_name)
  let state_label = runtime_schema_state_label(entity, view.state)
  let fields : Array[String] = []
  let actions : Array[String] = []
  let rules : Array[String] = []
  for field in view.fields {
    fields.push(render_runtime_field_html(field))
  }
  for action in view.actions {
    actions.push(render_runtime_action_html(action))
  }
  for rule in view.rules {
    rules.push(render_runtime_rule_html(rule))
  }
  let header = "<header class=\"page-header\"><h1>\{html_escape(entity.label)}</h1><p class=\"entity-name\">\{html_escape(entity.name)}</p>\{render_state_badge_html(view.state, state_label, true)}</header>"
  let fields_block = render_div_block("field-grid", fields)
  let actions_block = render_div_block("action-list", actions)
  let rules_block = render_list_block("Rules", "rule-list", rules)
  let body = "<section class=\"entity-page runtime-page\">\n\{header}\n<p class=\"view-name\">view: \{html_escape(view.view_name)}</p>\n\{fields_block}\n\{actions_block}\n\{rules_block}\n</section>"
  let title = "\{entity.label} - \{state_label}"
  render_html_document(title, body, lang=detect_document_lang(title, body))
}

///|
fn render_runtime_field_html(field : RuntimeGuiField) -> String {
  let control = render_html_control(
    field.name,
    field.component,
    field.mode,
    field.value,
  )
  "<label class=\"field field--\{html_escape_attr(field.mode)}\"><span class=\"field-label\">\{html_escape(field.name)}</span>\{control}</label>"
}

///|
fn render_runtime_action_html(action : RuntimeGuiAction) -> String {
  let inputs : Array[String] = []
  let issues : Array[String] = []
  for input in action.inputs {
    inputs.push(render_runtime_action_input_html(input))
  }
  for issue in action.issues {
    issues.push("<li>\{html_escape(issue.message)}</li>")
  }
  let disabled = if action.available { "" } else { " disabled" }
  let issues_block = if issues.length() == 0 {
    ""
  } else {
    let issue_items = issues.join("\n")
    "<ul class=\"issue-list\">\n\{issue_items}\n</ul>"
  }
  let inputs_block = render_div_block("action-inputs", inputs)
  "<section class=\"action-card\"><button type=\"button\" class=\"action-button\"\{disabled}>\{html_escape(action.name)}</button><p class=\"action-target\">to \{html_escape(action.to)}</p>\{issues_block}\n\{inputs_block}\n</section>"
}

///|
fn render_runtime_action_input_html(input : RuntimeGuiActionInput) -> String {
  let required_badge = if input.required {
    "<span class=\"required\">required</span>"
  } else {
    ""
  }
  let control = render_html_control(
    input.name,
    input.component,
    "editable",
    input.value,
  )
  "<label class=\"field action-input\"><span class=\"field-label\">\{html_escape(input.name)}</span><span class=\"field-meta\">\{html_escape(transition_input_kind_name(input.kind))} \{required_badge}</span>\{control}</label>"
}

///|
fn render_runtime_rule_html(rule : RuntimeRuleStatus) -> String {
  let status_class = if rule.active { "active" } else { "inactive" }
  let issue_suffix = if rule.issues.length() == 0 {
    ""
  } else {
    let messages = rule.issues.map(issue => issue.message).join("; ")
    "<span class=\"rule-issues\">\{html_escape(messages)}</span>"
  }
  "<li class=\"rule rule--\{status_class}\"><span class=\"rule-name\">\{html_escape(rule.name)}</span><span class=\"rule-state\">\{status_class}</span>\{issue_suffix}</li>"
}

///|
fn render_html_control(
  name : String,
  component : String,
  mode : String,
  value : RuntimeValue?,
  label? : String,
) -> String {
  let field_label = label.unwrap_or(name)
  let escaped_name = html_escape_attr(name)
  let value_text = runtime_value_to_html_value(value)
  let is_readonly = mode == "readonly"
  match component {
    "textarea" => {
      let readonly_attr = if is_readonly { " readonly" } else { "" }
      "<textarea name=\"\{escaped_name}\" class=\"control control--textarea\"\{readonly_attr}>\{html_escape(value_text)}</textarea>"
    }
    "checkbox" => {
      let checked = match value {
        Some(RuntimeValue::Flag(true)) => " checked"
        _ => ""
      }
      let disabled = if is_readonly { " disabled" } else { "" }
      "<input type=\"checkbox\" name=\"\{escaped_name}\" class=\"control control--checkbox\"\{checked}\{disabled}>"
    }
    "select" | "reference-select" => {
      let disabled = if is_readonly { " disabled" } else { "" }
      let option_value = if value_text == "" { "" } else { html_escape_attr(value_text) }
      let option_label = if value_text == "" { field_label } else { value_text }
      let option_attr =
        if option_value == "" {
          " selected"
        } else {
          " value=\"\{option_value}\" selected"
        }
      "<select name=\"\{escaped_name}\" class=\"control control--select\"\{disabled}><option\{option_attr}>\{html_escape(option_label)}</option></select>"
    }
    "state-badge" =>
      "<span class=\"state-badge state-badge--inline\">\{html_escape(value_text)}</span>"
    "file-upload" => {
      let disabled = if is_readonly { " disabled" } else { "" }
      "<input type=\"file\" name=\"\{escaped_name}\" class=\"control control--file\"\{disabled}>"
    }
    _ => {
      let html_type = html_input_type(component)
      let readonly_attr = if is_readonly { " readonly" } else { "" }
      let value_attr = if value_text == "" {
        ""
      } else {
        " value=\"\{html_escape_attr(value_text)}\""
      }
      "<input type=\"\{html_type}\" name=\"\{escaped_name}\" class=\"control control--\{html_escape_attr(component)}\"\{value_attr}\{readonly_attr}>"
    }
  }
}

///|
fn html_input_type(component : String) -> String {
  match component {
    "number" | "money" => "number"
    "date-picker" => "date"
    "datetime-picker" => "datetime-local"
    _ => "text"
  }
}

///|
fn render_html_document(
  title : String,
  body : String,
  lang? : String = "en",
) -> String {
  (
    $|<!DOCTYPE html>
    $|<html lang="\{html_escape_attr(lang)}">
    $|<head>
    $|  <meta charset="utf-8">
    $|  <meta name="viewport" content="width=device-width, initial-scale=1">
    $|  <title>\{html_escape(title)}</title>
    $|  <style>
    $|    body { font-family: sans-serif; line-height: 1.5; margin: 2rem; }
    $|    .entity-page { border: 1px solid #ddd; border-radius: 12px; padding: 1.5rem; margin-bottom: 2rem; }
    $|    .page-header { display: flex; gap: 1rem; align-items: center; flex-wrap: wrap; }
    $|    .entity-name, .view-name, .action-target { color: #666; margin: 0; }
    $|    .state-badge { display: inline-block; padding: 0.15rem 0.5rem; border-radius: 999px; background: #eef; margin-right: 0.5rem; }
    $|    .state-badge--current { font-weight: 700; background: #ddf; }
    $|    .field-grid, .action-list { display: grid; gap: 1rem; margin-top: 1rem; }
    $|    .field { display: grid; gap: 0.35rem; }
    $|    .field-meta, .required, .rule-state { font-size: 0.85rem; color: #666; }
    $|    .required { color: #b00; }
    $|    .control { padding: 0.5rem; border: 1px solid #ccc; border-radius: 8px; }
    $|    textarea.control { min-height: 6rem; }
    $|    .action-card, .view-card { border-top: 1px solid #eee; padding-top: 1rem; margin-top: 1rem; }
    $|    .action-button { padding: 0.5rem 0.9rem; border-radius: 8px; }
    $|    .issue-list, .rule-list, .state-list, .action-notes { margin: 0.5rem 0 0 1rem; }
    $|    .state-list { list-style: none; padding-left: 0; }
    $|    .state-list-item { list-style: none; }
    $|    .rule--active .rule-state { color: #070; }
    $|    .rule--inactive .rule-state { color: #999; }
    $|  </style>
    $|</head>
    $|<body>
    $|\{body}
    $|</body>
    $|</html>
  )
}

///|
fn detect_document_lang(title : String, body : String) -> String {
  if contains_japanese_text(title) || contains_japanese_text(body) {
    "ja"
  } else {
    "en"
  }
}

///|
fn contains_japanese_text(text : String) -> Bool {
  for char in text {
    match char {
      'ぁ'..='ゖ' | 'ァ'..='ヺ' | '一'..='龯' => return true
      _ => ()
    }
  }
  false
}

///|
fn render_div_block(class_name : String, items : Array[String]) -> String {
  if items.length() == 0 {
    ""
  } else {
    let body = items.join("\n")
    "<div class=\"\{class_name}\">\n\{body}\n</div>"
  }
}

///|
fn render_list_block(
  title : String,
  class_name : String,
  items : Array[String],
) -> String {
  if items.length() == 0 {
    ""
  } else {
    let body = items.join("\n")
    "<section class=\"\{class_name}-section\"><h2>\{html_escape(title)}</h2><ul class=\"\{class_name}\">\n\{body}\n</ul></section>"
  }
}

///|
fn render_state_badge_html(
  name : String,
  label : String,
  current : Bool,
) -> String {
  let current_class = if current { " state-badge--current" } else { "" }
  "<span class=\"state-badge\{current_class}\" data-state=\"\{html_escape_attr(name)}\">\{html_escape(label)}</span>"
}

///|
fn find_manifest_state_label(
  entity : GuiManifestEntity,
  state_name : String,
) -> String {
  for state in entity.states {
    if state.name == state_name {
      return state.label
    }
  }
  state_name
}

///|
fn runtime_schema_entity(schema : Schema, entity_name : String) -> Entity {
  for entity in schema.entities {
    if entity.name == entity_name {
      return entity
    }
  }
  abort("validated schema lost entity \{entity_name}")
}

///|
fn runtime_schema_state_label(entity : Entity, state_name : String) -> String {
  for state in entity.states {
    if state.name == state_name {
      return state.label
    }
  }
  state_name
}

///|
fn runtime_value_to_html_value(value : RuntimeValue?) -> String {
  match value {
    None | Some(RuntimeValue::Null) => ""
    Some(RuntimeValue::Text(text)) => text
    Some(RuntimeValue::Integer(number)) => "\{number}"
    Some(RuntimeValue::Flag(flag)) => if flag { "true" } else { "false" }
  }
}

///|
fn html_escape(text : String) -> String {
  let builder = StringBuilder::new()
  for char in text {
    match char {
      '&' => builder.write_string("&amp;")
      '<' => builder.write_string("&lt;")
      '>' => builder.write_string("&gt;")
      '"' => builder.write_string("&quot;")
      '\'' => builder.write_string("&#39;")
      _ => builder.write_char(char)
    }
  }
  builder.to_string()
}

///|
fn html_escape_attr(text : String) -> String {
  html_escape(text)
}
