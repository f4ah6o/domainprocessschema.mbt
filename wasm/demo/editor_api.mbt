///|
pub fn editor_compile_json(
  yaml : String,
  locale? : String = "",
) -> String {
  try {
    let parsed = @schema.parse_schema_yaml(yaml)
    let schema = @schema.validate_schema(parsed)
    render_editor_compile_success_json(schema, locale, yaml)
  } catch {
    err => render_editor_compile_error_json(err)
  }
}

///|
pub fn editor_runtime_preview_json(
  yaml : String,
  actor_role? : String = "",
  record_json? : String = "",
  locale? : String = "",
) -> String {
  try {
    let runtime = @schema.compile_runtime_from_yaml(yaml)
    let entity_name = editor_default_entity_name(runtime)
    let actor = actor_for_role(actor_role)
    let validation = editor_validation_from_record_json(
      runtime,
      entity_name,
      record_json,
    )
    if validation.issues.length() > 0 {
      return render_editor_runtime_failure_json(validation.record, validation.issues)
    }
    let view = @schema.project_gui(
      runtime,
      validation.record,
      actor=actor,
      locale~,
    )
    let html = @schema.render_runtime_gui_html(
      runtime,
      validation.record,
      actor=actor,
      locale~,
    )
    render_editor_runtime_success_json(validation.record, view, html)
  } catch {
    err => render_editor_compile_error_json(err)
  }
}

///|
pub fn editor_apply_transition_json(
  yaml : String,
  transition_name : String,
  input_json : String,
  actor_role? : String = "",
  record_json? : String = "",
  locale? : String = "",
) -> String {
  try {
    let runtime = @schema.compile_runtime_from_yaml(yaml)
    let entity_name = editor_default_entity_name(runtime)
    let actor = actor_for_role(actor_role)
    let validation = editor_validation_from_record_json(
      runtime,
      entity_name,
      record_json,
    )
    if validation.issues.length() > 0 {
      return render_editor_runtime_failure_json(validation.record, validation.issues)
    }
    let input = parse_demo_input_json(input_json)
    let next_record = @schema.apply_transition(
      runtime,
      validation.record,
      transition_name,
      input~,
      actor=actor,
    )
    let view = @schema.project_gui(
      runtime,
      next_record,
      actor=actor,
      locale~,
    )
    let html = @schema.render_runtime_gui_html(
      runtime,
      next_record,
      actor=actor,
      locale~,
    )
    render_editor_runtime_success_json(next_record, view, html)
  } catch {
    err => render_editor_compile_error_json(err)
  }
}

///|
fn render_editor_compile_success_json(
  schema : @schema.Schema,
  locale : String,
  source : String,
) -> String {
  let normalized = @schema.generate_normalized_schema(schema)
  let api_manifest = @schema.generate_api_manifest(schema)
  let validation_manifest = @schema.generate_validation_manifest(schema)
  let gui_manifest = @schema.generate_gui_manifest(schema, locale~)
  let emitted_yaml = @schema.emit_schema_yaml(schema)
  let entities = render_editor_entities_json(schema)
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"ok\":true,")
  builder.write_string("\"diagnostics\":[],")
  builder.write_string("\"source\":")
  write_json_string(builder, source)
  builder.write_string(",\"emittedYaml\":")
  write_json_string(builder, emitted_yaml)
  builder.write_string(",\"entities\":")
  builder.write_string(entities)
  builder.write_string(",\"normalizedSchema\":")
  builder.write_string(normalized)
  builder.write_string(",\"apiManifest\":")
  builder.write_string(api_manifest)
  builder.write_string(",\"validationManifest\":")
  builder.write_string(validation_manifest)
  builder.write_string(",\"guiManifest\":")
  builder.write_string(gui_manifest)
  builder.write_string(",\"previewHtml\":")
  write_json_string(builder, "")
  builder.write_char('}')
  builder.to_string()
}

///|
fn render_editor_compile_error_json(err : Error) -> String {
  match err {
    @schema.SchemaError::ParseError(issues~) |
    @schema.SchemaError::ValidationError(issues~) =>
      render_editor_diagnostics_only_json(issues)
    @schema.RuntimeError::InvalidRecord(issues~, ..) =>
      render_editor_diagnostics_only_json(issues)
    @schema.RuntimeError::TransitionRejected(issues~, ..) =>
      render_editor_diagnostics_only_json(issues)
    @schema.RuntimeError::UnknownEntity(entity~) =>
      render_editor_text_error_json("unknown-entity", "unknown entity \{entity}")
    @schema.RuntimeError::EntityMismatch(expected~, found~) =>
      render_editor_text_error_json(
        "entity-mismatch",
        "entity mismatch: expected \{expected}, found \{found}",
      )
    @schema.RuntimeError::UnknownTransition(entity~, transition~) =>
      render_editor_text_error_json(
        "unknown-transition",
        "unknown transition \{transition} for entity \{entity}",
      )
    @schema.RuntimeError::MissingView(entity~, state~) =>
      render_editor_text_error_json(
        "missing-view",
        "missing view for entity \{entity} state \{state}",
      )
    @schema.HtmlRenderError::InvalidGuiJson(message) =>
      render_editor_text_error_json("html-render", message)
    @schema.HtmlRenderError::InvalidGuiManifest(path~, message) =>
      render_editor_text_error_json("html-render", "\{path}: \{message}")
    other => render_editor_text_error_json("error", "\{other}")
  }
}

