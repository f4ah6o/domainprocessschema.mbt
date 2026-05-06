///|
/// Convert a validated schema into a normalized (canonical) JSON representation.
pub fn generate_normalized_schema(schema : Schema) -> String {
  render_normalized_schema(schema)
}

///|
/// Compile YAML directly to normalized schema JSON.
pub fn compile_normalized_schema_from_yaml(
  input : String,
) -> String raise SchemaError {
  let parsed = parse_schema_yaml(input)
  let schema = validate_schema(parsed)
  generate_normalized_schema(schema)
}

///|
fn render_normalized_schema(schema : Schema) -> String {
  let rendered_entities : Array[String] = []
  for entity in schema.entities {
    rendered_entities.push(render_normalized_entity(entity))
  }
  let entities_block = indent_block(rendered_entities.join(",\n"), 4)
  let payload = "{\n  \"entities\": [\n\{entities_block}\n  ]\n}"
  render_manifest_envelope("normalized-schema", payload)
}

///|
fn render_normalized_entity(entity : Entity) -> String {
  let rendered_fields : Array[String] = []
  for field in entity.fields {
    rendered_fields.push(render_normalized_field(field))
  }

  let rendered_states : Array[String] = []
  for state in entity.states {
    rendered_states.push(render_normalized_state(state))
  }

  let rendered_transitions : Array[String] = []
  for transition in entity.transitions {
    rendered_transitions.push(render_normalized_transition(transition))
  }

  let rendered_views : Array[String] = []
  for view in entity.views {
    rendered_views.push(render_normalized_view(view))
  }

  let rendered_constraints : Array[String] = []
  for constraint in entity.constraints {
    rendered_constraints.push(render_normalized_constraint(constraint))
  }

  let rendered_rules : Array[String] = []
  for rule in entity.rules {
    rendered_rules.push(render_normalized_rule(rule))
  }

  let rendered_relations : Array[String] = []
  for relation in entity.relations {
    rendered_relations.push(render_normalized_relation(relation))
  }

  let storage_json = render_normalized_storage(entity)

  let body_lines = [
    "\"name\": \{json_quote(entity.name)}",
    "\"label\": \{json_quote(entity.label)}",
    "\"labels\": \{render_labels_json(entity.labels)}",
    render_named_object_array("fields", rendered_fields),
    render_named_object_array("states", rendered_states),
    render_named_object_array("transitions", rendered_transitions),
    render_named_object_array("views", rendered_views),
    render_named_object_array("constraints", rendered_constraints),
    render_named_object_array("rules", rendered_rules),
    render_named_object_array("relations", rendered_relations),
    "\"storage\": \{storage_json}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_normalized_field(field : Field) -> String {
  let body_lines = [
    "\"name\": \{json_quote(field.name)}",
    "\"type\": \{json_quote(field_type_name(field.field_type))}",
    "\"label\": \{json_quote(field.label)}",
    "\"labels\": \{render_labels_json(field.labels)}",
    "\"required\": \{json_bool(field.required)}",
    "\"readOnly\": \{json_bool(field.read_only)}",
    "\"system\": \{json_bool(field.system)}",
    "\"primary\": \{json_bool(field.primary)}",
    "\"column\": \{json_quote(field.column_name)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_normalized_state(state : State) -> String {
  let body_lines = [
    "\"name\": \{json_quote(state.name)}",
    "\"label\": \{json_quote(state.label)}",
    "\"labels\": \{render_labels_json(state.labels)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_normalized_transition(transition : Transition) -> String {
  let rendered_inputs : Array[String] = []
  for input in transition.inputs {
    rendered_inputs.push(render_normalized_transition_input(input))
  }

  let guard_json = json_optional_expr(transition.guard_expr)
  let role_json = json_optional_string(transition.role)

  let body_lines = [
    "\"name\": \{json_quote(transition.name)}",
    "\"from\": \{json_quote(transition.from)}",
    "\"to\": \{json_quote(transition.to)}",
    render_named_object_array("inputs", rendered_inputs),
    "\"guard\": \{guard_json}",
    "\"role\": \{role_json}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_normalized_transition_input(input : TransitionInput) -> String {
  let body_lines = [
    "\"name\": \{json_quote(input.name)}",
    "\"kind\": \{json_quote(transition_input_kind_name(input.kind))}",
    "\"type\": \{json_quote(field_type_name(input.field_type))}",
    "\"required\": \{json_bool(input.required)}",
    "\"readOnly\": \{json_bool(input.read_only)}",
    "\"default\": \{json_optional_string(input.default_value)}",
    "\"target\": \{json_optional_string(input.target)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_normalized_view(view : View) -> String {
  let rendered_editable : Array[String] = []
  for field_name in view.editable_fields {
    rendered_editable.push(json_quote(field_name))
  }

  let rendered_readonly : Array[String] = []
  for field_name in view.readonly_fields {
    rendered_readonly.push(json_quote(field_name))
  }

  let body_lines = [
    "\"name\": \{json_quote(view.name)}",
    render_named_simple_array("editableFields", rendered_editable),
    render_named_simple_array("readonlyFields", rendered_readonly),
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_normalized_constraint(constraint : Constraint) -> String {
  let body_lines = [
    "\"name\": \{json_quote(constraint.name)}",
    "\"expr\": \{json_quote(expr_to_string(constraint.expr))}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_normalized_rule(rule : Rule) -> String {
  let body_lines = [
    "\"name\": \{json_quote(rule.name)}",
    "\"when\": \{json_quote(expr_to_string(rule.when_expr))}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_normalized_relation(relation : Relation) -> String {
  let body_lines = [
    "\"name\": \{json_quote(relation.name)}",
    "\"field\": \{json_quote(relation.field)}",
    "\"target\": \{json_quote(relation.target)}",
    "\"kind\": \{json_quote(relation_kind_name(relation.kind))}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_normalized_storage(entity : Entity) -> String {
  let rendered_indexes : Array[String] = []
  for index in entity.indexes {
    rendered_indexes.push(render_storage_key_json(index))
  }

  let rendered_uniques : Array[String] = []
  for unique_key in entity.unique_keys {
    rendered_uniques.push(render_storage_key_json(unique_key))
  }

  let body_lines = [
    "\"table\": \{json_quote(entity.table_name)}",
    "\"softDelete\": \{json_bool(entity.soft_delete)}",
    render_named_object_array("indexes", rendered_indexes),
    render_named_object_array("unique", rendered_uniques),
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_storage_key_json(key : StorageKey) -> String {
  let rendered_fields : Array[String] = []
  for field_name in key.fields {
    rendered_fields.push(json_quote(field_name))
  }
  let fields_block = indent_block(rendered_fields.join(",\n"), 4)
  let fields_json = "[\n\{fields_block}\n  ]"
  let body_lines = ["\"fields\": \{fields_json}"]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_labels_json(labels : Map[String, String]) -> String {
  let items : Array[String] = []
  for lang, text in labels {
    items.push("\{json_quote(lang)}: \{json_quote(text)}")
  }
  if items.length() == 0 {
    "{}"
  } else {
    let block = indent_block(items.join(",\n"), 4)
    "{\n\{block}\n  }"
  }
}

///|
fn render_named_simple_array(name : String, items : Array[String]) -> String {
  if items.length() == 0 {
    "\"\{name}\": []"
  } else {
    let block = indent_block(items.join(",\n"), 4)
    "\"\{name}\": [\n\{block}\n  ]"
  }
}

///|
fn relation_kind_name(kind : RelationKind) -> String {
  match kind {
    RelationKind::OneToOne => "1:1"
    RelationKind::OneToMany => "1:N"
    RelationKind::ManyToOne => "N:1"
    RelationKind::ManyToMany => "N:N"
  }
}
