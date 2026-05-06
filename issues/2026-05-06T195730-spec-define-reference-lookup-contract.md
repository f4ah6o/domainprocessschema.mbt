# Reference / Lookup の最小 contract を定義する

Created: 2026-05-06
Model: GPT-5.4 1.0.41

## 背景

`ref` field は GUI manifest と demo で扱われ始めているが、表示ラベルや value field の contract はまだ安定していない。  
renderer や API generator が自然に接続するには、lookup metadata の最低限の shape を決める必要がある。

## 提案

field-level または schema-level で reference lookup metadata を持てる contract を定義し、manifest に `labelField` / `valueField` を出せるようにする。

## 受け入れ条件

- [ ] `ref` field の lookup metadata の置き場所が定義されている
- [ ] manifest で `target` / `labelField` / `valueField` を機械読取できる
- [ ] GUI renderer と API manifest の接続方針が説明されている

## 非目標

- async search API の実装
- reference catalog の永続化戦略を固定すること

## 根拠

WASM demo はすでに reference-select を表示する方向に進んでいる。  
lookup contract を入れると、demo 専用 metadata から汎用 contract へ昇格させやすい。
