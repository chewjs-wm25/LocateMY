# Feature 与依赖（Issue #31）

旧 DAG 的 Privacy、通用 Shell 协调和 Suitability 节点退出。Wave 保留作为开发次序参考，不再是逐声明框架依赖。

| 责任 | Owner | 当前状态／必要依赖 |
| --- | --- | --- |
| 最小 Authentication | A | 已有实现本次重构；SDK |
| Geographic Context | B | 保留；合法坐标与只读边界 RPC |
| Application Shell | A | 最小装配、登录入口、双 Tab／普通路由、语言 |
| Home | A | 已有实现；公共宏观 RPC／SQLite |
| Map / Location | A | 已有实现；范围验证、在线收藏、地图图层 |
| Facilities / Transit / Hazard | A | 已有实现重新接线；各自来源、必要地图对象 |
| Cost / Budget | B | Implemented；Geo、只读成本输入、在线预案、JSON；Map/Account/Socio 已真实接线 |
| Crime | B | Wave 5 已实现；Geo 统计州、真实只读治安输入、SQLite、单点/A-B 页面；验收见 owning contract |
| Socio | B | Implemented；真实 Geo、只读社会经济 RPC、预算 current 读取、SQLite、单点/A-B 页面；完整预算联动已真实验证，验收见 owning contract |
| Infrastructure | B | Implemented；Geo、canonical Transit、在线三权重；地图中性摘要已接线 |
| Property | B | Implemented；合法地点、州级安全、附近隐患计数、在线照片／回收站；Account/Crime 已接线 |
| Account Center | A | 独立 AccountCenterPage；消费 Auth、预算 current、房产／本人隐患真实入口 |

Account Privacy 已取消，Personalized Location Suitability 已排除，不再安排开发。
六类分析保留；新页面未接入时明确标注尚未实现，不以 fake 成功表示交付。
契约从 [设计入口](../README.md) 进入；详细开发状态以执行检查和未来各 Feature 验收为准。

2026-09-18 全模块集成以[本期报告](../../human/integration-2026-09-18.md)为准；Implemented 与负责人 Integrated 批准分开。
