///|
/// Public API for the phase-1 compiler.
///
/// The repository name is `domainprocessschema.mbt`, but the MoonBit module name
/// uses `_` because `.` is not allowed in MoonBit package names.
///
/// Phase 1 intentionally focuses on a single vertical slice:
///
/// - parse a constrained YAML schema
/// - normalize and validate the model
/// - generate SQL DDL
pub(all) suberror SchemaError {
  ParseError(line~ : Int, String)
  ValidationError(path~ : String, String)
} derive(Eq, Show)

///|
pub(all) enum FieldType {
  Id
  Text
  Number
  Money
  Boolean
  Date
  DateTime
  Enum
  Ref
  State
  File
} derive(Eq, Show)

///|
pub(all) enum RelationKind {
  OneToOne
  OneToMany
  ManyToOne
  ManyToMany
} derive(Eq, Show)

///|
pub(all) enum BinaryOp {
  Or
  And
  Eq
  NotEq
  Gt
  Gte
  Lt
  Lte
} derive(Eq, Show)

///|
pub(all) enum Expr {
  Path(Array[String])
  StringLiteral(String)
  NumberLiteral(String)
  BoolLiteral(Bool)
  Not(Expr)
  Binary(BinaryOp, Expr, Expr)
} derive(Eq, Show)

///|
pub(all) struct ParsedField {
  name : String
  type_name : String
  required : Bool
  primary : Bool
  read_only : Bool
  system : Bool
  default_value : String?
  target : String?
  initial : String?
} derive(Eq, Show)

///|
pub(all) struct ParsedRelation {
  name : String
  kind_name : String
  target : String
  field : String
} derive(Eq, Show)

///|
pub(all) struct ParsedConstraint {
  name : String
  expr : String
} derive(Eq, Show)

///|
pub(all) struct ParsedState {
  name : String
  label : String
} derive(Eq, Show)

///|
pub(all) struct ParsedTransitionInput {
  name : String
  type_name : String
  required : Bool
  read_only : Bool
  default_value : String?
  target : String?
} derive(Eq, Show)

///|
pub(all) struct ParsedTransition {
  name : String
  from : String
  to : String
  role : String?
  input_names : Array[String]
  inputs : Array[ParsedTransitionInput]
  guard_expr : String?
} derive(Eq, Show)

///|
pub(all) struct ParsedRule {
  name : String
  when_expr : String
} derive(Eq, Show)

///|
pub(all) struct ParsedView {
  name : String
  editable_fields : Array[String]
  readonly_fields : Array[String]
} derive(Eq, Show)

///|
pub(all) struct ParsedStorageKey {
  fields : Array[String]
} derive(Eq, Show)

///|
pub(all) struct ParsedStorage {
  table : String?
  indexes : Array[ParsedStorageKey]
  unique_keys : Array[ParsedStorageKey]
  soft_delete : Bool
} derive(Eq, Show)

///|
pub(all) struct ParsedEntity {
  name : String
  label : String
  fields : Array[ParsedField]
  relations : Array[ParsedRelation]
  constraints : Array[ParsedConstraint]
  states : Array[ParsedState]
  transitions : Array[ParsedTransition]
  rules : Array[ParsedRule]
  views : Array[ParsedView]
  storage : ParsedStorage
} derive(Eq, Show)

///|
pub(all) struct ParsedSchema {
  entities : Array[ParsedEntity]
} derive(Eq, Show)

///|
pub(all) struct Field {
  name : String
  column_name : String
  field_type : FieldType
  required : Bool
  primary : Bool
  read_only : Bool
  system : Bool
  default_value : String?
  target : String?
  initial : String?
} derive(Eq, Show)

///|
pub(all) struct Relation {
  name : String
  kind : RelationKind
  target : String
  field : String
} derive(Eq, Show)

///|
pub(all) struct Constraint {
  name : String
  expr : Expr
} derive(Eq, Show)

///|
pub(all) struct State {
  name : String
  label : String
} derive(Eq, Show)

///|
pub(all) enum TransitionInputKind {
  EntityField
  Local
} derive(Eq, Show)

///|
pub(all) struct TransitionInput {
  name : String
  kind : TransitionInputKind
  field_type : FieldType
  required : Bool
  read_only : Bool
  default_value : String?
  target : String?
} derive(Eq, Show)

