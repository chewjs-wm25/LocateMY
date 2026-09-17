---
kb_id: feature-transportation
kind: feature-spec
status: accepted
capabilities: [TRANSIT-01, TRANSIT-02, TRANSIT-03]
tags: [transit, station, coverage]
---

# 公共交通与通勤

## 产品定义

公共交通页面分析单个地点周围 1.5 公里的公共交通覆盖情况。交通连通性是覆盖读数，不是实际通勤时间、票价、准点率、班次密度或服务质量评分。

交通连通性分数同时供本页和基础设施综合覆盖指数（ICI）使用；两处必须复用同一个已计算结果。公式、数据集清单和 ICI 规则见[单个地点基础设施指数](../infrastructure_index_scoring.md)。

## 页面功能

- 显示交通连通性分数、统一等级、范围内站点总数、最近站距离和数据状态。
- 显示站点分布图：分析中心、1.5 公里范围圆和范围内全部站点 Marker。
- 显示站点列表；首屏按距离升序显示最近 30 个，同时显示范围内完整站点数。列表截断不影响评分统计。
- 列表和 Marker 可相互高亮；选中站点显示名称、归一化类型、距离和粗略步行分钟提示。
- 站点类型归一化为“巴士”“铁路”“渡轮”“其他”；保留 GTFS 原始 `route_type`。
- 站点选择不移动全局选点、不移动主地图中心、不写入全局选点，也不提供路线导航。
- 页面不提供“在主地图上查看”；“站点分布图”是本页的局部地图，不称为热力图。
- 当前单点页面使用本地 `TransportReport` fixture；正常示例两处预设地点均为 72/100、5 个站点和 9 条有效路线，状态场景可切换但未连接真实 GTFS。
- 地点 A/B 总览和详情当前使用固定示例站点数与分数，未读取两地的 `TransportReport`，也未逐地点展示 `availability_status`、feed 采集日期和来源；这些文本不能视为 A/B 实际比较结果。

## 空间与站点口径

- 距离使用分析坐标到站点坐标的直线距离，采用米为单位；步行分钟只是展示提示，不参与分数。
- 统计半径固定为 1,500 米；页面标题、说明、列表、地图和评分统一使用 1.5 公里。
- 统计可上下车的站点实体，通常为 `stops.txt` 中 `location_type = 0` 的记录。存在 `parent_station` 时，列表可按父站点分组，但统计仍按子站点实体计数。
- 同一 feed 内使用原始 `stop_id` 去重；跨 feed 使用 `feed_id + stop_id` 去重。不同 feed 中同名或同坐标站点不自动合并。
- 路线唯一键使用 `feed_id + route_id`；相同 `route_short_name` 跨 feed 不合并。

### 固定参照组服务范围

项目负责人于 2026-09-17 确认：参照组服务范围采用分析日期可用 feed 的 `location_type = 0` 站点周围 1.5 公里圆的并集，不使用城市名称或未提供的运营边界。固定 1 km 米制格点中心须在该并集内；参照组绑定同一 GTFS snapshot、分析日期及方法版本。站点是否在圆内仍使用真实米制地理距离；参照组不会随用户选点变化。具体投影、原点、grid ID 和数据准备证据属于 Schema Catalog。

## 数据处理边界

