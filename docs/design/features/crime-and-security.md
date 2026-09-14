# Crime & Security

> 状态：`Ready for Development`
> Owner：`待项目负责人分配（实现学生分配不阻碍设计 Ready）`
> 系统基线：`5d11769`（含 2026-09-14 已批准的州级范围变更）
> 依赖波次：`5`
> 最后更新：`2026-09-14`
> Prototype 视觉参考：`N/A`（现有原型示例不代表地点的官方治安结果）

本文件是 Crime & Security 与其消费者的高层协调设计。它固定官方州级治安读数、趋势、筛选、比较、缓存和跨 Owner 结果；内部读取、缓存、呈现及测试策略归实现 Owner。

## 1. 用户成果与范围

- 用户成果：用户可查看合法地点所属**统计州**的 0–100 安全指数、最新完整年度案件数和最近五年趋势；类别筛选只改变趋势。地点 A/B 在本域资料可比时并列相同口径读数。用户可从治安页进入房产档案或新增房产表单。
- 包含的 Capability ID：`SAFE-01`、`SAFE-03`。
- 不包含及原因：`SAFE-02` 已排除。Crime 不解析警区边界、不产生警区结果或安全专题地图/图层；`crime_district.district` 只用于州级汇总。公共 Hazard 报告、其图层、投票、处理状态和附近计数完全属于 Hazard Reporting，不进入本 Feature 的指数、趋势、缓存或适配度输入。Crime 也不推断个人受害概率、拥有行政区统计、房产记录或可变选点。
- 产品事实源：[治安与犯罪](../../knowledge_base/locatemy_product/features/crime_security.md)、[Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)、[UI 规则](../../knowledge_base/locatemy_product/ui_design_spec.md#治安与犯罪)。
- 原型差异：固定州名、示例趋势及固定“暂不可用”安全卡必须替换为绑定不可变地点和官方资料的结果；页面不承载安全专题地图。主地图入口只返回当前分析地点，绝不创建或改写全局选点。

## 2. 依赖、责任与文件边界

| 模块 / 文件边界 | Owner | 负责 | 不负责 | 与其他模块的沟通 |
| --- | --- | --- | --- | --- |
| `lib/features/crime_and_security/` | Crime & Security | 官方资料读取、州级安全模型、案件/趋势/类别语义、3 天公共缓存、比较判断与 `SAFETY-001` | 地点选择、行政空间匹配、导航、用户隐患、房产持久化、适配度聚合 | 消费 `SHELL-001`、`LOCATION-001`、`GEO-001`；提供 `SAFETY-001` |
| `lib/app/` | Application Shell | 以地点快照打开单点或 A/B 分析、返回语境、治安摘要及房产档案/新增表单导航 | 治安计算、资料解释、可比性判断、房产数据读取或缓存 | 消费 `SAFETY-001`；按既有 `SHELL-001` 转交纯导航意图 |
| `lib/features/map_location/` | Map / Location | 合法、不可变地点引用及主地图呈现 | 统计州、治安结果或治安图层 | 提供 `LOCATION-001`；接收 Shell 的返回导航 |
| `lib/modules/geographic_context/` | Geographic Context | 版本化坐标到统计州的解析与 unresolved/ambiguous 事实 | 警区边界、犯罪聚合或安全评分 | 提供 `GEO-001` 的州结果 |
| Crime 受控读取对象及 SQLite 公共缓存 | Crime & Security | `read_safety_inputs`、`crime_public_cache` 的 Owner 语义 | 用户账户资料、直接镜像表读取或跨 Feature 缓存 | 对象字段/RLS/migration 仅由 [Schema Catalog](../data/schema-catalog.md) 定义 |

### 依赖与未决项

| 依赖或问题 | 影响 | 验证方式 / 最迟解决点 |
| --- | --- | --- |
| `SHELL-001`、`LOCATION-001`、`GEO-001` 已 Ready | 仅以同一不可变地点发起分析，且只在 resolved reporting state 时读取官方资料 | Crime Ready 审查核对 `FLOW-02`、`FLOW-03` 和三项上游完整契约 |
| `crime_district`、`read_safety_inputs`、`crime_public_cache` 仍为 `proposed` | 官方资料、稳定读取和缓存尚须学生 migration/实现 | `RISK-SCHEMA-01` 的 Crime 部分：核验官方 schema/键、导入资料、最新完整年度、五年趋势及州级聚合；Crime 实现/集成验收前关闭 |
| 已批准的州级范围 | 已退役 `police_districts_boundary` 及 `SAFE-02` 不可再作为输入或功能 | 审查所有 Crime 读写/呈现只使用 `GEO-001` 的 reporting state 和 `crime_district.state`；无警区或安全地图贡献 |

## 3. 对外协调契约

### 提供：`SAFETY-001` 州级安全结果与趋势

| 消费者 | 动作与可观察事实 | 输入、结果与失败语义 | 权限与副作用边界 |
| --- | --- | --- | --- |
| Application Shell；Property Inspection；Personalized Location Suitability | 对给定不可变合法地点取得该地点统计州的安全指数、最新完整年度案件数、类别可用性和五年趋势；A/B 时对每端独立返回同一结果族及本域可比性。 | 输入是 `LOCATION-001` 地点快照和由 `GEO-001` 返回的统计州结果；结果为带地点、统计州、资料年份、来源、完整性、缓存状态及模型/边界版本的 `available`、`partial`、`unavailable(reason)` 或 A/B `comparable`/`incomparable(reason)`。`unresolved`、`ambiguous`、资料缺失、无有效类别、非完整年度、不可用类别及 stale/cached 必须保持可区分，绝不以 0、默认州或邻近地区替代。 | 只读官方公共资料和无账户字段的公共缓存；不写地点、房产、账户资料或 Hazard 对象，不发布地图图层。结果仅绑定请求地点/版本；过期地点、范围关闭或晚到结果不得进入当前槽位。 |

筛选是 `SAFETY-001` 返回的趋势视图请求，而非另一种安全指数：`all` 固定存在，`assault`、`property` 及可用的具体 `type` 只重取/重呈趋势；指数、最新完整年度和总体案件数不随筛选改变。

### 消费

| ID | Owner | 使用目的 | 调用方依赖的结果与失败语义 |
| --- | --- | --- | --- |
| `SHELL-001` | Application Shell | 单点/A-B 分析、主地图返回、治安摘要及进入房产档案/新增表单的类型化导航 | 只有合格且处于当前语境的目的地被接受；拒绝导航与治安资料不可用保持不同。返回携带原地点/任务，Crime 不改写 Map 选点，也不读取、传输或缓存房产资料。 |
| `LOCATION-001` | Map / Location | 获得单点或 A/B 的合法不可变地点引用 | 无地点、范围外、坐标无效或相同 A/B 时不请求 Crime；读取地点快照无副作用。 |
| `GEO-001` | Geographic Context | 将地点坐标解析为治安所用 reporting state | 只消费 resolved state；unresolved/ambiguous 直接成为 Safety unavailable 原因。不得要求或推测警区、行政区、最近州或名称匹配。 |

## 4. 用户可观察行为与跨模块流程

| 入口或用户动作 | 成功结果 | 空、不可用或失败结果 | 必须保持的可访问性 / 安全语义 |
| --- | --- | --- | --- |
| 打开单点治安页或地点摘要 | 显示当前地点、统计州、指数、最新完整年度案件数及五年趋势，连同来源、年份、州级口径、完整性和缓存状态 | 地点/州未解析或歧义、资料缺失、两类均无有效数据时显示“暂不可用”及原因，不显示 0 或示例统计 | 读数、趋势、风险含义和资料状态有文字摘要，不仅靠颜色；明确这不是官方评级、警区结果或个人受害概率。 |
| 选择“全部”、类别或具体 type | 可用筛选项更换同一统计州的趋势 | 无该类别或 type 的资料时保留该筛选不可用原因，不伪造零趋势 | 控件旁明确“筛选只影响趋势图”；总体指数和案件数保持不变。 |
| 刷新或读取缓存 | 最新成功资料显示为 fresh；在契约允许时显示 3 天 cached/stale 结果及原始资料年份 | 缓存不存在、过期且刷新失败、或读取失败时明确 retryable/non-retryable unavailable；不把失败写成完整空 | 缓存不含账户 ID；日期、来源、资料完整性、缓存/过期状态始终可见。 |
| 发起 A/B 比较 | 两端各保留地点、州、年份、来源、口径、完整性和指数/案件/趋势；相同完整年度、口径和可用性满足本域可比条件时才显示差异 | 任一侧未解析/不可用，或年份、口径、完整性、模型/边界版本不一致时保留可用原值与 `incomparable(reason)`，不生成差异 | A/B 仅表示显示顺序；不标示赢家、不作搬迁建议。 |
| “查看主地图” | Shell 返回发起分析时的当前地点及返回语境 | 导航拒绝保留其原因，不伪装为治安失败 | 不贡献警区边界或安全图层；不改变全局地点。 |
| 打开房产档案或新增房产 | Shell 接受 Crime 页面发起的类型化 Property 目的地，保留治安页作为返回语境；目标 Feature 呈现自身档案或新增表单 | 目的地不可用、范围关闭或导航被拒绝时保留可理解原因；Crime 的治安读数不被伪装为房产资料 | Crime 只发起导航意图，不拥有、缓存、读取或写入房产记录、草稿、照片、风险快照或选择状态；不呈现最近房产或任何 fixture。 |

跨 Owner 完成条件：在 `FLOW-02`，Map 先发布 `LOCATION-001` 快照，Crime 经 `GEO-001` 取得州结果后独立贡献 `SAFETY-001`，Shell 不把不可用改写为零。在 `FLOW-03`，Shell 将 A/B 快照分别交给 Crime；Crime 独立判定本域可比性，Shell 只并列展示。房产入口复用 `SHELL-001` 已冻结的“业务导航意图、返回语境与拒绝原因”协调契约：Crime 只声明房产档案或新增表单目的地；不消费 `PROPERTY-001`、不等待 Property，也不组合最近房产资料。在 `FLOW-06`，Property 消费已带采集时间、统计州与可用性语义的 `SAFETY-001` 结果制作自身风险快照；Crime 不写房产快照。Hazard 的 `HAZARD-002` 是完全独立的另一个输入。

## 5. 数据与确定性业务规则

| 目的 | 权威对象或事实源 | 访问 / 应用边界 | 必须保持的语义 |
| --- | --- | --- | --- |
| 州级安全指数、案件数和趋势 | [治安产品事实及公式](../../knowledge_base/locatemy_product/features/crime_security.md#安全指数)；`crime_district` | 仅通过 `read_safety_inputs` 取得官方镜像资料；先使用 `GEO-001` resolved reporting state，再按 `crime_district.state` 聚合警区原始行 | 使用最新完整年度、同年度同类别实际统计州基准与产品事实中的对数/百分位/60:40 规则；排除 Malaysia 行并应用事实源定义的联邦直辖区归并。指数高仅表示该完整年度相对案件规模较低。 |
| 类别、趋势和部分资料 | [治安产品事实：犯罪类别与趋势](../../knowledge_base/locatemy_product/features/crime_security.md#犯罪类别) | `all` 为两类总和；类别筛选只作用于 `Y-4` 至 `Y` 的可用完整年度趋势 | `assault`、`property` 与具体 type 的资料可用性分别呈现；仅一个主类别有效时按既定权重重归一化并标示 partial，两个皆无才 unavailable。 |
| 地理、来源和比较 | `GEO-001`、`crime_district`、[CONTEXT.md](../../../CONTEXT.md#行政区与统计州) | 保留 state、边界来源/版本、官方年份、资料来源和完整性，不把 police district 当地点地理语境 | 不解析或呈现警区边界；`district` 从不替代 reporting state。A/B 只有两端同一可解释口径和可比资料时才计算差异。 |
| 公共缓存 | `crime_public_cache`；[Schema Catalog](../data/schema-catalog.md#本机对象) | 以 reporting state、模型/边界版本和资料事实区分缓存；3 天 TTL | 无账户字段，退出/换号保留；cached/stale 不冒充 fresh，原始官方年份仍显示。 |
| 公共隐患隔离 | [Hazard 产品事实](../../knowledge_base/locatemy_product/features/hazard_reporting.md)、`HAZARD-001`/`HAZARD-002` | 不读写 Hazard 报告、投票或计数；不消费其图层或状态作为 Crime 输入 | 隐患不进入安全指数、趋势、比较、缓存或适配度安全维度。 |

## 6. 验收与 Ready Gate

| Capability | 验收情景 | 用户操作 | 可观察结果 |
| --- | --- | --- | --- |
| `SAFE-01` | resolved state，有两类完整资料；最新年、五年窗口、州归并及来源资料齐全 | 打开单点分析 | 显示州级 0–100 指数、最新完整年度案件数和趋势；每项带地点、州、年份、来源、完整性和口径。对应 `AT-ANALYSIS-01`。 |
| `SAFE-01` | 仅一主类别有效、两类均无、空/缺年、资料不完整、刷新失败及 cached/stale | 打开或刷新 | partial、unavailable、完整空、retryable/non-retryable 及 cached/stale 不互换；不显示伪 0。对应 `AT-ANALYSIS-01`。 |
| `SAFE-01` | 州 resolved、unresolved、ambiguous、边界版本变化及州外/相邻地区诱因 | 选择地点后分析 | 只使用 resolved reporting state；其余显示可解释 unavailable；无警区、行政区或邻近地区回退。对应 `AT-LOC-01`、`AT-LOC-02`。 |
| `SAFE-03` | all、assault、property、可用/不可用具体 type | 切换筛选 | 只有趋势变化；指数、最新年和总体案件数不变，筛选范围有文字说明。对应 `AT-ANALYSIS-01`。 |
| `SAFE-01` | 有效 A/B、单侧不可用、年份/口径/完整性/版本不同及混合缓存 | 比较或交换 A/B | 并列原值；仅可比时显示差异，其他显示原因；交换仅改变呈现顺序。对应 `AT-COMPARE-01`、`AT-COMPARE-03`。 |
| `SAFETY-001` / Property、Suitability、Shell | 风险快照请求、地点摘要、主地图返回及 Hazard 数据存在 | 从消费者请求或返回 | 结果含保存所需州/年份/来源/可用性；Crime 不写 Property，不产出安全图层，也不混入 Hazard。 |
| 可访问性与披露 | 中文/English、动态字体、图表/颜色、来源与模型限制 | 阅读单点或比较页 | 文字等价信息覆盖读数、趋势、筛选作用域、状态和限制；州级而非警区/个人风险的口径清楚可见。 |

- [x] `SAFE-01`、`SAFE-03` 追踪到 Crime Owner、`SAFETY-001`、资料对象、唯一事实源与验收情景。
- [x] `SAFETY-001` 与 `SHELL-001`、`LOCATION-001`、`GEO-001`、Property/Suitability 消费边的职责和副作用无冲突。
- [x] 公式正文、字段、RLS、migration 和内部缓存策略分别仍只在产品事实源或 Schema Catalog；本文件没有可提交实现。
- [x] 州级聚合、无警区/安全地图、Hazard 隔离、缺失/部分/过期、A/B、可访问性与来源披露均已独立审查。
- [x] 仅房产档案和新增房产入口通过 `SHELL-001` 的既有类型化导航/返回语境到达 Property；Crime 不消费 `PROPERTY-001` 或任何房产资料，并且不展示最近房产、逐行详情、`and N more`、空/unavailable 房产状态或 fixture。
- [x] `RISK-SCHEMA-01` 的 Crime 资料与读取对象证据已保留为实现/集成验收项；不以现有 `crime_stats` 或示例资料宣称完成。
- [x] 独立 Standards/Spec 双轴复审均通过；设计 AI已依 ADR 0013 批准 `Ready for Development`。

## 7. Change Log

| 日期 | 状态 | 变更原因 | 受影响的 Capability / Interface / 数据对象 / Feature | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Draft` | Issue #15 建立 Wave 5 Crime & Security owning design；按项目负责人已批准范围以统计州聚合原始警区记录 | `SAFE-01`、`SAFE-03`、`SAFETY-001`、`crime_district`、`read_safety_inputs`、`crime_public_cache`、D11/D12/D13/D33/D43 | 待独立审查与设计 AI 依 ADR 0013 批准 |
| 2026-09-14 | `Draft` | 记录警区边界/安全图层已撤销及 Hazard 完全隔离，替代 #15 旧描述中的过时范围 | `SAFE-02`（excluded）、`police_districts_boundary`（retiring）、Hazard Reporting | 项目负责人既有范围决定 |
| 2026-09-14 | `Draft` | 独立审查补齐房产入口与最近房产 Shell 组合槽；不引入 Crime→Property 的数据依赖或 Ready blocker | `SHELL-001`、`PROPERTY-001`、Property Inspection、Crime 页组合槽 | 待独立审查与设计 AI 依 ADR 0013 批准 |
| 2026-09-14 | `Draft` | 项目负责人 Q10 移除 Crime 页最近房产预览及组合槽，仅保留档案/新增的纯导航 | `SHELL-001`、Crime 房产入口、`PROPERTY-001` 消费者摘要、产品/UI 事实源 | 项目负责人 |
| 2026-09-14 | `Ready for Development` | 独立 Standards/Spec 双轴复审关闭全部发现；依 [ADR 0013](../../adr/0013-autonomous-design-ai-ready-approval.md) 批准 Ready | `SAFE-01`、`SAFE-03`、`SAFETY-001`、D11–D13、D33、D43 | 设计 AI（项目负责人授权） |
