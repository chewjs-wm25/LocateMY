# 视图模型层：生活开销组件

## 状态定义
- `originDistrict`：选定的出发地区。
- `destinationDistrict`：选定的目的地地区。
- `userBudget`：基础月度支出。
- `differentialResult`：计算出的购买力变化结果。
- `isLoading`：网络或计算状态的布尔值。

## 命令 / 方法
- `updateOrigin(District district)`：设置出发地并触发部分计算。
- `updateDestination(District district)`：设置目的地并触发完整计算。
- `calculateDifferential(double budget, Map<Category, double> weights)`：计算 $\Delta \text{CoL}$ 的核心逻辑。

## 数据转换
- 将 `PriceCatcher` 数据聚合为类别平均价格。
- 将用户定义的权重应用于 CPI 指数。
