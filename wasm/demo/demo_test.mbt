///|
fn demo_yaml() -> String {
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
test "render_manifest_preview returns HTML" {
  let result = render_manifest_preview(demo_yaml())
  inspect(result_is_ok(result), content="true")
  inspect(
    result_unwrap(result).contains("<title>Generated GUI Preview</title>"),
    content="true",
  )
}

///|
test "render_runtime_preview returns manager-submitted HTML" {
  let result = render_runtime_preview(demo_yaml(), "submitted-manager")
  inspect(result_is_ok(result), content="true")
  let html = result_unwrap(result)
  inspect(html.contains("view: submitted"), content="true")
  inspect(html.contains("canApprove"), content="true")
}

///|
test "render_runtime_preview returns an error for unknown scenarios" {
  let result = render_runtime_preview(demo_yaml(), "unknown-scenario")
  inspect(result_is_ok(result), content="false")
  inspect(
    result_error(result).contains("unsupported preview scenario"),
    content="true",
  )
}

///|
test "render_validation_manifest returns validation json" {
  let result = render_validation_manifest(demo_yaml())
  inspect(result_is_ok(result), content="true")
  inspect(
    result_unwrap(result).contains("\"constraints\""),
    content="true",
  )
}
