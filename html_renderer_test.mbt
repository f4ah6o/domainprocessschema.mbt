///|
test "render_gui_html_from_manifest renders static html preview" {
  let manifest = compile_gui_manifest_from_yaml(sample_schema())
  let html = render_gui_html_from_manifest(manifest)
  inspect(
    html,
    content=(
      #|<!DOCTYPE html>
      #|<html lang="ja">
      #|<head>
      #|  <meta charset="utf-8">
      #|  <meta name="viewport" content="width=device-width, initial-scale=1">
      #|  <title>Generated GUI Preview</title>
      #|  <style>
      #|    body { font-family: sans-serif; line-height: 1.5; margin: 2rem; }
      #|    .entity-page { border: 1px solid #ddd; border-radius: 12px; padding: 1.5rem; margin-bottom: 2rem; }
      #|    .page-header { display: flex; gap: 1rem; align-items: center; flex-wrap: wrap; }
      #|    .entity-name, .view-name, .action-target { color: #666; margin: 0; }
      #|    .state-badge { display: inline-block; padding: 0.15rem 0.5rem; border-radius: 999px; background: #eef; margin-right: 0.5rem; }
      #|    .state-badge--current { font-weight: 700; background: #ddf; }
      #|    .field-grid, .action-list { display: grid; gap: 1rem; margin-top: 1rem; }
      #|    .field { display: grid; gap: 0.35rem; }
      #|    .field-meta, .required, .rule-state { font-size: 0.85rem; color: #666; }
      #|    .required { color: #b00; }
      #|    .control { padding: 0.5rem; border: 1px solid #ccc; border-radius: 8px; }
      #|    textarea.control { min-height: 6rem; }
      #|    .action-card, .view-card { border-top: 1px solid #eee; padding-top: 1rem; margin-top: 1rem; }
      #|    .action-button { padding: 0.5rem 0.9rem; border-radius: 8px; }
      #|    .issue-list, .rule-list, .state-list, .action-notes { margin: 0.5rem 0 0 1rem; }
      #|    .state-list { list-style: none; padding-left: 0; }
      #|    .state-list-item { list-style: none; }
      #|    .rule--active .rule-state { color: #070; }
      #|    .rule--inactive .rule-state { color: #999; }
      #|  </style>
      #|</head>
      #|<body>
      #|<section class="entity-page">
      #|<header class="page-header"><h1>ユーザー</h1><p class="entity-name">User</p></header>
      #|
      #|
      #|
      #|</section>
      #|<section class="entity-page">
      #|<header class="page-header"><h1>経費申請</h1><p class="entity-name">ExpenseRequest</p></header>
      #|<section class="state-list-section"><h2>States</h2><ul class="state-list">
      #|<li class="state-list-item"><span class="state-badge" data-state="draft">下書き</span></li>
      #|<li class="state-list-item"><span class="state-badge" data-state="submitted">申請中</span></li>
      #|<li class="state-list-item"><span class="state-badge" data-state="approved">承認済</span></li>
      #|<li class="state-list-item"><span class="state-badge" data-state="rejected">却下</span></li>
      #|</ul></section>
      #|<section class="rule-list-section"><h2>Rules</h2><ul class="rule-list">
      #|<li class="rule"><span class="rule-name">canApprove</span><code>state == &quot;submitted&quot; &amp;&amp; user.role == &quot;manager&quot;</code></li>
      #|</ul></section>
      #|<section class="view-card" data-view="draft">
      #|<div class="state-heading"><span class="state-title">下書き</span><span class="state-code">draft</span></div>
      #|<div class="field-grid">
      #|<label class="field field--editable"><span class="field-label">amount</span><input type="number" name="amount" class="control control--money"></label>
      #|<label class="field field--editable"><span class="field-label">reason</span><textarea name="reason" class="control control--textarea"></textarea></label>
      #|<label class="field field--readonly"><span class="field-label">createdAt</span><input type="datetime-local" name="createdAt" class="control control--datetime-picker" readonly></label>
      #|<label class="field field--readonly"><span class="field-label">updatedAt</span><input type="datetime-local" name="updatedAt" class="control control--datetime-picker" readonly></label>
      #|</div>
      #|<div class="action-list">
      #|<section class="action-card"><button type="button" class="action-button">submit</button><p class="action-target">to submitted</p><ul class="action-notes">
      #|<li>when: <code>amount &gt; 0</code></li>
      #|</ul>
      #|<div class="action-inputs">
      #|<label class="field action-input"><span class="field-label">amount</span><span class="field-meta">entity-field <span class="required">required</span></span><input type="number" name="amount" class="control control--money"></label>
      #|<label class="field action-input"><span class="field-label">reason</span><span class="field-meta">entity-field <span class="required">required</span></span><textarea name="reason" class="control control--textarea"></textarea></label>
      #|</div>
      #|</section>
      #|</div>
      #|</section>
      #|<section class="view-card" data-view="submitted">
      #|<div class="state-heading"><span class="state-title">申請中</span><span class="state-code">submitted</span></div>
      #|<div class="field-grid">
      #|<label class="field field--readonly"><span class="field-label">amount</span><input type="number" name="amount" class="control control--money" readonly></label>
      #|<label class="field field--readonly"><span class="field-label">reason</span><textarea name="reason" class="control control--textarea" readonly></textarea></label>
      #|<label class="field field--readonly"><span class="field-label">createdAt</span><input type="datetime-local" name="createdAt" class="control control--datetime-picker" readonly></label>
      #|<label class="field field--readonly"><span class="field-label">updatedAt</span><input type="datetime-local" name="updatedAt" class="control control--datetime-picker" readonly></label>
      #|</div>
      #|<div class="action-list">
      #|<section class="action-card"><button type="button" class="action-button">approve</button><p class="action-target">to approved</p><ul class="action-notes">
      #|<li>role: <code>manager</code></li>
      #|</ul>
      #|
      #|</section>
      #|<section class="action-card"><button type="button" class="action-button">reject</button><p class="action-target">to rejected</p><ul class="action-notes">
      #|<li>role: <code>manager</code></li>
      #|</ul>
      #|<div class="action-inputs">
      #|<label class="field action-input"><span class="field-label">rejectReason</span><span class="field-meta">local <span class="required">required</span></span><textarea name="rejectReason" class="control control--textarea"></textarea></label>
      #|</div>
      #|</section>
      #|</div>
      #|</section>
      #|<section class="view-card" data-view="approved">
      #|<div class="state-heading"><span class="state-title">承認済</span><span class="state-code">approved</span></div>
      #|<div class="field-grid">
      #|<label class="field field--readonly"><span class="field-label">amount</span><input type="number" name="amount" class="control control--money" readonly></label>
      #|<label class="field field--readonly"><span class="field-label">reason</span><textarea name="reason" class="control control--textarea" readonly></textarea></label>
      #|<label class="field field--readonly"><span class="field-label">createdAt</span><input type="datetime-local" name="createdAt" class="control control--datetime-picker" readonly></label>
      #|<label class="field field--readonly"><span class="field-label">updatedAt</span><input type="datetime-local" name="updatedAt" class="control control--datetime-picker" readonly></label>
      #|</div>
      #|
      #|</section>
      #|<section class="view-card" data-view="rejected">
      #|<div class="state-heading"><span class="state-title">却下</span><span class="state-code">rejected</span></div>
      #|<div class="field-grid">
      #|<label class="field field--readonly"><span class="field-label">amount</span><input type="number" name="amount" class="control control--money" readonly></label>
      #|<label class="field field--readonly"><span class="field-label">reason</span><textarea name="reason" class="control control--textarea" readonly></textarea></label>
      #|<label class="field field--readonly"><span class="field-label">createdAt</span><input type="datetime-local" name="createdAt" class="control control--datetime-picker" readonly></label>
      #|<label class="field field--readonly"><span class="field-label">updatedAt</span><input type="datetime-local" name="updatedAt" class="control control--datetime-picker" readonly></label>
      #|</div>
      #|
      #|</section>
      #|</section>
      #|</body>
      #|</html>
    ),
  )
}

