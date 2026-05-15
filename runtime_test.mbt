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
    #|        input:
    #|          - rejectReason
    #|        inputs:
    #|          rejectReason:
    #|            type: text
    #|    rules:
    #|      canApprove:
    #|        when: state == "submitted" && user.role == "manager"
    #|    views:
    #|      draft:
    #|        editable:
    #|          - amount
    #|          - reason
    #|      submitted:
    #|        readonly:
    #|          - amount
    #|          - reason
    #|      approved:
    #|        readonly:
    #|          - amount
    #|          - reason
    #|      rejected:
    #|        readonly:
    #|          - amount
    #|          - reason
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
fn schema_missing_rejected_view() -> String {
  (
    #|entities:
    #|  ExpenseRequest:
    #|    label: 経費申請
    #|    fields:
    #|      id:
    #|        type: id
    #|        primary: true
    #|      status:
    #|        type: state
    #|        initial: draft
    #|    states:
    #|      draft:
    #|        label: 下書き
    #|      rejected:
    #|        label: 却下
    #|    views:
    #|      draft:
    #|        readonly:
    #|          - id
  )
}

///|
fn schema_with_default_local_input() -> String {
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
    #|      rejected:
    #|        label: 却下
    #|    transitions:
    #|      submit:
    #|        from: draft
    #|        to: submitted
    #|        input:
    #|          - amount
    #|          - reason
    #|      reject:
    #|        from: submitted
    #|        to: rejected
    #|        role: manager
    #|        input:
    #|          - rejectReason
    #|        inputs:
    #|          rejectReason:
    #|            type: text
    #|            default: auto-reject
    #|    views:
    #|      draft:
    #|        editable:
    #|          - amount
    #|          - reason
    #|      submitted:
    #|        readonly:
    #|          - amount
    #|          - reason
    #|      rejected:
    #|        readonly:
    #|          - amount
    #|          - reason
  )
}

///|
fn high_value_payment_schema() -> String {
  (
    #|entities:
    #|  Payment:
    #|    label: Payment
    #|    fields:
    #|      id:
    #|        type: id
    #|        primary: true
    #|      amount:
    #|        type: money
    #|        required: true
    #|      managerComment:
    #|        type: text
    #|      status:
    #|        type: state
    #|        initial: draft
    #|    states:
    #|      draft:
    #|        label: Draft
    #|      autoApproved:
    #|        label: Auto approved
    #|      needsApproval:
    #|        label: Needs approval
    #|      approved:
    #|        label: Approved
    #|      rejected:
    #|        label: Rejected
    #|    transitions:
    #|      submitSmall:
    #|        from: draft
    #|        to: autoApproved
    #|        guard: amount < 1000
    #|      submitLarge:
    #|        from: draft
    #|        to: needsApproval
    #|        guard: amount >= 1000
    #|      approve:
    #|        from: needsApproval
    #|        to: approved
    #|        role: manager
    #|        guard: amount >= 2000
    #|      reject:
    #|        from: needsApproval
    #|        to: rejected
    #|        role: manager
    #|        input:
    #|          - managerComment
    #|    rules:
    #|      defaultPrecedenceKeepsDraftActive:
    #|        when: amount > 0 && user.role == "manager" || state == "draft"
    #|      groupedPrecedenceRequiresPositiveAmount:
    #|        when: amount > 0 && (user.role == "manager" || state == "draft")
    #|      missingActorDepartment:
    #|        when: user.department.name == "sales"
    #|    views:
    #|      draft:
    #|        editable:
    #|          - amount
    #|      autoApproved:
    #|        readonly:
    #|          - amount
    #|          - managerComment
    #|      needsApproval:
    #|        readonly:
    #|          - amount
    #|        editable:
    #|          - managerComment
    #|      approved:
    #|        readonly:
    #|          - amount
    #|          - managerComment
    #|      rejected:
    #|        readonly:
    #|          - amount
    #|          - managerComment
  )
}

///|
fn high_value_payment_runtime() -> Runtime raise SchemaError {
  compile_runtime_from_yaml(high_value_payment_schema())
}

