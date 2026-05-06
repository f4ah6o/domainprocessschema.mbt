///|
fn runtime_find_entity(
  runtime : Runtime,
  entity_name : String,
) -> Entity raise RuntimeError {
  for entity in runtime.schema.entities {
    if entity.name == entity_name {
      return entity
    }
  }
  raise RuntimeError::UnknownEntity(entity=entity_name)
}

///|
fn runtime_find_field(entity : Entity, field_name : String) -> Field? {
  for field in entity.fields {
    if field.name == field_name {
      return Some(field)
    }
  }
  None
}

///|
fn runtime_find_transition(
  entity : Entity,
  transition_name : String,
) -> Transition raise RuntimeError {
  for transition in entity.transitions {
    if transition.name == transition_name {
      return transition
    }
  }
  raise RuntimeError::UnknownTransition(
    entity=entity.name,
    transition=transition_name,
  )
}

///|
fn runtime_find_view(
  entity : Entity,
  state_name : String,
) -> View raise RuntimeError {
  for view in entity.views {
    if view.name == state_name {
      return view
    }
  }
  raise RuntimeError::MissingView(entity=entity.name, state=state_name)
}

///|
fn runtime_find_state_field(entity : Entity) -> Field? {
  for field in entity.fields {
    if field.field_type == FieldType::State {
      return Some(field)
    }
  }
  None
}

///|
fn runtime_issue(
  target : String,
  message : String,
  code? : String = "RUNTIME_ERROR",
  hint? : String = "",
  context? : Map[String, String] = {},
) -> Diagnostic {
  diagnostic(code, target, message, hint~, context~)
}

///|
fn copy_runtime_values(
  values : Map[String, RuntimeValue],
) -> Map[String, RuntimeValue] {
  let copied : Map[String, RuntimeValue] = {}
  for key, value in values {
    copied[key] = value
  }
  copied
}

///|
fn copy_runtime_issues(issues : Array[Diagnostic]) -> Array[Diagnostic] {
  let copied : Array[Diagnostic] = []
  for issue in issues {
    copied.push(issue)
  }
  copied
}

///|
fn runtime_current_state(
  entity : Entity,
  values : Map[String, RuntimeValue],
  path : String,
) -> Result[String, Diagnostic] {
  match runtime_find_state_field(entity) {
    Some(state_field) =>
      match values.get(state_field.name) {
        Some(RuntimeValue::Text(state_name)) => Ok(state_name)
        Some(_) =>
          Err(
            runtime_issue(
              path,
              "state field \{state_field.name} must be stored as text",
              code="INVALID_RUNTIME_INPUT",
            ),
          )
        None =>
          Err(
            runtime_issue(
              path,
              "state field \{state_field.name} is missing",
              code="UNKNOWN_STATE",
            ),
          )
      }
    None =>
      Err(
        runtime_issue(
          path,
          "entity \{entity.name} has no state field",
          code="UNKNOWN_STATE",
        ),
      )
  }
}

///|
fn parse_runtime_integer(text : String) -> Int {
  let trimmed = text.trim()
  let chars = trimmed.to_array()
  let mut negative = false
  let mut index = 0
  if chars.length() > 0 && chars[0] == '-' {
    negative = true
    index = 1
  }
  let mut value = 0
  for char in chars[index:] {
    let char_value = char.to_int()
    let zero_value = '0'.to_int()
    value = value * 10 + (char_value - zero_value)
  }
  if negative {
    -value
  } else {
    value
  }
}

///|
fn runtime_default_value(
  field : Field,
  path : String,
) -> Result[RuntimeValue?, Diagnostic] {
  if field.field_type == FieldType::State {
    match field.initial {
      Some(initial) => Ok(Some(RuntimeValue::Text(initial)))
      None => Ok(None)
    }
  } else {
    match field.default_value {
      Some(raw) =>
        runtime_parse_field_value(field, RuntimeValue::Text(raw), path)
      None => Ok(None)
    }
  }
}

///|
fn runtime_transition_input_default_value(
  input : TransitionInput,
  path : String,
) -> Result[RuntimeValue?, Diagnostic] {
  match input.default_value {
    Some(raw) =>
      runtime_parse_transition_input_value(input, RuntimeValue::Text(raw), path)
    None => Ok(None)
  }
}

