# External test case research

Created: 2026-05-15

`domainprocessschema.mbt` の追加テスト候補を、既存実装に移植しやすい形で整理する。
外部コードをコピーするのではなく、公開仕様や公式ドキュメントに出てくる挙動を
MoonBit の独自 YAML / runtime test / fixture に書き起こす前提で扱う。

## Sources

- XState Guards: <https://stately.ai/docs/guards>
- AWS Step Functions / Amazon States Language:
  <https://docs.aws.amazon.com/step-functions/latest/dg/concepts-amazon-states-language.html>
- Camunda 7 gateway quick start:
  <https://docs.camunda.org/get-started/quick-start/gateway/>
- Flowable holiday request example:
  <https://www.flowable.com/open-source/docs/bpmn/ch02-GettingStarted/>
- JSON Forms rules: <https://jsonforms.io/docs/uischema/rules>
- JSON Schema Test Suite:
  <https://github.com/json-schema-org/JSON-Schema-Test-Suite>

## Selection policy

- Priority 1: current contract / runtime にそのまま落とせるケース。
- Priority 2: `transition-semantics-v1` / `expression-language-v1` の仕様化に使えるケース。
- Priority 3: BPMN や JSON Schema の完全互換ではなく、業務ルールとして移植できるケース。

既存 `expense_request` fixture と同じ happy path は採用しない。追加候補は、分岐、
失敗、未定義、fallback、UI projection のどれかを固定するものに絞る。

## Recommended additions

| ID | Source | Target | Scenario | Expected behavior |
| --- | --- | --- | --- | --- |
| `runtime-guard-order-default` | XState multiple guarded transitions | `runtime_test.mbt` | 同じ現在 state から `approveSmall` / `approveLarge` / fallback 相当の transition を持つ。`amount < 1000`、`amount >= 1000`、どちらでもない値を試す。 | `list_transitions` は guard true の transition だけを available にする。fallback は現行 contract には無いので `future spec` として記録し、現行 test では「どちらも false なら available なし」を期待する。 |
| `runtime-exclusive-approval-path` | Flowable holiday request | `runtime_test.mbt` | manager が `approved` boolean input を送ると、true は `approved`、false は `rejected` に進む。 | transition-local input が runtime に渡され、`approved == true` / `approved == false` の guard が分岐を決める。 |
| `runtime-wrong-state-rejected` | state machine semantics | `runtime_test.mbt` | `draft` record に対して `approve` を直接適用する。 | `apply_transition` は state mismatch を structured runtime error として返す。 |
| `runtime-role-and-guard-both-required` | XState guard + BPMN user task | `runtime_test.mbt` | manager role だが guard false、または guard true だが role 不一致。 | どちらか一方だけでは transition は available にならない。error issue は role / guard の原因を識別できる。 |
| `expr-precedence-and-or-not` | XState higher-level guards | expression test | `amount > 0 && user.role == "manager" || state == "draft"` と括弧付き variant を評価する。 | parser と runtime evaluator が同じ precedence を使う。括弧で結果が変わることを固定する。 |
| `expr-unknown-context-path` | JSON Forms `scope` undefined handling comparison | validation/runtime test | `user.department.name == "sales"` のような未提供 actor path を評価する。 | 現行 v1 で undefined を true 扱いしない。diagnostic は unknown/missing path を明示する。 |
| `gui-rule-hide-show-equivalent` | JSON Forms rules | `fixtures` または `runtime_test.mbt` | `amount >= 1000` のときだけ `managerComment` を readonly/display 対象にする候補。 | 現行 schema では rule が view field visibility を直接変えないため `future spec`。今は `evaluate_rules` と `project_gui.rules` に active/inactive が出ることだけ固定する。 |
| `gui-readonly-disable-equivalent` | JSON Forms `DISABLE` / `ENABLE` | `runtime_test.mbt` | state が `submitted` の時は amount/reason readonly、`draft` の時は editable。 | `project_gui` の field mode が state view と一致する。既存テストが薄ければ field mode の配列まで snapshot する。 |
| `contract-choice-default-fail` | Amazon States Language Choice + Fail | diagnostics test | どの guard も true にならない transition group と default/fail の扱いを比較する。 | 現行 schema に default transition はない。追加仕様にするまでは、no available transition を正常な runtime projection として扱う。 |
| `contract-start-state-name-mismatch` | ASL `StartAt` name matching | validation test | state field の `initial` が declared state と大文字小文字違い。 | validator は case-sensitive に `UNKNOWN_STATE` 相当を返す。 |
| `storage-relation-target-mismatch` | schema validator pattern | fixture or validation test | `field: applicant` は `target: User` だが relation 側 target は `Team`。 | relation target と ref field target の不一致を validation error にする。既存 coverage があれば golden fixture にはしない。 |
| `json-schema-required-default` | JSON Schema Test Suite | validation test | default を持つ optional field、required field、type mismatch を同時に含む record。 | default は missing を補うが、required true で default なしの field は diagnostic。型違いは constraint ではなく field validation issue。 |
| `manifest-localized-fallback-chain` | JSON Forms labels / current locale support | fixture | `ja-JP` request、`ja` label あり、`default` label あり、どちらも無い field を混ぜる。 | exact -> base language -> default -> name の順に解決される。既存 smoke test ではなく manifest 全体で固定する。 |
| `diagnostic-unsupported-yaml-feature` | YAML subset contract | diagnostics test | quoted scalar、anchor、tab indent、advanced tag のうち v1 非対応を1つずつ入力する。 | parser diagnostic は `ParseError` として返り、target / message が consumer に表示できる。 |
| `audit-transition-applied-rejected` | audit event issue | future spec | approve 成功と role mismatch rejection の event shape を比較する。 | `transition.applied` / `transition.rejected` に entity、transition、from/to、actor、input、issues が入る。現行実装では issue/spec 用の候補。 |