///|
fn high_value_payment_payload(amount : Int) -> Map[String, RuntimeValue] {
  {
    "id": RuntimeValue::Text("pay-\{amount}"),
    "amount": RuntimeValue::Integer(amount),
  }
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
fn transition_issue_messages(
  statuses : Array[RuntimeTransitionStatus],
  transition_name : String,
) -> Array[String] {
  for status in statuses {
    if status.name == transition_name {
      return runtime_issue_messages(status.issues)
    }
  }
  []
}

///|
fn runtime_issue_messages(issues : Array[RuntimeIssue]) -> Array[String] {
  issues.map(issue => "\{issue.path}: \{issue.message}")
}

///|
fn active_rule_names(statuses : Array[RuntimeRuleStatus]) -> Array[String] {
  let names : Array[String] = []
  for status in statuses {
    if status.active && status.issues.length() == 0 {
      names.push(status.name)
    }
  }
  names
}

///|
fn rule_active_flag(
  statuses : Array[RuntimeRuleStatus],
  rule_name : String,
) -> String {
  for status in statuses {
    if status.name == rule_name {
      return if status.active { "active" } else { "inactive" }
    }
  }
  "missing"
}

///|
fn rule_issue_messages(
  statuses : Array[RuntimeRuleStatus],
  rule_name : String,
) -> Array[String] {
  for status in statuses {
    if status.name == rule_name {
      return runtime_issue_messages(status.issues)
    }
  }
  []
}

///|
fn action_input_names(
  view : RuntimeGuiView,
  action_name : String,
) -> Array[String] {
  for action in view.actions {
    if action.name == action_name {
      let names : Array[String] = []
      for input in action.inputs {
        names.push(input.name)
      }
      return names
    }
  }
  []
}

///|
fn gui_field_modes(view : RuntimeGuiView) -> Array[String] {
  view.fields.map(field => "\{field.name}:\{field.mode}")
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
test "apply_transition rejects a transition from the wrong state" {
  let runtime = sample_runtime()
  let draft = validate_record(runtime, "ExpenseRequest", draft_payload()).record
  let result : Result[RuntimeRecord, RuntimeError] = try? apply_transition(
    runtime,
    draft,
    "approve",
    actor=manager_actor(),
  )
  guard result
    is Err(RuntimeError::TransitionRejected(entity~, transition~, issues~)) else {
    fail("expected approve to be rejected from draft")
  }
  inspect(entity, content="ExpenseRequest")
  inspect(transition, content="approve")
  inspect(
    runtime_issue_messages(issues),
    content="[\"runtime.entities.ExpenseRequest.transitions.approve: transition approve requires state submitted, got draft\"]",
  )
}

///|
test "list_transitions requires role and guard before availability" {
  let runtime = high_value_payment_runtime()
  let below_limit = validate_record(
      runtime,
      "Payment",
      high_value_payment_payload(1500),
    ).record
  let needs_approval_below_limit = apply_transition(
    runtime, below_limit, "submitLarge",
  )
  let manager_statuses = list_transitions(
    runtime,
    needs_approval_below_limit,
    actor=manager_actor(),
  )
  inspect(available_transition_names(manager_statuses), content="[\"reject\"]")
  inspect(
    transition_issue_messages(manager_statuses, "approve"),
    content="[\"runtime.entities.Payment.transitions.approve: guard for transition approve evaluated to false\"]",
  )

  let at_limit = validate_record(
      runtime,
      "Payment",
      high_value_payment_payload(2000),
    ).record
  let needs_approval_at_limit = apply_transition(
    runtime, at_limit, "submitLarge",
  )
  let applicant_statuses = list_transitions(runtime, needs_approval_at_limit, actor=RuntimeActor::{
    attributes: { "role": RuntimeValue::Text("staff") },
  })
  inspect(available_transition_names(applicant_statuses), content="[]")
  inspect(
    transition_issue_messages(applicant_statuses, "approve"),
    content="[\"runtime.entities.Payment.transitions.approve: transition approve requires role manager\"]",
  )

  let manager_at_limit_statuses = list_transitions(
    runtime,
    needs_approval_at_limit,
    actor=manager_actor(),
  )
  inspect(
    available_transition_names(manager_at_limit_statuses),
    content="[\"approve\", \"reject\"]",
  )
  let approved = apply_transition(
    runtime,
    needs_approval_at_limit,
    "approve",
    actor=manager_actor(),
  )
  inspect(approved.values.get("status"), content="Some(Text(\"approved\"))")
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

///|
test "high value payment guards select exactly one submit path" {
  let runtime = high_value_payment_runtime()
  let small = validate_record(
      runtime,
      "Payment",
      high_value_payment_payload(999),
    ).record
  let large = validate_record(
      runtime,
      "Payment",
      high_value_payment_payload(1000),
    ).record
  inspect(
    available_transition_names(list_transitions(runtime, small)),
    content="[\"submitSmall\"]",
  )
  inspect(
    available_transition_names(list_transitions(runtime, large)),
    content="[\"submitLarge\"]",
  )

  let missing_amount = RuntimeRecord::{
    entity_name: "Payment",
    values: {
      "id": RuntimeValue::Text("pay-missing"),
      "status": RuntimeValue::Text("draft"),
    },
  }
  inspect(
    available_transition_names(list_transitions(runtime, missing_amount)),
    content="[]",
  )
  inspect(
    transition_issue_messages(
      list_transitions(runtime, missing_amount),
      "submitSmall",
    ),
    content="[\"runtime.entities.Payment.fields.amount: required field amount is missing\"]",
  )
}

///|
test "expression precedence is visible through runtime rules" {
  let runtime = high_value_payment_runtime()
  let draft = validate_record(
      runtime,
      "Payment",
      high_value_payment_payload(-1),
    ).record
  let rules = evaluate_rules(runtime, draft, actor=RuntimeActor::{
    attributes: { "role": RuntimeValue::Text("staff") },
  })
  inspect(
    active_rule_names(rules),
    content="[\"defaultPrecedenceKeepsDraftActive\"]",
  )
  inspect(
    rule_active_flag(rules, "groupedPrecedenceRequiresPositiveAmount"),
    content="inactive",
  )
}

///|
test "missing actor path reports a diagnostic instead of activating rule" {
  let runtime = high_value_payment_runtime()
  let record = validate_record(
      runtime,
      "Payment",
      high_value_payment_payload(1200),
    ).record
  let rules = evaluate_rules(runtime, record, actor=manager_actor())
  inspect(
    rule_issue_messages(rules, "missingActorDepartment"),
    content="[\"runtime.entities.Payment.rules.missingActorDepartment: missing actor attribute department.name\"]",
  )
}

///|
test "project_gui reflects state field modes for high value payments" {
  let runtime = high_value_payment_runtime()
  let draft = validate_record(
      runtime,
      "Payment",
      high_value_payment_payload(1200),
    ).record
  inspect(
    gui_field_modes(project_gui(runtime, draft)),
    content="[\"amount:editable\"]",
  )

  let needs_approval = apply_transition(runtime, draft, "submitLarge")
  inspect(
    gui_field_modes(project_gui(runtime, needs_approval, actor=manager_actor())),
    content="[\"amount:readonly\", \"managerComment:editable\"]",
  )
}

///|
test "evaluate_rules and project_gui follow the issue runtime model" {
  let runtime = sample_runtime()
  let draft = validate_record(runtime, "ExpenseRequest", draft_payload()).record
  let submitted = apply_transition(runtime, draft, "submit", input={
    "amount": RuntimeValue::Integer(1200),
    "reason": RuntimeValue::Text("hotel"),
  })
  let rules = evaluate_rules(runtime, submitted, actor=manager_actor())
  inspect(active_rule_names(rules), content="[\"canApprove\"]")

  let gui = project_gui(runtime, submitted, actor=manager_actor())
  inspect(gui.view_name, content="submitted")
  inspect(action_input_names(gui, "reject"), content="[\"rejectReason\"]")
}

///|
test "compile_runtime_from_yaml rejects states without matching views" {
  let result : Result[Runtime, SchemaError] = try? compile_runtime_from_yaml(
    schema_missing_rejected_view(),
  )
  guard result is Err(SchemaError::ValidationError(_, ..)) else {
    fail("expected a validation error for missing state view")
  }
}

///|
test "defaulted transition-local input is not treated as missing" {
  let runtime = compile_runtime_from_yaml(schema_with_default_local_input())
  let draft = validate_record(runtime, "ExpenseRequest", draft_payload()).record
  let submitted = apply_transition(runtime, draft, "submit", input={
    "amount": RuntimeValue::Integer(1200),
    "reason": RuntimeValue::Text("hotel"),
  })
  let rejected = apply_transition(
    runtime,
    submitted,
    "reject",
    actor=manager_actor(),
  )
  inspect(rejected.values.get("status"), content="Some(Text(\"rejected\"))")
}
