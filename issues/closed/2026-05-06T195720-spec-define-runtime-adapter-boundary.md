# Runtime Adapter Boundary を定義する

Created: 2026-05-06
Completed: 2026-05-09
Model: GPT-5.4 1.0.41

## 背景

現在の runtime は in-memory library として成立しているが、永続化や actor 解決などの外部接続点はまだ仕様化されていない。  
core を肥大化させずに実運用へ接続するためには、adapter boundary を文書で切り出す必要がある。

## 提案

`docs/runtime-adapter-boundary.md` を追加し、RecordLoader / RecordSaver / ReferenceResolver / ActorResolver / ClockProvider / IdGenerator / TransactionBoundary / AuditSink などの役割を定義する。

## 受け入れ条件

- [x] runtime core と外部 adapter の責務境界が文書化されている
- [x] persistence / actor / clock / id / audit の注入点が定義されている
- [x] core に HTTP server を入れない方針が明記されている

## 非目標

- 実際の adapter 実装をこの issue で追加すること
- D1 / SQLite / kintone など特定 backend へ先に最適化すること

## 根拠

README でも runtime は library/static-preview engine に限定すると明記されている。  
boundary を定義しておけば、その制約を保ったまま外部接続だけを増やせる。

## 解決方法

`docs/runtime-adapter-boundary.md` を追加し、runtime core が所有する決定的な schema/runtime 処理と、host adapter が所有する外部接続点を分けて定義した。

文書では `RecordLoader`、`RecordSaver`、`ReferenceResolver`、`ActorResolver`、`ClockProvider`、`IdGenerator`、`TransactionBoundary`、`AuditSink` の役割を固定した。read flow と mutation flow も分け、runtime が schema/state/actor/guard/input の妥当性を判定し、host が durable persistence と audit delivery を完了させる境界を明確にした。

README と schema contract から同文書へリンクし、runtime core に HTTP server、永続化 adapter、browser interactivity、App Server transport を入れない方針を維持した。
