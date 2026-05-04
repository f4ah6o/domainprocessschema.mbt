///|
fn render_gui_manifest(schema : Schema) -> String {
  let rendered_entities : Array[String] = []
  for entity in schema.entities {
    rendered_entities.push(render_gui_entity(entity))
  }
  let entities_block = indent_block(rendered_entities.join(",\n"), 4)
  "{\n  \"entities\": [\n\{entities_block}\n  ]\n}"
}

///|
fn render_gui_entity(entity : Entity) -> String {
  let rendered_states : Array[String] = []
  let rendered_views : Array[String] = []
  let rendered_rules : Array[String] = []

  for state in entity.states {
    rendered_states.push(render_gui_state(state))
  }
  for view in entity.views {
    rendered_views.push(render_gui_view(entity, view))
  }
  for rule in entity.rules {
    rendered_rules.push(render_gui_rule(rule))
  }

  let body_lines = [
    "\"name\": \{json_quote(entity.name)}",
    "\"label\": \{json_quote(entity.label)}",
    render_named_object_array("states", rendered_states),
    render_named_object_array("views", rendered_views),
    render_named_object_array("rules", rendered_rules),
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_gui_state(state : State) -> String {
  let body_lines = [
    "\"name\": \{json_quote(state.name)}",
    "\"label\": \{json_quote(state.label)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_gui_view(entity : Entity, view : View) -> String {
  let rendered_controls : Array[String] = []
  let rendered_actions : Array[String] = []

  for field in entity.fields {
    rendered_controls.push(render_gui_field_control(field, view))
  }
  for transition in entity.transitions {
    if transition.from == view.name {
      rendered_actions.push(render_gui_action(transition))
    }
  }

  let body_lines = [
    "\"name\": \{json_quote(view.name)}",
    render_named_object_array("fields", rendered_controls),
    render_named_object_array("actions", rendered_actions),
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_gui_field_control(field : Field, view : View) -> String {
  let mode = gui_field_mode(field, view)
  let body_lines = [
    "\"name\": \{json_quote(field.name)}",
    "\"component\": \{json_quote(gui_component(field.field_type))}",
    "\"mode\": \{json_quote(mode)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_gui_action(transition : Transition) -> String {
  let rendered_inputs : Array[String] = []
  for input in transition.inputs {
    rendered_inputs.push(render_gui_action_input(input))
  }
  let body_lines = [
    "\"name\": \{json_quote(transition.name)}",
    "\"to\": \{json_quote(transition.to)}",
    render_named_object_array("inputs", rendered_inputs),
    "\"enabledWhen\": \{json_optional_expr(transition.guard_expr)}",
    "\"role\": \{json_optional_string(transition.role)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_gui_action_input(input : TransitionInput) -> String {
  let body_lines = [
    "\"name\": \{json_quote(input.name)}",
    "\"kind\": \{json_quote(transition_input_kind_name(input.kind))}",
    "\"component\": \{json_quote(gui_component(input.field_type))}",
    "\"required\": \{json_bool(input.required)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_gui_rule(rule : Rule) -> String {
  let body_lines = [
    "\"name\": \{json_quote(rule.name)}",
    "\"when\": \{json_quote(expr_to_string(rule.when_expr))}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn gui_field_mode(field : Field, view : View) -> String {
  if field.system || field.read_only {
    "readonly"
  } else if string_array_contains(view.editable_fields, field.name) {
    "editable"
  } else if string_array_contains(view.readonly_fields, field.name) {
    "readonly"
  } else {
    "hidden"
  }
}

///|
fn gui_component(field_type : FieldType) -> String {
  match field_type {
    FieldType::Id => "text"
    FieldType::Text => "textarea"
    FieldType::Number => "number"
    FieldType::Money => "money"
    FieldType::Boolean => "checkbox"
    FieldType::Date => "date-picker"
    FieldType::DateTime => "datetime-picker"
    FieldType::Enum => "select"
    FieldType::Ref => "reference-select"
    FieldType::State => "state-badge"
    FieldType::File => "file-upload"
  }
}
