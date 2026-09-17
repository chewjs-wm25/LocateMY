# Supabase 政府数据核查与手动下载清单

核查日期：2026-09-17。远端项目：`ntlhjfljkjeefzzqutbc`（与本地 linked project 一致）。本次只读查询，没有修改远端数据。

结论：尚未齐全。发现 7 个需要补齐的数据源，包含 2 张空统计表、1 个失败 GTFS feed、价格历史、人口年份/地区覆盖，以及 2 张无法完整关联现有价格的维表。

下载目录：`/home/AC79/Desktop/LocateMY/data/government-downloads/`。保留原始字段和数据，不用 Excel 重存，不合并、不解压交通 ZIP。原始下载文件已通过目录级 .gitignore 排除版本控制。

## 下载清单

| 数据集 ID | 实际缺口 | 下载及保存文件 |
| --- | --- | --- |
| `hh_inequality_state` | 表存在但 0 行；州级基尼回退缺失 | [完整 CSV](https://storage.dosm.gov.my/hies/hh_inequality_state.csv)，保存为 `hh_inequality_state.csv` |
| `hies_state_percentile` | 表存在但 0 行；B40/M40/T20、收入分布和个人收入位置缺失 | [完整 CSV](https://storage.dosm.gov.my/hies/hies_state_percentile.csv)，保存为 `hies_state_percentile.csv` |
| `population_district` | 只到 2022 年；2022 年 both/overall/overall 总人口只有 129 个行政区，2020/2021 各有 160 个。2025 年学校资料不能用相差 3 年的 2022 年人口作分母 | [完整 CSV](https://storage.dosm.gov.my/population/population_district.csv)，保存为 `population_district.csv`，保留全部年份/维度 |
| `lookup_item` | 现有 756 行；13,061 条价格记录找不到商品代码 | [完整 CSV](https://storage.data.gov.my/pricecatcher/lookup_item.csv)，保存为 `lookup_item.csv` |
| `lookup_premise` | 现有 3,344 行；16,729 条价格记录找不到商户代码 | [完整 CSV](https://storage.data.gov.my/pricecatcher/lookup_premise.csv)，保存为 `lookup_premise.csv` |
| `pricecatcher` | 151,400 行，只有 2026-09-01 至 2026-09-04；不满足最近 12 个月窗口至少 6 个月有效观测的规则 | 下载下文列出的 12 个月完整文件，放入 `pricecatcher/` |
| `gtfs_static_prasarana_rapid_bus_kuantan` | official-2026-09-17 登记 failed/HTTPError，站点、路线、有效服务日期均 0；本次再检查官方端点仍 HTTP 404 | [官方 ZIP 端点](https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-kuantan)，保存到 `gtfs/gtfs_static_prasarana_rapid_bus_kuantan.zip` |

商品/商户两项无法关联的计数可能重叠，不能相加。取得完整官方维表后仍需核对是否涵盖全部历史代码，不能保证仅下载最新维表便修复全部关联。

关丹端点的 404 是官方资源目前无法取得；如果浏览器也下载不了，请先完成其余下载。不要把错误网页保存成 ZIP，也不要用其他城市 feed 替代。GTFS 是 realtime_api_resource，不是 catalogue_dataset；项目 ID 是所需 feed 的登记标识，下载参数为 rapid-bus-kuantan。[官方 GTFS 文档](https://developer.data.gov.my/realtime-api/gtfs-static)

## PriceCatcher 月份

按本次核查截止月，准备 2025-10 至 2026-09 共 12 个按月文件。2026-09 是尚未结束的月份；导入审计保留其实际截止日期。最低 6 个月只是每个地点的可用性门槛，准备 12 个月才能完整覆盖模型窗口；下载齐不保证每个地点都有足够篮子覆盖率。

CSV 或 Parquet 二选一，推荐 Parquet，文件较小；同一月份不必下载两种格式。放到 `data/government-downloads/pricecatcher/`，保留官方文件名。

| 月份 | Parquet | CSV |
| --- | --- | --- |
| 2025-10 | [pricecatcher_2025-10.parquet](https://storage.data.gov.my/pricecatcher/pricecatcher_2025-10.parquet) | [pricecatcher_2025-10.csv](https://storage.data.gov.my/pricecatcher/pricecatcher_2025-10.csv) |
| 2025-11 | [pricecatcher_2025-11.parquet](https://storage.data.gov.my/pricecatcher/pricecatcher_2025-11.parquet) | [pricecatcher_2025-11.csv](https://storage.data.gov.my/pricecatcher/pricecatcher_2025-11.csv) |
| 2025-12 | [pricecatcher_2025-12.parquet](https://storage.data.gov.my/pricecatcher/pricecatcher_2025-12.parquet) | [pricecatcher_2025-12.csv](https://storage.data.gov.my/pricecatcher/pricecatcher_2025-12.csv) |
| 2026-01 | [pricecatcher_2026-01.parquet](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-01.parquet) | [pricecatcher_2026-01.csv](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-01.csv) |
| 2026-02 | [pricecatcher_2026-02.parquet](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-02.parquet) | [pricecatcher_2026-02.csv](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-02.csv) |
| 2026-03 | [pricecatcher_2026-03.parquet](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-03.parquet) | [pricecatcher_2026-03.csv](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-03.csv) |
| 2026-04 | [pricecatcher_2026-04.parquet](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-04.parquet) | [pricecatcher_2026-04.csv](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-04.csv) |
| 2026-05 | [pricecatcher_2026-05.parquet](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-05.parquet) | [pricecatcher_2026-05.csv](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-05.csv) |
| 2026-06 | [pricecatcher_2026-06.parquet](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-06.parquet) | [pricecatcher_2026-06.csv](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-06.csv) |
| 2026-07 | [pricecatcher_2026-07.parquet](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-07.parquet) | [pricecatcher_2026-07.csv](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-07.csv) |
| 2026-08 | [pricecatcher_2026-08.parquet](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-08.parquet) | [pricecatcher_2026-08.csv](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-08.csv) |
| 2026-09 | [pricecatcher_2026-09.parquet](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-09.parquet) | [pricecatcher_2026-09.csv](https://storage.data.gov.my/pricecatcher/pricecatcher_2026-09.csv) |

链接按官方月文件命名规则列出。当前月地址已由[官方目录](https://data.gov.my/data-catalogue/pricecatcher)核实；本次未逐一下载历史大文件。

## 其他已存在的统计数据

以下为远端精确 COUNT 和实际日期范围。非空不等于已完成逐行官方文件一致性审计；本次主要检查数据存在性、日期窗口、人口总量地区覆盖和价格关联完整性。除上述确定缺口之外，其余数据暂不要求重新下载。项目采用一次性导入，不要求运营期间追踪所有官方更新。

| ID | 行数 | 最早日期 | 最新日期 |
| --- | ---: | --- | --- |
| `cpi_headline_inflation` | 7,812 | 1980-02-01 | 2026-07-01 |
| `cpi_state` | 44,576 | 2010-01-01 | 2026-07-01 |
| `cpi_state_inflation` | 44,352 | 2010-02-01 | 2026-07-01 |
| `economic_indicators` | 426 | 1991-01-01 | 2026-06-01 |
| `enrolment_school_district` | 12,756 | 2017-01-01 | 2025-06-30 |
| `fuelprice` | 955 | 2017-03-30 | 2026-09-10 |
| `gdp_qtr_real_sa` | 46 | 2015-01-01 | 2026-04-01 |
| `hh_access_amenities` | 655 | 2016-01-01 | 2024-01-01 |
| `hh_income` | 22 | 1970-01-01 | 2024-01-01 |
| `hh_income_district` | 480 | 2019-01-01 | 2024-01-01 |
| `hh_income_state` | 308 | 1974-01-01 | 2024-01-01 |
| `hh_inequality_district` | 480 | 2019-01-01 | 2024-01-01 |
| `hh_inequality_state` | 0 | — | — |
| `hies_district` | 322 | 2022-01-01 | 2024-01-01 |
| `hies_state_percentile` | 0 | — | — |
| `hospital_beds` | 5,468 | 2015-01-01 | 2022-01-01 |
| `lfs_month_sa` | 198 | 2010-01-01 | 2026-06-01 |
| `lookup_item` | 756 | — | — |
| `lookup_premise` | 3,344 | — | — |
| `mcoicop` | 343 | — | — |
| `population_district` | 179,000 | 2020-01-01 | 2022-01-01 |
| `pricecatcher` | 151,400 | 2026-09-01 | 2026-09-04 |
| `schools_district` | 3,977 | 2017-01-01 | 2025-06-30 |
| `teachers_district` | 8,805 | 2017-01-01 | 2025-06-30 |
| `crime_district` | 19,152 | 2016-01-01 | 2023-01-01 |

行政边界已有 160 行，采用批准的固定 DOSM administrative_2_district 版本，暂不要求重新下载。警区多边形已排除范围；OSM 周边设施不是政府数据集，不列为政府镜像缺口。可选 CPI 分类辅助数据不列为必需下载。

16 个 GTFS feed 中 15 个 usable，只有上述关丹失败。Ipoh、Seremban A/B 的服务日期范围均仅为 2026-09-17：这是已导入快照的实际服务日范围，不能将其描述为长期有效；当前没有证据表明缺了另一份可下载的官方文件。补齐关丹后，交通完整评分仍需重新核验整批快照和固定参照网格。

## 核查依据

- 项目事实源：CONTEXT.md；首页宏观指数；生活成本、社会经济、犯罪与治安功能事实源；单个地点基础设施指数。
- [州级基尼官方目录](https://open.dosm.gov.my/data-catalogue/hh_inequality_state)、[州级百分位官方目录](https://open.dosm.gov.my/data-catalogue/hies_state_percentile)。
- [人口官方目录](https://open.dosm.gov.my/data-catalogue/population_district)标示 Data as of 2025；其描述文字仍写 2020–2024，导入时应以完整文件的实际 date 和地区覆盖为准。
- [商品维表](https://data.gov.my/data-catalogue/lookup_item)、[商户维表](https://data.gov.my/data-catalogue/lookup_premise)、[价格记录](https://data.gov.my/data-catalogue/pricecatcher)、[GTFS 文档](https://developer.data.gov.my/realtime-api/gtfs-static)。

下载完成只表示文件就位；下一步需检查文件、字段、日期/代码覆盖，再按项目一次性导入边界补齐并核验 Supabase。

