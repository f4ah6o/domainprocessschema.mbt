# domainprocessschema.mbt

`f4ah6o/domainprocessschema.mbt` is a MoonBit-first compiler for the declarative
domain/process schema described in issue #1.

Phase 1 implements a single vertical slice:

- constrained YAML input
- normalized schema validation
- SQL DDL generation
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

The validator already checks references and workflow consistency, but SQL output
currently only materializes the database-oriented subset (fields, foreign keys,
checks, unique keys, and indexes).

## YAML scope

The current parser intentionally supports a **small YAML subset**:

- mappings via `key: value` / `key:`
- block sequences via `- item`
- inline string arrays via `[a, b, c]`
- bare scalar values

Quoted scalars, anchors, aliases, and advanced YAML features are out of scope
for phase 1.

## Quick start

```bash
just check
just test
moon run cmd/main -- examples/expense_request.yaml
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
