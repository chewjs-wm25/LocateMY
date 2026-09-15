# Account Center 开发协作契约

> 状态：`Ready for Development`（2026-09-15；设计 AI〔项目负责人授权〕，ADR 0013）
> Owner：`A`；系统基线：`Baselined — 5d11769`；依赖波次：Wave 6
> 唯一公开入口：`package:locatemy/features/account_center/account_center.dart`

本文件是 Account Center 唯一的跨 Owner Development Contract，也是同名 HTML 的 Markdown 源。它固定公开 Dart seam、账户页组合、评估偏好完整快照、账户业务意图及联合验收；`lib/features/account_center/` 内的 Widget、状态管理、Supabase Adapter、订阅、并发/取消/重试和测试组织由 A 决定。字段、RLS 与 migration 只在 Schema Catalog；Auth、Privacy、预算预案和 Shell 各自仍由其 Owner 定义。

## 0. 固定阅读顺序与四项 Readiness

实施和审查严格按此顺序读取，后项只能补充前项已经固定的事实：

1. [账户中心](../../knowledge_base/locatemy_product/features/account.md)、[评估偏好](../../knowledge_base/locatemy_product/domain_objects.md#assessment-preferences-评估偏好)和[预算预案](../../knowledge_base/locatemy_product/domain_objects.md#budget-scenario-预算预案)；
2. [Feature map](../system/feature-map.md)、[Interface 注册表](../system/interfaces.md)、[FLOW-01](../system/flows.md#flow-01启动注册登录退出与账户切换)及 [FLOW-07](../system/flows.md#flow-07个人化地点适配度)；
3. [Capability Traceability](../system/capability-traceability.md)、[数据所有权](../system/data-ownership.md)、[Schema Catalog](../data/schema-catalog.md#身份与账户业务对象)及 [`RISK-PREF-01`](../system/risks-and-decisions.md#risk-pref-01)；
4. 本契约及同名 HTML；后项不能改写前项。

| Readiness | 可核查证据 | 结论 |
| --- | --- | --- |
| 责任与范围 | A 唯一拥有 `ACCOUNT-01`、`ACCOUNT-02`、`ACCOUNT-08`；认证退出、`ACCOUNT-09`、ICI、语言及目标业务数据仍归原 Owner | 已就绪 |
| 契约与消费者 | `ACCOUNT-001` 的唯一入口、公开声明、typed failures、调用顺序和 fake 在第 3 节；消费者为 Shell 与 Suitability | 已就绪 |
| 数据与安全 | A 只读写 owner-only `user_assessment_preferences`；真实身份只消费 `AUTH-001`，预案只消费 `COST-002`，没有直读 `auth.users`、`profiles` 或预案表 | 已就绪 |
| 验收与风险 | 第 5 节覆盖 `AT-AUTH-02`、`AT-HAZARD-01`、`AT-PROP-01`、`AT-SUIT-01`–`06`、`AT-OUT-01/02` 与 `AT-SWITCH-01`；`RISK-PREF-01` 的 null 语义已锁定 | 已就绪 |

## 1. 成果、责任与边界

- 已 opened 的账户看到 Auth 的真实邮箱和确认状态、已配置偏好或设置入口、Cost 的 current 预案摘要，以及房产档案、本人隐患、预案管理和确认退出入口。
- 用户只能以一次完整确认保存安全、成本、日常便利、公共交通可达性、基础设施五项 `1–10` 偏好；成功后形成跨设备恢复的同账户 complete snapshot，作为个人化地点适配度唯一偏好输入。
- `ACCOUNT-03`–`06` excluded：不呈现固定资料、演示统计、空回调或替代业务。

| Owner | 负责 | 不负责 | 协作 |
| --- | --- | --- | --- |
| Account Center（A） | 账户页组合、`ACCOUNT-001`、偏好完整确认/变化、账户与退出意图 | Auth/预算/ICI/语言/房产/隐患的数据规则或写入，退出完成 | 消费 `SHELL-001`、`AUTH-001`、`PRIVACY-001`、`COST-002`；提供给 Shell、Suitability |
| Application Shell | 账户入口、接受意图、返回语境、门控与退出编排 | 偏好持久化、真实 Auth/预算事实 | 唯一入口为 `submit(ShellIntent)` |
| Authentication & Session | 当前账户真实邮箱、确认状态和当前设备 sign-out | 账户页、scope、偏好 | `AUTH-001` |
| Account Privacy | opened/closed scope 与 Account 本机状态关闭证明 | 远端偏好、页面规则 | `PRIVACY-001` |
| Cost of Living & Budget | 预案 CRUD/current 和摘要事实 | Account 资料/偏好 | `COST-002` |

## 2. A 消费的 Interface 与精确数据对象

消费者只能 import 标明的入口，不 import 对方 `src/`、SDK 或表实现。

### `SHELL-001`：导航、账户业务与退出意图

**唯一公开 import：** `package:locatemy/app/application_shell.dart`

唯一 Shell seam 是 `ApplicationShell`；Account 只调用 `submit`，但必须消费下列完整 canonical 声明，不能以 submit-only、本地 outcome 或其他变体缩窄它。

```dart
abstract interface class ApplicationShell {
  Future<ShellIntentOutcome> submit(ShellIntent intent);
  Future<ShellContributionOutcome> publish(ShellContribution contribution);
}
abstract interface class ShellIntent {}
abstract interface class ShellContribution {}
sealed class ShellIntentOutcome { const ShellIntentOutcome(); }
final class ShellIntentAccepted extends ShellIntentOutcome { const ShellIntentAccepted(); }
final class ShellAuthenticationRequired extends ShellIntentOutcome { const ShellAuthenticationRequired(); }
final class ShellIntentRejected extends ShellIntentOutcome {
  final ShellRejectionReason reason;
  const ShellIntentRejected(this.reason);
}
enum ShellRejectionReason { missingInput, staleInput, inapplicableDestination, scopeUnavailable }

sealed class ShellContributionOutcome {}
final class ShellContributionAccepted extends ShellContributionOutcome {}
final class ShellContributionAuthenticationRequired extends ShellContributionOutcome {}
final class ShellContributionRejected extends ShellContributionOutcome {
  const ShellContributionRejected(this.reason);
  final ShellRejectionReason reason;
}
```

Account 的公开入口声明以下 marker；它们只代表导航/编排请求，不能携带目标 Feature 的私有 payload。

```dart
final class OpenPropertyInspectionsIntent implements ShellIntent {
  final AccountReturnContext returnContext;
  const OpenPropertyInspectionsIntent(this.returnContext);
}
final class OpenMyHazardsIntent implements ShellIntent {
  final AccountReturnContext returnContext;
  const OpenMyHazardsIntent(this.returnContext);
}
final class OpenBudgetScenarioManagementIntent implements ShellIntent {
  final AccountReturnContext returnContext;
  const OpenBudgetScenarioManagementIntent(this.returnContext);
}
final class RequestSignOutIntent implements ShellIntent {
  final AccountReturnContext returnContext;
  const RequestSignOutIntent(this.returnContext);
}
final class AccountReturnContext {
  final String source;
  const AccountReturnContext(this.source);
}
```

只有当前同账户 scope opened 时可提交。`ShellIntentAccepted` 才进入目标；`ShellAuthenticationRequired` 保持当前无私有内容路径；`ShellIntentRejected` 保留其 reason 并提供返回/重试，不能伪装成资料、偏好或预案失败。退出确认后 Shell 固定协调屏蔽私有内容 → `AUTH-001.signOut` → `PRIVACY-001.close(oldAccountId)`；Account 不直接结束会话。

```dart
final outcome = await applicationShell.submit(
  OpenBudgetScenarioManagementIntent(const AccountReturnContext('account-center')),
);
// 仅 ShellIntentAccepted 进入预算管理；其余结果保留在账户任务语境。
```

fake：Shell 分别返回 accepted、authenticationRequired、staleInput；验证不进入错误目标、拒绝原因不被改写，并且确认退出后 Account 不自行宣称成功。

### `AUTH-001`：真实身份资料

**唯一公开 import：** `package:locatemy/features/authentication_session/authentication_session.dart`

```dart
abstract interface class AuthenticationSession {
  Future<SessionSnapshot> restoreSession();
  Stream<SessionSnapshot> watchSession();
}
sealed class SessionSnapshot { const SessionSnapshot(); }
final class AuthenticatedSession extends SessionSnapshot {
  final AuthenticatedAccount account;
  const AuthenticatedSession(this.account);
}
final class UnauthenticatedSession extends SessionSnapshot { const UnauthenticatedSession(); }
final class SessionUnavailable extends SessionSnapshot {
  final SessionFailure failure;
  const SessionUnavailable(this.failure);
}
final class AuthenticatedAccount {
  final String accountId;
  final String email;
  final EmailConfirmation confirmation;
  const AuthenticatedAccount({required this.accountId, required this.email, required this.confirmation});
}
enum EmailConfirmation { confirmed, verificationRequired, unavailable }
enum SessionFailure { retryableUnavailable, unsupportedClient, remoteRejected }
```

Account 只把与 opened scope 同一 `accountId` 的 `email` 和 `confirmation` 组合进页面。`confirmed`、`verificationRequired`、`unavailable` 分别呈现已验证、待验证、状态不可得；`SessionUnavailable` 是 typed unavailable，不降级为未验证或旧值。Account 不读 `auth.users`、`profiles`、token 或缓存身份资料；精确数据库对象和权限仅见 Schema Catalog。

fake：同一 A 账户的三个 `EmailConfirmation` 与 `SessionUnavailable(retryableUnavailable)`；验证 unavailable 绝不显示 verified，account id 不匹配时不显示 A 的资料。

### `PRIVACY-001`：账户范围

**唯一公开 import：** `package:locatemy/features/account_privacy/account_privacy.dart`

```dart
abstract interface class AccountPrivacy {
  AccountScopeSnapshot readScope();
}
final class AccountScope { final String accountId; const AccountScope(this.accountId); }
sealed class AccountScopeSnapshot { const AccountScopeSnapshot(); }
final class AccountScopeOpened extends AccountScopeSnapshot {
  final AccountScope scope;
  const AccountScopeOpened(this.scope);
}
final class AccountScopeClosing extends AccountScopeSnapshot {
  final AccountScope scope;
  const AccountScopeClosing(this.scope);
}
final class AccountScopeClosed extends AccountScopeSnapshot {
  final AccountScope scope;
  const AccountScopeClosed(this.scope);
}
final class AccountScopeUnavailable extends AccountScopeSnapshot {
  final AccountScopeFailure failure;
  const AccountScopeUnavailable(this.failure);
}
enum AccountScopeFailure { identityMismatch, scopeNotOpen, scopeClosing, retryableUnavailable }
```

A 只在 Account Center 读取到与 Auth 同一 `accountId` 的 `AccountScopeOpened.scope` 时读取、保存或发布偏好和组合结果。`AccountScopeClosing`、`AccountScopeClosed`、`identityMismatch`、`scopeNotOpen`、`scopeClosing`、`retryableUnavailable` 均拒绝访问/发布；关闭开始即清除 A 的偏好内存/副本和账户页组合状态。关闭证明只代表该本机 payload 已处理，不删除远端 `user_assessment_preferences`、公共缓存或语言。

fake：A opened → closing/closed → B opened，验证 A 的资料、草稿、complete snapshot 与晚到响应都不进入 B。

### `COST-002`：current 预算预案

**唯一公开 import：** `package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart`

```dart
abstract interface class BudgetScenarioStore {
  Future<BudgetScenariosOutcome> read();
  Stream<BudgetScenariosOutcome> watch();
}
sealed class BudgetScenariosOutcome { const BudgetScenariosOutcome(); }
final class BudgetScenariosAvailable extends BudgetScenariosOutcome {
  final List<BudgetScenario> scenarios;
  final CurrentBudgetScenarioSnapshot current;
  const BudgetScenariosAvailable(this.scenarios, this.current);
}
final class BudgetScenariosUnavailable extends BudgetScenariosOutcome {
  final BudgetScenarioFailure failure;
  const BudgetScenariosUnavailable(this.failure);
}
sealed class CurrentBudgetScenarioSnapshot { const CurrentBudgetScenarioSnapshot(); }
final class CurrentBudgetScenarioAvailable extends CurrentBudgetScenarioSnapshot {
  final BudgetScenario scenario;
  final int version;
  const CurrentBudgetScenarioAvailable(this.scenario, this.version);
}
final class NoCurrentBudgetScenario extends CurrentBudgetScenarioSnapshot {
  final int version;
  const NoCurrentBudgetScenario(this.version);
}
enum BudgetScenarioFailure { invalidName, invalidAmount, notFound, conflict, permissionDenied, retryableUnavailable, scopeUnavailable }
```

`BudgetScenario` 是 B 的只读保存快照：Account 显示 name、additionalLivingExpenseRm、housingExpenseRm、transportExpenseRm、monthlyNetIncomeRm、householdMonthlyIncomeRm 与每项缺失状态。`CurrentBudgetScenarioAvailable` 才显示 current；`NoCurrentBudgetScenario` 仍保留管理入口；`BudgetScenariosUnavailable` 以其 enum 呈现恢复路径，不能伪装为空/no-current。Account 不读写精确表 `user_budget_scenarios`，不创建默认预案、不选择 current；月净收入只说明预算压力，家庭月度总收入只说明 Socio 收入位置，二者不可互代。

fake：current、no-current、仅一项收入、permissionDenied、retryableUnavailable；验证摘要版本变化使旧摘要失效，缺失保持缺失且两种收入不互换。

### 精确数据对象：评估偏好

Account 是精确 Supabase 表 `user_assessment_preferences` 的唯一读写 Owner；没有 Account 专属 RPC。Flutter 只在同账户 opened 路径访问该 owner-only CRUD 表。该表以 `user id` 为主键，字段为 `safety`、`cost`、`daily convenience`、`transit accessibility`、`infrastructure`（均为整数 `1–10`）、nullable `configured_at` 与 `updated at`。字段/RLS/migration 的唯一权威是 [Schema Catalog](../data/schema-catalog.md#身份与账户业务对象)：migration 必须 additive 地增加 `configured_at`，现有行保持 null，不能猜测升级。

`configured_at == null` 或无行都是 prerequisite missing；五个默认 `5` 仅是未保存表单预填。仅一次远端成功保存五个有效值且写入 `configured_at` 后才能发布 complete snapshot。后续成功修改必须保留已配置事实，使用新的 snapshot version。无离线写队列；validation、permission、conflict 或网络失败均保留最后已保存事实。

## 3. A 必须提供的 Interface

### `ACCOUNT-001`：评估偏好快照与账户页意图

**提供者：** Account Center（A）
**消费者：** Application Shell、Personalized Location Suitability
**唯一公开 import：** `package:locatemy/features/account_center/account_center.dart`

消费者只能 import 此入口，不能 import `lib/features/account_center/src/`。以下都是跨 Owner 声明，不是函数体、SQL、SDK 调用或 Widget 结构。

```dart
abstract interface class AccountCenter {
  Future<AssessmentPreferencesOutcome> readAssessmentPreferences();
  Stream<AssessmentPreferencesOutcome> watchAssessmentPreferences();
  Future<AssessmentPreferencesSaveOutcome> saveAssessmentPreferences(
    AssessmentPreferenceValues values,
  );
}

final class AssessmentPreferenceValues {
  final int safety;
  final int cost;
  final int dailyConvenience;
  final int transitAccessibility;
  final int infrastructure;
  const AssessmentPreferenceValues({
    required this.safety, required this.cost, required this.dailyConvenience,
    required this.transitAccessibility, required this.infrastructure,
  });
}

sealed class AssessmentPreferencesOutcome { const AssessmentPreferencesOutcome(); }
final class AssessmentPreferencesComplete extends AssessmentPreferencesOutcome {
  final CompleteAssessmentPreferencesSnapshot snapshot;
  const AssessmentPreferencesComplete(this.snapshot);
}
final class AssessmentPreferencesPrerequisiteMissing extends AssessmentPreferencesOutcome {
  const AssessmentPreferencesPrerequisiteMissing();
}
final class AssessmentPreferencesUnavailable extends AssessmentPreferencesOutcome {
  final AssessmentPreferencesFailure failure;
  const AssessmentPreferencesUnavailable(this.failure);
}

sealed class AssessmentPreferencesSaveOutcome { const AssessmentPreferencesSaveOutcome(); }
final class AssessmentPreferencesSaved extends AssessmentPreferencesSaveOutcome {
  final CompleteAssessmentPreferencesSnapshot snapshot;
  const AssessmentPreferencesSaved(this.snapshot);
}
final class AssessmentPreferencesSaveRejected extends AssessmentPreferencesSaveOutcome {
  final AssessmentPreferencesFailure failure;
  const AssessmentPreferencesSaveRejected(this.failure);
}

final class CompleteAssessmentPreferencesSnapshot {
  final String accountId;
  final AssessmentPreferenceValues values;
  final int version;
  final DateTime configuredAt;
  const CompleteAssessmentPreferencesSnapshot({
    required this.accountId, required this.values, required this.version, required this.configuredAt,
  });
}
enum AssessmentPreferencesFailure {
  invalidInput, permissionDenied, conflict, retryableUnavailable, scopeUnavailable,
}
```

| 调用 | 输入约束 | 成功输出 | typed failure / 消费者处理 |
| --- | --- | --- | --- |
| `readAssessmentPreferences` / `watchAssessmentPreferences` | 当前同账户 opened；无其他输入 | `AssessmentPreferencesComplete` 或 `AssessmentPreferencesPrerequisiteMissing` | `scopeUnavailable`、permission、network 等只以 `AssessmentPreferencesUnavailable` 返回，不能装作未配置 |
| `saveAssessmentPreferences` | 五项同时给出；各为整数 `1–10`；当前同账户 opened | 远端成功后 `AssessmentPreferencesSaved(complete snapshot)`；首次保存写入 configuredAt，后续保存递增 version 且保留 configuredAt | invalid 不写；conflict/permission/network/scope 保留最后已保存 snapshot，不发布草稿/部分值 |

**完整快照、权限与顺序。** `CompleteAssessmentPreferencesSnapshot` 必须是同一账户、完整五项、非 null `configuredAt` 与保存 version 的不可变组合；Suitability 只消费此结果，绝不从页面默认值、草稿、表存在或 `configured_at` 自行推导。保存完成或 `COST-002` current 成功变更后，由 Shell 使相同账户关联的 Suitability 请求失效；任何 account/scope/version 变化后的旧读写响应均丢弃。A 不写预算、ICI、语言、Auth 或目标 Feature 数据。

```dart
final result = await accountCenter.saveAssessmentPreferences(
  const AssessmentPreferenceValues(
    safety: 8, cost: 6, dailyConvenience: 7, transitAccessibility: 5, infrastructure: 9,
  ),
);
// 只有 AssessmentPreferencesSaved 的 snapshot 可交给 Suitability；Rejected 保留上次保存结果。
```

fake：提供 `PrerequisiteMissing`、A 的 complete version 4、`SaveRejected(conflict)`、A→B scope 切换以及 version 5。Suitability 验证仅 A 的 complete version 进入计算，冲突不更新，B 不继承 A，version 变化使旧结果不可发布；Shell 验证业务 intent 的 accepted/rejected 不影响 complete snapshot。

## 4. 协作交付顺序

1. **A 先合入公开 seam。** 建立唯一入口、`ACCOUNT-001` 声明、意图 marker 和最小 fake；Shell、Suitability 不依赖 A 的内部文件。
2. **A 完成账户组合和偏好边界。** 接入 `AUTH-001`、`PRIVACY-001`、`COST-002` 与 `user_assessment_preferences`；确认 null/default、五项原子保存、版本和本机关闭语义。
3. **消费者并行使用 fake。** Shell 只处理 typed intent、门控和返回；Suitability 只接受同账户 complete snapshot；Cost 继续独占预案。
4. **共同联调。** 按 FLOW-01/FLOW-07 接入真实 seam；Schema migration/RLS、两账户关闭与跨设备恢复的运行时证据由实现/集成验收取得。

## 5. 联合验收

| 场景 | Owner | 可观察结果 | 追踪 |
| --- | --- | --- | --- |
| 真实身份与确认状态 | A、Authentication、Shell | 仅同 scope 的真实 email/confirmed/pending/unavailable；未知不显示 verified | `ACCOUNT-01`；`AT-AUTH-02`、`AT-SWITCH-01` |
| 账户业务入口与返回 | A、Shell、Property、Hazard、Cost | accepted 才进入且可返回账户；目标未组合/过期/门控拒绝保留 reason，不泄露目标数据 | `ACCOUNT-02`；`AT-HAZARD-01`、`AT-PROP-01` |
| 首次完整确认 | A、Suitability、Shell | 新账户默认 5 仍是未配置；全部有效且远端成功才发布 complete snapshot；无效/失败不发布 | `ACCOUNT-08`；`AT-SUIT-01`–`03` |
| 修改、旧行与跨设备恢复 | A、Suitability | 已配置修改发布新 version；`configured_at null` 旧行仍未配置；跨设备仅恢复远端 complete snapshot | `ACCOUNT-08`；`AT-SUIT-01`、`AT-SUIT-04` |
| current 预案摘要 | A、Cost、Socio、Shell | current/no-current/缺失/不可用精确呈现；两种收入用途不可互代；管理 intent 不创建预案 | `ACCOUNT-09` 入口；`AT-SUIT-02`、`AT-SUIT-04` |
| 退出与两账户切换 | A、Shell、Authentication、Privacy、Suitability | 关闭起 A 组合/偏好不可读；成功才到普通登录；失败停在无私有内容恢复态；B 不继承 A | `ACCOUNT-07/08`；`AT-OUT-01/02`、`AT-SWITCH-01`、`AT-SUIT-06` |
| 可访问账户页 | A、Shell | 中文/English、读屏、键盘/替代输入、200% 字体、长邮箱和错误状态均有文字、名称和可理解顺序 | `ACCOUNT-01/02/08`；上述 `AT-*` |

## 6. 实现自由、Gate 与检查

A 可决定内部文件、Widget、状态机、Supabase Adapter、订阅、取消/重试、冲突策略、局部校验及测试组织。以下变更必须暂停协商：唯一公开 import、公共声明/result variant、五项完整性、snapshot version、权限/副作用/顺序、`user_assessment_preferences` 的 Schema/RLS，或 Auth/Privacy/Cost/Shell 的 owning contract。

实现 Gate：`user_assessment_preferences` 仍是 proposed。实现前必须验证 owner-only RLS、`user id` 主键、五个整数 `1–10`、nullable `configured_at` 的 additive migration、旧行保持 null、两账户隔离及远端成功后才发布。不得以 fixture 宣称 migration/RLS 完成；该 Gate 不改变本 Feature 的 Ready 状态。

- [x] 四项 Readiness 均可核查。
- [x] `ACCOUNT-001` 有唯一入口、声明、输入、typed outputs/failures、完整快照、权限/副作用/顺序、示例和 fake。
- [x] Shell/Auth/Privacy/Cost-002 均列唯一入口、声明级协作形状、约束、typed failures 与 fake；唯一 Shell seam 是 `ApplicationShell.submit(ShellIntent)`。
- [x] 精确 DB 对象为 `user_assessment_preferences`，无 Account RPC；消费者不直读 Auth、profiles 或预算表。
- [x] 不含函数体、SDK、SQL、migration、测试实现或 Widget 结构；联验覆盖资料、意图、偏好、预案、退出和 A→B 隔离。

公共 Interface 变更由提供方说明原因与消费者，所有受影响消费者确认；同一 PR 更新公开声明、本契约、同名 HTML 与受影响 fake/Adapter 测试。Git/PR 保存历史；不使用文档版本、checksum、Manifest、Generation Gate、Development Release、PDF 或 ADR 0014/handoff 治理。

## 7. Change Log

| 日期 | 状态 | 变更原因 | 受影响对象 | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-15 | `Ready for Development` | Issue #23：改为单一 Development Contract 与同名 HTML；删除 PDF/ADR 0014/handoff 治理，Account 的 HTML 依固定阅读顺序重导出。同步 Shell 的 canonical `submit`/`publish` 和 Privacy 的 `readScope`/scope snapshot 声明。 | `ACCOUNT-001`、`SHELL-001`、`PRIVACY-001`、`user_assessment_preferences`、`account-center.html` | 设计 AI（项目负责人授权） |
