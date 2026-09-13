# 系统风险与待决项

> 状态：`Draft — Issue #4 system contract scope`
> 最后更新：2026-09-13

本文件记录完整 [Feature map](feature-map.md)、[Interface 注册表](interfaces.md)、
[数据所有权](data-ownership.md)、[技术架构](architecture.md)与[关键流程](flows.md)暴露的系统风险和关闭条件。
系统契约完整不表示具体 Adapter、schema migration 或 Feature design 已完成。

## 已采用的系统约束

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
| `RISK-CACHE-01` | 坐标精度、分类映射版本或缓存键不一致会复用错误地点/口径结果 | `LOCATION-001`、`facility_public_cache` | 缓存键至少含分析坐标、2,000 米半径和分类版本；结果回带原地点 | 手工验算邻近坐标、版本升级和 24 小时边界；契约测试断言 key/result 一致 | Nearby Facilities Ready 前 | Feature Ready 阻塞 |
| `RISK-CACHE-02` | 公共缓存若混入收藏名称或账户引用，会绕过退出清理泄露兴趣地点 | `facility_public_cache`、`PRIVACY-001` | 公共缓存只保存分析所需坐标、公共结果、时间、版本和归因 | Schema Catalog 审查和退出后存储检查，确认没有账户/用户命名字段 | Schema 对象批准前 | Baseline 阻塞 |
| `RISK-GEO-01` | 马来西亚范围校验的数据源和边界精度尚未固定 | `LOCATION-001`、`MAP-01` | 范围外结果必须拒绝；不以字符串国家名或默认城市替代空间校验 | 用边境、岛屿、海域及明显范围外坐标验证候选方案 | Map / Location Ready 前 | Feature Ready 阻塞 |
| `RISK-GEO-02` | 行政区与警区边界资料的版本、空间匹配和多匹配规则尚未固定 | Geographic Context；Cost、Crime、Socio-economic、Infrastructure | Feature map 将统计地理解析集中在 Geographic Context；两类口径分开返回且未解析不使用附近地区替代 | 用边界点、离岛、多边形重叠、无覆盖坐标及不同资料版本验证确定性结果 | Geographic Context Ready 前 | 下游 Feature Ready 阻塞 |
| `RISK-SCHEMA-01` | 现有 migration 的若干镜像名、粒度或字段与批准数据集不一致，且缺少多个 required 数据集 | Home、Crime、Socio、Infrastructure、Transit | Schema Catalog 将旧对象标为新设计不可消费，并登记 canonical 镜像与稳定读取对象 | 对照官方 dataset schema、实际导入行数/最大日期/键唯一性；每个读取对象做完整/空/部分导入验收 | 系统 Baseline Gate 前给出迁移计划；各数据 Feature Ready 前实现 | Baseline 阻塞 |
| `RISK-SCHEMA-02` | `user_ici_preferences` 现有五个 0–1 权重与三项 1–10 产品契约冲突 | Infrastructure、Account Privacy、Suitability | Schema Catalog 明确目标字段和旧表仅作迁移来源；中性 ICI 不读账户权重 | 两账户迁移样本验证三项值、默认 5、旧 safety/amenity 不进入新对象 | Infrastructure Ready 前 | Feature Ready 阻塞 |
| `RISK-PREF-01` | 评估偏好现有数据库默认 5 可能把“尚未设置”误判为已完成五项偏好 | Account、Suitability | Suitability 只接受 `ACCOUNT-001 complete snapshot`；表存在与完成语义由 owning design 明确 | 新账户无偏好、首次保存、部分旧记录与换号场景 | Account Center Ready 前 | 下游 Suitability Ready 阻塞 |
| `RISK-PROP-01` | “附近隐患数”的半径/空间口径尚无权威数值 | Hazard、Property、风险快照 | `HAZARD-002` 要求固定口径和采集时间，但系统不虚构半径 | 项目负责人选择口径并更新产品事实；用边界内外报告验证 | Property Inspection Ready 前 | Feature Ready 阻塞 |
| `RISK-STORAGE-01` | Storage 文件上传与照片元数据写入不是原子操作，清空回收站也可能部分失败 | Property、Account Privacy | 显式队列、可重试不一致状态、owner path 与可证明孤儿补偿 | 注入上传/元数据/删除每一阶段失败和重启，验证无跨账户访问与不误报完成 | Property Inspection Ready 前 | Feature Ready 阻塞 |
| `RISK-SYNC-01` | 收藏前台双向同步的幂等键、冲突和删除传播尚未精确定义 | Map、Account Privacy、跨设备恢复 | 系统只固定远端权威、create-only 离线队列、在线删除与触发时机 | 双设备创建/删除、重复请求、进程终止、晚到响应与换号测试 | Map / Location Ready 前 | Feature Ready 阻塞 |
| `RISK-HAZARD-01` | 现有 `hazard_vote_counts` 在只允许读取本人投票的 RLS 下无法产生全部用户的公开计数 | Hazard 投票、详情与图层 | Schema Catalog 将聚合对象退回 proposed；公开契约只暴露计数，不暴露投票者身份 | 两账户投票后，两者读取相同总计数且不能枚举他人投票；匿名仍拒绝 | Hazard Reporting Ready 前 | Feature Ready 阻塞 |
| `RISK-PROPERTY-01` | 现有实勘允许空地点，照片元数据与 Storage 的部分写/删 policy 只校验路径或行 owner，未完整绑定父实勘 owner | Property、风险快照、照片、回收站 | Schema Catalog 将三个对象退回 proposed 并要求父对象所有权和必需地点 | 尝试跨账户 inspection id 重绑/读写删照片；无地点实勘；回收站清空故障注入 | Property Inspection Ready 前 | Feature Ready 阻塞 |
| `RISK-NFR-01` | 当前仓库尚无 SQLite、文件、本地化、地图和网络最小依赖，非功能约束未有可执行证据 | 全系统 | architecture 固定责任和测试证据，不提前选择具体包版本 | 实现者锁版本后跑依赖审查、两 locale 流程、离线/性能/可访问性测试 | Wave 1–4 相关 owning design Ready 前逐项关闭 | 非 Baseline 阻塞；对应 Feature Ready 阻塞 |

## 明确延后而非静默假设

- Issue #4 已覆盖系统 Interface、数据 Owner、技术架构、非功能约束与跨 Feature 流程；精确成员、
  Adapter、migration 和测试实现仍只在 owning design/学生实现中完成。
- 离线写只授权收藏 create queue、房产草稿和照片待传；其他业务创建、编辑和删除保持在线，不能从
  通用 privacy barrier 或 SQLite 的存在推导离线能力。
- Capability 的全量追踪链、独立系统审查和项目负责人 `Baselined` 批准仍属于后续 Gate；Issue #4
  完成不自动改变系统 `Draft` 状态。