///|
fn runtime_parse_field_value(
  field : Field,
  value : RuntimeValue,
  path : String,
) -> Result[RuntimeValue?, Diagnostic] {
  match value {
    RuntimeValue::Null => Ok(None)
    RuntimeValue::Text(text) =>
      match field.field_type {
        FieldType::Id
        | FieldType::Text
        | FieldType::Date
        | FieldType::DateTime
        | FieldType::Enum
        | FieldType::Ref
        | FieldType::State
        | FieldType::File => Ok(Some(RuntimeValue::Text(text)))
        FieldType::Boolean => {
          let normalized = normalize_token(text)
          if normalized == "true" {
            Ok(Some(RuntimeValue::Flag(true)))
          } else if normalized == "false" {
            Ok(Some(RuntimeValue::Flag(false)))
          } else {
            Err(
              runtime_issue(
                path,
                "expected boolean for field \{field.name}, got \{text}",
                code="INVALID_RUNTIME_INPUT",
              ),
            )
          }
        }
        FieldType::Number | FieldType::Money =>
          if is_integer_literal(text) {
            Ok(Some(RuntimeValue::Integer(parse_runtime_integer(text))))
          } else {
            Err(
              runtime_issue(
                path,
                "expected integer for field \{field.name}, got \{text}",
                code="INVALID_RUNTIME_INPUT",
              ),
            )
          }
      }
    RuntimeValue::Integer(number) =>
      match field.field_type {
        FieldType::Number | FieldType::Money =>
          Ok(Some(RuntimeValue::Integer(number)))
        _ =>
          Err(
            runtime_issue(
              path,
              "expected \{field_type_name(field.field_type)} text value for field \{field.name}",
              code="INVALID_RUNTIME_INPUT",
            ),
          )
      }
    RuntimeValue::Flag(flag) =>
      if field.field_type == FieldType::Boolean {
        Ok(Some(RuntimeValue::Flag(flag)))
      } else {
        Err(
          runtime_issue(
            path,
            "expected \{field_type_name(field.field_type)} value for field \{field.name}",
            code="INVALID_RUNTIME_INPUT",
          ),
        )
      }
  }
}

///|
fn runtime_parse_transition_input_value(
  input : TransitionInput,
  value : RuntimeValue,
  path : String,
) -> Result[RuntimeValue?, Diagnostic] {
  match value {
    RuntimeValue::Null => Ok(None)
    RuntimeValue::Text(text) =>
      match input.field_type {
        FieldType::Id
        | FieldType::Text
        | FieldType::Date
        | FieldType::DateTime
        | FieldType::Enum
        | FieldType::Ref
        | FieldType::File => Ok(Some(RuntimeValue::Text(text)))
        FieldType::Boolean => {
          let normalized = normalize_token(text)
          if normalized == "true" {
            Ok(Some(RuntimeValue::Flag(true)))
          } else if normalized == "false" {
            Ok(Some(RuntimeValue::Flag(false)))
          } else {
            Err(
              runtime_issue(
                path,
                "expected boolean for transition input \{input.name}, got \{text}",
                code="INVALID_TRANSITION_INPUT",
              ),
            )
          }
        }
        FieldType::Number | FieldType::Money =>
          if is_integer_literal(text) {
            Ok(Some(RuntimeValue::Integer(parse_runtime_integer(text))))
          } else {
            Err(
              runtime_issue(
                path,
                "expected integer for transition input \{input.name}, got \{text}",
                code="INVALID_TRANSITION_INPUT",
              ),
            )
          }
        FieldType::State =>
          Err(
            runtime_issue(
              path,
              "transition-local inputs cannot use `state` values",
              code="INVALID_TRANSITION_INPUT",
            ),
          )
      }
    RuntimeValue::Integer(number) =>
      match input.field_type {
        FieldType::Number | FieldType::Money =>
          Ok(Some(RuntimeValue::Integer(number)))
        _ =>
          Err(
            runtime_issue(
              path,
              "expected \{field_type_name(input.field_type)} text value for transition input \{input.name}",
              code="INVALID_TRANSITION_INPUT",
            ),
          )
      }
    RuntimeValue::Flag(flag) =>
      if input.field_type == FieldType::Boolean {
        Ok(Some(RuntimeValue::Flag(flag)))
      } else {
        Err(
          runtime_issue(
            path,
            "expected \{field_type_name(input.field_type)} value for transition input \{input.name}",
            code="INVALID_TRANSITION_INPUT",
          ),
        )
      }
  }
}

///|
fn runtime_value_equals(left : RuntimeValue, right : RuntimeValue) -> Bool? {
  match (left, right) {
    (RuntimeValue::Null, RuntimeValue::Null) => Some(true)
    (RuntimeValue::Text(left), RuntimeValue::Text(right)) => Some(left == right)
    (RuntimeValue::Integer(left), RuntimeValue::Integer(right)) =>
      Some(left == right)
    (RuntimeValue::Flag(left), RuntimeValue::Flag(right)) => Some(left == right)
    _ => None
  }
}

///|
fn runtime_value_compare(left : RuntimeValue, right : RuntimeValue) -> Int? {
  match (left, right) {
    (RuntimeValue::Text(left), RuntimeValue::Text(right)) =>
      if left < right {
        Some(-1)
      } else if left > right {
        Some(1)
      } else {
        Some(0)
      }
    (RuntimeValue::Integer(left), RuntimeValue::Integer(right)) =>
      if left < right {
        Some(-1)
      } else if left > right {
        Some(1)
      } else {
        Some(0)
      }
    _ => None
  }
}

///|
fn runtime_value_to_bool(
  value : RuntimeValue,
  path : String,
) -> Result[Bool, Diagnostic] {
  match value {
    RuntimeValue::Flag(flag) => Ok(flag)
    _ =>
      Err(
        runtime_issue(
          path,
          "expression must evaluate to boolean",
          code="INVALID_EXPR",
        ),
      )
  }
}
