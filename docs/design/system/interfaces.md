# 必要业务接口注册表（Issue #31）

系统只登记仍必要的业务边界，完整实际 declarations 以 owning 入口代码／契约为准。

| 业务接口 | Owner | 消费者 | 状态／契约 |
| --- | --- | --- | --- |
| AUTH-001 最小 AuthenticationSession | A | app root／账号页 | 本次重构；[Auth](../features/authentication-and-session.md) |
| GEO-001 GeographicContext | B | Cost／Crime／Socio／Infrastructure／Property | 保留；[Geo](../modules/geographic-context.md) |
| HOME-001 HomeRelocationOutlook | A | 首页 | 保留业务；[Home](../features/home-and-relocation-outlook.md) |
| LOCATION-001 LocationCoordinator／地点对象 | A | 地图／业务页面 | 在线收藏；[Map](../features/map-and-location.md) |
| LOCATION-002 MapLayerHost／MapWorkspace | A | Facilities／Hazard／Transit 局部图 | 必要图层业务；[Map](../features/map-and-location.md) |
| FACILITY-001/002 NearbyFacilities | A | 页面／地图 | 保留 analyse／compare／地图层；[Facilities](../features/nearby-facilities.md) |
| TRANSIT-001 PublicTransportation | A | 页面／地图摘要／ICI | 保留 canonical 结果；[Transit](../features/public-transportation.md) |
| HAZARD-001/002 HazardReporting／HazardRiskCounter | A | 页面／地图／房产 | 当前 SDK 用户；[Hazard](../features/hazard-reporting.md) |
| COST-001/002 成本与预算 current 服务 | B | 页面／Account／Socio | Implemented，生产共享读取／通知已接线；[Cost](../features/cost-of-living-and-budget.md) |
| SAFETY-001 州级安全服务 | B | 页面／房产 | `CrimeSecurity.analyse/compare` + 不可变安全结果；[Crime](../features/crime-and-security.md) |
| SocioEconomic、InfrastructureService、PropertyInspectionService | B | 页面／Account／地图摘要 | Implemented；分别 owning contract |

| LocationSummaryReader | A | 地图展开详情 | app 组合五项真实业务读数，中性 ICI；[Map](../features/map-and-location.md) |
| AccountCenterPage | A | 登录后账户路由 | Auth／current 预算／房产／本人隐患；[Account](../features/account-center.md) |

AUTH-002、PRIVACY-001/002、SHELL-001、LOCATION-003、HAZARD-003、PROPERTY-002 清理接口、
ACCOUNT-001 五项评估偏好与 SUITABILITY-001 退役。旧 Interface ID 不要求保留空声明或替代包装。
外部 HTTP／Supabase／SQLite Adapter 保留具名 seam；页面导航不再登记通用协调接口。
