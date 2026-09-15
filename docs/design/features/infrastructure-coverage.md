# Infrastructure Coverage 开发协作契约

> 状态：`Ready for Development`（2026-09-15；设计 AI〔项目负责人授权〕，ADR 0013）
> Owner：`B`；系统基线：`Baselined — 5d11769`；依赖波次：Wave 6
> 唯一公开入口：`package:locatemy/features/infrastructure_coverage/infrastructure_coverage.dart`
> 完成定义（DoD）：B 在唯一公开入口提供第 3 节完整 `INFRA-001` 声明；Shell 与 Suitability 可用该入口 fake 完成组合。真实 Adapter 经第 5 节证明五项/ICI 元数据、未知/0、A/B neutral 可比性、预览/保存和 A→B 隔离均可观察，且不伪装为零、成功或推荐。

本文件是 Infrastructure Coverage 唯一的 Development Contract；同名 HTML 是由它导出的供人阅读副本，不是独立规格。它冻结跨 Owner Dart seam、数据访问、权重生命周期和联验；`lib/features/infrastructure_coverage/` 内的 Widget、状态、Adapter、缓存、并发/取消/重试、计算组织和测试实现由 B 决定。公式正文只在知识库；表/RLS/migration 只在 Schema Catalog。

## 0. 固定阅读顺序与四项 Readiness

