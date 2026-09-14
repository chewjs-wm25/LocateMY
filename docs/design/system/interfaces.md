# 系统 Interface 注册表

> 状态：`Baselined — 5d11769`
> 最后更新：2026-09-14

本表是跨 Feature Interface 摘要与外部 seam 的唯一真相。完整协调语义留给 owning Feature/shared module 设计；数据字段只在 [Schema Catalog](../data/schema-catalog.md) 定义。

## 跨 Feature Interface

| ID | Owner | 消费者 | 用途 | 状态 | Owning document |
| --- | --- | --- | --- | --- | --- |
| `AUTH-001` | Authentication & Session | Account Privacy；Application Shell；Account Center | 当前设备会话与真实邮箱确认 | `Ready for Development` | [Authentication & Session](../features/authentication-and-session.md) |
| `PRIVACY-001` | Account Privacy | Application Shell；所有私有状态 Owner | 账户范围开启、关闭与本机清理证明 | `Ready for Development` | [Account Privacy](../modules/account-privacy.md) |
| `SHELL-001` | Application Shell | 所有 Feature/shared module | 门控导航、组合槽位与跨 Feature 工作流 | `Ready for Development` | [Application Shell](../modules/application-shell.md) |
| `LOCATION-001` | Map / Location | Application Shell；Cost；Crime；Facilities；Transit；Hazard；Socio；Infrastructure；Property；Suitability | 合法、不可变的单点/A-B/房产地点引用 | `Ready for Development` | [Map / Location](../features/map-and-location.md) |
| `LOCATION-002` | Map / Location | Hazard Reporting；Nearby Facilities；Public Transportation | 声明式地图图层与点击/长按意图 | `Ready for Development` | [Map / Location](../features/map-and-location.md) |
| `GEO-001` | Geographic Context | Cost；Crime；Socio-economic；Infrastructure | 行政区与统计州地理语境 | `Ready for Development` | [Geographic Context](../modules/geographic-context.md) |
| `HOME-001` | Home & Relocation Outlook | Application Shell | 全国搬家时机、宏观卡与刷新状态 | `Ready for Development` | [Home & Relocation Outlook](../features/home-and-relocation-outlook.md) |
| `COST-001` | Cost of Living & Budget | Application Shell；Personalized Location Suitability | 地点成本、个人预算压力与临时 CPI 等效换算 | `Ready for Development` | [Cost of Living & Budget](../features/cost-of-living-and-budget.md) |
| `COST-002` | Cost of Living & Budget | Account Center；Socio-economic；Personalized Location Suitability；Application Shell | 预算预案及 current/无 current 的变化事实 | `Ready for Development` | [Cost of Living & Budget](../features/cost-of-living-and-budget.md) |
| `SAFETY-001` | Crime & Security | Application Shell；Property Inspection；Personalized Location Suitability | 州级安全结果与趋势 | `Ready for Development` | [Crime & Security](../features/crime-and-security.md) |
| `FACILITY-001` | Nearby Facilities | Application Shell；Map / Location 摘要；Personalized Location Suitability | 2 公里五类 OSM 覆盖结果 | `Ready for Development` | [Nearby Facilities](../features/nearby-facilities.md) |
| `TRANSIT-001` | Public Transportation | Application Shell；Infrastructure Coverage；Personalized Location Suitability | 站点/有效路线聚合、连通性分及资料状态 | `Ready for Development` | [Public Transportation](../features/public-transportation.md) |
| `HAZARD-001` | Hazard Reporting | Application Shell；Map / Location | 发布后内容不可变的公共隐患、作者状态/删除与账户投票 | `Ready for Development` | [Hazard Reporting](../features/hazard-reporting.md) |
| `HAZARD-002` | Hazard Reporting | Property Inspection | 风险快照的附近公共隐患数 | `Ready for Development` | [Hazard Reporting](../features/hazard-reporting.md) |
| `SOCIO-001` | Socio-economic | Application Shell | 收入、结构、基尼、分布和收入位置 | `Ready for Development` | [Socio-economic](../features/socio-economic.md) |
| `INFRA-001` | Infrastructure Coverage | Application Shell；Personalized Location Suitability | 账户权重与中性 ICI | `Ready for Development` | [Infrastructure Coverage](../features/infrastructure-coverage.md) |
| `PROPERTY-001` | Property Inspection | Application Shell | 实勘、照片、比较、回收站与风险快照 | `Ready for Development` | [Property Inspection](../features/property-inspection.md) |
| `ACCOUNT-001` | Account Center | Application Shell；Personalized Location Suitability | 账户评估偏好快照/变化与账户页意图 | `Ready for Development` | [Account Center](../features/account-center.md) |
| `SUITABILITY-001` | Personalized Location Suitability | Application Shell | 五维输入的个人化地点适配度 | `Ready for Development` | [Personalized Location Suitability](../features/personalized-location-suitability.md) |

## 外部来源 seam

| ID | Owner | 消费者 | 用途 | 状态 | Owning document |
| --- | --- | --- | --- | --- | --- |
| `AUTH-002` | Authentication & Session | Authentication & Session | 对接 Supabase Auth 的会话与邮箱确认 | `Ready for Development` | [Authentication & Session](../features/authentication-and-session.md) |
| `LOCATION-003` | Map / Location | Map / Location | 对接 Geoapify 的马来西亚地点候选 | `Ready for Development` | [Map / Location](../features/map-and-location.md) |
| `GEO-002` | Geographic Context | Geographic Context | 对接版本化行政边界读取对象 | `Ready for Development` | [Geographic Context](../modules/geographic-context.md) |
| `FACILITY-002` | Nearby Facilities | Nearby Facilities | 对接 Overpass 设施来源 | `Ready for Development` | [Nearby Facilities](../features/nearby-facilities.md) |

Supabase Data API、SQLite、文件和 Storage 是各 Owner 的 Data Adapter；可访问对象在 Schema Catalog 登记。

## 依赖边覆盖

| Interface | 覆盖的直接依赖 |
| --- | --- |
| `AUTH-001` | `D01`、`D02`、`D36` |
| `PRIVACY-001` | `D03`、`D06`、`D10`、`D20`、`D29`、`D32`、`D37` |
| `SHELL-001` | `D04`、`D05`、`D07`、`D11`、`D14`、`D16`、`D18`、`D21`、`D25`、`D30`、`D35`、`D39` |
| `LOCATION-001` | `D08`、`D12`、`D15`、`D22`、`D26`、`D31`、`D40` |
| `LOCATION-001`、`LOCATION-002` | `D17`（合法地点与声明式站点分布图） |
| `LOCATION-002` | `D19` |
| `GEO-001` | `D09`、`D13`、`D23`、`D27` |
| `COST-001` | `D42` |
| `COST-002` | `D24`、`D38` |
| `TRANSIT-001` | `D28`、`D45` |
| `SAFETY-001` | `D33`、`D43` |
| `HAZARD-002` | `D34` |
| `ACCOUNT-001` | `D41` |
| `FACILITY-001`、`INFRA-001` | `D44`、`D46` |

`D01`–`D46` 每条恰由上表一个 owning Interface 组覆盖；组合消费者可使用同一 Interface，不为每条边复制一个同义契约。

## Owning document Gate

每个 owning design 进入 `Ready for Development` 前补全其 Interface 的消费者、动作族、可观察结果、授权和跨 Owner 副作用/安全不变量。消费者只有在所需上游协调契约冻结后才能固定自己的依赖；不能在消费者文档复制提供方契约。
