///|
fn render_demo_session_snapshot_json(
  session : DemoSession,
  view : @schema.RuntimeGuiView,
) -> String {
  let actions = view.actions.map(render_demo_action_json).join(",")
  let actor_role = demo_actor_role(session.actor)
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"entityName\":\"\{json_escape(view.entity_name)}\",")
  builder.write_string("\"state\":\"\{json_escape(view.state)}\",")
  builder.write_string("\"viewName\":\"\{json_escape(view.view_name)}\",")
  builder.write_string("\"actorRole\":\{json_string_or_null(actor_role)},")
  builder.write_string("\"actions\":[\{actions}]")
  builder.write_string("}")
  builder.to_string()
}

///|
fn render_demo_action_json(action : @schema.RuntimeGuiAction) -> String {
  let issues = action.issues
    .map(issue => "\"\{json_escape(issue.message)}\"")
    .join(",")
  let inputs = action.inputs.map(render_demo_action_input_json).join(",")
  let available = if action.available { "true" } else { "false" }
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"name\":\"\{json_escape(action.name)}\",")
  builder.write_string("\"to\":\"\{json_escape(action.to)}\",")
  builder.write_string("\"available\":\{available},")
  builder.write_string("\"issues\":[\{issues}],")
  builder.write_string("\"inputs\":[\{inputs}]")
  builder.write_string("}")
  builder.to_string()
}

///|
fn render_demo_action_input_json(
  input : @schema.RuntimeGuiActionInput,
) -> String {
  let kind = demo_input_kind_name(input.kind)
  let required = if input.required { "true" } else { "false" }
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"name\":\"\{json_escape(input.name)}\",")
  builder.write_string("\"kind\":\"\{json_escape(kind)}\",")
  builder.write_string("\"component\":\"\{json_escape(input.component)}\",")
  builder.write_string("\"required\":\{required},")
  builder.write_string("\"value\":\{demo_runtime_value_json(input.value)}")
  builder.write_string("}")
  builder.to_string()
}

///|
fn demo_input_kind_name(kind : @schema.TransitionInputKind) -> String {
  match kind {
    @schema.TransitionInputKind::EntityField => "entity-field"
    @schema.TransitionInputKind::Local => "local"
  }
}

///|
fn demo_runtime_value_json(value : @schema.RuntimeValue?) -> String {
  match value {
    None | Some(@schema.RuntimeValue::Null) => "null"
    Some(@schema.RuntimeValue::Text(text)) => "\"\{json_escape(text)}\""
    Some(@schema.RuntimeValue::Integer(number)) => "\{number}"
    Some(@schema.RuntimeValue::Flag(flag)) =>
      if flag {
        "true"
      } else {
        "false"
      }
  }
}

///|
fn demo_actor_role(actor : @schema.RuntimeActor) -> String? {
  match actor.attributes.get("role") {
    Some(@schema.RuntimeValue::Text(role)) => Some(role)
    _ => None
  }
}

///|
fn json_string_or_null(value : String?) -> String {
  match value {
    Some(text) => "\"\{json_escape(text)}\""
    None => "null"
  }
}

///|
fn json_escape(text : String) -> String {
  let builder = StringBuilder::new()
  for char in text {
    match char {
      '\\' => builder.write_string("\\\\")
      '"' => builder.write_string("\\\"")
      '\n' => builder.write_string("\\n")
      '\r' => builder.write_string("\\r")
      '\t' => builder.write_string("\\t")
      _ => builder.write_char(char)
    }
  }
  builder.to_string()
}
