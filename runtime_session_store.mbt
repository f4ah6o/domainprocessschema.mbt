///|
fn schema_session_compile_runtime(source_yaml : String) -> Runtime? {
  let compiled = try? compile_runtime_from_yaml(source_yaml)
  match compiled {
    Ok(runtime) => Some(runtime)
    Err(_) => None
  }
}

///|
fn schema_session_refresh(
  source : SchemaSessionSource,
  selection : SchemaSessionSelection,
  actor : RuntimeActor,
  record : RuntimeRecord?,
  locale : String,
  last_action : String,
) -> SchemaRuntimeSessionStore {
  let compiled = try? compile_runtime_from_yaml(source.yaml)
  match compiled {
    Ok(runtime) => {
      let compatible_record = schema_session_compatible_record(runtime, record)
      let runtime_snapshot = schema_session_runtime_snapshot(
        runtime, compatible_record, actor,
      )
      SchemaRuntimeSessionStore::{
        source,
        selection,
        actor,
        record: compatible_record,
        compile: SchemaSessionCompileSnapshot::{
          ok: true,
          diagnostics: [],
          api_manifest: Some(generate_api_manifest(runtime.schema)),
          validation_manifest: Some(
            generate_validation_manifest(runtime.schema),
          ),
          gui_manifest: Some(generate_gui_manifest(runtime.schema)),
        },
        runtime: runtime_snapshot,
        graph: schema_session_graph_snapshot(runtime.schema),
        locale,
        last_action,
      }
    }
    Err(err) =>
      SchemaRuntimeSessionStore::{
        source,
        selection,
        actor,
        record: None,
        compile: SchemaSessionCompileSnapshot::{
          ok: false,
          diagnostics: [schema_session_error_diagnostic(err)],
          api_manifest: None,
          validation_manifest: None,
          gui_manifest: None,
        },
        runtime: SchemaSessionRuntimeSnapshot::{
          transitions: [],
          rules: [],
          view: None,
          diagnostics: [],
        },
        graph: SchemaSessionGraphSnapshot::{ nodes: [], edges: [] },
        locale,
        last_action,
      }
  }
}

///|
fn schema_session_compatible_record(
  runtime : Runtime,
  record : RuntimeRecord?,
) -> RuntimeRecord? {
  match record {
    Some(record) => {
      let validated = try? validate_record(
        runtime,
        record.entity_name,
        {},
        current=record,
      )
      match validated {
        Ok(validation) =>
          if validation.is_ok() {
            Some(validation.record)
          } else {
            None
          }
        Err(_) => None
      }
    }
    None => None
  }
}

///|
fn schema_session_runtime_snapshot(
  runtime : Runtime,
  record : RuntimeRecord?,
  actor : RuntimeActor,
) -> SchemaSessionRuntimeSnapshot {
  match record {
    Some(record) => {
      let transition_result = try? list_transitions(runtime, record, actor~)
      let rule_result = try? evaluate_rules(runtime, record, actor~)
      let view_result = try? project_gui(runtime, record, actor~)
      let diagnostics : Array[SchemaSessionDiagnostic] = []
      let transitions = match transition_result {
        Ok(transitions) => transitions
        Err(err) => {
          diagnostics.push(schema_session_runtime_error_diagnostic(err))
          []
        }
      }
      let rules = match rule_result {
        Ok(rules) => rules
        Err(err) => {
          diagnostics.push(schema_session_runtime_error_diagnostic(err))
          []
        }
      }
      let view = match view_result {
        Ok(view) => Some(view)
        Err(err) => {
          diagnostics.push(schema_session_runtime_error_diagnostic(err))
          None
        }
      }
      SchemaSessionRuntimeSnapshot::{ transitions, rules, view, diagnostics }
    }
    None =>
      SchemaSessionRuntimeSnapshot::{
        transitions: [],
        rules: [],
        view: None,
        diagnostics: [],
      }
  }
}

