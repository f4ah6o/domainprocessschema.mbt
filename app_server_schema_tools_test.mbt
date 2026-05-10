///|
test "app server tool shapes define access boundaries" {
  let shapes = schema_app_server_tool_shapes()
  inspect(shapes.length(), content="15")
  inspect(shapes[0].name, content="schema.session.snapshot")
  inspect(shapes[0].access, content="ReadOnly")
  inspect(shapes[6].name, content="schema.source.replace")
  inspect(shapes[6].access, content="Mutating")
  inspect(shapes[12].name, content="schema.transition.apply")
  inspect(shapes[12].access, content="ApprovalRequired")
  inspect(shapes[13].name, content="schema.session.reset")
  inspect(shapes[13].access, content="ApprovalRequired")
  inspect(shapes[14].name, content="schema.artifact.export")
  inspect(shapes[14].access, content="ReadOnly")
}

///|
test "app server compile read returns structured diagnostics" {
  let store = create_schema_runtime_session("entities:\n  Broken:\n")
  let envelope = schema_tool_compile_current_source(store)
  inspect(envelope.tool, content="schema.compile.currentSource")
  inspect(envelope.access, content="ReadOnly")
  inspect(envelope.snapshot.compile.ok, content="false")
  inspect(envelope.diagnostics.length() > 0, content="true")
  inspect(envelope.diagnostics[0].code, content="SCHEMA_PARSE_ERROR")
  inspect(envelope.diagnostics[0].severity, content="error")
  inspect(envelope.diagnostics[0].target.length() > 0, content="true")
  inspect(
    export_schema_tool_envelope(envelope).contains("\"diagnostics\": ["),
    content="true",
  )
  inspect(
    export_schema_tool_envelope(envelope).contains(
      "\"code\": \"SCHEMA_PARSE_ERROR\"",
    ),
    content="true",
  )
  inspect(
    export_schema_tool_envelope(envelope).contains("\"severity\": \"error\""),
    content="true",
  )
  inspect(
    export_schema_tool_envelope(envelope).contains("\"target\": \"source:"),
    content="true",
  )
  inspect(
    export_schema_tool_envelope(envelope).contains("\"hint\": "),
    content="true",
  )
  inspect(
    export_schema_tool_envelope(envelope).contains("\"context\": {"),
    content="true",
  )
}

///|
test "app server source replace refreshes snapshot" {
  let store = create_schema_runtime_session("entities:\n  Broken:\n")
  let envelope = schema_tool_replace_source(store, runtime_sample_schema())
  inspect(envelope.tool, content="schema.source.replace")
  inspect(envelope.access, content="Mutating")
  inspect(envelope.snapshot.compile.ok, content="true")
  inspect(envelope.snapshot.last_action, content="sourceChanged")
  inspect(envelope.diagnostics.length(), content="0")
}

///|
test "app server selection tool changes selected schema path" {
  let store = create_schema_runtime_session(runtime_sample_schema())
  let envelope = schema_tool_select(store, SchemaSessionSelection::{
    entity_name: Some("ExpenseRequest"),
    state_name: Some("draft"),
    transition_name: Some("submit"),
    field_name: Some("amount"),
  })
  inspect(envelope.tool, content="schema.selection.set")
  inspect(
    envelope.snapshot.selection.entity_name,
    content="Some(\"ExpenseRequest\")",
  )
  inspect(
    envelope.snapshot.selection.transition_name,
    content="Some(\"submit\")",
  )
  inspect(envelope.snapshot.last_action, content="selectionChanged")
}

///|
test "app server actor role change refreshes runtime view" {
  let store = create_schema_runtime_session(runtime_sample_schema(), record=RuntimeRecord::{
    entity_name: "ExpenseRequest",
    values: {
      "id": RuntimeValue::Text("exp-1"),
      "amount": RuntimeValue::Integer(1200),
      "reason": RuntimeValue::Text("hotel"),
      "applicant": RuntimeValue::Text("user-1"),
      "status": RuntimeValue::Text("submitted"),
    },
  })
  let envelope = schema_tool_set_actor_role(store, "manager")
  inspect(envelope.tool, content="schema.actor.role.set")
  inspect(
    envelope.snapshot.actor.attributes.get("role"),
    content="Some(Text(\"manager\"))",
  )
  inspect(
    available_transition_names(envelope.snapshot.runtime.transitions),
    content="[\"approve\", \"reject\"]",
  )
}

