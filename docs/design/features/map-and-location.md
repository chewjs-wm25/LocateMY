# Map / Location 开发协作契约

> Owner：`A`
> 依赖顺序：Wave 4。A 先合并唯一公开入口及本文件冻结的完整 `LOCATION-001`/`LOCATION-002` 声明；Application Shell、分析 Feature 和图层提供方随后以同一声明的 fake 并行开发。
> 完成定义：消费者仅凭本文件即可安全地区分合法地点、拒绝、收藏同步状态及图层意图；不读取 Map 内部状态、缓存或 SDK 对象。
> 状态：`Ready for Development`；系统基线：`5d11769`；最后复核：`2026-09-15`

这是 Map / Location 唯一的跨 Owner Development Contract；本 Markdown 为权威来源，`docs/human/map-and-location.html` 是同名、语义等价的人类可读导出。它冻结公开 Dart 声明、合法地点与账户隔离语义、收藏同步可观察结果及联合验收。`lib/features/map_location/` 内部的 Widget、地图/空间 SDK、状态管理、SQLite/Supabase/Geoapify Adapter、取消/重试/去重策略、缓存键、文件拆分和测试组织均由 Owner 决定。

## 1. 任务成果

- `MAP-01`–`MAP-06`：已开启账户范围的用户可在真实、可拖动/缩放的 OSM 地图上点选或搜索马来西亚内地点；管理 single、A、B、property 地点角色；保存/恢复/删除命名收藏；由合法不可变快照进入单点分析或 A/B 比较；承载声明式图层与长按创建意图。
- 地点详情只承载提供方摘要。`MAP-07` 的适配度计算、前提与结果归 Personalized Location Suitability；社会经济不进入地图摘要；用户隐患不进入地点摘要、`SAFETY-001` 或适配度。
- 不包含：行政区/统计州解析（Geographic Context）、六类分析或可比性（各分析 Owner）、隐患内容/写入（Hazard Reporting）、认证与导航执行（Application Shell）。不申请 GPS，不使用默认城市，不把收藏当行政区 ID，不把图层点击静默变为分析地点。

