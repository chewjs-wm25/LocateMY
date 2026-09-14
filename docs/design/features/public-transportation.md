# Public Transportation

> 状态：`Ready for Development`
> Owner：`A`
> 系统基线：`5d11769`
> 依赖波次：`5`
> 最后更新：`2026-09-14`
> Prototype 视觉参考：`N/A`（产品事实源记录原型差异）

本文件是公共交通 Feature 与消费者的高层协调设计。它冻结地点周围的 GTFS 覆盖读数、
可用性和局部呈现契约；不规定 GTFS 解析/导入、Flutter/Supabase 内部结构、缓存、请求策略或测试组织。

## 1. 用户成果与范围

- 用户成果：用户可查看一个合法地点周围 1.5 公里的站点实体、最近站距离、分析日期有效的
  路线数和交通连通性分；站点列表与本页站点分布图可局部联动。地点 A/B 时，用户可并列
  两端各自带来源、日期、范围和可用性的交通结果；Infrastructure 读取完全相同的连通性事实。
- 包含的 Capability ID：`TRANSIT-01`、`TRANSIT-02`、`TRANSIT-03`。
- 不包含及原因：不拥有 GTFS 手动取得/解析/导入、地点选择、主地图相机或全局 Marker、路线
  导航、实际步行路径、班次/票价/通勤时间/服务质量评价、ICI 聚合或个人化地点适配度。站点
  的粗略步行分钟仅为展示提示，不进入分数。
