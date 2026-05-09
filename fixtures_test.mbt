///|
/// Golden fixture contract tests for the expense_request scenario.
///
/// Each test reads the input from fixtures/expense_request/input.yaml,
/// runs the corresponding compile_*_from_yaml entry point, and compares
/// the result against the expected.* file in the same directory.
/// When generators change shape, these tests fail and the diff shows the
/// contract delta.

///|
fn load_fixture(name : String) -> String raise {
  @fs.read_file_to_string("fixtures/expense_request/\{name}")
}

///|
test "golden: normalized-schema" {
  let input = load_fixture("input.yaml")
  let expected = load_fixture("expected.normalized-schema.json")
  let actual = compile_normalized_schema_from_yaml(input)
  assert_eq(actual.trim_end().to_string(), expected.trim_end().to_string())
}

///|
test "golden: api-manifest" {
  let input = load_fixture("input.yaml")
  let expected = load_fixture("expected.api-manifest.json")
  let actual = compile_api_manifest_from_yaml(input)
  assert_eq(actual.trim_end().to_string(), expected.trim_end().to_string())
}

///|
test "golden: validation-manifest" {
  let input = load_fixture("input.yaml")
  let expected = load_fixture("expected.validation-manifest.json")
  let actual = compile_validation_manifest_from_yaml(input)
  assert_eq(actual.trim_end().to_string(), expected.trim_end().to_string())
}

///|
test "golden: gui-manifest" {
  let input = load_fixture("input.yaml")
  let expected = load_fixture("expected.gui-manifest.json")
  let actual = compile_gui_manifest_from_yaml(input)
  assert_eq(actual.trim_end().to_string(), expected.trim_end().to_string())
}

///|
test "golden: gui-html" {
  let input = load_fixture("input.yaml")
  let expected = load_fixture("expected.gui-html.html")
  let actual = compile_gui_html_from_yaml(input)
  assert_eq(actual.trim_end().to_string(), expected.trim_end().to_string())
}

///|
test "golden: schema.sql" {
  let input = load_fixture("input.yaml")
  let expected = load_fixture("expected.schema.sql")
  let actual = compile_sql_from_yaml(input)
  assert_eq(actual.trim_end().to_string(), expected.trim_end().to_string())
}

///|
test "golden: migration up/down" {
  let input = load_fixture("input.yaml")
  let combined = compile_migration_sql_from_yaml(input)
  let marker = "-- migrate:down"
  match combined.split_once(marker) {
    Some((up_part, down_rest)) => {
      let up = up_part.trim_end().to_string()
      let down = (marker + down_rest.to_string()).trim_end().to_string()
      let expected_up = load_fixture("expected.migration.up.sql")
        .trim_end()
        .to_string()
      let expected_down = load_fixture("expected.migration.down.sql")
        .trim_end()
        .to_string()
      assert_eq(up, expected_up)
      assert_eq(down, expected_down)
    }
    None =>
      fail("compile_migration_sql_from_yaml output missing `\{marker}` marker")
  }
}

///|
test "golden: runtime-projection" {
  let input = load_fixture("input.yaml")
  let expected = load_fixture("expected.runtime-projection.json")
  let runtime = compile_runtime_from_yaml(input)
  let draft = validate_record(runtime, "ExpenseRequest", fixture_draft_payload())
    .record
  let submitted = apply_transition(runtime, draft, "submit", input={
    "amount": RuntimeValue::Integer(1200),
    "reason": RuntimeValue::Text("hotel"),
    "applicant": RuntimeValue::Text("user-1"),
  })
  let view = project_gui(runtime, submitted, actor=fixture_manager_actor())
  let actual = render_fixture_runtime_view_json(view)
  assert_eq(actual.trim_end().to_string(), expected.trim_end().to_string())
}

///|
fn fixture_draft_payload() -> Map[String, RuntimeValue] {
  {
    "id": RuntimeValue::Text("exp-1"),
    "amount": RuntimeValue::Integer(1200),
    "reason": RuntimeValue::Text("hotel"),
    "applicant": RuntimeValue::Text("user-1"),
  }
}

