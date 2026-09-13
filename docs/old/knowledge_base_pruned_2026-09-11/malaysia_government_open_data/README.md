# 马来西亚政府开放数据知识库

本目录是供 AI Agent 使用的、只含元数据的知识库。它覆盖 OpenDOSM、data.gov.my 数据目录，以及 Malaysia's Official Open API 文档中列出的实时交通与天气资源。快照时间为 **2026-09-10 11:42:55（Asia/Kuala_Lumpur）**。

## 先读结论

- 官方数据目录：290 个数据集。
- 可经 `GET /data-catalogue?id=...` 查询：243 个。
- 已发布但官方标记为不可经 OpenAPI 查询：47 个。
- OpenDOSM 门户可见：183 个；其中可经 `GET /opendosm?id=...` 查询：157 个。
- 实时 API 资源：34 个，包括 16 个 GTFS Static feed、15 个 GTFS Realtime vehicle-position feed、3 个天气资源。
- 总资源记录：324 条；数据目录字段定义：1,391 个。

“已发布”不等于“可经 API 查询”。请优先读取每条记录的 `api.*.available`，不要仅凭数据集页面或下载链接判断。

## 文件入口

| 文件 | 用途 |
|---|---|
| `data/all_resources.jsonl` | 首选入口；324 条资源，每行一条 JSON |
| `data/catalogue_datasets.jsonl` | 290 个数据目录记录，含描述、字段、频率、来源、API/下载地址、edition keys、方法、限制及建议 SQL |
| `data/realtime_resources.jsonl` | 34 个实时交通/天气资源 |
| `data/resource_index.csv` | 轻量索引，适合快速过滤或导入表格工具 |
| `data/summary.json` | 数量与分类统计 |
| `schema/resource.schema.json` | 记录结构契约 |
| `sources/catalog_metadata/*.json` | 290 份官方原始元数据快照，未经改写 |
| `sources/dataset_list.csv` | 官方“List of Datasets on data.gov.my”快照 |
| `sources/provenance.json` | 来源 URL、commit、抓取时间与哈希 |
| `manifest.json` | 生成文件的字节数与 SHA-256 |
| `audit_result.json` / `AUDIT.md` | 自动检查结果和人工复核说明 |

## Agent 使用规则

1. 用 `id` 作为稳定主键。标题可能变化，且有英/马来文版本。
2. 查询数据前先检查 `api.data_catalogue.available` 或 `api.opendosm.available`。
3. `fields[].logical_type_official` 只在官方字段说明含类型标记时才有值。
4. `sql_structure` 和 `fields[].sql_type_suggested` 是本知识库根据官方逻辑类型生成的建议，不是政府公布的数据库 DDL。
5. 当 `sql_type_basis` 为 `fallback_text_no_official_type_annotation` 时，`TEXT` 只是保守占位，不能据此断言真实类型。
6. 所有来源判断应回到 `official_pages`、`provenance` 或 `sources/catalog_metadata`；不要把本知识库的归一化或推导字段冒充官方原文。
7. `last_updated`、`next_update` 与 `data_as_of` 是各数据集官方元数据字段，不代表本知识库抓取时间。

## 常用检索

PowerShell：

```powershell
$records = Get-Content .\data\all_resources.jsonl | ForEach-Object { $_ | ConvertFrom-Json -Depth 100 }
$records | Where-Object { $_.source_agencies -contains 'DOSM' }
$records | Where-Object { $_.api.data_catalogue.available -eq $true -and $_.temporal.frequency -eq 'DAILY' }
$records | Where-Object { $_.fields.name -contains 'state' }
```

Node.js：

```javascript
import fs from "node:fs";
const records = fs.readFileSync("data/all_resources.jsonl", "utf8")
  .trim().split(/\r?\n/).map(JSON.parse);
const dailyApiDatasets = records.filter(r =>
  r.record_kind === "catalogue_dataset" &&
  r.api.data_catalogue.available &&
  r.temporal.frequency === "DAILY"
);
```

## 重建与验证

离线重建（使用已保存的官方元数据快照）：

```powershell
node .\scripts\build.mjs
node .\scripts\validate.mjs
```

刷新数据目录快照需要网络访问：

```powershell
.\scripts\refresh_sources.ps1
```

刷新脚本会更新数据集目录和 `datagovmy-meta` 快照。实时 API 列表来自固定版本的官方开发者文档；当官方 GTFS/Weather 文档变更时，需要人工复核 `build.mjs` 中的 feed 列表和文档 commit。

## 边界

- 没有下载 290 个数据集的记录内容，也没有下载 GTFS、GTFS-R 或天气响应。
- 保存的 `dataset_list.csv` 本身是“数据集目录元数据”，不是业务数据。
- 没有使用第三方数据集目录或社区整理资料作为事实来源。
- GTFS 完整字段标准由官方页面链接到外部标准网站；因本项目限定只采用马来西亚政府官方来源，本知识库只记录政府页面明确列出的容器文件，不导入外部标准的完整字段表。

完整研究说明与引用见 `REPORT.md`，异常与遗漏检查见 `AUDIT.md`。
