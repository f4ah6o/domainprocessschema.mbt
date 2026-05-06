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