///|
fn render_editor_runtime_success_json(
  record : @schema.RuntimeRecord,
  view : @schema.RuntimeGuiView,
  html : String,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"ok\":true,")
  builder.write_string("\"diagnostics\":[],")
  builder.write_string("\"record\":")
  builder.write_string(render_runtime_record_json(record))
  builder.write_string(",\"view\":")
  builder.write_string(render_runtime_view_json(view))
  builder.write_string(",\"previewHtml\":")
  write_json_string(builder, html)
  builder.write_char('}')
  builder.to_string()
}

///|
fn render_editor_runtime_failure_json(
  record : @schema.RuntimeRecord,
  diagnostics : Array[@schema.Diagnostic],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"ok\":false,")
  builder.write_string("\"diagnostics\":")
  builder.write_string(render_schema_diagnostics_json(diagnostics))
  builder.write_string(",\"record\":")
  builder.write_string(render_runtime_record_json(record))
  builder.write_string(",\"view\":null,")
  builder.write_string("\"previewHtml\":null")
  builder.write_char('}')
  builder.to_string()
}

///|
fn render_editor_diagnostics_only_json(
  diagnostics : Array[@schema.Diagnostic],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"ok\":false,")
  builder.write_string("\"diagnostics\":")
  builder.write_string(render_schema_diagnostics_json(diagnostics))
  builder.write_string(",\"record\":null,")
  builder.write_string("\"view\":null,")
  builder.write_string("\"previewHtml\":null")
  builder.write_char('}')
  builder.to_string()
}

///|
fn render_editor_text_error_json(kind : String, message : String) -> String {
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"ok\":false,")
  builder.write_string("\"diagnostics\":[],")
  builder.write_string("\"error\":{")
  builder.write_string("\"kind\":")
  write_json_string(builder, kind)
  builder.write_string(",\"message\":")
  write_json_string(builder, message)
  builder.write_string("},\"record\":null,\"view\":null,\"previewHtml\":null")
  builder.write_char('}')
  builder.to_string()
}

///|
fn editor_validation_from_record_json(
  runtime : @schema.Runtime,
  fallback_entity_name : String,
  record_json : String,
) -> @schema.RuntimeValidation raise {
  let (entity_name, payload) = editor_record_payload_from_json(
    fallback_entity_name,
    record_json,
    runtime,
  )
  @schema.validate_record(runtime, entity_name, payload)
}

///|
fn editor_record_payload_from_json(
  fallback_entity_name : String,
  record_json : String,
  runtime : @schema.Runtime,
) -> (String, Map[String, @schema.RuntimeValue]) raise {
  if record_json.length() > 1_000_000 {
    raise @builtin.Failure::Failure("record_json exceeds 1 MB editor limit")
  }
  if record_json.trim() == "" {
    let entity = editor_find_entity(runtime, fallback_entity_name)
    return (fallback_entity_name, build_editor_seed_payload(entity))
  }
  let json = @json.parse(record_json[:])
  match json {
    Json::Object(entries) => {
      let entity_name = match entries.get("entityName") {
        Some(Json::String(name)) => name
        _ => fallback_entity_name
      }
      match entries.get("values") {
        Some(values_json) =>
          (entity_name, json_to_runtime_value_map(values_json, "record.values"))
        None => (entity_name, json_to_runtime_value_map(json, "record"))
      }
    }
    _ =>
      raise @builtin.Failure::Failure(
        "record must be a JSON object or { entityName, values } object",
      )
  }
}

///|
/// Editor preview endpoints choose the first entity that has states or a
/// state field so the runtime pane defaults to a workflow-shaped schema.
/// If none exist, the first declared entity is used.
fn editor_default_entity_name(runtime : @schema.Runtime) -> String raise {
  if runtime.schema.entities.length() == 0 {
    raise @builtin.Failure::Failure("schema does not define any entities")
  }
  for entity in runtime.schema.entities {
    if entity.states.length() > 0 {
      return entity.name
    }
    for field in entity.fields {
      if field.field_type == @schema.FieldType::State {
        return entity.name
      }
    }
  }
  runtime.schema.entities[0].name
}

