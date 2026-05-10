///|
fn schema_app_server_tool_shape_catalog() -> Array[SchemaAppServerToolShape] {
  [
    SchemaAppServerToolShape::{
      name: "schema.session.snapshot",
      access: SchemaAppServerToolAccess::ReadOnly,
      input_shape: "{}",
      output_shape: "{ diagnostics, snapshot }",
    },
    SchemaAppServerToolShape::{
      name: "schema.compile.currentSource",
      access: SchemaAppServerToolAccess::ReadOnly,
      input_shape: "{}",
      output_shape: "{ diagnostics, snapshot.compile, snapshot }",
    },
    SchemaAppServerToolShape::{
      name: "schema.runtime.view",
      access: SchemaAppServerToolAccess::ReadOnly,
      input_shape: "{}",
      output_shape: "{ diagnostics, snapshot.runtime.view, snapshot }",
    },
    SchemaAppServerToolShape::{
      name: "schema.runtime.transitions",
      access: SchemaAppServerToolAccess::ReadOnly,
      input_shape: "{}",
      output_shape: "{ diagnostics, snapshot.runtime.transitions, snapshot }",
    },
    SchemaAppServerToolShape::{
      name: "schema.graph",
      access: SchemaAppServerToolAccess::ReadOnly,
      input_shape: "{}",
      output_shape: "{ diagnostics, snapshot.graph, snapshot }",
    },
    SchemaAppServerToolShape::{
      name: "schema.diagnostics",
      access: SchemaAppServerToolAccess::ReadOnly,
      input_shape: "{}",
      output_shape: "{ diagnostics, snapshot }",
    },
    SchemaAppServerToolShape::{
      name: "schema.source.replace",
      access: SchemaAppServerToolAccess::Mutating,
      input_shape: "{ sourceYaml: string }",
      output_shape: "{ diagnostics, snapshot }",
    },
    SchemaAppServerToolShape::{
      name: "schema.inspector.edit",
      access: SchemaAppServerToolAccess::Mutating,
      input_shape: "{ entityName: string, sourcePath: string, schemaPath: string, value }",
      output_shape: "{ diagnostics, snapshot }",
    },
    SchemaAppServerToolShape::{
      name: "schema.selection.set",
      access: SchemaAppServerToolAccess::Mutating,
      input_shape: "{ entity?: string, state?: string, transition?: string, field?: string }",
      output_shape: "{ diagnostics, snapshot }",
    },
    SchemaAppServerToolShape::{
      name: "schema.actor.role.set",
      access: SchemaAppServerToolAccess::Mutating,
      input_shape: "{ role: string }",
      output_shape: "{ diagnostics, snapshot }",
    },
    SchemaAppServerToolShape::{
      name: "schema.record.payload.update",
      access: SchemaAppServerToolAccess::Mutating,
      input_shape: "{ entityName: string, payload }",
      output_shape: "{ diagnostics, snapshot }",
    },
    SchemaAppServerToolShape::{
      name: "schema.locale.set",
      access: SchemaAppServerToolAccess::Mutating,
      input_shape: "{ locale: string }",
      output_shape: "{ diagnostics, snapshot }",
    },
    SchemaAppServerToolShape::{
      name: "schema.transition.apply",
      access: SchemaAppServerToolAccess::ApprovalRequired,
      input_shape: "{ transitionName: string, input }",
      output_shape: "{ diagnostics, snapshot, approval }",
    },
    SchemaAppServerToolShape::{
      name: "schema.session.reset",
      access: SchemaAppServerToolAccess::ApprovalRequired,
      input_shape: "{}",
      output_shape: "{ diagnostics, snapshot, approval }",
    },
  ]
}

///|
fn schema_tool_read_session_snapshot(
  store : SchemaRuntimeSessionStore,
) -> SchemaAppServerToolEnvelope {
  schema_tool_envelope(
    "schema.session.snapshot",
    SchemaAppServerToolAccess::ReadOnly,
    store,
  )
}

///|
fn schema_tool_read_compile_current_source(
  store : SchemaRuntimeSessionStore,
) -> SchemaAppServerToolEnvelope {
  let refreshed = schema_session_set_source(store, store.source.yaml)
  SchemaAppServerToolEnvelope::{
    ..schema_tool_envelope(
      "schema.compile.currentSource",
      SchemaAppServerToolAccess::ReadOnly,
      refreshed,
    ),
    diagnostics: refreshed.compile.diagnostics,
  }
}

