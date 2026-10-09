# runtime session approval と artifact export を追加する

Created: 2026-05-10
Model: GPT-5 Codex
Category: integration
Status: closed

## Summary

transition/reset approval、source YAML / normalized schema / runtime session /
diagnostics export を実装する。

## Why

transition 実行と reset は domain state を変えるため、App Server client ではユーザーが
確認できる approval proposal が必要である。また、schema editor の成果を他 client や
fixture に渡すには、source、normalized schema、runtime snapshot、diagnostics を
deterministic に export できる必要がある。

後方互換性は不要なので、既存 demo の response 形状より artifact envelope の安定性を
優先する。

## Scope

- `apply_transition` approval proposal の shape を定義する。
- `reset_session` approval proposal の shape を定義する。
- Export formats: `source-yaml`、`normalized-schema`、`runtime-session`、
  `diagnostic-report`。
- proposal には entity、current state、target transition、actor、record summary、
  expected effects を含める。
- Export は stable JSON envelope または YAML payload envelope として返す。

## Acceptance Criteria

- [x] transition approval proposal に actor、transition、current/target state、
      expected effects が含まれる。
- [x] reset approval proposal に失われる session state の summary が含まれる。
- [x] source YAML export がある。
- [x] normalized schema export がある。
- [x] runtime session snapshot export がある。
- [x] diagnostic report export がある。
- [x] Tests or fixtures cover all proposal and export shapes.

## Non-goals

- External connector write 実装
- UI approval dialog 実装
- binary package format の固定
- 既存 demo response 互換

## Rationale

App Server integration では、state-changing action を明示的に承認し、成果物を安定した
envelope で取り出せることが価値になる。これにより schema/runtime session を安全に
共有・検証できる。

## Resolution

Approval proposal に typed `detail` JSON を追加し、transition apply と session reset の
確認情報を deterministic に出力するようにした。あわせて `source-yaml`、
`normalized-schema`、`runtime-session`、`diagnostic-report` の artifact envelope export
API と focused tests を追加した。
