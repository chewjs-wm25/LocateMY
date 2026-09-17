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
| Cost / Budget | B | 尚未实现；Geo、只读成本输入、在线预案、JSON |
| Crime | B | 尚未实现；Geo 统计州、只读治安输入 |
| Socio | B | 尚未实现；Geo、预算家庭月度总收入 |
| Infrastructure | B | 尚未实现；Geo、canonical Transit、在线三权重 |
| Property | B | 尚未实现；合法地点、州级安全、pending count、在线照片／回收站 |
| Account Center | A | 最小账号复用 Auth；完整入口后续消费预算／房产／本人隐患 |

Account Privacy 已取消，Personalized Location Suitability 已排除，不再安排开发。
六类分析保留；新页面未接入时明确标注尚未实现，不以 fake 成功表示交付。
契约从 [设计入口](../README.md) 进入；详细开发状态以执行检查和未来各 Feature 验收为准。
