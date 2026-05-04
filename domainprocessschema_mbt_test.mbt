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
test "compile_api_manifest_from_yaml renders routes and actions" {
  let manifest = compile_api_manifest_from_yaml(sample_schema())
  inspect(
    manifest,
    content=(
      #|{
      #|  "entities": [
      #|    {
      #|      "name": "User",
      #|      "label": "ユーザー",
      #|      "table": "users",
      #|      "fields": [
      #|          {
      #|            "name": "id",
      #|            "column": "id",
      #|            "type": "id",
      #|            "required": false,
      #|            "primary": true,
      #|            "readOnly": false,
      #|            "system": false
      #|          },
      #|          {
      #|            "name": "role",
      #|            "column": "role",
      #|            "type": "text",
      #|            "required": true,
      #|            "primary": false,
      #|            "readOnly": false,
      #|            "system": false
      #|          }
      #|        ],
      #|      "routes": [
      #|          {
      #|            "method": "GET",
      #|            "path": "/users/{id}"
      #|          },
      #|          {
      #|            "method": "POST",
      #|            "path": "/users"
      #|          },
      #|          {
      #|            "method": "PATCH",
      #|            "path": "/users/{id}"
      #|          }
      #|        ],
      #|      "actions": []
      #|    },
      #|    {
      #|      "name": "ExpenseRequest",
      #|      "label": "経費申請",
      #|      "table": "expense_requests",
      #|      "fields": [
      #|          {
      #|            "name": "id",
      #|            "column": "id",
      #|            "type": "id",
      #|            "required": false,
      #|            "primary": true,
      #|            "readOnly": false,
      #|            "system": false
      #|          },
      #|          {
      #|            "name": "amount",
      #|            "column": "amount",
      #|            "type": "money",
      #|            "required": true,
      #|            "primary": false,
      #|            "readOnly": false,
      #|            "system": false
      #|          },
      #|          {
      #|            "name": "reason",
      #|            "column": "reason",
      #|            "type": "text",
      #|            "required": true,
      #|            "primary": false,
      #|            "readOnly": false,
      #|            "system": false
      #|          },
      #|          {
      #|            "name": "applicant",
      #|            "column": "applicant_id",
      #|            "type": "ref",
      #|            "required": true,
      #|            "primary": false,
      #|            "readOnly": false,
      #|            "system": false
      #|          },
      #|          {
      #|            "name": "status",
      #|            "column": "status",
      #|            "type": "state",
      #|            "required": false,
      #|            "primary": false,
      #|            "readOnly": false,
      #|            "system": false
      #|          },
      #|          {
      #|            "name": "createdAt",
      #|            "column": "created_at",
      #|            "type": "datetime",
      #|            "required": false,
      #|            "primary": false,
      #|            "readOnly": false,
      #|            "system": true
      #|          },
      #|          {
      #|            "name": "updatedAt",
      #|            "column": "updated_at",
      #|            "type": "datetime",
      #|            "required": false,
      #|            "primary": false,
      #|            "readOnly": false,
      #|            "system": true
      #|          }
      #|        ],
      #|      "routes": [
      #|          {
      #|            "method": "GET",
      #|            "path": "/expense_requests/{id}"
      #|          },
      #|          {
      #|            "method": "POST",
      #|            "path": "/expense_requests"
      #|          },
      #|          {
      #|            "method": "PATCH",
      #|            "path": "/expense_requests/{id}"
      #|          }
      #|        ],
      #|      "actions": [
      #|          {
      #|            "name": "submit",
      #|            "from": "draft",
      #|            "to": "submitted",
      #|            "path": "/expense_requests/{id}/submit",
      #|            "input": ["amount", "reason"],
      #|            "guard": "amount > 0",
      #|            "role": null
      #|          },
      #|          {
      #|            "name": "approve",
      #|            "from": "submitted",
      #|            "to": "approved",
      #|            "path": "/expense_requests/{id}/approve",
      #|            "input": [],
      #|            "guard": null,
      #|            "role": "manager"
      #|          },
      #|          {
      #|            "name": "reject",
      #|            "from": "submitted",
      #|            "to": "rejected",
      #|            "path": "/expense_requests/{id}/reject",
      #|            "input": ["reason"],
      #|            "guard": null,
      #|            "role": "manager"
      #|          }
      #|        ]
      #|    }
      #|  ]
      #|}
    ),
  )
}

