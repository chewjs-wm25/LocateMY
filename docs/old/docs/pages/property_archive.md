# 房产档案与详情页

代码：`lib/modules/module_b/views/property/property_archive_screen.dart`、
`lib/modules/module_b/views/property/property_detail_screen.dart`

## 已完成

- 档案列表展示房产名称、地址、价格、评级、更新时间和风险摘要。
- 进入详情查看完整检查结果；从详情进入编辑。
- 单条软删除进入回收站。
- 档案页进入多选模式，选择 2–3 个房产后进入对比页。

## 部分完成

- CRUD、回收站和样例数据都工作在 `PropertyViewModel` 内存列表中。
- 风险上下文新增时来自 Supabase，但已保存房产本身不持久化。

## 未完成/差异

- 没有账户级同步、筛选、排序、搜索和导出。
- 应用重启后用户新增/修改/删除状态不会保留。