///|
pub(all) struct Transition {
  name : String
  from : String
  to : String
  role : String?
  inputs : Array[TransitionInput]
  guard_expr : Expr?
} derive(Eq, Show)

///|
pub(all) struct Rule {
  name : String
  when_expr : Expr
} derive(Eq, Show)

///|
pub(all) struct View {
  name : String
  editable_fields : Array[String]
  readonly_fields : Array[String]
} derive(Eq, Show)

///|
pub(all) struct StorageKey {
  fields : Array[String]
} derive(Eq, Show)

///|
pub(all) struct Entity {
  name : String
  label : String
  table_name : String
  fields : Array[Field]
  relations : Array[Relation]
  constraints : Array[Constraint]
  states : Array[State]
  transitions : Array[Transition]
  rules : Array[Rule]
  views : Array[View]
  indexes : Array[StorageKey]
  unique_keys : Array[StorageKey]
  soft_delete : Bool
} derive(Eq, Show)

///|
pub(all) struct Schema {
  entities : Array[Entity]
} derive(Eq, Show)

///|
pub(all) enum RuntimeValue {
  Null
  Text(String)
  Integer(Int)
  Flag(Bool)
} derive(Eq, Show)

///|
pub(all) struct RuntimeIssue {
  path : String
  message : String
} derive(Eq, Show)

///|
pub(all) struct RuntimeRecord {
  entity_name : String
  values : Map[String, RuntimeValue]
} derive(Eq, Show)

///|
pub(all) struct RuntimeActor {
  attributes : Map[String, RuntimeValue]
} derive(Eq, Show)

///|
pub(all) struct RuntimeValidation {
  record : RuntimeRecord
  issues : Array[RuntimeIssue]
} derive(Eq, Show)

///|
pub(all) struct RuntimeTransitionStatus {
  name : String
  from : String
  to : String
  role : String?
  inputs : Array[TransitionInput]
  available : Bool
  issues : Array[RuntimeIssue]
} derive(Eq, Show)

///|
pub(all) struct RuntimeRuleStatus {
  name : String
  active : Bool
  issues : Array[RuntimeIssue]
} derive(Eq, Show)

///|
pub(all) struct RuntimeGuiField {
  name : String
  component : String
  mode : String
  value : RuntimeValue?
} derive(Eq, Show)

///|
pub(all) struct RuntimeGuiActionInput {
  name : String
  kind : TransitionInputKind
  component : String
  required : Bool
  value : RuntimeValue?
} derive(Eq, Show)

///|
pub(all) struct RuntimeGuiAction {
  name : String
  to : String
  available : Bool
  issues : Array[RuntimeIssue]
  inputs : Array[RuntimeGuiActionInput]
} derive(Eq, Show)

///|
pub(all) struct RuntimeGuiView {
  entity_name : String
  state : String
  view_name : String
  fields : Array[RuntimeGuiField]
  actions : Array[RuntimeGuiAction]
  rules : Array[RuntimeRuleStatus]
} derive(Eq, Show)

///|
pub(all) struct Runtime {
  schema : Schema
} derive(Eq, Show)

///|
pub(all) struct SchemaSessionSource {
  yaml : String
} derive(Eq, Show)

///|
pub(all) struct SchemaSessionSelection {
  entity_name : String?
  state_name : String?
  transition_name : String?
  field_name : String?
} derive(Eq, Show)

///|
pub(all) struct SchemaSessionDiagnostic {
  code : String
  severity : String
  target : String
  message : String
  hint : String?
  context : Map[String, String]
} derive(Eq, Show)

///|
pub(all) struct SchemaSessionCompileSnapshot {
  ok : Bool
  diagnostics : Array[SchemaSessionDiagnostic]
  api_manifest : String?
  validation_manifest : String?
  gui_manifest : String?
} derive(Eq, Show)

///|
pub(all) struct SchemaSessionRuntimeSnapshot {
  transitions : Array[RuntimeTransitionStatus]
  rules : Array[RuntimeRuleStatus]
  view : RuntimeGuiView?
  diagnostics : Array[SchemaSessionDiagnostic]
} derive(Eq, Show)

///|
pub(all) struct SchemaSessionGraphNode {
  id : String
  label : String
  kind : String
} derive(Eq, Show)

///|
pub(all) struct SchemaSessionGraphEdge {
  from : String
  to : String
  label : String
  kind : String
} derive(Eq, Show)

