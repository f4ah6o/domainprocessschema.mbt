# Expression Language v1 を分離して仕様化する

Created: 2026-05-06
Model: GPT-5.4 1.0.41

## 背景

constraint / guard / rule はすでに小さな expression language を共有しているが、構文と評価規則は README と parser / evaluator 実装に分散している。  
unknown identifier、null/missing、short-circuit、reserved context を明文化しないと consumer ごとに解釈差が出やすい。

## 提案

`docs/expression-language-v1.md` を追加し、syntax / precedence / evaluation policy / reserved context names を仕様化する。

## 受け入れ条件

- [ ] `docs/expression-language-v1.md` が追加されている
- [ ] identifier path / literals / logical/comparison operators / parentheses が定義されている
- [ ] unknown identifier / missing / null / coercion / short-circuit policy が定義されている

## 非目標

- computed field や高度な関数呼び出しを追加すること
- full scripting language に拡張すること

## 根拠

expr parser / runtime evaluator はすでに共通 AST を持っている。  
この層を v1 spec として独立させると、validator と runtime の一貫性を今後も保ちやすい。