///|
test "compile_validation_manifest_from_yaml renders validation metadata" {
  let manifest = compile_validation_manifest_from_yaml(sample_schema())
  inspect(manifest, content=(
    
    #|{
    #|  "entities": [
    #|    {
    #|      "name": "User",
    #|      "fields": [
    #|          {
    #|            "name": "id",
    #|            "type": "id",
    #|            "required": false,
    #|            "primary": true,
    #|            "readOnly": false,
    #|            "system": false,
    #|            "default": null
    #|          },
    #|          {
    #|            "name": "role",
    #|            "type": "text",
    #|            "required": true,
    #|            "primary": false,
    #|            "readOnly": false,
    #|            "system": false,
    #|            "default": null
    #|          }
    #|        ],
    #|      "constraints": [],
    #|      "transitions": [],
    #|      "rules": []
    #|    },
    #|    {
    #|      "name": "ExpenseRequest",
    #|      "fields": [
    #|          {
    #|            "name": "id",
    #|            "type": "id",
    #|            "required": false,
    #|            "primary": true,
    #|            "readOnly": false,
    #|            "system": false,
    #|            "default": null
    #|          },
    #|          {
    #|            "name": "amount",
    #|            "type": "money",
    #|            "required": true,
    #|            "primary": false,
    #|            "readOnly": false,
    #|            "system": false,
    #|            "default": null
    #|          },
    #|          {
    #|            "name": "reason",
    #|            "type": "text",
    #|            "required": true,
    #|            "primary": false,
    #|            "readOnly": false,
    #|            "system": false,
    #|            "default": null
    #|          },
    #|          {
    #|            "name": "applicant",
    #|            "type": "ref",
    #|            "required": true,
    #|            "primary": false,
    #|            "readOnly": false,
    #|            "system": false,
    #|            "default": null
    #|          },
    #|          {
    #|            "name": "status",
    #|            "type": "state",
    #|            "required": false,
    #|            "primary": false,
    #|            "readOnly": false,
    #|            "system": false,
    #|            "default": null
    #|          },
    #|          {
    #|            "name": "createdAt",
    #|            "type": "datetime",
    #|            "required": false,
    #|            "primary": false,
    #|            "readOnly": false,
    #|            "system": true,
    #|            "default": null
    #|          },
    #|          {
    #|            "name": "updatedAt",
    #|            "type": "datetime",
    #|            "required": false,
    #|            "primary": false,
    #|            "readOnly": false,
    #|            "system": true,
    #|            "default": null
    #|          }
    #|        ],
    #|      "constraints": [
    #|          {
    #|            "name": "amountPositive",
    #|            "expr": "amount > 0"
    #|          }
    #|        ],
    #|      "transitions": [
    #|          {
    #|            "name": "submit",
    #|            "from": "draft",
    #|            "to": "submitted",
    #|            "input": ["amount", "reason"],
    #|            "guard": "amount > 0"
    #|          },
    #|          {
    #|            "name": "approve",
    #|            "from": "submitted",
    #|            "to": "approved",
    #|            "input": [],
    #|            "guard": null
    #|          },
    #|          {
    #|            "name": "reject",
    #|            "from": "submitted",
    #|            "to": "rejected",
    #|            "input": ["reason"],
    #|            "guard": null
    #|          }
    #|        ],
    #|      "rules": [
    #|          {
    #|            "name": "canApprove",
    #|            "when": "state == \"submitted\" && user.role == \"manager\""
    #|          }
    #|        ]
    #|    }
    #|  ]
    #|}
  ))
}

