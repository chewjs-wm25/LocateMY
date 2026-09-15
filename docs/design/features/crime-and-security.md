# Crime & Security 开发协作契约

> 状态：`Ready for Development`（2026-09-15；设计 AI〔项目负责人授权〕，ADR 0013）  
> Owner：`B`；系统基线：`Baselined — 5d11769`；依赖波次：Wave 5  
> 唯一公开入口：`package:locatemy/features/crime_and_security/crime_and_security.dart`  
> 定义完成：消费者可只凭本契约请求、呈现和保存同一不可变地点的州级安全结果；不会把警区、未知资料、隐患或导航结果混入治安结论。

本文件是 Crime & Security 对 #23 的唯一 Development Contract；Markdown 是权威来源，[同名 HTML](../../human/crime-and-security.html) 是语义等价、供人阅读的导出，不是第二份规格或发布包。它固定公开 Dart 声明、跨模块顺序、结果语义、数据边界和联合验收；`lib/features/crime_and_security/` 内的 Widget、状态管理、Adapter、缓存、并发/取消/重试及测试组织由 B 决定。公式正文只在产品知识库，字段、RLS、迁移和缓存物理结构只在 Schema Catalog。

## 0. 固定阅读顺序与四项 Readiness

1. [地点/统计州领域词汇](../../../CONTEXT.md#行政区与统计州) 与[治安产品事实及公式](../../knowledge_base/locatemy_product/features/crime_security.md)；
2. [Feature map（Crime）](../system/feature-map.md#fm-safety)、[Interface 注册表](../system/interfaces.md)、[FLOW-02](../system/flows.md#flow-02单点地点分析与摘要组合)、[FLOW-03](../system/flows.md#flow-03a-b-地点比较)、[FLOW-06](../system/flows.md#flow-06房产风险快照)；
3. [Capability Traceability](../system/capability-traceability.md)、[数据所有权](../system/data-ownership.md)、[Schema Catalog](../data/schema-catalog.md)、[风险登记](../system/risks-and-decisions.md#风险与关闭条件)；
4. 本契约与[同名 HTML 导出](../../human/crime-and-security.html)。Git/PR 保存变更历史；不使用 PDF、Manifest、checksum、Locked Source Set、Generation Gate、Development Release 或 Invalidated 生命周期。

| Readiness | 可核查证据 | 结论 |
| --- | --- | --- |
| 责任与范围 | `SAFE-01`、`SAFE-03` 唯一归属 Crime；警区边界/安全图层、Hazard、房产和可变选点归其他 Owner | 已就绪 |
| 契约与消费者 | `SAFETY-001` 唯一入口、声明、顺序和 fake 在第 3 节；上游仅 `SHELL-001`、`LOCATION-001`、`GEO-001` | 已就绪 |
| 数据与安全 | 只由 `read_safety_inputs` 读取 `crime_district`；`crime_public_cache` 无账户字段；对象契约只在 Catalog | 已就绪 |
| 验收与风险 | 第 5 节覆盖 canonical `AT-*`；`RISK-SCHEMA-01` 留作实现/集成证据 | 已就绪 |

## 1. 成果、责任与冻结边界

- 用户可看到分析地点所属**统计州**的 0–100 安全指数、最新完整年度案件数、五年趋势、类别可用性、来源、年份、完整性和缓存状态；分数高仅表示同年同类别州级已定罪案件规模相对较低。
- 单点与 A/B 都绑定 Map 的不可变地点引用。A/B 仅在年份、口径、完整性、模型及边界版本一致时显示差异；不产生赢家或搬迁建议。
- `all`、`assault`、`property` 和可用具体 `type` 仅筛选趋势，绝不改变指数、最新完整年度或总体案件数。
- 不包含 `SAFE-02`：不解析/呈现警区边界或安全地图图层；`crime_district.district` 只为州级聚合原始字段。Hazard 报告、投票、状态、图层和计数不进入本 Feature 结果、缓存或适配度输入。

| Owner / 受控边界 | 负责 | 不负责 | 协作 |
| --- | --- | --- | --- |
| `lib/features/crime_and_security/`（B） | 官方资料、州级模型、趋势/筛选、3 天公共缓存、可比性、`SAFETY-001` | 地点选择、行政空间匹配、Shell、Hazard、房产/风险快照、适配度 | 消费 `SHELL-001`、`LOCATION-001`、`GEO-001`；提供 `SAFETY-001` |
| Application Shell | 门控、分析/比较/返回/房产目的地导航、摘要组合 | 公式、资料解释、比较、缓存、房产资料 | 接收 Crime intent；消费 `SAFETY-001` |
| Map / Location | 合法 immutable single/A/B 地点和主地图 | 统计州、治安资料/图层 | `LOCATION-001` |
| Geographic Context | 坐标到 reporting state 的版本化 resolved/unresolved/ambiguous | 警区、聚合、指数 | `GEO-001` |
| Crime 受控对象 | `read_safety_inputs`、`crime_public_cache` | 用户资料、镜像表直读、跨 Feature cache | Schema Catalog 唯一权威 |

## 2. 需要调用的 Interface

### Interface 卡：`SHELL-001` — 分析返回与房产业务导航

**提供者：** Application Shell；**消费者：** Crime & Security；**唯一公开 import：** `package:locatemy/app/application_shell.dart`；**完整 canonical 声明和权威入口：** [Application Shell 的 `SHELL-001`](../modules/application-shell.md#3-shell-必须提供的-interface)。

Crime 只能对 provider 原样声明的 `ApplicationShell.submit(ShellIntent)` 调用，且只处理原样的 `ShellIntentAccepted`、`ShellAuthenticationRequired`、`ShellIntentRejected(ShellRejectionReason)`；不得在本 Feature 截断、复制、改名或另造 submit-only declaration / outcome。Crime 从自己的唯一入口导出具体 `ShellIntent` marker：返回地图时含当前 immutable `ValidLocationReference` 与原返回语境；打开房产档案或新增房产时只含原返回语境，不能携带房产、草稿、照片、治安结果或可变地图对象。其字段形状与返回语境的完整声明由 Crime 入口在与 Shell 联调前先合入；Shell 不拥有或重述这些领域字段。

| 输入约束 | 输出 / typed failures | 状态与副作用 | 顺序、权限与最小示例 |
| --- | --- | --- | --- |
| marker 目的地唯一、地点/返回语境完整、仍属当前 opened scope 且未过期。 | 只接受 provider 的三种 canonical outcome；后两者是导航结果，不是资料失败。 | Shell 只改门控、导航/返回栈或组合；Crime 不改 Map、结果、cache 或房产。 | 仅 opened 主应用；`await shell.submit(returnToMapIntent);`。拒绝或需认证时留页并保留安全结果与恢复原因。 |

**Fake 场景：** fake 必须实现 provider 的完整 `ApplicationShell`，分别返回 canonical accepted、authentication-required、`ShellIntentRejected(staleInput)`；断言 payload 不变，后两种不清除安全结果。无需真实 Shell、Map 或 Property。

### Interface 卡：`LOCATION-001` — 不可变合法地点（输入前提）

**提供者：** Map / Location；**消费者：** Crime & Security；**唯一公开 import：** `package:locatemy/features/map_location/map_location.dart`；**完整 canonical 声明和权威入口：** [Map / Location 的 `LOCATION-001`](map-and-location.md#location-001合法地点与收藏)。

Crime 不调用或包装 `LocationCoordinator` 来选点；它只接受 provider 的完整 canonical `ValidLocationReference` 作为 `SafetyRequest.location`。该引用必须来自 `LocationSelected`，角色为 single 或保留顺序的 A/B。`LocationAbsent`、`LocationSelectionRejected(invalidCoordinate/outsideMalaysia/sameComparisonPoint/scopeUnavailable)` 及任何自行构造、过期或可变地图状态都不得触发 Geo、资料读取、cache 或 Shell contribution。`displayName` 可为 null，且不作地区解析或 cache key。

**最小使用：** `SafetyRequest(location: selectedLocation, policy: SafetyLoadPolicy.cacheAllowed, filter: const AllCrimeTrend())`，其中 `selectedLocation` 是 canonical `LocationSelected.location`。**Fake 场景：** fake `LocationCoordinator` 只交付 canonical single/A/B 成功引用或上述 canonical rejection；Crime 仅转交成功引用。

### Interface 卡：`GEO-001` — reporting state 语境

**提供者：** Geographic Context；**消费者：** Crime & Security；**唯一公开 import：** `package:locatemy/modules/geographic_context/geographic_context.dart`；**完整 canonical 声明和权威入口：** [Geographic Context 的 `GEO-001`](../modules/geographic-context.md#interface-卡行政统计地理语境geo-001)。

Crime 只能调用 provider 原样声明的 `GeographicContext.resolve(GeographicContextRequest)`，请求必须是 `location: selectedLocation`、`levels: {GeographicLevel.reportingState}`。只在 `GeographicContextAvailable.results[GeographicLevel.reportingState]` 是 `GeographicLevelResolved` 时，使用该 `AdministrativeArea.reportingStateId` / `reportingStateName` 和同批 `BoundaryProvenance` 进入官方读取。`GeographicContextUnavailable`、`GeographicLevelUnresolved` 与 `GeographicLevelAmbiguous` 都映射为 Safety 的 typed unavailable；保留原因和已知 provenance，不选候选、不猜名称、不回退行政区、最近州或警区。

请求是公共只读，不能改地点、边界、账户或既有结果。边界 provenance 的 dataset/version/hash 是 cache key、`SafetyProvenance.boundaryVersion` 与 A/B 可比性的输入；版本不同不能称可比，旧地点/旧版本晚到结果不能覆盖当前端。

**最小调用：** `await geographicContext.resolve(GeographicContextRequest(location: selectedLocation, levels: {GeographicLevel.reportingState}));`。**Fake 场景：** fake 实现完整 canonical `GeographicContext`，覆盖 resolved、`GeographicLevelUnresolved(noCoverage)`、完整候选的 ambiguous、`GeographicContextUnavailable(scopeUnavailable)` 与不同 `sourceVersion`；仅 resolved 进入 `SAFETY-002`。

## 3. 必须提供的 Interface

### Interface 卡：`SAFETY-001` — 州级安全结果与趋势

**提供者：** Crime & Security（B）；**消费者：** Application Shell、Property Inspection、Personalized Location Suitability；**唯一公开 import：** `package:locatemy/features/crime_and_security/crime_and_security.dart`。

消费者只能 import 此入口。B 应先合入下列声明与最小 fake；这是协作形状，不是可提交实现体。

```dart
abstract interface class CrimeAndSecurity {
  Future<SafetyLoadOutcome> load(SafetyRequest request);
  Future<SafetyComparisonOutcome> compare(SafetyComparisonRequest request);
}
final class SafetyRequest {
  final ValidLocationReference location;
  final SafetyLoadPolicy policy;
  final SafetyTrendFilter filter;
  const SafetyRequest({required this.location, required this.policy, required this.filter});
}
enum SafetyLoadPolicy { cacheAllowed, refresh }
sealed class SafetyTrendFilter { const SafetyTrendFilter(); }
final class AllCrimeTrend extends SafetyTrendFilter { const AllCrimeTrend(); }
final class CategoryTrend extends SafetyTrendFilter { final CrimeCategory category; const CategoryTrend(this.category); }
final class TypeTrend extends SafetyTrendFilter { final String type; const TypeTrend(this.type); }
enum CrimeCategory { assault, property }
sealed class SafetyLoadOutcome { const SafetyLoadOutcome(); }
final class SafetyAvailable extends SafetyLoadOutcome { final SafetySnapshot snapshot; const SafetyAvailable(this.snapshot); }
final class SafetyPartiallyAvailable extends SafetyLoadOutcome { final SafetySnapshot snapshot; const SafetyPartiallyAvailable(this.snapshot); }
final class SafetyUnavailable extends SafetyLoadOutcome { final SafetyUnavailableReason reason; const SafetyUnavailable(this.reason); }
final class SafetySnapshot {
  final ValidLocationReference location; final ReportingState state;
  final SafetyScore score; final AnnualCrimeCount latestCompleteYearCount;
  final SafetyTrend trend; final List<SafetyTrendFilter> availableFilters;
  final SafetyFreshness freshness; final SafetyCompleteness completeness;
  final SafetyProvenance provenance;
  const SafetySnapshot({required this.location, required this.state, required this.score, required this.latestCompleteYearCount, required this.trend, required this.availableFilters, required this.freshness, required this.completeness, required this.provenance});
}
enum SafetyFreshness { fresh, cached, stale }
enum SafetyCompleteness { complete, partial }
enum SafetyUnavailableReason { stateUnresolved, stateAmbiguous, sourceMissing, noValidCategory, incompleteYear, retryableUnavailable, sourceUnverifiable }
final class SafetyScore { final int value; const SafetyScore(this.value); }
final class AnnualCrimeCount { final int value; final int year; const AnnualCrimeCount(this.value, this.year); }
final class SafetyTrend { final SafetyTrendFilter filter; final List<AnnualCrimePoint> points; const SafetyTrend(this.filter, this.points); }
final class AnnualCrimePoint { final int year; final int convictedCases; const AnnualCrimePoint(this.year, this.convictedCases); }
final class ReportingState { final String stableId; final String name; const ReportingState(this.stableId, this.name); }
final class SafetyProvenance { final String source; final String modelVersion; final String boundaryVersion; const SafetyProvenance(this.source, this.modelVersion, this.boundaryVersion); }
final class SafetyComparisonRequest { final SafetyRequest a; final SafetyRequest b; const SafetyComparisonRequest(this.a, this.b); }
sealed class SafetyComparisonOutcome { const SafetyComparisonOutcome(); }
final class SafetyComparable extends SafetyComparisonOutcome { final SafetySnapshot a; final SafetySnapshot b; const SafetyComparable(this.a, this.b); }
final class SafetyIncomparable extends SafetyComparisonOutcome { final SafetyLoadOutcome a; final SafetyLoadOutcome b; final SafetyComparisonReason reason; const SafetyIncomparable(this.a, this.b, this.reason); }
enum SafetyComparisonReason { sideUnavailable, yearMismatch, completenessMismatch, provenanceMismatch }
```

| 输入约束 | 输出 / typed failures | 状态与副作用 | 顺序、权限与最小示例 |
| --- | --- | --- | --- |
| location 必为 `LOCATION-001` immutable single/A/B；all 恒可请求，类别/type 仅可请求 snapshot 宣告可用项；refresh 绕过 cache。 | available、partial、unavailable(reason) 区分州、资料、完整年度与可重试失败；A/B 为 comparable 或 incomparable(reason)，不伪造差异。 | 只读 `read_safety_inputs`，可读写无账户 `crime_public_cache`；不写地点、房产、账户、Hazard、图层/Shell。filter 只改 trend。 | 先 `GEO-001` resolved，再读取/计算，再以原引用发布；仅 opened 过程呈现。`await safety.load(SafetyRequest(location: location, policy: SafetyLoadPolicy.cacheAllowed, filter: const AllCrimeTrend()));` |

**Fake 场景：** Shell fake 消费 fresh complete、cached partial、unresolved、ambiguous、无有效类别、retryable，均不可显示为 0；Property fake 只接受同地点 complete available 且有来源/年份的 snapshot；Suitability fake 将 partial/unavailable 保持为安全维度缺失；A/B fake 证明年份/完整性/版本任一不同即不可比，交换仅改显示顺序。

### Interface 卡：`SAFETY-002` — 官方资料读取 seam（仅 B）

**提供者/消费者：** Crime & Security（B）/ Crime & Security（B）；非跨 Owner 入口。B 经 Catalog 的 `read_safety_inputs` 读取 `crime_district`，得到州、完整年、类别/type、已定罪案件或分类失败。仅可验证最新完整年度与有效类别可形成结果；网络、SDK、取消、超时、重试、cache 替换和错误映射由 B 封装。应用消费者不能 import Adapter、镜像表或原始行。

## 4. 固定业务语义、数据与流程

| 目的 | 权威来源 / 访问边界 | 必须保持的语义 |
| --- | --- | --- |
| 安全指数/案件数 | [治安事实及公式](../../knowledge_base/locatemy_product/features/crime_security.md#安全指数)；`read_safety_inputs` | resolved reporting state 后聚合 `crime_district.state` 的警区原始行；最新完整年、同年同类别实际州基准、对数/百分位/60:40。排除 Malaysia，按事实源归并联邦直辖区；district 绝不作地理解析。 |
| 趋势/筛选 | [犯罪类别与趋势](../../knowledge_base/locatemy_product/features/crime_security.md#犯罪类别) | all 为两类总和；趋势 `Y-4…Y` 可用完整年。仅一主类按既定权重重归一化并 partial；两类无效则 unavailable。 |
| 地理/比较 | `GEO-001`、[CONTEXT](../../../CONTEXT.md#行政区与统计州) | 保留 state、边界来源/版本、官方年、来源、完整性/模型版。未解析/歧义无回退；同一可解释口径才可比。 |
| 公共缓存 | `crime_public_cache`（Catalog） | key 含 reporting state、模型/边界版、资料事实；TTL 3 天；无账户字段，退出保留；cached/stale 不冒充 fresh，始终示原始官方年。 |
| Hazard 隔离 | Hazard 产品事实、`HAZARD-001`/`HAZARD-002` | 不读写报告、投票、计数、图层/状态；隐患不进指数、趋势、比较、cache、Suitability 安全维度。 |

顺序：Map 在 `FLOW-02`/`FLOW-03` 先给每角色 immutable location；Crime 调 `GEO-001`，只对 resolved state 经 `SAFETY-002` 形成 `SAFETY-001`；Shell 组合但不重算/置零。`FLOW-06` 的 Property 只消费同地点完整结果并自行写风险快照；Crime 不读写 Property。返回地图/Portfolio/Add Property 均经本契约 Shell card。

## 5. 验收、Ready Gate 与变更

| Capability / canonical AT | 情景与操作 | 可观察完成条件 |
| --- | --- | --- |
| `SAFE-01` / `AT-ANALYSIS-01` | resolved 州、两类完整资料，打开单点 | 州级 0–100、最新完整年案件、五年趋势及地点/州/年/来源/完整性/cache/口径；无警区或个人风险。 |
| `SAFE-01` / `AT-ANALYSIS-01` | 单类、两类无、空/缺年、刷新失败、cached/stale | partial、unavailable、complete-empty、retryable/non-retryable、cached/stale 可区分，永无伪 0。 |
| `SAFE-01` / `AT-LOC-01`、`AT-LOC-02` | resolved/unresolved/ambiguous、边界版改变 | 仅 resolved 读；无默认/邻近/行政区/警区回退。 |
| `SAFE-03` / `AT-ANALYSIS-01` | all、类别、type 切换 | 仅趋势变化；指数/年/总案件不变，有文字说明。 |
| `SAFE-01` / `AT-COMPARE-03` | A/B、单侧不可用、年/完整性/provenance 不同、交换 | 并列原值；仅可比时显示差异；交换不改计算。 |
| `SAFETY-001` / `AT-PROP-03`、`AT-SUIT-01` | Property/Suitability/Shell 消费，存在 Hazard | 带保存所需州/年/来源/可用性；Crime 不写房产、不出图层、不混 Hazard。 |
| 披露 / `AT-ANALYSIS-01`、`AT-COMPARE-03` | 中文/English、动态字体、图表/颜色 | 文字等价覆盖读数、趋势、筛选、状态、来源/cache/限制；说明州级而非警区/评级/个人概率。 |

- [x] `SAFE-01`、`SAFE-03` 追踪到 Owner、`SAFETY-001`、`crime_district`、`read_safety_inputs`、`crime_public_cache`、事实源和 AT。
- [x] 每个跨 Owner Interface 含唯一 import、声明/精确调用、约束、typed outcome、状态副作用、顺序/权限、最小示例和 fake。
- [x] 无实现体、SQL、SDK 映射、缓存策略或内部测试组织。
- [x] `RISK-SCHEMA-01` 的官方 schema/键、导入行数、最大完整年、五年趋势和州聚合证据留实现/集成验收；不得用 `crime_stats` 或示例宣称完成。
- [x] Standards/Spec 双轴复审通过；设计 AI 依 ADR 0013 批准 Ready。

公共 Interface 变更须由提供方说明原因和受影响消费者，所有受影响消费者确认；同一 PR 更新声明、本契约、同名 HTML 导出及受影响 fake/Adapter 测试。Git/PR 保存历史；不使用 PDF、文档版本、checksum、Manifest、Locked Source Set、Generation Gate、Development Release 或 Invalidated 生命周期。

| 日期 | 状态 | 变更原因 | 受影响对象 | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-15 | `Ready for Development` | Issue #23：改为单一 Development Contract 和同名 HTML 导出；移除旧 PDF/ADR 0014/handoff 发布流程引用，并令 `SHELL-001`、`LOCATION-001`、`GEO-001` 消费卡只指向冻结 provider 的完整 canonical declaration；不改变公式、数据模型、权限、失败或验收语义 | `SAFE-01`、`SAFE-03`、`SAFETY-001`、`SHELL-001`、`LOCATION-001`、`GEO-001`、`crime_public_cache`、同名 HTML | 设计 AI（项目负责人授权） |
