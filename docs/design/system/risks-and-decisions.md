# 系统风险与待决项

> 状态：`Baselined — Issue #5 dispositions recorded at 5d11769`
> 最后更新：2026-09-14

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
| 发布后隐患内容不可变 | 项目负责人 Q8 决定 | 创建前允许修正表单；发布后仅作者可更新自身 `pending/resolved` 状态或删除，内容/位置/上报时间不被任何角色修改 |

这些约束是已批准产品事实在系统 seam 上的直接表达，尚未达到“难以逆转且经过真实技术取舍”的
ADR 门槛。若后续验证迫使改变它们，再由项目负责人决定是否记录 ADR。

## 风险与关闭条件

| ID | 风险 | 影响范围 | 当前控制 | 验证方式 | 最迟关闭点 | 阻塞性 |
| --- | --- | --- | --- | --- | --- | --- |
| `RISK-SESSION-01` | Supabase Flutter SDK 在 token 过期、离线和刷新失败时可能保留不可用于门控的本机会话 | `AUTH-001`、`NAV-01`、离线启动 | 只允许明确有效或成功刷新的会话打开账户范围；过期缓存、刷新中和刷新失败均保持门控 | 项目锁定版本的官方源码与测试确认冷启动、过期 token、可重试网络失败和远端拒绝；见[关闭证据](#risk-session-01-关闭证据) | 2026-09-14 已关闭；`supabase_flutter` / `gotrue` 版本改变时重开 | 已关闭；不再阻塞 Authentication Ready |
| `RISK-PRIVACY-01` | 未完成所有 Feature 设计前，私有状态 Owner 清单可能漏项，导致退出后残留 | `PRIVACY-001`、`ACCOUNT-07`、所有私有 Feature | privacy barrier 使用显式 Owner 清单；未登记 Owner 不能进入集成 | Ready 前：对照完整 Feature map、Schema Catalog 与数据所有权审查清单和每项关闭结果；集成验收：对每个实际 Owner 注入清理失败 | Ready 前关闭设计风险；实现后的 Account Privacy 集成验收关闭运行时证据 | Ready 阻塞（设计审查）；集成阻塞（运行时证据） |
| `RISK-PRIVACY-02` | 结束认证会话后本机物理清理失败，用户无法安全进入下一账户 | `AUTH-001`、`PRIVACY-001`、账户切换 | 先阻断旧范围读取；失败停在无私有内容的清理恢复态，重试幂等 | Ready 前：审查故障时仍关闭旧范围、可恢复关闭的可观察契约与验收情景；集成验收：文件/SQLite 不可写、部分已处理和进程重启故障注入 | Ready 前关闭设计风险；实现后的 Account Privacy 集成验收关闭运行时证据 | Ready 阻塞（设计审查）；集成阻塞（运行时证据） |
| `RISK-OSM-01` | Overpass 限流、超时或部分响应可能被误判为真实空结果 | `FACILITY-001`、`FACILITY-002`、`FAC-01` | owning design 已固定只有完整响应才能产生覆盖/未覆盖；其余为 unknown 或缓存降级 | 实现/集成以完整、截断、超时、HTTP 限流和无效 payload 验证 | 设计契约已关闭；实现/集成验收保留证据 | 不再阻塞 Ready；实现/集成验收阻塞 |
| `RISK-CACHE-01` | 坐标精度、分类映射版本或缓存键不一致会复用错误地点/口径结果 | `LOCATION-001`、`facility_public_cache` | owning design 已固定 key 包含坐标、2,000 米半径和分类版本，结果回带原地点 | 实现/集成手工验算邻近坐标、版本升级和 24 小时边界，并断言 key/result 一致 | 设计契约已关闭；实现/集成验收保留证据 | 不再阻塞 Ready；实现/集成验收阻塞 |
| `RISK-CACHE-02` | 公共缓存若混入收藏名称或账户引用，会绕过退出清理泄露兴趣地点 | `facility_public_cache`、`PRIVACY-001` | 公共缓存只保存分析所需坐标、公共结果、时间、版本和归因 | Schema Catalog 审查和退出后存储检查，确认没有账户/用户命名字段 | Schema 对象批准前 | Baseline 阻塞 |
| `RISK-GEO-01` | 马来西亚范围校验的数据源和边界精度曾未固定 | `LOCATION-001`、`MAP-01` | 项目负责人于 2026-09-14 选定已导入、版本和 hash 可审计的 DOSM/OpenDOSM 行政区边界联合范围；边界点合法，海域和范围外坐标拒绝 | Map 实现/集成验收以边境、岛屿、海域及明显范围外坐标验证固定资料；版本变化重开风险 | 设计决定已关闭；实现/集成验收保留证据 | 不再阻塞 Map Ready；实现/集成验收阻塞 |
| `RISK-GEO-02` | 行政区边界资料的版本、空间匹配和多匹配规则尚未固定 | Geographic Context；Cost、Crime、Socio-economic、Infrastructure | Feature map 将行政统计地理解析集中在 Geographic Context；州与行政区各自返回且未解析不使用附近地区替代 | 用边界点、离岛、多边形重叠、无覆盖坐标及不同资料版本验证确定性结果 | Geographic Context Ready 前 | 下游 Feature Ready 阻塞 |
| `RISK-SCHEMA-01` | 现有 migration 的若干镜像名、粒度或字段与批准数据集不一致，且缺少多个 required 数据集 | Home、Crime、Socio、Infrastructure、Transit | Schema Catalog 将旧对象标为新设计不可消费，并登记 canonical 镜像与稳定读取对象 | 对照官方 dataset schema、实际导入行数/最大日期/键唯一性；每个读取对象做完整/空/部分导入验收 | 系统 Baseline Gate 前给出迁移计划；各数据 Feature Ready 前实现 | Baseline 阻塞 |
| `RISK-COST-01` | Cost 的地点指数、个人预案与临时换算口径若未固定，会生成不一致的预算和适配度输入 | `COST-01`–`03`、`ACCOUNT-09` | 项目负责人已固定核心市场指数、个人预案、临时换算和 current 删除语义；完整契约见 [Cost owning design](../features/cost-of-living-and-budget.md) | Cost 实现/集成验证核心篮子缺失、CPI 缺失/不同月、删除最后一份及删除 current 后显式选择 | 设计决定已关闭；实现/集成验收保留证据 | 不再阻塞 Cost Ready；实现/集成验收阻塞 |
| `RISK-TRANSIT-01` | 任一预期 GTFS feed 的旧快照、缺失、失败或超服务日期范围若被混成无服务或完整结果，会把未知路线伪装为交通覆盖 | `TRANSIT-001`、`INFRA-01`、Suitability transit dimension | 项目负责人于 2026-09-14 固定 per-feed usable/stale/missing/failed/out-of-service-range，availability 仅为 available/incomplete/unavailable，且仅 available 有 served/no_stops/no_active_routes；实际使用 stale feed 仅附 warning | Transit 实现/集成验证第 30 天、超过 30 天、可解析/不可解析、分析日边界内/外、部分 feed、零站/零路线及 Infrastructure 同结果复用 | 设计决定已关闭；实现/集成验收保留证据 | 不再阻塞 Transit Ready；实现/集成验收阻塞 |
| `RISK-SCHEMA-02` | `user_ici_preferences` 现有五个 0–1 权重与三项 1–10 产品契约冲突 | Infrastructure、Account Privacy、Suitability | Schema Catalog 明确目标字段和旧表仅作迁移来源；中性 ICI 不读账户权重 | 两账户迁移样本验证三项值、默认 5、旧 safety/amenity 不进入新对象 | Infrastructure Ready 前 | Feature Ready 阻塞 |
| `RISK-PREF-01` | 评估偏好现有数据库默认 5 可能把“尚未设置”误判为已完成五项偏好 | Account、Suitability | Suitability 只接受 `ACCOUNT-001 complete snapshot`；表存在与完成语义由 owning design 明确 | 新账户无偏好、首次保存、部分旧记录与换号场景 | Account Center Ready 前 | 下游 Suitability Ready 阻塞 |
| `RISK-PROP-01` | 风险快照若未把附近隐患数的固定空间口径与可用性一并保存，会使历史读数不可解释 | Hazard、Property、风险快照 | 项目负责人已固定：房产坐标 2,000m Haversine 圆形、`d <= 2,000m`、只计 public `pending`；`HAZARD-002` 回带半径、统计时间和可用性，失败/partial 不当 0 | 用边界内/外、恰 2,000m、pending/resolved 和失败/partial 情景验证；Property 验证随快照保存而非静默重算 | Property Inspection Ready 前 | Feature Ready 阻塞 |
| `RISK-STORAGE-01` | Storage 文件上传与照片元数据写入不是原子操作，清空回收站也可能部分失败 | Property、Account Privacy | 显式队列、可重试不一致状态、owner path 与可证明孤儿补偿 | 注入上传/元数据/删除每一阶段失败和重启，验证无跨账户访问与不误报完成 | Property Inspection Ready 前 | Feature Ready 阻塞 |
| `RISK-SYNC-01` | 收藏前台双向同步的幂等键、冲突和删除传播曾未精确定义 | Map、Account Privacy、跨设备恢复 | 项目负责人于 2026-09-14 决定：每次 create 使用同账户唯一客户端幂等键；Supabase 远端版本为冲突权威；在线删除写入可同步墓碑，旧缓存和晚到队列不得复活已删除收藏 | Map 实现/集成验收覆盖双设备创建/删除、重放、进程终止、晚到响应、墓碑传播与换号；migration 验证唯一键、版本与墓碑访问控制 | 设计决定已关闭；实现/集成验收保留证据 | 不再阻塞 Map Ready；实现/集成验收阻塞 |
| `RISK-HAZARD-01` | 全局投票计数若绕过本人 vote RLS 或暴露投票者身份，会泄露账户行为 | Hazard 投票、详情与图层 | 项目负责人已选受控 `SECURITY DEFINER` RPC：固定空/安全 `search_path`、RPC 内验证 authenticated 调用者、撤销默认及 anon execute，只返回 `hazard_id/upvotes/downvotes`；底层 vote 继续本人可读写 | 两账户写不同票后读取相同计数；任一账户不能枚举他人票；anon、无效调用者和 search-path 注入均被拒绝 | Hazard Reporting 实现/集成验收 | 不再阻塞 Hazard Ready；实现/集成验收阻塞 |
| `RISK-HAZARD-02` | 现有 author-update policy 若允许发布后改写报告内容，会破坏公共报告的不可变性 | Hazard 报告、图层、详情与风险计数 | 项目负责人 Q8 已固定发布后仅作者可更新自身 `pending/resolved`；Schema Catalog 将对象退回 proposed，要求 migration 收紧 update policy | 作者状态更新成功；作者改 type/title/description/location/report time、非作者更新和任何维护者更新均被拒绝；成功状态更新在详情/列表/图层一致可见 | Hazard Reporting 实现/集成验收 | 不再阻塞 Hazard Ready；实现/集成验收阻塞 |
| `RISK-PROPERTY-01` | 现有实勘允许空地点，照片元数据与 Storage 的部分写/删 policy 只校验路径或行 owner，未完整绑定父实勘 owner | Property、风险快照、照片、回收站 | Schema Catalog 将三个对象退回 proposed 并要求父对象所有权和必需地点 | 尝试跨账户 inspection id 重绑/读写删照片；无地点实勘；回收站清空故障注入 | Property Inspection Ready 前 | Feature Ready 阻塞 |
| `RISK-NFR-01` | 当前仓库尚无 SQLite、文件、本地化、地图和网络最小依赖，非功能约束未有可执行证据 | 全系统 | architecture 固定责任和测试证据，不提前选择具体包版本；Application Shell 已冻结本地化和可访问性的可观察契约 | 实现者锁版本后跑依赖审查、两 locale 流程、离线/性能/可访问性测试 | Application Shell Ready 前完成契约审查；运行时证据在其实现/集成验收关闭；其余 Wave 1–4 Owner 仍在各自 Ready 前逐项关闭 | 非 Baseline 阻塞；Application Shell 实现/集成及其他对应 Feature Ready 阻塞 |

## 明确延后而非静默假设

### Issue #5 责任与 Baseline 处置

| 风险 | 责任 Owner | Baseline 处置 |
| --- | --- | --- |
| `RISK-PRIVACY-01` | Account Privacy | 已按全部私有对象、状态、队列和文件核对 8 个参与者；Baseline 阻塞关闭。Ready 审查确认完整清单和关闭不变量；逐 Owner 故障注入留待实现后的集成验收 |
| `RISK-CACHE-02` | 各公共缓存所属分析 Feature | 已核对 Schema Catalog 的具名公共缓存与公共缓存不变量；Baseline 阻塞关闭，各对象批准时验证字段 |
| `RISK-SCHEMA-01` | Geographic Context、Home、Cost、Crime、Transit、Socio-economic、Infrastructure | [Schema 迁移计划](baseline-review.md#schema-迁移计划)已分配 add/migrate/remove、证据与最迟 Gate；Baseline 阻塞关闭，实现仍阻塞各 owning Feature Ready |
| `RISK-COST-01` | Cost of Living & Budget | 项目负责人于 2026-09-14 固定 Cost 口径；完整契约见 [Cost owning design](../features/cost-of-living-and-budget.md)，实现/集成保留缺失、不同月和删除情景证据 |
| `RISK-TRANSIT-01` | Public Transportation | 项目负责人已固定 per-feed 与整体 GTFS 状态矩阵；完整语义见[公共交通事实源](../../knowledge_base/locatemy_product/features/transportation.md)，第 30 天/超 30 天、解析/服务范围边界、部分 feed、零站/零路线及 Infrastructure 复用证据留实现/集成验收 |
| `RISK-SESSION-01` | Authentication & Session | 2026-09-14 已以项目锁定版本证据关闭；依赖版本改变时重开 |
| `RISK-PRIVACY-02` | Account Privacy | Ready 审查关闭隐私屏障与恢复语义；文件/SQLite/部分处理/重启故障注入留待实现后的集成验收 |
| `RISK-OSM-01`、`RISK-CACHE-01` | Nearby Facilities | 保留至 Nearby Facilities Ready |
| `RISK-GEO-01` | Map / Location | 项目负责人已固定 DOSM/OpenDOSM 资料联合范围、边界点合法与海域拒绝；坐标样本证据留 Map 实现/集成验收 |
| `RISK-GEO-02` | Geographic Context | 保留至 Geographic Context Ready |
| `RISK-SCHEMA-02` | Infrastructure Coverage | 保留至 Infrastructure Ready |
| `RISK-PREF-01` | Account Center | 保留至 Account Center Ready |
| `RISK-PROP-01`、`RISK-STORAGE-01`、`RISK-PROPERTY-01` | Property Inspection（`RISK-PROP-01` 的 2,000m pending-only 口径已由项目负责人批准） | 保留至 Property Ready；风险快照保存及运行时证据仍待验证 |
| `RISK-SYNC-01` | Map / Location | 项目负责人已固定客户端幂等、远端版本权威与删除墓碑传播；双设备/重放/换号证据留 Map 实现/集成验收 |
| `RISK-HAZARD-01` | Hazard Reporting | 项目负责人已选安全 RPC 契约；两账户、匿名和安全 search-path 运行时证据留实现/集成验收 |
| `RISK-HAZARD-02` | Hazard Reporting | 项目负责人 Q8 已固定发布后内容不可变；status-only update migration 与权限/一致性证据留实现/集成验收 |
| `RISK-NFR-01` | 各相关 owning Feature；Application Shell 汇总 | Application Shell 已于 2026-09-14 完成门控、语言和可访问性契约审查并进入 Ready；运行时依赖/两 locale/可访问性证据留在其实现与集成验收。其余 Wave 1–4 owning design 仍逐项关闭。 |

上表为责任与 Gate disposition；风险内容、影响、验证方式和最迟关闭点仍只在主表定义。

### `RISK-SESSION-01` 关闭证据

- **证据版本**：项目 `pubspec.lock` 锁定
  [`supabase_flutter 2.17.2`](https://github.com/supabase/supabase-flutter/tree/supabase_flutter-v2.17.2) 与
  [`gotrue 2.27.2`](https://github.com/supabase/supabase-flutter/tree/gotrue-v2.27.2)；两个官方标签均指向 `d343292`。
- **执行证据**：在该标签运行官方现有测试
  `flutter test packages/gotrue/test/get_session_test.dart packages/gotrue/test/refresh_token_race_test.dart packages/supabase_flutter/test/auth_test.dart`，
  22 项全部通过。测试覆盖无会话/有效会话冷启动、过期缓存、按需刷新、并发恢复、可重试网络失败及无效刷新 token 的远端拒绝。
- **观察结论**：冷启动可先读到本机缓存，缓存对象即使存在也可能已过期；过期会话成功刷新后才可作为已认证事实。
  可重试网络失败不会把过期缓存提升为有效会话；无效刷新 token 会清除当前会话并产生非自愿退出结果。
- **契约处置**：上述行为与 `AUTH-001` 的“不可确认时无私有内容”一致，无须把 SDK 方法、事件、重试、时序或
  Adapter 策略冻结进 Feature 设计。实现验收须从用户可观察结果证明门控成立；升级任一锁定依赖时重新打开本风险。

### `RISK-GEO-02` 资料决定与未关闭证据

- **项目负责人决定（2026-09-14）**：行政统计地理资料采用 DOSM OpenDOSM
  `administrative_2_district.geojson` 的 Git commit
  `21a78e98efd4cd9b022a27a1bf67d167076b7591`；实际导入审计还必须记录该文件的
  SHA-256 `3edb1022b2de371bba6b7afb9802b6fc6d747c86dbcc40abf2374a9134f3c561`。许可依据、
  固定文件链接与研究边界见[决策简报](../../research/geographic-context-boundary-source-decision-brief-2026-09-14.md)。
- **范围变更（2026-09-14）**：项目负责人确认警区多边形资料不可获取，故移除警区解析与 `SAFE-02`，
  `police_districts_boundary` 退役。Crime 仅消费行政边界解析出的州，并聚合 `crime_district.state`；不得以
  行政区、警局点位或第三方资料产生警区结果。
- **空间语义决定（2026-09-14）**：边界点或重叠区的每个覆盖行政区都是候选；多个候选一律完整返回
  `ambiguous`，不按面积、名称或邻近性挑选。此规则也约束统计州，因此州级治安在多州候选时不可用。源内
  退化环可在导入时修复为有效多边形；审计必须同时保留原始 source hash、修复标识和派生几何 hash。资料
  本身的重叠不裁剪、不合并。
- **本地资料验证（2026-09-14）**：已下载固定 commit，SHA-256 与批准值一致。PostGIS 3.5.2 验证 160 个
  `MultiPolygon`、16 个州/联邦直辖区、160 个唯一边界标识和 WGS84 SRID；7 个含退化环的几何经
  `ST_CollectionExtract(ST_MakeValid(...), 3)` 后均有效且非空，确定性派生几何清单 hash 为
  `929e7ce03417d284972f6550820806d0a29179f532b1c6c77f6bf5473bc1cb7f`。固定样本验证了非主离岛、
  边界点（两个候选）、零覆盖、合成重叠和不同资料版本；原资料有 311 对正面积重叠，其中 56 对跨州，均按
  `ambiguous` 保留。
- **远端关闭证据（2026-09-14）**：已关联 Supabase 项目已导入 160 行修复后边界及 1 行不可变审计；
  无效/空几何为 0，16 个州/联邦直辖区均在。稳定 RPC 对离岛返回 1 个候选、对固定真实边界点返回 2 个候选、
  对范围外点返回 0 个候选；每行均关联审计。authenticated 无直接表读权但可执行 RPC，anon 无 RPC 权限。
  外键覆盖索引与 GiST 空间索引均已建立。`RISK-GEO-02` 的资料、空间和读取风险已关闭；项目负责人已接受
  authenticated-only 受控 RPC 例外并于 2026-09-14 批准 Geographic Context 转为 `Ready for Development`。

- Issue #4 已覆盖系统 Interface、数据 Owner、技术架构、非功能约束与跨 Feature 流程；跨 Owner
  可观察语义在 owning design 完成，Adapter、migration 和测试实现仍由 Owner/学生实现。
- 离线写只授权收藏 create queue、房产草稿和照片待传；其他业务创建、编辑和删除保持在线，不能从
  通用 privacy barrier 或 SQLite 的存在推导离线能力。
- Capability 全量追踪与独立系统审查已由 Issue #5 完成；项目负责人已于 2026-09-13 批准
  `5d11769` 为 `Baselined`。后续风险按各 owning design 的 Ready Gate 关闭。