///|
test "compile_gui_manifest_from_yaml renders views and actions" {
  let manifest = compile_gui_manifest_from_yaml(sample_schema())
  inspect(manifest, content=(
    
    #|{
    #|  "entities": [
    #|    {
    #|      "name": "User",
    #|      "label": "ユーザー",
    #|      "states": [],
    #|      "views": [],
    #|      "rules": []
    #|    },
    #|    {
    #|      "name": "ExpenseRequest",
    #|      "label": "経費申請",
    #|      "states": [
    #|          {
    #|            "name": "draft",
    #|            "label": "下書き"
    #|          },
    #|          {
    #|            "name": "submitted",
    #|            "label": "申請中"
    #|          },
    #|          {
    #|            "name": "approved",
    #|            "label": "承認済"
    #|          },
    #|          {
    #|            "name": "rejected",
    #|            "label": "却下"
    #|          }
    #|        ],
    #|      "views": [
    #|          {
    #|            "name": "draft",
    #|            "fields": [
    #|                {
    #|                  "name": "id",
    #|                  "component": "text",
    #|                  "mode": "hidden"
    #|                },
    #|                {
    #|                  "name": "amount",
    #|                  "component": "money",
    #|                  "mode": "editable"
    #|                },
    #|                {
    #|                  "name": "reason",
    #|                  "component": "textarea",
    #|                  "mode": "editable"
    #|                },
    #|                {
    #|                  "name": "applicant",
    #|                  "component": "reference-select",
    #|                  "mode": "hidden"
    #|                },
    #|                {
    #|                  "name": "status",
    #|                  "component": "state-badge",
    #|                  "mode": "hidden"
    #|                },
    #|                {
    #|                  "name": "createdAt",
    #|                  "component": "datetime-picker",
    #|                  "mode": "readonly"
    #|                },
    #|                {
    #|                  "name": "updatedAt",
    #|                  "component": "datetime-picker",
    #|                  "mode": "readonly"
    #|                }
    #|              ],
    #|            "actions": [
    #|                {
    #|                  "name": "submit",
    #|                  "to": "submitted",
    #|                  "input": ["amount", "reason"],
    #|                  "enabledWhen": "amount > 0",
    #|                  "role": null
    #|                }
    #|              ]
    #|          },
    #|          {
    #|            "name": "submitted",
    #|            "fields": [
    #|                {
    #|                  "name": "id",
    #|                  "component": "text",
    #|                  "mode": "hidden"
    #|                },
    #|                {
    #|                  "name": "amount",
    #|                  "component": "money",
    #|                  "mode": "readonly"
    #|                },
    #|                {
    #|                  "name": "reason",
    #|                  "component": "textarea",
    #|                  "mode": "readonly"
    #|                },
    #|                {
    #|                  "name": "applicant",
    #|                  "component": "reference-select",
    #|                  "mode": "hidden"
    #|                },
    #|                {
    #|                  "name": "status",
    #|                  "component": "state-badge",
    #|                  "mode": "hidden"
    #|                },
    #|                {
    #|                  "name": "createdAt",
    #|                  "component": "datetime-picker",
    #|                  "mode": "readonly"
    #|                },
    #|                {
    #|                  "name": "updatedAt",
    #|                  "component": "datetime-picker",
    #|                  "mode": "readonly"
    #|                }
    #|              ],
    #|            "actions": [
    #|                {
    #|                  "name": "approve",
    #|                  "to": "approved",
    #|                  "input": [],
    #|                  "enabledWhen": null,
    #|                  "role": "manager"
    #|                },
    #|                {
    #|                  "name": "reject",
    #|                  "to": "rejected",
    #|                  "input": ["reason"],
    #|                  "enabledWhen": null,
    #|                  "role": "manager"
    #|                }
    #|              ]
    #|          }
    #|        ],
    #|      "rules": [
    #|          {
    #|            "name": "canApprove",
    #|            "when": "state == \"submitted\" && user.role == \"manager\""
    #|          }
    #|        ]
    #|    }
    #|  ]
    #|}
  ))
}

///|
test "compile_migration_sql_from_yaml renders up and down migration blocks" {
  let migration_sql = compile_migration_sql_from_yaml(sample_schema())
  inspect(migration_sql, content=(
    
    #|-- migrate:up
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
    #|
    #|-- migrate:down
    #|DROP TABLE IF EXISTS expense_requests;
    #|DROP TABLE IF EXISTS users;
  ))
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
test "validate_schema rejects unknown identifiers in expressions" {
  let invalid =
    #|entities:
    #|  ExpenseRequest:
    #|    fields:
    #|      id:
    #|        type: id
    #|        primary: true
    #|      amount:
    #|        type: money
    #|      status:
    #|        type: state
    #|        initial: draft
    #|    states:
    #|      draft:
    #|        label: 下書き
    #|    constraints:
    #|      bad:
    #|        expr: missing > 0
  let result : Result[String, SchemaError] = try? compile_sql_from_yaml(invalid)
  inspect(
    result,
    content=(
      #|Err(ValidationError(path="schema.entities.ExpenseRequest.constraints.bad.expr", "unknown identifier path missing"))
    ),
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