///|
fn fixture_manager_actor() -> RuntimeActor {
  RuntimeActor::{ attributes: { "role": RuntimeValue::Text("manager") } }
}

///|
fn render_fixture_runtime_view_json(view : RuntimeGuiView) -> String {
  let builder = StringBuilder::new()
  builder.write_string("{\n")
  builder.write_string("  \"entityName\": ")
  fixture_write_json_string(builder, view.entity_name)
  builder.write_string(",\n  \"entityLabel\": ")
  fixture_write_json_string(builder, view.entity_label)
  builder.write_string(",\n  \"state\": ")
  fixture_write_json_string(builder, view.state)
  builder.write_string(",\n  \"stateLabel\": ")
  fixture_write_json_string(builder, view.state_label)
  builder.write_string(",\n  \"viewName\": ")
  fixture_write_json_string(builder, view.view_name)
  builder.write_string(",\n  \"fields\": ")
  builder.write_string(render_fixture_runtime_fields_json(view.fields))
  builder.write_string(",\n  \"actions\": ")
  builder.write_string(render_fixture_runtime_actions_json(view.actions))
  builder.write_string(",\n  \"rules\": ")
  builder.write_string(render_fixture_runtime_rules_json(view.rules))
  builder.write_string("\n}")
  builder.to_string()
}

///|
fn render_fixture_runtime_fields_json(fields : Array[RuntimeGuiField]) -> String {
  let builder = StringBuilder::new()
  builder.write_string("[\n")
  for i in 0..<fields.length() {
    if i > 0 {
      builder.write_string(",\n")
    }
    let field = fields[i]
    builder.write_string("    { \"name\": ")
    fixture_write_json_string(builder, field.name)
    builder.write_string(", \"label\": ")
    fixture_write_json_string(builder, field.label)
    builder.write_string(", \"component\": ")
    fixture_write_json_string(builder, field.component)
    builder.write_string(", \"mode\": ")
    fixture_write_json_string(builder, field.mode)
    builder.write_string(", \"value\": ")
    builder.write_string(fixture_runtime_value_json(field.value))
    builder.write_string(" }")
  }
  builder.write_string("\n  ]")
  builder.to_string()
}

///|
fn render_fixture_runtime_actions_json(
  actions : Array[RuntimeGuiAction],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("[\n")
  for i in 0..<actions.length() {
    if i > 0 {
      builder.write_string(",\n")
    }
    let action = actions[i]
    builder.write_string("    {\n")
    builder.write_string("      \"name\": ")
    fixture_write_json_string(builder, action.name)
    builder.write_string(",\n      \"to\": ")
    fixture_write_json_string(builder, action.to)
    builder.write_string(",\n      \"available\": ")
    builder.write_string(if action.available { "true" } else { "false" })
    builder.write_string(",\n      \"issues\": ")
    builder.write_string(render_fixture_diagnostics_json(action.issues, 6))
    builder.write_string(",\n      \"inputs\": ")
    builder.write_string(render_fixture_runtime_action_inputs_json(action.inputs))
    builder.write_string("\n    }")
  }
  builder.write_string("\n  ]")
  builder.to_string()
}

///|
fn render_fixture_runtime_action_inputs_json(
  inputs : Array[RuntimeGuiActionInput],
) -> String {
  let builder = StringBuilder::new()
  if inputs.length() == 0 {
    return "[]"
  }
  builder.write_string("[\n")
  for i in 0..<inputs.length() {
    if i > 0 {
      builder.write_string(",\n")
    }
    let input = inputs[i]
    builder.write_string("        { \"name\": ")
    fixture_write_json_string(builder, input.name)
    builder.write_string(", \"label\": ")
    fixture_write_json_string(builder, input.label)
    builder.write_string(", \"kind\": ")
    fixture_write_json_string(builder, fixture_transition_input_kind(input.kind))
    builder.write_string(", \"component\": ")
    fixture_write_json_string(builder, input.component)
    builder.write_string(", \"required\": ")
    builder.write_string(if input.required { "true" } else { "false" })
    builder.write_string(", \"value\": ")
    builder.write_string(fixture_runtime_value_json(input.value))
    builder.write_string(" }")
  }
  builder.write_string("\n      ]")
  builder.to_string()
}

