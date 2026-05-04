///|
/// CLI entry point for the schema compiler.
///
/// Usage:
///
/// ```text
/// moon run cmd/main -- examples/expense_request.yaml
/// moon run cmd/main -- api-manifest examples/expense_request.yaml
/// moon run cmd/main -- validation-manifest examples/expense_request.yaml
/// moon run cmd/main -- gui-manifest examples/expense_request.yaml
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
      err => {
        println("error: \{err}")
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
    "api-manifest" => @schema.compile_api_manifest_from_yaml(input)
    "validation-manifest" =>
      @schema.compile_validation_manifest_from_yaml(input)
    "gui-manifest" => @schema.compile_gui_manifest_from_yaml(input)
    _ =>
      raise @schema.SchemaError::ValidationError(
        path="cli.mode",
        "unsupported mode \{mode}; use `sql`, `migration-sql`, `api-manifest`, `validation-manifest`, or `gui-manifest`",
      )
  }
}

///|
fn print_usage() -> Unit {
  println(
    "usage: moon run cmd/main -- [sql|migration-sql|api-manifest|validation-manifest|gui-manifest] <schema.yaml>",
  )
}