## Candidate fixture scenarios

### `fixtures/approval_routing`

Flowable の holiday request と Camunda の gateway quick start を元にする。BPMN XML は
使わず、`HolidayRequest` entity として再表現する。

- Fields: `id`, `employee`, `days`, `reason`, `approved`, `status`, `createdAt`.
- States: `draft`, `submitted`, `approved`, `rejected`.
- Transitions:
  - `submit`: `draft` -> `submitted`, requires `days > 0`.
  - `approve`: `submitted` -> `approved`, role `manager`, guard `approved == true`.
  - `reject`: `submitted` -> `rejected`, role `manager`, guard `approved == false`.
- Tests:
  - SQL / normalized / API / GUI manifest golden.
  - Runtime: true path, false path, missing `approved`, wrong role, wrong state.

### `fixtures/high_value_payment`

Camunda gateway quick start の `<1000` / `>=1000` 分岐を元にする。現行 schema は同一
transition name の ordered guards を持たないので、別 transition として表現する。

- Fields: `id`, `amount`, `status`, `managerComment`.
- States: `draft`, `autoApproved`, `needsApproval`, `approved`, `rejected`.
- Transitions:
  - `submitSmall`: `draft` -> `autoApproved`, guard `amount < 1000`.
  - `submitLarge`: `draft` -> `needsApproval`, guard `amount >= 1000`.
  - `approve`: `needsApproval` -> `approved`, role `manager`.
  - `reject`: `needsApproval` -> `rejected`, role `manager`, local input `managerComment`.
- Tests:
  - guard true/false matrix.
  - `project_gui` field mode for `draft` vs `needsApproval`.
  - no available transition when `amount` is missing or invalid.

### `fixtures/form_rules`

JSON Forms rules を元にする。現行 schema では rule が直接 hide/show を実行しないため、
`evaluate_rules` と `project_gui.rules` の stable output を固定する。

- Fields: `id`, `counter`, `name`, `needsDetail`, `detail`, `status`.
- Rules:
  - `counterIsTen`: `counter == 10`.
  - `nameIsFooOrBar`: `name == "foo" || name == "bar"`.
  - `needsDetail`: `needsDetail == true`.
- Tests:
  - rule active/inactive matrix.
  - GUI projection に rule statuses が出る。
  - future spec として rule-driven visibility を別 issue に切る。

## Implementation order

1. `runtime_test.mbt` に `runtime-wrong-state-rejected` と
   `runtime-role-and-guard-both-required` を追加する。既存 schema helper を再利用でき、
   fixture 更新が不要。
2. `expr-precedence-and-or-not` を expression parser/evaluator の最小テストとして追加する。
   `expression-language-v1` の仕様化前に precedence の実装差分を見つけやすい。
3. `fixtures/high_value_payment` を作り、normalized/API/validation/GUI の golden を追加する。
   SQL/migration は storage 差分が小さい場合だけ固定する。
4. `fixtures/approval_routing` を作り、transition-local boolean input と role/guard の分岐を
   runtime fixture として固定する。
5. `fixtures/form_rules` は rule-driven visibility の仕様が決まるまで future spec に留める。

## Notes

- BPMN 互換は v1 の非目標なので、BPMN XML parser のテストは作らない。
- ASL の `Choice` / `Fail` は、default transition を追加する根拠にはなるが、現行 v1 では
  no available transition と runtime diagnostic の整理に使う。
- JSON Forms は UI schema と data schema が分かれている。`domainprocessschema.mbt` では
  `views` と `rules` が近い役割を持つが、rule が field visibility を直接変更する仕様はまだ無い。
- JSON Schema Test Suite は網羅性の考え方だけ借りる。JSON Schema 互換 validator を目指さない。
