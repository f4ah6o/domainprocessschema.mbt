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
pub(all) struct ParsedTransition {
  name : String
  from : String
  to : String
  role : String?
  input_fields : Array[String]
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
pub(all) struct Transition {
  name : String
  from : String
  to : String
  role : String?
  input_fields : Array[String]
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