- 候选来源为官方列出的全部 16 个 GTFS Static feed；系统可用覆盖登记缩小候选范围，但最终以站点坐标是否落入 1.5 公里为准，不按地点名称猜测城市。
- 路线必须通过 `routes.txt → trips.txt → stop_times.txt` 关联到范围内站点，并且服务日期在 `calendar.txt` / `calendar_dates.txt` 中有效，才计入有效路线数。
- GTFS ZIP 的下载、解析、去重、有效日期判断和评分由维护者在手动数据准备中完成；Flutter 读取 Supabase 的标准化只读结果。当前不实现自动同步。
- 每个 feed 保存 `feed_captured_at`；页面显示 feed 采集时间和本次刷新时间，不伪造统一统计日期。
- 每个预期 feed 独立标为 `usable`、`stale`、`missing`、`failed` 或 `out-of-service-range`。`stale` 是可解析、分析日期在服务日期范围内、但 `feed_captured_at` 距当前刷新或分析时刻超过 30 天的可用 feed；它仍可展示站点、有效路线和交通连通性分，但必须标记“资料可能过期”。`out-of-service-range` 不能确认该 feed 在分析日期的有效路线，不能仅标记 `stale` 或使用旧路线计算分数。
- 整体 **availability** 只有 `available`、`incomplete` 或 `unavailable`：全部预期 feed 均为 `usable` 或 `stale`、因此可用于分析日期时为 `available`；任何实际使用 feed 为 `stale` 时，`available` 结果同时附“资料可能过期”警告。
- 只有 `availability = available` 时才有 **service outcome**：有范围内站点且至少一条有效路线为 `served`；没有站点为 `no_stops`；有站点但路线数为 0 为 `no_active_routes`。`no_stops` 和 `no_active_routes` 不改变 availability，交通连通性分均不可用。
- 部分 feed 为 `usable` 或 `stale`、而另有 `missing`、`failed` 或 `out-of-service-range` feed 时，整体结果为 `incomplete`：可展示成功部分的站点/路线及各 feed 原因，但不计算交通连通性分。
- 没有任何预期 feed 为 `usable` 或 `stale`、可用于分析日期时，整体结果为 `unavailable`；从未成功取得结果和刷新失败均保留各 feed 原因，不能伪装为空服务。

### 交通可用状态

- `no_active_routes` 是 `availability = available` 的 service outcome：全部预期 feed 为 `usable` 或 `stale`、范围内有站点但分析日期没有有效服务路线时成立。站点继续展示，`unique_route_count = 0`，交通分不可用，并显示“有站点，但分析日期没有有效服务路线”。这是已知的零路线观测，不是 feed 失败。
- `incomplete` 表示部分预期 feed 为 `usable` 或 `stale`、另有 `missing`、`failed` 或 `out-of-service-range`；可保留成功部分，但交通分不可用，并显示“资料不完整，无法生成完整交通分”。
- `stale` 是整体 `available` 的附加警告，不是 availability 或 service outcome；它只表示至少一个实际使用 feed 超过 30 天，且仍可解析、分析日期仍在服务日期范围内。
- `no_stops` 是 `availability = available` 的 service outcome：全部预期 feed 为 `usable` 或 `stale` 且范围内没有站点时成立，站点数为有效的 0，交通分不可用。

## 标准化结果

页面读取的站点级结果至少包含：`analysis_location`、`radius_m`、`feed_id`、`feed_captured_at`、`stop_id`、`stop_name`、`lat`、`lon`、`parent_station`、`route_id`、`route_short_name`、`route_type`、`distance_m`、`service_active`。

页面和 ICI 读取的聚合结果至少包含：`nearest_distance_m`、`unique_stop_count`、`stop_density_per_km2`、`unique_route_count`、`distance_score`、`density_percentile`、`route_percentile`、`transit_score`、`availability_status`、`service_outcome`、`stale_warning`。

这些是产品结果契约；不规定 Supabase 表结构或 Flutter 类结构。

## 反例

- 1.5 公里内没有站点：显示有效的零站点观测和“暂不可用”交通分，不显示 0 分冒充评分结果。
- 范围内有站点但没有当前有效服务路线：使用 `no_active_routes`，站点仍可展示，路线数为 0，交通分不可用，并说明服务状态。
- Feed 解析、获取或服务日期范围失败：有其他可用 feed 时使用 `incomplete` 并保留成功部分；没有任何可用 feed 时为 `unavailable`，都不把失败 feed 当作没有交通。
- 列表只有 30 个站点：分数仍使用范围内全部站点，不能把 30 个当作统计上限。
