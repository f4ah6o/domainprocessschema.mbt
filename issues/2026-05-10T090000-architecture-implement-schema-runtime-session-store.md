# schema + runtime session store を実装する

Created: 2026-05-10
Model: GPT-5 Codex
Category: architecture
Status: open

## Summary

schema source、selection、actor、record、compile/runtime/graph/locale を持つ
durable session store を定義・実装する。

## Why

既存の Worker demo は browser 側が source と runtime state を持ち、Worker API は
stateless に近い。App Server client から同じ schema 編集 session を reopen するには、
source YAML、選択状態、actor、record、compile 結果、runtime view、graph、locale を
ひとつの durable session state として扱う必要がある。

後方互換性は不要なので、browser-local state ではなく App Server session を source of
truth とする。

## Scope

- Session store の top-level section を定義する。
- `source`、`selection`、`actor`、`record`、`compile`、`runtime`、`graph`、
  `locale`、`lastAction` を保持する。
- compile / transition / inspector edit 後の snapshot 更新規則を定義する。
- store の import/export JSON envelope を定義する。
- runtime core は library のまま保ち、HTTP / UI transport を混ぜない。

## Acceptance Criteria

- [ ] session store shape が文書化または型として定義されている。
- [ ] required top-level section が plan どおり含まれている。
- [ ] source YAML 変更後に compile/runtime/diagnostics が更新される規則がある。
- [ ] actor/record/locale/selection の resume semantics が定義されている。
- [ ] session snapshot export が stable JSON envelope を返す。
- [ ] runtime core に transport 責務を入れない方針が守られている。

## Non-goals

- Shared App Server repo の実装
- VS Code extension 実装
- HTTP server を runtime core に埋め込むこと
- browser-local state key の互換維持

## Rationale

domainprocessschema の強みは、schema compiler と runtime session を同じ domain model
で扱えることにある。durable session store を先に実装すれば、schema editor、runtime
preview、transition 実行を App Server client から一貫して操作できる。
