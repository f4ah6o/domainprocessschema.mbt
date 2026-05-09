# App Server Schema Runtime Session Contract

Created: 2026-05-10

This document defines the host-facing App Server contract for a durable
`schema + runtime` session. It turns the current browser editor and Worker demo
surface into an explicit session model without moving HTTP, persistence, UI, or
approval policy into the MoonBit runtime core.

## Ownership Boundary

`domainprocessschema.mbt` remains a deterministic schema and runtime library. It
parses and validates YAML, generates manifests, evaluates expressions, projects
runtime GUI state, lists transitions, and applies transitions to an in-memory
record.

An App Server host owns:

- durable session storage
- transport handlers such as HTTP, WebSocket, MCP, or VS Code extension RPC
- actor identity and authorization policy before runtime evaluation
- approval proposal, decision, and resume flow
- persistence adapters, transaction boundaries, reference lookup, audit sink,
  clock, and ID generation
- browser or editor UI

The runtime core must not embed an HTTP server, persistence adapter, VS Code
host, preview iframe owner, or browser demo state manager.

## Current Surface Used As Evidence

The browser prototype already exposes the parts that a durable host needs:

- `wasm/demo/editor_api.mbt` provides stateless compile, runtime preview, and
  transition application calls for the editor Worker API.
- `wasm/demo/session_json.mbt` serializes current runtime view fields, actions,
  actor role, reference catalog, and structured diagnostics for browser state.
- The browser editor owns source YAML, current record JSON, selection, locale,
  and retry state.

For App Server, those browser-owned values become durable session fields. The
Worker demo remains a reference prototype, not the target architecture.

## Session Snapshot

The durable snapshot has these required top-level sections:

- `source`
- `selection`
- `actor`
- `record`
- `compile`
- `runtime`
- `graph`
- `locale`
- `lastAction`

Example:

```json
{
  "source": {
    "yaml": "entities:\n  ExpenseRequest:\n    ..."
  },
  "selection": {
    "entity": "ExpenseRequest",
    "state": "submitted",
    "transition": "approve",
    "inspectorNode": "views.submitted",
    "focusMode": "runtime-preview"
  },
  "actor": {
    "role": "manager",
    "attributes": {
      "role": "manager"
    }
  },
  "record": {
    "entity": "ExpenseRequest",
    "state": "submitted",
    "payload": {
      "amount": 1200,
      "reason": "client visit"
    }
  },
  "compile": {
    "normalizedSchema": {},
    "apiManifest": {},
    "validationManifest": {},
    "guiManifest": {},
    "diagnostics": []
  },
  "runtime": {
    "view": {},
    "availableTransitions": [
      {
        "name": "approve",
        "enabled": true,
        "reason": null
      }
    ],
    "previewHtml": "<!doctype html>..."
  },
  "graph": {
    "nodes": [],
    "edges": []
  },
  "locale": "ja",
  "lastAction": {
    "kind": "compile_current_source",
    "completedAt": "2026-05-10T00:00:00Z",
    "diagnostics": []
  }
}
```

`source.yaml` is the editable source of truth. `compile.normalizedSchema` is the
validated canonical output from `generate_normalized_schema`; it is not a second
source of truth. `runtime.view`, `runtime.availableTransitions`, and
`runtime.previewHtml` are derived from the current schema, actor, record, and
locale.

## Tool Classes

Tools are split into read-only and mutating tools. Approval-required tools are a
subset of mutating tools; they are never a third independent category.

### Read-only Tools

Read-only tools do not change durable session state and never require approval:

| Tool | Input | Output |
| ---- | ----- | ------ |
| `get_session_snapshot` | none | `SessionSnapshot` |
| `compile_current_source` | none | `{ normalizedSchema, apiManifest, validationManifest, guiManifest, diagnostics }` |
| `get_runtime_view` | none | `{ view, diagnostics }` |
| `list_available_transitions` | none | `{ transitions }` |
| `get_graph` | none | `{ nodes, edges }` |
| `get_diagnostics` | none | `{ diagnostics }` |

