# Codex App Server 向け schema + runtime session 契約を定義する

Created: 2026-05-09
Model: GPT-5 Codex unknown

## 背景

`domainprocessschema.mbt` にはすでに次の editor/demo surface がある。

- `compile`
- `runtime-preview`
- `apply-transition`
- browser-side graph / inspector state

一方で、現在の editor は browser 側が source と state を持ち、Worker API は
基本的に stateless である。  
runtime core 自体は library として保つ方針がすでにあり、ここへ HTTP や UI
責務を混ぜずに、外側だけ durable session 化する contract が必要になっている。

この issue は shared repo の存在を前提条件にはしない。  
先にこの repo 側で `schema + runtime session` 契約を定義し、あとから shared
repo や VS Code extension がその contract を消費できる状態にする。

## 提案

現在の Worker demo を App Server 向け session モデルとして再定義する。

- schema source、selection、actor、record、diagnostics を durable session
  state として扱う
- runtime core は library のまま保ち、HTTP / UI は core に入れない
- compile / preview / inspector edit / transition apply を App Server tool と
  して定義する
- 将来の shared repo や VS Code extension から、同じ session を reopen して
  継続操作できる形にする

## Session Snapshot

session snapshot は少なくとも次の shape を持つ。

```json
{
  "source": {
    "yaml": "entities:\n  ExpenseRequest:\n    ..."
  },
  "selection": {
    "entity": "ExpenseRequest",
    "state": "submitted",
    "transition": "approve",
    "inspectorNode": "views.submitted"
  },
  "actor": {
    "role": "manager"
  },
  "record": {
    "state": "submitted",
    "payload": { "amount": 1200 }
  },
  "compile": {
    "normalizedSchema": {},
    "diagnostics": []
  },
  "runtime": {
    "view": {},
    "availableTransitions": [
      { "name": "approve", "enabled": true, "reason": null }
    ]
  },
  "graph": {
    "nodes": [],
    "edges": []
  },
  "locale": "ja",
  "lastAction": {
    "kind": "compile",
    "completedAt": "2026-05-09T00:00:00Z"
  }
}
```

必須の top-level section は次とする。

- `source`
- `selection`
- `actor`
- `record`
- `compile`
- `runtime`
- `graph`
- `locale`
- `lastAction`

## Read-only Tools

read-only tool は少なくとも次を含む。

- `get_session_snapshot() -> SessionSnapshot`
- `compile_current_source() -> { normalizedSchema: object, diagnostics: Diagnostic[] }`
- `get_runtime_view() -> { view: object, diagnostics: Diagnostic[] }`
- `list_available_transitions() -> { transitions: TransitionStatus[] }`
- `get_graph() -> { nodes: GraphNode[], edges: GraphEdge[] }`
- `get_diagnostics() -> { diagnostics: Diagnostic[] }`

これらは approval 不要とする。

## Mutating Tools

mutating tool は少なくとも次を含む。

- `replace_source(yaml) -> { diagnostics: Diagnostic[], snapshot: SessionSnapshot }`
- `apply_inspector_edit(path, value) -> { snapshot: SessionSnapshot }`
- `select_entity(name) -> { selection: SelectionState, snapshot: SessionSnapshot }`
- `select_state(name) -> { selection: SelectionState, snapshot: SessionSnapshot }`
- `select_transition(name) -> { selection: SelectionState, snapshot: SessionSnapshot }`
- `set_actor_role(role) -> { actor: ActorState, snapshot: SessionSnapshot }`
- `update_record_payload(payload) -> { record: RecordState, diagnostics: Diagnostic[], snapshot: SessionSnapshot }`
- `apply_transition(name, input?) -> { approvalRequired: boolean, snapshot?: SessionSnapshot, proposal?: object }`
- `set_locale(locale) -> { locale: string, snapshot: SessionSnapshot }`
- `reset_session(example?) -> { approvalRequired: boolean, proposal: object }`

approval-required action も mutating tool の一種であり、approval section で
その条件を追加定義する。

## Approval 境界

approval 方針は次で固定する。

- durable state change として扱う transition 実行は approval-required
- reset のような destructive action は approval-required
- compile / preview / inspect / graph read は approval 不要

初期実装が in-memory runtime であっても、この approval 境界は contract 上で
先に固定する。

## Import / Export Artifact

artifact は少なくとも次の envelope を定義する。

- source YAML export
- normalized schema export
- runtime session snapshot export
- diagnostics export

ここでは binary packaging を固定しない。  
代わりに、JSON envelope の top-level field 名と論理構造を固定する。

## Diagnostic Shape

diagnostic は次の shape を使う。

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

compile / validation / runtime failure はすべてこの structured shape に揃える。

## Selection / Focus State

session resume 用に次を保持する。

- selected entity
- selected state
- selected transition
- selected inspector node
- active panel or focus mode

## Preview / Navigation State

runtime preview は単なる iframe HTML ではなく session state として持つ。

- current preview mode
- active entity/runtime route
- locale-dependent preview state
- active record + transition context
- preview refresh trigger after compile / transition

## Shared Repo との関係

shared repo はこの issue の blocker ではない。  
この issue の成果は「この repo 内で session contract を定義すること」であり、
shared repo と VS Code extension はその consumer として後続で実装される。

## 受け入れ条件

- [x] stateless Worker demo を durable `schema + runtime session` contract と
      して定義している
- [x] session snapshot に source / selection / actor / record / compile /
      runtime / graph / locale / lastAction の section がある
- [x] read-only tool と mutating tool が input / output の shape 付きで定義
      されている
- [x] approval-required action が mutating tool の subset として明文化されて
      いる
- [x] diagnostic shape、artifact envelope、preview/navigation state が定義
      されている
- [x] runtime core に HTTP / UI を入れない方針が明記されている

## 非目標

- persistence adapter 実装をこの issue で追加すること
- runtime core に HTTP server を埋め込むこと
- shared repo や VS Code extension をこの repo で実装すること
- browser-local Worker demo を最終アーキテクチャとして固定すること

## 根拠

`domainprocessschema.mbt` は schema compiler、runtime state、graph-like UI、
diagnostics、transition semantics をすでに持っている。  
不足しているのは durable session contract だけであり、ここを先に定義すれば
runtime boundary を汚さずに App Server client 側の実装へつなげられる。

## Resolution

Completed: 2026-05-10

- Added `docs/app-server-schema-runtime-session.md` as the durable App Server
  `schema + runtime` session contract.
- Fixed the required snapshot sections to `source`, `selection`, `actor`,
  `record`, `compile`, `runtime`, `graph`, `locale`, and `lastAction`.
- Split tools into read-only and mutating classes, with approval-required
  actions defined as a subset of mutating tools.
- Fixed durable transition application and reset as approval-required, while
  compile, preview, inspect, graph read, transition listing, and diagnostic read
  remain approval-free.
- Referenced `wasm/demo/editor_api.mbt` and `wasm/demo/session_json.mbt` as
  current prototype evidence, while documenting that the browser Worker demo is
  not the target durable App Server architecture.
- Linked the new contract from README, runtime adapter boundary, and the
  versioned contract roadmap.
