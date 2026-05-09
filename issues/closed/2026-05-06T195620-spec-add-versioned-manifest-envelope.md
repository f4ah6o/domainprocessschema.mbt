# Generated manifest に version envelope を追加する

Created: 2026-05-06
Completed: 2026-05-10
Model: GPT-5.4 1.0.41

## 背景

現在の API / validation / GUI manifest は payload 直下の JSON を返しており、consumer が manifest kind や schema version を自己判別できない。  
破壊的変更検出や CI での互換性検査のためには、すべての generated manifest に共通 envelope が必要。

## 提案

既存の generated manifest を次の形に統一する。

```json
{
  "schemaVersion": "domainprocessschema.v1",
  "manifestKind": "<kind>",
  "generator": {
    "name": "domainprocessschema.mbt",
    "version": "0.1.0"
  },
  "payload": {}
}
```

初回 PR では `api-manifest` / `validation-manifest` / `gui-manifest` を対象にする。

## 受け入れ条件

- [x] 対象 manifest が共通 envelope を返す
- [x] `manifestKind` が consumer から機械判定できる
- [x] README / CLI examples / tests が新しい shape を前提に更新されている

## 非目標

- SQL や migration SQL の文字列出力に同じ envelope を被せること
- まだ存在しない `schema-diff` / `migration-plan` を同時に実装すること

## 根拠

現在の manifest renderer は `api_manifest.mbt` / `validation_manifest.mbt` / `gui_manifest.mbt` で個別に JSON を組み立てている。  
ここに共通 envelope を入れると、外部 consumer は payload の意味と version を安全に見分けられる。

## 解決方法

`api_manifest.mbt`、`validation_manifest.mbt`、`gui_manifest.mbt` は共通の `render_manifest_envelope` を通して JSON を返すようになっている。envelope は `schemaVersion`、`manifestKind`、`generator`、`payload` を持ち、`manifestKind` は `api-manifest` / `validation-manifest` / `gui-manifest` として consumer から機械判定できる。

README と `docs/schema-contract-v1.md` には envelope shape を記載し、expect test と `fixtures/expense_request/expected.*-manifest.json` も envelope 付き JSON を前提に更新済みであることを確認した。

SQL DDL と migration SQL の文字列出力には envelope を付けず、JSON manifest contract の対象外として維持した。
