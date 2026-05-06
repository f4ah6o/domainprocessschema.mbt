# Runtime Adapter Boundary を定義する

Created: 2026-05-06
Model: GPT-5.4 1.0.41

## 背景

現在の runtime は in-memory library として成立しているが、永続化や actor 解決などの外部接続点はまだ仕様化されていない。  
core を肥大化させずに実運用へ接続するためには、adapter boundary を文書で切り出す必要がある。

## 提案

`docs/runtime-adapter-boundary.md` を追加し、RecordLoader / RecordSaver / ReferenceResolver / ActorResolver / ClockProvider / IdGenerator / TransactionBoundary / AuditSink などの役割を定義する。

## 受け入れ条件

- [ ] runtime core と外部 adapter の責務境界が文書化されている
- [ ] persistence / actor / clock / id / audit の注入点が定義されている
- [ ] core に HTTP server を入れない方針が明記されている

## 非目標

- 実際の adapter 実装をこの issue で追加すること
- D1 / SQLite / kintone など特定 backend へ先に最適化すること

## 根拠

README でも runtime は library/static-preview engine に限定すると明記されている。  
boundary を定義しておけば、その制約を保ったまま外部接続だけを増やせる。
