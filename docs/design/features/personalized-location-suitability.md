# Personalized Location Suitability 开发协作契约

> 状态：`Ready for Development`（2026-09-15；设计 AI〔项目负责人授权〕，ADR 0013）
> Owner：`B`；系统基线：`Baselined — 5d11769`；依赖波次：Wave 7
> 唯一公开入口：`package:locatemy/features/personalized_location_suitability/personalized_location_suitability.dart`

本文件是 Personalized Location Suitability 唯一的跨 Owner 开发协作契约，也是同名人类 PDF 的 Markdown 源。它固定五维输入、资格门控、转换、重归一化、解释和 A/B 并列语义；`lib/features/personalized_location_suitability/` 内 Widget、状态管理、并发/取消、缓存、计算组织与测试组织由 B 决定。公式正文只在产品知识库；数据库字段、RLS 和 migration 只在 Schema Catalog。

## 0. 固定阅读顺序与四项 Readiness

实施和审查必须按下面顺序读取；后项只能补充已经冻结的事实：

1. [领域词汇](../../../CONTEXT.md#评估偏好)、[个人化地点适配度](../../knowledge_base/locatemy_product/domain_objects.md#personalized-location-suitability-个人化地点适配度)、[地图 MAP-07 规则](../../knowledge_base/locatemy_product/features/map_location.md#个人化地点适配度map-07)、[成本预算压力](../../knowledge_base/locatemy_product/features/cost_of_living.md)；
2. [Feature map（Suitability）](../system/feature-map.md)、[Interface 注册表](../system/interfaces.md)、[FLOW-02](../system/flows.md#flow-02单点选址地点摘要与六类分析)、[FLOW-03](../system/flows.md#flow-03地点-ab-比较)、[FLOW-07](../system/flows.md#flow-07个人化地点适配度)；
3. [Capability Traceability](../system/capability-traceability.md)、[数据所有权](../system/data-ownership.md)、[Schema Catalog](../data/schema-catalog.md#身份与账户业务对象)、[风险登记](../system/risks-and-decisions.md#风险与关闭条件)；
4. 本契约；生成或使用人类 PDF 时最后读 [ADR 0014](../../adr/0014-version-locked-pdf-development-documentation-packages.md) 与 [handoff](../handoff/README.md)。

| Readiness | 可核查证据 | 结论 |
| --- | --- | --- |
| 责任与范围 | `MAP-07` 唯一归 Suitability；原始安全/成本/设施/交通/ICI、偏好和预案持久化、选点和推荐均归其他 Owner | 已就绪 |
| 契约与消费者 | 第 2 节逐卡冻结 `SHELL-001`、`LOCATION-001`、`ACCOUNT-001`、五个 canonical 输入；第 3 节给出唯一 `SUITABILITY-001` 与 fake | 已就绪 |
| 数据与安全 | 只消费公开 Interface，不直读 `user_assessment_preferences`、`user_budget_scenarios`、政府镜像或上游 cache；总分只存在同账户页面内存 | 已就绪 |
| 验收与风险 | 第 5 节覆盖 `AT-SUIT-01`–`06`、`AT-RACE-01`、`AT-SWITCH-01`；`RISK-PREF-01` 的 null/default 边界已冻结，运行证据留实现/集成 | 已就绪 |

## 1. 成果、责任与冻结边界

- 已 opened 账户可以对一个合法地点看到可解释的 `0–100` 个人化读数，或精确知道是偏好、current 预案还是哪一维资料阻止结果。它不是客观宜居评分、官方评级、赢家或推荐。
- 五维固定顺序为：安全、成本、日常便利、公共交通可达性、基础设施。主读数固定为安全指数、个人预算压力转换分、2 km 五类确认设施覆盖转换分、交通连通性分和 **neutral `5/5/5` ICI**。
- A/B 先各自计算，再只在共同语境相容时并列显示原始读数；绝不产生数值差、排序、赢家或自动搬迁建议。

| Owner / 受控边界 | 负责 | 不负责 | 协作 |
| --- | --- | --- | --- |
| `lib/features/personalized_location_suitability/`（B） | `SUITABILITY-001`、五维资格、转换/加权、低优先级缺失重归一化、解释、A/B 可比性 | 原始分析、偏好/预案/ICI 权重写入、地图、导航、推荐 | 消费 Shell、Location、Account、Cost、Safety、Facility、Transit、Infrastructure；提供 Shell |
| Application Shell | opened 门控、地点详情/A-B 槽位、设置导航、按 `FLOW-07` 使旧请求失效 | 计算或补齐任一维、改写原因、决定可比性 | 消费 `SUITABILITY-001` |
| 各上游 Owner | 产生并解释自己的 canonical 结果与资料状态 | Suitability 转换、偏好加权、总分 | 只经各自公开入口交付快照 |

## 2. B 需要调用的 Interface 卡

消费者只能 import 卡中唯一入口，不能 import 对方 `src/`、Adapter、SDK、表或 cache。以下声明是协作形状，不含实现体。

### Interface 卡：`SHELL-001` — 详情/A-B 槽位、设置导航与结果发布

**提供者：** Application Shell；**唯一公开 import：** `package:locatemy/app/application_shell.dart`。

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
final class ShellIntentRejected extends ShellIntentOutcome { final ShellRejectionReason reason; const ShellIntentRejected(this.reason); }
sealed class ShellContributionOutcome { const ShellContributionOutcome(); }
final class ShellContributionAccepted extends ShellContributionOutcome { const ShellContributionAccepted(); }
final class ShellContributionAuthenticationRequired extends ShellContributionOutcome { const ShellContributionAuthenticationRequired(); }
final class ShellContributionRejected extends ShellContributionOutcome { final ShellRejectionReason reason; const ShellContributionRejected(this.reason); }
enum ShellRejectionReason { missingInput, staleInput, inapplicableDestination, scopeUnavailable }
```

B 从自己的公开入口导出 `OpenAssessmentPreferencesIntent`、`OpenCurrentBudgetScenarioIntent`（均带 `SuitabilityReturnContext`）及 `SuitabilityContribution implements ShellContribution`。贡献只含 `SuitabilitySingleOutcome` 或 `SuitabilityComparisonOutcome`、不可变地点、账户/输入版本和原始 warnings；不得携带账户草稿、收入、预案字段或上游内部对象。

```dart
final class SuitabilityReturnContext { final String source; const SuitabilityReturnContext(this.source); }
final class OpenAssessmentPreferencesIntent implements ShellIntent { final SuitabilityReturnContext returnContext; const OpenAssessmentPreferencesIntent(this.returnContext); }
final class OpenCurrentBudgetScenarioIntent implements ShellIntent { final SuitabilityReturnContext returnContext; const OpenCurrentBudgetScenarioIntent(this.returnContext); }
final class SuitabilityContribution implements ShellContribution { final Object outcome; const SuitabilityContribution(this.outcome); }
```

| 输入约束 | 输出 / typed failures | 状态与副作用 | 顺序、权限与 fake |
| --- | --- | --- | --- |
| 只向 opened 同账户 Shell submit/publish；贡献的 location、accountId、input versions 必须仍等于当前请求语境。 | `accepted` 才导航/进入槽位；`authenticationRequired`、`rejected(reason)` 是 Shell 结果，不能改写为资料失败。 | Shell 只导航/组合；Suitability 不改地图、上游、偏好、预案或 ICI 权重。 | `await shell.publish(contribution);` 仅 accepted 发布。fake 依次回 accepted/authenticationRequired/staleInput，断言拒绝保留 Suitability 结果与原因且不泄露私有输入。 |

### Interface 卡：`LOCATION-001` — 不可变合法地点

**提供者：** Map / Location；**唯一公开 import：** `package:locatemy/features/map_location/map_location.dart`。

```dart
abstract interface class LocationCoordinator { LocationRoleSnapshot read(LocationRole role); }
enum LocationRole { single, locationA, locationB, property }
sealed class LocationRoleSnapshot { const LocationRoleSnapshot(); }
final class LocationPresent extends LocationRoleSnapshot { final LocationRole role; final ValidLocationReference location; const LocationPresent(this.role, this.location); }
final class LocationAbsent extends LocationRoleSnapshot { final LocationRole role; const LocationAbsent(this.role); }
final class ValidLocationReference { final String locationId; final GeographicPoint point; final String? displayName; const ValidLocationReference(this.locationId, this.point, this.displayName); }
```

| 输入约束 | 输出 / typed failures | 状态与副作用 | 顺序、权限与 fake |
| --- | --- | --- | --- |
| 只接收 Map 已成功产生的 immutable single/A/B reference；不得造坐标、读可变地图状态、用默认城市或收藏名代替坐标。 | `LocationAbsent`、非法/范围外/same point（由 Map 拒绝）使计算为 `SuitabilityPrerequisiteMissing(location)`，不调上游。 | 读取无副作用；地点 id 改变时旧结果不可发布。 | Shell 先按 FLOW-02/03 取角色引用，再传 B。fake 给 single、A/B、absent、换点；断言 absent 不请求上游、A/B 不混端。 |

### Interface 卡：`ACCOUNT-001` — complete 评估偏好快照

**提供者：** Account Center；**唯一公开 import：** `package:locatemy/features/account_center/account_center.dart`。

```dart
abstract interface class AccountCenter { Future<AssessmentPreferencesOutcome> readAssessmentPreferences(); Stream<AssessmentPreferencesOutcome> watchAssessmentPreferences(); }
sealed class AssessmentPreferencesOutcome { const AssessmentPreferencesOutcome(); }
final class AssessmentPreferencesComplete extends AssessmentPreferencesOutcome { final CompleteAssessmentPreferencesSnapshot snapshot; const AssessmentPreferencesComplete(this.snapshot); }
final class AssessmentPreferencesPrerequisiteMissing extends AssessmentPreferencesOutcome { const AssessmentPreferencesPrerequisiteMissing(); }
final class AssessmentPreferencesUnavailable extends AssessmentPreferencesOutcome { final AssessmentPreferencesFailure failure; const AssessmentPreferencesUnavailable(this.failure); }
final class CompleteAssessmentPreferencesSnapshot { final String accountId; final AssessmentPreferenceValues values; final int version; final DateTime configuredAt; const CompleteAssessmentPreferencesSnapshot(this.accountId, this.values, this.version, this.configuredAt); }
final class AssessmentPreferenceValues { final int safety, cost, dailyConvenience, transitAccessibility, infrastructure; const AssessmentPreferenceValues(this.safety, this.cost, this.dailyConvenience, this.transitAccessibility, this.infrastructure); }
enum AssessmentPreferencesFailure { invalidInput, permissionDenied, conflict, retryableUnavailable, scopeUnavailable }
```

| 输入约束 | 输出 / typed failures | 状态与副作用 | 顺序、权限与 fake |
| --- | --- | --- | --- |
| 必须同账户，五项均为 `1–10`，`configuredAt` 非 null 的完整 immutable snapshot。 | `PrerequisiteMissing`（无行/`configured_at` null）与 `Unavailable(failure)` 分开；页面预填 5、草稿、部分保存均不是输入。 | 只读；账户或 snapshot version 改变使旧适配度失效。 | 先取得/监听 complete，再取五维。fake：missing、A/v4、save conflict、A→B、A/v5；仅同账户 complete 进入计算。 |

### Interface 卡：`COST-001` 与 `COST-002` — 个人预算压力和 current 预案

**提供者：** Cost of Living & Budget；**唯一公开 import：** `package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart`。

```dart
abstract interface class CostOfLivingBudget { Future<CostAnalysisOutcome> analyse(CostAnalysisRequest request); }
abstract interface class BudgetScenarioStore { Future<BudgetScenariosOutcome> read(); Stream<BudgetScenariosOutcome> watch(); }
sealed class CostAnalysisOutcome { const CostAnalysisOutcome(); }
final class CostAnalysisAvailable extends CostAnalysisOutcome { final CostAnalysis analysis; const CostAnalysisAvailable(this.analysis); }
final class CostAnalysisPartial extends CostAnalysisOutcome { final CostAnalysis analysis; final List<CostAvailabilityGap> gaps; const CostAnalysisPartial(this.analysis, this.gaps); }
final class CostAnalysisUnavailable extends CostAnalysisOutcome { final CostAnalysisFailure failure; const CostAnalysisUnavailable(this.failure); }
sealed class BudgetScenariosOutcome { const BudgetScenariosOutcome(); }
final class BudgetScenariosAvailable extends BudgetScenariosOutcome { final CurrentBudgetScenarioSnapshot current; const BudgetScenariosAvailable(this.current); }
final class BudgetScenariosUnavailable extends BudgetScenariosOutcome { final BudgetScenarioFailure failure; const BudgetScenariosUnavailable(this.failure); }
sealed class CurrentBudgetScenarioSnapshot { const CurrentBudgetScenarioSnapshot(); }
final class CurrentBudgetScenarioAvailable extends CurrentBudgetScenarioSnapshot { final BudgetScenario scenario; final int version; const CurrentBudgetScenarioAvailable(this.scenario, this.version); }
final class NoCurrentBudgetScenario extends CurrentBudgetScenarioSnapshot { final int version; const NoCurrentBudgetScenario(this.version); }
```

| 输入约束 | 输出 / typed failures | 状态与副作用 | 顺序、权限与 fake |
| --- | --- | --- | --- |
| `analyse` 用同一 immutable location 和 `CurrentBudgetScenarioAvailable`；仅 Cost 已发布的完整 `PersonalBudgetBurden(%)` 可转分。住房/交通 RM 0 有效；缺住房、交通、月净收入、少于 6 个月或平均覆盖低于 80% 不合格。 | no-current 为 prerequisite missing；partial/unavailable、预案读取 failure 均为成本维度 unavailable，不可用临时 CPI、地点成本指数、家庭月度总收入或其他预案替换。 | Suitability 只读，绝不读表或写 current；current version/地点/成本版本变更使旧分失效。 | 先 `COST-002` current，再 `COST-001`。fake：no-current、完整 burden 42、partial basket、住房 RM0、缺 monthly net income、CPI temporary；只有完整 42 转换。 |

### Interface 卡：`SAFETY-001` — 州级安全指数

**提供者：** Crime & Security；**唯一公开 import：** `package:locatemy/features/crime_and_security/crime_and_security.dart`。

```dart
abstract interface class CrimeAndSecurity { Future<SafetyLoadOutcome> load(SafetyRequest request); }
sealed class SafetyLoadOutcome { const SafetyLoadOutcome(); }
final class SafetyAvailable extends SafetyLoadOutcome { final SafetySnapshot snapshot; const SafetyAvailable(this.snapshot); }
final class SafetyPartiallyAvailable extends SafetyLoadOutcome { final SafetySnapshot snapshot; const SafetyPartiallyAvailable(this.snapshot); }
final class SafetyUnavailable extends SafetyLoadOutcome { final SafetyUnavailableReason reason; const SafetyUnavailable(this.reason); }
final class SafetySnapshot { final ValidLocationReference location; final SafetyScore score; final SafetyFreshness freshness; final SafetyCompleteness completeness; final SafetyProvenance provenance; const SafetySnapshot(this.location, this.score, this.freshness, this.completeness, this.provenance); }
final class SafetyScore { final int value; const SafetyScore(this.value); }
enum SafetyFreshness { fresh, cached, stale }
enum SafetyCompleteness { complete, partial }
```

| 输入约束 | 输出 / typed failures | 状态与副作用 | 顺序、权限与 fake |
| --- | --- | --- | --- |
| 同地点请求；仅 `SafetyAvailable` 且 complete score 纳入。 | unresolved/ambiguous、partial、unavailable 保持安全维度原因；不得用犯罪原始数、Hazard 或 0 替代。 | 只读上游；stale 但 available 可纳入且 warning 原样保留。 | Map 后请求 Safety。fake：complete 0/stale、partial、unresolved、ambiguous；明确 0 有效，其他均缺失。 |

### Interface 卡：`FACILITY-001` — 2 km 五类确认覆盖

**提供者：** Nearby Facilities；**唯一公开 import：** `package:locatemy/features/nearby_facilities/nearby_facilities.dart`。

```dart
abstract interface class NearbyFacilities { Future<FacilityAnalysisOutcome> analyse(FacilityAnalysisRequest request); }
sealed class FacilityAnalysisOutcome { const FacilityAnalysisOutcome(); }
final class FacilityAnalysisAvailable extends FacilityAnalysisOutcome { final FacilityAnalysis analysis; const FacilityAnalysisAvailable(this.analysis); }
final class FacilityAnalysisUnavailable extends FacilityAnalysisOutcome { final FacilityFailure failure; const FacilityAnalysisUnavailable(this.failure); }
```

| 输入约束 | 输出 / typed failures | 状态与副作用 | 顺序、权限与 fake |
| --- | --- | --- | --- |
| 只消费同地点、半径 `2,000m`、五类完整的 canonical result。 | 任一类别 unknown/unavailable 或整体 failure 即日常便利 unavailable；complete-empty 的确认类别数为 0 有效。 | 只读；保留 OSM 来源、查询/缓存时间、mapping version 与 warning。 | 先地点后 Facilities。fake：5/5、0/5 complete、1 类 unknown、refresh failure；仅两个 complete 结果可转 `100 × count / 5`。 |

### Interface 卡：`TRANSIT-001` — canonical connectivity score

**提供者：** Public Transportation；**唯一公开 import：** `package:locatemy/features/public_transportation/public_transportation.dart`。

```dart
abstract interface class PublicTransportation { Future<TransitLoadOutcome> load(TransitRequest request); }
sealed class TransitLoadOutcome { const TransitLoadOutcome(); }
final class TransitAvailable extends TransitLoadOutcome { final TransitSnapshot snapshot; const TransitAvailable(this.snapshot); }
final class TransitIncomplete extends TransitLoadOutcome { final TransitPartialSnapshot snapshot; const TransitIncomplete(this.snapshot); }
final class TransitUnavailable extends TransitLoadOutcome { final TransitUnavailableReason reason; const TransitUnavailable(this.reason); }
final class TransitSnapshot { final ValidLocationReference location; final int radiusMeters; final TransitServiceOutcome serviceOutcome; final TransitScore? score; final TransitProvenance provenance; const TransitSnapshot(this.location, this.radiusMeters, this.serviceOutcome, this.score, this.provenance); }
enum TransitServiceOutcome { served, noStops, noActiveRoutes }
```

| 输入约束 | 输出 / typed failures | 状态与副作用 | 顺序、权限与 fake |
| --- | --- | --- | --- |
| 必须为同地点 `1,500m`、`TransitAvailable`、`served` 且非空 score。 | incomplete/unavailable/noStops/noActiveRoutes 都是交通维度 unavailable；不能把无服务或 partial 显示为零分。 | 只读；可用 stale feed 的 warning、feed snapshot/reference-grid/model 随结果保留。 | fake：served 73 stale、served 0、noStops、noActiveRoutes、incomplete；前两者纳入，其余缺失。 |

### Interface 卡：`INFRA-001` — neutral ICI

**提供者：** Infrastructure Coverage；**唯一公开 import：** `package:locatemy/features/infrastructure_coverage/infrastructure_coverage.dart`。

```dart
abstract interface class InfrastructureCoverage { Future<InfrastructureNeutralOutcome> neutralForSuitability(InfrastructureNeutralRequest request); }
sealed class InfrastructureNeutralOutcome { const InfrastructureNeutralOutcome(); }
final class InfrastructureNeutralAvailable extends InfrastructureNeutralOutcome { final InfrastructureNeutralResult result; const InfrastructureNeutralAvailable(this.result); }
final class InfrastructureNeutralUnavailable extends InfrastructureNeutralOutcome { final InfrastructureNeutralFailure failure; final InfrastructureResultFacts facts; const InfrastructureNeutralUnavailable(this.failure, this.facts); }
final class InfrastructureNeutralResult { final InfrastructureResultFacts facts; final InfrastructureIci ici; const InfrastructureNeutralResult(this.facts, this.ici); }
final class InfrastructureIci { final int value; final InfrastructureIciGrade grade; const InfrastructureIci(this.value, this.grade); }
enum InfrastructureWeightMode { lastSavedAccount, unsavedPreview, neutral }
```

| 输入约束 | 输出 / typed failures | 状态与副作用 | 顺序、权限与 fake |
| --- | --- | --- | --- |
| 只请求 `neutralForSuitability`；固定 `5/5/5`，同地点、分析日和版本。 | neutral unavailable 保留 failure/facts 为基础设施维度原因；account-weighted、last saved、unsaved preview 一律不接受。 | 只读，不读/缓存账户 ICI 权重；保留分项、行政区/交通基础、来源日期与 model/reference version。 | fake：neutral 66、account preview 99、少于 3 项、provenance 变；仅 neutral 66 可纳入。 |

## 3. B 必须提供的 Interface 卡：`SUITABILITY-001`

**提供者：** Personalized Location Suitability（B）；**消费者：** Application Shell；**唯一公开 import：** `package:locatemy/features/personalized_location_suitability/personalized_location_suitability.dart`。

```dart
abstract interface class PersonalizedLocationSuitability { Future<SuitabilitySingleOutcome> assess(SuitabilityRequest request); Future<SuitabilityComparisonOutcome> compare(SuitabilityComparisonRequest request); }
final class SuitabilityRequest { final ValidLocationReference location; final SuitabilityRequestContext context; const SuitabilityRequest(this.location, this.context); }
final class SuitabilityRequestContext { final String accountId; final int preferenceVersion, currentScenarioVersion; const SuitabilityRequestContext(this.accountId, this.preferenceVersion, this.currentScenarioVersion); }
final class SuitabilityComparisonRequest { final SuitabilityRequest a, b; const SuitabilityComparisonRequest(this.a, this.b); }
sealed class SuitabilitySingleOutcome { const SuitabilitySingleOutcome(); }
final class SuitabilityAvailable extends SuitabilitySingleOutcome { final SuitabilityResult result; const SuitabilityAvailable(this.result); }
final class SuitabilityPrerequisiteMissing extends SuitabilitySingleOutcome { final SuitabilityPrerequisite reason; const SuitabilityPrerequisiteMissing(this.reason); }
final class SuitabilityDimensionUnavailable extends SuitabilitySingleOutcome { final SuitabilityCoverage coverage; const SuitabilityDimensionUnavailable(this.coverage); }
final class SuitabilityNoAvailableDimensions extends SuitabilitySingleOutcome { final SuitabilityCoverage coverage; const SuitabilityNoAvailableDimensions(this.coverage); }
enum SuitabilityPrerequisite { location, accountScope, assessmentPreferences, currentBudgetScenario, staleRequest }
sealed class SuitabilityComparisonOutcome { const SuitabilityComparisonOutcome(); }
final class SuitabilityComparable extends SuitabilityComparisonOutcome { final SuitabilityResult a, b; const SuitabilityComparable(this.a, this.b); }
final class SuitabilityIncomparable extends SuitabilityComparisonOutcome { final SuitabilitySingleOutcome a, b; final SuitabilityComparisonReason reason; const SuitabilityIncomparable(this.a, this.b, this.reason); }
enum SuitabilityComparisonReason { sideUnavailable, includedDimensionsMismatch, accountOrPreferenceMismatch, currentScenarioMismatch, ruleVersionMismatch, dimensionProvenanceMismatch }
final class SuitabilityResult { final ValidLocationReference location; final int score; final SuitabilityCoverage coverage; final SuitabilityProvenance provenance; const SuitabilityResult(this.location, this.score, this.coverage, this.provenance); }
final class SuitabilityCoverage { final List<SuitabilityDimensionCoverage> dimensions; const SuitabilityCoverage(this.dimensions); }
final class SuitabilityDimensionCoverage { final SuitabilityDimension dimension; final SuitabilityPriority priority; final SuitabilityInclusion inclusion; final int? sourceScore, convertedScore; final SuitabilityDimensionFailure? unavailableReason; final List<String> warnings; const SuitabilityDimensionCoverage({required this.dimension, required this.priority, required this.inclusion, required this.sourceScore, required this.convertedScore, required this.unavailableReason, required this.warnings}); }
enum SuitabilityDimension { safety, cost, dailyConvenience, transitAccessibility, infrastructure }
enum SuitabilityPriority { low, medium, high }
enum SuitabilityInclusion { included, excludedLowPriority, unavailable }
enum SuitabilityDimensionFailure { safetyUnavailable, costBudgetIncomplete, facilityCoverageUnknown, transitNotScored, infrastructureNeutralUnavailable, upstreamUnavailable }
final class SuitabilityProvenance { final int preferenceVersion, currentScenarioVersion; final String ruleVersion; final Map<SuitabilityDimension, String> inputVersions; const SuitabilityProvenance(this.preferenceVersion, this.currentScenarioVersion, this.ruleVersion, this.inputVersions); }
```

| 调用 | 输入约束 | 输出 / typed failures | 状态、副作用、顺序与 fake |
| --- | --- | --- | --- |
| `assess` | immutable valid location；opened 同账户 complete preferences、current scenario 与版本仍匹配。 | `Available`；缺前置为 `PrerequisiteMissing`；中/高维缺失为 `DimensionUnavailable`；全不可用/可用权重零为 `NoAvailableDimensions`。 | 依序确认 Location → Account complete → COST-002 current → 五个 canonical inputs → 门控/计算 → publish；只存页面内存。fake 组合完整、low missing、medium/high missing、all missing、scope close/late response。 |
| `compare` | A/B 不同 immutable location；同一账户/complete preference/current 语境。 | 两端 compatible 才 `Comparable`；其余 `Incomparable(reason)` 并保留两端可用原分/coverage。 | 先独立 assess A/B，再核对；交换只改呈现槽位。fake 验证不同集合、版本、模型、单侧缺失均不产生 winner/delta。 |

`SuitabilityCoverage` 必须逐维保留 priority、included/excluded、原始/转换读数或 typed reason、来源/日期/完整性/stale warning。`SuitabilityProvenance` 必须保留 preference/current/rule version 及每个纳入维的上游 model、mapping/basket/reference/boundary 版本。公开结果不可含月净收入、预案名称/字段、账户草稿或账户 ICI 权重。

## 4. 固定业务语义、状态与顺序

| 主题 | 不可变协作语义 |
| --- | --- |
| 前置 | 无合法地点、非 opened scope、非同账户 complete preferences 或无 current 均先返回 prerequisite missing；不请求或拼接默认值、草稿、其他账户/预案。 |
| 五维转换 | 安全直接用安全指数；成本为 `100 − clamp(PersonalBudgetBurden(%), 0, 100)`；日常便利为 `100 × 已确认覆盖类别数 ÷ 5`；交通直接用 connectivity score；基础设施直接用 neutral ICI。所有范围为 0–100，具体公式唯一见知识库。 |
| 门控 | 偏好 `1–3` 为低、`4–6` 中、`7–10` 高。中/高任一不可用时不显示总分；低不可用可排除并说明。明确零是可用，unknown/partial/unavailable/no route 不是零。 |
| 重归一化 | 每个可用维权重乘数=`preference ÷ 5`；只对可用维按权重加权平均。所有维不可用或可用权重为零，固定文案为“个人化地点适配度暂不可用：目前没有可用的评估维度”。 |
| stale | 上游明确 available 的 stale 读数可参与且 warning 必须保留；partial 或 unavailable 不因缓存存在变 available。 |
| A/B | 仅两端 available、included/excluded 集合一致、同账户同偏好/current/rule version，且每个纳入维的上游模型、篮子/类别映射、边界/参照组与完整性相容时 Comparable。来源日期/stale 可不同但需并列披露；任何不相容均 incomparable。 |
| 生命周期 | preference/current/地点/上游 input version 或 scope 变化立即使旧请求失效；关闭开始释放私有总分/coverage。公共上游结果可由其 Owner 存续，但不可与旧账户输入重新组合。 |

实施顺序：B 先合入唯一入口、`SUITABILITY-001` 声明和最小 fake；各上游/ Shell 可并行以 fake 对接；B 再接入公开 Interface；最后按 FLOW-02、03、07 联调。不得以运行时 cache、SDK、并发策略或内部测试形状改变以上可观察结果。

## 5. 联合验收、Ready Gate 与变更

| Capability / canonical AT | 情景与操作 | 可观察完成条件 |
| --- | --- | --- |
| `MAP-07` / `AT-SUIT-01` | complete 五项、current、五个合格输入；安全/设施/交通有明确 0，交通 stale | `0–100`、转换、权重、覆盖、来源/日期/warning 均可读；0 与 stale 不丢失。 |
| `MAP-07` / `AT-SUIT-02` | no preferences/`configured_at` null、no current、草稿/保存失败、账户不同 | 分类 prerequisite missing 并提供 Shell 设置入口；默认 5、其他预案、temporary CPI、家庭收入均不替代。 |
| `MAP-07` / `AT-SUIT-03` | 每一维 unavailable/partial/unknown/no route；低/中/高缺失；全缺失 | 低缺失重归一化且披露；中/高无总分；全缺失固定文案；未知绝不成 0。 |
| `MAP-07` / `AT-SUIT-04`、`AT-RACE-01` | current/偏好成功变更、地点/上游版本刷新、快速换点 | 旧请求不发布，新完整语境重算；失败保存或晚到响应不覆盖有效结果。 |
| `MAP-07` / `AT-SUIT-05` | A/B 共同语境、单侧缺失、集合/偏好/current/rule/provenance 不同、交换 | 合格仅并列原分；不可用和 incomparable 有不同原因；永无差值、赢家、推荐；交换只改呈现。 |
| `MAP-07` / `AT-SUIT-06`、`AT-SWITCH-01` | A/B 账户不同偏好/current、scope close、晚到回调 | A 的总分、coverage、预案/偏好事实不进入 B；关闭期间无私有结果。 |
| 可访问性 | 中文/English、读屏/键盘、200% 字体、长日期/原因 | 分数不作唯一表达；五维、优先级、纳入/排除、来源、限制、设置入口有文字与正确阅读顺序。 |

- [x] 所有跨 Owner Interface 均有唯一 import、声明、约束、typed outcome、状态/副作用、顺序、最小调用与 fake。
- [x] 五维门控、明确零/未知、低优先级重归一化、stale、A/B 无赢家与账户隔离均有唯一事实源。
- [x] 不含实现体、SQL、SDK 映射、缓存/并发策略或内部测试组织。
- [x] Standards/Spec 双轴复审通过；设计 AI 依 ADR 0013 批准 Ready。公共 Interface 变更须由项目负责人批准，并同步受影响消费者、契约、fake 与 PDF。

| 日期 | 状态 | 变更原因 | 受影响对象 | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-15 | `Ready for Development` | Issue #23：升级为单一契约优先 Markdown/PDF；补齐 nine interface cards、typed declarations、Shell submit/publish、状态/权限/顺序/fake；不改变产品公式或数据模型 | `MAP-07`、`SUITABILITY-001`、`SHELL-001`、`LOCATION-001`、`ACCOUNT-001`、`COST-001/002`、`SAFETY-001`、`FACILITY-001`、`TRANSIT-001`、`INFRA-001` | 设计 AI（项目负责人授权） |
