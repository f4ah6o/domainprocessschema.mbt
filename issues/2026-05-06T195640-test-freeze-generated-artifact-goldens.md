# Generated artifact の golden fixtures を固定する

Created: 2026-05-06
Model: GPT-5.4 1.0.41

## 背景

現在の test は `*_test.mbt` の snapshot / assertion ベースで、契約成果物を fixture ディレクトリとして公開していない。  
manifest envelope や diagnostics を安定化した後は、生成物そのものを contract test suite として固定する必要がある。

## 提案

`fixtures/expense_request/` を作り、input と expected outputs を並べる。

- `input.yaml`
- `expected.schema.normalized.json`
- `expected.sql`
- `expected.migration.up.sql`
- `expected.migration.down.sql`
- `expected.api-manifest.json`
- `expected.validation-manifest.json`
- `expected.gui-manifest.json`
- `expected.gui-html.html`
- `expected.runtime-projection.json`

## 受け入れ条件

- [ ] fixture ディレクトリが追加されている
- [ ] 主要生成物を fixture と比較する test がある
- [ ] 破壊的変更が差分で分かる状態になっている

## 非目標

- 初回 PR で fixture まで一気に入れること
- 大量の example schema を同時に追加すること

## 根拠

contract-first に移る以上、README の説明だけでなく参照可能な golden outputs が必要。  
fixture があれば refactor と外部 consumer の両方に対して「何が安定しているか」を明示できる。
