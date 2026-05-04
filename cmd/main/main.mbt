///|
/// CLI entry point for the phase-1 SQL compiler.
///
/// Usage:
///
/// ```text
/// moon run cmd/main -- examples/expense_request.yaml
/// ```
fn main {
  let args = @sys.get_cli_args()
  if args.length() != 2 {
    print_usage()
    @sys.exit(1)
  } else {
    let path = args[1]
    try {
      let input = @fs.read_file_to_string(path)
      let sql = @schema.compile_sql_from_yaml(input)
      println(sql)
    } catch {
      err => {
        println("error: \{err}")
        @sys.exit(1)
      }
    }
  }
}

///|
fn print_usage() -> Unit {
  println("usage: moon run cmd/main -- <schema.yaml>")
}
