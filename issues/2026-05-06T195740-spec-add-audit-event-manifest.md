# Audit event manifest を追加する

Created: 2026-05-06
Model: GPT-5.4 1.0.41

## 背景

transition 実行は runtime で扱えるようになったが、結果を安定した event contract として保存・表示・再利用する仕様はまだない。  
監査ログ、履歴 UI、debug/replay を見据えると audit event manifest が必要になる。

## 提案

`transition.applied` / `transition.rejected` を中心に、entity / recordId / transition / from / to / actor / input / result / issues を持つ event shape を定義する。

## 受け入れ条件

- [ ] success / failure の両 event shape が定義されている
- [ ] failure event が structured diagnostics を含められる
- [ ] audit sink や履歴 UI への接続先が説明されている

## 非目標

- event sourcing そのものを実装すること
- runtime adapter 実装を追加すること

## 根拠

structured diagnostics と runtime adapter boundary を導入すると、transition outcome は event contract として切り出しやすくなる。  
これがあると、運用時の可観測性と履歴 UI の拡張点を先に確保できる。
