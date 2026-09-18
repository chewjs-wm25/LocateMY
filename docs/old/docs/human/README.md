# LocateMY 模块总览与作业回顾索引

> 本文档回答「当前项目有哪些 Module」，并说明各模块是否属于"比较完整/庞大、且涉及
> CRUD 操作"的模块。CRUD 类模块按业务相关性融合为 **2 个 Module**，每个 Module 的
> 五个作业问题与答案记录在对应的 1 份文档中（docs/human 共 2 份问答文档 + 本总览）。

## 一、项目的功能模块（Module）清单

LocateMY 是一个面向马来西亚的搬迁选址辅助 Flutter 应用。项目按
「视图（`lib/views/<module>`）+ 状态（Provider/ChangeNotifier）+ 仓库（Repository）+ 模型（Model）」的
MVVM 风格组织。按页面与业务域划分，共有 11 个功能模块和若干横切公共组件：

| # | 模块 | 主要代码位置 | 数据性质 | CRUD 判定 / 归属 |
|---|------|--------------|----------|------------------|
| 1 | 认证与账户（Auth & Account） | `views/account/`、`providers/auth_provider.dart`、`repositories/auth_repository.dart` | Supabase Auth + `profiles` 表 | 仅创建与会话读取，未构成完整 CRUD |
| 2 | 首页宏观仪表盘（Home Dashboard） | `views/home/`、`providers/home_provider.dart`、`repositories/home_repository.dart` | 读取 `hh_income_district`、`cpi_state`、`crime_stats`、`gdp_gni_annual_real`、`lfs_month` 等并本地缓存 | 纯读取（R） |
| 3 | 地图与位置（Map & Location） | `views/map/map_view.dart`、`providers/location_provider.dart`、`repositories/map_repository.dart` | 本地 SQLite `saved_locations` + 云端 `user_saved_regions`（收藏，双向同步） | 完整 CRUD → 并入 **Module A** |
| 4 | 灾害上报（Hazard Reporting） | `views/account/reported_hazards_screen.dart`（入口在地图）、`providers/hazard_provider.dart`、`repositories/map_repository.dart` | 云端 `crowdsourced_hazards` | 涉及 C/R/D → 并入 **Module A** |
| 5 | 生活开销与预算（Cost of Living & Budget） | `views/cost_of_living/`、`providers/budget_provider.dart`、`repositories/cost_of_living_repository.dart` | 读取 `cpi_state`、PriceCatcher RPC；写 `user_budget_scenarios`（预算预案） | 完整 CRUD → 并入 **Module B** |
| 6 | 治安与犯罪（Crime & Security） | `views/crime_security/`、`providers/analysis/security_provider.dart`、`repositories/security_repository.dart` | 读取 `crime_stats`、`police_districts_boundary`（PostGIS RPC） | 纯读取（R），另嵌入房产检查入口 |
| 7 | 房产检查（Property Inspection） | `views/property/`、`providers/property_provider.dart`、`models/property_inspection.dart` | 内存列表（增删改查 + 回收站软删除）；风险上下文来自 `crime_stats` / `crowdsourced_hazards` | 完整 CRUD（内存态，未落库）→ 并入 **Module B** |
| 8 | 基础设施（Infrastructure / ICI） | `views/infrastructure/`、`providers/analysis/infrastructure_provider.dart`、`repositories/infrastructure_repository.dart`、`core/ici_score.dart` | 读取 `hh_access_amenities`、`hospital_beds`、`district_population`、`teachers_district`、`enrolment_school_district` 等 | 纯读取（R）+ 本地缓存 |
| 9 | 周边设施（Nearby Facilities / OSM） | `views/infrastructure/nearby_facilities_view.dart`、`providers/nearby_facilities_provider.dart`、`repositories/facility_repository.dart` | OSM Overpass API（HTTP POST） | 纯读取（R） |
| 10 | 社会经济（Socio-Economic） | `views/socio_economic/`、`providers/analysis/socio_economic_provider.dart`、`repositories/socio_economic_repository.dart` | 读取 `hh_income_district`、`hh_inequality_*`、`hies_*` 等 | 纯读取（R） |
| 11 | 公共交通（Transportation） | `views/transport/`、`providers/analysis/transit_provider.dart`、`repositories/transit_repository.dart` | 读取 `transit_stops` | 纯读取（R） |

横切公共组件（不属于业务模块，供上述模块复用）：

- `core/cache/local_cache_service.dart`：sqflite 本地缓存（`cached_reports`、`saved_locations` 两张表，含版本升级）。
- `core/supabase/`：Supabase 客户端单例管理、`mock_supabase_client.dart`、`district_resolver.dart`（把地点名/坐标解析为真实行政区与州）。
- `core/`：`ici_score.dart`、`normalized_score.dart`、`district_matcher.dart`、主题与颜色。
- `widgets/`：Bento 卡片、状态徽章、迷你地图、星级评分选择器、分析位置选择器等共享控件。
- 国际化：`lib/l10n/`（en/zh ARB），由 `flutter gen-l10n` 生成。

## 二、CRUD 判定与融合说明

判定标准：模块是否对**自己的数据实体**提供完整的创建 / 读取 / 更新 / 删除操作
（写入 Supabase 业务表或本地 SQLite，仅查询外部数据源再加缓存写入不算）。

满足"较完整/庞大 + 涉及 CRUD"的模块有 4 个（地图与位置、灾害上报、生活开销与预算、
房产检查）。考虑到它们在页面与数据链路上高度相关，作业回顾按两个融合后的 Module
组织，每个 Module 的五个问题以整体叙述方式作答，不再区分原始子模块：

- **Module A：地图选址与灾害上报** —— 融合"地图与位置"（收藏：本地先写、云端同步，
  C/R/U/D）与"灾害上报"（众包灾害：C/R/D，U 目前仅本地乐观更新）。两者共用地图页、
  `map_repository` 与全局选址状态。
- **Module B：开销预算与房产评估** —— 融合"生活开销与预算"（预案：C/R/U/D 全落
  Supabase）与"房产检查"（档案增删改查 + 回收站恢复，C/R/U/D；当前为内存态）。
  两者共同回答"搬迁开销与居住决策"，并复用同一套地点归一与风险解析设施。

其余模块以展示分析结果为主，是应用的重要"读取型"模块，但不满足本次"必须涉及 CRUD"
的筛选条件，因此仅在上表说明，不展开五问答。

## 三、按 Module 分开的问答文档

1. [Module A：地图选址与灾害上报（Map & Hazard）](./map_and_hazard.md)
2. [Module B：开销预算与房产评估（Budget & Property）](./budget_and_property.md)

每份文档按以下五个问题组织（问题沿用作业英文模板，答案以中文书写）：

- **Q1**：Please briefly describe the module(s)/function(s) you engaged in the assignment. Indicate clearly the APIs and external libraries used.
  （简要描述所负责的模块/功能，并明确指出使用的 API 与外部库。）
- **Q2**：What are the strengths of the modules/functions created by you?
  （这些模块/功能的优势是什么？）
- **Q3**：What are the weaknesses of the modules/functions created by you?
  （这些模块/功能的弱点是什么？）
- **Q4**：What have you learned in doing this assignment?
  （完成本作业学到了什么？）
- **Q5**：What are the challenges, if any, you faced while working on this assignment?
  （完成本作业时遇到过哪些挑战？）