///|
pub(all) struct SchemaSessionGraphSnapshot {
  nodes : Array[SchemaSessionGraphNode]
  edges : Array[SchemaSessionGraphEdge]
} derive(Eq, Show)

///|
pub(all) struct SchemaRuntimeSessionStore {
  source : SchemaSessionSource
  selection : SchemaSessionSelection
  actor : RuntimeActor
  record : RuntimeRecord?
  compile : SchemaSessionCompileSnapshot
  runtime : SchemaSessionRuntimeSnapshot
  graph : SchemaSessionGraphSnapshot
  locale : String
  last_action : String
} derive(Eq, Show)

///|
pub(all) enum SchemaAppServerToolAccess {
  ReadOnly
  Mutating
  ApprovalRequired
} derive(Eq, Show)

///|
pub(all) struct SchemaAppServerToolShape {
  name : String
  access : SchemaAppServerToolAccess
  input_shape : String
  output_shape : String
} derive(Eq, Show)

///|
pub(all) struct SchemaAppServerToolApprovalProposal {
  id : String
  tool : String
  title : String
  summary : String
  input_json : String
  detail_json : String
} derive(Eq, Show)

///|
pub(all) struct SchemaAppServerToolEnvelope {
  tool : String
  access : SchemaAppServerToolAccess
  diagnostics : Array[SchemaSessionDiagnostic]
  snapshot : SchemaRuntimeSessionStore
  approval : SchemaAppServerToolApprovalProposal?
} derive(Eq, Show)

///|
pub(all) struct SchemaToolInspectorEditInput {
  entity_name : String
  source_path : String
  schema_path : String
  value : RuntimeValue
} derive(Eq, Show)

///|
pub(all) struct SchemaToolTransitionApplyInput {
  transition_name : String
  input : Map[String, RuntimeValue]
} derive(Eq, Show)

///|
pub(all) enum SchemaSessionArtifactFormat {
  SourceYaml
  NormalizedSchema
  RuntimeSession
  DiagnosticReport
} derive(Eq, Show)

///|
pub(all) struct SchemaSessionArtifactEnvelope {
  version : Int
  format : SchemaSessionArtifactFormat
  media_type : String
  payload : String
} derive(Eq, Show)

///|
pub(all) suberror RuntimeError {
  UnknownEntity(entity~ : String)
  EntityMismatch(expected~ : String, found~ : String)
  UnknownTransition(entity~ : String, transition~ : String)
  MissingView(entity~ : String, state~ : String)
  InvalidRecord(entity~ : String, issues~ : Array[RuntimeIssue])
  TransitionRejected(
    entity~ : String,
    transition~ : String,
    issues~ : Array[RuntimeIssue]
  )
} derive(Eq, Show)

///|
pub(all) suberror HtmlRenderError {
  InvalidGuiJson(String)
  InvalidGuiManifest(path~ : String, String)
} derive(Eq, Show)

///|
pub fn RuntimeActor::anonymous() -> RuntimeActor {
  RuntimeActor::{ attributes: {} }
}

///|
pub fn RuntimeValidation::is_ok(self : RuntimeValidation) -> Bool {
  self.issues.length() == 0
}

///|
pub fn RuntimeTransitionStatus::is_available(
  self : RuntimeTransitionStatus,
) -> Bool {
  self.available && self.issues.length() == 0
}

///|
pub fn SchemaSessionSelection::empty() -> SchemaSessionSelection {
  SchemaSessionSelection::{
    entity_name: None,
    state_name: None,
    transition_name: None,
    field_name: None,
  }
}

///|
pub fn schema_app_server_tool_shapes() -> Array[SchemaAppServerToolShape] {
  schema_app_server_tool_shape_catalog()
}

///|
pub fn schema_tool_session_snapshot(
  store : SchemaRuntimeSessionStore,
) -> SchemaAppServerToolEnvelope {
  schema_tool_read_session_snapshot(store)
}

///|
pub fn schema_tool_compile_current_source(
  store : SchemaRuntimeSessionStore,
) -> SchemaAppServerToolEnvelope {
  schema_tool_read_compile_current_source(store)
}

///|
pub fn schema_tool_runtime_view(
  store : SchemaRuntimeSessionStore,
) -> SchemaAppServerToolEnvelope {
  schema_tool_read_runtime_view(store)
}

///|
pub fn schema_tool_available_transitions(
  store : SchemaRuntimeSessionStore,
) -> SchemaAppServerToolEnvelope {
  schema_tool_read_available_transitions(store)
}

