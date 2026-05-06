///|
fn runtime_evaluate_rules(
  runtime : Runtime,
  record : RuntimeRecord,
  actor : RuntimeActor,
) -> Array[RuntimeRuleStatus] raise RuntimeError {
  let entity = runtime_find_entity(runtime, record.entity_name)
  let validation = runtime_validate_record(
    runtime,
    entity.name,
    {},
    Some(record),
  )
  let statuses : Array[RuntimeRuleStatus] = []
  for rule in entity.rules {
    let issues = copy_runtime_issues(validation.issues)
    let mut active = false
    if issues.length() == 0 {
      let rule_path = "runtime.entities.\{entity.name}.rules.\{rule.name}"
      match
        runtime_eval_bool_expr(
          entity,
          validation.record.values,
          actor,
          rule.when_expr,
          rule_path,
        ) {
        Ok(result) => active = result
        Err(issue) => issues.push(issue)
      }
    }
    statuses.push(RuntimeRuleStatus::{ name: rule.name, active, issues })
  }
  statuses
}

///|
fn runtime_find_transition_status(
  statuses : Array[RuntimeTransitionStatus],
  transition_name : String,
) -> RuntimeTransitionStatus {
  for status in statuses {
    if status.name == transition_name {
      return status
    }
  }
  abort("transition status missing for \{transition_name}")
}

///|
fn runtime_gui_input_value(
  record : RuntimeRecord,
  input : TransitionInput,
  path : String,
) -> Result[RuntimeValue?, Diagnostic] {
  match input.kind {
    TransitionInputKind::EntityField => Ok(record.values.get(input.name))
    TransitionInputKind::Local =>
      runtime_transition_input_default_value(input, path)
  }
}

///|
fn runtime_project_gui(
  runtime : Runtime,
  record : RuntimeRecord,
  actor : RuntimeActor,
  locale : String,
) -> RuntimeGuiView raise RuntimeError {
  let entity = runtime_find_entity(runtime, record.entity_name)
  let validation = runtime_validate_record(
    runtime,
    entity.name,
    {},
    Some(record),
  )
  let state_path = "runtime.entities.\{entity.name}.state"
  let state_name = match
    runtime_current_state(entity, validation.record.values, state_path) {
    Ok(state_name) => state_name
    Err(issue) =>
      raise RuntimeError::InvalidRecord(entity=entity.name, issues=[issue])
  }
  let view = runtime_find_view(entity, state_name)
  let entity_label = resolved_entity_label(entity, locale)
  let state_label = resolved_state_label(entity, state_name, locale)
  let transition_statuses = runtime_list_transitions(
    runtime,
    validation.record,
    actor,
  )
  let rule_statuses = runtime_evaluate_rules(runtime, validation.record, actor)

  let fields : Array[RuntimeGuiField] = []
  for field in entity.fields {
    let mode = gui_field_mode(field, view)
    if mode != "hidden" {
      fields.push(RuntimeGuiField::{
        name: field.name,
        label: resolve_localized_text(field.label, field.labels, locale),
        component: gui_component(field.field_type),
        mode,
        value: validation.record.values.get(field.name),
      })
    }
  }

  let actions : Array[RuntimeGuiAction] = []
  for transition in entity.transitions {
    if transition.from == state_name {
      let status = runtime_find_transition_status(
        transition_statuses,
        transition.name,
      )
      let inputs : Array[RuntimeGuiActionInput] = []
      for input in transition.inputs {
        let input_path = "runtime.entities.\{entity.name}.transitions.\{transition.name}.inputs.\{input.name}"
        let value = match
          runtime_gui_input_value(validation.record, input, input_path) {
          Ok(value) => value
          Err(_) => None
        }
        inputs.push(RuntimeGuiActionInput::{
          name: input.name,
          label: resolved_transition_input_label(entity, input, locale),
          kind: input.kind,
          component: gui_component(input.field_type),
          required: input.required,
          value,
        })
      }
      actions.push(RuntimeGuiAction::{
        name: transition.name,
        to: transition.to,
        available: status.is_available(),
        issues: status.issues,
        inputs,
      })
    }
  }

  RuntimeGuiView::{
    entity_name: entity.name,
    entity_label,
    state: state_name,
    state_label,
    view_name: view.name,
    fields,
    actions,
    rules: rule_statuses,
  }
}
