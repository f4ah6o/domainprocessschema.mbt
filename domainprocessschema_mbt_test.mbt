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
      #|  "schemaVersion": "domainprocessschema.v1",
      #|  "manifestKind": "api-manifest",
      #|  "generator": {
      #|      "name": "domainprocessschema.mbt",
      #|      "version": "0.1.0"
      #|    },
      #|  "payload": {
      #|    "entities": [
      #|      {
      #|        "name": "User",
      #|        "label": "ユーザー",
      #|        "table": "users",
      #|        "fields": [
      #|            {
      #|              "name": "id",
      #|              "column": "id",
      #|              "type": "id",
      #|              "required": false,
      #|              "primary": true,
      #|              "readOnly": false,
      #|              "system": false,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            },
      #|            {
      #|              "name": "role",
      #|              "column": "role",
      #|              "type": "text",
      #|              "required": true,
      #|              "primary": false,
      #|              "readOnly": false,
      #|              "system": false,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            }
      #|          ],
      #|        "routes": [
      #|            {
      #|              "method": "GET",
      #|              "path": "/users/{id}"
      #|            },
      #|            {
      #|              "method": "POST",
      #|              "path": "/users"
      #|            },
      #|            {
      #|              "method": "PATCH",
      #|              "path": "/users/{id}"
      #|            }
      #|          ],
      #|        "actions": []
      #|      },
      #|      {
      #|        "name": "ExpenseRequest",
      #|        "label": "経費申請",
      #|        "table": "expense_requests",
      #|        "fields": [
      #|            {
      #|              "name": "id",
      #|              "column": "id",
      #|              "type": "id",
      #|              "required": false,
      #|              "primary": true,
      #|              "readOnly": false,
      #|              "system": false,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            },
      #|            {
      #|              "name": "amount",
      #|              "column": "amount",
      #|              "type": "money",
      #|              "required": true,
      #|              "primary": false,
      #|              "readOnly": false,
      #|              "system": false,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            },
      #|            {
      #|              "name": "reason",
      #|              "column": "reason",
      #|              "type": "text",
      #|              "required": true,
      #|              "primary": false,
      #|              "readOnly": false,
      #|              "system": false,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            },
      #|            {
      #|              "name": "applicant",
      #|              "column": "applicant_id",
      #|              "type": "ref",
      #|              "required": true,
      #|              "primary": false,
      #|              "readOnly": false,
      #|              "system": false,
      #|              "target": "User",
      #|              "labelField": "id",
      #|              "valueField": "id"
      #|            },
      #|            {
      #|              "name": "status",
      #|              "column": "status",
      #|              "type": "state",
      #|              "required": false,
      #|              "primary": false,
      #|              "readOnly": false,
      #|              "system": false,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            },
      #|            {
      #|              "name": "createdAt",
      #|              "column": "created_at",
      #|              "type": "datetime",
      #|              "required": false,
      #|              "primary": false,
      #|              "readOnly": false,
      #|              "system": true,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            },
      #|            {
      #|              "name": "updatedAt",
      #|              "column": "updated_at",
      #|              "type": "datetime",
      #|              "required": false,
      #|              "primary": false,
      #|              "readOnly": false,
      #|              "system": true,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            }
      #|          ],
      #|        "routes": [
      #|            {
      #|              "method": "GET",
      #|              "path": "/expense_requests/{id}"
      #|            },
      #|            {
      #|              "method": "POST",
      #|              "path": "/expense_requests"
      #|            },
      #|            {
      #|              "method": "PATCH",
      #|              "path": "/expense_requests/{id}"
      #|            }
      #|          ],
      #|        "actions": [
      #|            {
      #|              "name": "submit",
      #|              "from": "draft",
      #|              "to": "submitted",
      #|              "path": "/expense_requests/{id}/submit",
      #|              "inputs": [
      #|                  {
      #|                    "name": "amount",
      #|                    "kind": "entity-field",
      #|                    "type": "money",
      #|                    "required": true,
      #|                    "readOnly": false,
      #|                    "default": null,
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "reason",
      #|                    "kind": "entity-field",
      #|                    "type": "text",
      #|                    "required": true,
      #|                    "readOnly": false,
      #|                    "default": null,
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  }
      #|                ],
      #|              "guard": "amount > 0",
      #|              "role": null
      #|            },
      #|            {
      #|              "name": "approve",
      #|              "from": "submitted",
      #|              "to": "approved",
      #|              "path": "/expense_requests/{id}/approve",
      #|              "inputs": [],
      #|              "guard": null,
      #|              "role": "manager"
      #|            },
      #|            {
      #|              "name": "reject",
      #|              "from": "submitted",
      #|              "to": "rejected",
      #|              "path": "/expense_requests/{id}/reject",
      #|              "inputs": [
      #|                  {
      #|                    "name": "rejectReason",
      #|                    "kind": "local",
      #|                    "type": "text",
      #|                    "required": true,
      #|                    "readOnly": false,
      #|                    "default": null,
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  }
      #|                ],
      #|              "guard": null,
      #|              "role": "manager"
      #|            }
      #|          ]
      #|      }
      #|    ]
      #|  }
      #|}

    ),
  )
}

