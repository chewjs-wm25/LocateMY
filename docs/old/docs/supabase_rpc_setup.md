# Supabase RPC 函数部署指南

为了支持移动端应用的真实数据分析功能，需要在 Supabase SQL Editor 中运行以下 SQL 脚本以创建所需的存储过程（RPC）。

## 1. 警区位置匹配 (`match_police_district`)
用于根据经纬度从 `police_districts_boundary` 表中匹配所属警区。

```sql
CREATE OR REPLACE FUNCTION match_police_district(lat float8, lng float8)
RETURNS TABLE(id text, name text, state text) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.name, p.state
    FROM police_districts_boundary p
    WHERE ST_Contains(p.boundary_geom, ST_SetSRID(ST_Point(lng, lat), 4326))
    LIMIT 1;
END;
$$;
```

## 2. 地区物价聚合 (`get_district_prices`)
聚合 `price_catcher` 和 `lookup_premise` 表，获取特定地区的平均物价。

```sql
CREATE OR REPLACE FUNCTION get_district_prices(district_name text)
RETURNS TABLE(item_name text, price real)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT li.item as item_name, AVG(pc.price)::real as price
    FROM price_catcher pc
    JOIN lookup_premise lp ON pc.premise_code = lp.premise_code
    JOIN lookup_item li ON pc.item_code = li.item_code
    WHERE lp.district = district_name
    GROUP BY li.item;
END;
$$;
```

## 3. 基础设施密度评估 (`get_transit_density`)
计算地区内的公共交通站点密度评分。

```sql
CREATE OR REPLACE FUNCTION get_transit_density(district_name text)
RETURNS float8
LANGUAGE plpgsql
AS $$
DECLARE
    stop_count int;
BEGIN
    SELECT COUNT(*) INTO stop_count
    FROM transit_stops ts
    WHERE ST_Contains(
        (SELECT ST_Union(boundary_geom) FROM police_districts_boundary WHERE name = district_name),
        ts.geom
    );
    
    -- 归一化评分 (假设 100 个站点为满分 100)
    RETURN LEAST((stop_count::float8 / 1.0), 100.0);
END;
$$;
```

## 4. 地区收入排名 (`get_district_income_rank`)
计算指定地区在全国收入中位数的排名。

```sql
CREATE OR REPLACE FUNCTION get_district_income_rank(district_name text)
RETURNS TABLE(rank bigint, total bigint)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH RankedDistricts AS (
        SELECT district, 
               RANK() OVER (ORDER BY income_median DESC) as r,
               COUNT(*) OVER () as t
        FROM hh_income_district
    )
    SELECT r, t
    FROM RankedDistricts
    WHERE district = district_name;
END;
$$;
```

---

**注意：**
- 运行这些脚本前，请确保已安装 `postgis` 扩展：`CREATE EXTENSION IF NOT EXISTS postgis;`
- 请确保表名和字段名与 Supabase数据库内的Table 一致。
