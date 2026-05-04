# domainprocessschema.mbt

`f4ah6o/domainprocessschema.mbt` is a MoonBit-first compiler for the declarative
domain/process schema described in issue #1.

The current implementation provides five concrete generated artifacts and one
in-memory runtime surface:

- constrained YAML input
- normalized schema validation
- SQL DDL generation
- migration SQL generation
- API/action manifest generation
- validation manifest generation
- GUI manifest generation
- in-memory API/workflow runtime generation target
- CLI support for compiling a schema file

The GitHub repository name contains `.mbt`, but the MoonBit module name is
`f4ah6o/domainprocessschema_mbt` because MoonBit module names cannot contain `.`.

## Status

Phase 1 supports:

- `entities`
- `fields`
- `relations`
- `constraints`
- `states`
- `transitions`
- `rules`
- `views`
- `storage`

The validator now checks:

- field/relation/state/transition/view references
- transition-local input declarations for actions such as `rejectReason`
- a constrained expression layer for `constraint`, `guard`, and `rule`
- SQL output generation for the database-oriented subset
- migration output generation for initial up/down scripts
- API/action manifest generation for entities and transitions
- validation manifest generation for field/constraint/rule metadata
- GUI manifest generation for views, controls, and actions

The runtime now supports:

- building an in-memory runtime from validated `Schema`
- validating record payloads with defaults, required checks, and constraints
- listing available transitions for the current record + actor
- evaluating rules for the current record + actor
- projecting a runtime GUI view from current state, actions, and rule statuses
- applying transitions in memory with role / guard enforcement

The first runtime slice is intentionally limited to an in-memory engine:

- no HTTP server
- no persistence adapter
- no GUI renderer

## YAML scope

The current parser intentionally supports a **small YAML subset**:

- mappings via `key: value` / `key:`
- block sequences via `- item`
- inline string arrays via `[a, b, c]`
- bare scalar values

Quoted scalars, anchors, aliases, and advanced YAML features are out of scope
for phase 1.

## Expression scope

`constraint`, `guard`, and `rule` use a small expression language with:

- identifier paths like `amount`, `state`, `user.role`
- string / number / boolean literals
- `&&`, `||`, `!`
- `==`, `!=`, `>`, `>=`, `<`, `<=`
- parentheses

## Quick start

```bash
just check
just test
moon run cmd/main -- examples/expense_request.yaml
moon run cmd/main -- migration-sql examples/expense_request.yaml
moon run cmd/main -- api-manifest examples/expense_request.yaml
moon run cmd/main -- validation-manifest examples/expense_request.yaml
moon run cmd/main -- gui-manifest examples/expense_request.yaml
```

## Runtime API

The public MoonBit API now includes:

- `build_runtime`
- `compile_runtime_from_yaml`
- `validate_record`
- `list_transitions`
- `evaluate_rules`
- `project_gui`
- `apply_transition`

The runtime uses the validated `Schema` and `Expr` AST directly instead of
parsing the generated JSON manifests back into memory.

## Transition-local inputs

Issue #1 examples imply that some transition inputs are not persisted entity
fields. This repository now supports that explicitly:

```yaml
transitions:
  reject:
    from: submitted
    to: rejected
    role: manager
    input:
      - rejectReason
    inputs:
      rejectReason:
        type: text
```

`input` remains the ordered list of action input names, while `inputs` holds
typed transition-local definitions for names that are not entity fields.

## Example

Input:

```yaml
entities:
  ExpenseRequest:
    label: 経費申請
    fields:
      id:
        type: id
        primary: true
      amount:
        type: money
        required: true
      status:
        type: state
        initial: draft
    states:
      draft:
        label: 下書き
```

Output:

```sql
CREATE TABLE expense_requests (
  id TEXT PRIMARY KEY NOT NULL,
  amount INTEGER NOT NULL,
  status TEXT DEFAULT 'draft'
);
```
