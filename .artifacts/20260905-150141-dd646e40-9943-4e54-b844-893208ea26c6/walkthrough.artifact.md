# 气象数据文档更新说明

已更新 `docs/docs_supabase_tables.md` 以反映气象数据源的变更。

## 变更概要
- **数据源变更**：气象统计数据不再通过 `climate_weather_stats` API 获取，改为通过 CSV 手动导入。
- **文档更新**：
    - 更新了静态政务数据集清单中的 `climate_stats` 描述。
    - 新增了 `climate_stats` 数据表的 SQL 结构，以匹配新的 CSV 数据格式。

## 验证总结
- 确认 `docs/docs_supabase_tables.md` 中的描述已更新。
- 确认新增的 SQL 结构包含以下字段：`state`, `station`, `elevation`, `year`, `min_temp`, `max_temp`, `rainfall`, `rainfall_days`, `humidity` 以及唯一约束。

## 关键文件链接
- [docs_supabase_tables.md](file:///D:/Work/Mobile Application/Assignment/docs/docs_supabase_tables.md)