///|
pub fn schema_tool_graph(
  store : SchemaRuntimeSessionStore,
) -> SchemaAppServerToolEnvelope {
  schema_tool_read_graph(store)
}

///|
pub fn schema_tool_diagnostics(
  store : SchemaRuntimeSessionStore,
) -> SchemaAppServerToolEnvelope {
  schema_tool_read_diagnostics(store)
}

///|
pub fn schema_tool_replace_source(
  store : SchemaRuntimeSessionStore,
  source_yaml : String,
) -> SchemaAppServerToolEnvelope {
  schema_tool_mutate_replace_source(store, source_yaml)
}

///|
pub fn schema_tool_inspector_edit(
  store : SchemaRuntimeSessionStore,
  input : SchemaToolInspectorEditInput,
) -> SchemaAppServerToolEnvelope {
  schema_tool_mutate_inspector_edit(store, input)
}

///|
pub fn schema_tool_select(
  store : SchemaRuntimeSessionStore,
  selection : SchemaSessionSelection,
) -> SchemaAppServerToolEnvelope {
  schema_tool_mutate_select(store, selection)
}

///|
pub fn schema_tool_set_actor_role(
  store : SchemaRuntimeSessionStore,
  role : String,
) -> SchemaAppServerToolEnvelope {
  schema_tool_mutate_set_actor_role(store, role)
}

///|
pub fn schema_tool_update_record_payload(
  store : SchemaRuntimeSessionStore,
  entity_name : String,
  payload : Map[String, RuntimeValue],
) -> SchemaAppServerToolEnvelope {
  schema_tool_mutate_update_record_payload(store, entity_name, payload)
}

///|
pub fn schema_tool_set_locale(
  store : SchemaRuntimeSessionStore,
  locale : String,
) -> SchemaAppServerToolEnvelope {
  schema_tool_mutate_set_locale(store, locale)
}

///|
pub fn schema_tool_propose_transition_apply(
  store : SchemaRuntimeSessionStore,
  input : SchemaToolTransitionApplyInput,
) -> SchemaAppServerToolEnvelope {
  schema_tool_approval_transition_apply(store, input)
}

///|
pub fn schema_tool_propose_reset_session(
  store : SchemaRuntimeSessionStore,
) -> SchemaAppServerToolEnvelope {
  schema_tool_approval_reset_session(store)
}

///|
pub fn export_schema_tool_envelope(
  envelope : SchemaAppServerToolEnvelope,
) -> String {
  render_schema_tool_envelope_json(envelope)
}

///|
pub fn export_schema_session_artifact(
  store : SchemaRuntimeSessionStore,
  format : SchemaSessionArtifactFormat,
) -> SchemaSessionArtifactEnvelope {
  schema_session_export_artifact(store, format)
}

///|
pub fn render_schema_session_artifact(
  artifact : SchemaSessionArtifactEnvelope,
) -> String {
  render_schema_session_artifact_envelope_json(artifact)
}

///|
/// Parse the supported YAML subset into a stringly typed draft model.
pub fn parse_schema_yaml(input : String) -> ParsedSchema raise SchemaError {
  let root = parse_yaml_document(input)
  parse_schema_root(root)
}

///|
/// Validate the parsed draft model and normalize it into a SQL-ready schema.
pub fn validate_schema(parsed : ParsedSchema) -> Schema raise SchemaError {
  validate_parsed_schema(parsed)
}

///|
/// Convert a validated schema into SQL DDL.
pub fn generate_sql(schema : Schema) -> String {
  render_sql(schema)
}

///|
/// Convert a validated schema into a machine-readable API/action manifest.
pub fn generate_api_manifest(schema : Schema) -> String {
  render_api_manifest(schema)
}

///|
/// Convert a validated schema into an initial migration script.
pub fn generate_migration_sql(schema : Schema) -> String {
  render_migration_sql(schema)
}

///|
/// Convert a validated schema into a machine-readable validation manifest.
pub fn generate_validation_manifest(schema : Schema) -> String {
  render_validation_manifest(schema)
}

///|
/// Convert a validated schema into a machine-readable GUI manifest.
pub fn generate_gui_manifest(schema : Schema) -> String {
  render_gui_manifest(schema)
}

///|
/// Render static HTML from a GUI manifest JSON document.
pub fn render_gui_html_from_manifest(
  manifest_json : String,
) -> String raise HtmlRenderError {
  let manifest = parse_gui_manifest_json(manifest_json)
  render_gui_manifest_html(manifest)
}

