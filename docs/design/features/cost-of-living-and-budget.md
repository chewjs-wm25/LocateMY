# Cost of Living & Budget 开发协作契约

> 状态：`Ready for Development`（2026-09-15；设计 AI〔项目负责人授权〕，ADR 0013）
> Owner：`B`；系统基线：`Baselined — 5d11769`；依赖波次：Wave 5
> 唯一公开入口：`package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart`

本文件是 Cost of Living & Budget 唯一的跨 Owner Development Contract，也是同名 HTML 的 Markdown 源。它固定公开 Dart seam、稳定读取对象、结果语义、权限、次序和联验；`lib/features/cost_of_living_budget/` 内的 Widget、状态管理、Adapter、缓存键、查询/并发/取消/重试、公式代码与测试组织均由 B 决定。公式正文只在产品知识库，字段、RLS 与 migration 只在 Schema Catalog。

**定义完成：** 对合法 immutable 单点，页面可如实展示本地价格、`ObservedSpend12`、覆盖率及满足门槛时的地点成本指数；对同账户完整 current 预案，才另展示 `ScenarioSpend12` 与个人预算压力。A/B 保留原顺序，只在同篮子版本、窗口和元数据兼容时显示差异。预案 CRUD/current、两种收入边界、临时 CPI 等效换算及 A→B 隔离均按本契约可观察；缺失、partial、不可比、认证或 scope 故障必须保留其 typed 原因，绝不补零、猜测或自动选择预案。

## 0. 固定阅读顺序与四项 Readiness

实施和审查按顺序读取，后项只能补充而不能改写前项：

