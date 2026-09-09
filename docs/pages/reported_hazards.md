# 我的隐患报告（ReportedHazardsScreen）

代码：`lib/modules/module_a/views/map/reported_hazards_screen.dart`、
`lib/modules/module_a/view_models/map/hazard_view_model.dart`、`lib/modules/module_a/repositories/map/map_repository.dart`

## 已完成

- 按当前 Supabase 用户读取 `crowdsourced_hazards`。
- 展示报告类型、标题、描述、时间和投票数量。
- 删除确认并删除远端记录，同时更新全局隐患列表。
- 点击报告后回到地图 Tab 并定位该隐患；支持刷新、加载和空状态。

## 未完成/差异

- 没有编辑已上报隐患的页面/远端更新。
- 投票仅能从地图详情触发，且当前投票没有持久化。
- 没有分页、状态审核、图片证据或举报处理进度。