///|
fn editor_find_entity(
  runtime : @schema.Runtime,
  entity_name : String,
) -> @schema.Entity raise {
  for entity in runtime.schema.entities {
    if entity.name == entity_name {
      return entity
    }
  }
  raise @builtin.Failure::Failure("unknown entity \{entity_name}")
}

///|
fn build_editor_seed_payload(
  entity : @schema.Entity,
) -> Map[String, @schema.RuntimeValue] {
  let payload : Map[String, @schema.RuntimeValue] = {}
  for field in entity.fields {
    if field.system {
      continue
    }
    match field.initial {
      Some(initial) => payload[field.name] = @schema.RuntimeValue::Text(initial)
      None =>
        match field.default_value {
          Some(raw) => payload[field.name] = @schema.RuntimeValue::Text(raw)
          None =>
            if field.required {
              payload[field.name] = editor_placeholder_value(entity, field)
            }
        }
    }
  }
  payload
}

///|
fn editor_placeholder_value(
  entity : @schema.Entity,
  field : @schema.Field,
) -> @schema.RuntimeValue {
  match field.field_type {
    @schema.FieldType::Number | @schema.FieldType::Money =>
      @schema.RuntimeValue::Integer(1)
    @schema.FieldType::Boolean => @schema.RuntimeValue::Flag(false)
    @schema.FieldType::State =>
      match field.initial {
        Some(initial) => @schema.RuntimeValue::Text(initial)
        None =>
          if entity.states.length() == 0 {
            @schema.RuntimeValue::Text(field.name)
          } else {
            @schema.RuntimeValue::Text(entity.states[0].name)
          }
      }
    _ => @schema.RuntimeValue::Text(field.name)
  }
}

///|
fn render_editor_entities_json(schema : @schema.Schema) -> String {
  let builder = StringBuilder::new()
  builder.write_char('[')
  for i in 0..<schema.entities.length() {
    if i > 0 {
      builder.write_char(',')
    }
    let entity = schema.entities[i]
    builder.write_string("{\"name\":")
    write_json_string(builder, entity.name)
    builder.write_string(",\"label\":")
    write_json_string(builder, entity.label)
    builder.write_char('}')
  }
  builder.write_char(']')
  builder.to_string()
}

///|
fn render_schema_diagnostics_json(
  diagnostics : Array[@schema.Diagnostic],
) -> String {
  let builder = StringBuilder::new()
  builder.write_char('[')
  for i in 0..<diagnostics.length() {
    if i > 0 {
      builder.write_char(',')
    }
    let diagnostic = diagnostics[i]
    builder.write_string("{\"code\":")
    write_json_string(builder, diagnostic.code)
    builder.write_string(",\"severity\":")
    write_json_string(builder, render_schema_severity_text(diagnostic.severity))
    builder.write_string(",\"target\":")
    write_json_string(builder, diagnostic.target)
    builder.write_string(",\"message\":")
    write_json_string(builder, diagnostic.message)
    builder.write_string(",\"hint\":")
    match diagnostic.hint {
      Some(hint) => write_json_string(builder, hint)
      None => builder.write_string("null")
    }
    builder.write_string(",\"context\":")
    builder.write_string(render_string_context_json(diagnostic.context))
    builder.write_char('}')
  }
  builder.write_char(']')
  builder.to_string()
}

///|
fn render_string_context_json(values : Map[String, String]) -> String {
  let keys : Array[String] = []
  for key, _ in values {
    keys.push(key)
  }
  sort_strings(keys)
  let builder = StringBuilder::new()
  builder.write_char('{')
  for i in 0..<keys.length() {
    if i > 0 {
      builder.write_char(',')
    }
    let key = keys[i]
    builder.write_string("\"")
    builder.write_string(json_escape(key))
    builder.write_string("\":")
    write_json_string(builder, values.get(key).unwrap_or(""))
  }
  builder.write_char('}')
  builder.to_string()
}

///|
fn render_schema_severity_text(
  severity : @schema.DiagnosticSeverity,
) -> String {
  match severity {
    @schema.DiagnosticSeverity::Error => "error"
    @schema.DiagnosticSeverity::Warning => "warning"
    @schema.DiagnosticSeverity::Info => "info"
  }
}

///|
fn render_runtime_record_json(record : @schema.RuntimeRecord) -> String {
  let keys : Array[String] = []
  for key, _ in record.values {
    keys.push(key)
  }
  sort_strings(keys)
  let builder = StringBuilder::new()
  builder.write_string("{\"entityName\":")
  write_json_string(builder, record.entity_name)
  builder.write_string(",\"values\":{")
  for i in 0..<keys.length() {
    if i > 0 {
      builder.write_char(',')
    }
    let key = keys[i]
    builder.write_string("\"")
    builder.write_string(json_escape(key))
    builder.write_string("\":")
    builder.write_string(
      demo_runtime_value_json(record.values.get(key)),
    )
  }
  builder.write_string("}}")
  builder.to_string()
}

