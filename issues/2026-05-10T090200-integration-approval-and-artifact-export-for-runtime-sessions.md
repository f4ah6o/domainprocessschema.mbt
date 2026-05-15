# runtime session approval と artifact export を追加する

Created: 2026-05-10
Model: GPT-5 Codex
Category: integration
Status: open

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

- [ ] transition approval proposal に actor、transition、current/target state、
      expected effects が含まれる。
- [ ] reset approval proposal に失われる session state の summary が含まれる。
- [ ] source YAML export がある。
- [ ] normalized schema export がある。
- [ ] runtime session snapshot export がある。
- [ ] diagnostic report export がある。
- [ ] Tests or fixtures cover all proposal and export shapes.

## Non-goals

- External connector write 実装
- UI approval dialog 実装
- binary package format の固定
- 既存 demo response 互換

## Rationale

App Server integration では、state-changing action を明示的に承認し、成果物を安定した
envelope で取り出せることが価値になる。これにより schema/runtime session を安全に
共有・検証できる。
