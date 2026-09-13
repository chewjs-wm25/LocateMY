# 基础设施页（InfrastructureView）

代码：`lib/modules/module_a/views/infrastructure/infrastructure_view.dart`、
`lib/modules/module_a/view_models/infrastructure/infrastructure_view_model.dart`、
`lib/modules/module_a/repositories/infrastructure/infrastructure_repository.dart`

## 已完成

- 解析地区后聚合供水、供电、医疗床位、人口、教师和学生数据。
- 展示 ICI 综合分数和水、电、医疗、教育分项分数。
- 坐标可用时纳入交通分数；缺失项按公平口径计分。
- 医疗、教育、交通/商业便利三项权重滑块可实时重算 ICI。
- 缓存、缺失数据说明和错误重试。

## 部分完成

- 供水、供电权重存在于 Provider，但页面未提供对应滑块。
- 页面以分项卡和进度表现为主，并非旧设计所述雷达图。

## 未完成/差异

- 卫生设施虽在原始数据中读取，但当前未作为独立 UI 分项或权重显示。
- 没有服务类型的交互式状态切换。