///|
test "compile_validation_manifest_from_yaml renders validation metadata" {
  let manifest = compile_validation_manifest_from_yaml(sample_schema())
  inspect(
    manifest,
    content=(
      #|{
      #|  "schemaVersion": "domainprocessschema.v1",
      #|  "manifestKind": "validation-manifest",
      #|  "generator": {
      #|      "name": "domainprocessschema.mbt",
      #|      "version": "0.1.0"
      #|    },
      #|  "payload": {
      #|    "entities": [
      #|      {
      #|        "name": "User",
      #|        "fields": [
      #|            {
      #|              "name": "id",
      #|              "type": "id",
      #|              "required": false,
      #|              "primary": true,
      #|              "readOnly": false,
      #|              "system": false,
      #|              "default": null,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            },
      #|            {
      #|              "name": "role",
      #|              "type": "text",
      #|              "required": true,
      #|              "primary": false,
      #|              "readOnly": false,
      #|              "system": false,
      #|              "default": null,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            }
      #|          ],
      #|        "constraints": [],
      #|        "transitions": [],
      #|        "rules": []
      #|      },
      #|      {
      #|        "name": "ExpenseRequest",
      #|        "fields": [
      #|            {
      #|              "name": "id",
      #|              "type": "id",
      #|              "required": false,
      #|              "primary": true,
      #|              "readOnly": false,
      #|              "system": false,
      #|              "default": null,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            },
      #|            {
      #|              "name": "amount",
      #|              "type": "money",
      #|              "required": true,
      #|              "primary": false,
      #|              "readOnly": false,
      #|              "system": false,
      #|              "default": null,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            },
      #|            {
      #|              "name": "reason",
      #|              "type": "text",
      #|              "required": true,
      #|              "primary": false,
      #|              "readOnly": false,
      #|              "system": false,
      #|              "default": null,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            },
      #|            {
      #|              "name": "applicant",
      #|              "type": "ref",
      #|              "required": true,
      #|              "primary": false,
      #|              "readOnly": false,
      #|              "system": false,
      #|              "default": null,
      #|              "target": "User",
      #|              "labelField": "id",
      #|              "valueField": "id"
      #|            },
      #|            {
      #|              "name": "status",
      #|              "type": "state",
      #|              "required": false,
      #|              "primary": false,
      #|              "readOnly": false,
      #|              "system": false,
      #|              "default": null,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            },
      #|            {
      #|              "name": "createdAt",
      #|              "type": "datetime",
      #|              "required": false,
      #|              "primary": false,
      #|              "readOnly": false,
      #|              "system": true,
      #|              "default": null,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            },
      #|            {
      #|              "name": "updatedAt",
      #|              "type": "datetime",
      #|              "required": false,
      #|              "primary": false,
      #|              "readOnly": false,
      #|              "system": true,
      #|              "default": null,
      #|              "target": null,
      #|              "labelField": null,
      #|              "valueField": null
      #|            }
      #|          ],
      #|        "constraints": [
      #|            {
      #|              "name": "amountPositive",
      #|              "expr": "amount > 0"
      #|            }
      #|          ],
      #|        "transitions": [
      #|            {
      #|              "name": "submit",
      #|              "from": "draft",
      #|              "to": "submitted",
      #|              "inputs": [
      #|                  {
      #|                    "name": "amount",
      #|                    "kind": "entity-field",
      #|                    "type": "money",
      #|                    "required": true,
      #|                    "readOnly": false,
      #|                    "default": null,
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "reason",
      #|                    "kind": "entity-field",
      #|                    "type": "text",
      #|                    "required": true,
      #|                    "readOnly": false,
      #|                    "default": null,
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  }
      #|                ],
      #|              "guard": "amount > 0"
      #|            },
      #|            {
      #|              "name": "approve",
      #|              "from": "submitted",
      #|              "to": "approved",
      #|              "inputs": [],
      #|              "guard": null
      #|            },
      #|            {
      #|              "name": "reject",
      #|              "from": "submitted",
      #|              "to": "rejected",
      #|              "inputs": [
      #|                  {
      #|                    "name": "rejectReason",
      #|                    "kind": "local",
      #|                    "type": "text",
      #|                    "required": true,
      #|                    "readOnly": false,
      #|                    "default": null,
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  }
      #|                ],
      #|              "guard": null
      #|            }
      #|          ],
      #|        "rules": [
      #|            {
      #|              "name": "canApprove",
      #|              "when": "state == \"submitted\" && user.role == \"manager\""
      #|            }
      #|          ]
      #|      }
      #|    ]
      #|  }
      #|}

    ),
  )
}

