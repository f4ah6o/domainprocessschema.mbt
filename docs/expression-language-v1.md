# Expression Language v1

Created: 2026-05-10

This document fixes the v1 expression language shared by constraints, guards,
and rules. It describes the parser, validator, and in-memory runtime evaluation
contract. It does not add computed fields, functions, scripting, or host-side
policy hooks.

## Scope

Expressions appear in:

- entity constraints: `constraints.<name>.expr`
- transition guards: `transitions.<name>.guard`
- runtime rules: `rules.<name>.when`

The schema compiler parses each expression into the shared `Expr` AST. Runtime
validation, transition checks, rule projection, normalized schema output, and
manifests reuse that AST or its canonical string form.

## Syntax

Whitespace may appear between tokens and has no meaning.

Identifier paths:

- `amount`
- `state`
- `user.role`
- `user.profile.department`

Identifiers must start with `A-Z`, `a-z`, or `_`. Remaining characters may also
include `0-9`. A path uses `.` followed by another identifier. A `.` not followed
by an identifier is invalid.

Literals:

- string literal: `"submitted"`
- number literal: `123`
- boolean literal: `true` or `false`

String literals are delimited by double quotes. Escape sequences are not part of
v1; a literal ends at the next double quote. Number literals are unsigned
integer tokens. The parser preserves the token text, and runtime evaluation
accepts integer literals only. Boolean keywords are case-insensitive during
tokenization.

Operators:

- logical not: `!`
- logical and: `&&`
- logical or: `||`
- equality: `==`
- inequality: `!=`
- ordering: `>`, `>=`, `<`, `<=`
- grouping: `(` and `)`

Single `=`, `&`, or `|` tokens are invalid. Unsupported characters are invalid.
An empty expression is invalid.

## Precedence

Expressions are parsed with this precedence, from highest to lowest:

1. primary expressions: paths, literals, and parenthesized expressions
2. unary `!`
3. comparison operators: `==`, `!=`, `>`, `>=`, `<`, `<=`
4. `&&`
5. `||`

Binary operators are rendered in canonical form with spaces around the operator.
Parentheses are preserved only where required by precedence. Chained comparison
syntax such as `a < b < c` is not a comparison chain; after one comparison, the
remaining tokens are rejected as trailing tokens.

## Identifier Contexts

Declared entity field names are valid as single-segment paths in constraints,
guards, and rules.

`state` is a reserved runtime path. It is valid in guards and rules, where it
resolves to the current entity state field value. It is not valid in entity
constraints.

`user.<attribute>` is a reserved actor path. It is valid in guards and rules.
The runtime joins everything after `user.` with `.` and looks up that key in
`RuntimeActor.attributes`. For example, `user.profile.department` reads actor
attribute key `profile.department`. `user.<attribute>` is not valid in entity
constraints.

Any other identifier path is rejected during schema validation with
`INVALID_EXPR`.

## Runtime Evaluation

Runtime evaluation produces `RuntimeValue` values:

- string literals and text fields evaluate to `Text`
- integer literals and number / money fields evaluate to `Integer`
- boolean literals and boolean fields evaluate to `Flag`
- `Null` may appear only from runtime record or actor values

Logical operators require boolean values. If an operand is not boolean, the
runtime returns `INVALID_EXPR`.

Equality operators compare values only when both sides have the same runtime
kind. `Null == Null` is valid and true. `Null != Null` is valid and false.
Comparing `Null` with text, integer, or boolean is an invalid mixed-kind
comparison and returns `INVALID_EXPR`.

Ordering operators require matching text values or matching integer values.
Ordering across mixed kinds, boolean values, or `Null` returns `INVALID_EXPR`.

The runtime does not coerce values between kinds. Text `"1"` is not equal to
integer `1`; text `"true"` is not a boolean. Hosts must normalize payloads before
runtime expression evaluation.

## Missing And Unknown Values

Unknown identifier paths are schema validation errors and do not reach runtime
evaluation.

At runtime, a declared field path with no value in the record returns
`UNKNOWN_FIELD`. A missing `state` value returns `UNKNOWN_STATE`. A missing
`user.<attribute>` value returns `INVALID_EXPR`.

`Null` is not treated as missing. It is an explicit runtime value and follows
the comparison rules above.

## Short-Circuit Policy

v1 does not short-circuit `&&` or `||` during runtime evaluation. The runtime
evaluates both operands first, then applies the logical operator. If either side
produces a diagnostic, the expression returns that diagnostic instead of a
boolean result.

This policy keeps diagnostics deterministic for guards and rules. Consumers must
not rely on expressions such as `false && missingField == 1` to hide missing
value diagnostics.

## Implementation Mapping

| Contract area | Implementation |
| --- | --- |
| Tokenization, syntax errors, precedence, parentheses, canonical rendering | `expr_parser.mbt` |
| Identifier context validation for constraints, guards, and rules | `validate_expr` / `validate_expr_path` in `expr_parser.mbt`, called from `validator.mbt` |
| Runtime path resolution and missing value diagnostics | `runtime_eval_path` in `runtime_eval.mbt` |
| Logical, equality, and ordering evaluation | `runtime_eval_expr` and `runtime_eval_binary` in `runtime_eval.mbt` |
| Boolean result requirement for constraints, guards, and rules | `runtime_eval_bool_expr` in `runtime_eval.mbt` and `runtime_value_to_bool` in `runtime_helpers.mbt` |

The transition semantics document describes how guard expression diagnostics are
reported during transition availability and mutation:
`docs/transition-semantics-v1.md`.
