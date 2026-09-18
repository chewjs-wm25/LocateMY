# 视图模型层：HomeViewModel

## 职责
`HomeViewModel` 负责聚合来自多个仓库的数据，计算“搬迁综合指数”，并将原始数据转换为 `HomeView` 可直接使用的状态。

## 状态 (State)
- `isLoading`: 是否正在加载数据。
- `movingIndex`: 搬迁综合评分 (0-10)。
- `timingSummary`: 搬迁时机建议文本。
- `economicData`: 包含 GDP、CPI、失业率的模型对象。
- `climateSummary`: 当前季风状态与风险提示。
- `errorMessage`: 错误信息。

## 方法 (Methods)
- `fetchMacroData()`: 调用各仓库方法获取最新数据。
- `calculateMovingIndex()`: 根据物价、失业率和气候数据计算综合得分的私有逻辑。
- `refreshData()`: 强制刷新并更新本地缓存。

## 依赖
- `HomeRepository`: 获取宏观经济与气候聚合数据。
- `ClimateRepository`: 获取当前季节性天气概况。
