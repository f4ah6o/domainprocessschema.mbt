# Codex App Server 向け schema + runtime session 契約を定義する

- Status: active
- Disposition: proposed
- GitHub Issue: none
- GitHub URL: none
- GitHub State: none
- Created: 2026-05-09T09:31:00Z
- Closed: none
- Author: Codex
- Labels: architecture, app-server, session, runtime
- Assignees: none
- Parent: none
- Depends on: none
- Blocks: future shared App Server client implementation
- Superseded by: none
- Comments: 0
- Source: created in repo

Created: 2026-05-09
Model: GPT-5 Codex (version unknown)

## Summary

`domainprocessschema.mbt` の browser-local editor/demo surface を、Codex App
Server が reopen / notify / request approval できる durable `schema + runtime
session` contract として定義する。

この issue は shared repo の存在を blocker にしない。先にこの repo 側で
session contract を固定し、あとから `codex-app-server-shared` や VS Code
extension がそれを消費できる状態にする。

## Why

`domainprocessschema.mbt` にはすでに次の surface がある。

- `compile`
- `runtime-preview`
- `apply-transition`
- browser-side graph / inspector state

一方で現在の editor は browser 側が source と state を持ち、Worker API は
基本的に stateless である。runtime core 自体は library のまま保ちたいので、
HTTP / UI を core に入れずに durable session だけを外側で定義する必要がある。

## Scope

- 現在の Worker demo を App Server 向け session モデルとして再定義する
- schema source、selection、actor、record、diagnostics を durable session state
  として扱う
- compile / preview / inspector edit / transition apply を App Server tool と
  して定義する
- 同じ session を reopen して継続操作できる shape を固定する

## Boundary

runtime core は library のまま保ち、HTTP / UI / persistence adapter は core に
入れない。この issue で固定するのは durable session contract とその approval
境界であり、transport や host UI は外側で差し替え可能なままにする。

## Repo-local Source Of Truth

- repo-local issue を source of truth にする
- 今回は GitHub issue へ同期しない
- `issues-migrate` skill の自動同期対象としては扱わず、必要なら後続 automation
  がこの issue file を明示的に読む前提にする
- shared repo は consumer であり、この issue の blocker ではない

## Cross-repo Conventions

この issue は `papyr.mbt` / `vizprocess.mbt` / shared repo と共通で次を前提にする。

- tool naming は `verb_object` 形式
- read-only tool は snapshot projection か read result を返す
- mutating tool は差分結果だけでなく `snapshot` も返す
- approval が必要な tool は `approvalRequired: true` と proposal payload を返す
- diagnostic shape は `code / severity / target / message / hint / context`
- resumable session / notification / approval request を共通前提にする

## Shared Vocabulary

この repo で先に固定する共通 vocabulary は次。

- session id / snapshot envelope
- approval proposal / approval result
- notification event kind
- structured diagnostics

shared repo はこれらを再利用するが、repo 固有 snapshot field や runtime logic は
持たない。

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

`lastAction.kind` の許容値は、少なくとも現在定義している tool と対応づく次を
含む。

- `compile_current_source`
- `get_runtime_view`
- `replace_source`
- `apply_inspector_edit`
- `select_entity`
- `select_state`
- `select_transition`
- `set_actor_role`
- `update_record_payload`
- `apply_transition`
- `set_locale`
- `reset_session`

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
- `apply_transition(name, input?) -> { approvalRequired: true, proposal: ApprovalProposal } | { snapshot: SessionSnapshot, result: TransitionResult }`
- `set_locale(locale) -> { locale: string, snapshot: SessionSnapshot }`
- `reset_session(example?) -> { approvalRequired: true, proposal: ApprovalProposal } | { snapshot: SessionSnapshot }`

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

ここでは binary packaging を固定しない。代わりに JSON envelope の
top-level field 名と論理構造を固定する。

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

## Shared Repo Relationship

shared repo はこの issue の blocker ではない。この issue の成果は
`domainprocessschema.mbt` 側で `schema + runtime session` contract を定義する
ことにあり、`codex-app-server-shared` は後続でその contract を消費する。

## Acceptance Criteria

- [ ] stateless Worker demo を durable `schema + runtime session` contract として
      定義している
- [ ] session snapshot に source / selection / actor / record / compile /
      runtime / graph / locale / lastAction の section がある
- [ ] read-only tool と mutating tool が input / output の shape 付きで定義
      されている
- [ ] approval-required action が mutating tool の subset として明文化されている
- [ ] diagnostic shape、artifact envelope、preview/navigation state が定義
      されている
- [ ] runtime core に HTTP / UI を入れない方針が明記されている

## Non-goals

- persistence adapter 実装をこの issue で追加すること
- runtime core に HTTP server を埋め込むこと
- shared repo や VS Code extension をこの repo で実装すること
- browser-local Worker demo を最終アーキテクチャとして固定すること

## Rationale

`domainprocessschema.mbt` は schema compiler、runtime state、graph-like UI、
diagnostics、transition semantics をすでに持っている。不足しているのは durable
session contract だけであり、ここを先に定義すれば runtime boundary を汚さずに
App Server client 側の実装へつなげられる。
