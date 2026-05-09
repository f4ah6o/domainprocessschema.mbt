# normalized-schema CLI / public API を追加する

Created: 2026-05-06
Completed: 2026-05-10
Model: GPT-5.4 1.0.41

## 背景

外部 consumer は現在 YAML parser に依存するか、個別 manifest から必要情報を逆算するしかない。  
validated `Schema` を正式 JSON output として公開すれば、GUI / API / migration / diff の共通入力として再利用しやすくなる。

## 提案

- `normalized-schema` renderer を追加する
- public API と CLI mode を追加する
- output には version envelope を含める

## 受け入れ条件

- [x] `moon run cmd/main -- normalized-schema <schema.yaml>` が動く
- [x] public API から normalized schema JSON を取得できる
- [x] README / tests が新しい output を説明している

## 非目標

- schema diff / migration plan まで同時に実装すること
- YAML parser 自体を置き換えること

## 根拠

runtime と generators はすでに validated `Schema` を共有しており、normalized JSON は自然な公開面になる。  
この出力があると、上位ツールは YAML subset の実装差異に引きずられずに済む。

## 解決方法

`normalized_schema.mbt` の `generate_normalized_schema` と `compile_normalized_schema_from_yaml` を public API として確認し、`cmd/main/main.mbt` の `normalized-schema` mode が同じ output を返すことを確認した。出力は `manifestKind: "normalized-schema"` を持つ versioned envelope で、`fixtures/expense_request/expected.normalized-schema.json` と `fixtures_test.mbt` の golden test によって固定されている。

README には normalized schema output の位置づけ、quick start の CLI 例、public API 名を追記した。実装済み surface の文書化と issue close が主目的のため、version 番号や追加 generator は変更していない。
