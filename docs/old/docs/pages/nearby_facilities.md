# 周边设施页（NearbyFacilitiesView）

代码：`lib/modules/module_a/views/infrastructure/nearby_facilities_view.dart`、
`lib/modules/module_a/view_models/infrastructure/nearby_facilities_view_model.dart`、`lib/modules/module_a/repositories/infrastructure/facility_repository.dart`

## 已完成

- 对地图选点调用 OpenStreetMap Overpass API，查询 2km 半径内 POI。
- 分类展示医疗、教育、生活、交通、安全服务、休闲绿地和风险设施。
- 展示总点数、覆盖类别数、最近距离及每类最多三个示例。
- 同一坐标请求去重；地点变化清空旧数据；失败重试和空结果提示。
- 对 Overpass 超时、限流、服务不可用和响应解析异常提供用户可读错误。

## 未完成/差异

- 没有设施详情页、路线规划、营业时间/评分筛选。
- 结果只保存在 Provider 会话内，没有 SQLite 持久缓存。

