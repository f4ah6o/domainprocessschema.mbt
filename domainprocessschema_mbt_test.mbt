///|
fn sample_schema() -> String {
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
    #|      createdAt:
    #|        type: datetime
    #|        system: true
    #|      updatedAt:
    #|        type: datetime
    #|        system: true
    #|    relations:
    #|      applicant:
    #|        kind: many-to-one
    #|        target: User
    #|        field: applicant
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
    #|          - reason
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
    #|    storage:
    #|      table: expense_requests
    #|      indexes:
    #|        - fields: [status]
    #|        - fields: [applicant, createdAt]
    #|      unique:
    #|        - fields: [applicant, createdAt]
    #|      softDelete: true
  )
}

///|
test "compile_sql_from_yaml renders the phase-1 vertical slice" {
  let sql = compile_sql_from_yaml(sample_schema())
  inspect(
    sql,
    content=(
      #|CREATE TABLE users (
      #|  id TEXT PRIMARY KEY NOT NULL,
      #|  role TEXT NOT NULL
      #|);
      #|
      #|CREATE TABLE expense_requests (
      #|  id TEXT PRIMARY KEY NOT NULL,
      #|  amount INTEGER NOT NULL,
      #|  reason TEXT NOT NULL,
      #|  applicant_id TEXT NOT NULL,
      #|  status TEXT DEFAULT 'draft',
      #|  created_at TEXT NOT NULL,
      #|  updated_at TEXT NOT NULL,
      #|  FOREIGN KEY (applicant_id) REFERENCES users(id),
      #|  CHECK (amount > 0),
      #|  UNIQUE (applicant_id, created_at)
      #|);
      #|
      #|CREATE INDEX idx_expense_requests_status ON expense_requests (status);
      #|
      #|CREATE INDEX idx_expense_requests_applicant_id_created_at ON expense_requests (applicant_id, created_at);
    ),
  )
}

///|
test "validate_schema rejects unknown transition states" {
  let invalid =
    #|entities:
    #|  ExpenseRequest:
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
    #|    transitions:
    #|      submit:
    #|        from: draft
    #|        to: submitted
  let result : Result[String, SchemaError] = try? compile_sql_from_yaml(invalid)
  inspect(
    result,
    content="Err(ValidationError(path=\"schema.entities.ExpenseRequest.transitions.submit\", \"unknown target state submitted\"))",
  )
}

///|
test "parse_schema_yaml rejects malformed yaml" {
  let malformed =
    #|entities:
    #|  ExpenseRequest
    #|    label: broken
  let result : Result[ParsedSchema, SchemaError] = try? parse_schema_yaml(
    malformed,
  )
  inspect(
    result,
    content="Err(ParseError(line=2, \"expected a `key: value` mapping entry\"))",
  )
}
