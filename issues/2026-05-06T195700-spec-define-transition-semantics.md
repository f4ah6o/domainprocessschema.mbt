# Transition Semantics v1 を仕様として固定する

Created: 2026-05-06
Model: GPT-5.4 1.0.41

## 背景

runtime はすでに transition を実行できるが、`from` mismatch、role 未指定、guard 評価タイミング、input default の扱いなどは実装と README に分散している。  
API manifest と runtime behavior を一致させるには、transition semantics を別文書として固定する必要がある。

## 提案

`docs/transition-semantics-v1.md` を追加し、transition / guard / rule / validation / view の役割境界を文書化する。

## 受け入れ条件

- [ ] `docs/transition-semantics-v1.md` が追加されている
- [ ] `from` / `to` / `role` / `guard` / `input` / failure diagnostics の挙動が明文化されている
- [ ] runtime 実装との対応が追える

## 非目標

- persistence や transaction adapter の仕様まで同時に決めること
- GUI renderer 固有の UX を固定すること

## 根拠

`runtime_engine.mbt` はすでに state / role / guard / input を評価しているので、暗黙の仕様は存在している。  
それを文書として固定すれば、runtime と API/UI consumer のズレを減らせる。
