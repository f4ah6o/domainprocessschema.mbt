///|
fn schema_contract_version() -> String {
  "domainprocessschema.v1"
}

///|
fn manifest_generator_name() -> String {
  "domainprocessschema.mbt"
}

///|
fn manifest_generator_version() -> String {
  "0.1.0"
}

///|
fn render_manifest_envelope(
  manifest_kind : String,
  payload_json : String,
) -> String {
  let body_lines = [
    "\"schemaVersion\": \{json_quote(schema_contract_version())}",
    "\"manifestKind\": \{json_quote(manifest_kind)}",
    "\"generator\": {\n    \"name\": \{json_quote(manifest_generator_name())},\n    \"version\": \{json_quote(manifest_generator_version())}\n  }",
    "\"payload\": \{payload_json}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn diagnostic_severity_text(severity : DiagnosticSeverity) -> String {
  match severity {
    DiagnosticSeverity::Error => "error"
    DiagnosticSeverity::Warning => "warning"
    DiagnosticSeverity::Info => "info"
  }
}

///|
fn diagnostic(
  code : String,
  target : String,
  message : String,
  severity? : DiagnosticSeverity = DiagnosticSeverity::Error,
  hint? : String = "",
  context? : Map[String, String] = {},
) -> Diagnostic {
  Diagnostic::{
    code,
    severity,
    target,
    message,
    hint: if hint == "" {
      None
    } else {
      Some(hint)
    },
    context,
  }
}

///|
fn schema_validation_error(
  path~ : String,
  message : String,
  code? : String = "SCHEMA_VALIDATION_ERROR",
  hint? : String = "",
  context? : Map[String, String] = {},
) -> SchemaError {
  SchemaError::ValidationError(issues=[
    diagnostic(code, path, message, hint~, context~),
  ])
}

///|
fn schema_parse_error(
  line~ : Int,
  message : String,
  code? : String = "INVALID_YAML_SYNTAX",
  hint? : String = "",
  context? : Map[String, String] = {},
) -> SchemaError {
  let full_context : Map[String, String] = {}
  for key, value in context {
    full_context[key] = value
  }
  full_context["line"] = "\{line}"
  SchemaError::ParseError(issues=[
    diagnostic(code, "yaml.line.\{line}", message, hint~, context=full_context),
  ])
}

///|
fn render_diagnostic_json(issue : Diagnostic) -> String {
  let body_lines = [
    "\"code\": \{json_quote(issue.code)}",
    "\"severity\": \{json_quote(diagnostic_severity_text(issue.severity))}",
    "\"target\": \{json_quote(issue.target)}",
    "\"message\": \{json_quote(issue.message)}",
    "\"hint\": \{json_optional_string(issue.hint)}",
    "\"context\": \{render_string_map_json(issue.context)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_diagnostics_json(issues : Array[Diagnostic]) -> String {
  let rendered = issues.map(render_diagnostic_json)
  if rendered.length() == 0 {
    "[]"
  } else {
    let block = indent_block(rendered.join(",\n"), 4)
    "[\n\{block}\n  ]"
  }
}

///|
pub fn render_error_report_json(issues : Array[Diagnostic]) -> String {
  let body_lines = [
    "\"ok\": false",
    "\"issues\": \{render_diagnostics_json(issues)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_string_map_json(values : Map[String, String]) -> String {
  let items : Array[String] = []
  for key, value in values {
    items.push("\{json_quote(key)}: \{json_quote(value)}")
  }
  if items.length() == 0 {
    "{}"
  } else {
    let block = indent_block(items.join(",\n"), 4)
    "{\n\{block}\n  }"
  }
}
