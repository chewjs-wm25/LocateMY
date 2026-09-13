# 完整性与错误检查

## 结论

自动验证结果为 **PASS**。在 2026-09-10 快照范围内，没有发现数据集 ID 遗漏、重复、无法解析的官方元数据、生成记录与官方元数据数量不一致、API 排除标记不一致或生成文件哈希错误。

## 已执行检查

| 检查 | 结果 |
|---|---:|
| 官方目录行数 | 290 |
| 官方 `data-catalogue/*.json` 文件数 | 290 |
| 目录 ID 与元数据文件名双向差集 | 0 |
| 成功解析的官方 JSON | 290 / 290 |
| 生成的目录记录 | 290 |
| 生成的实时资源 | 34 |
| 全库唯一 ID | 324 / 324 |
| 官方字段数与生成字段数 | 1,391 / 1,391 |
| manifest 文件哈希检查 | 6 / 6 |
| 自动验证失败项 | 0 |

目录 CSV 与元数据 JSON 的标题、来源、频率、起止年份均一致。地理与人口维度出现的 71 处文本差异仅是逗号后空格格式差异，归一化为数组后完全一致。

## 官方元数据中发现的异常

这些问题来自官方源，本知识库没有静默掩盖：

1. `almanak_astronomi` 的字段名 `penerangan\r` 含尾随回车字符。归一化记录将字段名安全修正为 `penerangan`，并在 `name_official_raw` 保存原始值。
2. `ridership_od_brt_daily` 的英文 `caveat_en` 与 `publication_en` 为空。知识库保留 `null/空`，不编造内容。
3. 8 个数据集的共 32 个字段在英文说明开头没有官方类型标记：`almanak_astronomi`、`drug_addicts_age`、`drug_addicts_drugtype`、`drug_addicts_education`、`drug_addicts_occupation`、`drug_arrests_age`、`drug_arrests_ethnicity`、`poskod`。建议 SQL 对这些字段使用保守的 `TEXT` 占位，并明确标记推导依据不足。
4. 官方频率同时使用 `YEARLY` 与 `ANNUAL`。两者没有被擅自合并，以避免改变来源语义。

## 47 个已发布但不可由 Data Catalogue API 查询的数据集

以下 ID 的官方元数据设有 `exclude_openapi=true`；它们仍保留目录页面和直接下载元数据：

`arrivals_soe`, `cosmetic_notifications`, `cosmetic_notifications_cancelled`, `cosmetics_manufacturers`, `covid_deaths_linelist`, `cpi_3d`, `cpi_4d`, `cpi_5d`, `gdp_annual_nominal_demand_granular`, `gdp_annual_nominal_supply_granular`, `gdp_annual_real_demand_granular`, `gdp_annual_real_supply_granular`, `gdp_qtr_nominal_demand_granular`, `gdp_qtr_nominal_supply_granular`, `gdp_qtr_real_demand_granular`, `gdp_qtr_real_supply_granular`, `iowrt_3d`, `ipi_2d`, `ipi_3d`, `ipi_5d`, `ipi_domestic`, `ipi_export`, `lookup_item`, `lookup_premise`, `pharmaceutical_importers`, `pharmaceutical_manufacturers`, `pharmaceutical_products`, `pharmaceutical_products_cancelled`, `pharmaceutical_wholesalers`, `population_dun`, `population_parlimen`, `population_state`, `ppi_2d`, `ppi_3d`, `pricecatcher`, `registration_transactions_all`, `registration_transactions_car`, `registration_transactions_motorcycle`, `ridership_od_brt_daily`, `ridership_od_ets`, `ridership_od_intercity`, `ridership_od_komuter`, `ridership_od_komuter_utara`, `ridership_od_rapidrail_daily`, `ridership_od_shuttle_tebrau`, `sppi_3d`, `vaxreg_covid_demog`.

## 尚未执行的检查

- 没有请求数据集内容，因此未验证实际数据文件的列类型、记录数、值域或 schema drift。
- 没有批量访问 290 个 CSV/Parquet 下载链接，因此未做逐链接 HTTP 可达性检查。
- 没有下载 GTFS/GTFS-R/天气 feed，因此未做运行时协议解析。
- 没有采用官方页面指向的非马来西亚政府标准网站补全 GTFS 字段，符合“只采用马来西亚政府官方来源”的限制。

机器可读的最新验证输出在 `audit_result.json`。重新运行 `node scripts/validate.mjs` 会覆盖该文件并返回非零退出码表示失败。
