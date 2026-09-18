# 下载政府数据验证报告（2026-09-17）

结论：下载文件正确，但业务所需资料尚未完善。7 个文件的 SHA-256 与本次重新读取的对应官方文件或指定 Mobility Database 归档文件一致。未修改原始下载文件，未向 Supabase 导入任何数据。

下载位置：`/home/AC79/Desktop/LocateMY/data/government-downloads/`。

## 文件验证结果

| 数据源 | 本地检查结果 | 是否满足本次补齐要求 |
| --- | --- | --- |
| hh_inequality_state | 289 行，1974–2024；2024 年有全部 16 州；键不重复，gini 在 0–1，无空值 | 通过 |
| hies_state_percentile | 19,200 行；2019/2022/2024 各 6,400 行；每年 16 州 × P1–P100 × 4 种 variable；键不重复 | 通过 |
| population_district | 383,040 行，2020–2025 每年 63,840 行；3 种 sex × 19 种 age × 7 种 ethnicity × 160 行政区；总人口筛选每年覆盖全部 160 行政区；无重复键/空值/非法数值 | 通过，可补齐 2025 年教育人口分母和 2022 年医疗人口地区缺口 |
| lookup_item | 797 行，无重复键；11 项固定篮子的代码和单位均在维表中 | 文件正确；仍不能关联全部价格代码 |
| lookup_premise | 3,917 行；现有下载价格均可关联商户；有 1 条空主键记录，另有 -1 占位记录，代码采用 2.0 等文本形式 | 文件正确；导入前需要处理空键和整数格式 |
| pricecatcher_2026-09 | 894,995 行，2026-09-01 至 09-15；键不重复，无空值或非法价格 | 只有 1 个月，不满足至少 6 个有效月份及篮子覆盖率要求 |
| gtfs/tld-6768-202607230117.zip | CRC 通过；1 agency、17 routes、270 trips、635 stops、10,733 stop_times、2 calendar；关联与主键检查通过 | 可作为可追溯的关丹归档 feed；不是本次从官方端点新取得的文件 |

所有 CSV 表头均符合对应镜像所需字段。检查包括完整读取、业务键重复、日期/数值、人口维度覆盖、百分位分组、价格到维表的关联以及 GTFS ZIP/关联/服务日/坐标。SHA-256 对比明细见同目录 JSON 证据文件。

hies_state_percentile 的 96 个 income 空值全部位于 P1 minimum 和 P100 maximum，是官方隐私处理；median 数据无此缺口，且各州各年份 median 随百分位单调不下降。income 为 1638.0 等文本，但所有非空值均为整数金额，导入时应精确转换，不直接把字符串当整数解析。

人口原始 population 单位为千人；镜像保留原值，应用计算床位/学校每人密度前应按事实源单位转换，不能将 495.3 当成 495.3 人。

## PriceCatcher 仍缺什么

单个 CSV 不一定有问题，关键是内部日期。本文件确实只有 2026 年 9 月，没有合并历史月份。

请继续下载 **2025-10 至 2026-08 共 11 个按月完整文件**，放到 `pricecatcher/` 子目录，保留 `pricecatcher_YYYY-MM.csv` 或 `.parquet` 文件名。现有 2026-09 文件与核查时官方文件完全一致，无需为了校验重下。每个月 CSV/Parquet 二选一。

