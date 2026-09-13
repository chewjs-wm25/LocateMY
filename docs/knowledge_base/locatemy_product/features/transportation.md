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

## 数据处理边界

- 候选来源为官方列出的全部 16 个 GTFS Static feed；系统可用覆盖登记缩小候选范围，但最终以站点坐标是否落入 1.5 公里为准，不按地点名称猜测城市。
- 路线必须通过 `routes.txt → trips.txt → stop_times.txt` 关联到范围内站点，并且服务日期在 `calendar.txt` / `calendar_dates.txt` 中有效，才计入有效路线数。
- GTFS ZIP 的下载、解析、去重、有效日期判断和评分由维护者在手动数据准备中完成；Flutter 读取 Supabase 的标准化只读结果。当前不实现自动同步。
- 每个 feed 保存 `feed_captured_at`；页面显示 feed 采集时间和本次刷新时间，不伪造统一统计日期。
- Feed 可读取但长时间未刷新时仍可展示，并标记“可能过期”；解析失败或预期 feed 未取得时，页面标记资料不完整。
- 某地点有预期 feed 获取失败时，可展示已成功取得的站点，但交通分显示“暂不可用”，不能把失败 feed 当作没有交通。
- 从未成功取得结果时显示“暂不可用”；刷新失败时保留上一次结果并标记可能过期。

### 交通可用状态

- `no_active_routes` 表示站点结果完整、但分析日期没有有效服务路线：站点继续展示，`unique_route_count = 0`，交通分不可用，并显示“有站点，但分析日期没有有效服务路线”。这是已知的零路线观测，不是 feed 失败。
- `incomplete` 表示 feed 下载、解析或预期 feed 获取失败：可保留已成功取得的站点，但交通分不可用，并显示“资料不完整，无法生成完整交通分”。
- `stale` 表示上一次成功结果仍可读取但已长时间未刷新；保留原交通分并标记“可能过期”。
- `no_stops` 表示范围内没有已取得站点：站点数为有效的 0，交通分不可用。

## 标准化结果

页面读取的站点级结果至少包含：`analysis_location`、`radius_m`、`feed_id`、`feed_captured_at`、`stop_id`、`stop_name`、`lat`、`lon`、`parent_station`、`route_id`、`route_short_name`、`route_type`、`distance_m`、`service_active`。

页面和 ICI 读取的聚合结果至少包含：`nearest_distance_m`、`unique_stop_count`、`stop_density_per_km2`、`unique_route_count`、`distance_score`、`density_percentile`、`route_percentile`、`transit_score`、`availability_status`。

这些是产品结果契约；不规定 Supabase 表结构或 Flutter 类结构。

## 反例

- 1.5 公里内没有站点：显示有效的零站点观测和“暂不可用”交通分，不显示 0 分冒充评分结果。
- 范围内有站点但没有当前有效服务路线：使用 `no_active_routes`，站点仍可展示，路线数为 0，交通分不可用，并说明服务状态。
- Feed 解析或获取失败：使用 `incomplete`，保留已成功部分，但不把失败 feed 当作没有交通。
- 列表只有 30 个站点：分数仍使用范围内全部站点，不能把 30 个当作统计上限。
