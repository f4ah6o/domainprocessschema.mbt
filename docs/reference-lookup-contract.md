# Reference Lookup Contract

This document fixes the v1 lookup metadata for `ref` fields and `ref`
transition-local inputs.

The contract is intentionally small. It only tells a host which target entity is
referenced and which target fields should be used for option values and labels.
It does not define an async search API, persistence strategy, pagination model,
or permission policy.

## Schema Placement

In v1, lookup metadata is derived from the existing `ref` declaration:

```yaml
entities:
  ExpenseRequest:
    fields:
      applicant:
        type: ref
        target: User
```

The `target` property is the stable schema-level lookup anchor. It is valid only
on `type: ref` fields and `type: ref` transition-local inputs. The validator
requires the target entity to exist.

v1 does not add a separate `lookup` block. Future schema versions may add
optional overrides, but the current default remains stable:

- `target`: referenced entity name
- `valueField`: target entity primary field
- `labelField`: target entity primary field

Using the primary field for both value and label is deliberately conservative.
It matches the current schema surface without inventing display-field heuristics.

## Manifest Shape

API, validation, and GUI manifests expose lookup metadata on field/input objects:

```json
{
  "name": "applicant",
  "type": "ref",
  "target": "User",
  "labelField": "id",
  "valueField": "id"
}
```

For non-reference fields and inputs, the same properties are emitted as `null`.
That keeps consumer code simple: clients can read the fields directly and check
`target != null` to detect lookup-backed controls.

## GUI Renderer Connection

`gui-manifest` continues to use `component: "reference-select"` for `ref` fields
and `ref` transition inputs. A host renderer should use:

- `component` to choose the control family
- `target` to choose the reference catalog or resolver
- `valueField` to read the submitted value from each option
- `labelField` to display an option label

The built-in static HTML renderer does not fetch reference options. The browser
demo may provide a static reference catalog as a prototype, but durable lookup is
a host concern.

## API Manifest Connection

`api-manifest` exposes the same lookup metadata on entity fields and action
inputs. A generated API host can use it to validate that incoming values are IDs
for the target entity, then delegate actual lookup and authorization to a
`ReferenceResolver` adapter.

The API manifest does not define route shape for search or autocomplete in v1.
Those routes belong to the host/application layer.

## Validation Manifest Connection

`validation-manifest` exposes lookup metadata so editor hosts can show accurate
field hints before calling runtime mutation APIs. Validation still treats a ref
value as a scalar identifier; existence checks are adapter-level work.

## Non-Goals

The v1 contract does not include:

- async search request/response shape
- server-side pagination
- durable reference catalog storage
- cross-tenant access policy
- display-field fallback heuristics
- denormalized label snapshots

Those belong in a later host-level reference resolver contract.
