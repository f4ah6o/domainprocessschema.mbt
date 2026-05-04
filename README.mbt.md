# domainprocessschema.mbt

`f4ah6o/domainprocessschema.mbt` is a MoonBit-first compiler for the declarative
domain/process schema described in issue #1.

The current implementation provides five concrete generated artifacts:

- constrained YAML input
- normalized schema validation
- SQL DDL generation
- migration SQL generation
- API/action manifest generation
- validation manifest generation
- GUI manifest generation
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
- a constrained expression layer for `constraint`, `guard`, and `rule`
- SQL output generation for the database-oriented subset
- migration output generation for initial up/down scripts
- API/action manifest generation for entities and transitions
- validation manifest generation for field/constraint/rule metadata
- GUI manifest generation for views, controls, and actions

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
