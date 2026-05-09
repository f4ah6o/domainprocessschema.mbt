# Schema Contract v1 を明文化する

Created: 2026-05-06
Completed: 2026-05-10
Model: GPT-5.4 1.0.41

## 背景

現在の schema 仕様は README、tests、validator 実装に分散しており、外部 consumer が依存してよい contract が明文化されていない。  
GUI generator / API generator / migration tool / runtime が同じ入力に依存する以上、stable / experimental / internal を分けた仕様書が必要。

## 提案

`docs/schema-contract-v1.md` を追加し、少なくとも以下を定義する。

- YAML grammar
- Entity / Field / Relation / Constraint / State / Transition / Rule / View / Storage contract
- label resolution
- expression language との境界
- backward compatibility policy
- unsupported features
- stable / experimental / internal の分類

## 受け入れ条件

- [x] `docs/schema-contract-v1.md` が追加されている
- [x] README と validator 実装に存在する現在の仕様が v1 contract として整理されている
- [x] backward compatibility policy と unsupported features が明記されている

## 非目標

- expression language の完全仕様をこの issue 単体で完結させること
- schema diff や migration policy まで同時に実装すること

## 根拠

現在の public API は `parse_schema_yaml` / `validate_schema` / 各種 manifest generator を公開しているため、schema 自体が低レベル入力 contract になっている。  
その contract を文書で固定しないと、上位ツールが「どこまで依存してよいか」を判断できない。

## 解決方法

`docs/schema-contract-v1.md` で schema grammar、top-level schema、entity / field / relation / constraint / state / transition / rule / view / storage、label resolution、expression language boundary を v1 contract として整理した。

同文書には stable / experimental / internal の分類、backward compatibility policy、unsupported features も含めた。expression language の完全仕様や schema diff / migration policy は非目標のまま、別 issue で扱う前提を維持した。

`docs/versioned-contract-roadmap.md` の issue 参照は、この issue の close に合わせて `issues/closed/` 側へ更新した。
