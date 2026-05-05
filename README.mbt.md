# domainprocessschema.mbt

`f4ah6o/domainprocessschema.mbt` is a MoonBit-first compiler for the declarative
domain/process schema described in issue #1.

The current implementation provides five concrete generated artifacts, one
static HTML renderer, and one in-memory runtime surface:

- constrained YAML input
- normalized schema validation
- SQL DDL generation
- migration SQL generation
- API/action manifest generation
- validation manifest generation
- GUI manifest generation
- static HTML preview generation from GUI manifest / runtime state
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
- every declared state has a matching view, and every view name matches a state
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
- rendering static HTML from GUI manifest JSON
- rendering stateful HTML from runtime GUI projection
- applying transitions in memory with role / guard enforcement

The first runtime slice is intentionally limited to a library/static-preview
engine:

- no HTTP server
- no persistence adapter
- no browser-side interactivity

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
moon run cmd/main -- gui-html examples/expense_request.yaml
```

## Runtime API

The public MoonBit API now includes:

- `build_runtime`
- `compile_runtime_from_yaml`
- `validate_record`
- `list_transitions`
- `evaluate_rules`
- `project_gui`
- `render_gui_html_from_manifest`
- `compile_gui_html_from_yaml`
- `render_runtime_gui_html`
- `apply_transition`

`gui-html` is the first issue #2 delivery: it consumes the GUI manifest shape and
renders a semantic static HTML document with state badge, visible fields,
action buttons, action-local inputs, and rule/action availability hints.

## MoonBit WASM demo

Issue #2 is broader than the static HTML proof. This branch also adds a
**MoonBit WASM browser demo** under `wasm/demo/`.

It keeps the current HTML renderer as a WASM-exported preview engine, and now
also exposes a small browser-driven runtime session:

- `render_manifest_preview(yaml)` exports the schema-only HTML preview
- `render_runtime_preview(yaml, scenario)` exports stateful runtime previews
- `create_demo_session(yaml, actor_role)` builds a live runtime session from the
  example schema and draft payload
- `session_snapshot_json(session)` lists current state and available transitions
- `apply_session_transition(session, name, input_json)` applies a transition and
  returns the updated session
- `wasm/demo/index.html` loads the built `.wasm`, fetches
  `examples/expense_request.yaml`, and renders the returned full HTML document
  into an `<iframe srcdoc>`
- the host page now keeps the current `DemoSession` in JS, shows available
  transitions for the chosen actor role, collects action input values, and
  rerenders after each transition
- the host page also parses `validation_manifest`, so each action input can show
  schema-derived hints such as entity-field/local kind, type, target/default
  metadata, and read-only/system flags
- failed transition attempts are now preserved per action card, including the
  last submitted payload, so browser-side retry/debugging does not depend only
  on the global status area
- the host page still exposes the YAML source as a textarea, so schema edits and
  compile / validation errors can be exercised directly in the browser demo
- the host page chrome supports a minimal `en` / `ja` switch, and schema-level
  entity / field / state labels now follow the same locale when YAML uses a
  locale-keyed label map

Schema labels stay backward compatible:

```yaml
entities:
  ExpenseRequest:
    label:
      default: Expense Request
      ja: 経費申請
    fields:
      amount:
        label:
          default: Amount
          ja: 金額
        type: money
    states:
      draft:
        label:
          default: Draft
          ja: 下書き
```

The locale resolution order is:

1. exact locale match
2. base language match (`ja-jp` -> `ja`)
3. `default`
4. existing fallback string/name

Build and test it with:

```bash
just wasm-demo-test
just wasm-demo-build
python3 -m http.server
# then open /wasm/demo/index.html
```

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

If a transition-local input omits `required`, it is treated as:

- `true` when no `default` is present
- `false` when a `default` is present

## Example

Input:

```yaml
entities:
  ExpenseRequest:
    label:
      default: Expense Request
      ja: 経費申請
    fields:
      id:
        type: id
        primary: true
      amount:
        label:
          default: Amount
          ja: 金額
        type: money
        required: true
      status:
        label:
          default: Status
          ja: 状態
        type: state
        initial: draft
    states:
      draft:
        label:
          default: Draft
          ja: 下書き
```

Output:

```sql
CREATE TABLE expense_requests (
  id TEXT PRIMARY KEY NOT NULL,
  amount INTEGER NOT NULL,
  status TEXT DEFAULT 'draft'
);
```
