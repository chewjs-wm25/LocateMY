---
kb_id: feature-cost-of-living
kind: feature-spec
capabilities: [COST-01, COST-02, COST-03, COST-04]
tags: [cost, budget, cpi, prices]
---

# 生活成本与预算

## 当前原型功能

- 当前原型提供单点生活成本报告和地点 A/B 生活成本比较；单点报告使用选中地点，比较页并列地点 A/B。
- 当前原型展示固定示例的生活成本指数、统一生活篮子、预算场景和预算压力；尚未接入真实数据服务。
- 当前原型的地点比较可展示同名商品价格对照，数据和金额为 fixture。
- 当前 `CostReport` 以每个地点的一组 fixture 单价乘以篮子数量，再加住房和交通输入；它没有执行下方 canonical 模型所要求的逐商户中位数、逐月平均和实际缺失月份聚合。`merchantCount`、`recordCount` 和 `months` 只是审查展示字段。
- 单项价格是商品单位价格（例如每 5 kg、每 10 粒或每份），不是 RM/月；当前原型价格行将其统一显示为 `/月`，这是待修正的单位文案，不是产品口径。

## 当前原型的临时预算换算

- 当没有可用预案金额时，购买力卡显示“当前月支出”输入框。
- 输入后只更新该卡片的等效预算。
- 输入不会改写当前预算预案或整页比较结果，离开页面即丢失。
- 当有预案时，页面直接使用预案中最高租金、生活开销和交通津贴的合计，不显示临时输入框。

## 预算预案

- 远端字段：预案标识、名称、最高租金、生活开销、交通津贴和更新时间。
- 支持读取、新建、选择、重命名和删除。
- 重开发预案字段统一为生活篮子调整、住房支出、交通支出和月净收入；当前原型的预案选择和编辑仍不完整。
- 当前 UI 的新建/重命名只处理名称，没有空名称校验。
- 只剩一个预案时隐藏删除按钮。
- 删除当前预案后选择列表第一项。
- 当前选择只在内存；切换预案后已有比较结果可能不立即重算。

## 商品和商家

- 商品列表无点击交互。
- “View Stores / 查看商家”按钮为空回调。

## 数据边界

- 预算预案是远端账号数据。
- 公共价格比较可在本机缓存约 3 天。
- 临时预算输入是页面内存。

## 重开发要求

- 单点生活成本报告只分析当前地点：展示本地价格、统一生活篮子的估算月支出，以及相对于固定基准的生活成本指数；指数不得暗指另一个用户选定地点。
- 有当前评估预案时，在单点报告中额外展示该地点的预算压力；没有预案时仍展示成本报告，并明确预算压力尚不可计算及其设置入口。不以临时输入或默认金额制造预算结果。
- 两地地点对比把生活成本作为六类分析之一：以相同口径并列两个地点的单点结果，资料可比时才显示差异；可在详情保留同名商品价格对照。
- 预算预案的编辑、保存与切换必须统一；切换后所有依赖预案的预算压力和个人化地点适配度立即重算。
- 当前评估预案必须能表达统一篮子调整、住房支出、交通支出和月净收入；这些输入缺失时，按单点生活成本模型显示相应的不可用状态。
- 必须保留不保存的“当前月支出”CPI 等效预算换算器，以兑现[大学提交承诺基线](../submission_commitments.md)；它只服务等效换算，预算压力和个人化地点适配度仍只使用当前评估预案。
- 预案名称必须校验。
- 账户保存一份当前评估预案；它是预算压力和个人化地点适配度的必要输入。
- “查看商家”与商品下钻（`COST-04`）归类为 `excluded`，本次不实现，也不显示入口。

## 已确认的单点生活成本模型

以下模型用于“完整分析（单个地点）”中的生活成本部分。它服务个人预算估算，不把结果包装成官方生活成本统计。

### 结果与默认场景

- 默认对象是单身成年人 1 人；用户可调整商品数量或频次。数量属于产品假设，并按篮子版本保存。
- 标准篮子覆盖食品、住房、水电燃气与通信、交通、医疗、教育/托育、个人用品与服务、休闲/其他。
- 储蓄、保险、税费和债务还款不属于标准篮子，只作为用户额外预算项。
- 住房与交通不提供公共数据默认值，必须由用户输入月度金额，或明确选择 RM 0；“未填写”与 RM 0 分开。
- 地点间比较时，住房和交通输入沿用同一预算场景。若每个地点输入不同金额，结果只能解释为个人化场景结果，不能解释为纯地点价格差异。
- 所有结果拆分标示为“官方观测”“模型假设”或“用户输入”。