///|
/// Compile YAML directly to a static HTML preview derived from GUI manifest output.
pub fn compile_gui_html_from_yaml(input : String) -> String raise {
  let manifest = compile_gui_manifest_from_yaml(input)
  render_gui_html_from_manifest(manifest)
}

///|
/// Render a stateful runtime GUI projection as static HTML.
pub fn render_runtime_gui_html(
  runtime : Runtime,
  record : RuntimeRecord,
  actor? : RuntimeActor = RuntimeActor::anonymous(),
) -> String raise RuntimeError {
  let projected = project_gui(runtime, record, actor~)
  render_runtime_gui_view_html(runtime.schema, projected)
}

///|
/// Prepare a validated schema for in-memory runtime operations.
pub fn build_runtime(schema : Schema) -> Runtime {
  Runtime::{ schema, }
}

///|
/// Compile YAML directly to a prepared runtime.
pub fn compile_runtime_from_yaml(input : String) -> Runtime raise SchemaError {
  let parsed = parse_schema_yaml(input)
  let schema = validate_schema(parsed)
  build_runtime(schema)
}

///|
/// Validate a partial or full entity payload in memory.
pub fn validate_record(
  runtime : Runtime,
  entity_name : String,
  payload : Map[String, RuntimeValue],
  current? : RuntimeRecord,
) -> RuntimeValidation raise RuntimeError {
  runtime_validate_record(runtime, entity_name, payload, current)
}

///|
/// List transition availability for the current record and actor context.
pub fn list_transitions(
  runtime : Runtime,
  record : RuntimeRecord,
  actor? : RuntimeActor = RuntimeActor::anonymous(),
) -> Array[RuntimeTransitionStatus] raise RuntimeError {
  runtime_list_transitions(runtime, record, actor)
}

///|
/// Evaluate entity rules for a record and actor context.
pub fn evaluate_rules(
  runtime : Runtime,
  record : RuntimeRecord,
  actor? : RuntimeActor = RuntimeActor::anonymous(),
) -> Array[RuntimeRuleStatus] raise RuntimeError {
  runtime_evaluate_rules(runtime, record, actor)
}

///|
/// Project a runtime GUI view for the current record state.
pub fn project_gui(
  runtime : Runtime,
  record : RuntimeRecord,
  actor? : RuntimeActor = RuntimeActor::anonymous(),
) -> RuntimeGuiView raise RuntimeError {
  runtime_project_gui(runtime, record, actor)
}

///|
/// Apply a transition in memory and return the updated record.
pub fn apply_transition(
  runtime : Runtime,
  record : RuntimeRecord,
  transition_name : String,
  input? : Map[String, RuntimeValue] = {},
  actor? : RuntimeActor = RuntimeActor::anonymous(),
) -> RuntimeRecord raise RuntimeError {
  runtime_apply_transition(runtime, record, transition_name, input, actor)
}

///|
/// Create a durable schema/runtime session store from YAML source.
///
/// The store is a library data model. It keeps transport concerns such as HTTP,
/// Durable Objects, or browser storage outside the runtime core.
pub fn create_schema_runtime_session(
  source_yaml : String,
  actor? : RuntimeActor = RuntimeActor::anonymous(),
  record? : RuntimeRecord,
  selection? : SchemaSessionSelection = SchemaSessionSelection::empty(),
  locale? : String = "en",
) -> SchemaRuntimeSessionStore {
  schema_session_refresh(
    SchemaSessionSource::{ yaml: source_yaml },
    selection,
    actor,
    record,
    locale,
    "created",
  )
}

///|
/// Replace source YAML and refresh compile, runtime, diagnostics, and graph.
///
/// Resume fields are preserved: selection, actor, locale, and a compatible
/// record are carried forward. An incompatible record is dropped.
pub fn schema_session_set_source(
  store : SchemaRuntimeSessionStore,
  source_yaml : String,
) -> SchemaRuntimeSessionStore {
  schema_session_refresh(
    SchemaSessionSource::{ yaml: source_yaml },
    store.selection,
    store.actor,
    store.record,
    store.locale,
    "sourceChanged",
  )
}

