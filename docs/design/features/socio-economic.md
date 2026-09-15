# Socio-economic 开发协作契约

> 状态：`Ready for Development`（2026-09-15；设计 AI〔项目负责人授权〕，ADR 0013）
> Owner：`B`；系统基线：`Baselined — 5d11769`；依赖波次：Wave 6
> 唯一公开入口：`package:locatemy/features/socio_economic/socio_economic.dart`

本文件是 Socio-economic 唯一的跨 Owner Development Contract；同名 HTML 是由它导出的供人阅读副本，不是独立规格。它固定公开 Dart seam、受控资料读取、结果语义、权限、次序和联验；`lib/features/socio_economic/` 内的 Widget、状态管理、查询、缓存、插值、图表、并发、取消、重试与测试组织均由 B 决定。公式正文只在产品知识库，字段、RLS 与 migration 只在 Schema Catalog。

## 0. 任务成果与完成定义

**完成定义（DoD）。** B 已在唯一公开入口提供本节第 3 节完整的 `SOCIO-001` 声明；Shell 可只靠该入口的 fake 完成单点与 A/B 组合；真实 Adapter 经第 6 节情景证明：(a) 合法单点逐项显示收入中位数、收入结构、基尼、州级分布与可用的收入位置及其层级、年份、单位、来源和性质，(b) 缺失、行政区不可用、资料/权限失败与收入位置不可用均有可读恢复语义且不补零，(c) A/B 只为可比读数显示差异且没有赢家或推荐，(d) closing、换号、地点/资料/预案版本变化不发布旧结果。完成不包括 Widget、SDK、SQL 或测试实现。

## 1. 任务成果、责任与依赖顺序

用户在合法单点可看到收入中位数、收入结构、基尼、州级收入分布及可用时的家庭收入位置；每项都呈现实际层级、DOSM 年份、单位、来源及 official/reference/derived 性质。A/B 保留两端原值，只有同一口径且完整可用的单项显示差异。不会生成综合社会经济指数、推荐、CPI/购买力换算、预算预案写入或行政边界解析。

| Owner | 负责 | 不负责 | 协作 |
| --- | --- | --- | --- |
| Socio-economic（B） | `SOCIO-001`、收入/结构/基尼/分布、收入位置、层级回退、完整性、逐项可比性 | 地点合法性、Geo 解析、预案 CRUD、导航、综合评分 | 调用 Shell、Location、Geo、Cost；提供 `SOCIO-001` |
| Application Shell | opened 范围内导航、返回语境与结果组合 | Socio 资料选择、回退、完整性、可比性 | 调用 `SOCIO-001` |
| Map / Location | 合法 immutable single/A/B 引用 | 社会经济资料与解释 | 提供 `LOCATION-001` |
| Geographic Context | state/district 的 resolved/unresolved/ambiguous 事实与版本 | Socio 回退或资料读取 | 提供 `GEO-001` |
| Cost of Living & Budget | 同账户 current/no-current 的保存事实与版本 | 社会经济位置计算 | 提供 `COST-002` |

**协作顺序。** (1) 提供者已合入 Shell、Location、Geo、Cost 的声明级公共入口；(2) B 以它们的 fake 完成 Socio 并先合入本节的 `SOCIO-001` 声明；(3) Shell 以 Socio fake 组合页面；(4) 两位 Owner 用真实 Adapter 完成第 6 节的少量 joint flows。公开 seam 变化由提供者说明影响、消费者确认，并在同一 PR 更新声明、契约与受影响测试。

### 权威阅读顺序与四项 Readiness

实施和审查先确认上述结果，再按以下权威来源补充事实；后项不能改写前项：