///|
fn render_fixture_runtime_rules_json(rules : Array[RuntimeRuleStatus]) -> String {
  let builder = StringBuilder::new()
  builder.write_string("[\n")
  for i in 0..<rules.length() {
    if i > 0 {
      builder.write_string(",\n")
    }
    let rule = rules[i]
    builder.write_string("    { \"name\": ")
    fixture_write_json_string(builder, rule.name)
    builder.write_string(", \"active\": ")
    builder.write_string(if rule.active { "true" } else { "false" })
    builder.write_string(", \"issues\": ")
    builder.write_string(render_fixture_diagnostics_json(rule.issues, 4))
    builder.write_string(" }")
  }
  builder.write_string("\n  ]")
  builder.to_string()
}

///|
fn render_fixture_diagnostics_json(
  issues : Array[Diagnostic],
  _indent : Int,
) -> String {
  let builder = StringBuilder::new()
  builder.write_char('[')
  for i in 0..<issues.length() {
    if i > 0 {
      builder.write_char(',')
    }
    let issue = issues[i]
    builder.write_string("{\"code\":")
    fixture_write_json_string(builder, issue.code)
    builder.write_string(",\"severity\":")
    fixture_write_json_string(builder, fixture_diagnostic_severity(issue.severity))
    builder.write_string(",\"target\":")
    fixture_write_json_string(builder, issue.target)
    builder.write_string(",\"message\":")
    fixture_write_json_string(builder, issue.message)
    builder.write_string(",\"hint\":")
    builder.write_string(fixture_optional_string_json(issue.hint))
    builder.write_string(",\"context\":")
    builder.write_string(render_fixture_context_json(issue.context))
    builder.write_char('}')
  }
  builder.write_char(']')
  builder.to_string()
}

///|
fn render_fixture_context_json(context : Map[String, String]) -> String {
  let keys : Array[String] = []
  for key, _ in context {
    keys.push(key)
  }
  fixture_sort_strings(keys)
  let builder = StringBuilder::new()
  builder.write_char('{')
  for i in 0..<keys.length() {
    if i > 0 {
      builder.write_char(',')
    }
    let key = keys[i]
    fixture_write_json_string(builder, key)
    builder.write_char(':')
    fixture_write_json_string(builder, context.get(key).unwrap_or(""))
  }
  builder.write_char('}')
  builder.to_string()
}

///|
fn fixture_runtime_value_json(value : RuntimeValue?) -> String {
  match value {
    None => "null"
    Some(RuntimeValue::Null) => "null"
    Some(RuntimeValue::Text(text)) => fixture_json_quote(text)
    Some(RuntimeValue::Integer(number)) => "\{number}"
    Some(RuntimeValue::Flag(flag)) => if flag { "true" } else { "false" }
  }
}

///|
fn fixture_transition_input_kind(kind : TransitionInputKind) -> String {
  match kind {
    TransitionInputKind::EntityField => "entity-field"
    TransitionInputKind::Local => "local"
  }
}

///|
fn fixture_diagnostic_severity(severity : DiagnosticSeverity) -> String {
  match severity {
    DiagnosticSeverity::Error => "error"
    DiagnosticSeverity::Warning => "warning"
    DiagnosticSeverity::Info => "info"
  }
}

///|
fn fixture_optional_string_json(value : String?) -> String {
  match value {
    Some(text) => fixture_json_quote(text)
    None => "null"
  }
}

///|
fn fixture_json_quote(value : String) -> String {
  let builder = StringBuilder::new()
  fixture_write_json_string(builder, value)
  builder.to_string()
}

///|
fn fixture_write_json_string(builder : StringBuilder, value : String) -> Unit {
  builder.write_char('"')
  for char in value {
    match char {
      '\\' => builder.write_string("\\\\")
      '"' => builder.write_string("\\\"")
      '\n' => builder.write_string("\\n")
      '\r' => builder.write_string("\\r")
      '\t' => builder.write_string("\\t")
      _ => builder.write_char(char)
    }
  }
  builder.write_char('"')
}

///|
fn fixture_sort_strings(values : Array[String]) -> Unit {
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
