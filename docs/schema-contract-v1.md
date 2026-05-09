# Schema Contract v1

Created: 2026-05-06

`domainprocessschema.v1` は、`domainprocessschema.mbt` が外部 consumer に公開する
schema contract の最小安定面を定義する。

## Stability levels

| Level | Meaning |
| --- | --- |
| stable | 外部ツールが依存してよい。互換性ポリシーの対象。 |
| experimental | 方向性はあるが shape が変わる可能性がある。 |
| internal | 実装都合。外部依存禁止。 |

## YAML grammar

`stable`

v1 の YAML subset は次だけを許可する。

- `key: value` / `key:` の mapping
- `- item` の block sequence
- `[a, b, c]` の inline string array
- bare scalar value

次は v1 では非対応。

- anchors / aliases
- tabs indentation
- advanced YAML tags
- quoted scalar 固有構文に依存する表現

## Top-level schema

`stable`

トップレベルは次の shape を持つ。

```yaml
entities:
  ExpenseRequest:
    fields: {}
    relations: {}
    constraints: {}
    states: {}
    transitions: {}
    rules: {}
    views: {}
    storage: {}
```

`entities` は 1 つ以上必要。

## Entity contract

`stable`

各 entity は次を持てる。

- `label`
- `fields`
- `relations`
- `constraints`
- `states`
- `transitions`
- `rules`
- `views`
- `storage`

Phase 1 では entity ごとに primary field はちょうど 1 つ必要。

## Field contract

`stable`

対応 field type:

- `id`
- `text`
- `number`
- `money`
- `boolean`
- `date`
- `datetime`
- `enum`
- `ref`
- `state`
- `file`

対応 metadata:

- `required`
- `primary`
- `readonly`
- `system`
- `default`
- `target` (`ref` のみ)
- `initial` (`state` のみ)

`ref` の lookup metadata は `docs/reference-lookup-contract.md` で固定する。
v1 manifest は `target` / `labelField` / `valueField` を機械読取可能な形で出力する。

## Relation contract

`stable`

relation は `kind` / `target` / `field` を持つ。  
`field` は同一 entity 内の `type: ref` field を参照し、`target` はその `target` と一致しなければならない。

## Constraint contract

`stable`

constraint は `expr` を持つ。  
validator と runtime は同じ expression AST を共有し、空文字の expression は無効。

## State contract

`stable`

- `states` を持つ entity はちょうど 1 つの `type: state` field を持つ
- `state` field は `initial` を持つ
- `initial` は declared state に一致しなければならない

## Transition contract

`stable`

transition は次を持つ。

- `from`
- `to`
- `role?`
- `input`
- `inputs`
- `guard?`

`from` / `to` は declared state に一致しなければならない。  
`input` は ordered list、`inputs` は transition-local input の型定義。

## Rule contract

`stable`

rule は `when` expression を持つ。  
`rule` は runtime で active/inactive として評価されるが、state transition 自体を直接実行しない。

## View contract

`stable`

view は state name と 1:1 で対応する。  
`editable` / `readonly` は field name list。state に対応しない view、view を持たない state は無効。

## Storage contract

`stable`

storage metadata:

- `table`
- `indexes`
- `unique`
- `softDelete`

`indexes` / `unique` の field group は空不可。各 field は declared field を参照しなければならない。

## Label resolution

`stable`

`label` は string または locale map を取れる。locale map の解決順は次。

1. exact locale
2. base language (`ja-jp` -> `ja`)
3. `default`
4. 既存 fallback string / name

## Expression language boundary

`stable`

v1 で使える expression は次。

- identifier path (`amount`, `state`, `user.role`)
- string / number / boolean literals
- `&&`, `||`, `!`
- `==`, `!=`, `>`, `>=`, `<`, `<=`
- parentheses

評価詳細は別 issue の `expression-language-v1` で拡張するが、上記の surface 自体は v1 contract に含む。

## Generated manifest contract

`stable`

JSON manifest は次の envelope を共有する。

```json
{
  "schemaVersion": "domainprocessschema.v1",
  "manifestKind": "api-manifest",
  "generator": {
    "name": "domainprocessschema.mbt",
    "version": "0.1.0"
  },
  "payload": {}
}
```

初回 v1 で stable とする `manifestKind`:

- `api-manifest`
- `validation-manifest`
- `gui-manifest`

## Audit event contract

`stable`

Transition audit events are host-facing records, not generated schema manifests.
The v1 event shape is defined in `docs/audit-event-manifest.md` and covers
`transition.applied` and `transition.rejected`.

Rejected transition events embed the same structured diagnostic shape as parser,
validator, and runtime failures.

## Runtime adapter boundary

`stable`

The runtime core is an in-memory library. Durable persistence, actor resolution,
reference lookup, clocks, ID generation, transaction boundaries, audit sinks,
and HTTP/App Server transport live in host adapters.

The boundary is defined in `docs/runtime-adapter-boundary.md`.

## Diagnostics contract

`stable`

validator / compiler / runtime diagnostics は少なくとも次を持つ。

- `code`
- `severity`
- `target`
- `message`
- `hint`
- `context`

代表 code:

- `UNKNOWN_ENTITY`
- `UNKNOWN_FIELD`
- `UNKNOWN_STATE`
- `INVALID_EXPR`
- `INVALID_TRANSITION_INPUT`
- `VIEW_STATE_MISMATCH`
- `STORAGE_CONFLICT`

## Backward compatibility policy

`stable`

- `stable` surface の削除・rename・意味変更は breaking change
- 新しい optional field / new diagnostic code の追加は non-breaking
- `experimental` は minor でも shape change を許容
- `internal` は告知なしに変更できる

## Unsupported features

`stable`

v1 では次を含まない。

- BPMN compatibility
- parallel workflow
- timer / scheduler semantics
- concrete adapter trait API
- schema diff / migration plan JSON
- fully specified expression-language document
- async reference lookup API

## Internal implementation details

`internal`

- validated `Schema` の具体的な MoonBit struct layout
- parser / renderer の file split
- HTML renderer 固有の DOM / class name
- WASM demo host の UI 実装
