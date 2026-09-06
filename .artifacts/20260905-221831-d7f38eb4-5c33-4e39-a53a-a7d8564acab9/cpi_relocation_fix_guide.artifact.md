# CPI 通胀率与搬迁指数调试指南

根据目前的逻辑，**搬迁指数**是依赖于 **CPI 通胀率**和 **ICI 基础设施得分**的。如果这两个指标其中一个获取不到，搬迁指数就会显示为“暂无数据”。

## 1. 检查 CPI 通胀率 (`cpi_state`)

### 逻辑分析
代码目前查询 `cpi_state` 表，要求满足以下条件：
- 字段 `division` 必须精确等于 `'00. ALL ITEMS'`。
- 数据量需足够计算同比（即需要包含当前日期和一年前的记录）。

### 推荐 SQL Structure
请检查您的 Supabase 中该表的结构是否如下：
```sql
-- 确保 division 字段包含 "00. ALL ITEMS"
SELECT DISTINCT division FROM public.cpi_state;

-- 所需数据示例
-- date: 2024-07-01, division: "00. ALL ITEMS", index: 112.5
-- date: 2023-07-01, division: "00. ALL ITEMS", index: 110.2
```

---

## 2. 检查基础设施评分 (`hh_access_amenities`)

### 逻辑分析
代码查询 `hh_access_amenities` 表的最近 16 条记录（代表各州平均水平），并计算 `piped_water`, `electricity`, `sanitation` 的均值。

### 推荐 SQL Structure
```sql
-- 字段必须为数值类型 (real/float)
-- piped_water: 95.5
-- electricity: 99.8
-- sanitation: 98.2
```

---

## 3. 代码层面优化建议

为了提高容错性，我建议将搬迁指数的计算逻辑改为**部分依赖**。即使缺失 ICI，也可以根据收入和通胀计算出一个参考值。

### 计划调整
1.  **容错计算**：在 `relocationIndex` 计算中，允许 `iciScore` 为 null 时取默认值 80.0（或按比例调整权重）。
2.  **CPI 匹配优化**：由于 `division` 字段可能有空格差异，我将使用模糊匹配。

## 您需要检查的操作：
1.  运行 `SELECT DISTINCT division FROM cpi_state` 确认是否有 `'00. ALL ITEMS'` 这个分类。
2.  确认 `hh_access_amenities` 表中是否有数据。