1. [领域词汇](../../../CONTEXT.md#行政地理语境)、[基础设施功能](../../knowledge_base/locatemy_product/features/infrastructure.md)、[ICI 评分模型](../../knowledge_base/locatemy_product/infrastructure_index_scoring.md)；
2. [Feature map](../system/feature-map.md#fm-infra)、[Interface 注册表](../system/interfaces.md)、[FLOW-02](../system/flows.md#flow-02单点选址地点摘要与六类分析)、[FLOW-03](../system/flows.md#flow-03地点-ab-比较)；
3. [Traceability](../system/capability-traceability.md)、[数据所有权](../system/data-ownership.md)、[Schema Catalog](../data/schema-catalog.md)、[`RISK-SCHEMA-01/02`](../system/risks-and-decisions.md#风险与关闭条件)、[`RISK-TRANSIT-01`](../system/risks-and-decisions.md#风险与关闭条件)；
4. 本契约及同名 HTML；后项不能改写前项。

| Readiness | 可核查证据 | 结论 |
| --- | --- | --- |
| 责任和顺序 | `INFRA-01/02` 唯一归 B；先有 `D25`–`D29`，再提供给 `D46` Suitability | 已就绪 |
| Interface | 第 2、3 节每个跨 Owner seam 都有入口、声明、约束、结果/失败、顺序、权限、示例和 fake | 已就绪 |
| 数据和权限 | B 唯一直读 `read_infrastructure_inputs` 和 own `user_ici_preferences`；公共输入只读，preview 仅页面内存 | 已就绪 |
| 联验和风险 | 第 5 节覆盖 single/A-B/缺失/保存/中性/换号；真实导入与迁移证据仍须满足 Schema risks | 已就绪 |

## 1. 成果、责任与边界

- 合法单点显示供水、供电、医疗、教育、公共交通的 0–100 分项、各自来源/日期/范围/缺失原因，以及可用时的 account-weighted ICI。ICI 是相对服务覆盖，不是质量、可靠性、官方评级或推荐。
- 医疗、教育、公共交通权重为 `1–10`；合法调整即时产生标记的 single `unsaved preview`，远端保存成功才成为跨设备 last saved。供水/供电没有滑块。
- A/B、地点摘要与 Suitability 只拿 `5/5/5` neutral ICI；两端只有资料口径相容才显示差异，永不显示赢家。

| Owner / 边界 | 负责 | 不负责 |
| --- | --- | --- |
| B：`lib/features/infrastructure_coverage/` | 五项分项、ICI、权重、`INFRA-001`、A/B 可比性 | 地点、Geo、GTFS、Shell、assessment preferences、Suitability |
| Shell | opened 主应用导航、返回、组合 | ICI/资料/权重/可比性 |
| Map / Geo / Transit / Privacy | immutable 合法地点；行政区事实；canonical connectivity；scope | B 的公式、资料读取、preview 或保存 |

## 2. B 需要调用的 Interface 与读取对象

只能 import 指定入口，不能 import 他人 `src/`、Adapter 或 SDK。以下仅是 declaration，不是可执行实现。

### Interface 卡：`SHELL-001` — 导航和组合

**提供者：** Application Shell；**唯一 import：** `package:locatemy/app/application_shell.dart`。

`SHELL-001` 的完整 canonical 声明、输入约束、结果、权限、顺序和 fake 规则只在 [Application Shell](../modules/application-shell.md#3-shell-必须提供的-interface) 定义。B 直接 import 该入口，不复制、缩窄或另造 Shell 类型。实际调用子集为 `ApplicationShell.submit(ShellIntent)` 与 `publish(ShellContribution)`，并处理 canonical `ShellIntentAccepted`、`ShellAuthenticationRequired`、`ShellIntentRejected(ShellRejectionReason)`、`ShellContributionAccepted`、`ShellContributionAuthenticationRequired`、`ShellContributionRejected(ShellRejectionReason)`；reason 仍为 `missingInput`、`staleInput`、`inapplicableDestination`、`scopeUnavailable`。

B 从自己的唯一入口完整导出 `OpenInfrastructureIntent`、`OpenInfrastructureComparisonIntent` 和 `InfrastructureContribution` marker；只含 immutable location、A/B 原角色、返回语境和 typed result，不能带可变地图、原始行、账户 ID 或表行。仅 opened scope 可 `submit/publish`；respective accepted 才导航/组合，authenticationRequired/rejected 是 Shell 结果而非数据 missing。Shell 仅改导航；地点、ICI、权重仍归 B。过期地点/角色/scope 的晚到结果不能发布。

最小调用：`await shell.publish(InfrastructureContribution(outcome, returnContext));`。fake Shell 返回 accepted、authenticationRequired、staleInput；断言拒绝不把旧 ICI 发布为新地点结果。

### Interface 卡：`LOCATION-001` — immutable 合法地点

**提供者：** Map / Location；**唯一 import：** `package:locatemy/features/map_location/map_location.dart`。

`LOCATION-001` 的完整 canonical 声明、输入约束、结果与生命周期只在 [Map / Location](map-and-location.md#location-001合法地点与收藏) 定义。B 的调用子集仅为 `LocationCoordinator.read(LocationRole)`，及 canonical `LocationRole`（single/locationA/locationB）、`LocationPresent`、`LocationAbsent`、`ValidLocationReference`；不 import `src/` 或重述 Map 类型。

只接受 single，或两个不同且角色明确的 A/B `LocationPresent`。absent、过期、非法/范围外或同点时不读资料、不产生 preview/ICI、不发布，也不以默认城市、收藏名或旧点替代。调用无副作用；结果始终绑定原 `locationId`、角色和分析日。fake Map 给 single/A-B/缺端/同点，断言缺端无请求、交换不污染原角色。

### Interface 卡：`GEO-001` — 行政地理语境

**提供者：** Geographic Context；**唯一 import：** `package:locatemy/modules/geographic_context/geographic_context.dart`。

`GEO-001` 的完整 canonical 声明、逐层结果、provenance 与失败语义只在 [Geographic Context](../modules/geographic-context.md#interface-卡行政统计地理语境geo-001) 定义。B 的调用子集为 `GeographicContext.resolve(GeographicContextRequest)`，请求 `district` 与 `reportingState`，并处理 canonical `GeographicContextAvailable` / `GeographicContextUnavailable` 及每层 `GeographicLevelResolved`、`GeographicLevelUnresolved`、`GeographicLevelAmbiguous`；不复制或重塑任何 Geo 类型。

B 请求同一地点的 district/reportingState；只有 `GeographicLevelResolved(district)` 能读四项行政区资料。`GeographicLevelUnresolved` / `GeographicLevelAmbiguous`（即使州 resolved）使水、电、医疗、教育均 missing，保留 canonical 原因/provenance/candidates；不得以州、邻区、名称或历史结果补足。调用只读、不改变地点或账户。fake Geo 给 resolved、unresolved、ambiguous 和 state-only；断言交通仍独立但四项不猜测。

### Interface 卡：`TRANSIT-001` — canonical connectivity

**提供者：** Public Transportation；**唯一 import：** `package:locatemy/features/public_transportation/public_transportation.dart`。

`TRANSIT-001` 的完整 canonical 声明只在 [Public Transportation](public-transportation.md) 定义。B 的调用子集为 `PublicTransportation.load(TransitRequest)` 及 canonical available/incomplete/unavailable、service outcome、score 与 provenance；不复制或重塑 Transit 类型。

请求必须用同地点、明确分析日、`1,500m`；仅 `TransitAvailable + served + score != null` 的 score 进入交通分。noStops/noActiveRoutes、incomplete、unavailable 都是交通 component missing，原样保留原因；served score 0 是有效 0。完整 served 的 stale warning 仍可用且保留 warning，B 不下载 GTFS/重算百分位。保存 analysisDate/radius/snapshot/reference-grid 用于 A/B 可比性。fake Transit 覆盖 served 0、noStops、noActiveRoutes、incomplete/unavailable、stale served，断言仅 scored served 入 ICI。

### Interface 卡：`PRIVACY-001` — 账户范围

**提供者：** Account Privacy；**唯一 import：** `package:locatemy/features/account_privacy/account_privacy.dart`。

`PRIVACY-001` 的完整 canonical 声明、账户范围、关闭参与者和结果只在 [Account Privacy](../modules/account-privacy.md#privacy-001--账户范围与关闭参与者) 定义。B 的调用子集为 `AccountPrivacy.readScope()` 与 infrastructureCoverage participant 的 `clearPrivateState(AccountScope)`；处理 canonical `AccountScopeOpened`、`AccountScopeClosing`、`AccountScopeClosed`、`AccountScopeUnavailable` 和 `PrivateStateCleared` / `PrivateStateClearIncomplete`。不以本地 `read()`、自定义 account id 或旧 scope 类型替代。

Shell 唯一发起 lifecycle。B 仅同账户 `AccountScopeOpened` 时读/写权重；`AccountScopeClosing` 即令旧 preview、last-saved 副本、保存中动作和晚到结果不可读/提交。B 只清理并报告 `STATE-INFRA-WEIGHT-PREVIEW`，不删远端权重或公共资料；closed/identity mismatch 绝不伪装为已保存 `5/5/5`。fake A opened→closing→closed→B opened，断言 A 回调不进入 B，公共资料无账户字段。

### 直接读取：`read_infrastructure_inputs` 与 `user_ici_preferences`（仅 B）

`read_infrastructure_inputs` 是 authenticated security-invoker、只读、`proposed` 的 View/RPC；Flutter 不直读 `hh_access_amenities`、`hospital_beds`、`population_district`、`schools_district`、`teachers_district`、`enrolment_school_district`。`user_ici_preferences` 是 B 的 owner-only CRUD 表：每账户一行，`health/education/transit` 整数 `1–10`、`updated_at`；缺行=5。旧五个 `0–1` 列仅迁移来源。

```dart
abstract interface class InfrastructureInputsReader { Future<InfrastructureInputsOutcome> read(InfrastructureInputsRequest request); }
final class InfrastructureInputsRequest { final AdministrativeGeographicContext district; final InfrastructureRefreshPolicy policy; const InfrastructureInputsRequest({required this.district, required this.policy}); }
enum InfrastructureRefreshPolicy { cacheAllowed, refresh }
sealed class InfrastructureInputsOutcome { const InfrastructureInputsOutcome(); }
final class InfrastructureInputsAvailable extends InfrastructureInputsOutcome { final InfrastructureInputRows rows; const InfrastructureInputsAvailable(this.rows); }
final class InfrastructureInputsUnavailable extends InfrastructureInputsOutcome { final InfrastructureInputsFailure failure; const InfrastructureInputsUnavailable(this.failure); }
enum InfrastructureInputsFailure { retryableUnavailable, sourceUnverifiable, permissionDenied }
final class InfrastructureInputRows { final String state; final String district; final List<AmenitiesRow> amenities; final List<HospitalBedsRow> beds; final List<PopulationRow> population; final List<SchoolsRow> schools; final List<TeachersRow> teachers; final List<EnrolmentRow> enrolment; const InfrastructureInputRows({required this.state, required this.district, required this.amenities, required this.beds, required this.population, required this.schools, required this.teachers, required this.enrolment}); }
final class AmenitiesRow { final DateTime date; final double? pipedWater; final double? electricity; final String sourceId; const AmenitiesRow(this.date, this.pipedWater, this.electricity, this.sourceId); }
final class HospitalBedsRow { final DateTime date; final String type; final int? value; const HospitalBedsRow(this.date, this.type, this.value); }
final class PopulationRow { final DateTime date; final String sex; final String age; final String ethnicity; final int? value; const PopulationRow(this.date, this.sex, this.age, this.ethnicity, this.value); }
final class SchoolsRow { final DateTime date; final String stage; final String type; final int? value; const SchoolsRow(this.date, this.stage, this.type, this.value); }
final class TeachersRow { final DateTime date; final String stage; final String sex; final int? value; const TeachersRow(this.date, this.stage, this.sex, this.value); }
final class EnrolmentRow { final DateTime date; final String stage; final String sex; final int? value; const EnrolmentRow(this.date, this.stage, this.sex, this.value); }
```

请求 `(state,district)` 必为 Geo resolved；每数据集取自身最新有效日期，人口同年或最多向前两年且 `sex=both/age=overall/ethnicity=overall`；排除 `All Districts`/州合计。失败和必要字段 null 使对应 component missing；明确 0 有效。B 仅同账户 select/insert/update 权重，不能将 preview 写表。fake reader 给完整、必要行缺失、人口超期、0、permissionDenied，验证分项缺失和门槛。

## 3. B 必须提供的 Interface

### Interface 卡：`INFRA-001` — 五项结果、权重和 neutral ICI

**提供者：** Infrastructure Coverage（B）；**消费者：** Application Shell、Personalized Location Suitability；**唯一 import：** `package:locatemy/features/infrastructure_coverage/infrastructure_coverage.dart`。消费者不得读 B 的表/View、`src/` 或重算 ICI；B 先合并以下声明和最小 fake。

```dart
final class InfrastructureReturnContext { final String destination; final String? stableItemId; const InfrastructureReturnContext({required this.destination, this.stableItemId}); }
final class OpenInfrastructureIntent extends ShellIntent { final ValidLocationReference location; final InfrastructureReturnContext returnContext; const OpenInfrastructureIntent({required this.location, required this.returnContext}); }
final class OpenInfrastructureComparisonIntent extends ShellIntent { final ValidLocationReference locationA; final ValidLocationReference locationB; final InfrastructureReturnContext returnContext; const OpenInfrastructureComparisonIntent({required this.locationA, required this.locationB, required this.returnContext}); }
final class InfrastructureContribution extends ShellContribution { final InfrastructureContributionTarget target; final InfrastructureReturnContext returnContext; final InfrastructureLoadOutcome? single; final InfrastructureComparisonOutcome? comparison; const InfrastructureContribution({required this.target, required this.returnContext, this.single, this.comparison}); }
enum InfrastructureContributionTarget { single, comparison }
abstract interface class InfrastructureCoverage {
  Future<InfrastructureLoadOutcome> loadSingle(InfrastructureSingleRequest request);
  Future<InfrastructureComparisonOutcome> compare(InfrastructureComparisonRequest request);
  Future<InfrastructureNeutralOutcome> neutralForSummary(InfrastructureNeutralRequest request);
  Future<InfrastructureNeutralOutcome> neutralForSuitability(InfrastructureNeutralRequest request);
  InfrastructureWeightPreviewOutcome previewWeights(InfrastructureWeightPreviewRequest request);
  Future<InfrastructureWeightOutcome> saveWeights(SaveInfrastructureWeightsRequest request);
  InfrastructureWeightPreviewOutcome restoreLastSavedWeights();
}
final class InfrastructureSingleRequest { final ValidLocationReference location; final DateTime analysisDate; final InfrastructureLoadPolicy policy; const InfrastructureSingleRequest({required this.location, required this.analysisDate, required this.policy}); }
final class InfrastructureNeutralRequest { final ValidLocationReference location; final DateTime analysisDate; final InfrastructureLoadPolicy policy; const InfrastructureNeutralRequest({required this.location, required this.analysisDate, required this.policy}); }
enum InfrastructureLoadPolicy { cacheAllowed, refresh }
final class InfrastructureComparisonRequest { final InfrastructureNeutralRequest a; final InfrastructureNeutralRequest b; const InfrastructureComparisonRequest({required this.a, required this.b}); }
final class InfrastructureWeights { final int health; final int education; final int transit; const InfrastructureWeights({required this.health, required this.education, required this.transit}); }
final class InfrastructureWeightPreviewRequest { final InfrastructureWeights weights; const InfrastructureWeightPreviewRequest(this.weights); }
final class SaveInfrastructureWeightsRequest { final InfrastructureWeights weights; const SaveInfrastructureWeightsRequest(this.weights); }
sealed class InfrastructureLoadOutcome { const InfrastructureLoadOutcome(); }
final class InfrastructureLoaded extends InfrastructureLoadOutcome { final InfrastructureSingleResult result; const InfrastructureLoaded(this.result); }
final class InfrastructureLoadRejected extends InfrastructureLoadOutcome { final InfrastructureLoadFailure failure; const InfrastructureLoadRejected(this.failure); }
enum InfrastructureLoadFailure { invalidLocation, scopeUnavailable, staleRequest, retryableUnavailable }
sealed class InfrastructureNeutralOutcome { const InfrastructureNeutralOutcome(); }
final class InfrastructureNeutralAvailable extends InfrastructureNeutralOutcome { final InfrastructureNeutralResult result; const InfrastructureNeutralAvailable(this.result); }
final class InfrastructureNeutralUnavailable extends InfrastructureNeutralOutcome { final InfrastructureNeutralFailure failure; final InfrastructureResultFacts facts; const InfrastructureNeutralUnavailable(this.failure, this.facts); }
enum InfrastructureNeutralFailure { insufficientBaseWeight, componentUnavailable, staleRequest, invalidLocation }
sealed class InfrastructureComparisonOutcome { const InfrastructureComparisonOutcome(); }
final class InfrastructureComparable extends InfrastructureComparisonOutcome { final InfrastructureNeutralResult a; final InfrastructureNeutralResult b; const InfrastructureComparable(this.a, this.b); }
final class InfrastructureIncomparable extends InfrastructureComparisonOutcome { final InfrastructureNeutralOutcome a; final InfrastructureNeutralOutcome b; final InfrastructureComparisonFailure failure; const InfrastructureIncomparable(this.a, this.b, this.failure); }
enum InfrastructureComparisonFailure { sideUnavailable, geographicBasisMismatch, sourceDateMismatch, sourceMismatch, modelOrReferenceMismatch, completenessMismatch }
sealed class InfrastructureWeightPreviewOutcome { const InfrastructureWeightPreviewOutcome(); }
final class InfrastructureWeightPreviewed extends InfrastructureWeightPreviewOutcome { final InfrastructureWeights weights; final InfrastructureSingleResult result; const InfrastructureWeightPreviewed(this.weights, this.result); }
final class InfrastructureWeightPreviewRejected extends InfrastructureWeightPreviewOutcome { final InfrastructureWeightFailure failure; const InfrastructureWeightPreviewRejected(this.failure); }
sealed class InfrastructureWeightOutcome { const InfrastructureWeightOutcome(); }
final class InfrastructureWeightsSaved extends InfrastructureWeightOutcome { final InfrastructureWeights weights; final DateTime updatedAt; const InfrastructureWeightsSaved(this.weights, this.updatedAt); }
final class InfrastructureWeightsSaveRejected extends InfrastructureWeightOutcome { final InfrastructureWeightFailure failure; const InfrastructureWeightsSaveRejected(this.failure); }
enum InfrastructureWeightFailure { invalidLevel, scopeUnavailable, retryableUnavailable, permissionDenied, staleRequest }
```

```dart
final class InfrastructureSingleResult { final InfrastructureResultFacts facts; final InfrastructureIci accountWeightedIci; final InfrastructureWeightContext weightContext; const InfrastructureSingleResult({required this.facts, required this.accountWeightedIci, required this.weightContext}); }
final class InfrastructureNeutralResult { final InfrastructureResultFacts facts; final InfrastructureIci ici; const InfrastructureNeutralResult({required this.facts, required this.ici}); }
final class InfrastructureResultFacts { final ValidLocationReference location; final AdministrativeGeographicContext? district; final DateTime analysisDate; final List<InfrastructureComponent> components; final InfrastructureProvenance provenance; const InfrastructureResultFacts({required this.location, required this.district, required this.analysisDate, required this.components, required this.provenance}); }
enum InfrastructureComponentKind { water, electricity, health, education, transit }
sealed class InfrastructureComponent { final InfrastructureComponentKind kind; const InfrastructureComponent(this.kind); }
final class InfrastructureComponentAvailable extends InfrastructureComponent { final int score; final DateTime sourceDate; final String sourceId; final String unit; final String geographicBasis; final String? warning; const InfrastructureComponentAvailable({required super.kind, required this.score, required this.sourceDate, required this.sourceId, required this.unit, required this.geographicBasis, required this.warning}); }
final class InfrastructureComponentMissing extends InfrastructureComponent { final InfrastructureComponentMissingReason reason; final String detail; const InfrastructureComponentMissing({required super.kind, required this.reason, required this.detail}); }
enum InfrastructureComponentMissingReason { geographicContextUnavailable, sourceRowsMissing, populationDateIneligible, requiredMetricMissing, transitNotScored, sourceUnavailable, staleRequest }
final class InfrastructureIci { final int value; final InfrastructureIciGrade grade; const InfrastructureIci(this.value, this.grade); }
enum InfrastructureIciGrade { weak, fair, good, veryGood }
enum InfrastructureWeightMode { lastSavedAccount, unsavedPreview, neutral }
final class InfrastructureWeightContext { final InfrastructureWeightMode mode; final InfrastructureWeights weights; final DateTime? savedUpdatedAt; const InfrastructureWeightContext({required this.mode, required this.weights, required this.savedUpdatedAt}); }
final class InfrastructureProvenance { final String? boundaryVersion; final String? transitSnapshotId; final String? transitReferenceGridVersion; final String calculationModelVersion; const InfrastructureProvenance({required this.boundaryVersion, required this.transitSnapshotId, required this.transitReferenceGridVersion, required this.calculationModelVersion}); }
```

| 主题 | 固定协作语义 |
| --- | --- |
| single/account | `loadSingle` 只接受 single immutable location、分析日和 opened scope；无行=last saved `5/5/5`。合法 preview 覆盖本页并标记 `unsavedPreview`。 |
| neutral | summary、Suitability、A/B 强制 `5/5/5` 和 mode neutral；不得读、输出、缓存或推导账户权重。 |
| 分项 | water/electricity 直接百分比；health=所有 type beds ÷ eligible population ×1000 的同期全国行政区百分位；education=学校密度与师生资源百分位各 50%；transit 仅 canonical scored served。均 0–100，附单位/范围、日期/来源/warning。 |
| 缺失/ICI | 任一必要 input 缺失则整个分项 missing；未知不为 0，明确 0 为 available。missing 不入分子/分母；五项原始基础权重均 .20，少于 3 项可用则 ICI unavailable。 |
| 权重 | water/electricity multiplier 1；三个滑块 `1–10`、multiplier=`level/5`；account-weighted 仅 single，neutral 固定 5；assessment preferences 永不进入 ICI。 |

`InfrastructureLoadRejected` 是无法安全开始，与已返回其余分项/一个 missing 不同。preview 仅同步改 `STATE-INFRA-WEIGHT-PREVIEW`；非整数/不在 1–10 返回 `invalidLevel` 并不改 preview。save 只保存全部三项合法值；仅 `InfrastructureWeightsSaved` 替换 last saved/发布跨设备，失败保留 preview/last saved，restore 可恢复；不建离线写队列。scope close、身份不符、地点/日期/provenance 改变时，旧 load/save 变 `scopeUnavailable/staleRequest`，不污染新账户/地点。公开结果不含 account ID、表行或原始数据。

**A/B 顺序：** Shell/Map 先给原顺序 A/B；B 分别取 Geo、输入和 Transit，先形成两端 neutral。任一 ICI unavailable 为 `InfrastructureIncomparable(sideUnavailable)`；只有全部使用分项的日期/source、district/1,500m basis、模型、Transit snapshot/reference-grid 和完整性相容，才 `Comparable` 并显示差异。交换只换槽位。Suitability 只调用 `neutralForSuitability`。

```dart
final outcome = await infrastructure.loadSingle(
  InfrastructureSingleRequest(location: location, analysisDate: analysisDate, policy: InfrastructureLoadPolicy.cacheAllowed),
);
```

调用方以 `InfrastructureLoaded` 呈现 `facts`、`accountWeightedIci` 和 `weightContext`；以 `InfrastructureLoadRejected` 呈现可区分恢复路径，绝不显示伪 0。

**Fake 场景：** Shell/Suitability 以 fake `InfrastructureCoverage` 返回完整 neutral、single `8/3/10` preview、Geo missing/人口超期/Transit noActiveRoutes/served 0、A/B provenance mismatch、save retryable failure、A closing→B opened。断言 Shell 保留地点/原因；Suitability 永远只见 neutral；失败保存不丢 preview；A 回调不进入 B。无需生产 Geo/Transit/Supabase。

## 4. 直接数据与推荐实施顺序

| 对象 | B 的边界 | 不可变规则 |
| --- | --- | --- |
| `read_infrastructure_inputs` | authenticated security-invoker read-only；仅 B | 各数据集最新有效日期；每项独立日期/来源；不能以导入时间代替统计日期。 |
| `user_ici_preferences` | B owner-only select/insert/update | 缺行=5；只存 last saved；旧 0–1 表不消费；其他 Owner 仅 `INFRA-001`。 |
| `STATE-INFRA-WEIGHT-PREVIEW` | B 当前账户 single 页内存 | 关闭即清；不进 A/B、summary、Suitability/跨设备。 |

1. B 先合并唯一入口、`INFRA-001` declarations 和最小 fake。
2. B 实现 immutable-location 管线：Geo、稳定 View、canonical Transit 到五项/缺失/provenance。
3. B 实现 opened-scope 权重 read/preview/save/restore/close，完成 `RISK-SCHEMA-02` 迁移证据。
4. Shell/Suitability 并行使用 fake；最后只共同联调第 5 节场景。

## 5. 联合验收

| 场景 | Owner | 可观察结果 | 追踪 |
| --- | --- | --- | --- |
| 完整 single | B、Map、Geo、Transit、Shell | 五项/ICI 均有分数、单位/范围、来源、各自日期与模型；不称质量 | `INFRA-01`；`AT-ANALYSIS-01` |
| unknown/0/stale | B、Geo、Transit、Shell | Geo/输入/人口/Transit 不可用均具体 missing；0 保持 0；stale served 可用 warning；<3 项无 ICI | `INFRA-01`；`AT-ANALYSIS-01` |
| A/B neutral | B、Map、Geo、Transit、Shell | 固定 5/5/5；仅相容显示差异；否则保留原值/原因、无赢家；交换不换引用 | `INFRA-01`；`AT-COMPARE-01/03` |
| preview/save | B、Privacy、Shell | 缺行 5；合法预览即时；成功才发布；失败 retain/retry/restore；分项/neutral 不变 | `INFRA-02`；`AT-ANALYSIS-01` |
| neutral consumer | B、Suitability、Shell | 摘要/A-B/Suitability 只得 neutral 或明确 unavailable | `INFRA-01/02`；`AT-SUIT-01` |
| A→B | B、Privacy、Shell | A preview/save/晚到结果不入 B；B 只见自己的行或 5；公共资料无私有字段 | `INFRA-02`；`AT-SWITCH-01`、`AT-RACE-01` |

## 6. 实现自由、阻塞和参考

B 可决定私有文件、Widget、状态管理、缓存、Supabase 映射和测试。若改变公开入口/声明/结果/失败、ICI/neutral 边界、可比性、顺序/权限，或 View/table 字段/RLS/migration/官方口径，须与受影响 Owner 停止协商。

实现 Gate：`read_infrastructure_inputs`、`user_ici_preferences` 仍 `proposed`。完成前须验证官方 schema、导入行数/最大日期/唯一键、完整/空/部分资料、人口年份、三项迁移、owner-only RLS 和两账户样本，满足 `RISK-SCHEMA-01/02`；不得以 fixture、旧五列权重或镜像直读冒充完成。权威来源：[评分模型](../../knowledge_base/locatemy_product/infrastructure_index_scoring.md)、[Schema Catalog](../data/schema-catalog.md)、[Transit 契约](public-transportation.md#interface-卡transit-001--公共交通-canonical-connectivity-result)、[数据所有权](../system/data-ownership.md)。

## 7. 契约变更与完成检查

公开变更须由提供方说明原因/消费者，所有消费者确认；同一 PR 更新 declarations、契约、同名 HTML 与受影响 fake/Adapter tests。Git/PR 保存历史；不使用独立发布、文档版本、checksum、Manifest、Generation Gate 或 Development Release。

- [x] 四项 Readiness 可核查。
- [x] Shell/Location/Geo/Transit/Privacy 的完整 frozen 声明由各 owning contract 唯一拥有；本 Feature 只说明实际调用子集。`INFRA-001` 有唯一入口、完整公开声明、约束、typed failures、状态、权限、顺序、示例和 fake。
- [x] 直接数据访问、字段、CRUD/RLS、公式输入、单位、missing/0/60%/权重/neutral 均完整。
- [x] 无函数体、Widget、SDK、SQL、migration 或测试实现。
- [x] 同名 HTML 与本 Markdown 语义等价；无 PDF、ADR 0014 或 handoff 发布治理。

## 8. Change Log

| 日期 | 状态 | 变更原因 | 受影响对象 | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Ready for Development` | 固定五项覆盖、ICI、权重、neutral 与联验语义 | `INFRA-01`、`INFRA-02`、`INFRA-001` | 项目负责人 |
| 2026-09-15 | `Ready for Development` | Issue #23 返工为单一 Development Contract：补首屏可观察 DoD；上游 frozen seam 改为引用 owning canonical 声明并列出实际调用子集；移除 PDF、ADR 0014 与 handoff 治理 | `INFRA-001`、`SHELL-001`、`LOCATION-001`、`GEO-001`、`TRANSIT-001`、`PRIVACY-001`、同名 HTML | 设计 AI〔项目负责人授权〕，ADR 0013 |
