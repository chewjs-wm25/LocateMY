# 公共交通页（TransportationView）

代码：`lib/modules/module_a/views/transport/transportation_view.dart`、
`lib/modules/module_a/view_models/transport/transit_view_model.dart`、`lib/modules/module_a/repositories/transport/transit_repository.dart`

## 已完成

- 通过 Supabase `transit_stops` 获取选点 1.5km 内最多 30 个站点。
- 客户端 Haversine 距离过滤与排序，展示站名、模式/线路、距离和步行提示。
- 根据站点数量和距离计算连通性评分。
- 地图展示站点，列表和地图可联动选中，并可返回主地图定位。
- 数据为空/失败时提示与重试；同一坐标请求去重。

## 部分完成

- 页面有“热力图”区域，但本质为站点散点/密度表达，不是完整 GIS 热力栅格。
- 交通模式信息来自站点字段，没有独立 GTFS route/trip/frequency 数据链路。

## 未完成/差异

- 旧设计中的“显示路线”、线路几何可视化、班次/运营时间筛选未实现。
- 未使用预打包 GTFS/Spatialite；当前数据源是 Supabase 表。

