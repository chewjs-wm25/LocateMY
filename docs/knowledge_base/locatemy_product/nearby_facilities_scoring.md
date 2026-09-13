---
kb_id: locatemy-nearby-facilities-coverage
kind: product-model
language: zh-CN
canonical: true
status: accepted
---

# 单个地点周边设施覆盖

## 产品口径

本页回答“分析点 2 公里内有哪些已收录设施”，不生成 0–100 综合指数，也不评价设施质量、营业状态或政府服务水平。

分析范围是以用户选定坐标为中心的 2,000 米直线半径。距离使用 Haversine 公式；矩形范围只用于查询预筛选，最终必须再次按圆形距离过滤。

```text
d = Haversine(分析点, 设施代表点)
纳入结果 ⇔ d ≤ 2,000 米
```

## 设施分类

每个 OSM 对象只归入一个产品类别。归属优先级为：医疗健康 → 教育资源 → 交通出行 → 日常生活 → 休闲与绿地。药房只计入医疗健康。

| 类别 | OSM 标签范围 |
| --- | --- |
| 医疗健康 | `amenity=hospital/clinic/doctors/dentist/pharmacy` |
| 教育资源 | `amenity=school/college/university/kindergarten/childcare` |
| 日常生活 | `shop=supermarket/convenience`；`amenity=marketplace/bank/atm/fuel` |
| 交通出行 | `highway=bus_stop`；`public_transport=platform/station/stop_position`；`railway=station/halt/tram_stop`；`amenity=ferry_terminal/charging_station` |
| 休闲与绿地 | `leisure=park/garden/playground/sports_centre/fitness_centre` |

标签范围是产品的最小稳定映射。用户界面显示中文类型，不显示原始 OSM 标签。

## 结果公式与状态

对类别 `c`，令 `T_c` 为该类别标签集合，`rep(e)` 为设施代表点：Node 使用自身坐标，Way/Relation 使用查询返回的代表中心点。

```text
E_c = { e | e 匹配 T_c，且 Haversine(分析点, rep(e)) ≤ 2,000 米 }
N_c = |E_c|
最近距离_c = min(Haversine(分析点, rep(e)))，e ∈ E_c
```

查询返回 Node、Way、Relation；唯一键为 `element_type + osm_id`。同一 OSM 对象只计一次，不把面边界节点另算为设施。列表按直线距离由近到远，显示最近 3 条。

类别状态：

- `N_c > 0` 且查询完整：已覆盖；
- `N_c = 0` 且查询完整：范围内暂无已收录设施；
- 查询失败、超时或结果完整性无法确认：未知；
- 未知不计为未覆盖，也不以 0 代替。

页面可以显示总设施数和“有记录类别数/5”作为数量摘要，但不得把它命名为指数或分数；存在未知类别时，不显示确定的覆盖比例。

## 数据源与数据集边界

本页实际只使用 OpenStreetMap，通过 Overpass API 查询。它不是 `data.gov.my` 的 `catalogue_dataset`，因此没有可填写的马来西亚开放数据库数据集 ID。

| 来源 | ID | 类型 | 用途 |
| --- | --- | --- | --- |
| OpenStreetMap | 无 `data.gov.my` 数据集 ID | 实时地理 API / Overpass API | 实际设施位置、标签、数量和距离 |
| `schools_district` | `schools_district` | `catalogue_dataset` | 不采用；行政区学校汇总，不能支持 2 km POI 计数 |
| `hospital_beds` | `hospital_beds` | `catalogue_dataset` | 不采用；行政区医院床位汇总，不能支持 2 km POI 计数 |

官方目录：[schools_district](https://data.gov.my/data-catalogue/schools_district)、[hospital_beds](https://data.gov.my/data-catalogue/hospital_beds)。Overpass 支持 Node、Way、Relation 查询及代表中心点输出，见 [Overpass QL](https://wiki.openstreetmap.org/wiki/OverpassQL)。

## 缓存与页面状态

- 本地缓存有效期为 24 小时，缓存键至少包含分析坐标、半径和分类映射版本。
- 有效缓存可直接显示；页面显示 OSM 查询时间或缓存时间。
- 用户主动刷新时绕过缓存并重新查询。
- 查询失败时，仍在 24 小时内的缓存可继续显示并标注“缓存数据”；没有可用缓存时显示“资料暂不可用”。
- 页面显示：`数据来源：OpenStreetMap`、查询时间、`未收录不代表现实中不存在`。
- 按 OSM 要求显示 `© OpenStreetMap contributors`，并链接到 [版权与许可说明](https://www.openstreetmap.org/copyright)。OSM 数据使用 ODbL。

## 明确不包含

- 0–100 周边设施综合指数；
- 设施质量、评分、营业时间和路线；
- 政府行政区汇总数据向 2 km 范围的推算；
- 将 OSM 空结果解释为现实中不存在设施。
