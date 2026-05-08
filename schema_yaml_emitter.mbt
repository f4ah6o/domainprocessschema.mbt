///|
fn render_schema_yaml(schema : Schema) -> String {
  let lines : Array[String] = ["entities:"]
  for entity in schema.entities {
    render_entity_yaml(lines, entity)
  }
  lines.join("\n") + "\n"
}

///|
fn render_entity_yaml(lines : Array[String], entity : Entity) -> Unit {
  let entity_indent = "  "
  let child_indent = "    "
  lines.push("\{entity_indent}\{entity.name}:")
  render_localized_value(lines, child_indent, "label", entity.label, entity.labels)
  if entity.fields.length() > 0 {
    lines.push("\{child_indent}fields:")
    for field in entity.fields {
      render_field_yaml(lines, field)
    }
  }
  if entity.relations.length() > 0 {
    lines.push("\{child_indent}relations:")
    for relation in entity.relations {
      render_relation_yaml(lines, relation)
    }
  }
  if entity.constraints.length() > 0 {
    lines.push("\{child_indent}constraints:")
    for constraint in entity.constraints {
      lines.push("      \{constraint.name}:")
      lines.push("        expr: \{expr_to_string(constraint.expr)}")
    }
  }
  if entity.states.length() > 0 {
    lines.push("\{child_indent}states:")
    for state in entity.states {
      lines.push("      \{state.name}:")
      render_localized_value(lines, "        ", "label", state.label, state.labels)
    }
  }
  if entity.transitions.length() > 0 {
    lines.push("\{child_indent}transitions:")
    for transition in entity.transitions {
      render_transition_yaml(lines, transition)
    }
  }
  if entity.rules.length() > 0 {
    lines.push("\{child_indent}rules:")
    for rule in entity.rules {
      lines.push("      \{rule.name}:")
      lines.push("        when: \{expr_to_string(rule.when_expr)}")
    }
  }
  if entity.views.length() > 0 {
    lines.push("\{child_indent}views:")
    for view in entity.views {
      render_view_yaml(lines, view)
    }
  }
  render_storage_yaml(lines, entity)
}

///|
fn render_field_yaml(lines : Array[String], field : Field) -> Unit {
  lines.push("      \{field.name}:")
  render_localized_value(lines, "        ", "label", field.label, field.labels)
  lines.push("        type: \{field_type_name(field.field_type)}")
  if field.required {
    lines.push("        required: true")
  }
  if field.primary {
    lines.push("        primary: true")
  }
  if field.read_only {
    lines.push("        read_only: true")
  }
  if field.system {
    lines.push("        system: true")
  }
  match field.default_value {
    Some(value) => lines.push("        default: \{value}")
    None => ()
  }
  match field.target {
    Some(target) => lines.push("        target: \{target}")
    None => ()
  }
  match field.initial {
    Some(initial) => lines.push("        initial: \{initial}")
    None => ()
  }
}

///|
fn render_relation_yaml(lines : Array[String], relation : Relation) -> Unit {
  lines.push("      \{relation.name}:")
  lines.push("        kind: \{yaml_relation_kind_name(relation.kind)}")
  lines.push("        target: \{relation.target}")
  lines.push("        field: \{relation.field}")
}

///|
fn render_transition_yaml(lines : Array[String], transition : Transition) -> Unit {
  lines.push("      \{transition.name}:")
  lines.push("        from: \{transition.from}")
  lines.push("        to: \{transition.to}")
  match transition.role {
    Some(role) => lines.push("        role: \{role}")
    None => ()
  }
  if transition.inputs.length() > 0 {
    lines.push("        input:")
    for input in transition.inputs {
      lines.push("          - \{input.name}")
    }
    let local_inputs = transition.inputs.filter(input => input.kind == TransitionInputKind::Local)
    if local_inputs.length() > 0 {
      lines.push("        inputs:")
      for input in local_inputs {
        lines.push("          \{input.name}:")
        lines.push("            type: \{field_type_name(input.field_type)}")
        if input.required {
          lines.push("            required: true")
        }
        if input.read_only {
          lines.push("            read_only: true")
        }
        match input.default_value {
          Some(value) => lines.push("            default: \{value}")
          None => ()
        }
        match input.target {
          Some(target) => lines.push("            target: \{target}")
          None => ()
        }
      }
    }
  }
  match transition.guard_expr {
    Some(expr) => lines.push("        guard: \{expr_to_string(expr)}")
    None => ()
  }
}

///|
fn render_view_yaml(lines : Array[String], view : View) -> Unit {
  lines.push("      \{view.name}:")
  if view.editable_fields.length() > 0 {
    lines.push("        editable:")
    for field_name in view.editable_fields {
      lines.push("          - \{field_name}")
    }
  }
  if view.readonly_fields.length() > 0 {
    lines.push("        readonly:")
    for field_name in view.readonly_fields {
      lines.push("          - \{field_name}")
    }
  }
}

///|
fn render_storage_yaml(lines : Array[String], entity : Entity) -> Unit {
  let has_storage =
    entity.table_name != pluralize_snake(entity.name) ||
    entity.indexes.length() > 0 ||
    entity.unique_keys.length() > 0 ||
    entity.soft_delete
  if !has_storage {
    return
  }
  lines.push("    storage:")
  if entity.table_name != pluralize_snake(entity.name) {
    lines.push("      table: \{entity.table_name}")
  }
  if entity.indexes.length() > 0 {
    lines.push("      indexes:")
    for index in entity.indexes {
      render_storage_key_yaml(lines, index)
    }
  }
  if entity.unique_keys.length() > 0 {
    lines.push("      unique:")
    for unique_key in entity.unique_keys {
      render_storage_key_yaml(lines, unique_key)
    }
  }
  if entity.soft_delete {
    lines.push("      softDelete: true")
  }
}

///|
fn render_storage_key_yaml(lines : Array[String], key : StorageKey) -> Unit {
  lines.push("        - fields: \{render_inline_string_array_yaml(key.fields)}")
}

///|
fn render_localized_value(
  lines : Array[String],
  indent : String,
  name : String,
  fallback : String,
  labels : Map[String, String],
) -> Unit {
  if labels.length() == 0 {
    lines.push("\{indent}\{name}: \{fallback}")
    return
  }

  let label_keys = sorted_label_keys(labels)
  if label_keys.length() == 1 && label_keys[0] == "default" {
    let default_label = labels.get("default").unwrap_or(fallback)
    lines.push("\{indent}\{name}: \{default_label}")
    return
  }

  lines.push("\{indent}\{name}:")
  for key in label_keys {
    match labels.get(key) {
      Some(value) => lines.push("\{indent}  \{key}: \{value}")
      None => ()
    }
  }
}

///|
fn sorted_label_keys(labels : Map[String, String]) -> Array[String] {
  let keys : Array[String] = []
  for key, _ in labels {
    keys.push(key)
  }
  sort_strings(keys)
  if keys.contains("default") && keys[0] != "default" {
    let reordered : Array[String] = ["default"]
    for key in keys {
      if key != "default" {
        reordered.push(key)
      }
    }
    return reordered
  }
  keys
}

///|
fn yaml_relation_kind_name(kind : RelationKind) -> String {
  match kind {
    RelationKind::OneToOne => "one_to_one"
    RelationKind::OneToMany => "one_to_many"
    RelationKind::ManyToOne => "many_to_one"
    RelationKind::ManyToMany => "many_to_many"
  }
}

///|
fn render_inline_string_array_yaml(values : Array[String]) -> String {
  "[" + values.join(", ") + "]"
}

///|
fn sort_strings(values : Array[String]) -> Unit {
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