///|
pub fn schema_session_set_selection(
  store : SchemaRuntimeSessionStore,
  selection : SchemaSessionSelection,
) -> SchemaRuntimeSessionStore {
  SchemaRuntimeSessionStore::{
    ..store,
    selection,
    last_action: "selectionChanged",
  }
}

///|
pub fn schema_session_set_actor(
  store : SchemaRuntimeSessionStore,
  actor : RuntimeActor,
) -> SchemaRuntimeSessionStore {
  schema_session_refresh(
    store.source,
    store.selection,
    actor,
    store.record,
    store.locale,
    "actorChanged",
  )
}

///|
pub fn schema_session_set_locale(
  store : SchemaRuntimeSessionStore,
  locale : String,
) -> SchemaRuntimeSessionStore {
  SchemaRuntimeSessionStore::{ ..store, locale, last_action: "localeChanged" }
}

///|
/// Apply inspector edits to the current record and refresh runtime snapshots.
pub fn schema_session_edit_record(
  store : SchemaRuntimeSessionStore,
  entity_name : String,
  payload : Map[String, RuntimeValue],
) -> SchemaRuntimeSessionStore {
  match schema_session_compile_runtime(store.source.yaml) {
    Some(runtime) => {
      let current = match store.record {
        Some(record) =>
          if record.entity_name == entity_name {
            Some(record)
          } else {
            None
          }
        None => None
      }
      let validation = match current {
        Some(current) =>
          try? validate_record(runtime, entity_name, payload, current~)
        None => try? validate_record(runtime, entity_name, payload)
      }
      let next_record = match validation {
        Ok(result) => Some(result.record)
        Err(_) => store.record
      }
      schema_session_refresh(
        store.source,
        store.selection,
        store.actor,
        next_record,
        store.locale,
        "recordEdited",
      )
    }
    None =>
      SchemaRuntimeSessionStore::{ ..store, last_action: "recordEditRejected" }
  }
}

///|
/// Apply a runtime transition to the current record and refresh snapshots.
pub fn schema_session_apply_transition(
  store : SchemaRuntimeSessionStore,
  transition_name : String,
  input? : Map[String, RuntimeValue] = {},
) -> SchemaRuntimeSessionStore {
  match (schema_session_compile_runtime(store.source.yaml), store.record) {
    (Some(runtime), Some(record)) => {
      let applied = try? apply_transition(
        runtime,
        record,
        transition_name,
        input~,
        actor=store.actor,
      )
      let next_record = match applied {
        Ok(record) => Some(record)
        Err(_) => store.record
      }
      schema_session_refresh(
        store.source,
        store.selection,
        store.actor,
        next_record,
        store.locale,
        "transition:\{transition_name}",
      )
    }
    _ =>
      SchemaRuntimeSessionStore::{
        ..store,
        last_action: "transitionRejected:\{transition_name}",
      }
  }
}

///|
/// Export the durable session snapshot as a stable JSON envelope.
pub fn export_schema_runtime_session(
  store : SchemaRuntimeSessionStore,
) -> String {
  render_schema_runtime_session_json(store)
}

///|
/// Compile YAML directly to SQL by chaining parse, validate, and render.
pub fn compile_sql_from_yaml(input : String) -> String raise SchemaError {
  let parsed = parse_schema_yaml(input)
  let schema = validate_schema(parsed)
  generate_sql(schema)
}

///|
/// Compile YAML directly to API/action manifest JSON.
pub fn compile_api_manifest_from_yaml(
  input : String,
) -> String raise SchemaError {
  let parsed = parse_schema_yaml(input)
  let schema = validate_schema(parsed)
  generate_api_manifest(schema)
}

///|
/// Compile YAML directly to an initial migration script.
pub fn compile_migration_sql_from_yaml(
  input : String,
) -> String raise SchemaError {
  let parsed = parse_schema_yaml(input)
  let schema = validate_schema(parsed)
  generate_migration_sql(schema)
}

///|
/// Compile YAML directly to a validation manifest JSON document.
pub fn compile_validation_manifest_from_yaml(
  input : String,
) -> String raise SchemaError {
  let parsed = parse_schema_yaml(input)
  let schema = validate_schema(parsed)
  generate_validation_manifest(schema)
}

///|
/// Compile YAML directly to a GUI manifest JSON document.
pub fn compile_gui_manifest_from_yaml(
  input : String,
) -> String raise SchemaError {
  let parsed = parse_schema_yaml(input)
  let schema = validate_schema(parsed)
  generate_gui_manifest(schema)
}