官方月文件目录：[PriceCatcher](https://data.gov.my/data-catalogue/pricecatcher)。下载地址按 `https://storage.data.gov.my/pricecatcher/pricecatcher_YYYY-MM.csv` 或 `.parquet` 选择月份；官方目录的下载月份选择用于取得历史文件。

现有价格有 **13,027 行、14 个 item_code** 不在完整官方 lookup_item 中：

`2023, 2035, 2048, 2053, 2057, 2059, 2089, 2090, 2091, 2092, 2093, 2094, 2095, 2096`。

商品维表和价格文件都与官方文件一致，因此这是当前官方文件之间的关联缺口，不是你的下载错误。不能猜商品名称或单位补齐。下载其余月份后需重新评估；这些代码均不属于本项目固定 11 项篮子。

固定篮子当前月份完全无价格记录的代码是 **224（牛奶）、272（面包）、1541（洗洁精）、1645（咖啡）**。118（鸡蛋）全国仅 2 条观测。其余 7 项有观测，不代表每个行政区都有。不能据此生成完整篮子、固定全国基准或预算压力；不能仅按“7/11 项”推断达到按预算份额计算的 80% 门槛。补历史月份后需逐地点、逐月份重新检查至少 6 个月有效观测与平均覆盖率。

## 商户维表的导入处理

下载文件原样保留。存在 1 条 premise_code 为空、其余业务信息也为空（address 为两个逗号）的记录；另有 premise_code=-1 的官方占位记录。item 维表同样存在 item_code=-1 占位记录。

空主键行不能直接导入以 premise_code 为主键的表，应在暂存阶段隔离并记录审计；-1 占位行不能解释为真实商品或地点。所有非空 premise_code 均能按整数精确归一化；不要因 2.0 等格式导入失败而修改真实代码或丢弃正常记录。

本次关联验证在整数精确归一化后进行，下载价格的 missing premise 数为 0。原始 JSON 证据中的 lookup_premise InvalidOperation=1 正是上述空代码行，不表示 CSV 损坏。

## 关丹备份来源与可用性

用户提供页面：[Mobility Database tld-6768](https://mobilitydatabase.org/feeds/gtfs/tld-6768)。页面将此 feed 标记为 Official Feed，producer URL 指向原 `rapid-bus-kuantan` 官方端点，归档为 2026-07-23。本地文件与该指定归档 ZIP 的 SHA-256 完全一致：

`5a7d1010a22e61f2720fef3abc634c6c452703b6e5f59788080a71a0ad195a86`

归档下载 URL：[tld-6768-202607230117.zip](https://files.mobilitydatabase.org/tld-6768/tld-6768-202607230117/tld-6768-202607230117.zip)。

ZIP 内 agency 为 RapidKuantan，路线名称和站点范围与关丹地区相符。包含所需 routes/trips/stops/stop_times/calendar；无 calendar_dates，但已有完整星期服务日历，calendar_dates 并非必须同时存在。经纬度有效、parent station 和路线/班次/站点/服务日关联均无断链。

服务范围为 2020-04-01 至 2027-03-31；2026-09-17 的 weekday 服务有 140 条有效 trip。服务日范围表示 feed 声明的日期，不保证现实运营未发生变化。

归档[完整质量报告](https://files.mobilitydatabase.org/tld-6768/tld-6768-202607230117/report_8.0.1.html)记录 0 errors、877 条 warning、101 条 info。目录页面的“4 warnings”代表警告类别，不能当作仅 4 条记录；其中包含站点间速度异常。项目只计算站点和有效路线覆盖，这些警告不直接阻止本次覆盖输入解析，但不能用该数据保证真实行程时间或运营质量。

可以保留现有文件名。未来导入登记应分别记录：
- 业务 feed_id：gtfs_static_prasarana_rapid_bus_kuantan。
- 官方 producer URL 与真实 archive download URL。
- 2026-07-23 归档时间、本地取得时间以及 SHA-256。

本次验证没有证明备份网站另授予独立再分发许可，也没有将备份标成 2026-09-17 官方新快照。来源可追溯和字段可解析，足以将其作为后续导入核验候选；全交通评分仍需按现有契约创建/核验新批次和对应参照网格，不能覆盖已推广批次或只把旧 failed 状态改成 usable。

## 下一步

仍需补齐 11 个月 PriceCatcher 历史；无需重下其余已校验文件。商品代码缺口和空商户键在导入审计中处理；生活篮子不足保持真实缺失状态。本报告验证的是下载文件，不能表示远端 Supabase 已补齐。