- 产品事实源：[公共交通](../../knowledge_base/locatemy_product/features/transportation.md)、
  [单个地点基础设施指数：公共交通](../../knowledge_base/locatemy_product/infrastructure_index_scoring.md#公共交通)、
  [核心业务对象](../../knowledge_base/locatemy_product/domain_objects.md#transit-coverage-公共交通覆盖)、
  [UI 规则](../../knowledge_base/locatemy_product/ui_design_spec.md#公共交通)。
- 原型差异：以标准化官方 GTFS 结果取代固定 72/80 分、固定站点/路线数及 fixture；“热力图”
  固定称为本页的“站点分布图”，不成为主地图图层，也不提供导航或“在主地图上查看”。

## 2. 依赖、责任与文件边界

| 模块 / 文件边界 | Owner | 负责 | 不负责 | 与其他模块的沟通 |
| --- | --- | --- | --- | --- |
| `lib/features/public_transportation/` | Public Transportation | 标准化 GTFS 只读结果、站点/有效路线口径、`TRANSIT-001`、`STATE-TRANSIT-SELECTION`、本页站点分布图 | Feed 导入、可变地点、主地图、ICI/适配度聚合 | 消费 `SHELL-001`、`LOCATION-001`；向 Shell、Infrastructure、Suitability 提供 `TRANSIT-001` |
| `lib/app/` | Application Shell | 将合法单点/A-B 快照导航至交通页，组合带元数据的摘要/比较结果及返回语境 | 交通计算、站点选择、资料完整性判断 | 经 `SHELL-001` 接受 Feature 导航与声明式结果；不改写可用性或站点选择 |
| `lib/features/map_location/` | Map / Location | 发布不可变合法地点引用，并寄宿声明式站点分布图 | GTFS 读取、站点选择、交通可用性 | `LOCATION-001` 提供地点快照；`LOCATION-002` 只接收当前交通页的中心/圆/Marker/选中意图，不改写 single/A/B |
| 标准化 GTFS 读取对象 | Public Transportation / 受控维护导入 | Feed 快照、站点、路线、服务日期、固定参照网格和交通聚合结果 | Flutter 直接下载 ZIP 或猜测资料缺口 | Flutter 只读取 `read_transit_analysis`；对象与访问规则由 [Schema Catalog](../data/schema-catalog.md#标准化-gtfs-对象)定义 |
| `lib/features/infrastructure_coverage/` | Infrastructure Coverage | 以其 ICI 规则消费交通分项 | 重查站点、路线、百分位或生成第二个交通结果 | 只消费与地点、范围、分析日期和资料版本相同的 `TRANSIT-001` 连通性事实 |

Owner 可在自己的目录内组织内部文件；上述受控边界不冻结 DTO、查询形状、GTFS parser、
缓存、并发/取消、刷新、重试或测试策略。

### 依赖与未决项

| 依赖或问题 | 影响 | 验证方式 / 最迟解决点 |
| --- | --- | --- |
| `D16` / `SHELL-001` 已 Ready | 交通页、A/B 与返回只在 opened 主应用中导航和组合 | 以 `FLOW-02`、`FLOW-03` 和 `AT-ANALYSIS-01`/`AT-COMPARE-03` 核对；无阻塞 |
| `D17` / `LOCATION-001`、`LOCATION-002` 已 Ready | 读取结果绑定合法、不可变 single/A/B 地点快照；站点分布图通过既有声明式地图 seam 寄宿 | `absent`、`invalid coordinate`、`outside Malaysia` 或过期地点请求由 Shell/Map 拒绝，不能转为 no-service；中心/圆/稳定 Marker/选中意图仅以 `accepted`/`hidden`/`rejected(reason)` 呈现，且不改地点；无阻塞 |
| 标准化 GTFS 对象和 `read_transit_analysis` | 真实结果、完整性、来源和固定参照组的唯一读取入口 | Transit 实现前验证官方 16 feed 的来源登记、快照/解析/服务日期、键、覆盖登记、参考网格及完整/失败导入；首次导入失败显示资料暂不可用，不用 fixture 代替 |
| `RISK-TRANSIT-01` 已关闭 | per-feed、availability 与 service outcome 具有确定性可观察语义 | 每个预期 feed 独立为 usable/stale/missing/failed/out-of-service-range；全部 usable 或 stale 才为 availability available，部分为 incomplete、无 usable/stale 为 unavailable；仅 available 再有 served/no_stops/no_active_routes，stale 仅为 available warning。第 30 天、超 30 天、解析/范围边界与部分 feed 留实现/集成验收 |

## 3. 对外协调契约

### 提供

| ID | 消费者 | 动作与可观察事实 | 输入、结果与失败语义 | 权限与副作用边界 |
| --- | --- | --- | --- | --- |
| `TRANSIT-001` | Application Shell；Infrastructure Coverage；Personalized Location Suitability | 对一个不可变合法地点和明确分析日期，提供 1,500m 圆内的站点/路线聚合、最近距离、交通连通性及完整来源/可用性。 | 输入为 `LOCATION-001` single/A/B 快照及分析日期。结果带半径、地点、分析日期、生成时间、每个预期/实际使用 feed 的官方 source id/URL、snapshot id、`feed_captured_at`、解析状态、服务日期覆盖、固定参照组版本、站点/路线聚合事实、分数、availability、仅 availability 为 available 时的 service outcome，以及 stale warning。完整两层矩阵只以[公共交通事实源](../../knowledge_base/locatemy_product/features/transportation.md#数据处理边界)为准。 | 仅在 Shell 已为同账户 opened scope 接受的主应用旅程使用。接口只发布 canonical connectivity result，不携带页面选择或地图呈现；消费者不得把失败/部分当作零、重查原始 GTFS 或重算分数。 |

`TRANSIT-001` 的**canonical connectivity result**是同一地点快照、1,500m、分析日期和同一
GTFS 快照/参照组版本下的一份聚合结果。它是交通页、Shell 摘要、A/B 组合、Infrastructure
交通分项和 Suitability 所能消费的唯一连通性事实；消费者不得以原始 stops/routes 重算、
替换百分位或补造另一份分数。只有主状态为 `available` 的已计算分数可被消费；`stale` 仅是
该完整结果的附加警告，不改变主状态。其余主状态的交通分不可用，明确观测到的站点/路线零值仍按自身语义保留。

本页的站点选择和分布图是 Transit 的页面内部可观察行为。Transit 经 `LOCATION-002` 提交
`analysis centre + 1.5km circle + 当前结果稳定 station markers + 可选高亮 station` 的声明式呈现，
Map 只寄宿并返回选中意图；选择仍由 Transit 维护，不移动全局选点、不改变主地图中心，也不触发路线导航。

### 消费

| ID | Owner | 使用目的 | 调用方依赖的结果与失败语义 |
| --- | --- | --- | --- |
| `SHELL-001` | Application Shell | 从单点/A-B 摘要进入交通页、回到来源任务，并组合每端交通贡献 | 合格的地点/分析目的地得到 `accepted`；输入缺失、过期、scope 未开启或目的地不适用时为 `rejected(reason)`/`authentication required`，不改写为交通资料失败。 |
| `LOCATION-001` | Map / Location | 取得 single 或 A/B 的合法不可变地点引用 | 只接受 valid snapshot；`absent`、范围外、无效、同一点或 scope 关闭时不请求交通资料、不显示 no-service，也不使用默认城市或较旧可变选点。 |
| `LOCATION-002` | Map / Location | 提交当前交通页的声明式中心、圆、稳定 Marker 与选中意图，并接收 Map 的呈现结果 | `accepted`、`hidden` 或 `rejected(reason)` 不改变交通数据或 global location；点击只回传 `feed_id + stop_id` 选中意图，Map 不解释站点内容。 |

## 4. 用户可观察行为与跨模块流程

| 入口或用户动作 | 成功结果 | 空、不可用或失败结果 | 必须保持的可访问性 / 安全语义 |
| --- | --- | --- | --- |
| 打开合法单点交通分析 | 显示距离排序的最近 30 个站点、范围内完整站点数、最近距离、有效路线数、连通性分、范围/分析日期和 feed provenance | 仅完整资料可判 no stops/无有效路线；部分 feed 为 incomplete、无可用 feed 为 unavailable，实际使用 stale feed 另有可能过期警告；均不以 0 分替代不可用 | 所有数值、状态、来源、日期与范围有文字；交通分是覆盖读数，不称通勤/票价/质量评价。 |
| 打开 A/B 交通比较 | 并列两端各自 canonical result 与 provenance；只有分析日期、半径、资料完整性和参考快照/网格口径可比时才显示差异 | 任一端 invalid/unavailable/incomplete/no-service，或版本/日期/口径不可比时，保留可用端及原因，不生成差异或赢家 | A/B 交换只交换呈现槽位；结果绑定原地点快照，晚到结果不覆盖另一地点或新请求。 |
| 选择列表站点或 Marker | 当前页列表和 Marker 高亮同一 station，并显示名称、归一化类型、距离和粗略步行提示 | 条目不在当前结果、结果已替换或 scope 关闭时清除/拒绝该选择；不保留跨地点选择 | 选中、未选中、类型、距离和步行提示具文字说明；不改全局地点、主地图中心或分析结果。 |
| 查看站点分布图 | 显示分析中心、固定 1.5km 圆与当前结果全部站点 Marker | 不可读资料没有虚构 Marker；no stops 显示有效空图及零站点事实；部分结果明确范围/资料不完整 | 图不是唯一信息载体：列表/文字摘要同样提供站点、范围、来源、状态和选择信息。 |
| 刷新/读取旧快照 | 新完整结果按自身 provenance/日期取代旧结果；仅完整 `available` 结果中实际使用 feed 超过 30 天、仍可解析且分析日期在服务范围内时附 stale 警告 | 刷新失败后仍按唯一矩阵判定：完整 available 可附警告；部分为 incomplete；无可用为 unavailable。分析日期超服务范围时有效路线/连通性 unavailable | 旧/晚到结果不能覆盖不同地点、日期或范围的当前请求；不伪造统一采集日期。 |

跨 Owner 完成条件：

1. 在 [FLOW-02](../system/flows.md#flow-02单点选址地点摘要与六类分析) 中，Shell 只把 Map 已发布的
   single 快照交给 Transit。Transit 返回 canonical result，Shell 原样保留范围、分析日期、来源和状态。
2. 在 [FLOW-03](../system/flows.md#flow-03地点-ab-比较) 中，Shell 为 A/B 分别请求并接收绑定原快照的
   canonical result；Transit 自行判定是否可比较，Shell 不根据分数判定赢家。
3. Infrastructure 在其 ICI 旅程中消费同一 canonical connectivity result，而非再次通过
   `read_transit_analysis` 或原始 GTFS 对象计算交通分项；分数不可用时 ICI 按其唯一事实源处理缺失。

## 5. 数据与确定性业务规则

| 目的 | 权威对象或事实源 | 访问 / 应用边界 | 必须保持的语义 |
| --- | --- | --- | --- |
| GTFS provenance、完整性与稳定读取 | [`gtfs_feed_snapshots`、标准化 GTFS 对象及 `read_transit_analysis`](../data/schema-catalog.md#标准化-gtfs-对象)；[公共交通事实源](../../knowledge_base/locatemy_product/features/transportation.md#数据处理边界) | Flutter 通过只读稳定对象取得已准备结果；原始 ZIP 仅由受控维护操作使用 | 每个 feed 保留官方 source、采集时刻、解析状态、有效服务日期和失败原因；预期缺失/失败不会伪装为空 feed；每次结果显示使用的 feed provenance、年龄和生成时间，并按唯一事实源矩阵显示主状态及适用警告。 |
| 固定范围、站点、路线和连通性 | [公共交通事实源](../../knowledge_base/locatemy_product/features/transportation.md#空间与站点口径)；[ICI 交通规则](../../knowledge_base/locatemy_product/infrastructure_index_scoring.md#公共交通) | 只对 `LOCATION-001` 快照按 1,500m 圆和指定分析日期读取/应用 | `location_type = 0` 站点实体；同 feed 按 `stop_id`、跨 feed 按 `feed_id + stop_id`；路线键为 `feed_id + route_id`；仅 routes→trips→stop_times 且 calendar/calendar_dates 当日有效的路线计数。完整公式正文只在知识库。 |
| 参照组与分数 | `transit_reference_grid`、`transit_analysis_results` 和 ICI 交通规则 | Transit 产生并发布 canonical connectivity result；消费者仅复用 | 固定 1km 网格、可用 feed 服务范围内的参考点和同一 GTFS 评估快照决定密度/路线百分位；列表最多 30 项不截断统计。分数只能在完整站点和有效路线事实存在时生成。 |
| 可用性与无服务 | [公共交通可用状态](../../knowledge_base/locatemy_product/features/transportation.md#交通可用状态) | Transit 保留所有原始事实、部分成功结果和原因 | availability 仅为 `available`、`incomplete`、`unavailable`；仅 availability available 时 service outcome 才为 `served`、`no_stops` 或 `no_active_routes`；`stale` 仅为 available 的附加警告。invalid location 是上游拒绝，不是交通状态；部分/失败/未知永不补零。 |
| 局部选择与地图 | `STATE-TRANSIT-SELECTION`；[数据所有权](../system/data-ownership.md#运行时状态与派生结果) | 选择只绑定当前 canonical result；本页分布图只消费该结果 | 本地选择与 global location 分离；离开结果、换地点/日期/资料版本或关闭 scope 时释放，且不写数据库、队列或主地图。 |

## 6. 验收与 Ready Gate

| Capability | 验收情景 | 用户操作 | 可观察结果 |
| --- | --- | --- | --- |
| `TRANSIT-01` | 合法单点、边界内站点、完整可评分资料和不同 analysis date | 打开或刷新交通页 | 固定 1.5km、站点实体、有效路线、最近距离、完整站点数、分数、feed provenance/age/日期和等级一致；结果来自 canonical result。对应 `AT-ANALYSIS-01`。 |
| `TRANSIT-01` | 每个预期 feed 的 usable/stale/missing/failed/out-of-service-range，及全部 usable/stale、部分 usable/stale、无 usable/stale、served/no stops/no active routes、captured_at 恰 30 天/超过 30 天、invalid location | 打开/刷新或尝试分析 | availability 仅为 available/incomplete/unavailable：全部预期 feed 为 usable 或 stale 才 available，部分为 incomplete、无 usable/stale 为 unavailable。仅 available 有 served/no_stops/no_active_routes；任何实际使用 stale feed 仅附 warning。上游地点拒绝独立于交通状态；没有状态用 0 分、虚构 Marker 或默认地点伪装。对应 `AT-ANALYSIS-01`、`AT-RACE-01`。 |
| `TRANSIT-01` | A/B 完整可比、单侧不可用、资料版本/分析日期不一致及交换 | 进入比较、交换 A/B | 两端保留各自来源/日期/状态；仅可比时给差异，永不自动推荐；交换不混淆地点。对应 `AT-COMPARE-01`、`AT-COMPARE-03`。 |
| `TRANSIT-02`、`TRANSIT-03` | 列表与 Marker 互选、no stops、部分资料、换地点/结果、关闭 scope | 选择站点、查看局部分布图、换点或退出 | 同一局部站点高亮且文字说明充分；图含中心/圆/站点，空/部分/失效可解释；选择不会改变全局地点/主地图，过期选择被丢弃。对应 `AT-ANALYSIS-01`、`AT-RACE-01`。 |
| `TRANSIT-001` / Infrastructure | 同地点、同日期、同 snapshot/reference grid 的交通页与 ICI 输入；交通不可评分 | 先读交通结果再显示 ICI | Infrastructure 消费同一 connectivity fact，不重查/重算；不可评分交通按 ICI 缺失规则处理，不能变成低分或零。对应 `AT-ANALYSIS-01`、`AT-COMPARE-03`。 |
| 全部 / `AT-ANALYSIS-01`、`AT-COMPARE-03`、`AT-RACE-01` | 中文/English、动态字体、屏幕阅读器及颜色不可见 | 阅读分数、来源、异常状态、选择与地图 | 状态、范围、来源、日期、选中和限制均有文本/可访问名称，图形与颜色不是唯一表达。 |

- [x] `TRANSIT-01`–`03` 可追踪至唯一 Owner、`TRANSIT-001`、资料对象、产品事实和验收情景。
- [x] `D16`、`D17`、`D28`、`D45` 分别由 Shell、Map 与 canonical connectivity result 的消费者关系覆盖；不复制 ICI 或 Suitability 契约。
- [x] 固定范围、站点/路线/日期、provenance、no-service/失败/部分/过期、局部选择和局部地图均有可观察语义。
- [x] 项目负责人已固定 `RISK-TRANSIT-01`：主状态矩阵与完整 available 的 stale 附加警告均以唯一事实源为准；运行时边界证据留实现/集成验收。
- [x] 独立 Standards/Spec 双轴复审已核对全部资料、Interface、下游复用、状态分层和验收链；设计 AI 已依 ADR 0013 批准 Ready。

## 7. Change Log

| 日期 | 状态 | 变更原因 | 受影响的 Capability / Interface / 数据对象 / Feature | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Draft` | Issue #16 建立 Wave 5 Public Transportation owning design，冻结固定半径 GTFS 覆盖、canonical connectivity result、局部选择/分布图及 Infrastructure 复用 | `TRANSIT-01`–`03`、`TRANSIT-001`、`STATE-TRANSIT-SELECTION`、GTFS 标准化对象、`read_transit_analysis`、`transit_reference_grid`、Infrastructure Coverage、Personalized Location Suitability、D16/D17/D28/D45 | 待独立审查 |
| 2026-09-14 | `Draft` | 项目负责人 Q11 固定 GTFS 快照 >30 天 stale 与服务日期范围规则，消除资料新鲜度 Ready 阻塞 | `RISK-TRANSIT-01`、`TRANSIT-001`、`gtfs_feed_snapshots`、`transit_analysis_results`、Infrastructure Coverage | 项目负责人 |
| 2026-09-14 | `Draft` | 项目负责人 Q12 固定 per-feed/整体 GTFS 状态矩阵；将页面选择/地图呈现移出 `TRANSIT-001`，经既有 `LOCATION-002` 声明式 seam 协调 | `TRANSIT-001`、`LOCATION-002`、`STATE-TRANSIT-SELECTION`、`read_transit_analysis`、Infrastructure Coverage、D17、`RISK-TRANSIT-01` | 项目负责人 |
| 2026-09-14 | `Ready for Development` | 独立 Standards/Spec 双轴复审关闭全部发现；依 [ADR 0013](../../adr/0013-autonomous-design-ai-ready-approval.md) 批准 Ready | `TRANSIT-01`–`03`、`TRANSIT-001`、`LOCATION-002`、D16/D17/D28/D45 | 设计 AI（项目负责人授权） |
| 2026-09-14 | `Ready for Development` | 全面设计审查补齐可访问性验收的 canonical `AT-*`；不改变交通状态矩阵或结果契约 | `TRANSIT-01`–`03`、`AT-ANALYSIS-01`、`AT-COMPARE-03`、`AT-RACE-01` | 项目负责人（本次审查） |
