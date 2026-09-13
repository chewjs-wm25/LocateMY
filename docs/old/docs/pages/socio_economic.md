# 社会经济页（SocioEconomicView）

代码：`lib/modules/module_b/views/socio_economic/socio_economic_view.dart`、
`lib/modules/module_b/view_models/socio_economic/socio_economic_view_model.dart`、
`lib/modules/module_b/repositories/socio_economic/socio_economic_repository.dart`

## 已完成

- 依据地图选择地点解析行政县，查询县级收入、县/州/全国不平等与 HIES 数据。
- 展示收入中位数、B40/M40/T20 估算占比与门槛、地区排名、收入增长和基尼系数。
- 以中位数、均值和官方基尼校准对数正态拟合曲线，并明确标注估算口径。
- 用户输入月收入后计算估算百分位。
- 对县级数据缺失提供州级/全国级回退，支持错误重试。

## 未完成/差异

- B40/M40/T20 占比和分布曲线是模型估算，不是官方个体级收入直方图。
- 没有独立的同州地区对比列表或可切换排行页面。

