# Socio-economic

> 状态：`Ready for Development`
> Owner：`B`
> 系统基线：`5d11769`
> 依赖波次：`6`
> 最后更新：`2026-09-14`
> Prototype 视觉参考：`N/A`（既有示例读数只可作页面结构 fixture）

本文件协调社会经济资料、层级回退、推导和比较的可观察语义。它冻结收入、结构、基尼、收入分布和账户家庭收入位置在跨 Owner 边界的结果；不规定资料查询、缓存、图表、插值实现或测试组织。

## 1. 用户成果与范围

- 用户成果：用户可在合法单点看到收入中位数、收入结构、基尼和州级收入分布，各读数均带实际统计层级、年份、单位与 DOSM 来源；有同账户 current 预案的家庭月度总收入时，可看到州级参考的家庭收入位置。A/B 保留双方原值，只在该读数的口径相容时显示差异。
- 包含的 Capability ID：`SOCIO-01`、`SOCIO-02`、`SOCIO-03`。
- 不包含及原因：不生成综合社会经济指数或推荐；不作 CPI/实际购买力换算；不保存、修改或选择预算预案；不解析坐标或行政边界。它们分别归产品事实、Cost of Living & Budget 或 Geographic Context Owner。
- 产品事实源：[社会经济](../../knowledge_base/locatemy_product/features/socio_economic.md)、[Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)（Capability 语义）、[UI 规则](../../knowledge_base/locatemy_product/ui_design_spec.md#社会经济)。
- 原型差异：移除硬编码收入、基尼和 A/B 示例值；不再沿用“不插值”旧文案。官方读数与州级百分位推导/估算持续分组并以文字区分。

## 2. 依赖、责任与文件边界

| 模块 / 文件边界 | Owner | 负责 | 不负责 | 与其他模块的沟通 |
| --- | --- | --- | --- | --- |
| `lib/features/socio_economic/` | Socio-economic | `SOCIO-001`、社会经济只读资料、层级/年份/完整性判断、结构/位置推导、A/B 可比性 | 地点、地理解析、预案写入、综合评分、实际购买力 | 消费 `SHELL-001`、`LOCATION-001`、`GEO-001`、`COST-002`；提供 `SOCIO-001` |
| `lib/app/` | Application Shell | 单点/A-B 分析导航、返回和结果组合 | 社会经济资料/回退/可比性判断 | 接收带地点、来源、年份、层级、单位和可用性的贡献 |
| `lib/features/map_location/` | Map / Location | single/A/B 合法不可变地点引用 | 行政语境和社会经济结果 | `LOCATION-001` 只提供地点角色快照 |
| `lib/modules/geographic_context/` | Geographic Context | 州和行政区的 resolved/unresolved/ambiguous 事实及版本 | 社会经济资料层级回退 | `GEO-001` 不替 Socio 选择回退或读数 |
| `lib/features/cost_of_living_budget/` | Cost of Living & Budget | 同账户 current 或无 current 的已保存快照及版本 | 用户收入位置计算、社会经济资料 | `COST-002` 只提供 current 的家庭月度总收入和缺失事实 |
| `read_socio_inputs` | Socio 数据读取对象 | 受控暴露收入、基尼及百分位资料和导入完整性 | 地点解析、页面推导 | Flutter 不直接读取镜像表；字段、权限和迁移只在 Schema Catalog 定义 |

| 依赖或问题 | 影响 | 验证方式 / 最迟解决点 |
| --- | --- | --- |
| `D21` / `SHELL-001` 已 Ready | 结果只能在 opened 主应用中导航与组合 | 导航拒绝保留其原因，不能改写为资料失败；无阻塞 |
| `D22` / `LOCATION-001` 已 Ready | 单点/A-B 必须以合法不可变地点读取 | 缺失、无效、同一 A/B 地点不读社会经济结果；无阻塞 |
| `D23` / `GEO-001` 已 Ready | 行政区优先和州级回退必须基于明确地理事实 | unresolved/ambiguous 不能猜选地区；无阻塞 |
| `D24` / `COST-002` | 家庭收入位置只可使用同账户、已保存 current 的家庭月度总收入 | 无 current、家庭月度总收入未填或保存失败都不是 RM 0，月净收入不能替代；Q18 影响复审已通过 |
| `read_socio_inputs` 和 canonical 镜像 | 真实结果、完整性和可比性不能由 fixture 替代 | Socio 实现前验证五个 DOSM 数据集的键、单位、统计日期、各层级和百分位覆盖；见 [Schema 迁移计划](../system/baseline-review.md#schema-迁移计划) |

## 3. 对外协调契约

### 提供

| ID | 消费者 | 动作与可观察事实 | 输入、结果与失败语义 | 权限与副作用边界 |
| --- | --- | --- | --- | --- |
| `SOCIO-001` | Application Shell | 对合法单点或 A/B 的每端提供互不合成的家庭收入中位数、收入结构、基尼及其可用时的同比变化、州级收入分布与可用时的家庭收入位置；每项带地点、统计层级、统计年份、单位、来源/资料集、推导或官方性质及 `available`、`partial`、`unavailable` 状态。 | 输入为 `LOCATION-001` 引用、`GEO-001` 分层语境、公共资料和可选同账户 `COST-002` current 快照。单点返回每项读数或精确原因；A/B 逐项判断可比性，只在两端实际层级、统计年份、单位、来源资料集、读数/推导定义和完整性相同且均为 available 时产生差异。收入位置使用最新完整州级 `median` 分布与 current 家庭月度总收入；无合格输入时独立 unavailable，不影响公共读数。 | 只在 opened 主应用读取；不写地点、地理资料、预案、偏好或适配度。公共资料缓存若建立不得含账户或 current 收入；范围关闭后丢弃 current 快照、私有结果和晚到响应。 |

完整公式只在[社会经济产品事实](../../knowledge_base/locatemy_product/features/socio_economic.md)定义；字段、RLS、迁移与稳定读取对象只在[Schema Catalog](../data/schema-catalog.md#稳定公共读取对象)定义。

### 消费

| ID | Owner | 使用目的 | 调用方依赖的结果与失败语义 |
| --- | --- | --- | --- |
| `SHELL-001` | Application Shell | 进入单点/A-B 社会经济页、提交结果贡献和返回原任务 | 只有 opened scope 的合格目的地会被接受；导航拒绝保留原因，Socio 不把它伪装为无资料。 |
| `LOCATION-001` | Map / Location | 读取 single 或 A/B 的合法不可变地点 | 只有 valid reference 可查询；absent、outside Malaysia、invalid coordinate 或 same comparison point 不产生社会经济读取或结果。 |
| `GEO-001` | Geographic Context | 获取行政区优先读取和明确州级回退所需的地理事实 | 每层独立 resolved/unresolved/ambiguous 并保留版本；Socio 只在相关层级 resolved 时读该层级资料，不选邻近、默认或候选地区。 |
| `COST-002` | Cost of Living & Budget | 取得同账户已保存 current 的家庭月度总收入及其缺失/版本事实 | 无 current、家庭月度总收入缺失、非同账户或未保存编辑使收入位置 unavailable；月净收入与临时 CPI 输入都不能替代。 |

## 4. 用户可观察行为与跨模块流程

| 入口或用户动作 | 成功结果 | 空、不可用或失败结果 | 必须保持的可访问性 / 安全语义 |
| --- | --- | --- | --- |
| 打开合法单点的社会经济页 | 收入中位数和基尼优先显示行政区官方读数；行政区未有相应读数时显示明确州级参考。结构与分布显示州级参考估算；每项显示实际年份、名义 RM/月或 0–1、资料来源和统计层级。 | 行政区/州未解析、目标年份/层级/记录缺失或资料不可读时，仅受影响项 unavailable，并说明是哪一种原因；其他独立读数继续显示。 | 官方统计与推导估算分组；金额注明“名义 RM/月、未按通胀调整”，基尼不转 0–100；状态、层级和来源不只以颜色表达。 |
| 阅读 B40/M40/T20 或分布 | 在同一州、同一完整统计年份，按已确认的百分位规则显示 B40/M40/T20 门槛、组内均值/份额和 P1–P100 的 median 曲线；P50 标示州级中位数参考。 | 缺结构所需的任一 `mean(P1…P100)`、`maximum(P40/P80)`，或缺曲线/位置所需的任一 `median(P1…P100)` 时为 partial distribution：保留可审计的已有观测和缺失范围，但不计算受影响的结构推导、完整曲线或收入位置；完全无合格记录则 unavailable。 | 标题和说明持续写明“州级参考/由百分位数据推导”；图表有同等文字表格或摘要，P1/P100 的无关 minimum/maximum 空值不补零。 |
| current 预案已有家庭月度总收入时查看收入位置 | 用该州最新完整 `median` P1–P100 记录计算州级参考百分位位置；命中观测点、两点间、低于 P1 和高于 P100 分别如实呈现。 | 无 current、家庭月度总收入未填写、州 unresolved、没有完整 median 分布或资料读取失败时显示独立 unavailable 原因；partial distribution 不执行插值；月净收入不能替代。 | 输入是家庭月度总收入、不是个人工资、不是月净收入或官方阶层判定；只在同账户 opened scope 中呈现，退出/换号不保留。 |
| 打开 A/B 社会经济比较或交换 A/B 显示 | 各端保留自己的收入、基尼、结构及分布元数据；某项满足可比性时显示该项差异，交换仅改显示槽位。 | 任一端 missing year、missing level、missing data、unresolved geography、partial distribution 或口径不相容时，该项不显示差异/赢家，保留双方可用原值与具体不可比原因。 | 不压缩为总分、不自动推荐；图表和差异有文字说明，A/B 不改变原地点或账户预案。 |
| 资料刷新、失败、账户关闭或晚到响应 | 成功刷新更新公共资料事实；只在地点、Geo 版本和 current 预案版本仍相同的请求语境中呈现结果。 | 读取失败不将旧 fixture 或缺失填成零；关闭开始即丢弃旧账户 income position 和晚到结果。 | 公共读数不泄露账户收入；错误和恢复入口可读，公共资料与用户收入状态不混合。 |

跨 Owner 完成条件：在 `FLOW-02`/`FLOW-03`，Shell 传入 `LOCATION-001` 的原始 single/A/B 快照；Socio 请求 `GEO-001` 的两个地理层级，再逐项应用其唯一产品事实。`COST-002` 的远端保存成功版本变化只会使同账户的收入位置失效/重算；不会改变公共收入、基尼、结构或分布。Shell 仅组合 Socio 提供的元数据，绝不为其判定回退、完整性或可比性。

## 5. 数据与确定性业务规则

| 目的 | 权威对象或事实源 | 访问 / 应用边界 | 必须保持的语义 |
| --- | --- | --- | --- |
| 收入和基尼的层级读取 | [`read_socio_inputs`](../data/schema-catalog.md#稳定公共读取对象)；[社会经济：收入/基尼](../../knowledge_base/locatemy_product/features/socio_economic.md#家庭收入中位数)；`GEO-001` | 对每个指标独立先读 resolved `(state, district)` 的 `hh_income_district` 或 `hh_inequality_district`；仅该指标在行政区层级没有匹配读数时，读 resolved state 的对应州级表。 | 收入取 `income_median`，单位 RM/月；基尼原样为 0–1。行政区和州级都不是互相替代的成功标签：结果必须披露实际层级、DOSM date、资料集和 official/reference 性质。 |
| 基尼同比变化 | [社会经济：基尼系数](../../knowledge_base/locatemy_product/features/socio_economic.md#基尼系数) | 仅在当前基尼与其紧邻上一 DOSM 统计年份都属于同一实际层级、同一资料集且均可用时，应用唯一的同比绝对差公式。 | 显示该公式结果规定的上升或下降及绝对变化；上一年缺失、层级回退改变、资料集改变或任一读数不可用时，同比变化 unavailable，保留当前基尼及原因，不以不同层级/年份补造趋势。 |
| 年份选择与缺失分类 | [社会经济：年份、缺失与文案](../../knowledge_base/locatemy_product/features/socio_economic.md#年份缺失与文案) | 对当前单点同时可得的公共读数，优先采用它们共同完整的最新 DOSM 原始统计 `date`；没有共同年份时，每项取自身层级、资料集和所需字段完整的最新 `date`，并显示年份不同。结构/分布/位置的百分位按同一 state/date/variable 成组验证。 | `missing year` 表示该层级/资料集无可用统计日期；`missing level` 表示 Geo 已解析但该指标在允许层级均无匹配读数；`missing data` 表示已有目标日期/层级但必需字段为空或资料不可读；`unresolved geography` 表示必需州或行政区为 unresolved/ambiguous。缺失不为 0，也不用附近地点、插值或不同日期替代。 |
| B40/M40/T20 与收入分布 | [社会经济：地区收入结构与分布](../../knowledge_base/locatemy_product/features/socio_economic.md#地区收入结构) | 结构以同州、同 date、完整 `mean(P1…P100)` 与 `maximum(P40/P80)` 应用唯一推导；曲线以同州、同 date、完整 `median(P1…P100)` 连接真实观测点。 | B40/M40/T20 始终为州级参考估算；分布始终为州级收入分布参考。不得将其说成行政区官方读数，不做曲线插值/平滑，也不使用全国百分位或州汇总表。 |
| 当前预案收入位置 | `COST-002`；[社会经济：用户收入位置](../../knowledge_base/locatemy_product/features/socio_economic.md#用户收入位置) | 只用 current 评估预案的已保存家庭月度总收入和该地点 resolved state 的最新完整 `median` P1–P100 资料。 | 月净收入不得替代家庭月度总收入；相邻真实点之间的线性插值、命中点与 P1/P100 边界的输出均按唯一事实源；其结果是州级参考估算，不反写预案或参与官方统计。 |
| A/B 可比性 | [FLOW-03](../system/flows.md#flow-03地点-ab-比较)；`SOCIO-001` | 每个读数独立比较两端的结果元数据；收入位置另要求同账户同一 current 预案版本，且仍不作为地点间社会经济差异。 | 仅两端均 `available` 且层级、DOSM date、单位、资料集/来源、official/reference 或推导定义和完整性相同时显示差异。其他情况为 `incomparable`，列出差异属性或一侧状态；不从不同年、层级或部分分布生成差异。 |
| 数据对象与公共/私有边界 | [Schema Catalog](../data/schema-catalog.md#公共政府镜像与边界对象)；[数据所有权](../system/data-ownership.md#公共资料镜像与缓存) | 只经 `read_socio_inputs` 使用五个 canonical DOSM 镜像；账户收入只经 `COST-002` 取得。 | `hh_income_state`、`hh_inequality_state`、`hies_state_percentile` 和读取对象在实现前仍为 proposed；现有全国或错误粒度对象不得替代。可选公共缓存仅含公共结果/版本/日期/完整性。 |

## 6. 验收与 Ready Gate

| Capability | 验收情景 | 用户操作 | 可观察结果 |
| --- | --- | --- | --- |
| `SOCIO-01` | resolved 行政区有当前和连续上一年基尼；另一地点仅有州级基尼或上一年缺失 | 打开单点页 | 每项优先行政区并独立回退州级；收入为名义 RM/月、基尼为 0–1，均带实际层级、年份、来源；只有同层级连续年份才显示产品事实定义的基尼升降/绝对变化，其他情况明确同比 unavailable。 |
| `SOCIO-01` | 结构/分布州资料完整；分别缺一个百分位、variable、年份或资料读取失败 | 阅读结构和图表 | 完整集合才显示全量推导/曲线；partial 与 unavailable 保持不同，缺失不补零，仍明确州级参考估算。 |
| `SOCIO-01` | 行政区或州 unresolved/ambiguous、行政区无匹配、州无匹配、字段空值 | 打开或刷新 | `unresolved geography`、`missing level`、`missing year`、`missing data` 分别可见；其他独立读数不被清空。 |
| `SOCIO-02` | 同账户 current 有家庭月度总收入，州 median 分布完整，输入恰中点/两点间/低于 P1/高于 P100 | 打开收入位置 | 显示正确州级参考位置或边界状态；不称官方阶层判定。 |
| `SOCIO-02` | 无 current、current 缺家庭月度总收入、只有月净收入、未保存编辑、换号、州不可解析或 partial median 分布 | 打开收入位置或切换账户 | 仅收入位置 unavailable，说明输入/资料原因；公共读数保留，旧账户收入不进入新账户。 |
| `SOCIO-03` | 两端同层级/年/单位/来源/定义且完整；或其中一项层级、年、单位、来源、定义、完整性或状态不同；交换 A/B | 比较和交换 | 仅合格指标显示差异；其余并列原值与 specific incomparable 原因，无总分、赢家或自动推荐。 |
| `SOCIO-01`–`03` | 中文/English、长金额/日期、图表、估算和错误状态 | 阅读完整、部分或不可用页 | 单位、层级、年份、官方/估算、来源及错误有文本和可访问名称；非颜色传达，图表有文字摘要。 |

- [x] `SOCIO-01`–`03` 可追踪至 Socio Owner、`SOCIO-001`、`D21`–`D24`、唯一事实源、数据对象和验收情景。
- [x] 复合评分、购买力换算、预案持久化和地理解析仍分别归既有 Owner；本设计未改变其契约或数据模型。
- [x] 固定每项的层级、原始统计年份、单位、DOSM 来源、层级回退、完整性与 A/B 可比性语义；missing year/level/data、unresolved geography、absent scenario income、partial distribution 与 incomparable 不互换。
- [x] 独立 Standards/Spec 双轴审查及 Q18 跨 Cost/Account 影响复审已关闭全部发现。
- [x] 设计 AI 已依 ADR 0013 批准 `Ready for Development`；`read_socio_inputs` migration 与 canonical 资料导入证据仍是实现开始前 Gate，不以设计批准冒充运行证据。

## 7. Change Log

| 日期 | 状态 | 变更原因 | 受影响的 Capability / Interface / 数据对象 / Feature | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Draft` | Issue #20 建立 Wave 6 Socio-economic owning design，冻结层级/年份/回退、百分位推导、current 预案收入位置及逐项 A/B 可比性 | `SOCIO-01`–`03`、`SOCIO-001`、`read_socio_inputs`、五个社会经济 DOSM 镜像、D21–D24 | 待独立审查与设计 AI 依 ADR 0013 批准 |
| 2026-09-14 | `Draft` | 项目负责人 Q18 批准收入位置使用 current 的家庭月度总收入、月净收入不可替代；并补齐产品既定的同层级连续年份基尼同比展示 | `SOCIO-01`–`03`、`SOCIO-001`、`COST-002`、`user_budget_scenarios`、Cost、Account Center | 项目负责人 |
| 2026-09-14 | `Ready for Development` | 独立 Standards/Spec 双轴审查关闭全部发现；Q18 对 Cost/Account 的字段与用途分离影响复审通过；依 [ADR 0013](../../adr/0013-autonomous-design-ai-ready-approval.md) 批准 Ready，资料导入与 migration 证据保留为实现 Gate | `SOCIO-01`–`03`、`SOCIO-001`、`COST-002`、`ACCOUNT-001`、`read_socio_inputs`、D21–D24 | 设计 AI（项目负责人授权） |
