# 系统风险与待决项

> 状态：`Draft — Issue #2 tracer + Issue #3 boundary scope`
> 最后更新：2026-09-13

本文件记录 [TRACER-01](flows.md#tracer-01启动登录选址查看周边设施并退出) 与
[完整 Feature map](feature-map.md) 暴露的系统风险和关闭条件。产品事实已由 Issue #1 批准，Feature
边界与 DAG 已由项目负责人在 Issue #3 批准；它们不替 Feature owning design 决定实现细节。

## 已采用的 tracer 约束

| 约束 | 依据 | 影响 |
| --- | --- | --- |
| 应用门控以真实会话结果为准 | `NAV-01`、`AUTH-01` | 页面跳转不能证明登录；启动失败时不显示私有内容 |
| 分析只接收不可变地点引用 | 跨 Feature 协作规范、地点契约 | 分析期间后续选点不会静默改写结果；无地点不使用默认城市 |
| 周边设施归 Feature 所有并保留完整性分支 | `FAC-01` 与覆盖模型 | 空结果、未知和失败不会被同一个可空列表混淆 |
| 当前设备退出经过 privacy barrier | `ACCOUNT-07`、数据保留边界 | 会话结束与本机清理都完成后才开放新登录；其他设备与远端记录不受影响 |
| 公共设施缓存与语言偏好跨退出保留 | 已批准产品分类和数据边界 | 清理不会误删无账户数据；公共缓存不得夹带账户资料 |

这些约束是已批准产品事实在系统 seam 上的直接表达，尚未达到“难以逆转且经过真实技术取舍”的
ADR 门槛。若后续验证迫使改变它们，再由项目负责人决定是否记录 ADR。

## 风险与关闭条件

| ID | 风险 | 影响范围 | 当前控制 | 验证方式 | 最迟关闭点 | 阻塞性 |
| --- | --- | --- | --- | --- | --- | --- |
| `RISK-SESSION-01` | Supabase Flutter SDK 在 token 过期、离线和刷新失败时的实际会话语义尚未验证 | `AUTH-001`、`NAV-01`、离线启动 | 只允许 SDK 明确可接受的会话打开账户范围；不确定时保持门控 | 学生建立最小认证实验并记录冷启动、过期 token、离线和远端拒绝结果 | Authentication & Session 进入 `Ready for Development` 前 | 后续 Feature Ready 阻塞；不阻塞本 tracer 设计 |
| `RISK-PRIVACY-01` | 未完成所有 Feature 设计前，私有状态 Owner 清单可能漏项，导致退出后残留 | `PRIVACY-001`、`ACCOUNT-07`、所有私有 Feature | privacy barrier 使用显式 Owner 清单；未登记 Owner 不能进入集成 | 对照完整 Feature map、Schema Catalog、SQLite 表、键值和文件目录逐项审计；注入每个 Owner 清理失败 | 系统 Baseline Gate 与 Account Privacy Ready 前 | Baseline 阻塞 |
| `RISK-PRIVACY-02` | 结束认证会话后本机物理清理失败，用户无法安全进入下一账户 | `AUTH-001`、`PRIVACY-001`、账户切换 | 先阻断旧范围读取；失败停在无私有内容的清理恢复态，重试幂等 | 文件/SQLite 不可写、部分已删和进程重启故障注入 | Account Privacy Ready 前 | Feature Ready 阻塞 |
| `RISK-OSM-01` | Overpass 限流、超时或部分响应可能被误判为真实空结果 | `FACILITY-001`、`FACILITY-002`、`FAC-01` | 只有可证明完整的响应才能产生覆盖/未覆盖；其余为未知或缓存降级 | 用完整、有意截断、超时、HTTP 限流和无效 payload 的代表查询验证 | Nearby Facilities Ready 前 | Feature Ready 阻塞 |
| `RISK-CACHE-01` | 坐标精度、分类映射版本或缓存键不一致会复用错误地点/口径结果 | `LOCATION-001`、`CACHE-FACILITY` | 缓存键至少含分析坐标、2,000 米半径和分类版本；结果回带原地点 | 手工验算邻近坐标、版本升级和 24 小时边界；契约测试断言 key/result 一致 | Nearby Facilities Ready 前 | Feature Ready 阻塞 |
| `RISK-CACHE-02` | 公共缓存若混入收藏名称或账户引用，会绕过退出清理泄露兴趣地点 | `CACHE-FACILITY`、`PRIVACY-001` | 公共缓存只保存分析所需坐标、公共结果、时间、版本和归因 | Schema Catalog 审查和退出后存储检查，确认没有账户/用户命名字段 | Schema 对象批准前 | Baseline 阻塞 |
| `RISK-GEO-01` | 马来西亚范围校验的数据源和边界精度尚未固定 | `LOCATION-001`、`MAP-01` | 范围外结果必须拒绝；不以字符串国家名或默认城市替代空间校验 | 用边境、岛屿、海域及明显范围外坐标验证候选方案 | Map / Location Ready 前 | Feature Ready 阻塞 |
| `RISK-GEO-02` | 行政区与警区边界资料的版本、空间匹配和多匹配规则尚未固定 | Geographic Context；Cost、Crime、Socio-economic、Infrastructure | Feature map 将统计地理解析集中在 Geographic Context；两类口径分开返回且未解析不使用附近地区替代 | 用边界点、离岛、多边形重叠、无覆盖坐标及不同资料版本验证确定性结果 | Geographic Context Ready 前 | 下游 Feature Ready 阻塞 |

## 明确延后而非静默假设

- Issue #3 只确定其余单点分析、A/B 比较、个人化地点适配度与设施摘要组合的责任 Owner、直接
  设计依赖和波次；它们必须在各自 Capability 追踪与 Interface 登记完成后接入。
- 本 tracer 只确认收藏创建队列和房产照片待传清理责任；其他离线写行为必须由对应产品事实与
  owning Feature 设计授权，不能从通用 privacy barrier 推导。
- 完整技术架构、composition root 与 Schema Catalog 对象仍由系统步骤 4–6 及后续 Feature 设计完成。
  Issue #3 只批准 Feature 边界、DAG 与设计波次；风险控制不等于系统 Baseline Gate 已通过。