///|
test "compile_gui_manifest_from_yaml renders views and actions" {
  let manifest = compile_gui_manifest_from_yaml(sample_schema())
  inspect(
    manifest,
    content=(
      #|{
      #|  "schemaVersion": "domainprocessschema.v1",
      #|  "manifestKind": "gui-manifest",
      #|  "generator": {
      #|      "name": "domainprocessschema.mbt",
      #|      "version": "0.1.0"
      #|    },
      #|  "payload": {
      #|    "entities": [
      #|      {
      #|        "name": "User",
      #|        "label": "ユーザー",
      #|        "states": [],
      #|        "views": [],
      #|        "rules": []
      #|      },
      #|      {
      #|        "name": "ExpenseRequest",
      #|        "label": "経費申請",
      #|        "states": [
      #|            {
      #|              "name": "draft",
      #|              "label": "下書き"
      #|            },
      #|            {
      #|              "name": "submitted",
      #|              "label": "申請中"
      #|            },
      #|            {
      #|              "name": "approved",
      #|              "label": "承認済"
      #|            },
      #|            {
      #|              "name": "rejected",
      #|              "label": "却下"
      #|            }
      #|          ],
      #|        "views": [
      #|            {
      #|              "name": "draft",
      #|              "fields": [
      #|                  {
      #|                    "name": "id",
      #|                    "label": "id",
      #|                    "component": "text",
      #|                    "mode": "hidden",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "amount",
      #|                    "label": "amount",
      #|                    "component": "money",
      #|                    "mode": "editable",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "reason",
      #|                    "label": "reason",
      #|                    "component": "textarea",
      #|                    "mode": "editable",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "applicant",
      #|                    "label": "applicant",
      #|                    "component": "reference-select",
      #|                    "mode": "hidden",
      #|                    "target": "User",
      #|                    "labelField": "id",
      #|                    "valueField": "id"
      #|                  },
      #|                  {
      #|                    "name": "status",
      #|                    "label": "status",
      #|                    "component": "state-badge",
      #|                    "mode": "hidden",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "createdAt",
      #|                    "label": "createdAt",
      #|                    "component": "datetime-picker",
      #|                    "mode": "readonly",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "updatedAt",
      #|                    "label": "updatedAt",
      #|                    "component": "datetime-picker",
      #|                    "mode": "readonly",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  }
      #|                ],
      #|              "actions": [
      #|                  {
      #|                    "name": "submit",
      #|                    "to": "submitted",
      #|                    "inputs": [
      #|                        {
      #|                          "name": "amount",
      #|                          "label": "amount",
      #|                          "kind": "entity-field",
      #|                          "component": "money",
      #|                          "required": true,
      #|                          "target": null,
      #|                          "labelField": null,
      #|                          "valueField": null
      #|                        },
      #|                        {
      #|                          "name": "reason",
      #|                          "label": "reason",
      #|                          "kind": "entity-field",
      #|                          "component": "textarea",
      #|                          "required": true,
      #|                          "target": null,
      #|                          "labelField": null,
      #|                          "valueField": null
      #|                        }
      #|                      ],
      #|                    "enabledWhen": "amount > 0",
      #|                    "role": null
      #|                  }
      #|                ]
      #|            },
      #|            {
      #|              "name": "submitted",
      #|              "fields": [
      #|                  {
      #|                    "name": "id",
      #|                    "label": "id",
      #|                    "component": "text",
      #|                    "mode": "hidden",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "amount",
      #|                    "label": "amount",
      #|                    "component": "money",
      #|                    "mode": "readonly",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "reason",
      #|                    "label": "reason",
      #|                    "component": "textarea",
      #|                    "mode": "readonly",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "applicant",
      #|                    "label": "applicant",
      #|                    "component": "reference-select",
      #|                    "mode": "hidden",
      #|                    "target": "User",
      #|                    "labelField": "id",
      #|                    "valueField": "id"
      #|                  },
      #|                  {
      #|                    "name": "status",
      #|                    "label": "status",
      #|                    "component": "state-badge",
      #|                    "mode": "hidden",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "createdAt",
      #|                    "label": "createdAt",
      #|                    "component": "datetime-picker",
      #|                    "mode": "readonly",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "updatedAt",
      #|                    "label": "updatedAt",
      #|                    "component": "datetime-picker",
      #|                    "mode": "readonly",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  }
      #|                ],
      #|              "actions": [
      #|                  {
      #|                    "name": "approve",
      #|                    "to": "approved",
      #|                    "inputs": [],
      #|                    "enabledWhen": null,
      #|                    "role": "manager"
      #|                  },
      #|                  {
      #|                    "name": "reject",
      #|                    "to": "rejected",
      #|                    "inputs": [
      #|                        {
      #|                          "name": "rejectReason",
      #|                          "label": "rejectReason",
      #|                          "kind": "local",
      #|                          "component": "textarea",
      #|                          "required": true,
      #|                          "target": null,
      #|                          "labelField": null,
      #|                          "valueField": null
      #|                        }
      #|                      ],
      #|                    "enabledWhen": null,
      #|                    "role": "manager"
      #|                  }
      #|                ]
      #|            },
      #|            {
      #|              "name": "approved",
      #|              "fields": [
      #|                  {
      #|                    "name": "id",
      #|                    "label": "id",
      #|                    "component": "text",
      #|                    "mode": "hidden",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "amount",
      #|                    "label": "amount",
      #|                    "component": "money",
      #|                    "mode": "readonly",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "reason",
      #|                    "label": "reason",
      #|                    "component": "textarea",
      #|                    "mode": "readonly",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "applicant",
      #|                    "label": "applicant",
      #|                    "component": "reference-select",
      #|                    "mode": "hidden",
      #|                    "target": "User",
      #|                    "labelField": "id",
      #|                    "valueField": "id"
      #|                  },
      #|                  {
      #|                    "name": "status",
      #|                    "label": "status",
      #|                    "component": "state-badge",
      #|                    "mode": "hidden",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "createdAt",
      #|                    "label": "createdAt",
      #|                    "component": "datetime-picker",
      #|                    "mode": "readonly",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "updatedAt",
      #|                    "label": "updatedAt",
      #|                    "component": "datetime-picker",
      #|                    "mode": "readonly",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  }
      #|                ],
      #|              "actions": []
      #|            },
      #|            {
      #|              "name": "rejected",
      #|              "fields": [
      #|                  {
      #|                    "name": "id",
      #|                    "label": "id",
      #|                    "component": "text",
      #|                    "mode": "hidden",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "amount",
      #|                    "label": "amount",
      #|                    "component": "money",
      #|                    "mode": "readonly",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "reason",
      #|                    "label": "reason",
      #|                    "component": "textarea",
      #|                    "mode": "readonly",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "applicant",
      #|                    "label": "applicant",
      #|                    "component": "reference-select",
      #|                    "mode": "hidden",
      #|                    "target": "User",
      #|                    "labelField": "id",
      #|                    "valueField": "id"
      #|                  },
      #|                  {
      #|                    "name": "status",
      #|                    "label": "status",
      #|                    "component": "state-badge",
      #|                    "mode": "hidden",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "createdAt",
      #|                    "label": "createdAt",
      #|                    "component": "datetime-picker",
      #|                    "mode": "readonly",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  },
      #|                  {
      #|                    "name": "updatedAt",
      #|                    "label": "updatedAt",
      #|                    "component": "datetime-picker",
      #|                    "mode": "readonly",
      #|                    "target": null,
      #|                    "labelField": null,
      #|                    "valueField": null
      #|                  }
      #|                ],
      #|              "actions": []
      #|            }
      #|          ],
      #|        "rules": [
      #|            {
      #|              "name": "canApprove",
      #|              "when": "state == \"submitted\" && user.role == \"manager\""
      #|            }
      #|          ]
      #|      }
      #|    ]
      #|  }
      #|}

    ),
  )
}

