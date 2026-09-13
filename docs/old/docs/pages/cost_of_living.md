# 生活开销页（CostOfLivingView）

代码：`lib/modules/module_b/views/cost_of_living/cost_of_living_view.dart`、
`lib/modules/module_b/view_models/cost_of_living/budget_view_model.dart`、`lib/modules/module_b/repositories/cost_of_living/cost_of_living_repository.dart`

## 已完成

- 根据地图单点或比较模式确定原地区与目标地区。
- 从 `cpi_state` 与 `get_district_prices` RPC 获取 CPI/PriceCatcher 聚合数据。
- 展示购买力变化、等效预算、微观商品均价与分类支出对比图。
- 预算输入后实时换算目标预算。
- `user_budget_scenarios` 预案读取、新建、选择、重命名和删除。
- 加载、空数据、错误和强制重试状态。

## 部分完成

- Provider 已有预算金额更新方法，但当前页面没有调用；页面只完成预案名称层面的新增、读取、改名和删除。
- 微观价格展示为地区聚合结果，没有逐商家来源详情。

## 未完成/差异

- “查看商家”按钮当前为空回调。
- 用户输入的预算换算只保留在页面局部状态，不会保存回当前预案。
- 5km 地理围栏、商家列表、食品类别点击下钻未实现。
- “独居/家庭/买房 vs 租房”模板与跨预案并排比较未实现。
- 雷达图、盈余仪表盘、滑动后自动平衡其他类别未实现。
