警告：禁止修改本文件

# Supabase 数据表清单 (Supabase Tables Documentation)

本文档列出了本项目所需的所有 Supabase 数据表，分为政府开放数据集关联表和应用自定义业务表。

---

## 1. 政府开放数据集 (Government Datasets)

这些表用于存储或实时同步来自 OpenDOSM 和 data.gov.my 的数据。

| 表名 (Table Name) | 数据集 ID (Dataset ID) | 描述 (Description) |
| :--- | :--- | :--- |
| `price_catcher` | `pricecatcher` | 每日微观物价数据 (Daily price data) |
| `lookup_item` | `lookup_item` | 商品信息查找表 (Item lookup table) |
| `lookup_premise` | `lookup_premise` | 零售场所查找表 (Premise lookup table) |
| `cpi_state` | `cpi_state` (API) / `cpi_2d_state` (Storage) | 州级消费物价指数 (CPI by State) |
| `cpi_core` | `cpi_core` (API) / `cpi_2d_core` (Storage) | 核心消费物价指数 (Core CPI) |
| `crime_stats` | `crime_district` | 警区级犯罪统计数据 (Crime stats by district) |
| `hh_income_district` | `hh_income_district` | 县级家庭中位数收入与基尼系数 (Household income) |
| `hh_access_amenities` | `hh_access_amenities` | 基础设施普及率 (Water, Electricity, Sanitation) |
| `hospital_beds` | `hospital_beds` | 医疗床位数据 (Healthcare capacity) |
| `enrolment_school_district`| `enrolment_school_district` | 学校在校生人数 (School enrolment) |
| `teachers_district` | `teachers_district` | 教师人数统计 (Teachers stats) |

---

## 2. 应用自定义表 (Custom Application Tables)

这些表用于存储用户生成的内容、个性化配置和空间分析数据。

### 2.1 用户基础档案表 (`profiles`)
```sql
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  avatar_url TEXT,
  bio TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT username_length CHECK (char_length(username) >= 3)
);

-- 启用 Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
```

### 2.2 用户预算方案表 (`user_budget_scenarios`)
```sql
CREATE TABLE public.user_budget_scenarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  scenario_name TEXT NOT NULL,
  max_rent NUMERIC(12, 2) DEFAULT 0,
  living_expenses NUMERIC(12, 2) DEFAULT 0,
  transport_allowance NUMERIC(12, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_budget_scenarios ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own scenarios" ON public.user_budget_scenarios FOR ALL USING (auth.uid() = user_id);
```

### 2.3 众包排雷事件表 (`crowdsourced_hazards`)
```sql
CREATE TABLE public.crowdsourced_hazards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  hazard_type TEXT NOT NULL, -- 'flood_spot', 'pothole', 'crime_hotspot', etc.
  title TEXT,
  description TEXT,
  district TEXT, -- 冗余字段用于快速过滤
  location GEOMETRY(Point, 4326) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'resolved', 'rejected')),
  report_time TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_hazards_location ON public.crowdsourced_hazards USING GIST (location);
ALTER TABLE public.crowdsourced_hazards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Hazards are viewable by everyone" ON public.crowdsourced_hazards FOR SELECT USING (true);
CREATE POLICY "Authenticated users can report hazards" ON public.crowdsourced_hazards FOR INSERT WITH CHECK (auth.role() = 'authenticated');
```

### 2.4 用户收藏位置表 (`user_saved_regions`)
```sql
CREATE TABLE public.user_saved_regions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  district_id TEXT NOT NULL,
  alias TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, district_id)
);

ALTER TABLE public.user_saved_regions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own saved regions" ON public.user_saved_regions FOR ALL USING (auth.uid() = user_id);
```

### 2.5 基础设施评分偏好表 (`user_ici_preferences`)
```sql
CREATE TABLE public.user_ici_preferences (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  weight_safety NUMERIC(3, 2) DEFAULT 0.2,
  weight_transit NUMERIC(3, 2) DEFAULT 0.2,
  weight_education NUMERIC(3, 2) DEFAULT 0.2,
  weight_health NUMERIC(3, 2) DEFAULT 0.2,
  weight_amenity NUMERIC(3, 2) DEFAULT 0.2,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_ici_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own preferences" ON public.user_ici_preferences FOR ALL USING (auth.uid() = user_id);
```

### 2.6 实地验房记录表 (`user_property_inspections`)
```sql
CREATE TABLE public.user_property_inspections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  property_name TEXT NOT NULL,
  address TEXT,
  rating INT CHECK (rating >= 1 AND rating <= 5),
  inspection_data JSONB DEFAULT '{}'::jsonb,
  image_urls TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_property_inspections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own inspections" ON public.user_property_inspections FOR ALL USING (auth.uid() = user_id);
```

---

## 3. 空间与高性能计算扩展 (Spatial & Performance)

### 3.1 公共交通站点表 (`transit_stops`)
```sql
CREATE TABLE public.transit_stops (
  stop_id TEXT PRIMARY KEY,
  stop_name TEXT NOT NULL,
  transit_type TEXT NOT NULL, -- LRT, MRT, Bus, Rail
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  geom GEOMETRY(Point, 4326)
);

CREATE INDEX idx_transit_stops_geom ON public.transit_stops USING GIST (geom);
```

### 3.2 警区边界表 (`police_districts_boundary`)
```sql
CREATE TABLE public.police_districts_boundary (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  state TEXT NOT NULL,
  boundary_geom GEOMETRY(MultiPolygon, 4326)
);

CREATE INDEX idx_police_boundary_geom ON public.police_districts_boundary USING GIST (boundary_geom);
```
