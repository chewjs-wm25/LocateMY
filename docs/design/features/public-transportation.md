# Public Transportation 开发协作契约

> 状态：`Ready for Development`（2026-09-15；设计 AI〔项目负责人授权〕，ADR 0013）
> Owner：`A`；系统基线：`Baselined — 5d11769`；依赖波次：Wave 5
> 唯一公开入口：`package:locatemy/features/public_transportation/public_transportation.dart`
> 定义完成：消费者可只凭本契约，以不可变合法地点和明确分析日期取得、呈现或复用同一份交通连通性事实；不会把资料不完整、无服务或旧资料伪装为零分。

本文件是 Public Transportation 唯一的跨 Owner Development Contract；同名 HTML 是由本 Markdown 导出的等价人类阅读格式。它固定公开 Dart seam、GTFS 结果语义、局部地图协作和联合验收；`lib/features/public_transportation/` 内的 Widget、GTFS/Supabase Adapter、状态管理、缓存、并发/取消/重试、排序和测试组织由 A 决定。公式正文只在产品知识库，表/RLS/migration 只在 Schema Catalog。

## 0. 固定阅读顺序与四项 Readiness

1. [领域词汇](../../../CONTEXT.md#公共交通覆盖)、[公共交通产品事实](../../knowledge_base/locatemy_product/features/transportation.md)与[ICI 公共交通规则](../../knowledge_base/locatemy_product/infrastructure_index_scoring.md#公共交通)；
2. [Feature map（Transit）](../system/feature-map.md#fm-transit)、[Interface 注册表](../system/interfaces.md)、[FLOW-02](../system/flows.md#flow-02单点选址地点摘要与六类分析)与[FLOW-03](../system/flows.md#flow-03地点-ab-比较)；
3. [Capability Traceability](../system/capability-traceability.md)、[数据所有权](../system/data-ownership.md)、[Schema Catalog](../data/schema-catalog.md#标准化-gtfs-对象)与[`RISK-TRANSIT-01`](../system/risks-and-decisions.md#风险与关闭条件)；
4. 本契约及同名 HTML 导出。

| Readiness | 可核查证据 | 结论 |
| --- | --- | --- |
| 责任与依赖顺序 | `TRANSIT-01`–`03` 唯一归 A；`D16` 的 Shell 和 `D17` 的 Map 已先 Ready；`D28`/`D45` 的同一结果复用已指定消费者 | 已就绪 |
| 跨 Owner Interface | 第 2、3 节完整列出 `SHELL-001`、`LOCATION-001`、`LOCATION-002`、`TRANSIT-001` 的公开入口、声明、typed outcome、次序、权限与 fake | 已就绪 |
| 数据与权限 | A 是 `read_transit_analysis` 唯一直接消费者；GTFS 对象 authenticated read-only，Flutter 不直读表/ZIP；无账户私有资料或本地队列 | 已就绪 |
| 联合验收与风险 | 第 5 节覆盖 `AT-ANALYSIS-01`、`AT-COMPARE-03`、`AT-RACE-01`；状态矩阵已由 `RISK-TRANSIT-01` 固定，运行时导入证据留实现/集成 | 已就绪 |

## 1. 成果、责任与冻结边界

- 用户可查看合法地点 1,500 m 圆内的完整站点数、最近距离、分析日期有效路线数、连通性分、来源、采集/生成日期、可用性和资料限制；首屏按距离升序列 30 个站点，但统计和分数使用全部范围内站点。
- 单点和 A/B 结果均绑定 Map 的不可变地点引用与请求的 `analysisDate`。只有半径、分析日期、GTFS snapshot/参照网格、完整性和 provenance 相同才可比较；不产生赢家或通勤建议。
- 当前页面的局部站点分布图仅显示分析中心、固定圆和当前结果的 Marker；列表/Marker 互选只改变 `STATE-TRANSIT-SELECTION`，不移动全局选点、主地图中心或启动导航。
- 不包含 GTFS ZIP 自动下载/导入、路线导航、票价、班次、真实步行路线、服务质量、ICI 汇总和适配度公式。粗略步行分钟只是展示提示，不进入分数。

| Owner / 受控边界 | 负责 | 不负责 | 协作 |
| --- | --- | --- | --- |
| `lib/features/public_transportation/`（A） | 标准化 GTFS 读取、1.5 km 口径、可用性/服务结果、`TRANSIT-001`、局部选择/分布图 | ZIP 导入、全局地点、Shell 路由、ICI/适配度汇总 | 调用 `SHELL-001`、`LOCATION-001`、`LOCATION-002`；提供 `TRANSIT-001` |
| Application Shell | opened 主应用的分析/比较导航、返回语境、渐进组合 | GTFS 查询、状态矩阵、可比性/分数判断 | 接收 Transit intent/contribution；消费 `TRANSIT-001` |
| Map / Location | 合法 immutable single/A/B 引用、局部图层宿主 | GTFS、站点解释、选择状态、交通可用性 | 提供 `LOCATION-001`/`002` |
| Infrastructure / Suitability | 复用交通 canonical result 作 ICI/交通维度输入 | 重查 GTFS、重算百分位或另造交通分数 | 消费 `TRANSIT-001` |

## 2. 需要调用的 Interface

### Interface 卡：`SHELL-001` — 导航、返回与摘要组合

**提供者：** Application Shell；**消费者：** Public Transportation；**唯一公开 import：** `package:locatemy/app/application_shell.dart`。

```dart
abstract interface class ApplicationShell {
  Future<ShellIntentOutcome> submit(ShellIntent intent);
  Future<ShellContributionOutcome> publish(ShellContribution contribution);
}
abstract interface class ShellIntent {}
abstract interface class ShellContribution {}
sealed class ShellIntentOutcome {}
final class ShellIntentAccepted extends ShellIntentOutcome {}
final class ShellAuthenticationRequired extends ShellIntentOutcome {}
final class ShellIntentRejected extends ShellIntentOutcome {
  const ShellIntentRejected(this.reason);
  final ShellRejectionReason reason;
}
sealed class ShellContributionOutcome {}
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

Transit 从自己的唯一公开入口导出供 Shell 接收的 marker payload：`ReturnToMapIntent`（当前 immutable location 与 `AnalysisReturnContext`）及 `PublicTransportationContribution`（第 3 节的 `TransitLoadOutcome`、地点角色和原返回语境）。intent/贡献不得携带可变地图状态、GTFS 原始行、账户资料或其他 Feature payload。

| 输入约束 | 输出 / typed failures | 状态、副作用、次序与权限 |
| --- | --- | --- |
| `submit` 的 location 必为本次结果的 `ValidLocationReference`，并保留原返回语境；`publish` 只提交同一请求的 typed outcome 和完整元数据。 | accepted、authentication required、rejected(reason)；拒绝是导航/组合结果，不是交通 unavailable。 | 仅同账户 opened 主应用可调用。Shell 只更新导航/组合，不改地点、站点选择、GTFS 或分数。Transit 仅对当前地点/date/result publication；过期、换地点或关闭 scope 的结果不可发布。 |

最小调用：`await shell.publish(PublicTransportationContribution(outcome, returnContext));`。非 accepted 时保留本页结果并呈现可读恢复路径。

**Fake 场景：** fake Shell 依次返回 accepted、authentication required、stale input；Transit 验证只发布匹配请求的结果，后两者不把资料改为失败或把旧结果放入新槽位。无需 Shell 生产路由。

### Interface 卡：`LOCATION-001` — 不可变合法地点

**提供者：** Map / Location；**消费者：** Public Transportation；**唯一公开 import：** `package:locatemy/features/map_location/map_location.dart`。

以下为 Map owning contract 的**完整 canonical 声明**；Transit 只使用本 Feature 所需成员，但不得截断、复制或改形。

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
```

Transit 只接受 Map owning contract 已产生的 `ValidLocationReference`（single 或明确的 A/B 角色）。它不自行构造坐标、不回读可变地图状态、不用默认城市、收藏名或旧地点替代。`LocationAbsent`、`invalidCoordinate`、`outsideMalaysia`、`sameComparisonPoint` 或 `scopeUnavailable` 时，不读 GTFS、不显示 no-service、不发布 contribution。调用本身无副作用；异步结果必须仍匹配原 location id、角色、analysis date 与结果 provenance。

最小调用：`TransitRequest(location: selectedLocation, analysisDate: analysisDate, policy: TransitLoadPolicy.cacheAllowed)`，其中 `selectedLocation` 只能是 Map 成功返回的值。

**Fake 场景：** fake Map 给 single、A/B、缺端及 scope unavailable；Transit 仅对成功 immutable reference 请求，拒绝时无读取/Marker/0 分。

### Interface 卡：`LOCATION-002` — 局部站点分布图

**提供者：** Map / Location；**消费者：** Public Transportation；**唯一公开 import：** `package:locatemy/features/map_location/map_location.dart`。

以下为 Map owning contract 的**完整 canonical 声明**；Transit 只调用 `contribute`，但生产 Adapter、消费者和 fake 必须保留同一入口、成员与 result variant。

```dart
abstract interface class MapLayerHost {
  Future<MapLayerContributionOutcome> contribute(MapLayerContribution contribution);
  Future<MapLayerIntentOutcome> requestLongPress(GeographicPoint point);
}
final class MapLayerContribution {
  final String providerId; final String layerId; final String viewportVersion;
  final MapLayerVisibility visibility; final List<MapLayerItem> items;
}
enum MapLayerVisibility { visible, hidden }
final class MapLayerItem {
  final String stableItemId; final GeographicPoint point; final MapLayerIntent intent;
}
sealed class MapLayerIntent {}
final class ProviderDefinedIntent extends MapLayerIntent {
  final String providerId; final String action; final String stableItemId;
}
final class CreateHazardIntent extends MapLayerIntent { final ValidLocationReference location; }
sealed class MapLayerContributionOutcome {}
final class MapLayerAccepted extends MapLayerContributionOutcome {}
final class MapLayerHidden extends MapLayerContributionOutcome {}
final class MapLayerRejected extends MapLayerContributionOutcome { final MapLayerFailure failure; }
sealed class MapLayerIntentOutcome {}
final class MapLayerIntentAccepted extends MapLayerIntentOutcome { final MapLayerIntent intent; }
final class MapLayerIntentRejected extends MapLayerIntentOutcome { final MapLayerFailure failure; }
enum MapLayerFailure { invalidContribution, invalidCoordinate, outsideMalaysia, scopeUnavailable, staleViewport, unauthenticated }
```

Transit 使用 Map contract 定义的 `MapLayerContribution`、`MapLayerItem`、`ProviderDefinedIntent`、`MapLayerAccepted`、`MapLayerHidden`、`MapLayerRejected(MapLayerFailure)`。贡献固定为 `providerId: 'public-transportation'`，stable marker id 为 `feedId + ':' + stopId`，并包含当前 request 的 `viewportVersion`、分析中心、1.5 km 圆、当前结果的全部 station Marker 与可选已选站点意图。`hidden` 是接受但不显示；`invalidContribution`、`invalidCoordinate`、`outsideMalaysia`、`scopeUnavailable`、`staleViewport`、`unauthenticated` 为可区分失败。

图层只改 Map 覆盖物/相机，Map 点击只回传原 `feedId + stopId` 意图；Transit 负责将它解析为当前结果中的站点或拒绝过期选择。不得改 single/A/B/property、交通结果或启动导航。仅 opened scope 可见，关闭/换地点/date/snapshot 后清理选择并以 hidden/新 viewport 替换旧层。

最小调用：`await mapLayerHost.contribute(currentStationLayer);`。**Fake 场景：** fake host 对新旧 viewport 返回 accepted/staleViewport，断言旧站点不会覆盖新地点；点击未知或旧 marker 时本地选择清除。无需地图 SDK。

### Interface 卡：`TRANSIT-002` — 标准化 GTFS 读取（仅 A）

**提供者/消费者：** Public Transportation（A）/ A；非跨 Owner 公开入口。A 只经 authenticated、security-invoker 的 `read_transit_analysis` 读取已准备 snapshot、站点/路线、固定参照网格和聚合；Flutter 不下载 ZIP、不直读 `gtfs_feed_snapshots`、`gtfs_stops`、`gtfs_routes`、`gtfs_stop_services`、`transit_analysis_results` 或 `transit_reference_grid`。字段、键、RLS 和迁移唯一见 Schema Catalog。网络/SDK/查询映射、刷新、缓存、取消及 retry 是 A 的内部实现。

## 3. 必须提供的 Interface

### Interface 卡：`TRANSIT-001` — 公共交通 canonical connectivity result

**提供者：** Public Transportation（A）；**消费者：** Application Shell、Infrastructure Coverage、Personalized Location Suitability；**唯一公开 import：** `package:locatemy/features/public_transportation/public_transportation.dart`。

消费者只能 import 此入口，不能 import `lib/features/public_transportation/src/` 或任何 GTFS/Adapter 文件。A 应先合入以下声明与最小 fake；这是协作形状，不是可提交实现体。

```dart
abstract interface class PublicTransportation {
  Future<TransitLoadOutcome> load(TransitRequest request);
  Future<TransitComparisonOutcome> compare(TransitComparisonRequest request);
}
final class TransitRequest {
  final ValidLocationReference location;
  final DateTime analysisDate;
  final TransitLoadPolicy policy;
  const TransitRequest({required this.location, required this.analysisDate, required this.policy});
}
enum TransitLoadPolicy { cacheAllowed, refresh }
sealed class TransitLoadOutcome { const TransitLoadOutcome(); }
final class TransitAvailable extends TransitLoadOutcome { final TransitSnapshot snapshot; const TransitAvailable(this.snapshot); }
final class TransitIncomplete extends TransitLoadOutcome { final TransitPartialSnapshot snapshot; const TransitIncomplete(this.snapshot); }
final class TransitUnavailable extends TransitLoadOutcome {
  final TransitUnavailableReason reason; final List<FeedStatus> feeds;
  const TransitUnavailable(this.reason, this.feeds);
}
enum TransitUnavailableReason { noUsableFeed, analysisDateOutsideServiceRange, retryableUnavailable, sourceUnverifiable }
final class TransitSnapshot {
  final ValidLocationReference location; final DateTime analysisDate; final int radiusMeters;
  final List<TransitStation> stations; final int uniqueStopCount; final int? nearestDistanceMeters;
  final int uniqueRouteCount; final TransitServiceOutcome serviceOutcome; final TransitScore? score;
  final List<FeedStatus> feeds; final TransitProvenance provenance;
  const TransitSnapshot({required this.location, required this.analysisDate, required this.radiusMeters, required this.stations, required this.uniqueStopCount, required this.nearestDistanceMeters, required this.uniqueRouteCount, required this.serviceOutcome, required this.score, required this.feeds, required this.provenance});
}
final class TransitPartialSnapshot {
  final ValidLocationReference location; final DateTime analysisDate; final int radiusMeters;
  final List<TransitStation> stations; final int uniqueStopCount; final int? nearestDistanceMeters;
  final int uniqueRouteCount; final List<FeedStatus> feeds; final TransitProvenance provenance;
  const TransitPartialSnapshot({required this.location, required this.analysisDate, required this.radiusMeters, required this.stations, required this.uniqueStopCount, required this.nearestDistanceMeters, required this.uniqueRouteCount, required this.feeds, required this.provenance});
}
final class TransitStation {
  final String feedId; final String stopId; final String name; final GeographicPoint point;
  final TransitStationType type; final int distanceMeters; final String? parentStation;
  const TransitStation({required this.feedId, required this.stopId, required this.name, required this.point, required this.type, required this.distanceMeters, required this.parentStation});
}
enum TransitStationType { bus, rail, ferry, other }
enum TransitServiceOutcome { served, noStops, noActiveRoutes }
final class TransitScore { final int value; const TransitScore(this.value); }
enum FeedAvailability { usable, stale, missing, failed, outOfServiceRange }
final class FeedStatus {
  final String feedId; final String sourceId; final Uri sourceUrl; final DateTime? capturedAt;
  final FeedAvailability availability; final String? reason;
  const FeedStatus({required this.feedId, required this.sourceId, required this.sourceUrl, required this.capturedAt, required this.availability, required this.reason});
}
final class TransitProvenance { final String snapshotId; final String referenceGridVersion; final DateTime generatedAt; const TransitProvenance({required this.snapshotId, required this.referenceGridVersion, required this.generatedAt}); }
final class TransitComparisonRequest { final TransitRequest a; final TransitRequest b; const TransitComparisonRequest(this.a, this.b); }
sealed class TransitComparisonOutcome { const TransitComparisonOutcome(); }
final class TransitComparable extends TransitComparisonOutcome { final TransitSnapshot a; final TransitSnapshot b; const TransitComparable(this.a, this.b); }
final class TransitIncomparable extends TransitComparisonOutcome { final TransitLoadOutcome a; final TransitLoadOutcome b; final TransitComparisonReason reason; const TransitIncomparable(this.a, this.b, this.reason); }
enum TransitComparisonReason { sideUnavailable, sideIncomplete, analysisDateMismatch, radiusMismatch, provenanceMismatch, serviceOutcomeNotScored }
```

| 输入约束 | 输出 / typed failures | 状态与副作用 | 顺序与权限 |
| --- | --- | --- | --- |
| `location` 必为 `LOCATION-001` immutable reference；`analysisDate` 是明确本地日历日，不能以请求时刻、feed captured time 或生成时间替换；半径恒 1,500 m；refresh 只要求新读。 | `TransitAvailable` 只在全部预期 feed 为 usable/stale；`TransitIncomplete` 保留成功部分且无 score；`TransitUnavailable` 带 reason/feed 原因。A/B 只给 `TransitComparable` 或 `TransitIncomparable`。 | 只读公共 GTFS 稳定对象；不写地点、账户、ICI、Suitability、Shell 或 Map。站点选择是页面本地状态，不进入 result。 | 只在 opened 主应用旅程呈现。Map 先给 immutable reference；A 读取后以相同 location/date/provenance 发布。Infrastructure/Suitability 只能消费 `TransitAvailable` 的同一 `TransitSnapshot`，不得重读/重算。 |

#### 必须保持的日期、GTFS 与结果语义

- `analysisDate` 用于 `calendar.txt` / `calendar_dates.txt` 的有效服务判定；`feed.capturedAt` 只表示快照采集时间；`generatedAt` 只表示本次结果生成时刻，三者不可互代。恰 30 天不 stale；超过 30 天且仍可解析并覆盖 analysisDate 才是 `stale`。
- 站点实体是 `location_type = 0`；同 feed 以 `stop_id`、跨 feed 以 `feedId + stopId` 去重；`parentStation` 只可展示分组。路线以 `feedId + routeId` 唯一，必须经 routes → trips → stop_times 并在 analysisDate 有效；同名/同坐标站点与跨 feed `route_short_name` 不自动合并。
- `available` 不另设 enum：它由 `TransitAvailable` 表达。只有它带 service outcome：`served`（站点且至少一条有效路线）、`noStops`（有效零站）或 `noActiveRoutes`（有站/零路线）。后两者 `score == null`，不是 0 分。任何实际使用 stale feed 以 `FeedAvailability.stale` 让消费者展示“资料可能过期”。
- 任一预期 feed missing/failed/outOfServiceRange、但仍有 usable/stale 为 `TransitIncomplete`；可保留成功部分，绝不算分。没有 usable/stale 是 `TransitUnavailable`；上游地点拒绝不转换为本 Interface 的 no-service。
- 分数只有 `served` 的完整结果可用，0–100 整数；它复用事实源的距离、密度、路线百分位和固定 1 km 参照网格。列表最多 30 项不截断 `uniqueStopCount`、路线或分数。

最小调用：

```dart
final outcome = await transit.load(
  TransitRequest(location: location, analysisDate: analysisDate, policy: TransitLoadPolicy.cacheAllowed),
);
switch (outcome) {
  case TransitAvailable(:final snapshot):
    // 仅把此同一 snapshot 提供给 Shell/Infrastructure/Suitability。
  case TransitIncomplete(:final snapshot):
    // 展示成功部分与 feed 原因；不提供交通分。
  case TransitUnavailable(:final reason):
    // 显示恢复路径；不显示伪 0 或 no-stops。
}
```

**Fake 场景：** Infrastructure 的 fake `PublicTransportation` 返回 served score、noStops、noActiveRoutes、incomplete 和 unavailable，验证只在 served score 时纳入 ICI；Suitability fake 将全部非 scored outcome 保留为维度不可用。Shell fake 对 A/B 的 analysis date、radius 或 provenance 不同返回 `TransitIncomparable`，不显示差异。消费者无需 GTFS、Supabase 或 Transit 生产实现。

## 4. 直接使用的数据与推荐实施顺序

| 目的 | 权威来源 / A 的访问边界 | 固定语义 |
| --- | --- | --- |
| GTFS 读取 | `read_transit_analysis`；Schema Catalog 的标准化 GTFS 对象 | authenticated read-only；只取本 Feature 所需 provenance、feed 状态、站点、路线/聚合、参照网格结果；预期 feed 失败不是空 feed。 |
| 空间/服务/分数 | [公共交通事实](../../knowledge_base/locatemy_product/features/transportation.md)；[ICI 交通规则](../../knowledge_base/locatemy_product/infrastructure_index_scoring.md#公共交通) | 1,500 m 直线距离、站点和路线键、analysisDate 有效路线、固定 1 km grid 与完整资料才计算分数。 |
| 运行时选择 | `STATE-TRANSIT-SELECTION`（Transit 内存） | 仅当前 result 的 `feedId + stopId`；换地点/date/snapshot、离页或 scope closing 时清除；不持久化、不进入队列。 |
| 权限与生命周期 | Schema Catalog、data ownership | 公共结果无账户字段；不建 Transit 私有 cache/queue。authenticated read 不等于匿名公开；客户端无 service-role。 |

1. **A 先合入 seam。** 创建唯一入口、`TRANSIT-001` 声明及最小 fake；Shell、Infrastructure、Suitability 不依赖 Transit `src/`。
2. **A 完成真实读与页面结果。** 将 `read_transit_analysis` 映射为本契约 outcome，验证 16 feed、日期边界、单位、provenance、1.5 km、站点/路线键和无伪零。
3. **并行消费 fake。** Shell 组合贡献；Infrastructure/Suitability 只消费同一 snapshot；Map host 接收声明式图层。
4. **A 完成局部选择和可访问呈现。** 列表/Marker 同步，文字同时表达范围、状态、来源、日期、选中和限制；图不是唯一信息载体。
5. **共同联调。** 接入真实 seam，仅保留第 5 节所需跨模块流测试。

## 5. 联合验收、阻塞与变更

| Capability / canonical AT | 情景与操作 | 可观察完成条件 |
| --- | --- | --- |
| `TRANSIT-01` / `AT-ANALYSIS-01` | 单点、完整 served、不同 analysisDate | 1.5 km、全部站点数、最近距离、有效路线、可用分数、feed source/capturedAt、generatedAt 和 grid/snapshot 均来自同一 result。 |
| `TRANSIT-01` / `AT-ANALYSIS-01`、`AT-RACE-01` | 第 30 天/超 30 天；missing/failed/out-of-service-range；部分、无 usable；no stops/no active routes | 仅完整才 `TransitAvailable`；stale 是完整结果警告；partial/unavailable 与有效零站/零路线可区分，永无伪 0/Marker/默认地点。 |
| `TRANSIT-01` / `AT-COMPARE-03` | A/B、单侧不可用/partial、date/radius/provenance 不同、交换、晚到 | 保留两端自身事实；只有同口径 scored result 才可比较；交换仅改呈现槽位，旧响应不覆盖新请求。 |
| `TRANSIT-02`、`TRANSIT-03` / `AT-ANALYSIS-01`、`AT-RACE-01` | 列表/Marker 互选、no stops、换地点/date/snapshot、scope close | 同一稳定站点高亮且有文字；局部图显示中心/圆/当前 marker；失效选择释放，不改全局地点/导航。 |
| `TRANSIT-001` / `AT-ANALYSIS-01`、`AT-COMPARE-03` | Shell、Infrastructure、Suitability 消费 served/not scored result | Shell 不置零；Infrastructure/Suitability 不重读/重算，只有 served score 可作为同一 canonical fact 消费。 |
| 可访问性 / `AT-ANALYSIS-01` | 中文/English、动态字体、屏幕阅读器、无颜色 | 站点、范围、日期、来源、状态、限制、选择和分数含文字/可访问名；交通分只称覆盖读数，不称通勤或质量评价。 |

当前设计阻塞：**无**。`RISK-TRANSIT-01` 的产品/契约决定已关闭；16 个官方 feed 的来源登记、快照/解析/服务日期、导入完整性、固定参照网格及第 30 天/部分 feed 运行时证据是实现/集成 Gate。资料结构无法符合 Schema Catalog 或状态矩阵时，停止发布受影响结果并重开风险；不得以 fixture 代替。

公共 Interface 变更由 A 说明原因和受影响消费者，Shell、Infrastructure、Suitability 与 Map（如涉及图层）确认；同一 PR 更新公开声明、本契约、同名 HTML 与受影响 fake/Adapter 测试。Git/PR 保存历史；不使用文档版本、checksum、Manifest、Locked Source Set、Generation Gate、Development Release、Invalidated 状态机或独立 handoff 发布治理。

- [x] 四项 Readiness 在第 0 节均有可核查证据。
- [x] 每个跨 Owner Interface 具有唯一 import、声明/精确调用、输入约束、typed output/failure、状态/副作用、次序/权限、示例和 fake 场景。
- [x] `analysisDate`、capturedAt、generatedAt、完整性、stale、service outcome、站点/路线键与 canonical result 语义对齐唯一产品事实源。
- [x] Dart 只有声明和使用说明；无函数体、Widget、SDK 调用、SQL migration 或测试实现。
- [x] Standards/Spec 双轴复审通过；设计 AI 依 ADR 0013 批准 Ready。

| 日期 | 状态 | 变更原因 | 受影响对象 | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-15 | `Ready for Development` | Issue #23：收束为单一 Development Contract 与同名 HTML；移除 PDF/ADR 0014/handoff 发布治理，并逐字对齐 Shell 与 Map 的完整 canonical 声明（Transit 仅调用所需子集），不改变 GTFS、1.5 km、有效路线、缓存/权限或验收语义 | `TRANSIT-01`–`03`、`TRANSIT-001`、`SHELL-001`、`LOCATION-001`/`002`、`read_transit_analysis`、`RISK-TRANSIT-01`、同名 HTML | 设计 AI（项目负责人授权） |
