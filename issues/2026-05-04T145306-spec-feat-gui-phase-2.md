# feat: GUI 生成仕様 — Phase 2

Created: 2026-05-04

Model: gh-migrate

## Summary

feat: GUI 生成仕様 — Phase 2

## Original Issue

- [GitHub #2](https://github.com/f4ah6o/domainprocessschema.mbt/issues/2)


## Description

# GUI 生成仕様 — Phase 2

## 概要
`compile_gui_manifest_from_yaml` が出力する JSON マニフェストを消費し、状態遷移型のフォーム UI を自動生成する。

## 1. マニフェスト → UI 要素

| マニフェスト要素      | UI 要素                                   |
|------------------------|-------------------------------------------|
| `entity.name/label`    | ページタイトル・ヘッダ                    |
| `view.fields[].component` | 入力部品（text/textarea/number/money/checkbox/date-picker/datetime-picker/select/reference-select/state-badge/file-upload） |
| `view.fields[].mode`   | 編集可否（editable/readonly/hidden）     |
| `view.actions[]`       | 送信ボタン（label=transition.name, 有効条件=enabledWhen, role） |
| `states[].name/label`  | ステータスバッジ（state-badge）           |
| `rules[].when`         | アクションボタンの活性/非活性ロジック    |

## 2. 画面遷移フロー（§16 実行モデル）

```
Entity取得 → 現在state判定 → 該当view選択 → 利用可能transition列挙 → rule評価 → ボタン活性制御 → フォーム描画
```

各 state に対応する view をタブまたは画面切替で表示。
transition 実行後は再度 state を取得して再描画。

## 3. コンポーネント → UI マッピング

| FieldType      | component         | HTML/Web 向け              |
|---------------|-------------------|----------------------------|
| id            | text              | `<input type="text" readonly>` |
| text          | textarea          | `<textarea>`               |
| number        | number            | `<input type="number">`    |
| money         | money             | `<input type="number" step="0.01">` + 通貨表示 |
| boolean       | checkbox          | `<input type="checkbox">`  |
| date          | date-picker       | `<input type="date">`      |
| datetime      | datetime-picker   | `<input type="datetime-local">` |
| enum          | select            | `<select>`                 |
| ref           | reference-select  | 検索付きセレクト（非同期） |
| state         | state-badge       | `<span class="badge">`     |
| file          | file-upload       | `<input type="file">`      |

## 4. 実行モデル — ✅ 実装済み (456ebbe)

~§16 の実行モデルは [`runtime_engine.mbt`](https://github.com/f4ah6o/domainprocessschema.mbt/blob/main/runtime_engine.mbt) でインメモリランタイムとして実装済み。~

### 提供 API

| 関数 | 役割 |
|------|------|
| `build_runtime(schema)` | Runtime オブジェクト構築 |
| `validate_record(runtime, entity_name, payload)` | レコードの型・必須・制約チェック |
| `list_transitions(runtime, record, actor?)` | 現在の state と actor から実行可能 transition を列挙 |
| `apply_transition(runtime, record, transition_name, input?, actor?)` | transition 実行 → state 更新・guard・role・必須チェック |

### 実行フロー（§16 の具体化）

```
1. Runtime 構築
2. validate_record → 型チェック・必須・制約評価 → RuntimeValidation
3. list_transitions → 現在stateから遷移可能な操作を列挙 → RuntimeTransitionStatus[]
4. apply_transition → guard/role/input検証 → 成功なら更新後レコード、失敗なら RuntimeError::TransitionRejected
```

### 式評価

[~`runtime_eval.mbt`~](https://github.com/f4ah6o/domainprocessschema.mbt/blob/main/runtime_eval.mbt) が `&&`/`||`/`==`/`!=`/`>`/`>=`/`<`/`<=`/`!`/`path.field`/リテラルを実行時評価。`state`・`user.role` などのコンテキスト参照に対応。

## 5. 今後の検討事項

- [x] ~実行モデルのインメモリ実装~ → 456ebbe で完了
- [ ] レンダリング対象の選定（React/Vue/Svelte/Web Components / MoonBit WASM）
- [ ] スキーマ駆動フォームライブラリの既存品調査
- [ ] フォームバリデーションと validation_manifest の統合
- [ ] 多言語対応（label の i18n）
- [ ] エラーハンドリング UI
- [ ] ランタイム → 画面描画のブリッジ（runtime の出力を UI フレームワークに接続するグルーコード生成）