### 核心公式

#### 本地价格

先用 `item_code` 和 `premise_code` 连接商品、商户地点维表。对地点 `d`、商品 `i`、月份 `t`，仅在商品单位一致时计算：

```text
p(i,d,t) = median over premises d {
             median over observations at that premise {
               price(i, premise, t)
             }
           }
```

先求每个商户的中位数，再求商户中位数，避免采集次数较多的商户主导结果。每项同时记录观测商户数、原始记录数和实际数据月份。

行政区当月缺少商品价格时，直接从篮子中删除该商品；不以 RM 0、最近月份、州价或全国价替代，也不把删项后的金额称为完整月支出。

#### 统一生活篮子估算月支出

令 `q(i)` 为产品定义或用户调整后的单身成年人月数量，`A(d,t)` 为地点该月有有效价格的商品集合，`H` 与 `T` 为用户输入的住房和交通月支出。先计算市场观测部分：

```text
ObservedSpend(d,t) = Σ[i ∈ A(d,t)] q(i) × p(i,d,t)
```

只有 `H` 与 `T` 都已填写或明确为 RM 0 时，才将它们加入预算场景：

```text
ScenarioSpend(d,t) = ObservedSpend(d,t) + H + T
```

若住房或交通未填写，只展示 `ObservedSpend` 及其缺失输入状态，不把缺失输入当作 0。

在最近 12 个月窗口内，先逐月计算，再对可用月份取平均：

```text
ObservedSpend12(d) = average of ObservedSpend(d,t)
                     over available months in the 12-month window

ScenarioSpend12(d) = average of ScenarioSpend(d,t)
                     over available months in the 12-month window
```

住房与交通输入存在、且满足数据质量门槛时，`ScenarioSpend12` 才可展示为完整的“估算月支出”；否则展示 `ObservedSpend12`、缺失项目、缺失输入和覆盖率。

#### 篮子覆盖率与指数可用性

当住房与交通输入存在但数据质量门槛不满足时，仍展示部分篮子金额和覆盖率，但不展示完整总指数，并将预算压力标为不可计算；不能以部分篮子金额计算个人预算压力或其适配度成本转换分。

使用全国基准篮子中各商品的基准预算份额 `w(i)` 计算 12 个月平均覆盖率：

```text
Coverage(d) = average over t {
                Σ[i ∈ A(d,t)] w(i)
              }
```

完整总指数的前提是：

- 12 个月窗口内至少有 6 个月可用观测；
- 平均篮子覆盖率至少 80%；
- 住房与交通输入均已存在（明确为 RM 0 也算存在）。

不满足时仍显示部分篮子金额和覆盖率，但不显示完整总指数。不能通过放大剩余项目权重或以零填补缺失来制造完整指数。

全国基准使用同一篮子数量 `q(i)` 与全国 PriceCatcher 代表价格；固定基准篮子金额为 `BaseSpend12`：

```text
CostIndex(d) = 100 × ScenarioSpend12(d) / BaseSpend12
```

指数 100 表示与全国单身成年人基准篮子相同；大于 100 表示相对更贵，小于 100 表示相对更便宜。指数是辅助读数，RM/月是主结果；指数不是官方 CPI，也不是政府评级。

#### 预算压力

个人预算压力及其适配度成本转换分仅在 `ScenarioSpend12` 满足完整数据质量门槛、住房与交通输入已存在且用户月净收入已填写时计算；生活篮子月份不足 6 个月或平均覆盖率低于 80% 时，明确显示预算压力不可计算，不使用部分篮子金额代替。

地点基线与用户个人压力分开呈现：

```text
LocationBudgetBurden(%) =
100 × ScenarioSpend12(d) / district_household_income_median_monthly

PersonalBudgetBurden(%) =
  100 × ScenarioSpend12(d) / user_monthly_net_income
```

`district_household_income_median_monthly` 必须按官方元数据的金额单位归一化；不能因为 `date` 按年度发布就自动把收入除以 12，也不能把年度调查日期解释成月度实时收入。

地点基线优先使用行政区家庭收入中位数；用户个人压力使用预算场景中的月净收入。没有用户收入时不计算个人压力，不用家庭收入中位数冒充个人收入。预算压力显示连续百分比，不自行设置低/中/高等级。

### 马来西亚开放数据集映射

核心数据链路及其可承担的产品职责如下。数据集 ID 以官方目录为准；资源通常为 CSV/Parquet，是否提供 Open API 以官方页面当前说明为准。