///|
fn schema_session_graph_snapshot(schema : Schema) -> SchemaSessionGraphSnapshot {
  let nodes : Array[SchemaSessionGraphNode] = []
  let edges : Array[SchemaSessionGraphEdge] = []
  for entity in schema.entities {
    nodes.push(SchemaSessionGraphNode::{
      id: "entity:\{entity.name}",
      label: entity.label,
      kind: "entity",
    })
    for state in entity.states {
      nodes.push(SchemaSessionGraphNode::{
        id: "state:\{entity.name}:\{state.name}",
        label: state.label,
        kind: "state",
      })
    }
    for relation in entity.relations {
      edges.push(SchemaSessionGraphEdge::{
        from: "entity:\{entity.name}",
        to: "entity:\{relation.target}",
        label: relation.name,
        kind: "relation",
      })
    }
    for field in entity.fields {
      match field.target {
        Some(target) =>
          edges.push(SchemaSessionGraphEdge::{
            from: "entity:\{entity.name}",
            to: "entity:\{target}",
            label: field.name,
            kind: "reference",
          })
        None => ()
      }
    }
    for transition in entity.transitions {
      edges.push(SchemaSessionGraphEdge::{
        from: "state:\{entity.name}:\{transition.from}",
        to: "state:\{entity.name}:\{transition.to}",
        label: transition.name,
        kind: "transition",
      })
    }
  }
  SchemaSessionGraphSnapshot::{ nodes, edges }
}

///|
fn schema_session_error_diagnostic(
  err : SchemaError,
) -> SchemaSessionDiagnostic {
  match err {
    SchemaError::ParseError(line~, message) =>
      SchemaSessionDiagnostic::{ path: "source:\{line}", message }
    SchemaError::ValidationError(path~, message) =>
      SchemaSessionDiagnostic::{ path, message }
  }
}

///|
fn schema_session_runtime_error_diagnostic(
  err : RuntimeError,
) -> SchemaSessionDiagnostic {
  SchemaSessionDiagnostic::{ path: "runtime", message: err.to_string() }
}

