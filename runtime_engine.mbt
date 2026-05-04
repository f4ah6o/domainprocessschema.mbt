///|
fn runtime_validate_record(
  runtime : Runtime,
  entity_name : String,
  payload : Map[String, RuntimeValue],
  current : RuntimeRecord?,
) -> RuntimeValidation raise RuntimeError {
  let entity = runtime_find_entity(runtime, entity_name)
  match current {
    Some(record) =>
      if record.entity_name != entity_name {
        raise RuntimeError::EntityMismatch(
          expected=entity_name,
          found=record.entity_name,
        )
      }
    None => ()
  }

  let normalized : Map[String, RuntimeValue] = {}
  let issues : Array[RuntimeIssue] = []

  match current {
    Some(record) =>
      for key, value in record.values {
        normalized[key] = value
      }
    None => ()
  }

  for key, _ in payload {
    if runtime_find_field(entity, key) is None {
      issues.push(
        runtime_issue(
          "runtime.entities.\{entity.name}.payload.\{key}",
          "unknown field \{key}",
        ),
      )
    }
  }

  for field in entity.fields {
    let field_path = "runtime.entities.\{entity.name}.fields.\{field.name}"
    let payload_value = payload.get(field.name)
    if payload_value is Some(_) && field.system {
      issues.push(
        runtime_issue(
          field_path,
          "system field \{field.name} cannot be set from runtime payload",
        ),
      )
      continue
    }

    match payload_value {
      Some(value) =>
        match runtime_parse_field_value(field, value, field_path) {
          Ok(Some(parsed_value)) => normalized[field.name] = parsed_value
          Ok(None) => normalized.remove(field.name)
          Err(issue) => issues.push(issue)
        }
      None =>
        if !normalized.contains(field.name) {
          match runtime_default_value(field, field_path) {
            Ok(Some(default_value)) => normalized[field.name] = default_value
            Ok(None) => ()
            Err(issue) => issues.push(issue)
          }
        }
    }
  }

  match runtime_find_state_field(entity) {
    Some(state_field) =>
      match normalized.get(state_field.name) {
        Some(RuntimeValue::Text(state_name)) =>
          if !runtime_entity_has_state(entity, state_name) {
            issues.push(
              runtime_issue(
                "runtime.entities.\{entity.name}.fields.\{state_field.name}",
                "unknown state \{state_name}",
              ),
            )
          }
        Some(_) =>
          issues.push(
            runtime_issue(
              "runtime.entities.\{entity.name}.fields.\{state_field.name}",
              "state field must be stored as text",
            ),
          )
        None => ()
      }
    None => ()
  }

  for field in entity.fields {
    if field.required && !normalized.contains(field.name) {
      issues.push(
        runtime_issue(
          "runtime.entities.\{entity.name}.fields.\{field.name}",
          "required field \{field.name} is missing",
        ),
      )
    }
  }

  for constraint in entity.constraints {
    let constraint_path = "runtime.entities.\{entity.name}.constraints.\{constraint.name}"
    match
      runtime_eval_bool_expr(
        entity,
        normalized,
        RuntimeActor::anonymous(),
        constraint.expr,
        constraint_path,
      ) {
      Ok(true) => ()
      Ok(false) =>
        issues.push(
          runtime_issue(
            constraint_path,
            "constraint \{constraint.name} evaluated to false",
          ),
        )
      Err(issue) => issues.push(issue)
    }
  }

  RuntimeValidation::{
    record: RuntimeRecord::{ entity_name: entity.name, values: normalized },
    issues,
  }
}

///|
fn runtime_entity_has_state(entity : Entity, state_name : String) -> Bool {
  for state in entity.states {
    if state.name == state_name {
      return true
    }
  }
  false
}

///|
fn runtime_transition_issues(
  entity : Entity,
  transition : Transition,
  values : Map[String, RuntimeValue],
  actor : RuntimeActor,
) -> Array[RuntimeIssue] {
  let issues : Array[RuntimeIssue] = []
  let transition_path = "runtime.entities.\{entity.name}.transitions.\{transition.name}"

  match runtime_find_state_field(entity) {
    Some(state_field) =>
      match values.get(state_field.name) {
        Some(RuntimeValue::Text(current_state)) =>
          if current_state != transition.from {
            issues.push(
              runtime_issue(
                transition_path,
                "transition \{transition.name} requires state \{transition.from}, got \{current_state}",
              ),
            )
          }
        Some(_) =>
          issues.push(
            runtime_issue(
              transition_path,
              "state field \{state_field.name} must be a text runtime value",
            ),
          )
        None =>
          issues.push(
            runtime_issue(
              transition_path,
              "state field \{state_field.name} is missing",
            ),
          )
      }
    None =>
      issues.push(
        runtime_issue(
          transition_path,
          "entity \{entity.name} does not define a state field",
        ),
      )
  }

  match transition.role {
    Some(required_role) =>
      match actor.attributes.get("role") {
        Some(RuntimeValue::Text(role)) =>
          if role != required_role {
            issues.push(
              runtime_issue(
                transition_path,
                "transition \{transition.name} requires role \{required_role}",
              ),
            )
          }
        Some(_) =>
          issues.push(
            runtime_issue(
              transition_path, "actor role must be provided as text",
            ),
          )
        None =>
          issues.push(
            runtime_issue(
              transition_path,
              "transition \{transition.name} requires actor role \{required_role}",
            ),
          )
      }
    None => ()
  }

  match transition.guard_expr {
    Some(expr) =>
      match
        runtime_eval_bool_expr(entity, values, actor, expr, transition_path) {
        Ok(true) => ()
        Ok(false) =>
          issues.push(
            runtime_issue(
              transition_path,
              "guard for transition \{transition.name} evaluated to false",
            ),
          )
        Err(issue) => issues.push(issue)
      }
    None => ()
  }

  issues
}

