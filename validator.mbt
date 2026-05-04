///|
fn validate_parsed_schema(parsed : ParsedSchema) -> Schema raise SchemaError {
  if parsed.entities.length() == 0 {
    raise SchemaError::ValidationError(
      path="schema.entities",
      "at least one entity is required",
    )
  }
  let entity_names : Map[String, Bool] = {}
  for entity in parsed.entities {
    if entity_names.contains(entity.name) {
      raise SchemaError::ValidationError(
        path="schema.entities.\{entity.name}",
        "duplicate entity name \{entity.name}",
      )
    }
    entity_names[entity.name] = true
  }
  let entities : Array[Entity] = []
  for entity in parsed.entities {
    entities.push(validate_entity(entity, entity_names))
  }
  Schema::{ entities, }
}

///|
fn validate_entity(
  entity : ParsedEntity,
  entity_names : Map[String, Bool],
) -> Entity raise SchemaError {
  let path = "schema.entities.\{entity.name}"
  if entity.fields.length() == 0 {
    raise SchemaError::ValidationError(
      path="\{path}.fields",
      "an entity must define at least one field",
    )
  }
  let fields : Array[Field] = []
  let field_names : Map[String, Field] = {}
  let mut primary_count = 0
  let mut state_field_count = 0
  for parsed_field in entity.fields {
    let field = validate_field(parsed_field, entity.name, entity_names)
    if field_names.contains(parsed_field.name) {
      raise SchemaError::ValidationError(
        path="\{path}.fields.\{parsed_field.name}",
        "duplicate field name \{parsed_field.name}",
      )
    }
    if field.primary {
      primary_count = primary_count + 1
    }
    if field.field_type == FieldType::State {
      state_field_count = state_field_count + 1
    }
    field_names[field.name] = field
    fields.push(field)
  }
  if primary_count != 1 {
    raise SchemaError::ValidationError(
      path="\{path}.fields",
      "phase 1 requires exactly one primary field per entity",
    )
  }
  let state_names : Map[String, Bool] = {}
  let states : Array[State] = []
  for parsed_state in entity.states {
    if state_names.contains(parsed_state.name) {
      raise SchemaError::ValidationError(
        path="\{path}.states.\{parsed_state.name}",
        "duplicate state name \{parsed_state.name}",
      )
    }
    state_names[parsed_state.name] = true
    states.push(State::{ name: parsed_state.name, label: parsed_state.label })
  }
  if states.length() > 0 && state_field_count != 1 {
    raise SchemaError::ValidationError(
      path="\{path}.fields",
      "entities with states must define exactly one `state` field",
    )
  }
  if states.length() == 0 && state_field_count > 0 {
    raise SchemaError::ValidationError(
      path="\{path}.states",
      "a `state` field requires a non-empty `states` section",
    )
  }
  validate_state_field_initial(fields, state_names, path)
  let relations = validate_relations(
    entity.relations,
    field_names,
    entity_names,
    path,
  )
  let constraints = validate_constraints(entity.constraints, path)
  let transitions = validate_transitions(
    entity.transitions,
    state_names,
    field_names,
    path,
  )
  let rules = validate_rules(entity.rules, path)
  let views = validate_views(entity.views, field_names, path)
  let indexes = validate_storage_keys(
    entity.storage.indexes,
    field_names,
    "\{path}.storage.indexes",
  )
  let unique_keys = validate_storage_keys(
    entity.storage.unique_keys,
    field_names,
    "\{path}.storage.unique",
  )
  let table_name = validate_table_name(entity.storage.table, entity.name, path)
  Entity::{
    name: entity.name,
    label: entity.label,
    table_name,
    fields,
    relations,
    constraints,
    states,
    transitions,
    rules,
    views,
    indexes,
    unique_keys,
    soft_delete: entity.storage.soft_delete,
  }
}

