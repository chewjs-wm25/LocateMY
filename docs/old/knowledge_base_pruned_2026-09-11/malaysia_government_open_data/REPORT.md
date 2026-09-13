# 马来西亚政府开放数据与 API 元数据知识库

## 范围与结果

data.gov.my 是马来西亚官方开放数据门户，OpenDOSM 是马来西亚统计局（DOSM）的官方开放数据门户。官方开发者站点将公开接口分为 Data Catalogue、OpenDOSM、GTFS Static、GTFS Realtime 与 Weather 五类，并说明 Open API 使用统一的 `https://api.data.gov.my` 基址、HTTP GET 请求和无需 token 的公开访问模式。[^1][^2]

本知识库以 2026-09-10 的官方目录快照为基准，收录 290 个数据目录项和 34 个实时 API 资源，共 324 条机器可读记录。官方“List of Datasets on data.gov.my”页面说明该清单由网站内部 API 的数据集列表汇总，并与网站数据目录完全一致；该清单因此被用作完整性基线。[^3]

290 个目录项与 `data-gov-my/datagovmy-meta` 官方仓库中的 290 份 `data-catalogue/*.json` 文件逐一匹配。门户后端官方仓库也说明，其服务会从 `datagovmy-meta` 载入数据目录元数据并提供给前端，这支持将该仓库作为字段说明、更新日期、下载地址、来源机构和 API 排除标记的权威技术来源。[^4][^5]

## 数据目录与 API 可用性

Data Catalogue API 的公开入口是 `GET https://api.data.gov.my/data-catalogue`，使用必填的 `id` 参数定位数据集。官方页面强调：如果某个数据目录项不通过 API 提供，数据集页面会明确说明。[^6] OpenDOSM API 使用 `GET https://api.data.gov.my/opendosm`，同样以 `id` 定位，并面向 OpenDOSM 数据目录的子集。[^7]

结构化核对得出：

| 指标 | 数量 |
|---|---:|
| data.gov.my 数据目录项 | 290 |
| Data Catalogue API 可查询 | 243 |
| 已发布但 `exclude_openapi=true` | 47 |
| OpenDOSM 门户可见 | 183 |
| OpenDOSM API 可查询 | 157 |
| 目录字段定义 | 1,391 |

因此，OpenDOSM 不应被建模为与 data.gov.my 完全独立的重复数据池；对多数 DOSM 数据，它是同一元数据记录的另一门户视图和 API 路径。知识库在单条记录中同时保留 `portal_visibility`、`api.data_catalogue` 和 `api.opendosm`，使 Agent 可以区分门户归属、API 可用性与直接下载能力。

## 元数据内容

每个目录记录包含以下信息：

- 稳定 ID、创建日期、英/马来文标题与描述；
- 英/马来文分类、子分类、来源机构与更细的来源单位；
- 更新频率、数据截至时间、最后更新、下次更新、覆盖起止年份；
- 地理与人口维度；
- 方法说明、注意事项、相关出版物、相关数据集和可视化配置；
- CSV、Parquet、预览链接与 edition keys；
- 字段名、英/马来文标题、字段说明和官方逻辑类型标记；
- Data Catalogue / OpenDOSM API 地址与可用性；
- 官方页面、固定 commit 的元数据 URL、本地原始快照路径与 SHA-256。

平台文档列出的通用查询能力包括精确/不区分大小写筛选、包含筛选、数值范围、排序、日期/时间范围、记录数限制以及列的 include/exclude。[^8] 成功响应默认是记录数组；加上 `meta=true` 后会返回 `meta` 与 `data` 包装对象。[^9]

官方开发者站点当前对五类 API 均列出每分钟 4 次请求的限制，超限返回 HTTP 429。[^10] 这些是平台级事实，未在 290 条记录中重复展开，避免未来更新时出现不一致；实时资源记录则保留了当前限速提示。

## SQL 结构的处理

官方目录公布的是字段定义和描述中的逻辑类型，例如 `[Date]`、`[Integer]`、`[Float]`、`[String]`、`[Categorical]` 与 `[Timestamp]`，而不是数据库真实 DDL。政府后端仓库说明其后端使用 PostgreSQL，但这不代表每个公开数据集存在可复用的官方 SQL 表结构。[^5]

为满足 Agent 建表和原型分析的需要，知识库提供 `sql_structure.ddl` 与 `fields[].sql_type_suggested`。映射规则为：Date→`DATE`、Timestamp/Datetime→`TIMESTAMP`、Integer→`BIGINT`、Float→`DOUBLE PRECISION`、Numeric→`NUMERIC`、Boolean→`BOOLEAN`、String/Categorical→`TEXT`。这些字段全部标记为 `official: false`，并明确不推断主键、外键、NULL 约束、精度、索引或唯一性。

1,391 个目录字段中，1,359 个能从官方字段说明的类型标记获得映射；32 个字段没有类型标记，知识库保守使用 `TEXT`，并以 `fallback_text_no_official_type_annotation` 标记低确定性。这样既提供可操作的 SQL 草案，也避免把推导结果误称为政府公布的 schema。

## 实时交通资源

