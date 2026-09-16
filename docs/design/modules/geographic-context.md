# Geographic Context 开发协作契约

> 状态：`Ready for Development`（2026-09-15；设计 AI〔项目负责人授权〕，ADR 0013）
> 实现：`Implemented`（2026-09-16；本期证据与后续联合项见第 5.1 节）
> Owner：`B`；系统基线：`Baselined — 5d11769`；依赖波次：Wave 1
> 唯一公开入口：`package:locatemy/modules/geographic_context/geographic_context.dart`
> 定义完成：四个消费者可只经一个 Dart seam，以同一合法地点取得逐层、可追溯且不猜测的行政区/统计州事实；fake 与生产 Adapter 的结果语义相同。

本文件是 Geographic Context 唯一的跨 Owner 开发协作契约，也是同名 HTML 的权威 Markdown 源。它冻结公开 Dart 声明、资料读取、顺序和联合验收；`lib/modules/geographic_context/` 内的文件、空间库、缓存、Supabase SDK 映射、并发/取消/重试及测试组织由 B 决定。不得以本文件规定函数体、私有实现、迁移或测试实现。

## 0. 固定阅读顺序与四项 Readiness

1. [领域词汇](../../../CONTEXT.md#行政地理语境)及下游[生活成本](../../knowledge_base/locatemy_product/features/cost_of_living.md)、[治安](../../knowledge_base/locatemy_product/features/crime_security.md)、[社会经济](../../knowledge_base/locatemy_product/features/socio_economic.md)、[基础设施](../../knowledge_base/locatemy_product/features/infrastructure.md)事实；
2. [Feature map](../system/feature-map.md#fm-geo)、[Interface 注册表](../system/interfaces.md)、[FLOW-02](../system/flows.md#flow-02单点选址地点摘要与六类分析)及[FLOW-03](../system/flows.md#flow-03地点-ab-比较)；
3. [数据所有权](../system/data-ownership.md#公共资料镜像与缓存)、[Schema Catalog](../data/schema-catalog.md#稳定公共读取对象)、[`RISK-GEO-02`](../system/risks-and-decisions.md#risk-geo-02-资料决定与未关闭证据)；
4. 本契约与同名 HTML 导出。

| Readiness | 可核查证据 | 结论 |
| --- | --- | --- |
| 责任与依赖顺序 | `GEO-001` 唯一归 B；消费者为 Cost、Crime、Socio-economic、Infrastructure；输入先由 `LOCATION-001` 产生 | 已就绪 |
| 跨 Owner 契约 | 第 3 节的唯一入口、声明、输入、typed 结果/失败、顺序、权限、示例和 fake 场景 | 已就绪 |
| 数据与权限 | B 唯一经 authenticated-only RPC 读取边界；消费者只见公开地理类型，不见表/RPC 或账户资料 | 已就绪 |
| 联验与风险 | 第 5 节覆盖单点/A-B、零/多候选、版本及四个消费者；`RISK-GEO-02` 已关闭 | 已就绪 |

## 1. 任务成果、责任与协作顺序

- 对 `LOCATION-001` 已验证的不可变坐标，逐个请求层级返回 `resolved`、`unresolved` 或 `ambiguous`，并回带同一读取批次的来源与版本事实。
- 行政区用于收入、供水、供电、医疗、教育等地区统计；统计州只供 Crime 按 `crime_district.state` 聚合。Geo 不解析警区，也不决定任一 Feature 的统计回退。
- 一个层级成功不代表另一层级成功；零覆盖、边界点、重叠、资料不可读或版本不可验证时，不以最近、默认、名称或相邻地区替代。

| Owner / 受控边界 | 负责 | 不负责 | 协作 |
| --- | --- | --- | --- |
| Geographic Context（B） | `GEO-001`、边界候选分类、逐层事实与 provenance、公开无账户缓存 | 地点合法性/选点、资料导入迁移、指标读取/回退、地图和导航 | 消费 `LOCATION-001` 的公开类型；提供唯一入口 |
| Map / Location | 合法 immutable `ValidLocationReference` | 统计州/行政区解析 | 先提供地点；Geo 不读可变地图状态 |
| Cost / Crime / Socio / Infrastructure | 各自资料、缺失、回退与用户文案 | 空间匹配或猜测地区 | 仅 import `GEO-001`；按层级结果决定是否读自身资料 |

**协作顺序。** (1) Map 已合入 `LOCATION-001` 声明；(2) B 先合入本节唯一公开入口、声明和最小 fake；(3) 四个消费者以该 fake 并行实现，绝不 import B 的 `src/`；(4) B 接真实 `GEO-002` Adapter；(5) 只保留第 5 节必要的 joint flows。公开 seam 变化须由 B 说明影响、所有受影响消费者确认，并在同一 PR 更新声明、契约、HTML 和受影响测试。

## 2. B 需要调用的 Interface 与读取对象

### Interface 卡：合法地点（`LOCATION-001`）

**提供者：** Map / Location；**消费者：** B；**唯一 import：** `package:locatemy/features/map_location/map_location.dart`。

Geo 只接受该 Interface 已成功产生的 `ValidLocationReference`；`locationId` 非空，`point.latitude`/`point.longitude` 为有限 WGS84 数，且已通过 Malaysia 范围校验。`displayName` 可为 null，绝不参与解析或缓存键。absence、非法坐标、范围外和 A/B 同点均由 Map 拒绝，B 不重验为另一种地点、更不读取边界。Geo 的解析只读，不改 Map 的任何角色或地点状态。

**最小使用：** `GeographicContextRequest(location: selectedLocation, levels: {GeographicLevel.district})`，其中 `selectedLocation` 必为 Map 成功结果。**fake 场景：** fake Map 给合法单点、合法 A/B 与 absence；只有合法引用进入 Geo，A/B 的原始引用和角色归消费者保持，不被 Geo 替换。

### Interface 卡：版本化边界候选读取（`GEO-002`，仅 B）

**提供者 / 消费者：** `read_administrative_boundary_candidates` / Geographic Context（B）。这是 B 的外部来源 seam，不是其他 Owner 的 Dart import；生产与 B 的固定样本 Adapter 必须满足相同候选事实。

| 精确调用 / 行形状 | 输入、结果与 failure | 权限、副作用与顺序 |
| --- | --- | --- |
| authenticated-only `security definer` RPC：`read_administrative_boundary_candidates(latitude double precision, longitude double precision)`；每行严格为 `boundary_id`, `state`, `district`, `source_dataset`, `source_url`, `source_version`, `source_sha256`, `geometry_transform`, `derived_geometry_sha256`, `imported_at timestamptz`。 | 两个输入均为有限 WGS84 值，latitude `[-90, 90]`、longitude `[-180, 180]`。零行是 `noCoverage`，一/多行是完整候选；RPC/认证不可用为 `sourceUnavailable`/`scopeUnavailable`，缺少任一 provenance 字段为 `versionUnverifiable`。这些不是空列表成功。 | 仅 authenticated 账户可 execute；anon 和客户端对两张底表均无读权。B 不写 RPC、边界、导入审计、Map 或下游结果。只能在取得合法地点后调用；同一响应的所有候选必须原样保留并按 `boundary_id` 稳定处理。 |

资料对象、字段权限和 migration 唯一权威为 [Schema Catalog](../data/schema-catalog.md#稳定公共读取对象)；固定资料、hash、离岛和重叠证据为 [`RISK-GEO-02`](../system/risks-and-decisions.md#risk-geo-02-资料决定与未关闭证据)。

## 3. B 必须提供的 Interface

### Interface 卡：行政统计地理语境（`GEO-001`）

**提供者：** Geographic Context（B）；**消费者：** Cost、Crime、Socio-economic、Infrastructure。
**唯一公开 import：** `package:locatemy/modules/geographic_context/geographic_context.dart`

消费者只能 import 此入口，不得 import `lib/modules/geographic_context/src/`、B 的 Adapter 或 Supabase SDK。B 应先合入下列**声明**与最小 fake；它们是跨 Owner 形状，而不是函数体。

```dart
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

`GeographicContextAvailable.results` 的键**恰好**等于 request 的 `levels`；map 和 `candidates` 均为不可变快照。`levels` 必须非空且仅含 enum 值。所有 ID、名称和 provenance 字符串非空；`sourceUri` 必为绝对 URI；`importedAt` 为 UTC。`BoundaryProvenance?` 仅可在来源不可读/不可验证时为 null；它不允许以 `DateTime.now()` 或缓存读取时间代替资料版本。`AdministrativeArea(level: district)` 的 reporting-state 字段描述其所属统计州；`AdministrativeArea(level: reportingState)` 的 `stableId` 必等于 `reportingStateId`，`name` 必等于 `reportingStateName`。

#### 输入、结果、失败与调用者处理

| 条件 / 结果 | 精确意义 | 消费者必须处理 |
| --- | --- | --- |
| 请求 | `location` 是 `LOCATION-001` 成功的 immutable 合法引用；levels 为 non-empty set。Cost/Socio/Infrastructure 请求 `district` 与 `reportingState`；Crime 只请求 `reportingState`。 | 不自行构造坐标，不读 Map 可变状态；无地点/非法地点不调用 Geo。 |
| `GeographicContextAvailable` | 请求的每个层级都有一个独立结果：resolved、unresolved 或 ambiguous；这不是“所有层级 resolved”的同义词。 | 只将自己所需层级的 `GeographicLevelResolved` 用于资料读取；另一层级不成功仍如实呈现。 |
| `GeographicLevelResolved` | 恰一完整候选；area 和 provenance 是该批次事实。 | Cost/Infrastructure 用 district；Crime 用 reporting state 聚合原始警区；Socio 依其事实源自行决定州级回退。 |
| `GeographicLevelUnresolved` | `noCoverage`、`sourceUnavailable`、`versionUnverifiable` 或 `scopeUnavailable`；provenance 为已知则回带，未知则 null。 | 呈现/传播具体不可用原因；绝不补 0、最近、默认、名称或邻近地区。 |
| `GeographicLevelAmbiguous` | 两个或更多完整候选（含边界点或资料重叠），不含任选答案。 | 将该层级视为不可用于自身资料；完整 candidates 用于可解释性，不选首项。 |
| `GeographicContextUnavailable` | 请求无法产生可信的逐层结果；failure 与可知 provenance 描述整次读取。 | 将所有请求层级视为不可用；不把它折叠成 `noCoverage` 或空成功。 |

预期资料/权限故障一律用上述 typed result，消费者不得解析异常文字；编程错误不属于资料结果契约。B 不提供 `resolveState` 等第二公开入口，消费者一律调用 `resolve`。

#### 状态、副作用、权限与生命周期

- 这是公共只读 Interface：不读/写账户、收藏名、Map 状态、消费者结果或远端边界资料。可维护无账户公共缓存，但缓存值及键不得含 account id、收藏名或私有 payload；退出可保留。
- 调用只允许已 opened 主应用路径。Geo 本身不打开/关闭账户 scope；`scopeUnavailable` 说明认证/RPC 权限无法安全满足，绝不降级为匿名表读。
- 同一 location 坐标、levels 和 `BoundaryProvenance` 必有确定性逐层结果。版本不同的结果不宣称可比；地点、请求层级或版本在请求期间改变时，消费者丢弃晚到结果，不覆盖新地点/A-B 端。
- 先由 Map 成功产生 immutable 地点，再调用一次 `resolve`，再仅用 resolved 层级读自己的资料。公开 Interface 不承诺缓存、网络、并发、取消、超时或重试策略。

#### 最小调用示例（Crime）

```dart
final outcome = await geographicContext.resolve(GeographicContextRequest(
  location: selectedLocation, levels: {GeographicLevel.reportingState},
));
switch (outcome) {
  case GeographicContextAvailable(:final results):
    final state = results[GeographicLevel.reportingState];
    // 仅 GeographicLevelResolved 可进入 Crime 的州级资料读取。
  case GeographicContextUnavailable(:final failure):
    // 显示 failure 的不可用/恢复路径；不猜测州。
}
```

这是 seam 用法说明，不是可提交的 Crime 实现。

#### Fake Adapter 场景

消费者用 fake `GeographicContext` 实现相同 `resolve` 声明：(a) 两个 resolved：Cost/Socio/Infrastructure 只将 district 用于地区资料、Crime 只用 reporting state；(b) state resolved + district `GeographicLevelUnresolved(noCoverage)`：Socio 仅按自己的事实源显示州级参考，其他消费者不伪造 district；(c) `GeographicLevelAmbiguous`（完整候选）或 `GeographicContextUnavailable(scopeUnavailable)`：不读下游资料、不选候选、不显示零；(d) 同坐标不同 `sourceVersion`：不称可比，晚到旧版不覆盖当前。fake 不需要 Supabase、空间库或 B 的生产 Adapter；B 的真实 Adapter 须证明满足同一 Interface。

## 4. 直接资料与确定性口径

| 目的 | 权威对象 / 访问 | 不能改变的语义 |
| --- | --- | --- |
| 行政统计解析 | `administrative_district_boundaries` 和 `government_dataset_imports`，仅经 `GEO-002` RPC | 160 个 DOSM `administrative_2_district` 边界的 source/version/hash 随结果；Flutter 不直读底表。 |
| 州级治安 | [治安事实](../../knowledge_base/locatemy_product/features/crime_security.md#计算范围) | Geo 只给 reporting state；Crime 自行按 `crime_district.state` 聚合，绝不解析警区。 |
| 行政区和州资料 | [Cost](../../knowledge_base/locatemy_product/features/cost_of_living.md)、[Socio](../../knowledge_base/locatemy_product/features/socio_economic.md#已确认的产品口径)、[Infrastructure](../../knowledge_base/locatemy_product/features/infrastructure.md) | Geo 不决定指标缺失、层级回退、可比性文案或任何数值。 |

`ST_Covers` 使边界点成为所有覆盖边界的候选；候选数为零/一/多分别映射为 unresolved/resolved/ambiguous。对于 reporting state，B 从完整 district candidates 派生州候选：不同 state id 多个即 ambiguous；恰一个才 resolved；不能由候选的第一项或 district 名称猜测。该派生规则仅分类已经返回的候选，不改变资料、边界或下游事实。

## 5. 联调与验收情景

| 场景 | 参与 Owner | 操作 | 可观察结果 |
| --- | --- | --- | --- |
| 单一行政区 | B、Cost、Crime、Socio、Infrastructure | 对合法地点请求各自层级 | 同一 provenance 下返回同一州/行政区事实；只有对应 resolved 层级进入各自资料读取。 |
| 州成功、行政区零覆盖 | B、Socio、Cost、Infrastructure | fake/真实样本返回 state resolved、district `noCoverage` | Socio 仅按其事实源可给州级参考；Cost/Infrastructure 不猜测 district 或补零。 |
| 边界点/重叠 | B、四个消费者 | 返回完整多候选 | 该层级是 ambiguous；没有消费者任选候选或产生伪解析。 |
| RPC 权限或来源不可用 | B、四个消费者 | 未 opened、认证/RPC 拒绝、provenance 不完整 | `scopeUnavailable`、`sourceUnavailable` 或 `versionUnverifiable` 可区分；不伪装为空资料。 |
| A/B 与版本变化 | B、消费者 | 同点并行、不同地点或不同版本的晚到响应 | 同 location/版本一致；不同版本不可比，旧地点/旧版本不覆盖当前端。 |

追踪：`D09`、`D13`、`D23`、`D27`；`AT-ANALYSIS-01`、`AT-COMPARE-01`、`AT-COMPARE-03`。

### 5.1 Wave 1 验收分配（2026-09-16）

实现门槛依 [开发与完成判定规范](../development-standard.md) 第 3 节。
设计 Ready 与实现状态分别记录；本模块无页面，通过 `GEO-001.resolve` 验证。
本期真实依赖为 Supabase Auth 和 `GEO-002`；`LOCATION-001` 使用已合入公开类型的合法固定样本，
Map 的真实选点及四个消费者属于后续 Wave 槽位。测试 HTTP Adapter 只提供确定性错误、边界和并发证据，
不能替代真实开发环境调用。设备 harness 只访问公共地理资料，先验证真实确认会话；
不创建私有 Feature、缓存或队列。Privacy/Shell 的真实 `opened` 门控仍由 A 在 Wave 3 接入验证。

| 场景 ID / 可观察结果 | 验证归属 | 所需依赖及用途 | 证据要求 | 负责 Owner | 最迟 Wave | 本模块证据/状态 | 联合证据/状态 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| GEO-W1-01 单一行政区：请求键恰好一致、地区/州和同批来源正确、结果不可变 | 两者 | 本期真实 Auth/RPC；测试合法 LOCATION 固定样本；后续四个消费者 | 公开入口 Adapter 测试、真实 RPC、A 真机/B 模拟器；消费者仅用 resolved 读指标 | B；联合 Cost 主责 B、Crime 主责 A，B 参与；Socio/Infrastructure 主责 B | 本模块 1；Cost/Crime 5；Socio/Infrastructure 6 | 已通过；见 Wave 1 报告 GEO-W1-01 | 待接入，Wave 5/6 |
| GEO-W1-02 州成功、行政区 noCoverage：逐层模型保留部分成功 | 两者 | 测试公开 seam 的可表达结果；真实 RPC 无 district 候选时两层均 noCoverage；后续 Socio/Cost/Infrastructure fake 与真实消费 | 模型不折叠部分结果；同州多区真实分类保留州成功；消费者验证自身回退/不补零 | B；Cost/Infrastructure/Socio 主责 B | 本模块 1；Cost 5；Socio/Infrastructure 6 | 已通过；见 GEO-W1-02；state resolved + district noCoverage 是 seam fake 场景，不声称真实 RPC 可产生该组合 | 待接入，Wave 5/6 |
| GEO-W1-03 边界/重叠：完整 district 多候选，state 去重分类且稳定 | 两者 | 本期真实 RPC 边界点/离岛；HTTP 多州及重复州候选；后续消费者 | 完整候选、无任选答案、稳定 boundary_id 顺序和不可变列表；消费者 ambiguous 不读指标 | B；Cost 主责 B、Crime 主责 A；Socio/Infrastructure 主责 B | 本模块 1；Cost/Crime 5；Socio/Infrastructure 6 | 已通过；见 GEO-W1-03 | 待接入，Wave 5/6 |
| GEO-W1-04 来源/权限/版本故障、离线与恢复：四种失败可区分 | 两者 | 本期真实 Auth/RPC/底表权限；HTTP 故障/缺字段/错类型/混批；后续 Shell/Privacy 和消费者 | 未确认/匿名/无会话不调用 RPC；真实 anon RPC deny、底表客户端读写 deny；每行 provenance 校验；离线 sourceUnavailable；重试恢复 | B；opened 门控主责 A，B 参与；指标消费按各 owning contract | 本模块 1；门控 3；Cost/Crime 5；Socio/Infrastructure 6 | 已通过；见 GEO-W1-04 | 待接入，Wave 3/5/6 |
| GEO-W1-05 A/B、请求和版本变化：每次响应保留自身输入和来源，不缓存旧结果；退出后晚到响应拒绝 | 两者 | HTTP 延迟/并行/新版本；真实退出重登；后续 Map/A-B 与消费者 | 调用开始固定 levels；并行地点/同点结果相互独立；每次读当前批次；已失效会话不发布成功；消费方丢弃旧端/旧版本 | B；Map/A-B 主责 A，B 参与；各消费者主责同上 | 本模块 1；Map 4；Cost/Crime 5；Socio/Infrastructure 6 | 已通过；见 GEO-W1-05 | 待接入，Wave 4/5/6 |
| GEO-W1-06 工程门槛与无页面设备入口 | 本模块 | 全仓格式、分析、测试、debug APK；真实设备/模拟器公开入口 harness | 命令、环境、版本及成功/失败/重启证据；APK 不含高权限密钥 | B；A 提供真机目标 | 1 | 已通过；见 GEO-W1-06 | 不适用 |

上述“已通过”以 [Wave 1 实现验收报告](../../human/geographic-context-wave1-acceptance-2026-09-16.md)
中的最终验证证据为准。Wave 1 没有到期的跨模块联合场景；以后到期项不可用本期 HTTP/fixed-location
证据代替真实模块联验。`Integrated` 仍由项目负责人批准。

## 6. 实现自由、阻塞项与完成检查

B 可决定内部 Adapter、缓存、空间匹配库、状态管理、并发/取消/重试及真实/fake 测试组织。以下情况必须暂停协商：变更唯一公开入口、任何公开声明/失败/顺序/权限，修改 RPC 行形状或 authenticated-only 例外，或资料版本使 `RISK-GEO-02` 结论失效。

设计阻塞项：无。实现验收状态与证据见第 5.1 节及 Wave 1 报告。边界资料、导入审计、固定空间样本和权限证据已关闭 `RISK-GEO-02`；来源/依赖版本变化时重新打开。

- [x] 四项 Readiness 在第 0 节均有可核查证据，Owner 始终为 `B`。
- [x] `GEO-001` 有一个公开 entry point、声明、精确输入/nullability/约束、typed 结果/失败、状态/权限/顺序、最小调用与 fake 场景。
- [x] `GEO-002` 有精确 RPC/行形状和 B 专属权限边界；未向消费者泄漏 persistence seam。
- [x] 本文只含 declaration-level Dart 与协作验收，不含函数体、私有实现、migration 或测试实现。

## 7. Change Log

| 日期 | 状态 | 变更原因 | 影响 | 批准者 |
| --- | --- | --- | --- |
| 2026-09-14 | `Ready for Development` | 固定边界资料、导入、空间验证及 authenticated-only 例外 | `GEO-001`、`GEO-002`、四个消费者 | 项目负责人 |
| 2026-09-15 | `Ready for Development` | Issue #23 将 owning design 返工为单一开发协作契约；冻结唯一公开 Dart seam 与 fakeable 结果模型 | `GEO-001`、`GEO-002`、Cost、Crime、Socio、Infrastructure | 设计 AI〔项目负责人授权〕，ADR 0013 |
| 2026-09-16 | `Ready for Development`；实现验收见第 5.1 节 | 按 Wave 开发规范补齐当期验收分配及后续联合 Owner/期限；不改变公开声明、产品范围或数据模型 | Wave 1 Geographic Context、后续 Wave 3–6 门控/地点/四个消费者 | 实现 AI〔当前任务授权〕 |
