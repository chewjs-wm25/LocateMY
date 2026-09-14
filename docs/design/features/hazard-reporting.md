# Hazard Reporting

> 状态：`Ready for Development`
> Owner：`A`
> 系统基线：`5d11769`
> 依赖波次：5
> 最后更新：2026-09-14
> Prototype 视觉参考：N/A

本文件是 Hazard Reporting 与其消费者的高层协调设计。它固定公共报告、作者管理、投票、
地图贡献和风险计数的可观察语义；Feature 内部状态、查询、分页实现、RPC 调用、并发处理
和测试组织归实现 Owner。

## 1. 用户成果与范围

- 用户成果：已开启账户范围的用户可创建五类真实远端隐患报告，读取公共图层与详情，赞成、
  反对或撤回自己的票，并在“我的隐患报告”中标记自身处理状态、定位及确认删除自己的报告。
  房产实勘可取得明确口径的附近公共隐患数作为风险快照输入。
- 包含的 Capability ID：`HAZ-01`、`HAZ-02`、`HAZ-03`、`HAZ-04`。
- 不包含及原因：不产生官方犯罪统计或安全指数，不解释地图手势/底图，不审核、隐藏或代删
  报告，不让处理状态暗示平台核验，也不拥有房产风险快照。
- 产品事实源：[隐患上报与管理](../../knowledge_base/locatemy_product/features/hazard_reporting.md)、
  [大学提交承诺](../../knowledge_base/locatemy_product/submission_commitments.md#隐患报告)、
  [核心业务对象](../../knowledge_base/locatemy_product/domain_objects.md#hazard-report-隐患报告)。
- 原型差异：固定示例、内存投票与假删除替换为远端报告、持久化 vote 和作者权限；类型没有
  默认选择；公共图层、详情、分页、刷新、定位和投票均为真实结果，离线写不伪装为已排队。

## 2. 依赖、责任与文件边界

| 模块 / 文件边界 | Owner | 负责 | 不负责 | 与其他模块的沟通 |
| --- | --- | --- | --- | --- |
| `lib/features/hazard_reporting/` | Hazard Reporting | 报告、本人状态/投票私有视图、远端读写、计数、范围分页、详情和图层贡献 | 地图、导航、账户 scope、官方安全和房产快照 | 消费 `SHELL-001`、`LOCATION-002`、`PRIVACY-001`；提供 `HAZARD-001`、`HAZARD-002` |
| `lib/app/` 组合槽位 | Application Shell | 新建、详情、本人列表、状态标记、删除确认与返回语境 | 报告字段、权限、投票或图层内容 | 通过 `SHELL-001` 接受类型化业务意图与可观察结果 |
| Map / Location | Map / Location | 长按或明确地图入口的合法创建意图、图层宿主和点击回传 | 报告内容、范围查询、写入、详情或计数 | `LOCATION-002` 只传创建/点击意图或声明式贡献；Map 不改全局分析地点 |
| Account Privacy | Account Privacy | opened scope 与关闭时 privacy barrier | 远端报告删除或公共读缓存 | 通过 `PRIVACY-001` 清除旧账户的本人/投票私有状态和未完成请求 |
| Supabase 受控数据对象 | Hazard Reporting | 本表及 RPC 的权威远端读取/写入 | 客户端高权限或绕过 RLS | 字段、RLS、migration 只由 [Schema Catalog](../data/schema-catalog.md) 定义 |

共享文件边界只包括 `lib/app/` 的组合入口，以及由项目负责人维护顺序、学生按 Schema
Catalog 落地的 `supabase/migrations/`。Feature Owner 可在 `lib/features/hazard_reporting/` 内
自行组织实现文件；不得以此改变 Shell、Map、privacy 或 schema 的公开契约。

### 依赖与未决项

| 依赖或问题 | 影响 | 验证方式 / 最迟解决点 |
| --- | --- | --- |
| `D18` / `SHELL-001` 已 Ready | 只有 opened 主应用接受新建、详情、本人列表、状态标记和返回意图 | 集成验证导航拒绝不伪装为读写失败，且返回原任务语境 |
| `D19` / `LOCATION-002` 已 Ready | 创建坐标与图层/点击意图必须通过 Map seam，不读写全局选点 | 验证长按、明确入口、非法坐标、viewport 更新和点击均不改变分析地点 |
| `D20` / `PRIVACY-001` 已 Ready | 本人/投票私有状态不会跨账户展示、提交或重放 | 验证退出、换号和晚到请求只保留完全去身份公共读缓存 |
| `RISK-HAZARD-01` | 全局计数依赖安全 RPC 而非读取他人 vote | 实现/集成以两账户、匿名、无效调用者和安全 `search_path` 验证；不阻塞本设计审查 |
| `RISK-HAZARD-02` | 现有 report update policy 须收紧为发布后仅作者状态更新 | 实现/集成验证作者状态成功，已发布内容、非作者及维护者更新均被拒绝；不阻塞本设计审查 |
| `HAZARD-002` 的下游采用 | 2,000m pending-only 计数将由 Property 随风险快照保存 | Property Ready 前验证边界、状态与 failure/partial 语义 |

## 3. 对外协调契约

### 提供

| ID | 消费者 | 动作与可观察事实 | 输入、结果与失败语义 | 权限与副作用边界 |
| --- | --- | --- | --- | --- |
| `HAZARD-001` | Application Shell；Map / Location | 创建、读取公共报告/详情、本人列表、本人状态标记/删除和本人投票；提供声明式公共图层及类型化详情/创建意图。报告类型固定为 flood、crime、traffic、infrastructure、other；状态只为作者自己的 `pending/resolved`。 | 输入为 opened scope、由 `LOCATION-002` 给出的合法创建意图、创建字段、本人状态动作、viewport/分页、稳定报告 ID 或 vote 动作。创建前可更正 type、标题、描述和位置；成功发布后 type、trim 后标题、描述、位置、report time 与 author 不可编辑。状态成功返回权威更新记录；公共读取返回页及其完整性；本人列表只返回该账户作者记录；投票返回当前账户选择与全局计数。标题 trim 后为空、超长字段、无效类型/坐标、缺失 ID、空页、权限拒绝、冲突或可重试不可用均明确分类；空页不等于图层完整为空。 | authenticated 才可读公共报告；仅作者创建、更新自身状态或删除自己的报告；每账户每报告至多一行 vote，赞成/反对更新本人行，撤回删除本人行。计数只通过 `hazard_vote_counts` 读取，不直接由客户端写入，也不暴露投票者身份；无审核/维护者例外。隐患写必须在线。 |
| `HAZARD-002` | Property Inspection | 为一个合法房产地点返回附近公共隐患计数，供创建、坐标改变或显式风险刷新时随快照保存。 | 输入为合法房产地点。输出为 count、2,000m 半径、统计时间和 available，或带原因的 unavailable/partial；只计 Haversine `d <= 2,000m` 的 `pending` 公开报告，`resolved` 不计。失败或 partial 不返回 0。 | 只读公共报告，不写实勘、报告或快照；调用不改变图层、报告状态或官方安全结果。Property 决定何时将完整结果写入其私有风险快照。 |

### 消费

| ID | Owner | 使用目的 | 调用方依赖的结果与失败语义 |
| --- | --- | --- | --- |
| `SHELL-001` | Application Shell | 在 opened scope 中导航并组合新建、详情、本人列表、作者状态标记/删除确认和返回语境 | `accepted` 才进入业务任务；authentication required、过期或不适用目的地保留可理解原因，不能改成报告或网络失败 |
| `LOCATION-002` | Map / Location | 接受长按或明确地图入口的创建意图、提交声明式图层、接收点击详情意图 | accepted/hidden/rejected 与类型化点击按 Map 契约处理；非法或范围外坐标不能打开可提交写入；旧 viewport 结果不得覆盖新 viewport，图层不静默改全局地点 |
| `PRIVACY-001` | Account Privacy | 门控账户私有本人/投票状态，并在关闭时清理 | 仅同账户 opened scope 显示、提交或保留作者/投票状态；关闭失败时旧私有内容仍不可读，公共去身份缓存可保留 |

## 4. 用户可观察行为与跨模块流程

| 入口或用户动作 | 成功结果 | 空、不可用或失败结果 | 必须保持的可访问性 / 安全语义 |
| --- | --- | --- | --- |
| 明确“上报隐患”入口或地图合法长按 | 表单有五种本地化类型、必填去空白标题、可空描述和地点；在线提交显示进行中，成功后可进入本人列表/详情并刷新图层 | 类型未选、标题为空/越限或地点无效给字段错误；网络/服务失败保留输入并给重试；离线说明需联网，不显示 queued/created | 类型不预选；错误紧贴字段且焦点移到首个无效字段；提交防重复；Map 长按/提交不改变分析地点 |
| 创建前更正与发布后状态标记 | 提交前可更正类型、标题、描述和位置；发布后作者仅可将自身报告标为 pending/resolved，成功后详情、本人列表和受影响地图条目显示权威状态 | 创建字段按表单校验；已发布内容/位置/时间/author 无编辑入口且任何写入被拒绝。非作者状态更新为 permission denied；报告已删除或并发状态更新为 conflict/not found；可重试失败不伪称已保存。重新读取后，晚到状态保存不得覆盖较新的状态或删除 | 只有作者看到并可执行状态标记；状态不代表审核。状态写在线执行，文字说明保存中、失败或冲突，不以颜色为唯一反馈 |
| 读取公共图层、viewport 分页及点击详情 | authenticated 用户看到已成功页的报告和可打开详情；图层点击只产生 Hazard 定义的稳定报告 ID/详情意图 | 首页完整空才说明范围内暂无报告；后页失败保留成功页并标示不完整，不能称无内容；未认证为 authentication required | 文字说明加载、空和不完整；Map 仅呈现贡献/回传意图，不泄露其内部对象；报告不进入安全指数或地点适配度 |
| 详情投票或撤回 | 当前账户选择赞成/反对/无票与全局 up/down 计数保持一致；并发写后的权威结果不产生一账户多票 | 权限、报告已删除、冲突或网络失败显示结果未确认并允许重新读取/重试，不把本地猜测当权威计数 | 只能读取自己的投票状态；计数不含投票者身份；颜色不是赞反或失败的唯一表达 |
| 我的报告、定位、状态及删除 | 只显示当前账户的报告；定位通过 Shell/Map 返回式任务；作者可将 pending/resolved 切换，删除经确认后从本人列表和公共图层移除 | 本人无报告显示明确空态；非作者状态/删除被拒绝；确认取消无副作用；失败保留现有记录与重试入口 | 不显示已发布内容编辑或其他账户作者管理入口；状态、删除都是远端业务写且需在线；状态不称审核结果 |
| 账户切换、退出或关闭中请求完成 | 旧账户的本人列表、投票选择和未完成请求清除/丢弃；新账户只有其自身私有状态，去身份公共缓存可保留 | close 未完成时保持无私有内容并提供重试，不重放旧账户写入 | 遵守 `PRIVACY-001` 的先阻断再清理；远端记录不因退出被删除 |

跨 Owner 完成条件：Shell 只在 opened scope 接受入口/返回意图；Map 通过 `LOCATION-002`
交付创建、点击和图层意图；Hazard 读写其权威对象并回传领域结果；Shell 组合页面。
Property 另以 `HAZARD-002` 取得 complete count 与时间，连同其自身安全结果组成风险快照；任一
必需输入不可用时不制造部分新快照。

## 5. 数据与确定性业务规则

| 目的 | 权威对象或事实源 | 访问 / 应用边界 | 必须保持的语义 |
| --- | --- | --- | --- |
| 报告、状态与作者权限 | [隐患事实源](../../knowledge_base/locatemy_product/features/hazard_reporting.md)；`crowdsourced_hazards`（完整定义见 [Schema Catalog](../data/schema-catalog.md)） | authenticated 读公共远端记录；author-only insert/delete 与自身状态更新；按范围和分页读图层 | 仅五类；创建提交前按 trim title 1–120、可空 description ≤2000 与 WGS84 location 校验。发布后 type/title/description/location/report time/author 不可变，作者仅能更新 pending/resolved。永无 verified/rejected、审核/隐藏/维护者删除；公开不等于匿名 |
| 一人一票与全局计数 | `crowdsourced_hazard_votes`、`hazard_vote_counts` | 底层 votes 只由本人读写；客户端以受控 RPC 得全局 counts | 每账户每报告至多一票 `-1/+1`，撤回删除本人行；RPC 只对 authenticated 生效，只返回 hazard ID/up/down count，不泄露投票者身份；固定安全 search path、调用者验证及 execute 授权以 Schema Catalog 为准 |
| 图层范围与分页 | `crowdsourced_hazards` 与 `LOCATION-002` | 以 Map viewport/分页请求读公共报告，并为每项提供稳定领域 ID 和详情意图 | 成功页可逐页累积；无页/失败/partial/过期请求互不混同。Map 不拥有筛选、内容或读取权限；较旧 viewport 不能覆盖较新 viewport |
| 房产风险附近数 | [隐患事实源的 HAZARD-002 规则](../../knowledge_base/locatemy_product/features/hazard_reporting.md#房产风险快照的附近隐患数) | 对合法房产坐标最终按 Haversine 圆形距离计算；矩形仅可预筛选 | 固定 2,000m，含 `d <= 2,000m` 边界，只计 `pending` 公共报告；回带半径/统计时间/available。resolved、失败或 partial 永不当 0 |
| 私有状态与离线边界 | [数据所有权](../system/data-ownership.md)；`PRIVACY-001` | 仅本人/投票视图状态和未完成请求是账户私有；写入全为在线 | 清理旧账户私有状态；完全去身份公共读缓存可保留。报告、状态、投票和删除不进入离线队列 |

## 6. 验收与 Ready Gate

| Capability | 验收情景 | 用户操作 | 可观察结果 |
| --- | --- | --- | --- |
| `HAZ-01` / `AT-HAZARD-01`、`AT-HAZARD-05` | 五类创建与验证 | 从明确入口和合法长按各创建一份报告 | 类型、trim 标题、描述/地点校验、加载、成功、失败重试和真实远端创建均可观察；无默认类型或离线伪排队 |
| `HAZ-01`、`HAZ-04` / `AT-HAZARD-01`、`AT-HAZARD-03` | 创建前更正、作者状态与删除 | 创建提交前更正类型/标题/描述/位置；发布后作者切换 pending/resolved，确认删除；另一账户尝试状态/删除或任何人尝试改已发布内容 | 创建字段校验、permission、contract failure、conflict/not found 和 retryable failure 各自可见；成功状态后详情、本人列表和地图受影响条目刷新，晚到状态保存不覆盖更新/删除；已发布内容不可变，状态不表示审核，删除取消无副作用 |
| `HAZ-02` / `AT-HAZARD-01`、`AT-HAZARD-02` | 图层、详情、范围分页 | authenticated 用户移动 viewport、加载多页、点击报告 | 图层/详情来自远端，点击回传类型化意图；完整空、后页失败和 partial 清楚区分，已成功页保留；Map 不改分析地点 |
| `HAZ-03` / `AT-HAZARD-03`、`AT-HAZARD-04` | 单票、撤回与安全计数 | 两账户对同一报告投相反票、改票或撤回；匿名读取 | 每账户最多一票；两账户看到同一 up/down count；任一账户无法枚举他人 vote，匿名与无效调用者不能取得 counts |
| `HAZ-03` / `AT-HAZARD-04` | 并发与失败 | 同账户并发 vote，或在写后发生网络/删除冲突 | 权威读取后不出现双票或虚构计数；失败显示未确认并可重试/刷新 |
| `HAZ-04` / `AT-HAZARD-01`、`AT-HAZARD-03` | 本人列表、定位与账户切换 | 查看本人列表、定位、退出并以另一账户进入 | 仅本人记录可管理；定位保留返回任务；旧账户作者/投票状态和未完成请求不出现、不提交或重放 |
| `HAZARD-002` / `AT-PROP-03` | 风险计数口径 | 对内/外、恰 2,000m、pending/resolved 报告请求计数 | 仅边界内及恰边界的 pending 被计数；结果带半径、统计时间与 available；failure/partial 不为 0，且不写快照 |
| 全部 / `AT-HAZARD-01`–`AT-HAZARD-05` | 可访问性与范围隔离 | 阅读加载、空、错误、投票、状态和安全说明 | 每种状态有文字、非颜色唯一表达；隐患不进入安全指数、地点摘要或适配度，且无审核功能 |

- [x] `HAZ-01`–`04` 追踪至唯一 Owner、`HAZARD-001`、数据对象、产品事实与验收情景；
  `HAZARD-002` 的下游口径、失败语义和 Property 消费者明确。
- [x] `D18`–`D20` 与上游 Ready designs 一致：Feature 不拥有 Shell、Map 或账户 scope。
- [x] RLS/权限、输入无效、空页、分页/离线不可用、并发 vote、账号切换、作者隔离及图层点击均有可观察语义。
- [x] 项目负责人已为 `RISK-HAZARD-01` 选定安全 RPC 契约，并为 `HAZARD-002` 固定 2,000m
  pending-only Haversine 口径；运行时 migration/RLS 证据留实现/集成验收。
- [x] 项目负责人 Q8 已固定发布后报告不可变；`RISK-HAZARD-02` 的 status-only migration 与
  权限/跨视图运行时证据留实现/集成验收。
- [x] 独立 Standards/Spec 双轴复审均通过；设计 AI 已依 ADR 0013 完成 Ready 批准。

## 7. Change Log

| 日期 | 状态 | 变更原因 | 受影响的 Capability / Interface / 数据对象 / Feature | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Draft` | Issue #14 建立 Wave 5 owning design；项目负责人固定安全 vote-count RPC 及 HAZARD-002 的 2,000m pending-only 口径 | `HAZ-01`–`04`、`HAZARD-001`、`HAZARD-002`、`crowdsourced_hazards`、`crowdsourced_hazard_votes`、`hazard_vote_counts`、Property Inspection | 项目负责人（Q6、Q7） |
| 2026-09-14 | `Draft` | 项目负责人 Q8 覆盖先前内容编辑假设：发布后内容、位置和上报时间不可变，作者只可标记自身 pending/resolved 或删除 | `HAZ-01`、`HAZ-04`、`HAZARD-001`、`crowdsourced_hazards`、Application Shell、Map / Location、Account Center | 项目负责人（Q8） |
| 2026-09-14 | `Ready for Development` | 独立 Standards/Spec 双轴复审关闭全部发现；依 [ADR 0013](../../adr/0013-autonomous-design-ai-ready-approval.md) 批准 Ready | `HAZ-01`–`04`、`HAZARD-001`、`HAZARD-002`、D18–D20 | 设计 AI（项目负责人授权） |
| 2026-09-14 | `Ready for Development` | Account Center 双轴审查移除其作为 `HAZARD-001` 消费者的错误登记；账户入口只提交 Shell 导航意图，不读取隐患数据 | `HAZARD-001`、`SHELL-001`、Account Center | 设计 AI（项目负责人授权） |
| 2026-09-14 | `Ready for Development` | 全面设计审查修复验收表并补齐 canonical `AT-HAZARD-*` / `AT-PROP-03` 追踪；不改变可观察契约 | `HAZ-01`–`04`、`HAZARD-002`、`FLOW-05`、`FLOW-06` | 项目负责人（本次审查） |