///|
fn localized_label_schema() -> String {
  (
    #|entities:
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
    #|    views:
    #|      draft:
    #|        editable:
    #|          - amount
  )
}

///|
test "compile_gui_manifest_from_yaml resolves localized labels" {
  let manifest = compile_gui_manifest_from_yaml(
    localized_label_schema(),
    locale="ja",
  )
  inspect(manifest.contains("\"label\": \"経費申請\""), content="true")
  inspect(manifest.contains("\"label\": \"金額\""), content="true")
  inspect(manifest.contains("\"label\": \"下書き\""), content="true")
}

///|
test "render_runtime_gui_html resolves default locale fallback labels" {
  let runtime = compile_runtime_from_yaml(localized_label_schema())
  let record = validate_record(runtime, "ExpenseRequest", {
      "amount": RuntimeValue::Integer(1200),
    }).record
  let html = render_runtime_gui_html(runtime, record, locale="en")
  inspect(
    html.contains("<title>Expense Request - Draft</title>"),
    content="true",
  )
  inspect(html.contains("Amount"), content="true")
}

///|
test "localized labels without default fall back to original names" {
  let manifest = compile_gui_manifest_from_yaml(
    (
      #|entities:
      #|  ExpenseRequest:
      #|    label:
      #|      ja: 経費申請
      #|    fields:
      #|      id:
      #|        type: id
      #|        primary: true
      #|      amount:
      #|        label:
      #|          ja: 金額
      #|        type: money
      #|        required: true
      #|      status:
      #|        type: state
      #|        initial: draft
      #|    states:
      #|      draft:
      #|        label:
      #|          ja: 下書き
      #|    views:
      #|      draft:
      #|        editable:
      #|          - amount
    ),
    locale="en",
  )
  inspect(manifest.contains("\"label\": \"ExpenseRequest\""), content="true")
  inspect(manifest.contains("\"label\": \"amount\""), content="true")
  inspect(manifest.contains("\"label\": \"draft\""), content="true")
}