///|
fn schema_tool_read_runtime_view(
  store : SchemaRuntimeSessionStore,
) -> SchemaAppServerToolEnvelope {
  SchemaAppServerToolEnvelope::{
    ..schema_tool_envelope(
      "schema.runtime.view",
      SchemaAppServerToolAccess::ReadOnly,
      store,
    ),
    diagnostics: store.runtime.diagnostics,
  }
}

///|
fn schema_tool_read_available_transitions(
  store : SchemaRuntimeSessionStore,
) -> SchemaAppServerToolEnvelope {
  SchemaAppServerToolEnvelope::{
    ..schema_tool_envelope(
      "schema.runtime.transitions",
      SchemaAppServerToolAccess::ReadOnly,
      store,
    ),
    diagnostics: store.runtime.diagnostics,
  }
}

///|
fn schema_tool_read_graph(
  store : SchemaRuntimeSessionStore,
) -> SchemaAppServerToolEnvelope {
  schema_tool_envelope(
    "schema.graph",
    SchemaAppServerToolAccess::ReadOnly,
    store,
  )
}

///|
fn schema_tool_read_diagnostics(
  store : SchemaRuntimeSessionStore,
) -> SchemaAppServerToolEnvelope {
  SchemaAppServerToolEnvelope::{
    ..schema_tool_envelope(
      "schema.diagnostics",
      SchemaAppServerToolAccess::ReadOnly,
      store,
    ),
    diagnostics: schema_tool_collect_diagnostics(store),
  }
}

///|
fn schema_tool_mutate_replace_source(
  store : SchemaRuntimeSessionStore,
  source_yaml : String,
) -> SchemaAppServerToolEnvelope {
  let updated = schema_session_set_source(store, source_yaml)
  SchemaAppServerToolEnvelope::{
    ..schema_tool_envelope(
      "schema.source.replace",
      SchemaAppServerToolAccess::Mutating,
      updated,
    ),
    diagnostics: schema_tool_collect_diagnostics(updated),
  }
}

///|
fn schema_tool_mutate_inspector_edit(
  store : SchemaRuntimeSessionStore,
  input : SchemaToolInspectorEditInput,
) -> SchemaAppServerToolEnvelope {
  let values = match store.record {
    Some(record) =>
      if record.entity_name == input.entity_name {
        copy_runtime_values(record.values)
      } else {
        {}
      }
    None => {}
  }
  values[schema_tool_field_name_from_path(input.schema_path)] = input.value
  let updated = schema_session_edit_record(store, input.entity_name, values)
  SchemaAppServerToolEnvelope::{
    ..schema_tool_envelope(
      "schema.inspector.edit",
      SchemaAppServerToolAccess::Mutating,
      updated,
    ),
    diagnostics: schema_tool_collect_diagnostics(updated),
  }
}

///|
fn schema_tool_mutate_select(
  store : SchemaRuntimeSessionStore,
  selection : SchemaSessionSelection,
) -> SchemaAppServerToolEnvelope {
  let updated = schema_session_set_selection(store, selection)
  schema_tool_envelope(
    "schema.selection.set",
    SchemaAppServerToolAccess::Mutating,
    updated,
  )
}

///|
fn schema_tool_mutate_set_actor_role(
  store : SchemaRuntimeSessionStore,
  role : String,
) -> SchemaAppServerToolEnvelope {
  let attributes = copy_runtime_values(store.actor.attributes)
  attributes["role"] = RuntimeValue::Text(role)
  let updated = schema_session_set_actor(store, RuntimeActor::{ attributes, })
  SchemaAppServerToolEnvelope::{
    ..schema_tool_envelope(
      "schema.actor.role.set",
      SchemaAppServerToolAccess::Mutating,
      updated,
    ),
    diagnostics: schema_tool_collect_diagnostics(updated),
  }
}

///|
fn schema_tool_mutate_update_record_payload(
  store : SchemaRuntimeSessionStore,
  entity_name : String,
  payload : Map[String, RuntimeValue],
) -> SchemaAppServerToolEnvelope {
  let updated = schema_session_edit_record(store, entity_name, payload)
  SchemaAppServerToolEnvelope::{
    ..schema_tool_envelope(
      "schema.record.payload.update",
      SchemaAppServerToolAccess::Mutating,
      updated,
    ),
    diagnostics: schema_tool_collect_diagnostics(updated),
  }
}

