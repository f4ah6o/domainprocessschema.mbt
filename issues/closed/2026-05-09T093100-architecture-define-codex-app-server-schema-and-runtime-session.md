# Codex App Server 向け schema + runtime session 契約を定義する

Created: 2026-05-09
Closed: 2026-05-10
Model: GPT-5 Codex
Category: architecture
Status: closed
Resolution: completed

## Summary

`domainprocessschema.mbt` の browser-local editor/demo surface を、Codex App
Server が reopen、notify、approval request できる durable な `schema + runtime
session` contract として定義した。

## Acceptance Criteria

- [x] stateless Worker demo を durable `schema + runtime session` contract として定義している。
- [x] session snapshot に source / selection / actor / record / compile / runtime / graph / locale / lastAction の section がある。
- [x] read-only tool と mutating tool が input / output の shape 付きで定義されている。
- [x] approval-required action が mutating tool の subset として明文化されている。
- [x] diagnostic shape、artifact envelope、preview/navigation state が定義されている。
- [x] runtime core に HTTP / UI を入れない方針が明記されている。

## Resolution

既存の後続 App Server 実装で、この issue の大半はすでに満たされていた。

- `domainprocessschema_mbt.mbt` が `SchemaRuntimeSessionStore` と section 型を公開し、`source`、`selection`、`actor`、`record`、`compile`、`runtime`、`graph`、`locale`、`lastAction` を stable session snapshot として保持する。
- `runtime_session_store.mbt` が source replacement、selection、actor、record、transition、locale の snapshot 更新規則と `export_schema_runtime_session` / artifact envelope を実装している。
- `app_server_schema_tools.mbt` が read-only、mutating、approval-required の tool catalog を定義している。transition apply と reset は approval proposal を返し、compile / preview / inspect / graph read は approval 不要である。
- runtime core は MoonBit library API のままで、HTTP server、UI adapter、persistence adapter は追加していない。
- closeout として `SchemaSessionDiagnostic` を `code` / `severity` / `target` / `message` / `hint` / `context` の structured shape に揃え、JSON envelope と focused tests を更新した。

Preview / navigation state は現在の contract では `selection`、`record`、`runtime.view`、`runtime.transitions`、`locale`、`lastAction` に分散して保持する。将来 UI 固有の active panel や focus mode が必要になった場合は、runtime core ではなく App Server adapter 側の session extension として追加する。
