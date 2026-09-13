# 首页（HomeScreen）

代码：`lib/modules/module_a/views/home/home_screen.dart`、`lib/modules/module_a/view_models/home/home_view_model.dart`、
`lib/modules/module_a/repositories/home/home_repository.dart`

## 已完成

- 展示失业率、家庭收入中位数、CPI 通胀、OPR、GDP 历史趋势。
- 基于宏观指标计算并展示搬迁指数和建议；ICI 缺失时展示降级提示。
- 首次加载、失败重试、手动强制刷新和 1 分钟刷新限流。
- 点击“开始探索”切换到地图 Tab。
- Repository 从 Supabase 多表聚合数据，并通过 SQLite `cached_reports`
  缓存 `HomeStats`。

## 未完成/差异

- 旧设计中的独立气候/季风预警卡片未实现。
- CPI 分类分布图、指标卡片下钻未实现。
- 当前 OPR 是模型/页面字段，但 Repository 使用固定参考值，不是实时 OPR 数据源。
- 页面不是下拉刷新，刷新入口位于 AppBar 和失败态按钮。

