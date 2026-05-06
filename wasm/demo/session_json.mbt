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
fn render_demo_reference_catalog_json(
  runtime : @schema.Runtime,
  locale : String,
) -> String {
  let target_names = collect_demo_reference_targets(runtime)
  let targets = target_names
    .map(target => render_demo_reference_target_json(runtime, target, locale))
    .join(",")
  "{ \"targets\": [\{targets}] }"
}

///|
fn collect_demo_reference_targets(runtime : @schema.Runtime) -> Array[String] {
  let targets : Array[String] = []
  let seen : Map[String, Bool] = {}
  for entity in runtime.schema.entities {
    for field in entity.fields {
      match field.target {
        Some(target) =>
          if !seen.contains(target) {
            seen[target] = true
            targets.push(target)
          }
        None => ()
      }
    }
    for transition in entity.transitions {
      for input in transition.inputs {
        match input.target {
          Some(target) =>
            if !seen.contains(target) {
              seen[target] = true
              targets.push(target)
            }
          None => ()
        }
      }
    }
  }
  targets
}

///|
fn render_demo_reference_target_json(
  runtime : @schema.Runtime,
  target : String,
  locale : String,
) -> String {
  let label = demo_entity_label(runtime, target, locale)
  let options = demo_reference_options_for_target(runtime, target, locale).join(
    ",",
  )
  "{ \"name\": \"\{json_escape(target)}\", \"label\": \"\{json_escape(label)}\", \"options\": [\{options}] }"
}

///|
fn demo_reference_options_for_target(
  runtime : @schema.Runtime,
  target : String,
  locale : String,
) -> Array[String] {
  match target {
    "User" => {
      let target_label = demo_entity_label(runtime, target, locale)
      [
        render_demo_reference_option_json(
          "user-1",
          "\{target_label} user-1 (employee)",
        ),
        render_demo_reference_option_json(
          "user-2",
          "\{target_label} user-2 (manager)",
        ),
      ]
    }
    _ => []
  }
}

///|
fn render_demo_reference_option_json(value : String, label : String) -> String {
  "{ \"value\": \"\{json_escape(value)}\", \"label\": \"\{json_escape(label)}\" }"
}

///|
fn demo_entity_label(
  runtime : @schema.Runtime,
  entity_name : String,
  locale : String,
) -> String {
  for entity in runtime.schema.entities {
    if entity.name == entity_name {
      return @schema.resolve_localized_text(entity.label, entity.labels, locale)
    }
  }
  entity_name
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
fn render_demo_runtime_issue_json(issue : @schema.Diagnostic) -> String {
  let severity = match issue.severity {
    @schema.DiagnosticSeverity::Error => "error"
    @schema.DiagnosticSeverity::Warning => "warning"
    @schema.DiagnosticSeverity::Info => "info"
  }
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"code\":\"\{json_escape(issue.code)}\",")
  builder.write_string("\"severity\":\"\{json_escape(severity)}\",")
  builder.write_string("\"target\":\"\{json_escape(issue.target)}\",")
  builder.write_string("\"message\":\"\{json_escape(issue.message)}\"")
  builder.write_string("}")
  builder.to_string()
}

///|
fn render_demo_error_payload_json(
  kind : String,
  message : String,
  issues? : Array[@schema.Diagnostic] = [],
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
      render_demo_error_payload_json("unknown-entity", "\{err}", entity~)
    @schema.RuntimeError::EntityMismatch(expected~, found~) =>
      render_demo_error_payload_json(
        "entity-mismatch",
        "\{err}",
        expected~,
        found~,
      )
    @schema.RuntimeError::UnknownTransition(entity~, transition~) =>
      render_demo_error_payload_json(
        "unknown-transition",
        "\{err}",
        entity~,
        transition~,
      )
    @schema.RuntimeError::MissingView(entity~, state~) =>
      render_demo_error_payload_json(
        "missing-view",
        "\{err}",
        entity~,
        found=state,
      )
    @schema.RuntimeError::InvalidRecord(entity~, issues~) =>
      render_demo_error_payload_json(
        "invalid-record",
        "\{err}",
        entity~,
        issues~,
      )
    @schema.RuntimeError::TransitionRejected(entity~, transition~, issues~) =>
      render_demo_error_payload_json(
        "transition-rejected",
        "\{err}",
        entity~,
        transition~,
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
