///|
/// v1 reference lookup metadata is derived from the validated target entity.
/// Explicit schema-level overrides can be added later as optional metadata
/// without changing the current manifest fields.
fn reference_value_field_name(schema : Schema, target : String?) -> String? {
  match target {
    Some(target_name) => Some(find_primary_field(find_entity(schema, target_name)).name)
    None => None
  }
}

///|
fn reference_label_field_name(schema : Schema, target : String?) -> String? {
  reference_value_field_name(schema, target)
}

///|
fn reference_value_field_name_from_optional_schema(
  schema : Schema?,
  target : String?,
) -> String? {
  match schema {
    Some(schema) => reference_value_field_name(schema, target)
    None => None
  }
}

///|
fn reference_label_field_name_from_optional_schema(
  schema : Schema?,
  target : String?,
) -> String? {
  match schema {
    Some(schema) => reference_label_field_name(schema, target)
    None => None
  }
}
