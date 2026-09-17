# LocateMY 设计与开发入口

2026-09-17 [Issue #31](https://github.com/chewjs-wm25/LocateMY/issues/31) 执行
[ADR 0017](../adr/0017-minimal-account-and-online-user-records.md)：最小账号、在线记录与普通 Flutter 导航。
当前设计取代冲突的历史框架；历史批准与实现证据仅描述原版本，不能自动证明修改后的完成状态。
产品术语／公式以 CONTEXT 与知识库为准，字段／RLS／migration 以 Schema Catalog 为准。

本轮分析页面精简按 [知识库 UI 边界](../knowledge_base/locatemy_product/ui_design_spec.md#分析页面精简边界2026-09-17) 执行；它覆盖冲突的技术元数据展示要求，不更改既有分析算法／缓存。既有分析页面尚待后续任务实施；治安 Wave 5 已按此边界实现。

先读 [开发标准](development-standard.md)（手写 Dart 遵循第 7 节）、[系统入口](system/README.md)，
再读 owning 契约。仅在实际跨 Owner 业务需要时固定公开 declarations，不保留空层或框架包装。
AI 可修改、测试全部代码；Integrated 由项目负责人批准。当前验收见 [执行检查](system/issue-31-validation.md)。

| 类型 | Owner | 当前契约／状态 |
| --- | --- | --- |
| Auth | A | [最小账号](features/authentication-and-session.md)，已有实现重构 |
| Geo | B | [地理语境](modules/geographic-context.md)，保留业务服务 |
| App | A | [最小装配](modules/application-shell.md)，已有实现重构 |
| Home | A | [首页](features/home-and-relocation-outlook.md)，已有实现 |
| Map | A | [地图／收藏](features/map-and-location.md)，已有实现重构 |
| Cost／Budget | B | [生活成本／预算／JSON](features/cost-of-living-and-budget.md)，Draft，尚未实现 |
| Crime | B | [治安](features/crime-and-security.md)，Implemented；Wave 5 本期验收通过，房产消费 Wave 6 |
| Facilities | A | [周边设施](features/nearby-facilities.md)，已有实现重构 |
| Transit | A | [公共交通](features/public-transportation.md)，已有实现重构 |
| Hazard | A | [隐患](features/hazard-reporting.md)，已有实现重构 |
| Socio | B | [社会经济](features/socio-economic.md)，Draft，尚未实现 |
| Infrastructure | B | [基础设施](features/infrastructure-coverage.md)，Draft，尚未实现 |
| Property | B | [房产](features/property-inspection.md)，Draft，尚未实现 |
| Account | A | [账户](features/account-center.md)，最小页已接线，完整入口后续 |

[Account Privacy](modules/account-privacy.md) 已取消；[Personalized Location Suitability](features/personalized-location-suitability.md) 已排除。
HTML 仅从 owning Markdown 导出，见 [交接规则](handoff/README.md)。不得将未实现目标或占位入口称为成功功能。
