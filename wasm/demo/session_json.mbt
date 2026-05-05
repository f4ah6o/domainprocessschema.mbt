///|
fn render_demo_session_snapshot_json(
  session : DemoSession,
  view : @schema.RuntimeGuiView,
) -> String {
  let fields = view.fields.map(render_demo_field_json).join(",")
  let actions = view.actions.map(render_demo_action_json).join(",")
  let actor_role = demo_actor_role(session.actor)
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"entityName\":\"\{json_escape(view.entity_name)}\",")
  builder.write_string("\"entityLabel\":\"\{json_escape(view.entity_label)}\",")
  builder.write_string("\"state\":\"\{json_escape(view.state)}\",")
  builder.write_string("\"stateLabel\":\"\{json_escape(view.state_label)}\",")
  builder.write_string("\"viewName\":\"\{json_escape(view.view_name)}\",")
  builder.write_string("\"actorRole\":\{json_string_or_null(actor_role)},")
  builder.write_string("\"fields\":[\{fields}],")
  builder.write_string("\"actions\":[\{actions}]")
  builder.write_string("}")
  builder.to_string()
}

///|
fn render_demo_field_json(field : @schema.RuntimeGuiField) -> String {
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"name\":\"\{json_escape(field.name)}\",")
  builder.write_string("\"label\":\"\{json_escape(field.label)}\",")
  builder.write_string("\"component\":\"\{json_escape(field.component)}\",")
  builder.write_string("\"mode\":\"\{json_escape(field.mode)}\",")
  builder.write_string("\"value\":\{demo_runtime_value_json(field.value)}")
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
  builder.write_string("\"label\":\"\{json_escape(input.label)}\",")
  builder.write_string("\"kind\":\"\{json_escape(kind)}\",")
  builder.write_string("\"component\":\"\{json_escape(input.component)}\",")
  builder.write_string("\"required\":\{required},")
  builder.write_string("\"value\":\{demo_runtime_value_json(input.value)}")
  builder.write_string("}")
  builder.to_string()
}

///|
fn render_demo_runtime_issue_json(issue : @schema.RuntimeIssue) -> String {
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"path\":\"\{json_escape(issue.path)}\",")
  builder.write_string("\"message\":\"\{json_escape(issue.message)}\"")
  builder.write_string("}")
  builder.to_string()
}

///|
fn render_demo_error_payload_json(
  kind : String,
  message : String,
  issues? : Array[@schema.RuntimeIssue] = [],
  entity? : String = "",
  transition? : String = "",
  expected? : String = "",
  found? : String = "",
) -> String {
  let issue_json = issues.map(render_demo_runtime_issue_json).join(",")
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"kind\":\"\{json_escape(kind)}\",")
  builder.write_string("\"message\":\"\{json_escape(message)}\",")
  if entity != "" {
    builder.write_string("\"entity\":\"\{json_escape(entity)}\",")
  }
  if transition != "" {
    builder.write_string("\"transition\":\"\{json_escape(transition)}\",")
  }
  if expected != "" {
    builder.write_string("\"expected\":\"\{json_escape(expected)}\",")
  }
  if found != "" {
    builder.write_string("\"found\":\"\{json_escape(found)}\",")
  }
  builder.write_string("\"issues\":[\{issue_json}]")
  builder.write_string("}")
  builder.to_string()
}

///|
fn render_demo_error_json(err : Error) -> String {
  match err {
    @schema.RuntimeError::UnknownEntity(entity~) =>
      render_demo_error_payload_json("unknown-entity", "\{err}", entity=entity)
    @schema.RuntimeError::EntityMismatch(expected~, found~) =>
      render_demo_error_payload_json(
        "entity-mismatch",
        "\{err}",
        expected=expected,
        found=found,
      )
    @schema.RuntimeError::UnknownTransition(entity~, transition~) =>
      render_demo_error_payload_json(
        "unknown-transition",
        "\{err}",
        entity=entity,
        transition=transition,
      )
    @schema.RuntimeError::MissingView(entity~, state~) =>
      render_demo_error_payload_json(
        "missing-view",
        "\{err}",
        entity=entity,
        found=state,
      )
    @schema.RuntimeError::InvalidRecord(entity~, issues~) =>
      render_demo_error_payload_json(
        "invalid-record",
        "\{err}",
        entity=entity,
        issues~,
      )
    @schema.RuntimeError::TransitionRejected(entity~, transition~, issues~) =>
      render_demo_error_payload_json(
        "transition-rejected",
        "\{err}",
        entity=entity,
        transition=transition,
        issues~,
      )
    _ => render_demo_error_payload_json("error", "\{err}")
  }
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
