# 治安与犯罪页（CrimeSecurityView）

代码：`lib/modules/module_b/views/security/crime_security_view.dart`、
`lib/modules/module_b/view_models/security/security_view_model.dart`、`lib/modules/module_b/repositories/security/security_repository.dart`

## 已完成

- 使用坐标调用 `match_police_district`，取得警区后查询 `crime_stats`。
- 展示安全分数、历史犯罪趋势和类别结构。
- 迷你地图加载 `police_districts_boundary`，可切换警区边界与隐患点。
- 隐患点详情、错误重试、返回主地图定位。
- 房产检查的新增、档案和最近房产入口。

## 部分完成

- 地图支持缩放与图层开关，但不是按缩放级别加载更高分辨率边界。
- 数据按案件数形成页面指标；人口归一化/每十万人犯罪率并未形成完整链路。

## 未完成/差异

- 文档描述的“暴力/财产犯罪”交互筛选未实现。
- 折线图数据点没有明确的点击/悬停详情交互。

