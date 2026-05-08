# Define Codex App Server schema and runtime session contract for domainprocessschema.mbt

Created: 2026-05-09
Model: GPT-5 Codex

## Background

`domainprocessschema.mbt` currently exposes a strong but mostly stateless demo
surface:

- `compile`
- `runtime-preview`
- `apply-transition`
- browser-side graph/inspector state

The runtime core is intentionally a library and should stay that way, as already
aligned with the runtime adapter boundary direction in this repo. The current
editor flow, however, still depends on browser-side source ownership and a
stateless Worker API.

As of 2026-05-09, Codex App Server is the preferred rich-client integration
surface for Codex. The App Server model assumes resumable sessions, server
notifications, approval requests, and tool-oriented mutation flows. A schema
editor plus runtime inspector fits that model better than a browser-local demo
does.

This repo needs a durable App Server-facing `schema + runtime session` contract
so a future shared repo and VS Code extension can interact with the runtime as a
real session rather than as a stateless HTTP demo.

## Proposal

Promote the current Worker demo into an App Server-oriented session model.

- Treat schema source, selection state, actor context, runtime record state, and
  diagnostics as durable session state.
- Keep runtime core as a library and do not move HTTP or UI concerns into core.
- Redefine compile, preview, graph/inspector edits, and transition application
  as App Server tools operating against a resumable session.
- Make schema editor + runtime inspector the primary target UX for the future
  shared repo and VS Code extension.

The repo-local responsibility is to define the domain session contract and its
approval boundaries. The future shared repo will own the actual client.

## Session Snapshot

The domainprocessschema session snapshot should include at least:

- YAML source
- normalized compile result
- selected entity
- selected state, view, or transition
- actor role
- current record payload
- runtime GUI view projection
- available transitions with enablement status
- graph nodes and graph relationships needed by the client
- locale
- diagnostics
- last successful compile or transition result metadata

## Read-only Tools

The read-only App Server tools should cover at least:

- read active session snapshot
- compile current source without mutating selection
- inspect normalized schema output
- inspect runtime GUI projection
- list available transitions
- inspect diagnostics
- inspect graph structure for the active entity or state

These operations should not require approval.

## Mutating Tools

The mutating App Server tools should cover at least:

- replace source
- apply inspector edit
- select entity, state, transition, or view
- set actor role
- update draft record payload
- apply transition
- change locale
- reset session to a known example or baseline

These are session mutations first, not browser widget actions.

## Approval-required Actions

Approval policy should follow the shared cross-repo rule:

- transition execution is approval-required when it is modeled as a durable
  state change or may trigger downstream side effects
- destructive reset actions are approval-required
- pure compile, preview, search, and inspect actions are not approval-required

The contract should make the approval boundary explicit even if the initial
implementation still runs against an in-memory runtime.

## Import / Export Artifact

The contract should define import/export artifacts for:

- source YAML import/export
- normalized schema export
- runtime session snapshot export
- diagnostic report export suitable for review or automation

These artifacts should be usable by the future shared repo without any
assumption that the source lives only in browser state.

## Diagnostic Shape

This repo already has active work on structured diagnostics. The App Server
contract should adopt a stable shape with:

- code
- severity
- target
- message
- hint
- context

The session contract should assume compile, validation, and runtime failures are
all emitted in that structured form.

## Selection / Focus State

The contract should expose:

- selected entity
- selected state
- selected transition
- selected inspector node
- active panel or focus mode when needed for restoration

This is necessary for session resume and for a future VS Code client to restore
the same editing context.

## Preview / Navigation State

The contract should expose runtime preview as session state, not only as
HTML-in-an-iframe output.

It should support:

- current preview mode
- active entity/runtime route
- locale-dependent preview state
- active record + transition context
- preview refresh triggers after compile or transition

## Shared Repo Dependency

This issue assumes a new shared repo will be created before implementation
starts.

That shared repo is expected to own:

- the reusable Codex App Server client
- the VS Code extension shell
- shared approval UX
- cross-repo session restoration and notification handling

`domainprocessschema.mbt` remains responsible for the domain-specific session
contract and for keeping runtime core independent from HTTP and UI layers.

## Acceptance Criteria

- [ ] The current stateless demo surface is redefined as a durable
      `schema + runtime session` contract.
- [ ] A session snapshot shape is defined that includes source, normalized
      result, graph/inspector selection, actor, record, runtime view, and
      diagnostics.
- [ ] Read-only and mutating tools are listed separately.
- [ ] Transition execution has an explicit approval boundary.
- [ ] The issue states that runtime core stays a library and does not absorb
      HTTP or UI concerns.
- [ ] The issue is suitable as specification input for a future shared repo and
      VS Code schema editor/runtime inspector client.

## Non-goals

- Implementing persistent storage adapters in this issue
- Embedding an HTTP server into runtime core
- Implementing the shared repo or VS Code extension here
- Preserving the current browser-local Worker demo as the primary architecture

## Rationale

`domainprocessschema.mbt` is already close to a compelling agent-facing
application: it has a schema compiler, structured runtime state, graph-like UI,
diagnostics, and transition semantics. What it lacks is a durable session model
that App Server clients can resume and mutate coherently.

Writing that contract now keeps the runtime boundary clean while giving the
future shared repo a clear interface for schema editing, preview inspection, and
transition-driven workflow review.