///|
fn render_runtime_view_json(view : @schema.RuntimeGuiView) -> String {
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"entityName\":")
  write_json_string(builder, view.entity_name)
  builder.write_string(",\"entityLabel\":")
  write_json_string(builder, view.entity_label)
  builder.write_string(",\"state\":")
  write_json_string(builder, view.state)
  builder.write_string(",\"stateLabel\":")
  write_json_string(builder, view.state_label)
  builder.write_string(",\"viewName\":")
  write_json_string(builder, view.view_name)
  builder.write_string(",\"fields\":")
  builder.write_string(render_runtime_view_fields_json(view.fields))
  builder.write_string(",\"actions\":")
  builder.write_string(render_runtime_view_actions_json(view.actions))
  builder.write_string(",\"rules\":")
  builder.write_string(render_runtime_view_rules_json(view.rules))
  builder.write_char('}')
  builder.to_string()
}

///|
fn render_runtime_view_fields_json(
  fields : Array[@schema.RuntimeGuiField],
) -> String {
  let builder = StringBuilder::new()
  builder.write_char('[')
  for i in 0..<fields.length() {
    if i > 0 {
      builder.write_char(',')
    }
    let field = fields[i]
    builder.write_string("{\"name\":")
    write_json_string(builder, field.name)
    builder.write_string(",\"label\":")
    write_json_string(builder, field.label)
    builder.write_string(",\"component\":")
    write_json_string(builder, field.component)
    builder.write_string(",\"mode\":")
    write_json_string(builder, field.mode)
    builder.write_string(",\"value\":")
    builder.write_string(demo_runtime_value_json(field.value))
    builder.write_char('}')
  }
  builder.write_char(']')
  builder.to_string()
}

///|
fn render_runtime_view_actions_json(
  actions : Array[@schema.RuntimeGuiAction],
) -> String {
  let builder = StringBuilder::new()
  builder.write_char('[')
  for i in 0..<actions.length() {
    if i > 0 {
      builder.write_char(',')
    }
    let action = actions[i]
    builder.write_string("{\"name\":")
    write_json_string(builder, action.name)
    builder.write_string(",\"to\":")
    write_json_string(builder, action.to)
    builder.write_string(",\"available\":")
    builder.write_string(if action.available { "true" } else { "false" })
    builder.write_string(",\"issues\":")
    builder.write_string(render_schema_diagnostics_json(action.issues))
    builder.write_string(",\"inputs\":")
    builder.write_string(render_runtime_view_action_inputs_json(action.inputs))
    builder.write_char('}')
  }
  builder.write_char(']')
  builder.to_string()
}

///|
fn render_runtime_view_action_inputs_json(
  inputs : Array[@schema.RuntimeGuiActionInput],
) -> String {
  let builder = StringBuilder::new()
  builder.write_char('[')
  for i in 0..<inputs.length() {
    if i > 0 {
      builder.write_char(',')
    }
    let input = inputs[i]
    builder.write_string("{\"name\":")
    write_json_string(builder, input.name)
    builder.write_string(",\"label\":")
    write_json_string(builder, input.label)
    builder.write_string(",\"kind\":")
    write_json_string(builder, demo_input_kind_name(input.kind))
    builder.write_string(",\"component\":")
    write_json_string(builder, input.component)
    builder.write_string(",\"required\":")
    builder.write_string(if input.required { "true" } else { "false" })
    builder.write_string(",\"value\":")
    builder.write_string(demo_runtime_value_json(input.value))
    builder.write_char('}')
  }
  builder.write_char(']')
  builder.to_string()
}

///|
fn render_runtime_view_rules_json(
  rules : Array[@schema.RuntimeRuleStatus],
) -> String {
  let builder = StringBuilder::new()
  builder.write_char('[')
  for i in 0..<rules.length() {
    if i > 0 {
      builder.write_char(',')
    }
    let rule = rules[i]
    builder.write_string("{\"name\":")
    write_json_string(builder, rule.name)
    builder.write_string(",\"active\":")
    builder.write_string(if rule.active { "true" } else { "false" })
    builder.write_string(",\"issues\":")
    builder.write_string(render_schema_diagnostics_json(rule.issues))
    builder.write_char('}')
  }
  builder.write_char(']')
  builder.to_string()
}

///|
fn write_json_string(builder : StringBuilder, value : String) -> Unit {
  builder.write_char('"')
  builder.write_string(json_escape(value))
  builder.write_char('"')
}

///|
fn sort_strings(values : Array[String]) -> Unit {
  let n = values.length()
  for i in 1..<n {
    let current = values[i]
    let mut j = i
    while j > 0 && values[j - 1] > current {
      values[j] = values[j - 1]
      j = j - 1
    }
    values[j] = current
  }
}