///|
test "app server record update and inspector edit return updated snapshots" {
  let store = create_schema_runtime_session(runtime_sample_schema())
  let updated = schema_tool_update_record_payload(
    store,
    "ExpenseRequest",
    draft_payload(),
  )
  inspect(updated.tool, content="schema.record.payload.update")
  inspect(updated.snapshot.record is Some(_), content="true")
  let edited = schema_tool_inspector_edit(updated.snapshot, SchemaToolInspectorEditInput::{
    entity_name: "ExpenseRequest",
    source_path: "entities.ExpenseRequest.fields.amount",
    schema_path: "ExpenseRequest.amount",
    value: RuntimeValue::Integer(2400),
  })
  let amount = match edited.snapshot.record {
    Some(record) => record.values.get("amount")
    None => None
  }
  inspect(edited.tool, content="schema.inspector.edit")
  inspect(amount, content="Some(Integer(2400))")
  inspect(edited.snapshot.runtime.view is Some(_), content="true")
}

///|
test "app server transition apply is approval proposal only" {
  let store = create_schema_runtime_session(runtime_sample_schema(), record=RuntimeRecord::{
    entity_name: "ExpenseRequest",
    values: draft_payload(),
  })
  let envelope = schema_tool_propose_transition_apply(store, SchemaToolTransitionApplyInput::{
    transition_name: "submit",
    input: {
      "amount": RuntimeValue::Integer(1200),
      "reason": RuntimeValue::Text("hotel"),
    },
  })
  inspect(envelope.tool, content="schema.transition.apply")
  inspect(envelope.access, content="ApprovalRequired")
  inspect(envelope.approval is Some(_), content="true")
  let status = match envelope.snapshot.record {
    Some(record) => record.values.get("status")
    None => None
  }
  inspect(status, content="Some(Text(\"draft\"))")
  inspect(
    export_schema_tool_envelope(envelope).contains("\"approval\": {"),
    content="true",
  )
  let exported = export_schema_tool_envelope(envelope)
  inspect(exported.contains("\"detail\": {"), content="true")
  inspect(exported.contains("\"actor\": {"), content="true")
  inspect(exported.contains("\"transition\": {"), content="true")
  inspect(exported.contains("\"currentState\": \"draft\""), content="true")
  inspect(exported.contains("\"targetState\": \"submitted\""), content="true")
  inspect(exported.contains("\"expectedEffects\": {"), content="true")
  inspect(exported.contains("\"recordAfterApproval\": {"), content="true")
}

///|
test "app server reset proposal summarizes lost session state" {
  let store = create_schema_runtime_session(
    runtime_sample_schema(),
    actor=manager_actor(),
    record=RuntimeRecord::{
      entity_name: "ExpenseRequest",
      values: draft_payload(),
    },
    selection=SchemaSessionSelection::{
      entity_name: Some("ExpenseRequest"),
      state_name: Some("draft"),
      transition_name: Some("submit"),
      field_name: Some("amount"),
    },
    locale="ja-JP",
  )
  let envelope = schema_tool_propose_reset_session(store)
  let exported = export_schema_tool_envelope(envelope)
  inspect(envelope.tool, content="schema.session.reset")
  inspect(envelope.access, content="ApprovalRequired")
  inspect(exported.contains("\"lostSource\": {"), content="true")
  inspect(exported.contains("\"lostSelection\": {"), content="true")
  inspect(exported.contains("\"lostActor\": {"), content="true")
  inspect(exported.contains("\"lostRecord\": {"), content="true")
  inspect(exported.contains("\"lostLocale\": \"ja-JP\""), content="true")
  inspect(exported.contains("\"lostRuntime\": {"), content="true")
}
