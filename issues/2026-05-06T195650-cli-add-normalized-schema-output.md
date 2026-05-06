# normalized-schema CLI / public API を追加する

Created: 2026-05-06
Model: GPT-5.4 1.0.41

## 背景

外部 consumer は現在 YAML parser に依存するか、個別 manifest から必要情報を逆算するしかない。  
validated `Schema` を正式 JSON output として公開すれば、GUI / API / migration / diff の共通入力として再利用しやすくなる。

## 提案

- `normalized-schema` renderer を追加する
- public API と CLI mode を追加する
- output には version envelope を含める

## 受け入れ条件

- [ ] `moon run cmd/main -- normalized-schema <schema.yaml>` が動く
- [ ] public API から normalized schema JSON を取得できる
- [ ] README / tests が新しい output を説明している

## 非目標

- schema diff / migration plan まで同時に実装すること
- YAML parser 自体を置き換えること

## 根拠

runtime と generators はすでに validated `Schema` を共有しており、normalized JSON は自然な公開面になる。  
この出力があると、上位ツールは YAML subset の実装差異に引きずられずに済む。
