# 模型层：HomeDataModel

## 描述
定义首页展示所需的宏观数据实体。

## 数据结构

### MacroEconomicData
- `gdpGrowthRate` (double): 年度 GDP 增长率。
- `cpiTotal` (double): 综合消费者物价指数。
- `cpiCategories` (Map<String, double>): 分类物价指数（食品、住房、交通等）。
- `unemploymentRate` (double): 失业率。
- `medianIncome` (int): 家庭月收入中位数。

### MacroClimateData
- `currentSeason` (String): 当前季节（如 "Southwest Monsoon", "Northeast Monsoon", "Inter-monsoon"）。
- `isHighRiskPeriod` (bool): 是否为水灾高风险期。
- `riskDescription` (String): 风险详细描述。

### HomeViewStateModel
- `macroEconomic`: `MacroEconomicData` 实例。
- `macroClimate`: `MacroClimateData` 实例。
- `overallScore`: 综合得分。
- `recommendation`: 推荐文案。
