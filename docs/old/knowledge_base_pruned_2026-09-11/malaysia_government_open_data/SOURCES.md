# 官方来源清单

本知识库只使用以下马来西亚政府门户、政府维护的 GitHub 组织及其官方存储域名。外部标准页面、搜索结果摘要、博客和社区整理资料没有作为数据集事实来源。

| 来源 | 用途 |
|---|---|
| [data.gov.my](https://data.gov.my/) | 国家开放数据门户身份与数据目录页面 |
| [OpenDOSM](https://open.dosm.gov.my/data-catalogue) | DOSM 官方目录视图 |
| [List of Datasets on data.gov.my](https://data.gov.my/data-catalogue/datasets) | 290 个数据集 ID 的完整性基线 |
| [官方目录 CSV](https://storage.data.gov.my/metrics/dataset_list.csv) | ID、创建日期、双语标题/分类、来源、频率、维度、起止年份 |
| [`data-gov-my/datagovmy-meta`](https://github.com/data-gov-my/datagovmy-meta) | 290 份数据集描述、字段、更新时间、下载链接和 API 排除标记 |
| [`data-gov-my/datagovmy-back`](https://github.com/data-gov-my/datagovmy-back) | 确认元数据仓库与门户后端的关系及 PostgreSQL 后端事实 |
| [Data Catalogue API](https://developer.data.gov.my/static-api/data-catalogue) | `/data-catalogue` 接口与 ID 规则 |
| [OpenDOSM API](https://developer.data.gov.my/static-api/opendosm) | `/opendosm` 接口与范围 |
| [Query syntax](https://developer.data.gov.my/request-query) | 通用筛选、排序、日期、limit、include/exclude 参数 |
| [Response format](https://developer.data.gov.my/response-format) | 响应包装与 HTTP 状态 |
| [Rate limits](https://developer.data.gov.my/rate-limit) | 五类 API 的公开限速 |
| [GTFS Static](https://developer.data.gov.my/realtime-api/gtfs-static) | 静态交通 feed、入口、频率和容器文件 |
| [GTFS Realtime](https://developer.data.gov.my/realtime-api/gtfs-realtime) | vehicle-position feed、入口、30 秒更新和注意事项 |
| [Weather API](https://developer.data.gov.my/realtime-api/weather) | MET Malaysia 天气端点、字段与频率 |
| [FAQ](https://developer.data.gov.my/faq) | CC BY 4.0 平台许可 |

固定版本、抓取时间和哈希见 `sources/provenance.json`。每个目录记录还包含自己的固定 commit URL 和原始元数据 SHA-256。
