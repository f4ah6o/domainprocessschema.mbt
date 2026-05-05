///|
fn parse_schema_root(root : YamlValue) -> ParsedSchema raise SchemaError {
  let root_map = expect_yaml_map(root, "schema")
  ensure_allowed_keys(root_map, ["entities"], "schema")
  let entities_value = require_key(root_map, "entities", "schema.entities")
  let entities_map = expect_yaml_map(entities_value, "schema.entities")
  let entities : Array[ParsedEntity] = []
  for entity_name, entity_value in entities_map {
    let entity_path = "schema.entities.\{entity_name}"
    let entity_map = expect_yaml_map(entity_value, entity_path)
    ensure_allowed_keys(
      entity_map,
      [
        "label", "fields", "relations", "constraints", "states", "transitions", "rules",
        "views", "storage",
      ],
      entity_path,
    )
    let (entity_label, entity_labels) = optional_localized_label_value(
      entity_map,
      "label",
      entity_path,
      entity_name,
    )
    let fields = parse_fields(entity_map, entity_path)
    let relations = parse_relations(entity_map, entity_path)
    let constraints = parse_constraints(entity_map, entity_path)
    let states = parse_states(entity_map, entity_path)
    let transitions = parse_transitions(entity_map, entity_path)
    let rules = parse_rules(entity_map, entity_path)
    let views = parse_views(entity_map, entity_path)
    let storage = parse_storage(entity_map, entity_path)
    entities.push(ParsedEntity::{
      name: entity_name,
      label: entity_label,
      labels: entity_labels,
      fields,
      relations,
      constraints,
      states,
      transitions,
      rules,
      views,
      storage,
    })
  }
  ParsedSchema::{ entities, }
}

///|
fn parse_fields(
  entity_map : Map[String, YamlValue],
  entity_path : String,
) -> Array[ParsedField] raise SchemaError {
  let fields_value = require_key(entity_map, "fields", "\{entity_path}.fields")
  let fields_map = expect_yaml_map(fields_value, "\{entity_path}.fields")
  let fields : Array[ParsedField] = []
  for field_name, field_value in fields_map {
    let path = "\{entity_path}.fields.\{field_name}"
    let field_map = expect_yaml_map(field_value, path)
    ensure_allowed_keys(
      field_map,
      [
        "label", "type", "required", "primary", "readonly", "system", "default",
        "target", "initial",
      ],
      path,
    )
    let type_name = required_string_value(field_map, "type", "\{path}.type")
    let (label, labels) = optional_localized_label_value(
      field_map,
      "label",
      path,
      field_name,
    )
    fields.push(ParsedField::{
      name: field_name,
      label,
      labels,
      type_name,
      required: optional_bool_value(field_map, "required", path, false),
      primary: optional_bool_value(field_map, "primary", path, false),
      read_only: optional_bool_value(field_map, "readonly", path, false),
      system: optional_bool_value(field_map, "system", path, false),
      default_value: optional_string_value(field_map, "default", path),
      target: optional_string_value(field_map, "target", path),
      initial: optional_string_value(field_map, "initial", path),
    })
  }
  fields
}

///|
fn parse_relations(
  entity_map : Map[String, YamlValue],
  entity_path : String,
) -> Array[ParsedRelation] raise SchemaError {
  let relations : Array[ParsedRelation] = []
  match entity_map.get("relations") {
    None => relations
    Some(relations_value) => {
      let relations_map = expect_yaml_map(
        relations_value,
        "\{entity_path}.relations",
      )
      for relation_name, relation_value in relations_map {
        let path = "\{entity_path}.relations.\{relation_name}"
        let relation_map = expect_yaml_map(relation_value, path)
        ensure_allowed_keys(relation_map, ["kind", "target", "field"], path)
        relations.push(ParsedRelation::{
          name: relation_name,
          kind_name: required_string_value(relation_map, "kind", "\{path}.kind"),
          target: required_string_value(
            relation_map,
            "target",
            "\{path}.target",
          ),
          field: required_string_value(relation_map, "field", "\{path}.field"),
        })
      }
      relations
    }
  }
}

