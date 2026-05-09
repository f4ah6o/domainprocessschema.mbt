# Reference / Lookup の最小 contract を定義する

Created: 2026-05-06
Model: GPT-5.4 1.0.41

## 背景

`ref` field は GUI manifest と demo で扱われ始めているが、表示ラベルや value field の contract はまだ安定していない。  
renderer や API generator が自然に接続するには、lookup metadata の最低限の shape を決める必要がある。

## 提案

field-level または schema-level で reference lookup metadata を持てる contract を定義し、manifest に `labelField` / `valueField` を出せるようにする。

## 受け入れ条件

- [x] `ref` field の lookup metadata の置き場所が定義されている
- [x] manifest で `target` / `labelField` / `valueField` を機械読取できる
- [x] GUI renderer と API manifest の接続方針が説明されている

## 非目標

- async search API の実装
- reference catalog の永続化戦略を固定すること

## 根拠

WASM demo はすでに reference-select を表示する方向に進んでいる。  
lookup contract を入れると、demo 専用 metadata から汎用 contract へ昇格させやすい。

## 解決方法

`docs/reference-lookup-contract.md` を追加し、v1 では既存の `type: ref` + `target` を lookup metadata の置き場所として固定した。明示的な `lookup` block は追加せず、`labelField` / `valueField` は target entity の primary field から導出する方針にした。

API / validation / GUI manifest の field/input object に `target` / `labelField` / `valueField` を出力するようにした。非 ref では `null` を出すため、consumer は同じ property を直接読んで `target != null` を lookup control の判定に使える。

README と schema contract から参照を追加し、GUI renderer は `reference-select` + lookup metadata を使い、API manifest は host の `ReferenceResolver` adapter へ接続する方針を文書化した。