///|
test "compile_migration_sql_from_yaml renders up and down migration blocks" {
  let migration_sql = compile_migration_sql_from_yaml(sample_schema())
  inspect(
    migration_sql,
    content=(
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
    content=(
      #|Err(ValidationError(issues=[{code: "UNKNOWN_STATE", severity: Error, target: "schema.entities.ExpenseRequest.transitions.submit", message: "unknown target state submitted", hint: None, context: {}}]))
    ),
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
      #|Err(ValidationError(issues=[{code: "INVALID_EXPR", severity: Error, target: "schema.entities.ExpenseRequest.constraints.bad.expr", message: "unknown identifier path missing", hint: Some("Use a declared field name, `state`, or `user.<attr>` where that context is allowed."), context: {}}]))
    ),
  )
}

///|
test "validate_schema reports invalid expr code for empty rule expression" {
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
    #|    rules:
    #|      empty:
    #|        when: ""
  let result : Result[String, SchemaError] = try? compile_sql_from_yaml(invalid)
  inspect(
    result,
    content=(
      #|Err(ValidationError(issues=[{code: "INVALID_EXPR", severity: Error, target: "schema.entities.ExpenseRequest.rules.empty.when", message: "rule expressions must not be empty", hint: None, context: {}}]))
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
    content=(
      #|Err(ParseError(issues=[{code: "INVALID_YAML_SYNTAX", severity: Error, target: "yaml.line.2", message: "expected a `key: value` mapping entry", hint: None, context: {"line": "2"}}]))
    ),
  )
}
