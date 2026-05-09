# moon.mod.json の description / keywords を実態に合わせて更新する

Created: 2026-05-06
Completed: 2026-05-10
Model: GPT-5.4 1.0.41

## 背景

現在の `moon.mod.json` は description が SQL generation 寄りで、keywords も現在の manifest / runtime / GUI scope を十分に表していない。  
README との整合を取るには package metadata の更新が必要。

## 提案

- description を storage / API / validation / GUI / runtime manifest を含む表現へ更新する
- keywords に `workflow` / `state-machine` / `manifest` / `validation` / `gui` などを追加する

## 受け入れ条件

- [x] `moon.mod.json` の description が現在の repository scope を表している
- [x] keywords が README と整合している
- [x] metadata 更新が docs / README の説明と矛盾しない

## 非目標

- version 番号の更新
- publish workflow の追加

## 根拠

検索性と package discovery は module metadata に強く依存する。  
ここを更新すると、この repository が単なる SQL generator ではなく contract-oriented schema compiler だと伝わりやすくなる。

## 解決方法

`moon.mod.json` の description を SQL generation 専用の説明から、validation、manifest、GUI preview、runtime workflow、SQL generation を含む説明へ更新した。

keywords には `workflow`、`state-machine`、`manifest`、`validation`、`gui`、`runtime` を追加し、README に書かれている現在の生成 artifact と runtime scope に合わせた。

version 番号、dependency、publish workflow は変更していない。