产品事实唯一来源：[地图、选址与收藏](../../knowledge_base/locatemy_product/features/map_location.md)、[提交承诺](../../knowledge_base/locatemy_product/submission_commitments.md#地图地点与收藏)、[地图 UI 规则](../../knowledge_base/locatemy_product/ui_design_spec.md#地图和分析入口)。当前静态原型、预设地点与内存收藏不是实现依据。

## 2. 责任与依赖

| Owner / 文件边界 | 负责 | 不负责 | 协作边界 |
| --- | --- | --- | --- |
| Map / Location：`lib/features/map_location/` | `STATE-LOCATION`、最终马来西亚校验、地图手势/Marker、地点角色、收藏同步/本机 create queue、图层宿主 | 分析、行政语境、图层领域内容、认证/全局路由 | 提供 `LOCATION-001`、`LOCATION-002`；调用 `SHELL-001`、`PRIVACY-001`、`LOCATION-003` |
| Application Shell：`lib/app/` | 地图 Tab、门控、分析/表单/详情导航、返回语境和组合 | 选点、收藏、图层领域语义 | 消费 `LOCATION-001`；唯一执行 `SHELL-001` |
| Account Privacy | scope opened/closed 与关闭证明 | Map payload、远端收藏或公共缓存 | Map 是八个清理参与 Owner 之一，消费 `PRIVACY-001` |
| Hazard / Facilities / Transit | 图层内容、数据权限、刷新、稳定领域标识与点击后的业务意图 | 底图、可变选点、其他图层解释 | 通过 `LOCATION-002` 提交声明 |

直接依赖为 `SHELL-001`（`D05`）和 `PRIVACY-001`（`D06`）。Map 向 Cost、Crime、Facilities、Transit、Hazard、Socio-economic、Infrastructure、Property、Suitability 输出合法引用，覆盖 `D08`、`D12`、`D15`、`D17`、`D19`、`D22`、`D26`、`D31`、`D40`。系统登记在 [Feature map](../system/feature-map.md#fm-map)、[Interface registry](../system/interfaces.md) 与 [Capability traceability](../system/capability-traceability.md)。

## 3. 需要调用的 Interface

### `SHELL-001` Application Shell

**唯一公开 import：** `package:locatemy/app/application_shell.dart`

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
  final ShellRejectionReason reason;
}
sealed class ShellContributionOutcome {}
final class ShellContributionAccepted extends ShellContributionOutcome {}
final class ShellContributionAuthenticationRequired extends ShellContributionOutcome {}
final class ShellContributionRejected extends ShellContributionOutcome {
  final ShellRejectionReason reason;
}
enum ShellRejectionReason { missingInput, staleInput, inapplicableDestination, scopeUnavailable }
```

Map 在自己的唯一公开入口声明其 `ShellIntent` 与 `ShellContribution` marker：分析/比较/返回式选点、图层点击和地点详情摘要。每个 intent 的地点输入必须为本 Interface 已产生的 `ValidLocationReference`，并保留返回语境；贡献保留提供方原始来源、日期、口径、单位与可用性。仅同账户 `opened` 可提交或发布；`ShellAuthenticationRequired` 保持地点状态但不开放目标，`rejected` 只报告导航/组合拒绝，不能伪装为地点或数据失败。Shell 不得借调用改写 Map 地点。

最小调用：

```dart
final result = await applicationShell.submit(
  OpenAnalysisIntent(location: selectedLocation),
);
// accepted 才导航；其他 outcome 保持当前地图并显示对应恢复路径。
```

fake 场景：Map UI 以 fake Shell 分别返回 accepted、authentication required、stale input，证明旧地点/图层意图不进入目标且拒绝原因可读；不需要 Shell 生产路由。

### `PRIVACY-001` 与 `LOCATION-003`

| Interface | Owner | Map 调用目的、输入与结果 | 顺序、权限与副作用 |
| --- | --- | --- | --- |
| `PRIVACY-001` | Account Privacy | 同账户 `opened` 是私有地点、收藏读取/同步的前提；关闭请求时 Map 报告自己的处理完成。 | closing 开始即拒绝旧账户地点意图、同步和晚到结果；清除 `STATE-LOCATION`、旧账户 cache/queue，不删除远端收藏、公共地图/边界缓存或语言。 |
| `LOCATION-003` | Map 的 Geoapify Adapter | 以地点名称取得马来西亚限定候选。空、失败、过期候选均是可解释状态，不产生默认城市。 | 候选只是 `LOCATION-001.select` 输入；国家文字/来源不能替代空间校验。防抖、取消、网络策略和密钥隔离为内部实现。 |

## 4. 必须提供的 Interface

### `LOCATION-001`：合法地点与收藏

**提供者：** Map / Location（A）
**消费者：** Application Shell、Cost、Crime、Facilities、Transit、Hazard、Socio-economic、Infrastructure、Property Inspection、Personalized Location Suitability。
**唯一公开 import：** `package:locatemy/features/map_location/map_location.dart`

消费者只能 import 此入口，不能 import `lib/features/map_location/src/`。**下列代码块是 `LOCATION-001` 的完整 canonical 声明：生产 Adapter、所有消费者和 fake 必须使用同一类型、成员、输入及 result variant；不得在消费者文件截断、复制或改形。** 以下是声明而不是函数体或 SDK 映射：

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

| 调用 | 输入约束 | 成功输出 | typed failure 与调用方处理 |
| --- | --- | --- | --- |
| `select` | 显式 `role`；有限 WGS84 数值；候选须再次校验 | `LocationSelected` 携带不可变引用，只更新指定角色 | `invalidCoordinate`、`outsideMalaysia`、`sameComparisonPoint`、`scopeUnavailable`；保留原合法角色或空状态，不默认选点 |
| `read` | 任一角色 | `LocationPresent` 或该角色 `LocationAbsent` | 无副作用；absence 时不得分析/比较 |
| `swapComparisonLocations` | A 与 B 存在且不同 | 交换后的 `LocationSelected` 事实 | 缺端/同点拒绝；只换显示槽位，不改地点身份、single/property 或已发出分析 |
| `save` | `location` 来自本 Interface；名称 trim 后 1–120；scope opened | 在线 `SavedLocationSaved`；离线仅 create 是 `SavedLocationQueued` | 非法值不入队；失败不称已同步；retryable 保留队列 |
| `deleteSavedLocation` | 非空当前账户收藏 id，在线 | `SavedLocationSaved` 表示远端删除且本机已更新 | 离线 `offlineDeleteUnsupported`，不建删除队列；permission/conflict/not-found 不伪装成功 |
| `watchSavedLocations` / `synchronizeSavedLocations` | opened；同步在冷启动 opened、登录后、前台或手动重试 | `SavedLocationsAvailable` 含远端权威记录与队列状态 | `Unavailable` 需恢复路径；不以空列表表示失败/不完整 |

状态/副作用/顺序/权限：最终合法性使用版本可审计的 DOSM/OpenDOSM 行政区边界联合范围；边界点合法，海域/范围外拒绝，Map 不解析统计州/行政区。single/A/B/property 相互隔离；A/B 中性、不可相同；合法 select 只改请求角色。只有同账户 `PRIVACY-001.opened` 才可读私有地点/收藏或同步；closing 后丢弃旧账户响应。Supabase `user_saved_locations` 是权威；本机 cache/queue 按账户隔离；每次 create 使用同账户唯一客户端幂等键，远端版本解决冲突，在线删除写可同步墓碑，旧 cache 或晚到 create 不得复活删除项。仅 create 可离线；编辑/删除在线。

最小调用：

```dart
final selected = await locations.select(
  LocationSelectionRequest(role: LocationRole.single, point: point),
);
switch (selected) {
  case LocationSelected(:final location):
    // Submit this immutable location to SHELL-001; do not reread mutable map state.
  case LocationSelectionRejected(:final failure):
    // Keep the prior/empty role and present recovery for failure.
}
```

fake 场景：Shell fake 返回 single selected、A/B 缺端、same comparison point、scope unavailable，证明只转交返回引用且拒绝时不导航。收藏 UI fake 返回 saved、queued、offline delete unsupported、unavailable，证明 queued 不称同步成功、离线删除不隐藏原项。无需 Geoapify、地图 SDK、SQLite 或 Supabase。

### `LOCATION-002`：声明式地图图层与意图

**提供者：** Map / Location（A）
**消费者：** Hazard Reporting、Nearby Facilities、Public Transportation。
**唯一公开 import：** `package:locatemy/features/map_location/map_location.dart`

消费者只能 import 此入口，不能 import `lib/features/map_location/src/`。**下列代码块是 `LOCATION-002` 的完整 canonical 声明：生产 Adapter、所有图层消费者和 fake 必须使用同一类型、成员、输入及 result variant；不得在消费者文件截断、复制或改形。** 以下是声明而不是函数体或 SDK 映射：

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

| 要求 | 契约 |
| --- | --- |
| 输入 | provider 提交稳定 id、坐标、viewport version、纯声明式点击意图。Transit 仅提交当前交通页的分析中心、1.5 km 圆、`feed_id + stop_id` Marker 与选中意图。 |
| 输出/failure | hidden 是接受但不显示；stale viewport、非法贡献/坐标、范围外、scope 不可用为 rejected。Map 不泄露内部地图对象。 |
| 副作用/顺序 | 只更新覆盖物/相机；旧 viewport 不覆盖新 viewport；点击回传原意图；长按先空间校验再返回 `CreateHazardIntent`。点击/长按不改 single/A/B/property，除非用户另行 `select`。 |
| 权限 | 图层读取权限/内容归 provider；长按创建需 authenticated/opened。Map 不写隐患、设施或交通结果。 |

fake 场景：Hazard fake 贡献 visible、hidden、分页不完整、stale viewport；Map 仅呈现声明，不把不完整称无内容。Transit fake 用两个 viewport version 证明晚到站点不覆盖新视口；合法长按只产生创建意图，范围外返回 `outsideMalaysia`。

## 5. 直接使用的数据

| 目的 | 权威来源及 Map 访问边界 | 固定语义 |
| --- | --- | --- |
| 运行时地点 | `STATE-LOCATION`（Map 内存、进程寿命） | 最近一次合法明确动作；关闭清空角色、Marker、摘要与 viewport。 |
| 范围校验 | `RISK-GEO-01` DOSM/OpenDOSM 联合边界；版本/hash 由 `government_dataset_imports` 审计 | 边界合法，海域/范围外拒绝；样本证据留实现/集成。 |
| 收藏 | `user_saved_locations`；`saved_location_cache`、`saved_location_create_queue` | 字段、RLS、迁移唯一见 [Schema Catalog](../data/schema-catalog.md#身份与账户业务对象)，本契约不复制。 |
| 私有关闭 | [data ownership](../system/data-ownership.md#privacy-barrier-参与者清单) | 清除旧账户 Map 私有状态，保留公共地图/边界缓存。 |

## 6. 推荐实现顺序

1. A 先合并唯一入口、两组声明与最小 fake；消费者不得依赖 Map `src/`。
2. 实现角色隔离、不可变引用、DOSM/OpenDOSM 校验及地图文字可访问替代；验证边境、岛屿、海域、范围外、快速换点。
3. 在 `PRIVACY-001` 下实现同账户同步、create-only queue、幂等/墓碑与 close；验证重启、双设备、冲突、A→B。
4. Shell/分析 Feature 用 `LOCATION-001` fake；Hazard/Facilities/Transit 用 `LOCATION-002` fake 并行开发。
5. 接入真实 Adapter，保留下表联合验收；分析结果按原地点引用/版本入槽。

## 7. 联合验收

| 场景 | Owners | 操作 | 可观察结果 | Trace |
| --- | --- | --- | --- | --- |
| 马来西亚选点/搜索 | A、Shell | 点选/候选；边境、岛屿、海域、范围外、空/过期、快速换点 | 仅改明确角色；无默认城市；旧响应不覆盖新；文字反馈可访问 | `MAP-01`–`03`；`AT-LOC-01`、`AT-LOC-02`、`AT-RACE-01` |
| 单点分析 | A、Shell、六类 Owner | 合法 single 请求摘要/完整分析；注入 unavailable/partial/cached | Shell 只转交同一引用；各项保留元数据，缺失不置零 | `MAP-06`；`AT-ANALYSIS-01` |
| A/B 比较 | A、Shell、分析 Owner | 缺端、同点、交换、请求中换槽 | 两端有效不同才进入；交换只换呈现；结果按原引用入槽，无赢家 | `MAP-04`；`AT-COMPARE-01`–`03` |
| 收藏同步 | A、Privacy | 在线 create/delete、离线 create/重启/重放、双设备删除、冲突 | 远端权威；queued 有文字；同 key 不重复；墓碑不复活 | `MAP-05`；`AT-SAVED-01`–`03` |
| 换号/关闭 | A、Shell、Privacy | A close 中/失败重试后 B open；晚到搜索/同步 | A 地点/name/cache/queue/响应不可见/不可重放；公共缓存保留 | `MAP-01`、`MAP-05`；`AT-SAVED-04`、`AT-RACE-01` |
| 图层/长按 | A、Hazard、Facilities、Transit、Shell | visible/hidden/rejected、旧 viewport、点击、合法/非法长按 | 按 provider 语义；旧视口不覆盖新；意图不静默改地点 | `LOCATION-002`；`AT-HAZARD-01`、`AT-ANALYSIS-01`、`AT-RACE-01` |

## 8. 内部自由

Owner 可自行决定底图包、Geoapify/空间 Adapter、点位内部映射、缓存读写、SQLite/Supabase 访问、同步算法、取消、排序、Widget/状态管理和测试组织。以下变化必须取得跨 Owner agreement：唯一公开 import、公开声明/result variant、输入约束、权限/副作用/顺序、角色隔离、范围校验结论，或收藏 Schema/RLS。变更在同一 PR 更新本 Development Contract、同名 HTML 导出与受影响 fake/Adapter 测试；不引入独立发布、版本锁定或同步治理流程。

## 9. 阻塞与权威参考

当前设计阻塞：**无**。`RISK-GEO-01` 与 `RISK-SYNC-01` 已关闭设计决定；边界样本、运行时地图/网络/SQLite、双设备/重放/墓碑、可访问性为实现/集成验收项，不是 Ready 阻塞。依赖版本变化或范围/同步语义无法维持时，重新打开风险并暂停受影响实现。

权威参考：[Issue #23](https://github.com/chewjs-wm25/LocateMY/issues/23)、[ADR 0011](../../adr/0011-human-coded-ai-designed-delivery-process.md)、[ADR 0012](../../adr/0012-high-level-design-coordination-boundaries.md)、[ADR 0013](../../adr/0013-autonomous-design-ai-ready-approval.md)、[Flows 02–05](../system/flows.md)、[data ownership](../system/data-ownership.md)、[risk decisions](../system/risks-and-decisions.md)、[Schema Catalog](../data/schema-catalog.md)、[Authentication contract](authentication-and-session-development-contract.en.md)。

### Change Log

| 日期 | 状态 | 变更原因 | 受影响的 Capability / Interface / 数据对象 / Feature | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-15 | `Ready for Development` | 依 Issue #23 收束为单一 Development Contract 与同名 HTML 语义等价导出；移除旧式多文件发布治理，并明确冻结两份接口的单一公开入口和完整 canonical 声明。 | `MAP-01`–`MAP-06`、`LOCATION-001`、`LOCATION-002`、同名 HTML 导出；地点、权限、同步、数据与验收语义不变。 | 项目负责人 |

## 10. 完成核对

- [x] 按固定顺序：任务成果、责任/依赖、调用 Interface、提供 Interface、直接数据、实现顺序、联合验收、内部自由、阻塞/权威参考。
- [x] `LOCATION-001`/`LOCATION-002` 有唯一公开 import、完整 canonical 声明、输入、输出/typed failures、状态/副作用、顺序、权限、最小示例与 fake 场景；所有消费者与 fake 引用同一声明，不改形或 import 内部文件。
- [x] `MAP-01`–`MAP-06`、`D05/D06` 与下游 Map 边可追溯；`MAP-07` 明确不由本 Owner 重算。
- [x] 范围、账户隔离、同步权威/墓碑、分析快照、A/B 中性、图层不改地点均有唯一权威；不复制 Schema、RLS、公式或可提交实现。
- [x] 同名 HTML 与本 Markdown 在任务成果、依赖顺序、两份 canonical 声明、表格、链接、联合验收与 Change Log 上语义等价；无旧式多文件发布治理要求。