///|
fn schema_tool_mutate_set_locale(
  store : SchemaRuntimeSessionStore,
  locale : String,
) -> SchemaAppServerToolEnvelope {
  let updated = schema_session_set_locale(store, locale)
  schema_tool_envelope(
    "schema.locale.set",
    SchemaAppServerToolAccess::Mutating,
    updated,
  )
}

///|
fn schema_tool_approval_transition_apply(
  store : SchemaRuntimeSessionStore,
  input : SchemaToolTransitionApplyInput,
) -> SchemaAppServerToolEnvelope {
  let input_json = render_schema_tool_transition_apply_input_json(input)
  SchemaAppServerToolEnvelope::{
    ..schema_tool_envelope(
      "schema.transition.apply",
      SchemaAppServerToolAccess::ApprovalRequired,
      store,
    ),
    diagnostics: schema_tool_collect_diagnostics(store),
    approval: Some(SchemaAppServerToolApprovalProposal::{
      id: "schema.transition.apply:\{input.transition_name}",
      tool: "schema.transition.apply",
      title: "Apply transition \{input.transition_name}",
      summary: "Apply transition \{input.transition_name} to the current runtime record.",
      input_json,
    }),
  }
}

///|
fn schema_tool_approval_reset_session(
  store : SchemaRuntimeSessionStore,
) -> SchemaAppServerToolEnvelope {
  SchemaAppServerToolEnvelope::{
    ..schema_tool_envelope(
      "schema.session.reset",
      SchemaAppServerToolAccess::ApprovalRequired,
      store,
    ),
    diagnostics: schema_tool_collect_diagnostics(store),
    approval: Some(SchemaAppServerToolApprovalProposal::{
      id: "schema.session.reset",
      tool: "schema.session.reset",
      title: "Reset schema session",
      summary: "Reset source, selection, actor, record, locale, and runtime snapshots after approval.",
      input_json: "{}",
    }),
  }
}

///|
fn schema_tool_envelope(
  tool : String,
  access : SchemaAppServerToolAccess,
  store : SchemaRuntimeSessionStore,
) -> SchemaAppServerToolEnvelope {
  SchemaAppServerToolEnvelope::{
    tool,
    access,
    diagnostics: [],
    snapshot: store,
    approval: None,
  }
}

///|
fn schema_tool_collect_diagnostics(
  store : SchemaRuntimeSessionStore,
) -> Array[SchemaSessionDiagnostic] {
  let diagnostics : Array[SchemaSessionDiagnostic] = []
  for diagnostic in store.compile.diagnostics {
    diagnostics.push(diagnostic)
  }
  for diagnostic in store.runtime.diagnostics {
    diagnostics.push(diagnostic)
  }
  diagnostics
}

///|
fn schema_tool_field_name_from_path(path : String) -> String {
  let parts = path.split(".").to_array()
  if parts.length() == 0 {
    path
  } else {
    parts[parts.length() - 1].to_owned()
  }
}

///|
fn render_schema_tool_envelope_json(
  envelope : SchemaAppServerToolEnvelope,
) -> String {
  let approval = match envelope.approval {
    Some(proposal) => render_schema_tool_approval_proposal_json(proposal)
    None => "null"
  }
  let body_lines = [
    "\"version\": 1",
    "\"tool\": \{json_quote(envelope.tool)}",
    "\"access\": \{json_quote(schema_tool_access_name(envelope.access))}",
    "\"diagnostics\": \{render_session_diagnostics_json(envelope.diagnostics)}",
    "\"snapshot\": \{export_schema_runtime_session(envelope.snapshot)}",
    "\"approval\": \{approval}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_schema_tool_approval_proposal_json(
  proposal : SchemaAppServerToolApprovalProposal,
) -> String {
  let body_lines = [
    "\"id\": \{json_quote(proposal.id)}",
    "\"tool\": \{json_quote(proposal.tool)}",
    "\"title\": \{json_quote(proposal.title)}",
    "\"summary\": \{json_quote(proposal.summary)}",
    "\"input\": \{proposal.input_json}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_schema_tool_transition_apply_input_json(
  input : SchemaToolTransitionApplyInput,
) -> String {
  let body_lines = [
    "\"transitionName\": \{json_quote(input.transition_name)}",
    "\"input\": \{render_runtime_value_map_json(input.input)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn schema_tool_access_name(access : SchemaAppServerToolAccess) -> String {
  match access {
    SchemaAppServerToolAccess::ReadOnly => "read-only"
    SchemaAppServerToolAccess::Mutating => "mutating"
    SchemaAppServerToolAccess::ApprovalRequired => "approval-required"
  }
}
