///|
fn runtime_sample_schema() -> String {
  (
    #|entities:
    #|  User:
    #|    label: ユーザー
    #|    fields:
    #|      id:
    #|        type: id
    #|        primary: true
    #|      role:
    #|        type: text
    #|        required: true
    #|  ExpenseRequest:
    #|    label: 経費申請
    #|    fields:
    #|      id:
    #|        type: id
    #|        primary: true
    #|      amount:
    #|        type: money
    #|        required: true
    #|      reason:
    #|        type: text
    #|        required: true
    #|      applicant:
    #|        type: ref
    #|        target: User
    #|        required: true
    #|      status:
    #|        type: state
    #|        initial: draft
    #|    constraints:
    #|      amountPositive:
    #|        expr: amount > 0
    #|    states:
    #|      draft:
    #|        label: 下書き
    #|      submitted:
    #|        label: 申請中
    #|      approved:
    #|        label: 承認済
    #|      rejected:
    #|        label: 却下
    #|    transitions:
    #|      submit:
    #|        from: draft
    #|        to: submitted
    #|        input:
    #|          - amount
    #|          - reason
    #|        guard: amount > 0
    #|      approve:
    #|        from: submitted
    #|        to: approved
    #|        role: manager
    #|      reject:
    #|        from: submitted
    #|        to: rejected
    #|        role: manager
  )
}

///|
fn sample_runtime() -> Runtime raise SchemaError {
  compile_runtime_from_yaml(runtime_sample_schema())
}

///|
fn draft_payload() -> Map[String, RuntimeValue] {
  {
    "id": RuntimeValue::Text("exp-1"),
    "amount": RuntimeValue::Integer(1200),
    "reason": RuntimeValue::Text("hotel"),
    "applicant": RuntimeValue::Text("user-1"),
  }
}

///|
fn manager_actor() -> RuntimeActor {
  RuntimeActor::{ attributes: { "role": RuntimeValue::Text("manager") } }
}

///|
fn available_transition_names(
  statuses : Array[RuntimeTransitionStatus],
) -> Array[String] {
  let names : Array[String] = []
  for status in statuses {
    if status.is_available() {
      names.push(status.name)
    }
  }
  names
}

///|
test "validate_record applies defaults for stateful entity payloads" {
  let runtime = sample_runtime()
  let validation = validate_record(runtime, "ExpenseRequest", draft_payload())
  inspect(validation.is_ok(), content="true")
  inspect(
    validation.record.values.get("status"),
    content="Some(Text(\"draft\"))",
  )
}

///|
test "validate_record reports required and constraint issues" {
  let runtime = sample_runtime()
  let validation = validate_record(runtime, "ExpenseRequest", {
    "id": RuntimeValue::Text("exp-2"),
    "amount": RuntimeValue::Integer(-1),
    "applicant": RuntimeValue::Text("user-1"),
  })
  let issue_messages = validation.issues.map(issue => {
    "\{issue.path}: \{issue.message}"
  })
  inspect(
    issue_messages,
    content="[\"runtime.entities.ExpenseRequest.fields.reason: required field reason is missing\", \"runtime.entities.ExpenseRequest.constraints.amountPositive: constraint amountPositive evaluated to false\"]",
  )
}

///|
test "list_transitions exposes availability from current state and actor" {
  let runtime = sample_runtime()
  let validation = validate_record(runtime, "ExpenseRequest", draft_payload())
  let draft_statuses = list_transitions(runtime, validation.record)
  inspect(available_transition_names(draft_statuses), content="[\"submit\"]")

  let submitted = apply_transition(runtime, validation.record, "submit", input={
    "amount": RuntimeValue::Integer(1200),
    "reason": RuntimeValue::Text("hotel"),
  })
  let submitted_statuses = list_transitions(
    runtime,
    submitted,
    actor=manager_actor(),
  )
  inspect(
    available_transition_names(submitted_statuses),
    content="[\"approve\", \"reject\"]",
  )
}

///|
test "apply_transition updates the state in memory" {
  let runtime = sample_runtime()
  let validation = validate_record(runtime, "ExpenseRequest", draft_payload())
  let submitted = apply_transition(runtime, validation.record, "submit", input={
    "amount": RuntimeValue::Integer(1200),
    "reason": RuntimeValue::Text("hotel"),
  })
  let approved = apply_transition(
    runtime,
    submitted,
    "approve",
    actor=manager_actor(),
  )
  inspect(approved.values.get("status"), content="Some(Text(\"approved\"))")
}