`compile_current_source` returns the same generated artifact fields that appear
under the snapshot `compile` section. The tool itself is read-only: a host that
wants to persist those returned artifacts back into the durable session must do
so through an explicit mutating refresh operation or a documented host-owned
refresh policy.

### Mutating Tools

Mutating tools change the durable session snapshot or return an approval
proposal before changing it:

| Tool | Input | Output |
| ---- | ----- | ------ |
| `replace_source` | `{ yaml }` | `{ diagnostics, snapshot }` |
| `apply_inspector_edit` | `{ path, value }` | `{ snapshot }` |
| `select_entity` | `{ name }` | `{ selection, snapshot }` |
| `select_state` | `{ name }` | `{ selection, snapshot }` |
| `select_transition` | `{ name }` | `{ selection, snapshot }` |
| `set_actor_role` | `{ role }` | `{ actor, snapshot }` |
| `update_record_payload` | `{ payload }` | `{ record, diagnostics, snapshot }` |
| `apply_transition` | `{ name, transitionInput }` | `{ snapshot }` after approval, or `{ proposal }` before approval |
| `set_locale` | `{ locale }` | `{ locale, snapshot }` |
| `reset_session` | `{ example? }` | `{ proposal }` before approval, `{ snapshot }` after approval |

The host may implement these as direct function calls, RPC methods, or App
Server tools. The contract is the input/output vocabulary, not the transport.

## Approval Boundary

The approval boundary is fixed before persistence implementation:

- `apply_transition` is approval-required when it would commit a durable state
  change.
- `reset_session` is approval-required because it discards current source,
  selection, actor, record, compile, runtime, graph, locale, and last-action
  state.
- `reset_session.example` is optional. When omitted, the host resets to its
  configured empty/default session.
- `replace_source`, inspector edits, selection updates, actor role changes,
  record payload updates, and locale changes are mutating but not approval-
  required by default.
- `compile_current_source`, runtime preview, graph read, transition listing, and
  diagnostics read are approval-free.

An approval proposal should describe the tool name, input, expected snapshot
diff at a human-readable level, and diagnostics that would block or warn. The
host owns proposal persistence, decision capture, and resume.

## Diagnostics

All compile, validation, runtime, adapter, and approval failures use the shared
structured diagnostic shape:

```json
{
  "code": "UNKNOWN_STATE",
  "severity": "error",
  "target": "schema.entities.ExpenseRequest.transitions.submit",
  "message": "unknown target state submitted",
  "hint": "define submitted in states",
  "context": {}
}
```

Required fields are:

- `code`
- `severity`
- `target`
- `message`
- `hint`
- `context`

`severity` is one of `error`, `warning`, or `info`. `hint` may be `null`.
`context` is an object reserved for machine-readable host or runtime details.

## Artifact Envelopes

Session artifact export uses JSON envelopes with stable top-level names:

- `sourceYaml`: source YAML export
- `normalizedSchema`: generated normalized schema export
- `sessionSnapshot`: durable runtime session snapshot export
- `diagnostics`: diagnostics export

The contract does not define binary packaging. A host can package these
envelopes into files, clipboard payloads, workspace exports, or extension
messages without changing the runtime core.

## Preview And Navigation State

Preview state is session state, not only an iframe string:

- selected entity, state, transition, and inspector node
- active panel or focus mode
- current preview mode
- active entity/runtime route
- locale-dependent labels
- current record and transition input context
- refresh trigger after compile, source replacement, record update, locale
  change, or transition application

`runtime.previewHtml` may be cached for browser convenience, but
`runtime.view` and diagnostics are the primary machine-readable surfaces.

## Compatibility

This contract depends on the lower-level documents:

- `docs/schema-contract-v1.md`
- `docs/runtime-adapter-boundary.md`
- `docs/transition-semantics-v1.md`
- `docs/expression-language-v1.md`
- `docs/reference-lookup-contract.md`
- `docs/audit-event-manifest.md`

Future App Server hosts can add optional fields under existing sections, but
they should not remove or rename the required top-level snapshot sections
without a versioned contract update.
