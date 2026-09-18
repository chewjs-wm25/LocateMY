---
kb_id: locatemy-home-outlook-scoring
kind: product-model
language: zh-CN
canonical: true
status: proposed
---

# 首页搬家时机评分模型

## 定位与边界

首页评分回答“从马来西亚全国近期经济、就业和生活成本来看，现在是否较适合搬家”，不判断某个具体地区是否宜居。

- 该分数由 LocateMY 根据官方数据计算，不是政府发布的评级。
- 具体地点的治安、设施、收入、基础设施和交通属于地点分析，不进入全国时机分。
- 家庭收入中位数可作为补充背景，但不参与第一版评分。
- 当前固定 OPR 只能标记为非实时参考值，不参与评分；接入可验证的官方目标利率来源后再评估。
- 本模型是产品设计提案；实现前需以样本回测、异常值检查和产品确认完成验证。

## 数据输入

| 分项 | 数据集 | 主要字段 | 频率 |
| --- | --- | --- | --- |
| 生活成本压力 | `cpi_headline_inflation` | `division`, `inflation_yoy`, `inflation_mom` | 月度 |
| 就业稳定度 | `lfs_month_sa` | `lf_employed`, `u_rate`, `p_rate` | 月度 |
| 经济动能 | `economic_indicators` | `leading`, `leading_diffusion`, `coincident_diffusion` | 月度 |
| 经济动能 | `gdp_qtr_real_sa` | `series`, `value` | 季度 |

Agent 查询前必须到马来西亚政府开放数据知识库检查对应记录的 API 可用性、字段和最新日期，不能把本表当作实时状态。

## 通用计算约定

### 历史百分位

除已经是 0–100 的扩散指数外，指标使用过去五年同频率观测计算百分位：

```text
P(x) = 有效历史观测中小于或等于 x 的数量 / 有效观测总数 × 100
```

- 对数值越低越有利的指标使用 `100 - P(x)`。
- 数据不足五年时可使用全部可用历史，但至少需要 24 个有效月度观测或 8 个有效季度观测。
- 结果限制在 0–100 并四舍五入为整数。
- 百分位表达相对近年历史的位置，不是官方阈值。

### 缺失值

- 分项缺少单个指标时，将剩余权重按比例重新归一化。
- 分项可用权重不足原设计的 60% 时，该分项记为不可用，不以 0 补齐。
- 三个分项有任一个不可用时，不生成综合状态；UI 显示“暂时无法形成可靠判断”，并保留可用分项。

## 生活成本压力分

```text
weightedInflation =
    40% × overallYoY
  + 20% × foodYoY
  + 25% × housingUtilitiesYoY
  + 15% × transportYoY

levelScore = 100 - P(weightedInflation)
change3m = 当前 weightedInflation - 3个月前 weightedInflation
trendScore = 100 - P(change3m)

costScore = 80% × levelScore + 20% × trendScore
```

分类使用 `overall`、`01` 食品与饮料、`04` 住房水电燃气、`07` 交通。趋势文案：

| 三个月变化 | 中文 | English |
| ---: | --- | --- |
| ≤ -0.3 个百分点 | 生活成本压力正在缓解 | Cost pressure is easing |
| -0.3 至 +0.3 | 生活成本压力大致稳定 | Cost pressure is broadly stable |
| ≥ +0.3 个百分点 | 生活成本压力正在加剧 | Cost pressure is increasing |

## 就业稳定度分

```text
unemploymentScore = 100 - P(latestUnemploymentRate)

employmentGrowthYoY =
  (latestEmployed / employed12MonthsAgo - 1) × 100
employmentScore = P(employmentGrowthYoY)

participationChange3m =
  latestParticipationRate - participationRate3MonthsAgo
participationScore = P(participationChange3m)

jobScore =
    50% × unemploymentScore
  + 35% × employmentScore
  + 15% × participationScore
```

当前分数与三个月前按相同方法重算的分数相比：增加至少 5 为改善，变化在 -5 至 +5 为稳定，下降至少 5 为转弱。

## 经济动能分

```text
diffusionScore = clamp(latestLeadingDiffusion, 0, 100)

leadingChange6m =
  (latestLeading / leading6MonthsAgo - 1) × 100
leadingScore = P(leadingChange6m)

gdpScore = P(latestSeasonallyAdjustedGdpGrowth)

economicScore =
    40% × diffusionScore
  + 30% × leadingScore
  + 30% × gdpScore
```

- 分数至少 60，且较三个月前没有下降超过 5：扩张 / Strengthening。
- 分数低于 40，或较三个月前下降至少 10：转弱 / Weakening。
- 其他：平稳 / Broadly stable。

经济指标不能预测突发冲击；UI 禁止使用“保证增长”或“必然好转”等确定性表述。

## 综合分

```text
movingTimingScore =
    37.5% × costScore
  + 31.25% × jobScore
  + 31.25% × economicScore
```

| 分数 | 中文 | English |
| ---: | --- | --- |
| 70–100 | 较适合 | More favorable |
| 45–69 | 建议观望 | Watch closely |
| 0–44 | 暂缓较好 | Consider waiting |

“为什么”摘要按分项对综合分的影响排序，最多显示三条，同时显示各数据日期。

## 首页收藏地点分数

首页不得用全国搬家时机分填充地点分。只有统一地点分析模型完成并生成 `locationFitScore` 与计算时间时才显示整数分数；没有分数、分析不完整或缓存不兼容时显示“未分析 / Not analyzed”。

收藏预览最多两项，按最近访问时间排序；没有访问记录时按保存时间倒序，不按分数排序。

## 刷新与缓存

- 月度与季度经济资料缓存 24 小时。
- 页面先显示最近一次成功缓存，再后台检查更新。
- 手动刷新保持 60 秒限流，按钮和下拉刷新必须使用相同规则。
- 单一来源失败时保留该来源上次成功值并标记日期，不使整页空白。

## 展示限制

- 首页全国概览最多展示四个主要数值、三条原因和一个主要操作。
- 分数必须同时显示名称、状态和数据日期。
- 分数、趋势、风险和缺失不可只通过颜色表达。
- 所有百分比带单位，所有日期按当前语言本地化。
- 页面底部持续显示非官方评分说明。