///|
fn validate_field(
  parsed_field : ParsedField,
  entity_name : String,
  entity_names : Map[String, Bool],
) -> Field raise SchemaError {
  let path = "schema.entities.\{entity_name}.fields.\{parsed_field.name}"
  let field_type = parse_field_type(parsed_field.type_name, "\{path}.type")
  match (field_type, parsed_field.target) {
    (FieldType::Ref, None) =>
      raise SchemaError::ValidationError(
        path~,
        "`ref` fields require a `target` entity",
      )
    (FieldType::Ref, Some(target)) =>
      if !entity_names.contains(target) {
        raise SchemaError::ValidationError(
          path~,
          "unknown ref target \{target}",
        )
      }
    (_, Some(_)) =>
      raise SchemaError::ValidationError(
        path~,
        "`target` is only valid for `ref` fields",
      )
    _ => ()
  }
  match (field_type, parsed_field.initial) {
    (FieldType::State, None) =>
      raise SchemaError::ValidationError(
        path~,
        "`state` fields require an `initial` state",
      )
    (FieldType::State, Some(_)) => ()
    (_, Some(_)) =>
      raise SchemaError::ValidationError(
        path~,
        "`initial` is only valid for `state` fields",
      )
    _ => ()
  }
  Field::{
    name: parsed_field.name,
    column_name: sql_column_name(parsed_field.name, field_type),
    field_type,
    required: parsed_field.required,
    primary: parsed_field.primary,
    read_only: parsed_field.read_only,
    system: parsed_field.system,
    default_value: parsed_field.default_value,
    target: parsed_field.target,
    initial: parsed_field.initial,
  }
}

///|
fn validate_state_field_initial(
  fields : Array[Field],
  state_names : Map[String, Bool],
  path : String,
) -> Unit raise SchemaError {
  for field in fields {
    if field.field_type == FieldType::State {
      let initial = field.initial.unwrap_or("")
      if !state_names.contains(initial) {
        raise SchemaError::ValidationError(
          path="\{path}.fields.\{field.name}",
          "initial state \{initial} does not exist in `states`",
        )
      }
    }
  }
}

///|
fn validate_relations(
  parsed_relations : Array[ParsedRelation],
  field_names : Map[String, Field],
  entity_names : Map[String, Bool],
  path : String,
) -> Array[Relation] raise SchemaError {
  let relations : Array[Relation] = []
  for relation in parsed_relations {
    let relation_path = "\{path}.relations.\{relation.name}"
    if !entity_names.contains(relation.target) {
      raise SchemaError::ValidationError(
        path=relation_path,
        "unknown relation target \{relation.target}",
      )
    }
    let field = match field_names.get(relation.field) {
      Some(field) => field
      None =>
        raise SchemaError::ValidationError(
          path=relation_path,
          "relation field \{relation.field} does not exist",
        )
    }
    if field.field_type != FieldType::Ref {
      raise SchemaError::ValidationError(
        path=relation_path,
        "relation field \{relation.field} must use `type: ref`",
      )
    }
    if field.target != Some(relation.target) {
      raise SchemaError::ValidationError(
        path=relation_path,
        "relation target must match the ref field target",
      )
    }
    relations.push(Relation::{
      name: relation.name,
      kind: parse_relation_kind(relation.kind_name, "\{relation_path}.kind"),
      target: relation.target,
      field: relation.field,
    })
  }
  relations
}

///|
fn validate_constraints(
  parsed_constraints : Array[ParsedConstraint],
  path : String,
) -> Array[Constraint] raise SchemaError {
  let constraints : Array[Constraint] = []
  for constraint in parsed_constraints {
    if constraint.expr.trim().is_empty() {
      raise SchemaError::ValidationError(
        path="\{path}.constraints.\{constraint.name}",
        "constraint expressions must not be empty",
      )
    }
    constraints.push(Constraint::{
      name: constraint.name,
      expr: constraint.expr,
    })
  }
  constraints
}

///|
fn validate_transitions(
  parsed_transitions : Array[ParsedTransition],
  state_names : Map[String, Bool],
  field_names : Map[String, Field],
  path : String,
) -> Array[Transition] raise SchemaError {
  let transitions : Array[Transition] = []
  for transition in parsed_transitions {
    let transition_path = "\{path}.transitions.\{transition.name}"
    if !state_names.contains(transition.from) {
      raise SchemaError::ValidationError(
        path=transition_path,
        "unknown source state \{transition.from}",
      )
    }
    if !state_names.contains(transition.to) {
      raise SchemaError::ValidationError(
        path=transition_path,
        "unknown target state \{transition.to}",
      )
    }
    for field_name in transition.input_fields {
      if !field_names.contains(field_name) {
        raise SchemaError::ValidationError(
          path=transition_path,
          "transition input field \{field_name} does not exist",
        )
      }
    }
    transitions.push(Transition::{
      name: transition.name,
      from: transition.from,
      to: transition.to,
      role: transition.role,
      input_fields: transition.input_fields,
      guard_expr: transition.guard_expr,
    })
  }
  transitions
}

