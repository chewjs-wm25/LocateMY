---
kb_id: feature-socio-economic
kind: feature-spec
capabilities: [SOCIO-01, SOCIO-02, SOCIO-03]
tags: [income, inequality, socio-economic, malaysia-open-data]
---

# 社会经济

## 已确认的产品口径

- 页面不生成综合“社会经济指数”。收入中位数、收入结构、基尼系数和收入分布是相互独立的读数。
- 地点先解析为 `state + administrative district`。行政区数据优先；无法匹配行政区时，相关读数可退回州级数据，并在卡片上标明统计层级。
- 每个指标独立处理缺失。一个指标缺失时，其他指标仍可显示；缺失卡片显示“暂无数据”和原因。
- 使用 DOSM 名义金额，显示统计年份，并注明未按通胀调整。不与 CPI 拼接换算实际购买力。

## 数据集

以下数据集均为 DOSM 的 `catalogue_dataset`，频率为 `YEARLY`，可使用 OpenDOSM API。接口路径为 `GET https://api.data.gov.my/opendosm?id={id}`；CSV/Parquet 下载地址见对应 OpenDOSM 页面。

| 用途 | ID | 层级 | 字段 |
|---|---|---|---|
| 行政区家庭收入中位数、均值 | `hh_income_district` | 行政区 | `state`、`district`、`date`、`income_mean`、`income_median` |
| 行政区基尼系数 | `hh_inequality_district` | 行政区 | `state`、`district`、`date`、`gini` |
| 州级收入中位数、均值回退 | `hh_income_state` | 州 | `state`、`date`、`income_mean`、`income_median` |
| 州级基尼系数回退 | `hh_inequality_state` | 州 | `state`、`date`、`gini` |
| 州级 B40/M40/T20 与收入分布 | `hies_state_percentile` | 州、百分位 | `date`、`state`、`percentile`、`variable`、`income` |

字段类型以 DOSM 字段说明为准：`date` 为日期，`state`/`district`/`variable` 为分类值，`percentile` 为整数，收入字段为 RM 整数，`gini` 为浮点数。

`hies_district` 不纳入实现，也不作为交叉核对来源。它不是本页面的主数据源。

## 家庭收入中位数

1. 用地点的行政区名称匹配 `hh_income_district.district`，并同时校验 `state`。
2. 取所选统计年份的 `income_median`，单位为 RM/月。
3. 行政区无法匹配时，使用 `hh_income_state.income_median`，卡片标记为“州级参考”。
4. 优先选择与其他社会经济读数相同的年份；没有共同年份时，保留各自年份并提示“统计年份不同，不宜直接比较”。

该字段是 HIES 的家庭月度总收入中位数，不是个人工资中位数，也不是税后收入。

## 地区收入结构

行政区没有官方百分位分布，因此使用地点所属州的 `hies_state_percentile` 作为“州级参考”。只保留 `variable = mean`、`minimum` 或 `maximum` 的相应记录，并按同一 `date` 和 `state` 筛选。

分组定义：

- B40：`percentile ∈ [1, 40]`
- M40：`percentile ∈ [41, 80]`
- T20：`percentile ∈ [81, 100]`

公式：

```text
B40 门槛 = maximum(P40)
M40 门槛 = maximum(P80)

组内平均收入(G) = average(mean(Pk)), k 属于 G
组收入份额(G) = sum(mean(Pk)), k 属于 G
                  --------------------------------
                  sum(mean(P1..P100))
```

百分位组是等量家庭组，因此以各百分位 `mean` 的算术平均和总和估算组均值及收入份额。页面必须标注“州级参考、由百分位数据推导”，不能称为行政区官方 B40/M40/T20。

## 家庭月收入分布图

使用 `hies_state_percentile` 中 `variable = median` 的记录：

- X 轴：`percentile`，P1–P100。
- Y 轴：该百分位组内的家庭月收入中位数 `income`，单位 RM/月。
- 在 P50 处标记州级中位数参考。
- 连接真实观测点，不做插值或平滑。
- P1 的 `minimum` 和 P100 的 `maximum` 因官方可识别性处理可能为空；这些字段不用于本曲线，也不补零。

图表标题和说明必须写明“州级收入分布参考”，不能写成当前行政区的官方收入分布。

## 基尼系数

- 行政区优先取 `hh_inequality_district.gini`；无法匹配行政区时取 `hh_inequality_state.gini`。
- 原样显示 0–1；数值越高表示家庭收入不平等程度越高。
- 同比变化使用绝对差：`ΔGini = 本年 Gini − 上年 Gini`。例如从 `0.42` 到 `0.40` 显示“下降 0.02”。
- 不将基尼转换为 0–100 分，也不纳入综合社会经济指数。

## 用户收入位置（SOCIO-02）

- 用户输入是当前评估预案中已保存的家庭月度总收入，单位为名义 RM/月；该输入不是个人工资、不是月净收入，也不用于官方阶层判定。
- 使用地点所属州的 `hies_state_percentile`，筛选最新完整统计年份及 `variable = median`。在相邻真实百分位收入点之间做线性插值；恰好命中观测点时使用该百分位。
- 低于 P1 显示“低于 P1”，高于 P100 显示“高于 P100”，不把边界外输入强行截为 P1 或 P100。
- 无法匹配州、缺少完整州级分布或没有可用年份时，用户收入位置显示“暂不可用”。
- 页面持续标注“州级参考估算”；用户输入结果与官方收入、基尼和州级分布在视觉上分组。
- 家庭月度总收入保存为当前账户评估预案的私有字段，用户可编辑和删除；没有 current 预案或该字段缺失时，收入位置不可用，不用月净收入替代。

## 年份、缺失与文案

- 所有数据均保留 DOSM 原始统计年份；不把不同年份拼成一个无年份的读数。
- 行政区层级没有数据时，只有明确的州级回退读数可以使用；不使用附近行政区、最近地点或空间插值替代行政区官方读数。SOCIO-02 的州级百分位估算按本文件专门定义的收入点插值规则处理。
- 缺失值保持缺失，不用 0 填补。
- 所有金额显示“名义 RM/月、未按通胀调整”。
- 官方统计与推导估算分开标注：行政区收入/基尼可标为官方统计；州级 B40/M40/T20 和分布图标为州级参考估算。

## 当前原型与重开发边界

当前 Flutter 页面仍使用硬编码示例值，尚未连接上述数据服务。用户收入位置的领域函数会对本地 fixture 的相邻百分位点做线性插值；页面尾注曾写成“不使用插值”，该文案与已确认规则不一致，不能据此改变本节的插值定义。重开发时应移除示例收入、基尼和结构比例；保留单点行政区分析、州级参考分布和逐项缺失状态。

地点 A/B 的社会经济总览和详情当前也使用固定示例收入与基尼读数，未从两地单点分析结果读取；这些值只能作为页面结构 fixture，不能视为两个地点的官方比较结果。

## 官方来源

- [hh_income_district](https://open.dosm.gov.my/data-catalogue/hh_income_district)
- [hh_inequality_district](https://open.dosm.gov.my/data-catalogue/hh_inequality_district)
- [hh_income_state](https://open.dosm.gov.my/data-catalogue/hh_income_state)
- [hh_inequality_state](https://open.dosm.gov.my/data-catalogue/hh_inequality_state)
- [hies_state_percentile](https://open.dosm.gov.my/data-catalogue/hies_state_percentile)
