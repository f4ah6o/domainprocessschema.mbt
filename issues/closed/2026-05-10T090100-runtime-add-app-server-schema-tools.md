# App Server schema tools を追加する

Created: 2026-05-10
Model: GPT-5 Codex
Category: runtime
Status: closed

## Summary

compile、runtime preview、inspector edit、transition apply、diagnostics read を
App Server tool 境界へ分割する。

## Why

現在の editor API は demo 用の route と browser state に寄っている。App Server client
では、読み取り、session mutation、approval-required transition を tool として区別する
必要がある。これにより schema editor や VS Code client が同じ session store を安全に
操作できる。

後方互換性は不要なので、既存 route 名より tool の意味と snapshot 更新を優先する。

## Scope

- Read-only tools: session snapshot、compile current source、runtime view、
  available transitions、graph、diagnostics。
- Mutating tools: replace source、inspector edit、select entity/state/transition、
  actor role set、record payload update、locale set。
- Approval-required tools: apply transition、reset session。
- 各 tool は diagnostics と updated snapshot を stable JSON envelope で返す。

## Acceptance Criteria

- [x] read-only tools の input / output shape が定義されている。
- [x] mutating tools の input / output shape が定義されている。
- [x] transition apply と reset が approval-required として定義されている。
- [x] inspector edit は source/schema path と value を受け取り snapshot を返す。
- [x] compile / runtime failure は structured diagnostics として返る。
- [x] Tests cover compile read, source replace, selection change, actor change,
      record update, and transition approval proposal.

## Non-goals

- UI inspector の見た目変更
- Shared App Server client 実装
- 外部 persistence adapter 実装
- 既存 demo route の互換維持

## Rationale

schema runtime は mutation の意味が明確な domain である。App Server tool boundary を
定義すると、client は schema editing と runtime execution を ad hoc HTTP route ではなく
typed tool flow として扱える。

## Resolution

`SchemaRuntimeSessionStore` の上に read-only、mutating、approval-required の typed tool
境界を追加した。各 tool は diagnostics と session snapshot を含む envelope を返し、
transition apply と reset は状態を直接変更せず approval proposal を返す。