1. [社会经济](../../knowledge_base/locatemy_product/features/socio_economic.md)、[账户](../../knowledge_base/locatemy_product/features/account.md)、[生活成本与预算](../../knowledge_base/locatemy_product/features/cost_of_living.md)；
2. [Feature map](../system/feature-map.md)、[Interface 注册表](../system/interfaces.md)、[FLOW-02](../system/flows.md#flow-02单点选址地点摘要与六类分析)、[FLOW-03](../system/flows.md#flow-03地点-ab-比较)、[FLOW-07](../system/flows.md#flow-07个人化地点适配度)；
3. [Capability Traceability](../system/capability-traceability.md)、[数据所有权](../system/data-ownership.md)、[Schema Catalog](../data/schema-catalog.md#公共政府镜像与边界对象)、[`RISK-COST-01`](../system/risks-and-decisions.md#risk-cost-01)；
4. 本契约与其同名 HTML 导出。

| Readiness | 可核查证据 | 结论 |
| --- | --- | --- |
| 责任与依赖顺序 | B 唯一拥有 `SOCIO-01`–`03`；先有 Shell、Location、Geo、Cost 的公开声明，再由 B 合入 `SOCIO-001` 声明，Shell 随后接入 | 已就绪 |
| 跨 Owner 契约 | 第 2、3 节为 `SHELL-001`、`LOCATION-001`、`GEO-001`、`COST-002` 和 `SOCIO-001` 给出唯一入口、声明、失败、顺序和 fake 场景 | 已就绪 |
| 数据与权限 | B 仅经 security-invoker `read_socio_inputs` 读取五个 DOSM 数据集；家庭收入仅从 `COST-002` 的同账户 current 快照取得 | 已就绪 |
| 联验与风险 | 第 6 节覆盖 `AT-ANALYSIS-01`、`AT-COMPARE-01/03`、`AT-SUIT-04`；`RISK-COST-01` 的两种收入分离不变 | 已就绪 |

## 2. B 需要调用的 Interface

消费者只能 import 下列唯一入口，不能 import 对方 `src/`、私有 Widget、Repository 或 SDK。

### 应用导航与组合（`SHELL-001`）

**提供者：** Application Shell；**消费者：** B
**唯一公开 import：** `package:locatemy/app/application_shell.dart`

`SHELL-001` 的**完整 canonical 声明**、所有输入约束、结果、权限、顺序与 fake 规则只在 [Application Shell 开发协作契约](../modules/application-shell.md#3-shell-必须提供的-interface) 定义；B 直接 import 该入口，绝不复制、缩窄或另造 Shell 类型。实际调用子集是同一 `ApplicationShell` 的 `submit(ShellIntent)` 与 `publish(ShellContribution)`，以及以下 canonical outcome：`ShellIntentAccepted`、`ShellAuthenticationRequired`、`ShellIntentRejected(ShellRejectionReason)`；`ShellContributionAccepted`、`ShellContributionAuthenticationRequired`、`ShellContributionRejected(ShellRejectionReason)`。`ShellRejectionReason` 仍为 `missingInput`、`staleInput`、`inapplicableDestination`、`scopeUnavailable`。

B 在自己的唯一入口完整声明 `OpenSocioEconomicIntent`、`OpenSocioEconomicComparisonIntent` 与 `SocioEconomicContribution`（见第 3 节）：前两者带 `LOCATION-001` 的 immutable single 或原序 A/B 引用及返回语境，贡献带 Socio 产出的地点、层级、年份、单位、来源、状态和可比性。仅当前同账户 `opened` 可 `submit` 或 `publish`；上述 respective accepted 才导航/组合；任一 authentication-required 保持原页或保留结果不发布；rejected 只表示导航/组合被拒绝，不能改写成资料 unavailable。Shell 仅更新导航/组合呈现，不改变地点、Geo、预案或 Socio 结论；scope 关闭即丢弃待提交意图和晚到贡献。

```dart
final outcome = await applicationShell.submit(
  OpenSocioEconomicIntent(location: location, returnContext: returnContext),
);
// 只有 ShellIntentAccepted 才开始呈现该地点的 Socio 页面。
```

**fake 场景：** fake Shell 分别返回 accepted、authenticationRequired、staleInput；验证 B 保留原地点与返回语境，拒绝不会显示为“暂无社会经济资料”，过期贡献不会覆盖新地点。

### 合法地点与行政地理（`LOCATION-001`、`GEO-001`）

**提供者：** Map / Location、Geographic Context；**消费者：** B
**唯一公开 import：** `package:locatemy/features/map_location/map_location.dart`；`package:locatemy/modules/geographic_context/geographic_context.dart`

`LOCATION-001` 的完整 canonical 声明只在 [Map / Location](map-and-location.md#location-001合法地点与收藏)，`GEO-001` 的完整 canonical 声明只在 [Geographic Context](../modules/geographic-context.md#interface-卡行政统计地理语境geo-001)。B 不复制或重塑任一类型；实际调用子集为 `LocationCoordinator.read(LocationRole)`、`GeographicContext.resolve(GeographicContextRequest)`，并使用 frozen `LocationRole`（`single`、`locationA`、`locationB`）、`LocationPresent` / `LocationAbsent`、`ValidLocationReference`、`GeographicLevel`（`district`、`reportingState`）及 Geo 的 `GeographicContextAvailable`、`GeographicContextUnavailable`、`GeographicLevelResolved`、`GeographicLevelUnresolved`、`GeographicLevelAmbiguous` 与其 canonical failure/provenance/candidates。

输入只接受 `LocationPresent`：单点用 `single`，比较用不同的 `locationA`、`locationB` 原序引用。absent、非法、范围外或同点不会触发 Socio 读取，也不会写缓存。B 对每端以原引用一次请求 `district` 与 `reportingState`；`GeographicContextAvailable` 的每层独立处理：只有 `GeographicLevelResolved` 可进入所需层级资料读取；`GeographicLevelUnresolved` 或 `GeographicLevelAmbiguous` 保留 canonical reason、provenance 或完整 candidates。州 resolved 不代表行政区 resolved：每个指标仅在所需层级 resolved 时读资料，绝不按名称、附近或默认地区猜测。调用只读且不改变 Map/Geo 状态；地点或边界版本变化使晚到结果失效。

```dart
if (locations.read(LocationRole.single) case LocationPresent(:final location)) {
  final geo = await geographicContext.resolve(GeographicContextRequest(
    location: location, levels: {GeographicLevel.district, GeographicLevel.reportingState},
  ));
  // 仅 GeographicLevelResolved 可用于对应层级的资料读取。
}
```

**fake 场景：** Location 给 absent、single、A/B 与同点；Geo 给 resolved、仅 state resolved、district unresolved、ambiguous。验证 absent 无读取；state 可成为授权的州级参考，行政区却不会伪装 resolved；交换 A/B 仅交换显示槽位。

### 当前预算预案的家庭收入（`COST-002`）

**提供者：** Cost of Living & Budget；**消费者：** B
**唯一公开 import：** `package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart`

`COST-002` 的完整 canonical 声明只在 [Cost of Living & Budget](cost-of-living-and-budget.md#cost-002预算预案与-current-变化)。B 不复制或缩窄该 entry point；实际调用子集为同一 `BudgetScenarioStore` 的 `read()`、`watch()`，以及 `BudgetScenariosAvailable`、`BudgetScenariosUnavailable`、`CurrentBudgetScenarioAvailable`、`NoCurrentBudgetScenario` 和 canonical `BudgetScenarioFailure`。不调用其 CRUD 成员。

B 只读 `CurrentBudgetScenarioAvailable.scenario.householdMonthlyIncomeRm`（`double?`，名义 RM/月）及 `version`；它是 current、已保存、同账户快照。`NoCurrentBudgetScenario`、字段为 null、`BudgetScenariosUnavailable`、未保存编辑、不同账户或旧版本，都使**收入位置**单独 unavailable，绝不将月净收入、临时输入或 RM 0 替代；公共收入/基尼/结构/分布继续独立呈现。`watch` 中仅远端保存成功的新版本可触发 B 失效/重算位置；关闭开始即丢弃旧账户快照、位置与晚到响应。B 不读写 `user_budget_scenarios`，也不公开家庭收入至公共缓存/贡献。

```dart
final scenarios = await budgetScenarioStore.read();
// 仅 CurrentBudgetScenarioAvailable 且 householdMonthlyIncomeRm != null 才可请求位置。
```

**fake 场景：** fake 依次给有家庭收入、仅月净收入、no-current、retryable、A→closing→B。验证只有已保存的同账户家庭收入参与位置；公共结果不混入该金额，旧账户位置不会进入 B。

## 3. B 必须提供的 Interface

### 社会经济分析与比较（`SOCIO-001`）

**提供者：** B；**消费者：** Application Shell
**唯一公开 import：** `package:locatemy/features/socio_economic/socio_economic.dart`

消费者只能 import 该入口，不能 import `src/`。下列是声明，不是实现、SQL、SDK 调用或公式正文。

```dart
final class SocioReturnContext { final String destination; final String? stableItemId; }
final class OpenSocioEconomicIntent extends ShellIntent {
  final ValidLocationReference location; final SocioReturnContext returnContext;
}
final class OpenSocioEconomicComparisonIntent extends ShellIntent {
  final ValidLocationReference locationA; final ValidLocationReference locationB;
  final SocioReturnContext returnContext;
}
final class SocioEconomicContribution extends ShellContribution {
  final SocioContributionTarget target; final SocioReturnContext returnContext;
  final SocioEconomicAnalysisOutcome? analysis;
  final SocioEconomicComparisonOutcome? comparison;
}
enum SocioContributionTarget { analysis, comparison }
abstract interface class SocioEconomic {
  Future<SocioEconomicAnalysisOutcome> analyse(SocioEconomicAnalysisRequest request);
  Future<SocioEconomicComparisonOutcome> compare(SocioEconomicComparisonRequest request);
}
final class SocioEconomicAnalysisRequest {
  final ValidLocationReference location; final SocioRefreshPolicy refreshPolicy;
}
final class SocioEconomicComparisonRequest {
  final ValidLocationReference locationA; final ValidLocationReference locationB;
  final SocioRefreshPolicy refreshPolicy;
}
enum SocioRefreshPolicy { cacheAllowed, refresh }
sealed class SocioEconomicAnalysisOutcome {}
final class SocioEconomicAnalysisAvailable extends SocioEconomicAnalysisOutcome { final SocioEconomicAnalysis analysis; }
final class SocioEconomicAnalysisPartial extends SocioEconomicAnalysisOutcome {
  final SocioEconomicAnalysis analysis; final List<SocioAvailabilityGap> gaps;
}
final class SocioEconomicAnalysisUnavailable extends SocioEconomicAnalysisOutcome { final SocioEconomicFailure failure; }
sealed class SocioEconomicComparisonOutcome {}
final class SocioEconomicComparisonAvailable extends SocioEconomicComparisonOutcome { final SocioEconomicComparison comparison; }
final class SocioEconomicComparisonPartial extends SocioEconomicComparisonOutcome {
  final SocioEconomicComparison comparison; final List<SocioAvailabilityGap> gaps;
}
final class SocioEconomicComparisonUnavailable extends SocioEconomicComparisonOutcome { final SocioEconomicFailure failure; }
enum SocioEconomicFailure {
  invalidLocation, sameComparisonPoint, geographicContextUnavailable, sourceUnavailable,
  permissionDenied, retryableUnavailable, scopeUnavailable, incompatibleMetadata,
}
final class SocioEconomicAnalysis { final ValidLocationReference location; final List<SocioReading> readings; }
final class SocioEconomicComparison {
  final ValidLocationReference locationA; final ValidLocationReference locationB;
  final List<SocioComparisonReading> readings;
}
final class SocioReading {
  final SocioReadingKind kind; final SocioAvailability availability;
  final SocioAvailabilityReason? availabilityReason; final SocioStatisticalLevel? statisticalLevel;
  final DateTime? sourceDate; final String? unit; final String? sourceDataset;
  final SocioProvenance? provenance; final SocioReadingValue? value;
  final int? scenarioVersion;
}
final class SocioComparisonReading {
  final SocioReadingKind kind; final SocioReading locationA; final SocioReading locationB;
  final SocioReadingValue? difference; final SocioAvailabilityReason? comparabilityReason;
}
enum SocioReadingKind { medianHouseholdIncome, incomeStructure, gini, incomeDistribution, incomePosition }
enum SocioAvailability { available, partial, unavailable }
enum SocioAvailabilityReason {
  missingYear, missingLevel, missingData, unresolvedGeography, absentScenarioIncome, incomparable,
}
enum SocioStatisticalLevel { district, reportingState }
final class SocioReadingValue { final String displayValue; }
final class SocioProvenance { final Uri sourceUri; final String sourceVersion; }
final class SocioAvailabilityGap { final SocioReadingKind kind; final SocioAvailabilityReason reason; }
```

| 调用 | 输入约束 | 成功/部分输出 | typed failure 与调用方处理 |
| --- | --- | --- | --- |
| `analyse` | 合法 immutable single；refresh 为 cacheAllowed 或显式 refresh | 每项独立的收入中位数、基尼/可用时同比、州级结构、州级 median 分布和可选收入位置；每项带地点、state/district 实际层级、DOSM `date`、单位、dataset/source、official/reference/derived、完整性与原因 | Shell 原样显示分类原因；不得把 unavailable/partial 变为 0、空或整个页面失败 |
| `compare` | 合法且不同的 A/B；Map 的原始顺序 | 两端逐项原值与元数据；仅两端均 available 且层级、年份、单位、资料集/来源、定义及完整性一致的读数含 difference | `sameComparisonPoint`、地理/资料/scope failure 分开处理；incomparable 不是 winner，保留双方值与具体属性差异 |

以上是 `SOCIO-001` 的完整公开声明：空字段只允许对应 unavailable/partial 的缺失事实，`sourceDate` 是 DOSM 原始统计日期，金额的 `unit` 为名义 RM/月，`SocioReadingValue.displayValue` 必须是可访问的原值/边界状态/文字摘要，不能以 0 代替缺失。每项读数保留 `availability`、`availabilityReason`、`statisticalLevel`、`sourceDate`、`unit`、`sourceDataset` 和 `provenance`；比较差异只属于对应读数，且只在两端均 available、层级、年份、单位、资料集/来源、定义及完整性相同才非 null。收入位置另保留 `scenarioVersion`，且从不作为地点间赢家或总体差异。

**状态、权限与次序。** B 先将 request 绑定 immutable 地点、Geo 版本与当前预案版本，再读取每端 Geo、公共资料和可选 current 快照；任一绑定值或 scope 在完成前变化，旧响应不可发布。读取只读：不写地点、边界、预案、偏好或适配度。公共缓存如建立，只含公共读数、地点/Geo 版本、资料日期和完整性；不含账户、家庭收入或 current 版本。收入/基尼行政区优先，仅该指标无行政区匹配才使用已 resolved state 的州级读数；结构、分布和位置始终是州级参考。完整性、年份、回退和可比性规则见第 4 节。

```dart
final result = await socioEconomic.analyse(SocioEconomicAnalysisRequest(
  location: location, refreshPolicy: SocioRefreshPolicy.cacheAllowed,
));
// Shell 仅组合 Socio 返回的元数据与 availability；不自行决定州级回退或比较差异。
```

**fake 场景：** fake Socio 依次返回 district available、state reference、partial percentile、absentScenarioIncome、A/B incomparable、scopeUnavailable。Shell 验证每项元数据和恢复路径可见，部分/不可比不会被渲染为总分、赢家或全页空白。

## 4. B 直接使用的数据与确定性规则

### `read_socio_inputs`：稳定公共读取对象（仅 B）

**精确对象：** Schema Catalog 的 security-invoker View/RPC `read_socio_inputs`（`proposed`）。Flutter 不直接读取五个镜像表，也不读取 `hies_district`、`hies_state`、全国 percentile 或其他退役对象。

| 读取对象 / 精确字段 | 访问与权限 | B 的使用边界 |
| --- | --- | --- |
| `hh_income_district(state, district, date, income_mean, income_median)`；`hh_income_state(state, date, income_mean, income_median)` | `read_socio_inputs` 以调用者权限只读；仅 authenticated opened 主应用可读 | `income_median` 为名义 RM/月；逐指标 district 优先，缺匹配才 state reference |
| `hh_inequality_district(state, district, date, gini)`；`hh_inequality_state(state, date, gini)` | 同上 | `gini` 原样 0–1；同比只比较同一实际层级、资料集且紧邻的 DOSM 年份 |
| `hies_state_percentile(date, state, percentile, variable, income)` | 同上 | 仅同 state/date 的 P1–P100；`mean` + `maximum(P40/P80)` 生成 B40/M40/T20，`median` 生成曲线和收入位置 |

`read_socio_inputs` 的成功或部分读取必须向本 Feature 回带上述字段、资料集、原始 `date`、资料完整性和导入批次；partial 绝不等于零或完整。B 不写数据库；客户端无 service-role。公共读取 permission/source/version failure 通过 `SOCIO-001` 的 typed outcome 返回，不能伪装为无记录。

**确定性应用规则。** 每项优先采用当前单点可共享的最新完整 DOSM 日期；无共同日期时每项取自己层级/资料集/必需字段完整的最新日期，并呈现年份不同。`missingYear` 是允许层级没有日期，`missingLevel` 是 Geo 已解析而允许层级都无记录，`missingData` 是目标层级/日期存在但必需字段空或不可读，`unresolvedGeography` 是所需层级 unresolved/ambiguous。结构要求同州同 date 全部 `mean(P1…P100)` 和 `maximum(P40/P80)`；曲线/位置要求全部 `median(P1…P100)`。缺任一所需点就是 partial，不推导受影响结构、曲线或位置。相邻真实 `median` 点之间的线性插值仅适用于收入位置；低于 P1、高于 P100 分别呈现边界状态。金额一直标注“名义 RM/月、未按通胀调整”；官方统计与州级参考/推导估算分组显示。

## 5. 推荐实施顺序

1. B 先在唯一入口提交 declaration-only `SocioEconomic`、公开请求/结果/failure/readings 模型；让 Shell 以 fake 编译与测试其组合行为。
2. 对 `LOCATION-001`/`GEO-001`/`COST-002` 建立 fake：覆盖 single/A-B、resolved/ambiguous、current/no-current/换号；先证明输入与失效边界，再接真实 provider。
3. 接 `read_socio_inputs`，验证五个 canonical 数据集的键、字段、单位、统计日期、P1–P100 完整性、security-invoker 权限与导入证据；资料或权限未就绪时保留 typed unavailable，而非 fixture。
4. 实现每项独立的层级回退、年份、partial 和 provenance；最后才组成单点/A-B 呈现贡献与收入位置。
5. 以真实 Adapter 证明其满足 `SOCIO-001`；Shell 保持 fake consumer 行为测试，双方仅增加第 6 节必要的跨模块测试。

## 6. 联调与验收情景

| 人类可读场景 | 参与 Owner | 操作 | 可观察完成条件 |
| --- | --- | --- | --- |
| 行政区优先与诚实州级回退（`AT-ANALYSIS-01`） | Map、Geo、B、Shell | 打开有 district 数据的地点；再打开只有 state 数据的地点 | 每个指标独立采用实际层级，显示年份/单位/来源；州级永远标 reference，不以邻近 district 补齐 |
| 百分位完整性与收入位置（`AT-ANALYSIS-01`、`AT-SUIT-04`） | Geo、Cost、B、Shell | 完整 median P1–P100 与 current 家庭收入，随后移除一点、移除 current、仅保留月净收入 | 完整时显示命中/插值/边界位置；其余只让位置 unavailable，公共读数保留，绝不以月净收入或 0 替代 |
| A/B 的逐项可比性与交换（`AT-COMPARE-01`、`AT-COMPARE-03`） | Map、Geo、B、Shell | 比较同口径两点，再制造层级/年份/来源/定义/完整性不同并交换 A/B | 只有兼容且 available 的同项有差异；其他保留两端原值和原因；交换不重写地点或预案，也没有赢家/推荐 |
| 关闭范围与晚到响应（`AT-ANALYSIS-01`） | Shell、Cost、B | A 的位置请求未完成时 closing，再打开 B 或变更 Geo/current 版本 | closing 起丢弃 A 的收入和晚到结果；公共读取不含私有收入，新版本才可发布 |
| 可访问的完整、部分、不可用页 | B、Shell | 在中文/English、长金额/日期、图表、估算和错误状态阅读 | 层级、年份、单位、来源、官方/估算和错误均有文字/可访问名称；图表有文字摘要，状态不只靠颜色 |

## 7. Owner 的内部实现自由

B 可在 `lib/features/socio_economic/` 内自行决定文件拆分、Widget、状态管理、查询/缓存键、Supabase SDK 映射、图表库、取消、并发、重试、Adapter 与测试组织。不得以这些内部选择改变本契约的唯一公开入口、typed outcomes、公共/私有边界、层级/年份/完整性或 A/B 可比性。Shell、Map、Geo、Cost 的内部文件与数据库 schema 均不属于 B 的实现边界。

## 8. 阻塞项与权威参考

**当前阻塞：无。** 实现开始前必须取得 `read_socio_inputs` 及 `hh_income_state`、`hh_inequality_state`、`hies_state_percentile` 的 canonical 导入、字段/键、P1–P100 覆盖和 security-invoker 权限证据；这是实现/集成验证条件，不能由设计批准或 fixture 代替。若该资料 seam、任一公开 Interface 或家庭收入语义改变，停止受影响工作并由相关 Owner 在同一 PR 更新契约、声明、HTML 与测试。

权威参考：[社会经济产品事实](../../knowledge_base/locatemy_product/features/socio_economic.md)、[账户事实](../../knowledge_base/locatemy_product/features/account.md)、[Cost 公开契约](cost-of-living-and-budget.md)、[Schema Catalog](../data/schema-catalog.md)、[流程](../system/flows.md)、[Capability Traceability](../system/capability-traceability.md)、[数据所有权](../system/data-ownership.md)、[风险与决定](../system/risks-and-decisions.md)、[ADR 0011](../../adr/0011-human-coded-ai-designed-delivery-process.md)、[ADR 0012](../../adr/0012-high-level-design-coordination-boundaries.md)、[ADR 0013](../../adr/0013-autonomous-design-ai-ready-approval.md)。

## 9. Change Log 与完成核对

| 日期 | 状态 | 变更原因 | 受影响对象 | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Ready for Development` | 固定 Socio 范围、产品口径、资料边界与联验 | `SOCIO-01`–`SOCIO-03`、`SOCIO-001` | 项目负责人 |
| 2026-09-15 | `Ready for Development` | Issue #23 返工为单一 Development Contract：首屏可观察 DoD；改为引用 Application Shell、Map / Location、Geographic Context、Cost 的完整 canonical 声明并只说明 Socio 实际调用子集；消除旧 publish outcome 变体，移除 PDF、ADR 0014 与 handoff 发布治理 | `SOCIO-001`、`SHELL-001`、`LOCATION-001`、`GEO-001`、`COST-002`、同名 HTML | 设计 AI〔项目负责人授权〕，ADR 0013 |

- [x] 首屏给出任务成果、Owner、依赖和可观察 DoD。
- [x] 每个跨 Owner seam 都有 frozen 的唯一公开入口；上游完整声明仍由其 Owner 唯一拥有，本 Feature 仅列实际调用子集。
- [x] `SOCIO-001` 声明、数据/权限边界、地区统计、家庭收入位置和 A/B 可比性均可追溯到事实源与验收情景。
- [x] 同名 HTML 与本 Markdown 语义等价，且没有 PDF、ADR 0014 或 handoff 发布治理。