1. [生活成本与预算](../../knowledge_base/locatemy_product/features/cost_of_living.md)、[统一生活篮子 v1](../../knowledge_base/locatemy_product/cost_basket_v1.md)、[账户](../../knowledge_base/locatemy_product/features/account.md)；
2. [Feature map](../system/feature-map.md)、[Interface 注册表](../system/interfaces.md)、[FLOW-02](../system/flows.md#flow-02单点完整分析)、[FLOW-03](../system/flows.md#flow-03地点-ab-比较)、[FLOW-07](../system/flows.md#flow-07个人化地点适配度)；
3. [Capability Traceability](../system/capability-traceability.md)、[数据所有权](../system/data-ownership.md)、[Schema Catalog](../data/schema-catalog.md#身份与账户业务对象)、[`RISK-COST-01`](../system/risks-and-decisions.md#risk-cost-01)；
4. 本契约及同名 HTML；HTML 是供人阅读的等价导出，不产生平行工作包或新的治理事实。

| Readiness | 可核查证据 | 结论 |
| --- | --- | --- |
| 责任与范围 | B 唯一拥有 `COST-01`–`03`、`ACCOUNT-09`；`COST-04` excluded；地点、Geo、scope、适配度和 Socio 仍归原 Owner | 已就绪 |
| 契约与消费者 | `COST-001`、`COST-002` 的唯一入口、声明、失败、顺序和 fake 场景均在第 3 节 | 已就绪 |
| 数据与安全 | Flutter 仅读 security-invoker `read_cost_inputs`；预案仅 `user_budget_scenarios` owner-only CRUD；公共缓存无账户/预案/收入/临时输入 | 已就绪 |
| 验收与风险 | 第 5 节覆盖 `AT-ANALYSIS-01`、`AT-COMPARE-01/03`、`AT-SUIT-02/04/06`；`RISK-COST-01` 的口径锁定 | 已就绪 |

## 1. 成果、责任与边界

- 合法单点显示真实单位的本地价格、`ObservedSpend12`、覆盖率和合格时地点成本指数；同账户完整 current 预案时另显示 `ScenarioSpend12`、地点基线及个人预算压力。
- A/B 复用同一篮子版本和月份窗口；仅元数据可比时显示差异。预案可 CRUD/选择；每账户至多一份 current，删除 current 后明确为无 current，绝不自动选择别份。
- 无可用预案金额时可做页面内存的 CPI 等效换算；它不保存，绝不进入压力或适配度。

| Owner | 负责 | 不负责 | 协作 |
| --- | --- | --- | --- |
| Cost of Living & Budget（B） | `COST-001`/`002`、成本模型应用、3 天公共缓存、`STATE-COST-TEMP`、预案 CRUD/current | 地点、行政区匹配、Shell、scope、Schema/RLS/migration、适配度和偏好 | 消费 Shell、Location、Geo、Privacy、`read_cost_inputs` |
| Shell | 成本/预案导航、返回语境和组合呈现 | Cost 计算、预案写入、可比性 | 消费 Cost 两 seam |
| Map / Geo | 合法 immutable 地点；行政区/州及边界版本 | 成本与预案规则 | `LOCATION-001` / `GEO-001` |
| Privacy | 同账户 scope 与关闭证明 | Cost payload 或远端预案 | `PRIVACY-001` |

## 2. B 消费的 Interface / 读取对象

完整语义仍属 owning document；B 只能 import 指定入口，不能 import 对方 `src/` 或 SDK。

### `SHELL-001`：导航与组合

**唯一公开 import：** `package:locatemy/app/application_shell.dart`

下列为 [Application Shell](../modules/application-shell.md#shell-001--application-coordination) 的完整 canonical 声明；Cost 不得自行缩窄、复制或改名其中任一公开类型。

```dart
abstract interface class ApplicationShell {
  Future<ShellIntentOutcome> submit(ShellIntent intent);
  Future<ShellContributionOutcome> publish(ShellContribution contribution);
}

abstract interface class ShellIntent {}
abstract interface class ShellContribution {}

sealed class ShellIntentOutcome { const ShellIntentOutcome(); }
final class ShellIntentAccepted extends ShellIntentOutcome {}
final class ShellAuthenticationRequired extends ShellIntentOutcome {}
final class ShellIntentRejected extends ShellIntentOutcome {
  const ShellIntentRejected(this.reason);
  final ShellRejectionReason reason;
}
sealed class ShellContributionOutcome { const ShellContributionOutcome(); }
final class ShellContributionAccepted extends ShellContributionOutcome {}
final class ShellContributionAuthenticationRequired extends ShellContributionOutcome {}
final class ShellContributionRejected extends ShellContributionOutcome {
  const ShellContributionRejected(this.reason);
  final ShellRejectionReason reason;
}
enum ShellRejectionReason {
  missingInput,
  staleInput,
  inapplicableDestination,
  scopeUnavailable,
}
```

B 在自己的入口声明 `OpenCostIntent`、`OpenCostComparisonIntent` 和 `OpenBudgetScenarioIntent` 等 `ShellIntent` marker。分析 intent 携带 `LOCATION-001` immutable 引用，比较携带 A/B 原顺序和返回语境；若 Cost 向 Shell 组合结果，则使用同一 canonical `ShellContribution` / `publish`。只有同账户 `opened` 可提交或发布；accepted 才导航或组合，authenticationRequired 保持原页，rejected 仅表示导航/组合拒绝，不能改写为资料失败。Shell 不得改写地点、预案或临时输入。

```dart
final result = await applicationShell.submit(OpenCostIntent(location: location));
// 仅 ShellIntentAccepted 进入目标。
```

fake：返回 accepted/authenticationRequired/staleInput，验证不导航至错误地点且拒绝不显示成 cost unavailable。

### `LOCATION-001` 与 `GEO-001`：地点和行政地理

**唯一公开 import：** `package:locatemy/features/map_location/map_location.dart`；`package:locatemy/modules/geographic_context/geographic_context.dart`

```dart
abstract interface class LocationCoordinator {
  Future<LocationSelectionOutcome> select(LocationSelectionRequest request);
  LocationRoleSnapshot read(LocationRole role);
  Future<LocationSelectionOutcome> swapComparisonLocations();
  Future<SavedLocationOutcome> save(SaveLocationRequest request);
  Future<SavedLocationOutcome> deleteSavedLocation(String savedLocationId);
  Stream<SavedLocationsSnapshot> watchSavedLocations();
  Future<SavedLocationsSnapshot> synchronizeSavedLocations();
}
enum LocationRole { single, locationA, locationB, property }
final class GeographicPoint { final double latitude; final double longitude; }
final class LocationSelectionRequest {
  final LocationRole role; final GeographicPoint point; final String? displayName;
}
final class ValidLocationReference {
  final String locationId; final GeographicPoint point; final String? displayName;
}
sealed class LocationRoleSnapshot {}
final class LocationPresent extends LocationRoleSnapshot {
  final LocationRole role; final ValidLocationReference location;
}
final class LocationAbsent extends LocationRoleSnapshot { final LocationRole role; }
sealed class LocationSelectionOutcome {}
final class LocationSelected extends LocationSelectionOutcome {
  final LocationRole role; final ValidLocationReference location;
}
final class LocationSelectionRejected extends LocationSelectionOutcome {
  final LocationSelectionFailure failure;
}
enum LocationSelectionFailure { invalidCoordinate, outsideMalaysia, sameComparisonPoint, scopeUnavailable }
final class SaveLocationRequest { final ValidLocationReference location; final String name; }
sealed class SavedLocationOutcome {}
final class SavedLocationSaved extends SavedLocationOutcome { final SavedLocation savedLocation; }
final class SavedLocationQueued extends SavedLocationOutcome { final SavedLocation savedLocation; }
final class SavedLocationRejected extends SavedLocationOutcome { final SavedLocationFailure failure; }
final class SavedLocation {
  final String id; final String name; final ValidLocationReference location;
  final DateTime createdAt; final SavedLocationSyncState syncState;
}
enum SavedLocationSyncState { synchronized, queued, retryableFailure }
enum SavedLocationFailure {
  invalidName, invalidLocation, offlineDeleteUnsupported, retryableUnavailable,
  permissionDenied, conflict, scopeUnavailable, notFound,
}
sealed class SavedLocationsSnapshot {}
final class SavedLocationsAvailable extends SavedLocationsSnapshot { final List<SavedLocation> locations; }
final class SavedLocationsUnavailable extends SavedLocationsSnapshot { final SavedLocationFailure failure; }

abstract interface class GeographicContext {
  Future<GeographicContextOutcome> resolve(GeographicContextRequest request);
}
enum GeographicLevel { district, reportingState }
final class GeographicContextRequest {
  final ValidLocationReference location;
  final Set<GeographicLevel> levels;
  const GeographicContextRequest({required this.location, required this.levels});
}
sealed class GeographicContextOutcome { const GeographicContextOutcome(); }
final class GeographicContextAvailable extends GeographicContextOutcome {
  final Map<GeographicLevel, GeographicLevelOutcome> results;
  const GeographicContextAvailable(this.results);
}
final class GeographicContextUnavailable extends GeographicContextOutcome {
  final GeographicContextFailure failure;
  final BoundaryProvenance? provenance;
  const GeographicContextUnavailable(this.failure, {this.provenance});
}
sealed class GeographicLevelOutcome { const GeographicLevelOutcome(); }
final class GeographicLevelResolved extends GeographicLevelOutcome {
  final AdministrativeArea area; final BoundaryProvenance provenance;
  const GeographicLevelResolved(this.area, this.provenance);
}
final class GeographicLevelUnresolved extends GeographicLevelOutcome {
  final GeographicContextFailure failure; final BoundaryProvenance? provenance;
  const GeographicLevelUnresolved(this.failure, {this.provenance});
}
final class GeographicLevelAmbiguous extends GeographicLevelOutcome {
  final List<AdministrativeArea> candidates; final BoundaryProvenance provenance;
  const GeographicLevelAmbiguous(this.candidates, this.provenance);
}
final class AdministrativeArea {
  final GeographicLevel level; final String stableId; final String name;
  final String reportingStateId; final String reportingStateName;
  const AdministrativeArea({required this.level, required this.stableId,
    required this.name, required this.reportingStateId, required this.reportingStateName});
}
final class BoundaryProvenance {
  final String datasetId; final Uri sourceUri; final String sourceVersion;
  final String sourceSha256; final String derivedGeometrySha256; final DateTime importedAt;
  const BoundaryProvenance({required this.datasetId, required this.sourceUri,
    required this.sourceVersion, required this.sourceSha256,
    required this.derivedGeometrySha256, required this.importedAt});
}
enum GeographicContextFailure { noCoverage, sourceUnavailable, versionUnverifiable, scopeUnavailable }
```

以上分别是 [Location](map-and-location.md#location-001合法地点与收藏) 和 [Geo](../modules/geographic-context.md#interface-卡行政统计地理语境geo-001) 的完整 canonical 声明。输入仅 `single` 或不相同 A/B 的 `LocationPresent`；absent、非法、范围外或同点不发 Cost 请求、不写缓存。B 用原引用请求 district 与 reporting state；`GeographicContextAvailable.results` 的键恰为请求层级，B 仅使用其中 `GeographicLevelResolved` 的 district 读成本资料。unresolved/ambiguous 与整次 unavailable 都保留其原因、候选（适用时）和 provenance；行政区不得以附近、州或名称猜测，州 resolved 也不使 district resolved。调用只读、不改变 Map/Geo；地点或边界版本变化后的晚到结果不可发布。

```dart
if (locations.read(LocationRole.single) case LocationPresent(:final location)) {
  final geo = await geographicContext.resolve(GeographicContextRequest(
    location: location, levels: {GeographicLevel.district, GeographicLevel.reportingState},
  ));
}
```

fake：Location 给 absent/single/A-B；Geo 给 resolved、district unresolved+state resolved、ambiguous。验证 absent 无请求，州 CPI 可独立解释但行政区价格/收入不猜测，A/B 角色不变。

### `PRIVACY-001`：账户范围

**唯一公开 import：** `package:locatemy/features/account_privacy/account_privacy.dart`

```dart
abstract interface class AccountPrivacy {
  AccountScopeSnapshot readScope();
  Future<OpenAccountScopeOutcome> open(AuthenticatedAccount account);
  Future<CloseAccountScopeOutcome> close(
    AccountScope scope, AccountScopeCloseReason reason,
  );
}
final class AccountScope { final String accountId; const AccountScope(this.accountId); }
sealed class AccountScopeSnapshot { const AccountScopeSnapshot(); }
final class AccountScopeOpened extends AccountScopeSnapshot { final AccountScope scope; const AccountScopeOpened(this.scope); }
final class AccountScopeClosing extends AccountScopeSnapshot { final AccountScope scope; const AccountScopeClosing(this.scope); }
final class AccountScopeClosed extends AccountScopeSnapshot { final AccountScope scope; const AccountScopeClosed(this.scope); }
final class AccountScopeUnavailable extends AccountScopeSnapshot { final AccountScopeFailure failure; const AccountScopeUnavailable(this.failure); }
enum AccountScopeFailure { identityMismatch, scopeNotOpen, scopeClosing, retryableUnavailable }
enum AccountScopeCloseReason { signOut, sessionInvalidated, accountSwitch }
sealed class OpenAccountScopeOutcome { const OpenAccountScopeOutcome(); }
final class AccountScopeOpenedForAccount extends OpenAccountScopeOutcome { final AccountScope scope; const AccountScopeOpenedForAccount(this.scope); }
final class AccountScopeOpenRejected extends OpenAccountScopeOutcome { final AccountScopeFailure failure; const AccountScopeOpenRejected(this.failure); }
sealed class CloseAccountScopeOutcome { const CloseAccountScopeOutcome(); }
final class AccountScopeClosedForAccount extends CloseAccountScopeOutcome { final AccountScope scope; const AccountScopeClosedForAccount(this.scope); }
final class AccountScopeCloseIncomplete extends CloseAccountScopeOutcome { final AccountScope scope; final List<PrivateStateClearIncomplete> incomplete; const AccountScopeCloseIncomplete(this.scope, this.incomplete); }
final class AccountScopeCloseRejected extends CloseAccountScopeOutcome { final AccountScope scope; final AccountScopeFailure failure; const AccountScopeCloseRejected(this.scope, this.failure); }

abstract interface class AccountPrivacyParticipant {
  AccountPrivacyParticipantId get participantId;
  Future<PrivateStateClearOutcome> clearPrivateState(AccountScope scope);
}
enum AccountPrivacyParticipantId { authenticationSession, applicationShell, mapLocation, costLivingBudget, infrastructureCoverage, hazardReporting, propertyInspection, accountCenter }
sealed class PrivateStateClearOutcome { const PrivateStateClearOutcome(); }
final class PrivateStateCleared extends PrivateStateClearOutcome { final AccountPrivacyParticipantId participantId; final AccountScope scope; const PrivateStateCleared(this.participantId, this.scope); }
final class PrivateStateClearIncomplete extends PrivateStateClearOutcome { final AccountPrivacyParticipantId participantId; final AccountScope scope; final PrivateStateClearFailure failure; const PrivateStateClearIncomplete(this.participantId, this.scope, this.failure); }
enum PrivateStateClearFailure { localStoreUnavailable, fileCleanupIncomplete, queuedWorkCleanupIncomplete, scopeUnavailable, retryableUnavailable }
```

以上为 [Account Privacy](../modules/account-privacy.md#privacy-001--账户范围与关闭参与者) 的完整 canonical 声明。Shell 是 lifecycle 唯一发起者。B 只在当前同账户 `AccountScopeOpened` 读写预案；closing 开始即清除 current 内存选择/私有副本并拒绝旧读写和晚到响应。B 以 `AccountPrivacyParticipantId.costLivingBudget` 对固定旧 scope 提供 close 证明；不删远端预案、公共缓存或语言。`identityMismatch`、`scopeNotOpen`、`scopeClosing`、`retryableUnavailable` 是 typed failure，绝不以空预案冒充。

```dart
if (privacy.readScope() case AccountScopeOpened(:final scope)) {
  // 仅操作 scope.accountId 的预算预案。
}
```

fake：A opened→closing/closed→B opened，验证 A 的 current/压力不进入 B，公共成本缓存仍可保留。

### `read_cost_inputs`：稳定公共读取对象（仅 B）

**精确对象：** Schema Catalog 的 security-invoker View/RPC `read_cost_inputs`（`proposed`）。Flutter 不直读 PriceCatcher、lookup、CPI 或收入镜像。

```dart
abstract interface class CostInputsReader { Future<CostInputsOutcome> read(CostInputsRequest request); }
final class CostInputsRequest {
  final ValidLocationReference location;
  final AdministrativeArea district;
  final AdministrativeArea reportingState;
  final BoundaryProvenance districtProvenance;
  final BoundaryProvenance reportingStateProvenance;
  final String basketVersion; final CostRefreshPolicy refreshPolicy;
}
enum CostRefreshPolicy { cacheAllowed, refresh }
sealed class CostInputsOutcome {}
final class CostInputsAvailable extends CostInputsOutcome { final CostInputs inputs; }
final class CostInputsPartial extends CostInputsOutcome { final CostInputs inputs; final List<CostInputGap> gaps; }
final class CostInputsUnavailable extends CostInputsOutcome { final CostInputFailure failure; }
enum CostInputFailure { invalidGeographicContext, sourceUnavailable, permissionDenied, retryableUnavailable, incompatibleVersion }
```

输入是本次 Geo 已 resolved 的地点、district/state 和各自可验证 provenance，篮子固定 `cost-basket-v1`，刷新只为 cacheAllowed/显式 refresh；任一层级非 `GeographicLevelResolved` 时不得构造此读取请求。available/partial 均回带 item 单位/观测、资料日期、全国基准、行政区收入、州/全国同口径 Headline/Overall CPI 与导入完整性；partial 不是零或完整。只读且仅 opened 路径可用；permission/retry/version failure 不伪装为空。`cost_public_cache` 仅 location/admin key、模型版、来源日期、fetched-at、3-day expiry/完整性。

```dart
final inputs = await costInputsReader.read(CostInputsRequest(
  location: location, district: districtArea, reportingState: reportingStateArea,
  districtProvenance: districtProvenance, reportingStateProvenance: reportingStateProvenance,
  basketVersion: 'cost-basket-v1', refreshPolicy: CostRefreshPolicy.cacheAllowed,
));
```

fake：完整 12 月、5 月、低覆盖、CPI 无共同月、retryable；验证只有事实源门槛满足时发布指数/压力，缓存无私有字段。

## 3. B 提供的 Interface

### `COST-001`：地点成本、个人压力、临时换算

**提供者：** B；**消费者：** Application Shell、Personalized Location Suitability
**唯一公开 import：** `package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart`

消费者只能 import 该入口，不能 import `src/`。下列是声明，不是实现、SQL、SDK 调用或公式正文。

```dart
abstract interface class CostOfLivingBudget {
  Future<CostAnalysisOutcome> analyse(CostAnalysisRequest request);
  Future<CostComparisonOutcome> compare(CostComparisonRequest request);
  Future<CpiEquivalentOutcome> calculateCpiEquivalent(CpiEquivalentRequest request);
  void clearTemporaryCpiInput();
}
final class CostAnalysisRequest { final ValidLocationReference location; final CostRefreshPolicy refreshPolicy; }
final class CostComparisonRequest { final ValidLocationReference locationA; final ValidLocationReference locationB; final CostRefreshPolicy refreshPolicy; }
final class CpiEquivalentRequest { final ValidLocationReference location; final double inputMonthlySpendRm; final CostRefreshPolicy refreshPolicy; }
sealed class CostAnalysisOutcome {}
final class CostAnalysisAvailable extends CostAnalysisOutcome { final CostAnalysis analysis; }
final class CostAnalysisPartial extends CostAnalysisOutcome { final CostAnalysis analysis; final List<CostAvailabilityGap> gaps; }
final class CostAnalysisUnavailable extends CostAnalysisOutcome { final CostAnalysisFailure failure; }
sealed class CostComparisonOutcome {}
final class CostComparisonAvailable extends CostComparisonOutcome { final CostComparison comparison; }
final class CostComparisonPartial extends CostComparisonOutcome { final CostComparison comparison; final List<CostAvailabilityGap> gaps; }
final class CostComparisonUnavailable extends CostComparisonOutcome { final CostAnalysisFailure failure; }
sealed class CpiEquivalentOutcome {}
final class CpiEquivalentAvailable extends CpiEquivalentOutcome { final CpiEquivalentReading reading; }
final class CpiEquivalentUnavailable extends CpiEquivalentOutcome { final CpiEquivalentFailure failure; }
enum CostAnalysisFailure { invalidLocation, sameComparisonPoint, geographicContextUnavailable, sourceUnavailable, permissionDenied, retryableUnavailable, scopeUnavailable, incompatibleMetadata }
enum CpiEquivalentFailure { invalidInput, geographicContextUnavailable, cpiUnavailable, noCommonMonth, retryableUnavailable, scopeUnavailable }
```

| 调用 | 输入约束 | 输出 | typed failure / 调用方处理 |
| --- | --- | --- | --- |
| `analyse` | 合法 immutable single；refresh 二选一 | 地点、行政区/州口径、篮子/模型版、来源、资料日期、单位、覆盖率和 fresh/cached/stale/partial/unavailable；可含价格、Observed、指数、Scenario、压力 | 各 failure 分类呈现；不把 0/空/缓存称完整 fresh |
| `compare` | 合法且不同 A/B；Map 原顺序 | 各端原值/元数据；仅兼容读数有差异 | samePoint 或不可用时不判赢家；partial 保留值和不可比原因 |
| `calculateCpiEquivalent` | 有限非负的全国基准 RM/月；仅 `STATE-COST-TEMP` | 最新共同月份州/全国 Headline/Overall CPI、日期、口径、等效 RM | invalid/CPI 缺失/无共同月/网络/scope 分开；不跨月 |
| `clearTemporaryCpiInput` | 无 | 离页后临时输入不存在 | 无远端写入；不改预案/压力/Suitability |

**状态、权限、副作用、次序。** 按[模型](../../knowledge_base/locatemy_product/features/cost_of_living.md#已确认的单点生活成本模型)应用逐商户中位数、逐月平均、删项、12 月窗口、至少 6 月/平均覆盖率 80% 门槛。`CostIndex` 仅同版 `ObservedSpend12`/`BaseSpend12`，不含住房/交通/额外生活开销，不是官方 CPI/评级。只有完整核心市场、住房/交通已填或明确 RM 0、已保存 current 的月净收入才发布 `ScenarioSpend12`/个人压力；家庭月度总收入不可替月净收入。临时输入不访问预案，离页清除。每次先绑定 location、Geo/资料/篮子/current 版本，任何版本或 scope 变化均使旧响应无效。

```dart
final result = await costOfLivingBudget.analyse(
  CostAnalysisRequest(location: location, refreshPolicy: CostRefreshPolicy.cacheAllowed),
);
// Suitability 仅消费明确可用且同账户同 current 版本的个人压力。
```

fake：Shell 验证完整/Geo unresolved/partial/stale 的来源日期原因保留；Suitability 验证合格压力、无 current、缺住房、仅家庭收入，只有合格压力进入成本维度；临时 reading 永不进入。

### `COST-002`：预算预案与 current 变化

**提供者：** B；**消费者：** Account Center、Socio-economic、Suitability、Shell
**唯一公开 import：** `package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart`

```dart
abstract interface class BudgetScenarioStore {
  Future<BudgetScenariosOutcome> read(); Stream<BudgetScenariosOutcome> watch();
  Future<BudgetScenarioMutationOutcome> create(BudgetScenarioDraft draft);
  Future<BudgetScenarioMutationOutcome> update(BudgetScenarioUpdate update);
  Future<BudgetScenarioMutationOutcome> selectCurrent(String scenarioId);
  Future<BudgetScenarioMutationOutcome> delete(String scenarioId);
}
final class BudgetScenarioDraft {
  final String name; final double? additionalLivingExpenseRm; final double? housingExpenseRm;
  final double? transportExpenseRm; final double? monthlyNetIncomeRm; final double? householdMonthlyIncomeRm;
}
final class BudgetScenarioUpdate { final String scenarioId; final BudgetScenarioDraft values; }
sealed class BudgetScenariosOutcome {}
final class BudgetScenariosAvailable extends BudgetScenariosOutcome { final List<BudgetScenario> scenarios; final CurrentBudgetScenarioSnapshot current; }
final class BudgetScenariosUnavailable extends BudgetScenariosOutcome { final BudgetScenarioFailure failure; }
sealed class CurrentBudgetScenarioSnapshot {}
final class CurrentBudgetScenarioAvailable extends CurrentBudgetScenarioSnapshot { final BudgetScenario scenario; final int version; }
final class NoCurrentBudgetScenario extends CurrentBudgetScenarioSnapshot { final int version; }
sealed class BudgetScenarioMutationOutcome {}
final class BudgetScenarioMutationSaved extends BudgetScenarioMutationOutcome { final BudgetScenario scenario; final CurrentBudgetScenarioSnapshot current; }
final class BudgetScenarioMutationDeleted extends BudgetScenarioMutationOutcome { final String scenarioId; final CurrentBudgetScenarioSnapshot current; }
final class BudgetScenarioMutationRejected extends BudgetScenarioMutationOutcome { final BudgetScenarioFailure failure; }
enum BudgetScenarioFailure { invalidName, invalidAmount, notFound, conflict, permissionDenied, retryableUnavailable, scopeUnavailable }
```

| 调用 | 输入约束 | 输出 | typed failure / 调用方处理 |
| --- | --- | --- | --- |
| `read` / `watch` | 当前同账户 opened | 全部该账户预案与 current/no-current、保存版本 | permission/retry/scope 不得伪装为空列表/no-current |
| `create` / `update` | name trim 后 1–120；所有已填金额有限且非负；空额外生活开销即无额外开销 | 仅远端成功后 Saved、新 current/version | invalid 不写；conflict/permission/retry 保留最后已保存事实 |
| `selectCurrent` | 当前账户已存在 id | Saved 及版本 | 不存在/跨账户/冲突不提升 current |
| `delete` | 当前账户已存在 id；最后一份允许 | Deleted；删 current 返回 NoCurrent | 不自动选择；不离线排队 |

`BudgetScenario` 是只读保存快照，含 id/name、五个金额及其缺失状态、isCurrent、时间和版本。Account 固定显示名称、额外生活开销、住房、交通、月净收入、家庭月度总收入及缺失状态；Socio 只读 current 家庭月度总收入；Suitability 只读同账户同版本 current。B 是 `user_budget_scenarios` 唯一读写 Owner；每次远端保存成功才发布 version，消费者可去重并使依赖读数失效/重算。

```dart
final outcome = await budgetScenarioStore.selectCurrent(scenarioId);
// Saved 才用 current.version 更新摘要；Rejected 保留最后已保存摘要并显示恢复路径。
```

fake：Account 验证 no-current、invalidName、conflict、retry；Socio 以仅月净收入/仅家庭收入验证只读家庭收入；Suitability 用 A/B 与 version 变化验证不跨账户、不用过期结果。

## 4. 协作交付顺序

1. **B 先合入公开 seam：** 唯一入口、两 Interface 声明和最小 fake；消费者不得依赖 B 私有文件。
2. **B 完成输入边界：** 接入 Location/Geo/Privacy、`read_cost_inputs` 和 `user_budget_scenarios`；验证 item/单位/资料日期、CPI 共同月份、完整/部分/空导入。
3. **消费者并行 fake：** Shell 只导航/呈现；Account 只摘要/意图；Socio 只家庭月收入；Suitability 只合格同版本压力/current。
4. **共同联调：** 按 FLOW-02/03/07 接生产 seam；迁移、RLS、导入、缓存与关闭的运行时证据留实现/集成验收。

## 5. 联合验收

| 场景 | Owner | 可观察结果 | 追踪 |
| --- | --- | --- | --- |
| 单点完整/缺失 | B、Map、Geo、Shell | 完整时价格/Observed/覆盖率/指数/压力；<6 月、低覆盖、Geo unresolved/ambiguous 时保留读数和精确原因 | `COST-01`；`AT-ANALYSIS-01` |
| A/B 可比/不可比 | B、Map、Geo、Shell | 原 A/B 与元数据保留；仅兼容有差异；无赢家/自动推荐 | `COST-01`；`AT-COMPARE-01/03` |
| 预案与两收入 | B、Account、Socio、Suitability | 月净收入仅压力，家庭收入仅 Socio；空与 RM 0 区分；切换即按 version 重算 | `COST-01/03`、`ACCOUNT-09`；`AT-SUIT-02/04` |
| 删除/保存失败 | B、Account、Shell | 删除 current/最后一份为 no-current；validation/conflict/permission/network 保留最后保存事实且不排队 | `COST-03`；`AT-SUIT-02/04` |
| 临时 CPI | B、Geo、Shell | 仅同月等效/来源；缺失/异月不跨月；离页清除且不影响预案/压力/适配度 | `COST-02`；`AT-ANALYSIS-01` |
| 退出换号 | B、Privacy、Shell、Suitability | A current/副本不可读，B 不继承，公共无身份缓存可留；失败为无私有内容恢复态 | `COST-03`；`AT-SUIT-06` |

## 6. 实现自由、Gate 与检查

B 可决定内部文件、Widget、状态机、SDK/SQLite、缓存、取消、重试、冲突、公式代码和测试组织。以下变更须暂停协商：唯一公开 import、公共声明/result variant、输入约束、版本语义、权限/副作用/顺序、`read_cost_inputs`/`user_budget_scenarios` Schema/RLS，或事实源锁定的篮子/门槛/两种收入边界。

实现 Gate：`read_cost_inputs` 与 `user_budget_scenarios` 仍 proposed；实现前必须验证官方 schema/键/单位、导入完整性和最大日期、CPI 最新共同月、完整/部分/空导入、可空非负字段和旧预案缺失保留。不得用 fixture 宣称完成；此 Gate 不改变本 Feature 的 Ready 设计状态。

- [x] 四项 Readiness 均可核查。
- [x] `COST-001`/`002` 均有唯一入口、声明、输入、typed outputs/failures、状态/权限/副作用/顺序、示例和 fake。
- [x] Shell/Location/Geo/Privacy 与精确 View/RPC 都有唯一入口/对象、声明级协作形状、约束和 fake。
- [x] 无函数体、SDK、SQL、migration、测试实现或 Widget 结构。
- [x] 联验覆盖单点、A/B、current、临时换算、两收入、失败与 A→B 隔离。

公共 Interface 变更由提供方说明原因与消费者，所有受影响消费者确认；同一 PR 更新公开声明、本契约、同名 HTML 与受影响 fake/Adapter 测试。Git/PR 保存历史；不使用 PDF、文档版本、checksum、Manifest、Locked Source Set、Generation Gate、Development Release 或 Invalidated 状态机。

## Change Log

| 日期 | 状态 | 变更原因 | 受影响对象 | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Ready for Development` | 固定 Cost 范围、产品口径、数据边界与联验 | `COST-01`–`03`、`ACCOUNT-09` | 项目负责人 |
| 2026-09-15 | `Ready for Development` | Issue #23 返工为单一 Development Contract：首屏完成定义、HTML 等价导出、完整引用冻结的 `SHELL-001`、`LOCATION-001`、`GEO-001` 与 `PRIVACY-001`；移除 PDF/ADR 0014/handoff 发布治理 | `COST-001`、`COST-002`、Cost 的四个上游 seam、Shell、Map、Geo、Privacy、Account、Socio、Suitability | 设计 AI〔项目负责人授权〕，ADR 0013 |
