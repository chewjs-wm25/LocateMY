# 视图模型层：基础设施组件

## 状态定义
- `iciIndex`：最终计算出的指数分数。
- `componentScores`：各项指标得分的映射（水、电、医疗、教育）。
- `userWeights`：用户设置的权重映射。

## 命令 / 方法
- `loadInfrastructureData(String districtId)`：获取公共设施、医疗及学校数据。
- `updateWeights(Map<String, double> newWeights)`：重新计算 ICI 分数。

## 数据转换
- **ICI 建模**：实现归一化指标的加权求和（极差标准化/Min-Max Normalization）。
- 将“医疗床位”和“师生比”归一化为 0-100 标度。