///|
fn parse_constraints(
  entity_map : Map[String, YamlValue],
  entity_path : String,
) -> Array[ParsedConstraint] raise SchemaError {
  let constraints : Array[ParsedConstraint] = []
  match entity_map.get("constraints") {
    None => constraints
    Some(constraints_value) => {
      let constraints_map = expect_yaml_map(
        constraints_value,
        "\{entity_path}.constraints",
      )
      for constraint_name, constraint_value in constraints_map {
        let path = "\{entity_path}.constraints.\{constraint_name}"
        let constraint_map = expect_yaml_map(constraint_value, path)
        ensure_allowed_keys(constraint_map, ["expr"], path)
        constraints.push(ParsedConstraint::{
          name: constraint_name,
          expr: required_string_value(constraint_map, "expr", "\{path}.expr"),
        })
      }
      constraints
    }
  }
}

///|
fn parse_states(
  entity_map : Map[String, YamlValue],
  entity_path : String,
) -> Array[ParsedState] raise SchemaError {
  let states : Array[ParsedState] = []
  match entity_map.get("states") {
    None => states
    Some(states_value) => {
      let states_map = expect_yaml_map(states_value, "\{entity_path}.states")
      for state_name, state_value in states_map {
        let path = "\{entity_path}.states.\{state_name}"
        let state_map = expect_yaml_map(state_value, path)
        ensure_allowed_keys(state_map, ["label"], path)
        let (label, labels) = optional_localized_label_value(
          state_map,
          "label",
          path,
          state_name,
        )
        states.push(ParsedState::{ name: state_name, label, labels })
      }
      states
    }
  }
}

///|
fn parse_transitions(
  entity_map : Map[String, YamlValue],
  entity_path : String,
) -> Array[ParsedTransition] raise SchemaError {
  let transitions : Array[ParsedTransition] = []
  match entity_map.get("transitions") {
    None => transitions
    Some(transitions_value) => {
      let transitions_map = expect_yaml_map(
        transitions_value,
        "\{entity_path}.transitions",
      )
      for transition_name, transition_value in transitions_map {
        let path = "\{entity_path}.transitions.\{transition_name}"
        let transition_map = expect_yaml_map(transition_value, path)
        ensure_allowed_keys(
          transition_map,
          ["from", "to", "input", "inputs", "guard", "role"],
          path,
        )
        transitions.push(ParsedTransition::{
          name: transition_name,
          from: required_string_value(transition_map, "from", "\{path}.from"),
          to: required_string_value(transition_map, "to", "\{path}.to"),
          role: optional_string_value(transition_map, "role", path),
          input_names: optional_string_list_value(transition_map, "input", path),
          inputs: parse_transition_local_inputs(transition_map, path),
          guard_expr: optional_string_value(transition_map, "guard", path),
        })
      }
      transitions
    }
  }
}

///|
fn parse_transition_local_inputs(
  transition_map : Map[String, YamlValue],
  transition_path : String,
) -> Array[ParsedTransitionInput] raise SchemaError {
  let inputs : Array[ParsedTransitionInput] = []
  match transition_map.get("inputs") {
    None => inputs
    Some(inputs_value) => {
      let inputs_map = expect_yaml_map(
        inputs_value,
        "\{transition_path}.inputs",
      )
      for input_name, input_value in inputs_map {
        let path = "\{transition_path}.inputs.\{input_name}"
        let input_map = expect_yaml_map(input_value, path)
        ensure_allowed_keys(
          input_map,
          ["type", "required", "readonly", "default", "target"],
          path,
        )
        let default_value = optional_string_value(input_map, "default", path)
        let required =
          if input_map.contains("required") {
            optional_bool_value(input_map, "required", path, false)
          } else {
            default_value is None
          }
        inputs.push(ParsedTransitionInput::{
          name: input_name,
          type_name: required_string_value(input_map, "type", "\{path}.type"),
          required,
          read_only: optional_bool_value(input_map, "readonly", path, false),
          default_value,
          target: optional_string_value(input_map, "target", path),
        })
      }
      inputs
    }
  }
}

