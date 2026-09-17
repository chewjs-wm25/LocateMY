# Capability 追踪（Issue #31）

完整 Capability 分类以 [产品目录](../../knowledge_base/locatemy_product/capability_catalog.md) 为权威。
只取消明确排除项，核心分析／A/B／投票／房产回收站／风险保留，新增 COST-05 设计。

| 能力族 | 唯一责任／契约 | 验收成果 |
| --- | --- | --- |
| AUTH-01/02、ACCOUNT-07 | [Auth](../features/authentication-and-session.md)，A | 注册／登录／当前设备退出、SDK 默认保持身份 |
| NAV、语言 | [Application Shell](../modules/application-shell.md)，A | 登录入口、双 Tab、普通路由、语言 KV |
| HOME | [Home](../features/home-and-relocation-outlook.md)，A | 真实宏观卡、来源／日期、趋势／公共缓存 |
| MAP-01–06 | [Map](../features/map-and-location.md)，A | 合法角色／A/B、在线收藏、六类入口、业务图层 |
| COST-01–03、COST-05 | [Cost](../features/cost-of-living-and-budget.md)，B | 原生成本／压力、在线预案、临时 CPI、v1 JSON 导出读取 |
| SAFE-01/03 | [Crime](../features/crime-and-security.md)，B | 州级安全／趋势／A/B |
| SOCIO | [Socio](../features/socio-economic.md)，B | 地区统计及 current 家庭收入位置 |
| INFRA | [Infrastructure](../features/infrastructure-coverage.md)，B | 分项／ICI、在线三权重、摘要和 A/B 中性 |
| FAC-01 | [Facilities](../features/nearby-facilities.md)，A | 2 km 分类／数量／最近项／A/B |
| TRANSIT | [Transit](../features/public-transportation.md)，A | 1.5 km 有效服务／canonical 分／站点图与 A/B |
| HAZ | [Hazard](../features/hazard-reporting.md)，A | 公开报告、作者管理、本人持久化投票、pending count |
| PROP-01–05 | [Property](../features/property-inspection.md)，B | 在线实勘／照片、档案／2–3 对比、回收站恢复／永久清空、风险时机 |
| ACCOUNT-01/02/09 | [Account](../features/account-center.md)，A | 真实邮箱、已接入业务入口、当前预算预案 |

AUTH-03、MAP-07、ACCOUNT-08 排除；既有其他 excluded 项沿用产品目录，不恢复入口。
预算 JSON、房产和未实现分析以 owning 后续验收为准，本次不以 fake 成功宣称交付。
