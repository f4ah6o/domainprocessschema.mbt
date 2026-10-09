# Generated manifest に version envelope を追加する

Created: 2026-05-06
Completed: 2026-10-09
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

- [ ] 対象 manifest が共通 envelope を返す
- [ ] `manifestKind` が consumer から機械判定できる
- [ ] README / CLI examples / tests が新しい shape を前提に更新されている

## 非目標

- SQL や migration SQL の文字列出力に同じ envelope を被せること
- まだ存在しない `schema-diff` / `migration-plan` を同時に実装すること

## 根拠

現在の manifest renderer は `api_manifest.mbt` / `validation_manifest.mbt` / `gui_manifest.mbt` で個別に JSON を組み立てている。  
ここに共通 envelope を入れると、外部 consumer は payload の意味と version を安全に見分けられる。

## 解決方法

`render_manifest_envelope`（contract_support.mbt）により `api-manifest` / `validation-manifest` / `gui-manifest` が `schemaVersion` / `manifestKind` / `generator` / `payload` の共通 envelope を返す（2c6a4d4、PR #17）。tests・fixtures も新しい shape を前提に更新済み。

main 805e8b1 で確認。
