# Structured Diagnostics を導入する

Created: 2026-05-06
Completed: 2026-05-10
Model: GPT-5.4 1.0.41

## 背景

validator / compiler / runtime は現在 `path + message` 中心でエラーを返しており、CLI / browser demo / 将来の editor integration から機械処理しにくい。  
特に `SchemaError::ValidationError` と `RuntimeIssue` は code / severity / hint を持たず、同じ種別のエラーを安定して判定できない。

## 提案

共通 diagnostic shape を導入し、少なくとも以下を持たせる。

- `code`
- `severity`
- `target`
- `message`
- `hint`
- `context`

初回 PR では validator / compiler / runtime がこの shape を返せる状態にそろえる。

## 受け入れ条件

- [x] validator が `UNKNOWN_STATE` などの固定 diagnostic code を返す
- [x] runtime の transition / validation failure が structured diagnostics を返す
- [x] CLI / WASM demo / tests が string 比較ではなく diagnostic shape を前提に扱える

## 非目標

- すべての将来 error code をこの issue で出し切ること
- editor integration そのものを実装すること

## 根拠

browser host はすでに structured runtime payload を読む方向へ進んでおり、diagnostics だけが最後まで free-form string に寄っている。  
ここを固定すると CLI、GUI、agent のどれでも同じ修正案内を扱いやすくなる。

## 解決方法

`Diagnostic` と `DiagnosticSeverity` を public surface として固定し、diagnostic shape を `code`、`severity`、`target`、`message`、`hint`、`context` に統一した。validator / parser / runtime helper はこの shape を使って diagnostic を返す。

tests では `UNKNOWN_STATE`、`INVALID_EXPR`、`INVALID_YAML_SYNTAX` などの fixed code と diagnostic field を expect している。runtime validation / transition failure も structured issue を返し、CLI は structured diagnostic report を出力する。

WASM demo の editor/session JSON は severity、hint、context を含む diagnostic を JSON 化しており、browser host や将来の editor integration が free-form string ではなく diagnostic shape を扱える。
