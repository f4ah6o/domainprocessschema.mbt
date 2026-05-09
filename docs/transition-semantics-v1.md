# Transition Semantics v1

Created: 2026-05-10

This document fixes the v1 behavior of runtime transitions. It describes the
in-memory runtime contract only. Persistence, transaction boundaries, HTTP
routes, App Server transport, and GUI renderer UX remain host-layer concerns.

## Scope

The runtime transition surface is:

- `list_transitions(runtime, record, actor)`
- `apply_transition(runtime, record, transition_name, input, actor)`
- transition data compiled from `Schema.entities[*].transitions`
- structured `Diagnostic` values returned in transition status or
  `RuntimeError::TransitionRejected`

The runtime consumes already-loaded records and an already-resolved
`RuntimeActor`. It does not authenticate the actor, load or save records, append
audit events, or choose a browser presentation.

## Transition Fields

`from` is the required source state. The runtime reads the entity state field
from the normalized current record. If the current state differs from `from`,
the transition is unavailable in `list_transitions` and rejected by
`apply_transition` with `STATE_MISMATCH`.

`to` is the target state. After all validation, input, role, and guard checks
pass, `apply_transition` writes `to` to the state field and validates the final
record once more. The schema compiler is responsible for rejecting transition
targets that do not exist.

`role` is optional. A transition without `role` has no role gate. A transition
with `role` requires `actor.attributes["role"]` to be a text value that exactly
matches the configured role. Missing role, non-text role, or a different role
all produce `ROLE_DENIED`.

`guard` is optional. The runtime evaluates the guard after transition entity
inputs have been merged into the current record and normalized by record
validation. The guard sees the same `actor` passed to the runtime function. A
false guard produces `GUARD_REJECTED`; expression evaluation failures are
returned as structured expression diagnostics.

`input` is the ordered action input list. Each name is resolved as either an
entity field input or a transition-local input:

- entity field input values are merged into the record payload before
  validation and may be persisted by a host after the transition succeeds
- transition-local input values are validated for the action but are not stored
  in `RuntimeRecord.values`
- omitted transition-local inputs use their default when one exists
- omitted or `Null` required inputs produce `INVALID_TRANSITION_INPUT`
- input keys not listed by the transition produce `INVALID_TRANSITION_INPUT`

## Evaluation Order

`apply_transition` follows this order:

1. Find the entity from `record.entity_name` and find the named transition.
2. Validate transition inputs, separating entity field payload from
   transition-local values.
3. Validate the current record plus entity field payload.
4. Check `from` against the normalized state field.
5. Check `role` against `actor.attributes["role"]` when a role is configured.
6. Evaluate `guard` against the normalized record values and actor.
7. Reject with `RuntimeError::TransitionRejected` if any issue was collected.
8. Write `to` into the state field.
9. Validate the final record and return it.

The runtime accumulates diagnostics from steps 2 through 6 before rejecting.
This means input, record validation, state, role, and guard issues may appear
together in one rejected transition result.

`list_transitions` is read-only. It validates the current record and returns a
status for every compiled transition. When record validation fails, those issues
are copied to each transition status and transition-specific checks are skipped.
When the record is valid, each status reports whether that transition is
currently available for the given state and actor.

## Failure Diagnostics

Transition-related diagnostics use the shared structured diagnostic shape from
`docs/schema-contract-v1.md`.

| Code | Meaning |
| --- | --- |
| `STATE_MISMATCH` | The current state field is text, but does not match `transition.from`. |
| `UNKNOWN_STATE` | The entity has no state field, the state value is missing, or the state name is not declared. |
| `ROLE_DENIED` | The transition requires a role and the actor role is missing, non-text, or different. |
| `GUARD_REJECTED` | The guard expression evaluated to false. |
| `INVALID_TRANSITION_INPUT` | A transition input is missing, null when required, invalid for its type, or not declared on the transition. |
| `INVALID_RUNTIME_INPUT` | Runtime payload or state field data is structurally invalid. |
| `UNKNOWN_FIELD` | Runtime payload includes a field that is not declared on the entity. |
| `REQUIRED_FIELD_MISSING` | Record validation found a required entity field with no normalized value. |
| `CONSTRAINT_FAILED` | An entity constraint evaluated to false during record validation. |
| `INVALID_EXPR` | Expression parsing or evaluation failed for a guard, constraint, or rule. |

## Rule And View Boundary

Rules and views do not authorize state changes.

Rules are evaluated as active or inactive runtime facts. A rule can inform UI or
host policy, but it blocks a transition only when the same condition is encoded
as an entity constraint or transition guard.

Views project fields and available actions for a state. A hidden or omitted view
action is presentation data, not an authorization decision. Hosts must call the
runtime transition functions to enforce `from`, `role`, `guard`, and input
semantics.

## Implementation Mapping

The current runtime implementation maps to this contract as follows:

| Contract area | Runtime implementation |
| --- | --- |
| Record payload normalization, defaults, required fields, constraints, and state value validation | `runtime_validate_record` in `runtime_engine.mbt` |
| `from`, `role`, and `guard` checks | `runtime_transition_issues` in `runtime_engine.mbt` |
| Entity field vs transition-local input validation | `runtime_validate_transition_inputs` in `runtime_engine.mbt` |
| Mutating transition application and final target validation | `runtime_apply_transition` in `runtime_engine.mbt` |
| Read-only availability projection | `runtime_list_transitions` in `runtime_engine.mbt` |
| View projection and available action rendering | `runtime_project_gui` in `runtime_view.mbt` |

Hosts that need durable sessions should use the runtime adapter boundary in
`docs/runtime-adapter-boundary.md`: load a record, resolve an actor, call the
runtime, persist the returned record only after success, and normalize audit or
transport events outside the runtime core.
