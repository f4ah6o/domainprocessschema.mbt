# Audit Event Manifest

This document defines the v1 event contract for recording transition outcomes.
It is a host-facing contract, not an event-sourcing implementation.

The runtime core still applies transitions in memory and reports structured
diagnostics through `RuntimeError`. A host can convert that outcome into one of
the event shapes below before writing to an audit sink, rendering a history UI,
or keeping a replay/debug trace.

## Event Kinds

The v1 contract defines two transition event kinds:

- `transition.applied`
- `transition.rejected`

`transition.applied` records a transition that passed runtime validation and
returned a next record.

`transition.rejected` records a transition attempt that failed before producing a
next record. Rejections include structured diagnostics so a host can show the
same reason in audit logs, UI history, and debugging tools.

## Common Fields

Both event kinds share these top-level fields:

- `eventVersion`: fixed to `domainprocessschema.audit.v1`
- `kind`: `transition.applied` or `transition.rejected`
- `eventId`: host-generated stable event identifier
- `occurredAt`: host-provided timestamp
- `entity`: schema entity name
- `recordId`: stable record identifier from the host record
- `transition`: transition name requested by the actor
- `from`: state before the transition attempt
- `to`: target state declared by the transition, or `null` if the transition was
  unknown
- `actor`: actor snapshot used for runtime evaluation
- `input`: submitted transition input payload
- `result`: outcome-specific payload
- `issues`: structured diagnostics; empty for success
- `context`: host metadata such as request ID, session ID, tenant, or trace ID

The host owns `eventId`, `occurredAt`, `recordId`, and `context`. The runtime
outcome supplies entity, transition, state, input, result, and diagnostics.

## Actor Shape

`actor` is a stable snapshot, not a live user reference:

```json
{
  "id": "user-2",
  "role": "manager",
  "attributes": {
    "department": "finance"
  }
}
```

`id` may be `null` when the host only has a role or system actor. `attributes`
must contain the values that were available as `user.<attribute>` during guard
and rule evaluation.

## Applied Event

```json
{
  "eventVersion": "domainprocessschema.audit.v1",
  "kind": "transition.applied",
  "eventId": "evt_01",
  "occurredAt": "2026-05-09T14:00:00Z",
  "entity": "ExpenseRequest",
  "recordId": "exp-001",
  "transition": "approve",
  "from": "submitted",
  "to": "approved",
  "actor": {
    "id": "user-2",
    "role": "manager",
    "attributes": {}
  },
  "input": {},
  "result": {
    "state": "approved",
    "record": {
      "id": "exp-001",
      "status": "approved"
    }
  },
  "issues": [],
  "context": {
    "requestId": "req-001"
  }
}
```

`result.state` is the resulting state after the transition. `result.record` may
be a full persisted record, a redacted record, or a host-defined record summary.
The host must document which form it writes.

## Rejected Event

```json
{
  "eventVersion": "domainprocessschema.audit.v1",
  "kind": "transition.rejected",
  "eventId": "evt_02",
  "occurredAt": "2026-05-09T14:01:00Z",
  "entity": "ExpenseRequest",
  "recordId": "exp-001",
  "transition": "approve",
  "from": "draft",
  "to": "approved",
  "actor": {
    "id": "user-1",
    "role": "employee",
    "attributes": {}
  },
  "input": {},
  "result": {
    "state": "draft",
    "record": null
  },
  "issues": [
    {
      "code": "TRANSITION_UNAVAILABLE",
      "severity": "error",
      "target": "runtime.ExpenseRequest.transitions.approve",
      "message": "transition approve is not available from state draft",
      "hint": null,
      "context": {
        "from": "draft"
      }
    }
  ],
  "context": {
    "requestId": "req-002"
  }
}
```

`issues` uses the same structured diagnostic shape as parser, validator, and
runtime failures: `code`, `severity`, `target`, `message`, `hint`, and
`context`.

For rejected events, `result.state` is the unchanged source state and
`result.record` is `null` unless the host chooses to include a redacted current
record snapshot.

## Audit Sink Connection

An audit sink receives events after the host has normalized runtime success or
failure into this shape.

For a durable mutation, the host should write `transition.applied` in the same
transaction boundary as the record update when the backend supports it. If audit
write fails after a successful record write, the host must surface that as a host
diagnostic; the runtime core does not retry or roll back audit delivery.

For a rejected mutation, the host may write `transition.rejected` without a
record update. This is useful for access-denied traces, invalid input debugging,
and explaining UI history.

## History UI And Debugging

A history UI can group events by `entity` + `recordId`, display `from` -> `to`,
show actor and timestamp, and expand `input`, `result`, and `issues`.

Debug/replay tools may use the event sequence to reconstruct attempted
transitions, but v1 does not guarantee event sourcing. The event payload is an
audit record, not the canonical source of truth for rebuilding records.

## Non-Goals

The v1 contract does not define:

- event sourcing semantics
- durable storage backend
- delivery guarantees
- retention policy
- redaction policy
- async export route
- runtime adapter implementation
