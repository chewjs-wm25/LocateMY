---
kb_id: locatemy-infrastructure-index-scoring
kind: product-model
language: zh-CN
canonical: true
status: accepted
---

# 单个地点基础设施指数

## 产品口径

基础设施综合覆盖指数（ICI）衡量地点获得公共服务的相对程度，不评价服务质量、满意度或实际可靠性。地点由坐标确定；供水、供电、医疗和教育使用坐标所属行政区，公共交通使用坐标周围 1.5 公里。

分项分数均为 0–100。分数越高表示相对覆盖越高，不表示官方评级。

## 数据集

| 分项 | 数据集 ID | 类型 | 字段或文件 | 地理口径 |
| --- | --- | --- | --- | --- |
| 供水 | `hh_access_amenities` | `catalogue_dataset` | `state`, `district`, `date`, `piped_water` | 行政区 |
| 供电 | `hh_access_amenities` | `catalogue_dataset` | `state`, `district`, `date`, `electricity` | 行政区 |
| 医疗 | `hospital_beds` | `catalogue_dataset` | `state`, `district`, `date`, `type`, `beds` | 行政区 |
| 医疗分母 | `population_district` | `catalogue_dataset` | `state`, `district`, `date`, `sex`, `age`, `ethnicity`, `population` | 行政区 |
| 教育设施 | `schools_district` | `catalogue_dataset` | `state`, `district`, `date`, `stage`, `type`, `schools` | 行政区 |
| 教育教师 | `teachers_district` | `catalogue_dataset` | `state`, `district`, `date`, `stage`, `sex`, `teachers` | 行政区 |
| 教育学生 | `enrolment_school_district` | `catalogue_dataset` | `state`, `district`, `date`, `stage`, `sex`, `students` | 行政区 |
| 公共交通 | `gtfs_static_ktmb`; `gtfs_static_prasarana_rapid_rail_kl`; `gtfs_static_prasarana_rapid_bus_kl`; `gtfs_static_prasarana_rapid_bus_penang`; `gtfs_static_prasarana_rapid_bus_kuantan`; `gtfs_static_prasarana_rapid_bus_mrtfeeder`; `gtfs_static_mybas_kangar`; `gtfs_static_mybas_alor_setar`; `gtfs_static_mybas_kota_bharu`; `gtfs_static_mybas_kuala_terengganu`; `gtfs_static_mybas_ipoh`; `gtfs_static_mybas_seremban_a`; `gtfs_static_mybas_seremban_b`; `gtfs_static_mybas_melaka`; `gtfs_static_mybas_johor`; `gtfs_static_mybas_kuching` | `realtime_api_resource`，GTFS Static ZIP | `stops.txt`, `routes.txt`, `trips.txt`, `stop_times.txt` | 坐标半径 |

主来源统一使用 `hh_access_amenities`，不以州级 `water_access` 或 `electricity_access` 自动替代行政区记录。GTFS Static 资源不是 Data Catalogue 表，而是马来西亚官方交通 API 的静态 feed。