///|
fn render_schema_runtime_session_json(
  store : SchemaRuntimeSessionStore,
) -> String {
  let body_lines = [
    "\"version\": 1",
    "\"source\": \{render_schema_session_source_json(store.source)}",
    "\"selection\": \{render_schema_session_selection_json(store.selection)}",
    "\"actor\": \{render_runtime_actor_json(store.actor)}",
    "\"record\": \{render_optional_runtime_record_json(store.record)}",
    "\"compile\": \{render_schema_session_compile_json(store.compile)}",
    "\"runtime\": \{render_schema_session_runtime_json(store.runtime)}",
    "\"graph\": \{render_schema_session_graph_json(store.graph)}",
    "\"locale\": \{json_quote(store.locale)}",
    "\"lastAction\": \{json_quote(store.last_action)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn schema_session_export_artifact(
  store : SchemaRuntimeSessionStore,
  format : SchemaSessionArtifactFormat,
) -> SchemaSessionArtifactEnvelope {
  match format {
    SchemaSessionArtifactFormat::SourceYaml =>
      SchemaSessionArtifactEnvelope::{
        version: 1,
        format,
        media_type: "application/x-yaml",
        payload: store.source.yaml,
      }
    SchemaSessionArtifactFormat::NormalizedSchema =>
      SchemaSessionArtifactEnvelope::{
        version: 1,
        format,
        media_type: "application/json",
        payload: render_normalized_schema_artifact_payload(store),
      }
    SchemaSessionArtifactFormat::RuntimeSession =>
      SchemaSessionArtifactEnvelope::{
        version: 1,
        format,
        media_type: "application/json",
        payload: render_schema_runtime_session_json(store),
      }
    SchemaSessionArtifactFormat::DiagnosticReport =>
      SchemaSessionArtifactEnvelope::{
        version: 1,
        format,
        media_type: "application/json",
        payload: render_diagnostic_report_payload(store),
      }
  }
}

///|
fn render_schema_session_artifact_envelope_json(
  artifact : SchemaSessionArtifactEnvelope,
) -> String {
  let body_lines = [
    "\"version\": \{artifact.version}",
    "\"format\": \{json_quote(schema_session_artifact_format_name(artifact.format))}",
    "\"mediaType\": \{json_quote(artifact.media_type)}",
    "\"payload\": \{json_quote(artifact.payload)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn schema_session_artifact_format_name(
  format : SchemaSessionArtifactFormat,
) -> String {
  match format {
    SchemaSessionArtifactFormat::SourceYaml => "source-yaml"
    SchemaSessionArtifactFormat::NormalizedSchema => "normalized-schema"
    SchemaSessionArtifactFormat::RuntimeSession => "runtime-session"
    SchemaSessionArtifactFormat::DiagnosticReport => "diagnostic-report"
  }
}

///|
fn render_normalized_schema_artifact_payload(
  store : SchemaRuntimeSessionStore,
) -> String {
  let compiled = try? compile_runtime_from_yaml(store.source.yaml)
  match compiled {
    Ok(runtime) => render_normalized_schema_json(runtime.schema)
    Err(_) => "null"
  }
}

///|
fn render_diagnostic_report_payload(
  store : SchemaRuntimeSessionStore,
) -> String {
  let body_lines = [
    "\"ok\": \{json_bool(store.compile.ok && store.runtime.diagnostics.length() == 0)}",
    "\"compile\": \{render_session_diagnostics_json(store.compile.diagnostics)}",
    "\"runtime\": \{render_session_diagnostics_json(store.runtime.diagnostics)}",
    "\"all\": \{render_session_diagnostics_json(schema_tool_collect_diagnostics(store))}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_normalized_schema_json(schema : Schema) -> String {
  let rendered_entities : Array[String] = []
  for entity in schema.entities {
    rendered_entities.push(render_normalized_entity_json(entity))
  }
  let body = indent_block(
    render_named_object_array("entities", rendered_entities),
    2,
  )
  "{\n\{body}\n}"
}

///|
fn render_normalized_entity_json(entity : Entity) -> String {
  let rendered_fields : Array[String] = []
  let rendered_states : Array[String] = []
  let rendered_transitions : Array[String] = []
  for field in entity.fields {
    rendered_fields.push(render_normalized_field_json(field))
  }
  for state in entity.states {
    rendered_states.push(render_normalized_state_json(state))
  }
  for transition in entity.transitions {
    rendered_transitions.push(render_normalized_transition_json(transition))
  }
  let body_lines = [
    "\"name\": \{json_quote(entity.name)}",
    "\"label\": \{json_quote(entity.label)}",
    "\"table\": \{json_quote(entity.table_name)}",
    render_named_object_array("fields", rendered_fields),
    render_named_object_array("states", rendered_states),
    render_named_object_array("transitions", rendered_transitions),
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_normalized_field_json(field : Field) -> String {
  let body_lines = [
    "\"name\": \{json_quote(field.name)}",
    "\"column\": \{json_quote(field.column_name)}",
    "\"type\": \{json_quote(field_type_name(field.field_type))}",
    "\"required\": \{json_bool(field.required)}",
    "\"primary\": \{json_bool(field.primary)}",
    "\"readOnly\": \{json_bool(field.read_only)}",
    "\"system\": \{json_bool(field.system)}",
    "\"target\": \{json_optional_string(field.target)}",
    "\"initial\": \{json_optional_string(field.initial)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_normalized_state_json(state : State) -> String {
  let body_lines = [
    "\"name\": \{json_quote(state.name)}",
    "\"label\": \{json_quote(state.label)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_normalized_transition_json(transition : Transition) -> String {
  let body_lines = [
    "\"name\": \{json_quote(transition.name)}",
    "\"from\": \{json_quote(transition.from)}",
    "\"to\": \{json_quote(transition.to)}",
    "\"role\": \{json_optional_string(transition.role)}",
    "\"inputs\": \{render_transition_inputs_json(transition.inputs)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn schema_session_current_state(store : SchemaRuntimeSessionStore) -> String {
  match store.record {
    Some(record) =>
      match schema_session_record_state(record) {
        Some(state) => state
        None => ""
      }
    None => ""
  }
}

///|
fn schema_session_target_state(
  store : SchemaRuntimeSessionStore,
  transition_name : String,
) -> String {
  for transition in store.runtime.transitions {
    if transition.name == transition_name {
      return transition.to
    }
  }
  ""
}

///|
fn schema_session_record_state(record : RuntimeRecord) -> String? {
  match record.values.get("status") {
    Some(RuntimeValue::Text(state)) => Some(state)
    _ =>
      match record.values.get("state") {
        Some(RuntimeValue::Text(state)) => Some(state)
        _ => None
      }
  }
}

///|
fn render_record_summary_json(record : RuntimeRecord?) -> String {
  match record {
    Some(record) => {
      let field_count = record.values.length()
      let body_lines = [
        "\"entity\": \{json_quote(record.entity_name)}",
        "\"state\": \{json_optional_string(schema_session_record_state(record))}",
        "\"fieldCount\": \{field_count}",
        "\"values\": \{render_runtime_value_map_json(record.values)}",
      ]
      let body = indent_block(body_lines.join(",\n"), 2)
      "{\n\{body}\n}"
    }
    None => "null"
  }
}

///|
fn render_source_summary_json(source : SchemaSessionSource) -> String {
  let line_count = source.yaml.split("\n").to_array().length()
  let body_lines = [
    "\"bytes\": \{source.yaml.length()}",
    "\"lineCount\": \{line_count}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_runtime_summary_json(store : SchemaRuntimeSessionStore) -> String {
  let body_lines = [
    "\"transitionCount\": \{store.runtime.transitions.length()}",
    "\"ruleCount\": \{store.runtime.rules.length()}",
    "\"hasView\": \{json_bool(store.runtime.view is Some(_))}",
    "\"diagnosticCount\": \{store.runtime.diagnostics.length()}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_schema_session_source_json(source : SchemaSessionSource) -> String {
  let line = "\"yaml\": \{json_quote(source.yaml)}"
  let body = indent_block(line, 2)
  "{\n\{body}\n}"
}

///|
fn render_schema_session_selection_json(
  selection : SchemaSessionSelection,
) -> String {
  let body_lines = [
    "\"entity\": \{json_optional_string(selection.entity_name)}",
    "\"state\": \{json_optional_string(selection.state_name)}",
    "\"transition\": \{json_optional_string(selection.transition_name)}",
    "\"field\": \{json_optional_string(selection.field_name)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_schema_session_compile_json(
  compile : SchemaSessionCompileSnapshot,
) -> String {
  let body_lines = [
    "\"ok\": \{json_bool(compile.ok)}",
    "\"diagnostics\": \{render_session_diagnostics_json(compile.diagnostics)}",
    "\"apiManifest\": \{json_optional_string(compile.api_manifest)}",
    "\"validationManifest\": \{json_optional_string(compile.validation_manifest)}",
    "\"guiManifest\": \{json_optional_string(compile.gui_manifest)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_schema_session_runtime_json(
  runtime : SchemaSessionRuntimeSnapshot,
) -> String {
  let body_lines = [
    "\"transitions\": \{render_runtime_transition_statuses_json(runtime.transitions)}",
    "\"rules\": \{render_runtime_rule_statuses_json(runtime.rules)}",
    "\"view\": \{render_optional_runtime_gui_view_json(runtime.view)}",
    "\"diagnostics\": \{render_session_diagnostics_json(runtime.diagnostics)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_schema_session_graph_json(
  graph : SchemaSessionGraphSnapshot,
) -> String {
  let rendered_nodes : Array[String] = []
  let rendered_edges : Array[String] = []
  for node in graph.nodes {
    rendered_nodes.push(render_schema_session_graph_node_json(node))
  }
  for edge in graph.edges {
    rendered_edges.push(render_schema_session_graph_edge_json(edge))
  }
  let body_lines = [
    render_named_object_array("nodes", rendered_nodes),
    render_named_object_array("edges", rendered_edges),
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_schema_session_graph_node_json(
  node : SchemaSessionGraphNode,
) -> String {
  let body_lines = [
    "\"id\": \{json_quote(node.id)}",
    "\"label\": \{json_quote(node.label)}",
    "\"kind\": \{json_quote(node.kind)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_schema_session_graph_edge_json(
  edge : SchemaSessionGraphEdge,
) -> String {
  let body_lines = [
    "\"from\": \{json_quote(edge.from)}",
    "\"to\": \{json_quote(edge.to)}",
    "\"label\": \{json_quote(edge.label)}",
    "\"kind\": \{json_quote(edge.kind)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_session_diagnostics_json(
  diagnostics : Array[SchemaSessionDiagnostic],
) -> String {
  let rendered : Array[String] = []
  for diagnostic in diagnostics {
    rendered.push(render_session_diagnostic_json(diagnostic))
  }
  render_json_array(rendered)
}

///|
fn render_session_diagnostic_json(
  diagnostic : SchemaSessionDiagnostic,
) -> String {
  let body_lines = [
    "\"path\": \{json_quote(diagnostic.path)}",
    "\"message\": \{json_quote(diagnostic.message)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_runtime_actor_json(actor : RuntimeActor) -> String {
  render_runtime_value_map_json(actor.attributes)
}

///|
fn render_optional_runtime_record_json(record : RuntimeRecord?) -> String {
  match record {
    Some(record) => render_runtime_record_json(record)
    None => "null"
  }
}

///|
fn render_runtime_record_json(record : RuntimeRecord) -> String {
  let body_lines = [
    "\"entity\": \{json_quote(record.entity_name)}",
    "\"values\": \{render_runtime_value_map_json(record.values)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_runtime_value_map_json(values : Map[String, RuntimeValue]) -> String {
  let keys : Array[String] = []
  for key, _ in values {
    keys.push(key)
  }
  keys.sort()
  let rendered : Array[String] = []
  for key in keys {
    match values.get(key) {
      Some(value) =>
        rendered.push(
          "\"\{json_escape(key)}\": \{render_runtime_value_json(value)}",
        )
      None => ()
    }
  }
  let body = indent_block(rendered.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_runtime_value_json(value : RuntimeValue) -> String {
  match value {
    RuntimeValue::Null => "null"
    RuntimeValue::Text(text) => json_quote(text)
    RuntimeValue::Integer(value) => value.to_string()
    RuntimeValue::Flag(value) => json_bool(value)
  }
}

///|
fn render_runtime_transition_statuses_json(
  statuses : Array[RuntimeTransitionStatus],
) -> String {
  let rendered : Array[String] = []
  for status in statuses {
    rendered.push(render_runtime_transition_status_json(status))
  }
  render_json_array(rendered)
}

///|
fn render_runtime_transition_status_json(
  status : RuntimeTransitionStatus,
) -> String {
  let body_lines = [
    "\"name\": \{json_quote(status.name)}",
    "\"from\": \{json_quote(status.from)}",
    "\"to\": \{json_quote(status.to)}",
    "\"role\": \{json_optional_string(status.role)}",
    "\"inputs\": \{render_transition_inputs_json(status.inputs)}",
    "\"available\": \{json_bool(status.is_available())}",
    "\"issues\": \{render_runtime_issues_json(status.issues)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_runtime_rule_statuses_json(
  statuses : Array[RuntimeRuleStatus],
) -> String {
  let rendered : Array[String] = []
  for status in statuses {
    rendered.push(render_runtime_rule_status_json(status))
  }
  render_json_array(rendered)
}

///|
fn render_runtime_rule_status_json(status : RuntimeRuleStatus) -> String {
  let body_lines = [
    "\"name\": \{json_quote(status.name)}",
    "\"active\": \{json_bool(status.active)}",
    "\"issues\": \{render_runtime_issues_json(status.issues)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_optional_runtime_gui_view_json(view : RuntimeGuiView?) -> String {
  match view {
    Some(view) => render_runtime_gui_view_json(view)
    None => "null"
  }
}

///|
fn render_runtime_gui_view_json(view : RuntimeGuiView) -> String {
  let body_lines = [
    "\"entity\": \{json_quote(view.entity_name)}",
    "\"state\": \{json_quote(view.state)}",
    "\"view\": \{json_quote(view.view_name)}",
    "\"fields\": \{render_runtime_gui_fields_json(view.fields)}",
    "\"actions\": \{render_runtime_gui_actions_json(view.actions)}",
    "\"rules\": \{render_runtime_rule_statuses_json(view.rules)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_runtime_gui_fields_json(fields : Array[RuntimeGuiField]) -> String {
  let rendered : Array[String] = []
  for field in fields {
    rendered.push(render_runtime_gui_field_json(field))
  }
  render_json_array(rendered)
}

///|
fn render_runtime_gui_field_json(field : RuntimeGuiField) -> String {
  let body_lines = [
    "\"name\": \{json_quote(field.name)}",
    "\"component\": \{json_quote(field.component)}",
    "\"mode\": \{json_quote(field.mode)}",
    "\"value\": \{render_optional_runtime_value_json(field.value)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_runtime_gui_actions_json(actions : Array[RuntimeGuiAction]) -> String {
  let rendered : Array[String] = []
  for action in actions {
    rendered.push(render_runtime_gui_action_json(action))
  }
  render_json_array(rendered)
}

///|
fn render_runtime_gui_action_json(action : RuntimeGuiAction) -> String {
  let body_lines = [
    "\"name\": \{json_quote(action.name)}",
    "\"to\": \{json_quote(action.to)}",
    "\"available\": \{json_bool(action.available)}",
    "\"issues\": \{render_runtime_issues_json(action.issues)}",
    "\"inputs\": \{render_runtime_gui_action_inputs_json(action.inputs)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_runtime_gui_action_inputs_json(
  inputs : Array[RuntimeGuiActionInput],
) -> String {
  let rendered : Array[String] = []
  for input in inputs {
    rendered.push(render_runtime_gui_action_input_json(input))
  }
  render_json_array(rendered)
}

///|
fn render_runtime_gui_action_input_json(
  input : RuntimeGuiActionInput,
) -> String {
  let body_lines = [
    "\"name\": \{json_quote(input.name)}",
    "\"kind\": \{json_quote(transition_input_kind_name(input.kind))}",
    "\"component\": \{json_quote(input.component)}",
    "\"required\": \{json_bool(input.required)}",
    "\"value\": \{render_optional_runtime_value_json(input.value)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}

///|
fn render_optional_runtime_value_json(value : RuntimeValue?) -> String {
  match value {
    Some(value) => render_runtime_value_json(value)
    None => "null"
  }
}

///|
fn render_runtime_issues_json(issues : Array[RuntimeIssue]) -> String {
  let rendered : Array[String] = []
  for issue in issues {
    rendered.push(render_runtime_issue_json(issue))
  }
  render_json_array(rendered)
}

///|
fn render_json_array(rendered : Array[String]) -> String {
  let body = rendered.join(", ")
  "[\{body}]"
}

///|
fn render_runtime_issue_json(issue : RuntimeIssue) -> String {
  let body_lines = [
    "\"path\": \{json_quote(issue.path)}",
    "\"message\": \{json_quote(issue.message)}",
  ]
  let body = indent_block(body_lines.join(",\n"), 2)
  "{\n\{body}\n}"
}
