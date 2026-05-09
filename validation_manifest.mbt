///|
fn render_validation_manifest(schema : Schema) -> String {
  let rendered_entities : Array[String] = []
  for entity in schema.entities {
    rendered_entities.push(render_validation_entity(schema, entity))
  }
  let entities_block = indent_block(rendered_entities.join(",\n"), 4)
  let payload = "{\n  \"entities\": [\n\{entities_block}\n  ]\n}"
  render_manifest_envelope("validation-manifest", payload)
}

///|
fn render_validation_entity(schema : Schema, entity : Entity) -> String {
  let rendered_fields : Array[String] = []
  let rendered_constraints : Array[String] = []
  let rendered_transitions : Array[String] = []
  let rendered_rules : Array[String] = []

  for field in entity.fields {
    rendered_fields.push(render_validation_field(schema, field))
  }
  for constraint in entity.constraints {
    rendered_constraints.push(render_validation_constraint(constraint))
  }
  for transition in entity.transitions {
    rendered_transitions.push(render_validation_transition(schema, transition))
  }
  for rule in entity.rules {
    rendered_rules.push(render_validation_rule(rule))
  }

  let body_lines = [
    "\"name\": \{json_quote(entity.name)}",
    render_named_object_array("fields", rendered_fields),
    render_named_object_array("constraints", rendered_constraints),
    render_named_object_array("transitions", rendered_transitions),
    render_named_object_array("rules", rendered_rules),
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_validation_field(schema : Schema, field : Field) -> String {
  let body_lines = [
    "\"name\": \{json_quote(field.name)}",
    "\"type\": \{json_quote(field_type_name(field.field_type))}",
    "\"required\": \{json_bool(field.required)}",
    "\"primary\": \{json_bool(field.primary)}",
    "\"readOnly\": \{json_bool(field.read_only)}",
    "\"system\": \{json_bool(field.system)}",
    "\"default\": \{json_optional_string(field.default_value)}",
    "\"target\": \{json_optional_string(field.target)}",
    "\"labelField\": \{json_optional_string(reference_label_field_name(schema, field.target))}",
    "\"valueField\": \{json_optional_string(reference_value_field_name(schema, field.target))}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_validation_constraint(constraint : Constraint) -> String {
  let body_lines = [
    "\"name\": \{json_quote(constraint.name)}",
    "\"expr\": \{json_quote(expr_to_string(constraint.expr))}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_validation_transition(schema : Schema, transition : Transition) -> String {
  let body_lines = [
    "\"name\": \{json_quote(transition.name)}",
    "\"from\": \{json_quote(transition.from)}",
    "\"to\": \{json_quote(transition.to)}",
    "\"inputs\": \{render_transition_inputs_json(transition.inputs, schema=Some(schema))}",
    "\"guard\": \{json_optional_expr(transition.guard_expr)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_validation_rule(rule : Rule) -> String {
  let body_lines = [
    "\"name\": \{json_quote(rule.name)}",
    "\"when\": \{json_quote(expr_to_string(rule.when_expr))}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}