官方数据页：[hh_access_amenities](https://data.gov.my/data-catalogue/hh_access_amenities)、[hospital_beds](https://data.gov.my/data-catalogue/hospital_beds)、[schools_district](https://data.gov.my/data-catalogue/schools_district)、[population_district](https://data.gov.my/data-catalogue/population_district)。GTFS 入口和文件说明见[官方 GTFS Static API](https://developer.data.gov.my/realtime-api/gtfs-static)。

## 年份与行政区

- 每个数据集使用自身最新有效记录；每个分项显示自己的数据日期。
- `population_district` 优先匹配分项年份；没有同年数据时，使用最近两年内的上一期；再找不到则该分项缺失。
- 人口过滤为 `sex = both`、`age = overall`、`ethnicity = overall`。
- 行政区统计只使用对应 `state`、`district` 记录；`All Districts` 和州合计不与行政区记录混用。
- 坐标无法可靠取得行政区时，行政区分项标记缺失；不使用最近城市或州中心点推断。

## 百分位转换

行政区资源密度使用同一数据年份的全部马来西亚行政区作为参照组。公共交通密度和路线数使用同一 GTFS 评估快照的固定参照组：1 km × 1 km 网格中心必须落在至少一个可用 feed 的服务范围内；网格间距固定，不随用户收藏地点或用户数量改变：

```text
P(x) = 小于或等于 x 的有效参照点数量 ÷ 有效参照点数量 × 100
```

真实数值 `0` 是有效观测。百分位只表示相对位置，不是官方阈值。内部保留完整精度，最终页面分数四舍五入为整数。

## 分项公式

### 供水与供电

`hh_access_amenities` 已提供百分比，直接使用：

```text
供水分 = piped_water
供电分 = electricity
```

### 医疗

医院类型全部纳入；先按县和年份汇总所有 `type` 的床位：

```text
床位密度 = beds ÷ population × 1,000
医疗分 = P(床位密度)
```

该分数表示每千人医院床位的相对水平，不表示就医距离、医生质量或床位可预约性。

### 教育

教育统计包含所有教育阶段和学校类型；教师与学生过滤为 `sex = both`。按官方分类维度汇总，不能把州合计或 `All Districts` 再次计入：

```text
学校密度 = schools ÷ population × 10,000
师生资源 = teachers ÷ students × 100

教育分 = 50% × P(学校密度)
        + 50% × P(师生资源)
```

教育分是设施与人员承载能力的代理指标，不是教育质量评分。

### 公共交通

候选来源为官方列出的全部 16 个 GTFS Static feed：`gtfs_static_ktmb`、5 个 `gtfs_static_prasarana_*` feed 和 10 个 `gtfs_static_mybas_*` feed。同步层可用覆盖登记缩小候选范围，但最终以站点坐标是否落入分析半径为准，不按地点名称猜测城市。GTFS Static 是官方 `realtime_api_resource`，内容为 ZIP，不是 `catalogue_dataset`。

合并 feed 后，同一 feed 内用原始 `stop_id` 去重，跨 feed 用 `feed_id + stop_id` 去重；同名或同坐标站点不自动合并。统计可上下车的站点实体，通常是 `stops.txt` 中 `location_type = 0` 的记录；有 `parent_station` 时可在列表中分组，但仍按子站点计数。路线唯一键为 `feed_id + route_id`，不能按跨 feed 的 `route_short_name` 合并。

路线必须通过 `routes.txt → trips.txt → stop_times.txt` 关联到范围内站点，并且服务日期在 `calendar.txt` / `calendar_dates.txt` 中有效，才计入有效路线数。站点可以在没有当前有效路线时继续展示；此时 `route_count = 0` 是已知的零路线观测，交通分项不可用，不按公式计算低分。

只统计坐标周围 1.5 公里内的站点：

```text
距离分 = 100 × (1 − 最近站距离 ÷ 1,500)
站点密度 = 范围内唯一站点数 ÷ (π × 1.5²)
路线数量 = 范围内有实际有效服务站点的唯一 route 数

交通分 = 50% × 距离分
        + 25% × P(站点密度)
        + 25% × P(路线数量)
```

距离使用分析坐标到站点坐标的直线距离，单位为米；密度单位为站点/平方公里。距离分限制在 0–100，内部保留完整精度，页面最终四舍五入为整数。1.5 公里边界内存在站点但距离分为 0，是有效结果；没有边界内站点时站点数可以显示为有效的 0，但交通分为“暂不可用”，不能用 0 分冒充缺失结果。范围内有站点但 `route_count = 0` 时同样显示交通分“暂不可用”，不能用路线百分位计算低分。交通百分位使用同一 GTFS 评估快照的固定 1 km 网格参照组。

每个 feed 保存 `feed_captured_at`，页面显示 feed 采集时间和本次刷新时间。资料新鲜度、服务日期范围、availability、service outcome 与 stale warning 的判定以[公共交通功能事实源](features/transportation.md#数据处理边界)为唯一权威；解析失败或预期 feed 未取得时，站点结果可以保留已成功部分，但交通分按该唯一矩阵处理。刷新失败时依该唯一规则保留上一次成功结果；从未成功取得结果时显示“暂不可用”。

## 综合指数与优先级

五个分项基础权重均为 `0.20`。医疗、教育和公共交通滑块取值 1–10，权重乘数为：

```text
priority_multiplier = slider_level ÷ 5
```

因此 5 为中性，1 为 `0.2` 倍，10 为 `2.0` 倍。供水和供电乘数固定为 `1.0`。调整后：

```text
adjusted_weight_i = 0.20 × priority_multiplier_i

ICI = Σ(score_i × adjusted_weight_i)
      ÷ Σ(adjusted_weight_i)
```

个人化地点适配度引用 ICI 时，医疗、教育和公共交通的 ICI 优先级固定为中性值 5；账户五项评估偏好只用于适配度总分，不再叠加到 ICI 内部。

缺失分项不进入分子或分母，剩余分项按调整后权重重新归一化。以调整前基础权重判断，可用分项基础权重少于总权重的 60%（少于 3/5 个分项）时，ICI 显示“暂不可用”。

分项内部任一必要组成指标缺失时，整个分项缺失；不在分项内部用 0 补齐。没有记录表示未知，只有明确数值 `0` 才表示数量为零。

## 展示等级与限制

```text
0–39    较弱
40–59   一般
60–79   良好
80–100  很好
```

页面同时显示：地点行政区、每个分项数据日期、综合指数等级、缺失分项和人口年份错配提示。该指数不能比较服务质量，也不能证明某项服务在用户需要的时间可用。