///|
fn validate_rules(
  parsed_rules : Array[ParsedRule],
  path : String,
) -> Array[Rule] raise SchemaError {
  let rules : Array[Rule] = []
  for rule in parsed_rules {
    if rule.when_expr.trim().is_empty() {
      raise SchemaError::ValidationError(
        path="\{path}.rules.\{rule.name}",
        "rule expressions must not be empty",
      )
    }
    rules.push(Rule::{ name: rule.name, when_expr: rule.when_expr })
  }
  rules
}

///|
fn validate_views(
  parsed_views : Array[ParsedView],
  field_names : Map[String, Field],
  path : String,
) -> Array[View] raise SchemaError {
  let views : Array[View] = []
  for view in parsed_views {
    let view_path = "\{path}.views.\{view.name}"
    for field_name in view.editable_fields {
      if !field_names.contains(field_name) {
        raise SchemaError::ValidationError(
          path=view_path,
          "editable field \{field_name} does not exist",
        )
      }
    }
    for field_name in view.readonly_fields {
      if !field_names.contains(field_name) {
        raise SchemaError::ValidationError(
          path=view_path,
          "readonly field \{field_name} does not exist",
        )
      }
    }
    views.push(View::{
      name: view.name,
      editable_fields: view.editable_fields,
      readonly_fields: view.readonly_fields,
    })
  }
  views
}

///|
fn validate_storage_keys(
  parsed_keys : Array[ParsedStorageKey],
  field_names : Map[String, Field],
  path : String,
) -> Array[StorageKey] raise SchemaError {
  let keys : Array[StorageKey] = []
  for parsed_key in parsed_keys {
    if parsed_key.fields.length() == 0 {
      raise SchemaError::ValidationError(
        path~,
        "storage field groups must not be empty",
      )
    }
    for field_name in parsed_key.fields {
      if !field_names.contains(field_name) {
        raise SchemaError::ValidationError(
          path~,
          "storage field \{field_name} does not exist",
        )
      }
    }
    keys.push(StorageKey::{ fields: parsed_key.fields })
  }
  keys
}

///|
fn validate_table_name(
  configured : String?,
  entity_name : String,
  path : String,
) -> String raise SchemaError {
  match configured {
    Some(table_name) => {
      if table_name.trim().is_empty() {
        raise SchemaError::ValidationError(
          path="\{path}.storage.table",
          "storage.table must not be empty",
        )
      }
      table_name
    }
    None => pluralize_snake(entity_name)
  }
}

///|
fn parse_field_type(
  type_name : String,
  path : String,
) -> FieldType raise SchemaError {
  match normalize_token(type_name) {
    "id" => FieldType::Id
    "text" => FieldType::Text
    "number" => FieldType::Number
    "money" => FieldType::Money
    "boolean" => FieldType::Boolean
    "date" => FieldType::Date
    "datetime" => FieldType::DateTime
    "date_time" => FieldType::DateTime
    "enum" => FieldType::Enum
    "ref" => FieldType::Ref
    "state" => FieldType::State
    "file" => FieldType::File
    _ =>
      raise SchemaError::ValidationError(
        path~,
        "unsupported field type \{type_name}",
      )
  }
}

///|
fn parse_relation_kind(
  kind_name : String,
  path : String,
) -> RelationKind raise SchemaError {
  match normalize_token(kind_name) {
    "one_to_one" => RelationKind::OneToOne
    "one_to_many" => RelationKind::OneToMany
    "many_to_one" => RelationKind::ManyToOne
    "many_to_many" => RelationKind::ManyToMany
    _ =>
      raise SchemaError::ValidationError(
        path~,
        "unsupported relation kind \{kind_name}",
      )
  }
}

///|
fn normalize_token(text : String) -> String {
  text[:].trim().to_lower().replace_all(old="-", new="_").to_string()
}