GTFS Static API 以 `GET https://api.data.gov.my/gtfs-static/<agency>` 提供 ZIP feed。官方页面列出 KTMB、Prasarana 和 BAS.MY 的当前入口，说明 KTMB 每日 00:01 更新，Prasarana 与 BAS.MY 按需更新，并建议使用者每天至少在凌晨 4 点刷新一次。[^11]

本知识库把参数化类别展开为独立资源，共 16 个 GTFS Static feed：KTMB 1 个、Prasarana 5 个类别、BAS.MY 10 个城市/运营方入口。官方页面明确列出的所有 feed 基本容器文件为 `agency.txt`、`stops.txt`、`routes.txt`、`trips.txt`、`stop_times.txt`、`calendar.txt`，并提到可能有 `frequencies.txt` 与 `shapes.txt`。[^11] 由于完整 GTFS 列定义仅通过外部标准链接提供，本知识库没有在“马来西亚政府官方来源限定”之外补入第三方标准字段。

GTFS Realtime API 使用 `GET https://api.data.gov.my/gtfs-realtime/vehicle-position/<agency>`，目前只提供 vehicle-position，不提供 service alerts 或 trip updates；所有 vehicle-position feed 每 30 秒更新。[^12] 参数类别展开后共 15 个资源：KTMB 1 个、Prasarana 4 个类别、BAS.MY 10 个入口。知识库也保留官方页面列出的 GPS 越界、部分 Prasarana trip/route ID 对齐和 Penang trip ID 匹配注意事项。

## 实时天气资源

Weather API 由 MET Malaysia 提供，当前有 7 日一般预报、一般天气警报与地震警报三个入口。一般预报每日更新，警报及地震资料按需更新；官方页面同时注明海洋预报当前不可用。[^13]

天气记录保留官方开发者文档中明确列出的字段。7 日预报包含嵌套地点 ID/名称、日期、早晨/下午/夜间预报、摘要、摘要时段和最低/最高温度；一般警报包含发布信息、有效期与英/马来文标题、正文和指示；地震警报包含 UTC/本地时间、经纬度、深度、地点、距离、震级、状态、可见性及方向向量。[^13]

## 许可与复用

官方 FAQ 说明平台数据采用 Creative Commons Attribution 4.0 International（CC BY 4.0），可免费使用。[^14] 每条记录保存统一许可标识，同时保留来源机构和原始页面，供下游应用履行署名要求。

## 局限

此知识库是元数据快照，不是政府数据镜像。没有下载或抽样检查 290 个数据集的业务记录，因此不会验证记录数、实际列类型、值域、NULL 比例或数据文件与元数据的运行时一致性。实时 feed 也未下载；其结构完全依据官方开发者文档。

更新日期和计划日期由发布机构维护，可能出现已过期的 `next_update` 或历史数据集仍可下载的情况。知识库忠实保留这些值，不擅自改写。API 可用性依据官方 `exclude_openapi` 标记和门户可见性推导，并通过目录与元数据仓库的一一对应关系复核。

## Sources

[^1]: Government of Malaysia, [data.gov.my — Malaysia's official open data portal](https://data.gov.my/), accessed 10 September 2026.
[^2]: Government of Malaysia, [Malaysia's Official Open API — Quickstart](https://developer.data.gov.my/quickstart), accessed 10 September 2026.
[^3]: Jabatan Digital Negara and Ministry of Digital, [List of Datasets on data.gov.my](https://data.gov.my/data-catalogue/datasets), data as of 9 September 2026; updated 10 September 2026.
[^4]: Government of Malaysia, [`data-gov-my/datagovmy-meta`](https://github.com/data-gov-my/datagovmy-meta), commit `d01fd4d2e6235d4b6b70ef4a7a67f88101972ff7`, 10 September 2026.
[^5]: Government of Malaysia, [`data-gov-my/datagovmy-back`](https://github.com/data-gov-my/datagovmy-back), accessed 10 September 2026.
[^6]: Government of Malaysia, [Data Catalogue API](https://developer.data.gov.my/static-api/data-catalogue), accessed 10 September 2026.
[^7]: Government of Malaysia, [OpenDOSM API](https://developer.data.gov.my/static-api/opendosm), accessed 10 September 2026.
[^8]: Government of Malaysia, [Open API Request Query](https://developer.data.gov.my/request-query), accessed 10 September 2026.
[^9]: Government of Malaysia, [Open API Response Format](https://developer.data.gov.my/response-format), accessed 10 September 2026.
[^10]: Government of Malaysia, [Open API Rate Limit](https://developer.data.gov.my/rate-limit), accessed 10 September 2026.
[^11]: Government of Malaysia, [GTFS Static API](https://developer.data.gov.my/realtime-api/gtfs-static), accessed 10 September 2026.
[^12]: Government of Malaysia, [GTFS Realtime API](https://developer.data.gov.my/realtime-api/gtfs-realtime), accessed 10 September 2026.
[^13]: Government of Malaysia and MET Malaysia, [Weather API](https://developer.data.gov.my/realtime-api/weather), accessed 10 September 2026.
[^14]: Government of Malaysia, [Open API FAQ](https://developer.data.gov.my/faq), accessed 10 September 2026.
