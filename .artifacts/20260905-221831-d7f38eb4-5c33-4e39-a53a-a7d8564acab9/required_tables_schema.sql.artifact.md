# Home Page 所需数据表结构说明

为了让首页的 GDP 趋势图和失业率指标能够正常显示，您需要在 Supabase 中创建以下两个表并导入数据。

## 1. GDP 增长趋势表 (`gdp_growth_trend`)

该表用于绘制首页的折线图，展示近几年的经济增长情况。

### SQL 创建语句
```sql
CREATE TABLE public.gdp_growth_trend (
    id SERIAL PRIMARY KEY,
    year TEXT NOT NULL,          -- 年份 (例如: "2020", "2021")
    value NUMERIC(4,2) NOT NULL, -- GDP 增长百分比 (例如: 4.20)
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 推荐导入数据 (示例)
| year | value |
| :--- | :--- |
| 2020 | 2.5 |
| 2021 | 3.1 |
| 2022 | 8.7 |
| 2023 | 3.7 |
| 2024 | 4.2 |

---

## 2. 失业率统计表 (`unemployment_stats`)

该表用于展示当前的失业率及其变动趋势。

### SQL 创建语句
```sql
CREATE TABLE public.unemployment_stats (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,          -- 统计日期 (通常是每月1号)
    value NUMERIC(4,2) NOT NULL, -- 失业率百分比 (例如: 3.30)
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 推荐导入数据 (示例)
| date | value |
| :--- | :--- |
| 2024-07-01 | 3.3 |
| 2024-06-01 | 3.4 |

---

## 3. 其他表的数据检查清单

如果您发现首页其他指标（如通胀、治安）依然显示“暂无数据”，请确保以下表中有数据记录：

- **`cpi_state`**: 必须包含 `division = '00. ALL ITEMS'` 的记录，用于计算通胀率。
- **`hh_access_amenities`**: 需要包含 `piped_water`, `electricity`, `sanitation` 字段的记录，用于计算基础设施评分。
- **`crime_stats`**: 需要包含 `crimes` 字段的历史记录，用于计算治安趋势。

**注意**：所有表都应位于 `public` schema 下。
