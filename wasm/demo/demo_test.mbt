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
    #|          - applicant
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
  inspect(result_unwrap(result).contains("\"constraints\""), content="true")
}

///|
test "create_demo_session exposes available transitions in snapshot json" {
  let session_result = create_demo_session(demo_yaml())
  inspect(session_result_is_ok(session_result), content="true")
  let session = session_result_unwrap(session_result)
  let snapshot = result_unwrap(session_snapshot_json(session))
  inspect(snapshot.contains("\"state\":\"draft\""), content="true")
  inspect(
    snapshot.contains("\"fields\":[{\"name\":\"amount\",\"label\":\"amount\",\"component\":\"money\",\"mode\":\"editable\",\"value\":1200}"),
    content="true",
  )
  inspect(snapshot.contains("\"component\":\"reference-select\""), content="true")
  inspect(snapshot.contains("\"name\":\"submit\""), content="true")
}

///|
test "apply_session_transition rerenders submitted session state" {
  let session = session_result_unwrap(
    create_demo_session(demo_yaml(), actor_role="manager"),
  )
  let updated = apply_session_transition(
    session, "submit", "{\"amount\":1200,\"reason\":\"hotel\",\"applicant\":\"user-1\"}",
  )
  inspect(session_result_is_ok(updated), content="true")
  let html = result_unwrap(session_preview_html(session_result_unwrap(updated)))
  inspect(html.contains("view: submitted"), content="true")
}

///|
test "session_result_error_json exposes structured transition errors" {
  let session = session_result_unwrap(create_demo_session(demo_yaml()))
  let rejected = apply_session_transition(session, "submit", "{}")
  inspect(session_result_is_ok(rejected), content="false")
  let error_json = session_result_error_json(rejected)
  inspect(error_json.contains("\"kind\":\"transition-rejected\""), content="true")
  inspect(error_json.contains("\"transition\":\"submit\""), content="true")
  inspect(
    error_json.contains("transition input field amount is required"),
    content="true",
  )
}

///|
test "session_reference_catalog_json exposes demo user options" {
  let session = session_result_unwrap(create_demo_session(demo_yaml()))
  let catalog = result_unwrap(session_reference_catalog_json(session))
  inspect(catalog.contains("\"name\": \"User\""), content="true")
  inspect(catalog.contains("\"value\": \"user-1\""), content="true")
}

///|
fn localized_demo_yaml() -> String {
  (
    #|entities:
    #|  User:
    #|    label:
    #|      default: User
    #|      ja: ユーザー
    #|    fields:
    #|      id:
    #|        type: id
    #|        primary: true
    #|      role:
    #|        type: text
    #|        required: true
    #|  ExpenseRequest:
    #|    label:
    #|      default: Expense Request
    #|      ja: 経費申請
    #|    fields:
    #|      id:
    #|        label:
    #|          default: ID
    #|          ja: ID
    #|        type: id
    #|        primary: true
    #|      amount:
    #|        label:
    #|          default: Amount
    #|          ja: 金額
    #|        type: money
    #|        required: true
    #|      reason:
    #|        label:
    #|          default: Reason
    #|          ja: 理由
    #|        type: text
    #|        required: true
    #|      applicant:
    #|        label:
    #|          default: Applicant
    #|          ja: 申請者
    #|        type: ref
    #|        target: User
    #|        required: true
    #|      status:
    #|        label:
    #|          default: Status
    #|          ja: ステータス
    #|        type: state
    #|        initial: draft
    #|    states:
    #|      draft:
    #|        label:
    #|          default: Draft
    #|          ja: 下書き
    #|      submitted:
    #|        label:
    #|          default: Submitted
    #|          ja: 申請中
    #|    transitions:
    #|      submit:
    #|        from: draft
    #|        to: submitted
    #|        input:
    #|          - amount
    #|          - applicant
    #|    views:
    #|      draft:
    #|        editable:
    #|          - amount
    #|      submitted:
    #|        readonly:
    #|          - amount
  )
}

///|
test "session snapshot json resolves localized labels" {
  let session = session_result_unwrap(create_demo_session(localized_demo_yaml()))
  let snapshot = result_unwrap(session_snapshot_json(session, locale="ja"))
  inspect(snapshot.contains("\"entityLabel\":\"経費申請\""), content="true")
  inspect(snapshot.contains("\"stateLabel\":\"下書き\""), content="true")
  inspect(
    snapshot.contains("\"fields\":[{\"name\":\"amount\",\"label\":\"金額\""),
    content="true",
  )
  inspect(snapshot.contains("\"label\":\"金額\""), content="true")
}

///|
test "session_reference_catalog_json localizes target labels" {
  let session = session_result_unwrap(create_demo_session(localized_demo_yaml()))
  let catalog = result_unwrap(session_reference_catalog_json(session, locale="ja"))
  inspect(catalog.contains("\"label\": \"ユーザー\""), content="true")
}

///|
test "session preview html resolves english labels from default locale map" {
  let session = session_result_unwrap(create_demo_session(localized_demo_yaml()))
  let html = result_unwrap(session_preview_html(session, locale="en"))
  inspect(html.contains("<title>Expense Request - Draft</title>"), content="true")
  inspect(html.contains("Amount"), content="true")
}