///|
fn parse_rules(
  entity_map : Map[String, YamlValue],
  entity_path : String,
) -> Array[ParsedRule] raise SchemaError {
  let rules : Array[ParsedRule] = []
  match entity_map.get("rules") {
    None => rules
    Some(rules_value) => {
      let rules_map = expect_yaml_map(rules_value, "\{entity_path}.rules")
      for rule_name, rule_value in rules_map {
        let path = "\{entity_path}.rules.\{rule_name}"
        let rule_map = expect_yaml_map(rule_value, path)
        ensure_allowed_keys(rule_map, ["when"], path)
        rules.push(ParsedRule::{
          name: rule_name,
          when_expr: required_string_value(rule_map, "when", "\{path}.when"),
        })
      }
      rules
    }
  }
}

///|
fn parse_views(
  entity_map : Map[String, YamlValue],
  entity_path : String,
) -> Array[ParsedView] raise SchemaError {
  let views : Array[ParsedView] = []
  match entity_map.get("views") {
    None => views
    Some(views_value) => {
      let views_map = expect_yaml_map(views_value, "\{entity_path}.views")
      for view_name, view_value in views_map {
        let path = "\{entity_path}.views.\{view_name}"
        let view_map = expect_yaml_map(view_value, path)
        ensure_allowed_keys(view_map, ["editable", "readonly"], path)
        views.push(ParsedView::{
          name: view_name,
          editable_fields: optional_string_list_value(
            view_map, "editable", path,
          ),
          readonly_fields: optional_string_list_value(
            view_map, "readonly", path,
          ),
        })
      }
      views
    }
  }
}

///|
fn parse_storage(
  entity_map : Map[String, YamlValue],
  entity_path : String,
) -> ParsedStorage raise SchemaError {
  match entity_map.get("storage") {
    None =>
      ParsedStorage::{
        table: None,
        indexes: [],
        unique_keys: [],
        soft_delete: false,
      }
    Some(storage_value) => {
      let path = "\{entity_path}.storage"
      let storage_map = expect_yaml_map(storage_value, path)
      ensure_allowed_keys(
        storage_map,
        ["table", "indexes", "unique", "softDelete"],
        path,
      )
      ParsedStorage::{
        table: optional_string_value(storage_map, "table", path),
        indexes: parse_storage_keys(storage_map, "indexes", path),
        unique_keys: parse_storage_keys(storage_map, "unique", path),
        soft_delete: optional_bool_value(storage_map, "softDelete", path, false),
      }
    }
  }
}

///|
fn parse_storage_keys(
  storage_map : Map[String, YamlValue],
  key : String,
  path : String,
) -> Array[ParsedStorageKey] raise SchemaError {
  let parsed : Array[ParsedStorageKey] = []
  match storage_map.get(key) {
    None => parsed
    Some(value) => {
      let list = expect_yaml_list(value, "\{path}.\{key}")
      for item in list {
        let item_map = expect_yaml_map(item, "\{path}.\{key}")
        ensure_allowed_keys(item_map, ["fields"], "\{path}.\{key}")
        let fields_value = require_key(
          item_map,
          "fields",
          "\{path}.\{key}.fields",
        )
        let fields = expect_yaml_list(fields_value, "\{path}.\{key}.fields")
        parsed.push(ParsedStorageKey::{
          fields: yaml_string_list(fields, "\{path}.\{key}.fields"),
        })
      }
      parsed
    }
  }
}

///|
fn ensure_allowed_keys(
  map : Map[String, YamlValue],
  allowed : Array[String],
  path : String,
) -> Unit raise SchemaError {
  for key, _ in map {
    if !string_array_contains(allowed, key) {
      raise SchemaError::ValidationError(path~, "unknown key \{key}")
    }
  }
}

///|
fn string_array_contains(values : Array[String], candidate : String) -> Bool {
  for value in values {
    if value == candidate {
      return true
    }
  }
  false
}

///|
fn require_key(
  map : Map[String, YamlValue],
  key : String,
  path : String,
) -> YamlValue raise SchemaError {
  match map.get(key) {
    Some(value) => value
    None =>
      raise SchemaError::ValidationError(path~, "missing required key \{key}")
  }
}

