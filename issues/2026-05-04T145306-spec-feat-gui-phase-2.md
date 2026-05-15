# GUI 生成仕様 — Phase 2 残タスク

Created: 2026-05-04

Model: gh-migrate unknown

## 背景

GUI manifest と runtime core の基礎はすでに揃っているが、Phase 2 として
想定していた「UI フレームワークへつなぐ残りの application 層」はまだ
未整理のまま open issue に残っている。

runtime core の実装済み範囲と、これから詰めるべき UI integration の範囲を
この issue で切り分け直す。

## 提案

この issue は Phase 2 全体を再実装する umbrella ではなく、次の残タスクの
仕様整理として扱う。

- runtime core の既完了範囲を前提として固定する
- UI framework 選定と bridge layer の責務を明文化する
- validation / i18n / error handling / runtime-to-UI bridge を残タスクとして
  追跡する

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

## 4. 実行モデル — 実装済み (456ebbe)

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

## 受け入れ条件

- [ ] runtime core の既完了範囲と、この issue で扱う残タスクの境界が明記
      されている
- [ ] UI framework 選定で決めるべき論点が列挙されている
- [ ] validation / i18n / error handling / runtime-to-UI bridge が残タスクと
      して明文化されている
- [ ] この issue 単体を読めば、実装済みの runtime core を再発明せずに
      follow-up を始められる

## 非目標

- runtime core をこの issue で再実装すること
- persistence / HTTP server を runtime core に足すこと
- 具体的な UI framework 実装をこの issue の記述だけで確定させること

## 根拠

open issue のまま「実装済み」と「未実装」が混在すると、何が残件か分からず
着手順序を誤りやすい。  
先に既完了範囲を固定し、UI integration だけを残課題として分けることで、
Phase 2 の follow-up を安全に進めやすくする。
