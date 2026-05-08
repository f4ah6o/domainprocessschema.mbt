///|
fn load_editor_fixture() -> String raise {
  @fs.read_file_to_string("examples/expense_request.yaml")
}

///|
test "editor emitted yaml recompiles to same normalized schema" {
  let input = load_editor_fixture()
  let emitted = compile_emitted_yaml_from_yaml(input)
  let original = compile_normalized_schema_from_yaml(input)
  let roundtrip = compile_normalized_schema_from_yaml(emitted)
  assert_eq(roundtrip.trim_end().to_string(), original.trim_end().to_string())
}

///|
test "normalized schema exposes editor metadata fields" {
  let input = load_editor_fixture()
  let normalized = compile_normalized_schema_from_yaml(input)
  inspect(normalized.contains("\"target\": \"User\""), content="true")
  inspect(normalized.contains("\"initial\": \"draft\""), content="true")
  inspect(normalized.contains("\"default\": null"), content="true")
}
