# Versioned Contract Roadmap

Created: 2026-05-10

This document records the stabilization order for the public
`domainprocessschema.mbt` contract. The goal is to keep external tools from
depending on incidental MoonBit struct layout or demo behavior.

## Stable Contract Set

The initial contract family is split into small, reviewable surfaces:

1. Schema grammar and schema model: `docs/schema-contract-v1.md`
2. Generated manifest envelope: the `Generated manifest contract` section in
   `docs/schema-contract-v1.md`
3. Structured diagnostics: the `Diagnostics contract` section in
   `docs/schema-contract-v1.md`
4. Reference lookup metadata: `docs/reference-lookup-contract.md`
5. Audit event shape: `docs/audit-event-manifest.md`
6. Runtime adapter ownership: `docs/runtime-adapter-boundary.md`
7. Transition semantics: `docs/transition-semantics-v1.md`
8. Expression language behavior: `docs/expression-language-v1.md`

Each surface has a separate issue so future changes can be reviewed without
turning the roadmap into a large implementation PR.

## Issue Split

Initial stabilization work is represented by these issue files:

- `issues/closed/2026-05-06T195610-spec-stabilize-schema-contract-v1.md`
- `issues/closed/2026-05-06T195620-spec-add-versioned-manifest-envelope.md`
- `issues/closed/2026-05-06T195630-spec-define-structured-diagnostics.md`

Follow-up stabilization work is represented by these issue files:

- `issues/closed/2026-05-06T195640-test-freeze-generated-artifact-goldens.md`
- `issues/closed/2026-05-06T195650-cli-add-normalized-schema-output.md`
- `issues/closed/2026-05-06T195700-spec-define-transition-semantics.md`
- `issues/closed/2026-05-06T195710-spec-document-expression-language-v1.md`
- `issues/closed/2026-05-06T195720-spec-define-runtime-adapter-boundary.md`
- `issues/closed/2026-05-06T195730-spec-define-reference-lookup-contract.md`
- `issues/closed/2026-05-06T195740-spec-add-audit-event-manifest.md`

The closed follow-up issues already define normalized schema output, generated
artifact golden fixtures, transition semantics, expression-language behavior,
the runtime adapter boundary, reference lookup contract, and audit event shape.
Remaining open issues are outside this follow-up contract split or cover App
Server session architecture.

## Stabilization Order

The order is:

1. Freeze schema contract v1.
2. Keep all generated manifests behind the shared versioned envelope.
3. Reuse one structured diagnostic shape across parser, validator, runtime, and
   host-facing events.
4. Add normalized schema output and golden fixtures to catch accidental contract
   drift.
5. Specify transition semantics and expression language behavior.
6. Keep host integration points outside the runtime core through the runtime
   adapter boundary, reference lookup contract, and audit event manifest.

This order keeps lower-level schema and diagnostic vocabulary stable before
adding more runtime behavior. It also keeps App Server and HTTP transport work in
host layers rather than in the MoonBit runtime core.

## Non-Goals

This roadmap does not define:

- concrete persistence adapter traits
- HTTP route shapes
- authentication or authorization protocol
- event sourcing guarantees
- a single PR that implements every listed issue
