# domainprocessschema.mbt versioned contract 安定化ロードマップ

Created: 2026-05-06
Model: GPT-5.4 1.0.41

## 背景

`domainprocessschema.mbt` はすでに YAML 入力、schema validation、SQL/migration、API/validation/GUI manifest、static HTML preview、in-memory runtime、WASM demo まで揃っている。  
次の価値は機能の横展開ではなく、外部ツールが安全に依存できる versioned contract を固定することにある。

## 提案

- Schema / Manifest / Diagnostic / Runtime Boundary を段階的に stable contract 化する
- 変更を複数 issue に分割し、初回 PR は `schema contract v1` / `manifest envelope` / `structured diagnostics` に絞る
- `normalized-schema` / `golden fixtures` / `transition semantics` 以降は follow-up PR として積む

## 実装順序

推奨順序は次の通り。

1. `schema contract v1`
2. `versioned manifest envelope`
3. `structured diagnostics`
4. `normalized schema output` と `golden fixtures`
5. `transition semantics` と `expression language`
6. `runtime adapter boundary` / `reference lookup` / `audit event`

特に `schema contract v1` は transition semantics や expression language の
前提になり、`manifest envelope` は audit event の出力整形より先に固める。

## 受け入れ条件

- [ ] 今回の proposal を個別 issue に分割して `issues/` に登録する
- [ ] 初回 PR の対象が `schema contract v1` / `manifest envelope` / `structured diagnostics` で明文化されている
- [ ] follow-up issue が `normalized-schema` / `golden fixtures` / `transition semantics` / `expression language` / `runtime adapter boundary` / `reference lookup` / `audit event` をカバーしている

## 非目標

- 1 本の PR で numbered proposal をすべて実装すること
- runtime に HTTP server や persistence adapter を直接組み込むこと

## 根拠

README にはすでに manifest / runtime / WASM demo までの実装が列挙されている一方、public contract の versioning と diagnostics shape は未固定。  
まず issue を仕様単位に分けることで、外部依存可能な低レベル core への移行を小さな PR で進めやすくする。
