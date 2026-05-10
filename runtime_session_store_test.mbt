///|
test "schema runtime session store keeps required top-level sections" {
  let store = create_schema_runtime_session(
    runtime_sample_schema(),
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
  inspect(store.compile.ok, content="true")
  inspect(store.locale, content="ja-JP")
  inspect(store.selection.entity_name, content="Some(\"ExpenseRequest\")")
  inspect(store.record is Some(_), content="true")
  inspect(store.runtime.view is Some(_), content="true")
  inspect(store.graph.nodes.length() > 0, content="true")
  inspect(store.graph.edges.length() > 0, content="true")
  inspect(store.last_action, content="created")
}

///|
test "schema runtime session source refresh preserves resume fields" {
  let initial = create_schema_runtime_session(
    runtime_sample_schema(),
    actor=manager_actor(),
    record=RuntimeRecord::{
      entity_name: "ExpenseRequest",
      values: draft_payload(),
    },
    selection=SchemaSessionSelection::{
      entity_name: Some("ExpenseRequest"),
      state_name: Some("draft"),
      transition_name: None,
      field_name: Some("reason"),
    },
    locale="ja-JP",
  )
  let refreshed = schema_session_set_source(initial, runtime_sample_schema())
  inspect(refreshed.compile.ok, content="true")
  inspect(refreshed.record is Some(_), content="true")
  inspect(
    refreshed.actor.attributes.get("role"),
    content="Some(Text(\"manager\"))",
  )
  inspect(refreshed.selection.field_name, content="Some(\"reason\")")
  inspect(refreshed.locale, content="ja-JP")
  inspect(refreshed.last_action, content="sourceChanged")
}

///|
test "schema runtime session inspector edit and transition update snapshots" {
  let store = create_schema_runtime_session(runtime_sample_schema())
  let edited = schema_session_edit_record(
    store,
    "ExpenseRequest",
    draft_payload(),
  )
  inspect(edited.record is Some(_), content="true")
  inspect(edited.runtime.view is Some(_), content="true")
  let submitted = schema_session_apply_transition(edited, "submit", input={
    "amount": RuntimeValue::Integer(1200),
    "reason": RuntimeValue::Text("hotel"),
  })
  let status = match submitted.record {
    Some(record) => record.values.get("status")
    None => None
  }
  inspect(status, content="Some(Text(\"submitted\"))")
  inspect(submitted.last_action, content="transition:submit")
}

///|
test "schema runtime session export is a stable json envelope" {
  let store = create_schema_runtime_session(
    runtime_sample_schema(),
    actor=RuntimeActor::{
      attributes: {
        "zeta": RuntimeValue::Text("last"),
        "alpha": RuntimeValue::Text("first"),
      },
    },
    record=RuntimeRecord::{
      entity_name: "ExpenseRequest",
      values: draft_payload(),
    },
    locale="ja-JP",
  )
  let exported = export_schema_runtime_session(store)
  inspect(exported.contains("\"version\": 1"), content="true")
  inspect(exported.contains("\"source\": {"), content="true")
  inspect(exported.contains("\"selection\": {"), content="true")
  inspect(exported.contains("\"actor\": {"), content="true")
  inspect(exported.contains("\"record\": {"), content="true")
  inspect(exported.contains("\"compile\": {"), content="true")
  inspect(exported.contains("\"runtime\": {"), content="true")
  inspect(exported.contains("\"graph\": {"), content="true")
  inspect(exported.contains("\"locale\": \"ja-JP\""), content="true")
  inspect(exported.contains("\"lastAction\": \"created\""), content="true")
  inspect(exported.contains("\"alpha\": \"first\""), content="true")
  inspect(exported.contains("\"zeta\": \"last\""), content="true")
}

///|
test "schema runtime session artifacts export stable envelopes" {
  let store = create_schema_runtime_session(
    runtime_sample_schema(),
    record=RuntimeRecord::{
      entity_name: "ExpenseRequest",
      values: draft_payload(),
    },
    locale="ja-JP",
  )
  let source = export_schema_session_artifact(
    store,
    SchemaSessionArtifactFormat::SourceYaml,
  )
  inspect(source.version, content="1")
  inspect(source.format, content="SourceYaml")
  inspect(source.media_type, content="application/x-yaml")
  inspect(source.payload.contains("ExpenseRequest:"), content="true")
  inspect(
    render_schema_session_artifact(source).contains(
      "\"format\": \"source-yaml\"",
    ),
    content="true",
  )
  inspect(
    render_schema_session_artifact(source).contains(
      "\"payload\": \"entities:\\n  User:",
    ),
    content="true",
  )

  let normalized = export_schema_session_artifact(
    store,
    SchemaSessionArtifactFormat::NormalizedSchema,
  )
  inspect(normalized.media_type, content="application/json")
  inspect(normalized.payload.contains("\"entities\": ["), content="true")
  inspect(normalized.payload.contains("\"transitions\": ["), content="true")

  let runtime = export_schema_session_artifact(
    store,
    SchemaSessionArtifactFormat::RuntimeSession,
  )
  inspect(runtime.payload.contains("\"runtime\": {"), content="true")
  inspect(runtime.payload.contains("\"locale\": \"ja-JP\""), content="true")

  let diagnostics = export_schema_session_artifact(
    store,
    SchemaSessionArtifactFormat::DiagnosticReport,
  )
  inspect(diagnostics.payload.contains("\"compile\": ["), content="true")
  inspect(diagnostics.payload.contains("\"runtime\": ["), content="true")
  inspect(diagnostics.payload.contains("\"all\": ["), content="true")
}
