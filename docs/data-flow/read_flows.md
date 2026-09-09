# 读取与分析 Data Flow

## 首页宏观数据

```text
HomeScreen → HomeViewModel.loadStats
→ HomeRepository.getHomeStats
→ SQLite cached_reports（命中则返回）
→ Supabase: hh_income_district / cpi_state / hh_access_amenities /
             crime_stats / gdp_gni_annual_real / lfs_month
→ 聚合为 HomeStats → 写缓存 → HomeViewModel → HomeScreen
```

## 地图搜索与分析地点

```text
MapView 搜索文字 → GeoapifyRepository → Geoapify HTTP
→ GeoSuggestion → LocationViewModel(selected/origin/destination)
→ 各分析页读取坐标/地点名
→ DistrictResolver（名称表匹配，必要时 match_police_district RPC）
→ 标准 state + district
```

## 生活开销

```text
CostOfLivingView → BudgetViewModel.fetchComparison(origin, target)
→ CostOfLivingRepository
→ cpi_state + get_district_prices RPC（两地）
→ CPI 比例、购买力、分类预算、商品均价
→ BudgetViewModel.comparisonData → 图表/预算换算 UI
```

## 治安

```text
CrimeSecurityView → SecurityViewModel.loadSecurityData(lat, lng)
→ SecurityRepository → match_police_district RPC
→ crime_stats → 趋势/类别/安全分数
→ SecurityViewModel → 页面

迷你地图 → SecurityRepository.fetchPoliceDistrictBoundary
→ police_districts_boundary → GeoJSON 边界
HazardViewModel → crowdsourced_hazards → 地图隐患 Marker
```

## 社会经济

```text
SocioEconomicView → SocioEconomicViewModel.loadSocioData
→ DistrictResolver
→ hh_income_district + hh_inequality_district + hies_state +
   hh_inequality + hh_income + hies_malaysia_percentile
→ 县级优先/州与全国回退 + 分布拟合/排名/门槛
→ Provider → 页面；用户收入 → 本地 CDF → 百分位
```

## 基础设施

```text
InfrastructureView → InfrastructureViewModel.loadInfraData
→ InfrastructureRepository + DistrictResolver
→ hh_access_amenities + hospital_beds + district_population +
   teachers_district + enrolment_school_district
→ 分项归一化 + ICI → Provider
→ 用户调整权重 → Provider 本地重算 → 页面更新（不写数据库）
```

## 公共交通与周边设施

```text
TransportationView → TransitViewModel → TransitRepository
→ Supabase transit_stops → Haversine 过滤/排序 → 站点 UI/地图

NearbyFacilitiesView → NearbyFacilitiesViewModel → FacilityRepository
→ Overpass HTTP POST → OSM elements 解析/分类/距离计算 → 分类 UI
```

两条流都以三位小数坐标组成 request key，在同一地点避免重复请求；切换地点清除旧结果。