///|
test "render_runtime_gui_html renders stateful html preview" {
  let runtime = sample_runtime()
  let draft = validate_record(runtime, "ExpenseRequest", draft_payload()).record
  let submitted = apply_transition(runtime, draft, "submit", input={
    "amount": RuntimeValue::Integer(1200),
    "reason": RuntimeValue::Text("hotel"),
  })
  let html = render_runtime_gui_html(runtime, submitted, actor=manager_actor())
  inspect(
    html,
    content=(
      #|<!DOCTYPE html>
      #|<html lang="ja">
      #|<head>
      #|  <meta charset="utf-8">
      #|  <meta name="viewport" content="width=device-width, initial-scale=1">
      #|  <title>経費申請 - 申請中</title>
      #|  <style>
      #|    body { font-family: sans-serif; line-height: 1.5; margin: 2rem; }
      #|    .entity-page { border: 1px solid #ddd; border-radius: 12px; padding: 1.5rem; margin-bottom: 2rem; }
      #|    .page-header { display: flex; gap: 1rem; align-items: center; flex-wrap: wrap; }
      #|    .entity-name, .view-name, .action-target { color: #666; margin: 0; }
      #|    .state-badge { display: inline-block; padding: 0.15rem 0.5rem; border-radius: 999px; background: #eef; margin-right: 0.5rem; }
      #|    .state-badge--current { font-weight: 700; background: #ddf; }
      #|    .field-grid, .action-list { display: grid; gap: 1rem; margin-top: 1rem; }
      #|    .field { display: grid; gap: 0.35rem; }
      #|    .field-meta, .required, .rule-state { font-size: 0.85rem; color: #666; }
      #|    .required { color: #b00; }
      #|    .control { padding: 0.5rem; border: 1px solid #ccc; border-radius: 8px; }
      #|    textarea.control { min-height: 6rem; }
      #|    .action-card, .view-card { border-top: 1px solid #eee; padding-top: 1rem; margin-top: 1rem; }
      #|    .action-button { padding: 0.5rem 0.9rem; border-radius: 8px; }
      #|    .issue-list, .rule-list, .state-list, .action-notes { margin: 0.5rem 0 0 1rem; }
      #|    .state-list { list-style: none; padding-left: 0; }
      #|    .state-list-item { list-style: none; }
      #|    .rule--active .rule-state { color: #070; }
      #|    .rule--inactive .rule-state { color: #999; }
      #|  </style>
      #|</head>
      #|<body>
      #|<section class="entity-page runtime-page">
      #|<header class="page-header"><h1>経費申請</h1><p class="entity-name">ExpenseRequest</p><span class="state-badge state-badge--current" data-state="submitted">申請中</span></header>
      #|<p class="view-name">view: submitted</p>
      #|<div class="field-grid">
      #|<label class="field field--readonly"><span class="field-label">amount</span><input type="number" name="amount" class="control control--money" value="1200" readonly></label>
      #|<label class="field field--readonly"><span class="field-label">reason</span><textarea name="reason" class="control control--textarea" readonly>hotel</textarea></label>
      #|</div>
      #|<div class="action-list">
      #|<section class="action-card"><button type="button" class="action-button">approve</button><p class="action-target">to approved</p>
      #|
      #|</section>
      #|<section class="action-card"><button type="button" class="action-button">reject</button><p class="action-target">to rejected</p>
      #|<div class="action-inputs">
      #|<label class="field action-input"><span class="field-label">rejectReason</span><span class="field-meta">local <span class="required">required</span></span><textarea name="rejectReason" class="control control--textarea"></textarea></label>
      #|</div>
      #|</section>
      #|</div>
      #|<section class="rule-list-section"><h2>Rules</h2><ul class="rule-list">
      #|<li class="rule rule--active"><span class="rule-name">canApprove</span><span class="rule-state">active</span></li>
      #|</ul></section>
      #|</section>
      #|</body>
      #|</html>
    ),
  )
}

///|
fn runtime_reference_field_schema() -> String {
  (
    #|entities:
    #|  User:
    #|    label: ユーザー
    #|    fields:
    #|      id:
    #|        type: id
    #|        primary: true
    #|  ExpenseRequest:
    #|    label: 経費申請
    #|    fields:
    #|      id:
    #|        type: id
    #|        primary: true
    #|      applicant:
    #|        type: ref
    #|        target: User
    #|        required: true
    #|      status:
    #|        type: state
    #|        initial: submitted
    #|    states:
    #|      submitted:
    #|        label: 申請中
    #|    views:
    #|      submitted:
    #|        readonly:
    #|          - applicant
  )
}

///|
test "render_runtime_gui_html keeps runtime values in reference selects" {
  let runtime = compile_runtime_from_yaml(runtime_reference_field_schema())
  let record = validate_record(runtime, "ExpenseRequest", {
      "id": RuntimeValue::Text("exp-1"),
      "applicant": RuntimeValue::Text("user-1"),
    }).record
  let html = render_runtime_gui_html(runtime, record)
  inspect(
    html.contains("<option value=\"user-1\" selected>user-1</option>"),
    content="true",
  )
}
