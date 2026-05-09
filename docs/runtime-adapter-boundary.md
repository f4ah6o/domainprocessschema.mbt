# Runtime Adapter Boundary

This document defines the v1 boundary between the in-memory runtime core and
host-provided adapters.

The runtime core remains a MoonBit library. It validates records, evaluates
guards/rules, projects GUI state, and applies transitions in memory. Durable
storage, actor lookup, reference lookup, clocks, ID generation, transaction
management, audit delivery, and HTTP routing belong to the host.

## Core Responsibility

The runtime core owns deterministic schema behavior:

- compile validated schema input into runtime structures
- validate record payloads with defaults, required checks, constraints, and
  structured diagnostics
- list available transitions for a record, state, and actor
- evaluate rules against the same runtime context
- project GUI state from schema views, current values, state, and available
  actions
- apply a transition to an already-loaded record in memory

The runtime core must not own:

- HTTP server setup, routes, middleware, or authentication
- durable record storage
- cross-record reference queries
- user directory lookup
- wall-clock access
- global ID generation
- database transactions
- audit log persistence or delivery

This keeps `domainprocessschema.mbt` usable from CLI, WASM demo, tests, and App
Server hosts without binding it to one deployment architecture.

## Adapter Roles

`RecordLoader` loads the current durable record and maps the host identifier to
the record payload expected by the validated schema.

`RecordSaver` persists the record returned by a successful runtime mutation.
Conflict detection, optimistic locking, retry policy, and backend-specific write
semantics stay in the host.

`ReferenceResolver` resolves `ref` options and existence checks for referenced
entities. The schema and manifests define `target`, `labelField`, and
`valueField`; the host owns lookup, filtering, pagination, permissions, and
durable catalog storage.

`ActorResolver` converts request/session identity into the runtime actor shape.
The runtime consumes stable role and `user.<attribute>` values. Authentication
and user directory policy stay outside the runtime.

`ClockProvider` supplies effective timestamps for host workflows. The runtime
does not read the wall clock directly.

`IdGenerator` supplies IDs for records, audit events, and host workflow objects.
The runtime does not require UUID, ULID, database sequence, or any other format.

`TransactionBoundary` wraps host operations that need durable consistency, such
as load, runtime mutation, save, and audit append.

`AuditSink` receives host-normalized audit events. The event contract is defined
in `docs/audit-event-manifest.md`; delivery, retention, redaction, and failure
policy are host responsibilities.

## Read Flow

A read-only host flow is:

1. compile or load the validated runtime
2. resolve the actor
3. load the current record
4. optionally resolve reference options
5. call `validate_record`, `list_transitions`, `evaluate_rules`, or `project_gui`
6. return a host response or session snapshot

This flow does not require a transaction unless the host storage layer needs a
consistent read boundary.

## Mutation Flow

A mutating host flow is:

1. resolve the actor
2. start a host transaction boundary when durable consistency is required
3. load the current record
4. call the runtime mutation, such as `apply_transition`
5. save the returned record
6. normalize a `transition.applied` audit event
7. append that event through `AuditSink`
8. commit the host transaction
9. return the host response

If the runtime rejects the mutation, the host may normalize a
`transition.rejected` audit event with the returned structured diagnostics and
write it without changing the record.

The runtime decides whether the mutation is valid for the schema, state, actor,
guards, and input payload. The host decides whether and when the result becomes
durable.

## Diagnostics

Adapter failures should use the same structured diagnostic shape as parser,
validator, and runtime failures:

- `code`
- `severity`
- `target`
- `message`
- `hint`
- `context`

Suggested host diagnostic codes include:

- `RECORD_NOT_FOUND`
- `REFERENCE_LOOKUP_FAILED`
- `ACTOR_UNAUTHORIZED`
- `CLOCK_UNAVAILABLE`
- `ID_GENERATION_FAILED`
- `PERSISTENCE_CONFLICT`
- `AUDIT_WRITE_FAILED`

The runtime does not need to know backend-specific failure details. The host
wraps adapter failures before composing the final response.

## HTTP And App Server Boundary

The runtime core must not embed an HTTP server. App Server support is a host
layer that maps transport requests to runtime functions and adapters.

This means:

- REST, WebSocket, MCP, or App Server protocol handlers live outside the runtime
  core
- approval policy and durable session ownership live in the host
- session snapshots may include runtime projections, but the runtime does not
  own session persistence
- browser demos may keep local state for prototyping, but that local state is not
  the target durable architecture

The App Server session snapshot, tool split, approval boundary, artifact export,
and preview/navigation vocabulary are defined in
`docs/app-server-schema-runtime-session.md`.

## Non-Goals

The v1 adapter boundary does not define:

- a concrete adapter trait API
- D1, SQLite, PostgreSQL, kintone, or filesystem storage implementation
- HTTP route shape
- authentication protocol
- async reference lookup request/response format
- audit delivery guarantees
- event sourcing semantics
