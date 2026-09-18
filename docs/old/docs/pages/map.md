# 地图页（MapView）

代码：`lib/modules/module_a/views/map/map_view.dart`、`lib/modules/module_a/view_models/map/location_view_model.dart`、
`lib/modules/module_a/view_models/map/hazard_view_model.dart`、`lib/modules/module_a/repositories/map/map_repository.dart`

## 已完成

- `flutter_map` + OpenStreetMap 瓦片地图、马来西亚范围约束、地图点选。
- 展示模式与双地点比较模式；原点/目的地可来自地图、搜索或收藏地点。
- Geoapify 地名自动补全及搜索。
- 收藏地点本地 SQLite 新增/读取/删除，并尝试同步到
  Supabase `user_saved_regions`。
- 众包隐患显示、开关、详情、创建；写入 `crowdsourced_hazards`。
- 分析报告抽屉可进入生活开销、治安、社会经济、基础设施、周边设施和交通页面。

## 部分完成

- 隐患创建采用乐观更新，失败会回滚；但界面没有独立提交错误提示。
- 收藏采用 local-first；同步只上传未同步项，并非完整的云端到本地双向合并。
- 隐患投票和 `updateHazard` 只修改 Provider 内存，未写回 Supabase。

## 未完成/差异

- 没有旧气候文档描述的历史洪水/实时河流水位图层。
- 没有离线地图瓦片、定位权限/GPS 当前定位流程。

