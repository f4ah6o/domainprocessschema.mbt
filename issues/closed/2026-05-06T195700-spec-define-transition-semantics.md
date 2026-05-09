# Transition Semantics v1 を仕様として固定する

Created: 2026-05-06
Completed: 2026-05-10
Model: GPT-5.4 1.0.41

## 背景

runtime はすでに transition を実行できるが、`from` mismatch、role 未指定、guard 評価タイミング、input default の扱いなどは実装と README に分散している。  
API manifest と runtime behavior を一致させるには、transition semantics を別文書として固定する必要がある。

## 提案

`docs/transition-semantics-v1.md` を追加し、transition / guard / rule / validation / view の役割境界を文書化する。

## 受け入れ条件

- [x] `docs/transition-semantics-v1.md` が追加されている
- [x] `from` / `to` / `role` / `guard` / `input` / failure diagnostics の挙動が明文化されている
- [x] runtime 実装との対応が追える

## 非目標

- persistence や transaction adapter の仕様まで同時に決めること
- GUI renderer 固有の UX を固定すること

## 根拠

`runtime_engine.mbt` はすでに state / role / guard / input を評価しているので、暗黙の仕様は存在している。  
それを文書として固定すれば、runtime と API/UI consumer のズレを減らせる。

## 解決方法

`docs/transition-semantics-v1.md` を追加し、in-memory runtime の transition contract として `apply_transition` / `list_transitions` の評価順を固定した。`from` / `to` / `role` / `guard` / `input` の意味、transition-local input の default / required 扱い、`STATE_MISMATCH` や `ROLE_DENIED` などの failure diagnostics を runtime 実装に合わせて文書化した。

あわせて runtime 関数との対応表を追加し、README と versioned contract roadmap から参照できるようにした。persistence、transaction adapter、HTTP/App Server transport、GUI renderer UX は非目標のまま runtime adapter / host layer 側に残している。