///|
fn expect_yaml_map(
  value : YamlValue,
  path : String,
) -> Map[String, YamlValue] raise SchemaError {
  match value {
    YamlValue::YamlMap(map) => map
    _ => raise SchemaError::ValidationError(path~, "expected a mapping")
  }
}

///|
fn expect_yaml_list(
  value : YamlValue,
  path : String,
) -> Array[YamlValue] raise SchemaError {
  match value {
    YamlValue::YamlList(items) => items
    _ => raise SchemaError::ValidationError(path~, "expected a list")
  }
}

///|
fn expect_yaml_scalar(
  value : YamlValue,
  path : String,
) -> String raise SchemaError {
  match value {
    YamlValue::YamlScalar(text) => text
    _ => raise SchemaError::ValidationError(path~, "expected a scalar value")
  }
}

///|
fn required_string_value(
  map : Map[String, YamlValue],
  key : String,
  path : String,
) -> String raise SchemaError {
  let value = require_key(map, key, path)
  expect_yaml_scalar(value, path)
}

///|
fn optional_string_value(
  map : Map[String, YamlValue],
  key : String,
  path : String,
) -> String? raise SchemaError {
  match map.get(key) {
    None => None
    Some(value) => Some(expect_yaml_scalar(value, "\{path}.\{key}"))
  }
}

///|
fn optional_localized_label_value(
  map : Map[String, YamlValue],
  key : String,
  path : String,
  fallback : String,
) -> (String, Map[String, String]) raise SchemaError {
  match map.get(key) {
    None => (fallback, {})
    Some(value) => localized_label_value(value, "\{path}.\{key}", fallback)
  }
}

///|
fn localized_label_value(
  value : YamlValue,
  path : String,
  fallback : String,
) -> (String, Map[String, String]) raise SchemaError {
  match value {
    YamlValue::YamlScalar(text) => (text, {})
    YamlValue::YamlMap(entries) => {
      let labels : Map[String, String] = {}
      for locale_key, locale_value in entries {
        let normalized_key = normalize_localized_label_key(locale_key, path)
        if labels.contains(normalized_key) {
          raise SchemaError::ValidationError(
            path~,
            "duplicate localized label key \{normalized_key}",
          )
        }
        labels[normalized_key] = expect_yaml_scalar(
          locale_value,
          "\{path}.\{locale_key}",
        )
      }
      (default_localized_text(labels, fallback), labels)
    }
    _ =>
      raise SchemaError::ValidationError(
        path~,
        "expected a scalar or mapping for localized label",
      )
  }
}

///|
fn normalize_localized_label_key(
  locale_key : String,
  path : String,
) -> String raise SchemaError {
  let normalized_key = normalize_label_locale(locale_key)
  if normalized_key == "" {
    raise SchemaError::ValidationError(path~, "localized label keys must not be empty")
  }
  normalized_key
}

///|
fn optional_bool_value(
  map : Map[String, YamlValue],
  key : String,
  path : String,
  default_ : Bool,
) -> Bool raise SchemaError {
  match map.get(key) {
    None => default_
    Some(value) => yaml_bool(value, "\{path}.\{key}")
  }
}

///|
fn optional_string_list_value(
  map : Map[String, YamlValue],
  key : String,
  path : String,
) -> Array[String] raise SchemaError {
  match map.get(key) {
    None => []
    Some(value) => {
      let items = expect_yaml_list(value, "\{path}.\{key}")
      yaml_string_list(items, "\{path}.\{key}")
    }
  }
}

///|
fn yaml_bool(value : YamlValue, path : String) -> Bool raise SchemaError {
  let text = expect_yaml_scalar(value, path)
  match normalize_token(text) {
    "true" => true
    "false" => false
    _ => raise SchemaError::ValidationError(path~, "expected `true` or `false`")
  }
}

///|
fn yaml_string_list(
  values : Array[YamlValue],
  path : String,
) -> Array[String] raise SchemaError {
  let strings : Array[String] = []
  for value in values {
    strings.push(expect_yaml_scalar(value, path))
  }
  strings
}