| 产品用途 | 官方数据集 ID | 类型与粒度 | 关键字段/说明 |
| --- | --- | --- | --- |
| 商品本地价格 | [`pricecatcher`](https://data.gov.my/data-catalogue/pricecatcher) | `catalogue_dataset`；商品交易表；按月文件，日采集；CSV/Parquet；无 Open API | `date`, `premise_code`, `item_code`, `price` |
| 商品名称、单位、分类 | [`lookup_item`](https://data.gov.my/data-catalogue/lookup_item) | `catalogue_dataset`；静态商品维表；CSV/Parquet | `item_code`, `item`, `unit`, `item_group`, `item_category` |
| 商户到地点映射 | [`lookup_premise`](https://data.gov.my/data-catalogue/lookup_premise) | `catalogue_dataset`；静态商户/地点维表；含行政区与州；CSV/Parquet | `premise_code`, `premise`, `address`, `premise_type`, `state`, `district` |
| 州级 CPI 水平与分类趋势 | [`cpi_state`](https://data.gov.my/data-catalogue/cpi_state) | `catalogue_dataset`；州级、月度 CPI 面板；CSV/Parquet；Open API | `state`, `date`, `division`, `index` |
| 州级 CPI 通胀变化 | [`cpi_state_inflation`](https://data.gov.my/data-catalogue/cpi_state_inflation) | `catalogue_dataset`；州级、月度变化率；CSV/Parquet；Open API | `state`, `date`, `division`, `inflation_yoy`, `inflation_mom` |
| 行政区支付能力基线 | [`hh_income_district`](https://data.gov.my/data-catalogue/hh_income_district) | `catalogue_dataset`；行政区、年度发布的家庭收入汇总；CSV/Parquet；Open API | `state`, `district`, `date`, `income_mean`, `income_median` |
| 行政区家庭支出背景 | [`hies_district`](https://data.gov.my/data-catalogue/hies_district) | `catalogue_dataset`；行政区 HIES 调查汇总；CSV/Parquet；Open API | `date`, `state`, `district`, `income_mean`, `income_median`, `expenditure_mean`, `gini`, `poverty` |
| 州级收入降级/背景 | [`hh_income_state`](https://data.gov.my/data-catalogue/hh_income_state) | `catalogue_dataset`；州级、年度发布的家庭收入汇总；CSV/Parquet；Open API | `state`, `date`, `income_mean`, `income_median` |
| 燃油参考 | [`fuelprice`](https://data.gov.my/data-catalogue/fuelprice) | `catalogue_dataset`；全国/半岛与东马、周度时间序列；CSV/Parquet；Open API | `series_type`, `date`, `ron95`, `ron97`, `diesel`, `diesel_eastmsia` |
| 分类辅助 | [`mcoicop`](https://data.gov.my/data-catalogue/mcoicop) | `catalogue_dataset`；静态 COICOP 分类维表 | `digits`, `division`, `group`, `class`, `subclass`, `desc_en`, `desc_bm` |

可选的全国/城乡趋势辅助数据包括 [`cpi_3d`](https://data.gov.my/data-catalogue/cpi_3d)、[`cpi_4d`](https://data.gov.my/data-catalogue/cpi_4d)、[`cpi_5d`](https://data.gov.my/data-catalogue/cpi_5d) 与 [`cpi_strata`](https://data.gov.my/data-catalogue/cpi_strata)。它们只能辅助解释价格趋势，不能直接生成 RM/月 的完整生活篮子。

### 数据边界与不可误判项

- 目前没有发现官方行政区 CPI；`cpi_state` 与 `cpi_state_inflation` 是州级数据，不能标作行政区 CPI。
- 官方目录没有完整公开单身生活篮子的商品数量 `q(i)`，也没有完整地点级租金或公共交通票价；这些部分来自模型假设或用户输入。
- `hies_district.expenditure_mean` 是官方家庭月均支出背景值，不是 LocateMY 的统一篮子支出，不能直接替代 `ScenarioSpend12` 或 `ObservedSpend12`。
- `fuelprice` 只提供燃油价格，Q6-B 选定后不用于生成住房/交通默认值。
- `lookup_item` 与 `mcoicop` 没有确认的直接连接键；分类映射若使用，必须作为人工规则并单独标记。
- `hies_district` 页面截至年份不等于每年都有连续调查观测；应保存调查年份并按实际可用日期展示。
- `pricecatcher` 的数据日期以同步到的实际最大 `date` 为准，历史目录快照中的结束日期不作为当前数据判断。
