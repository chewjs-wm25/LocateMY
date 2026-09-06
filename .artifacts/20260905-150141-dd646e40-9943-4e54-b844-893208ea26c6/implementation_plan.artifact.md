# 更新 Supabase 气象数据表文档

更新 `docs/docs_supabase_tables.md`，以反映气象统计数据现在通过 CSV 手动导入（采用新格式），而不是从 `climate_weather_stats` API 获取。

## 拟议变更

### 文档更新

#### [docs_supabase_tables.md](file:///D:/Work/Mobile Application/Assignment/docs/docs_supabase_tables.md)

- 更新第 1 部分：修改 `climate_stats` 的描述，注明为 CSV 手动导入，并移除已失效的数据集 ID。
- 新增第 2.9 节：根据新的 CSV 格式提供 `climate_stats` 表的 SQL 结构。

```diff
- - `climate_stats` (数据集 ID: `climate_weather_stats`) - 历史气象与降雨分布
+ - `climate_stats` (CSV 手动导入) - 历史气象与降雨分布
```

`climate_stats` 的新 SQL 结构：
```sql
CREATE TABLE public.climate_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  state TEXT NOT NULL, -- 州属
  station TEXT NOT NULL, -- 气象站名称
  elevation TEXT, -- 海拔高度，例如 '(37.8m)'
  year INT NOT NULL, -- 年份
  min_temp NUMERIC(4, 1), -- 最低平均气温
  max_temp NUMERIC(4, 1), -- 最高平均气温
  rainfall NUMERIC(10, 2), -- 总降雨量
  rainfall_days NUMERIC(5, 1), -- 降雨天数
  humidity NUMERIC(4, 1), -- 平均相对湿度
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(state, station, year)
);
```

## 验证计划

### 自动化测试
- 无。由于这是仅文档的更改，我将检查 Markdown 文件的基本结构。

### 手动验证
- 编辑后检查 `docs/docs_supabase_tables.md` 的内容，确保更改已正确应用且格式一致。
