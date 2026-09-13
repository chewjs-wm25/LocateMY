# LocateMY Data Flow

本目录记录当前代码中的数据流向，目标是回答“数据从哪里来、经过谁、显示到哪里、
是否被持久化”。

## 文档

- [读取与分析流](./read_flows.md)：首页、生活开销、治安、社会经济、基础设施、交通和 OSM POI。
- [用户写入与同步流](./write_flows.md)：认证、收藏地点、隐患、预算预案和房产档案。

## 总体流向

```text
用户操作 / 页面生命周期
        ↓
View (lib/modules/module_{a,b}/views)
        ↓ 调用 / watch
ViewModel (lib/modules/module_{a,b}/view_models)
        ↓
Repository (lib/modules/module_{a,b}/repositories)
   ┌────┼──────────────┐
   ↓    ↓              ↓
Supabase/RPC       HTTP API       SQLite
   ↓    ↓              ↓
Repository 解析/聚合/降级/缓存
        ↓
Provider 更新状态并 notifyListeners
        ↓
View 重建（loading / data / empty / error）
```

## 共享上下文

`LocationViewModel` 是多数分析页面的上游：地图选点产生坐标和名称，分析页再通过
`DistrictResolver`（名称匹配或 `match_police_district` RPC）解析为州/县。切换地点会
形成新的 request key，从而触发对应 Provider 重载；同一地点通常复用内存状态或缓存。

## 持久化边界

| 数据 | 内存 | SQLite | Supabase | 外部 HTTP |
| --- | --- | --- | --- | --- |
| 登录会话 | Auth SDK | SDK 管理 | Supabase Auth | — |
| 宏观/分析报告 | Provider | `cached_reports`（部分模块） | 多张只读表/RPC | — |
| 收藏地点 | `LocationViewModel` | `saved_locations` | `user_saved_regions`（上传同步） | — |
| 隐患报告 | `HazardViewModel` | — | `crowdsourced_hazards` | — |
| 预算预案 | `BudgetViewModel` | — | `user_budget_scenarios` | — |
| 房产档案/回收站 | `PropertyViewModel` | **未实现** | **未实现** | — |
| 周边设施 | `NearbyFacilitiesViewModel` | — | — | Overpass API |
| 地点搜索 | 页面短期状态 | — | — | Geoapify API |