///|
fn runtime_list_transitions(
  runtime : Runtime,
  record : RuntimeRecord,
  actor : RuntimeActor,
) -> Array[RuntimeTransitionStatus] raise RuntimeError {
  let entity = runtime_find_entity(runtime, record.entity_name)
  let validation = runtime_validate_record(
    runtime,
    entity.name,
    {},
    Some(record),
  )
  let statuses : Array[RuntimeTransitionStatus] = []
  for transition in entity.transitions {
    let issues = copy_runtime_issues(validation.issues)
    if issues.length() == 0 {
      let transition_issues = runtime_transition_issues(
        entity,
        transition,
        validation.record.values,
        actor,
      )
      for issue in transition_issues {
        issues.push(issue)
      }
    }
    statuses.push(RuntimeTransitionStatus::{
      name: transition.name,
      from: transition.from,
      to: transition.to,
      role: transition.role,
      inputs: transition.inputs,
      available: issues.length() == 0,
      issues,
    })
  }
  statuses
}

///|
fn runtime_validate_transition_inputs(
  transition : Transition,
  input : Map[String, RuntimeValue],
  path_prefix : String,
) -> (Map[String, RuntimeValue], Array[RuntimeIssue]) {
  let entity_payload : Map[String, RuntimeValue] = {}
  let local_values : Map[String, RuntimeValue] = {}
  let issues : Array[RuntimeIssue] = []
  let known_names : Map[String, Bool] = {}

  for transition_input in transition.inputs {
    known_names[transition_input.name] = true
    let input_path = "\{path_prefix}.\{transition_input.name}"
    match transition_input.kind {
      TransitionInputKind::EntityField =>
        match input.get(transition_input.name) {
          Some(RuntimeValue::Null) | None =>
            if transition_input.required {
              issues.push(
                runtime_issue(
                  input_path,
                  "transition input field \{transition_input.name} is required",
                ),
              )
            }
          Some(value) => entity_payload[transition_input.name] = value
        }
      TransitionInputKind::Local =>
        match input.get(transition_input.name) {
          Some(value) =>
            match
              runtime_parse_transition_input_value(
                transition_input, value, input_path,
              ) {
              Ok(Some(parsed_value)) =>
                local_values[transition_input.name] = parsed_value
              Ok(None) =>
                if transition_input.required {
                  issues.push(
                    runtime_issue(
                      input_path,
                      "transition input \{transition_input.name} is required",
                    ),
                  )
                }
              Err(issue) => issues.push(issue)
            }
          None =>
            match
              runtime_transition_input_default_value(
                transition_input, input_path,
              ) {
              Ok(Some(default_value)) =>
                local_values[transition_input.name] = default_value
              Ok(None) =>
                if transition_input.required {
                  issues.push(
                    runtime_issue(
                      input_path,
                      "transition input \{transition_input.name} is required",
                    ),
                  )
                }
              Err(issue) => issues.push(issue)
            }
        }
    }
  }

  for key, _ in input {
    if !known_names.contains(key) {
      issues.push(
        runtime_issue(
          "\{path_prefix}.\{key}",
          "unknown transition input \{key}",
        ),
      )
    }
  }
  (entity_payload, issues)
}

///|
fn runtime_apply_transition(
  runtime : Runtime,
  record : RuntimeRecord,
  transition_name : String,
  input : Map[String, RuntimeValue],
  actor : RuntimeActor,
) -> RuntimeRecord raise RuntimeError {
  let entity = runtime_find_entity(runtime, record.entity_name)
  let transition = runtime_find_transition(entity, transition_name)
  let input_path = "runtime.entities.\{entity.name}.transitions.\{transition.name}.inputs"
  let (entity_payload, input_issues) = runtime_validate_transition_inputs(
    transition, input, input_path,
  )
  let validation = runtime_validate_record(
    runtime,
    entity.name,
    entity_payload,
    Some(record),
  )
  let issues = copy_runtime_issues(validation.issues)
  for issue in input_issues {
    issues.push(issue)
  }

  let transition_issues = runtime_transition_issues(
    entity,
    transition,
    validation.record.values,
    actor,
  )
  for issue in transition_issues {
    issues.push(issue)
  }

  if issues.length() > 0 {
    raise RuntimeError::TransitionRejected(
      entity=entity.name,
      transition=transition.name,
      issues~,
    )
  }

  let next_values = copy_runtime_values(validation.record.values)
  match runtime_find_state_field(entity) {
    Some(state_field) =>
      next_values[state_field.name] = RuntimeValue::Text(transition.to)
    None =>
      raise RuntimeError::TransitionRejected(
        entity=entity.name,
        transition=transition.name,
        issues=[
          runtime_issue(
            "runtime.entities.\{entity.name}.transitions.\{transition.name}",
            "entity \{entity.name} does not define a state field",
          ),
        ],
      )
  }

  let finalized = runtime_validate_record(
    runtime,
    entity.name,
    {},
    Some(RuntimeRecord::{ entity_name: entity.name, values: next_values }),
  )
  if !finalized.is_ok() {
    raise RuntimeError::TransitionRejected(
      entity=entity.name,
      transition=transition.name,
      issues=finalized.issues,
    )
  }
  finalized.record
}
