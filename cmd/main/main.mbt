///|
/// CLI entry point for the schema compiler.
///
/// Usage:
///
/// ```text
/// moon run cmd/main -- examples/expense_request.yaml
/// moon run cmd/main -- normalized-schema examples/expense_request.yaml
/// moon run cmd/main -- api-manifest examples/expense_request.yaml
/// moon run cmd/main -- validation-manifest examples/expense_request.yaml
/// moon run cmd/main -- gui-manifest examples/expense_request.yaml
/// moon run cmd/main -- gui-html examples/expense_request.yaml
/// moon run cmd/main -- migration-sql examples/expense_request.yaml
/// ```
fn main {
  let args = @sys.get_cli_args()
  if args.length() != 2 && args.length() != 3 {
    print_usage()
    @sys.exit(1)
  } else {
    let (mode, path) = if args.length() == 2 {
      ("sql", args[1])
    } else {
      (args[1], args[2])
    }
    try {
      let input = @fs.read_file_to_string(path)
      let output = compile_output(mode, input)
      println(output)
    } catch {
      @schema.SchemaError::ParseError(issues~) => {
        println(@schema.render_error_report_json(issues))
        @sys.exit(1)
      }
      @schema.SchemaError::ValidationError(issues~) => {
        println(@schema.render_error_report_json(issues))
        @sys.exit(1)
      }
      err => {
        let issue = @schema.Diagnostic::{
          code: "INTERNAL_ERROR",
          severity: @schema.DiagnosticSeverity::Error,
          target: "cli",
          message: "\{err}",
          hint: None,
          context: {},
        }
        println(@schema.render_error_report_json([issue]))
        @sys.exit(1)
      }
    }
  }
}

///|
fn compile_output(mode : String, input : String) -> String raise {
  match mode {
    "sql" => @schema.compile_sql_from_yaml(input)
    "migration-sql" => @schema.compile_migration_sql_from_yaml(input)
    "normalized-schema" => @schema.compile_normalized_schema_from_yaml(input)
    "api-manifest" => @schema.compile_api_manifest_from_yaml(input)
    "validation-manifest" =>
      @schema.compile_validation_manifest_from_yaml(input)
    "gui-manifest" => @schema.compile_gui_manifest_from_yaml(input)
    "gui-html" => @schema.compile_gui_html_from_yaml(input)
    _ =>
      raise @schema.SchemaError::ValidationError(issues=[
        @schema.Diagnostic::{
          code: "UNSUPPORTED_MODE",
          severity: @schema.DiagnosticSeverity::Error,
          target: "cli.mode",
          message: "unsupported mode \{mode}; use `sql`, `migration-sql`, `normalized-schema`, `api-manifest`, `validation-manifest`, `gui-manifest`, or `gui-html`",
          hint: Some(
            "Pick one of the documented CLI modes from the usage string.",
          ),
          context: { "mode": mode },
        },
      ])
  }
}

///|
fn print_usage() -> Unit {
  println(
    "usage: moon run cmd/main -- [sql|migration-sql|normalized-schema|api-manifest|validation-manifest|gui-manifest|gui-html] <schema.yaml>",
  )
}
