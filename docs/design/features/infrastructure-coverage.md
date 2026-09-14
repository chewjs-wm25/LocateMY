# Infrastructure Coverage

> 状态：`Ready for Development`
> Owner：`B`
> 系统基线：`5d11769`
> 依赖波次：`6`
> 最后更新：`2026-09-14`
> Prototype 视觉参考：`N/A`（产品事实源记录原型差异）

本文件是 Infrastructure Coverage 与其消费者的高层协调设计。它冻结单点 ICI、五项分项、
账户 ICI 权重和中性结果的可观察语义；不规定数据查询、缓存、重算、持久化或 Flutter 的内部策略。

## 1. 用户成果与范围

- 用户成果：用户可在一个合法地点查看 0–100 的基础设施综合覆盖指数（ICI）、供水、供电、医疗、教育和公共交通五项分项、各自资料日期与缺失原因；合法医疗、教育和交通滑块变化会立即生成带 `unsaved preview` 标记的单点 ICI，可保存为账户级 `1–10` 权重。地点 A/B 时，用户只可并列两端中性 ICI；只有可比时显示差异。
- 包含的 Capability ID：`INFRA-01`、`INFRA-02`。
- 不包含及原因：不拥有地点选择/地理解析、公共交通计算、GTFS 或政府资料导入、账户五项评估偏好、个人化地点适配度聚合、服务质量评价或自动推荐。ICI 是相对服务覆盖读数，不是官方评级或实际可靠性承诺。
- 产品事实源：[基础设施](../../knowledge_base/locatemy_product/features/infrastructure.md)、[单个地点基础设施指数](../../knowledge_base/locatemy_product/infrastructure_index_scoring.md)、[核心业务对象](../../knowledge_base/locatemy_product/domain_objects.md#infrastructure-coverage-基础设施覆盖)、[UI 规则](../../knowledge_base/locatemy_product/ui_design_spec.md#基础设施)。
- 原型差异：固定 fixture、页面内滑块和错误的五个 `0–1` 权重均不再是事实；三个账户全局权重默认为中性 `5`，但地点摘要和 Suitability 一律使用三项均为 `5` 的中性 ICI。

## 2. 依赖、责任与文件边界

| 模块 / 文件边界 | Owner | 负责 | 不负责 | 与其他模块的沟通 |
| --- | --- | --- | --- | --- |
| `lib/features/infrastructure_coverage/` | Infrastructure Coverage | 五项分项、ICI 聚合、`INFRA-001`、账户 ICI 权重的读取/保存及本页单点/A-B 呈现 | 地点、Geo、交通计算、账户评估偏好与 Suitability | 消费 `SHELL-001`、`LOCATION-001`、`GEO-001`、`TRANSIT-001`、`PRIVACY-001`；向 Shell/Suitability 提供 `INFRA-001` |
| `lib/app/` | Application Shell | 将合法 single/A-B 快照导航至本 Feature，并组合原样带元数据的结果 | 公式、权重、资料完整性或可比性判断 | 经 `SHELL-001` 交付地点/返回语境与组合意图 |
| `lib/features/public_transportation/` | Public Transportation | 唯一 canonical connectivity result | ICI 聚合或账户权重 | 以 `TRANSIT-001` 给出已绑定地点、半径、分析日期、快照和参照组的结果 |
| `user_ici_preferences`、`read_infrastructure_inputs` | Infrastructure / 受控维护导入 | 权重权威记录、稳定公共资料读取 | 政府镜像的客户端直读或跨账户写入 | 对象、字段和访问规则只在 [Schema Catalog](../data/schema-catalog.md) 定义 |

Owner 可在自己的 Feature 目录内组织实现；以上是跨 Owner 文件边界，不冻结语言符号、DTO、查询形状、缓存或请求策略。

### 依赖与未决项

| 依赖或问题 | 影响 | 验证方式 / 最迟解决点 |
| --- | --- | --- |
| `D25` / `SHELL-001` 已 Ready | 只在 opened 主应用中进入单点/A-B 分析，并保留不可变地点及返回语境 | 以 `FLOW-02`、`FLOW-03`、`AT-ANALYSIS-01` 和 `AT-COMPARE-03` 核对；无阻塞 |
| `D26` / `LOCATION-001` 已 Ready | 所有结果绑定合法、不可变 single/A-B 地点 | absent、非法、范围外、同 A/B 或过期引用由上游拒绝，不请求资料或产生 ICI；无阻塞 |
| `D27` / `GEO-001` 已 Ready | 四项行政区分项只能使用 resolved 行政区语境 | unresolved/ambiguous 不以邻近地区、州中心或名称猜测替代；四项保持 missing；无阻塞 |
| `D28` / `TRANSIT-001` 已 Ready | 交通分项只能复用唯一 canonical connectivity result | 验证地点、1,500m、分析日期、GTFS 快照/参照组版本一致；不读原始 GTFS 或另算分数；无阻塞 |
| `D29` / `PRIVACY-001` 已 Ready | 权重、未完成保存和晚到结果不跨账户 | scope close 后该 Owner 的权重内存/副本不可读；公共分项缓存不属于私有 payload；无阻塞 |
| `RISK-SCHEMA-01` / `RISK-SCHEMA-02` | 真实五项输入、稳定读取对象及三项 `1–10` 权重仍须与 Catalog 迁移契约对齐 | Infrastructure 实现前验证 canonical 镜像/读取对象的字段、键、完整/空/部分导入与两账户迁移样本；不以现有五项 `0–1` 表或 fixture 代替 |

## 3. 对外协调契约

### 提供

| ID | 消费者 | 动作与可观察事实 | 输入、结果与失败语义 | 权限与副作用边界 |
| --- | --- | --- | --- | --- |
| `INFRA-001` | Application Shell；Personalized Location Suitability | 对一个合法 single 地点提供五项分项和带账户权重的单点 ICI；对 A/B、地点摘要和 Suitability 提供 distinct neutral ICI。每项保留实际行政区或固定半径、单位、资料日期、来源、模型/参照组版本、available/missing 原因和权重语境。 | 输入为 `LOCATION-001` 不可变地点、对应 `GEO-001` 行政区事实、同一地点的 `TRANSIT-001` canonical connectivity result，以及 opened scope 内的账户权重读取/预览/保存意图。合法未保存值立即产生 single `unsaved preview`；失败保留草稿/预览，可 retry 或恢复 last saved。只有远端成功保存才发布带版本的跨设备账户变化。single account-weighted ICI 仅在可用基础权重达到 60% 时产生；A/B、摘要和 Suitability 的 neutral ICI 固定三项权重 `5`。非法地点、Geo 未解析、资料未知、交通分不可用或 invalid weight 都保留具体原因，绝不改为 0。A/B 只有两端 neutral 结果的资料口径、模型/参照组版本和可比条件相容时才给差异。 | 仅 opened 主应用消费。用户只读写自己的 `user_ici_preferences`；未保存预览只在当前账户/单点页面内存，不构成跨设备变化。Feature 不写地点、交通资料、评估偏好、预算预案或 Suitability；结果不包含其他账户权重。 |

`INFRA-001` 有两个不可互换的 ICI 输出：**account-weighted ICI** 仅用于本 Feature 的 single 页面，使用账户最后已保存权重或当前合法 `unsaved preview`；**neutral ICI** 固定三项均为 `5`，是 A/B、地点摘要与 Personalized Location Suitability 的唯一 ICI。两者共享同一地点、分项、资料状态与公式，但 neutral ICI 不读取、继承或泄露账户权重。账户五项评估偏好也不进入任一 ICI。

交通分项严格消费 `TRANSIT-001` 的 **canonical connectivity result**。只有其 `availability = available` 且可计算的连接性分才是 ICI 的交通分；`incomplete`、`unavailable`、`no_stops`、`no_active_routes` 或上游拒绝均使交通分项 missing，并保留 Transit 原因。实际使用 stale feed 的 warning 随已完整可用交通分保留，不会另算交通分或把 warning 变成 missing。

### 消费

| ID | Owner | 使用目的 | 调用方依赖的结果与失败语义 |
| --- | --- | --- | --- |
| `SHELL-001` | Application Shell | 接收单点/A-B 入口、返回语境和结果组合 | opened scope 的合法分析目的地为 accepted；缺地点、scope 未开或目的地不适用时为 rejected(reason)/authentication required，Infrastructure 不将其改写成资料缺失。 |
| `LOCATION-001` | Map / Location | 取得不可变合法 single/A-B 地点 | 仅 valid snapshot 可开始分析；无地点、范围外、非法或同一点不产生 ICI、缓存写入或默认地点。 |
| `GEO-001` | Geographic Context | 为供水、供电、医疗、教育取得行政区语境 | 只有 resolved 行政区可读取四项；unresolved/ambiguous 返回来源/版本与原因，四项不补零，州不替代行政区。 |
| `TRANSIT-001` | Public Transportation | 取得交通分项唯一连通性事实 | 只消费同地点/1,500m/分析日期/资料版本的 canonical connectivity result；不完整或分数不可用即交通分项 missing，明确零与未知保持 Transit 的原语义。 |
| `PRIVACY-001` | Account Privacy | 限定账户权重的 scope 与关闭清理 | scope close 立即拒绝旧账户权重读写、未完成保存和旧结果；Infrastructure 仅报告自身权重内存/副本已处理，不删除远端权重或公共资料。 |

## 4. 用户可观察行为与跨模块流程

| 入口或用户动作 | 成功结果 | 空、不可用或失败结果 | 必须保持的可访问性 / 安全语义 |
| --- | --- | --- | --- |
| 打开合法单点基础设施分析 | 显示地点/行政区、供水/供电/医疗/教育/交通原始 0–100 分项、ICI、等级、日期、来源、缺失和权重语境 | Geo 或资料不可用时保留可用分项与具体缺失；可用基础权重少于 60% 时 ICI 暂不可用；没有状态以 0 替代 | ICI 是相对覆盖，不称质量、可靠性或官方评级；状态、分数、日期和来源均有文字而非仅颜色。 |
| 首次读取、调整或保存医疗/教育/交通权重 | 缺少记录按 `5/5/5`；每次合法 `1–10` 调整立即以 `unsaved preview` 重算当前单点 account-weighted ICI；成功保存后成为 last saved 并发布跨设备变化 | 非整数/范围外不改预览；保存失败保留草稿/预览及失败原因，用户可 retry 或恢复 last saved，且不发布变化 | 三个控制项清楚对应医疗、教育、公共交通；不更改原始分项、neutral ICI、评估偏好、预算或地点。 |
| 打开 A/B 基础设施比较 | 并列两端各自五项和 neutral `5/5/5` ICI；口径相容时显示差异 | 一端 neutral ICI unavailable、分项缺失或 Geo/Transit 不可用，或两端日期、来源、行政区/半径、模型/参照组版本不相容时，保留原值和原因且不显示差异/赢家 | A/B 不读取 account-weighted ICI、已保存自定义权重或 unsaved preview；交换只改变呈现槽位，结果绑定 A/B 原引用。 |
| 地点摘要或 Suitability 请求 neutral ICI | 对相同地点和同一结果事实返回固定 `5/5/5` neutral ICI，供摘要/Suitability 使用 | 未达到门槛或分项不可用时 neutral ICI 同样 unavailable 并保留原因 | 不显示或传递账户自定义权重；Suitability 仍自行使用五项评估偏好，不在本 Feature 聚合。 |
| 退出、认证失效或切换账户 | 旧账户权重内存/副本和相关晚到结果不可读；新账户只使用自己的远端记录或中性默认 `5` | close 未完成时没有旧/新账户的 account-weighted ICI；可重试关闭 | 可保留无账户信息的公共分项缓存；其中不得有账户 ID、权重或用户名称。 |

跨 Owner 完成条件：Shell 在 `FLOW-02`/`FLOW-03` 只传入 Map 的 immutable 地点引用。Infrastructure 向 Geo 请求行政区语境，并向 Transit 请求相同地点的 canonical result；本 Feature 单独判断 ICI 缺失与 A/B 可比性，Shell 原样展示。在摘要/Suitability 路径，消费者只消费 `INFRA-001` 的 neutral ICI，不能自行固定/套用账户 ICI 权重或复算分项。

## 5. 数据与确定性业务规则

| 目的 | 权威对象或事实源 | 访问 / 应用边界 | 必须保持的语义 |
| --- | --- | --- | --- |
| 五项公共输入与行政区范围 | [`read_infrastructure_inputs`](../data/schema-catalog.md#稳定公共读取对象)；`GEO-001`；[ICI 数据集/年份](../../knowledge_base/locatemy_product/infrastructure_index_scoring.md#数据集) | Flutter 仅经稳定读取对象消费供水、供电、床位、人口、学校、教师和学生；行政区四项只使用 resolved `(state, district)` | 每数据集使用自身最新有效记录、每分项显示自身日期；人口优先同年，最多可用前两年；行政区 `All Districts`/州合计不混入。 |
| 五项分项与单位 | [ICI 分项公式](../../knowledge_base/locatemy_product/infrastructure_index_scoring.md#分项公式)；`TRANSIT-001` | 按唯一公式以供水/供电百分比、床位/人口、学校/教师/学生及 canonical connectivity result 的所需单位和参照组产生分项 | 交通只消费 canonical result；完整公式和换算常数只在知识库。 |
| ICI、权重与缺失 | [ICI 综合指数与优先级](../../knowledge_base/locatemy_product/infrastructure_index_scoring.md#综合指数与优先级) | 仅按唯一公式对可用分项、single account-weighted 或 neutral 应用权重 | 分项内部必要指标缺失则整个分项 missing；未知永不作 `0`，明确 `0` 仍为观测。公式规定的可用性门槛不满足时 ICI unavailable。 |
| 账户权重与中性结果 | [`user_ici_preferences`](../data/schema-catalog.md#身份与账户业务对象)；`STATE-INFRA-WEIGHT-PREVIEW`；`PRIVACY-001` | 远端记录是 last saved 权重的唯一权威；合法草稿仅可驱动当前 single preview；首版不建离线写队列 | health/education/transit 都必须为 `1–10` 整数；保存失败不丢草稿/preview。neutral result 固定 `5/5/5`，不读账户对象；旧五列 `0–1` 对象只可迁移，不能消费。 |
| A/B 可比性 | `INFRA-001`；[地点比较](../../knowledge_base/locatemy_product/domain_objects.md#location-comparison-地点对比) | 两端独立保留 neutral ICI 与元数据；只在可比时派生差异 | 地点、行政区/1,500m、分项定义、日期、来源、参照组/模型版本和完整性须相容；否则并列原值与原因。A/B 不读取 account-weighted ICI 或 preview，也不生成客观推荐。 |

## 6. 验收与 Ready Gate

| Capability | 验收情景 | 用户操作 | 可观察结果 |
| --- | --- | --- | --- |
| `INFRA-01` | resolved 行政区、五项完整资料、交通 `available/served`，且每项来源/日期不同 | 打开单点页 | 五个 0–100 分项和 ICI 依唯一公式显示，明确行政区/1,500m、来源、每项日期、参照组/模型与覆盖非质量含义。对应 `AT-ANALYSIS-01`。 |
| `INFRA-01` / `AT-ANALYSIS-01` | Geo unresolved/ambiguous；四项任意资料/人口年份不合格；Transit incomplete/unavailable/no_stops/no_active_routes；明确零与实际 stale available 交通 | 打开或刷新单点页 | 受影响项为 missing 并保留上游原因；明确零仍为 0，actual stale available 交通分仍可用并带 warning；不足三项基础权重时 ICI unavailable，绝不补零/猜测地区/重算交通。 |
| `INFRA-01` | A/B 完整且相容；一端 partial；日期、来源、行政区/半径、参照组或模型不相容；交换 A/B | 打开比较并交换 | 每端绑定自己的地点与元数据；只有相容时显示差异，其他情况显示不可比原因且无赢家。对应 `AT-COMPARE-01`、`AT-COMPARE-03`。 |
| `INFRA-02` / `AT-ANALYSIS-01`、`AT-SWITCH-01` | 新账户无权重记录；权重 `5/5/5`；合法自定义 `1–10`；边界值 1/10；无效/失败保存、retry 与恢复 last saved | 打开并调整三个权重 | 无记录为中性 `5`；合法调整立即产生标记的 single `unsaved preview`；成功保存才发布跨设备变化。失败保留草稿/preview，可 retry 或恢复 last saved；三个分项原值不变。 |
| `INFRA-01` / A/B；`INFRA-02` / Suitability | 同一地点有已保存或 unsaved 自定义账户权重，打开 A/B、摘要/Suitability；neutral ICI 缺失 | 返回比较/摘要/适配度输入 | single 页面可用账户权重/preview；A/B、摘要和 Suitability 只获得 `5/5/5` neutral ICI，且中性结果不可用时保留原因。对应 `AT-COMPARE-01`、`AT-SUIT-01`。 |
| `INFRA-02` / Privacy | A、B 两账户各有权重；保存中换号、scope close 或晚到结果 | 切换账户/退出后再打开 | A 权重、未完成写入和结果不进入 B；close 期间没有 account-weighted ICI；公共分项不含私有信息。对应 `AT-SWITCH-01`、`AT-RACE-01`。 |
| `INFRA-01`–`02` / `AT-ANALYSIS-01`、`AT-COMPARE-03`、`AT-SWITCH-01` | 中文/English、长数字、资料缺失、颜色不可辨或键盘/读屏操作 | 阅读与调整 | 分项、权重、状态、日期、来源、等级及不可用原因均有文本和可访问名称；不以颜色、图标或滑块位置作为唯一含义。 |

- [x] `INFRA-01`、`INFRA-02` 可追踪到 Owner、`INFRA-001`、事实源、数据对象和验收情景。
- [x] `D25`–`D29` 与下游 `D46` 的责任明确；地点、Geo、交通、隐私、评估偏好与 Suitability 没有被本 Feature 接管。
- [x] 五项、单位、行政区/1,500m 范围、公式、缺失门槛、账户 `1–10` 权重和 neutral `5/5/5` 输出均链接唯一事实源。
- [x] 明确覆盖账户隔离、invalid weights、partial components、Geo/data/transit unavailable、A/B、立即重算、stale warning 与可访问性。
- [x] `RISK-SCHEMA-01`、`RISK-SCHEMA-02` 的 Infrastructure 资料/迁移证据已明确保留为实现 Gate；在无 canonical 读取对象、完整资料导入审计及三项权重迁移证据时，不得以 fixture 或旧表宣称实现完成。
- [x] 独立 Standards/Spec 双轴复审已通过；设计 AI 已依 ADR 0013 批准 Ready。

## 7. Change Log

| 日期 | 状态 | 变更原因 | 受影响的 Capability / Interface / 数据对象 / Feature | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Draft` | Issue #19 建立 Wave 6 Infrastructure Coverage owning design，冻结五项 ICI、账户权重、missing 规则、canonical Transit 复用和 neutral 输出；不改变既有数据模型或批准契约 | `INFRA-01`、`INFRA-02`、`INFRA-001`、`user_ici_preferences`、`read_infrastructure_inputs`、`TRANSIT-001`、D25–D29、D46 | 待独立审查 |
| 2026-09-14 | `Draft` | 项目负责人批准 Q16/Q17：single 合法未保存权重即时预览、失败保留/retry/恢复 last saved、仅成功保存发布跨设备变化；A/B 固定 neutral ICI | `INFRA-01`、`INFRA-02`、`INFRA-001`、`STATE-INFRA-WEIGHT-PREVIEW`、`user_ici_preferences`、D46 | 项目负责人；独立审查待完成 |
| 2026-09-14 | `Ready for Development` | 独立 Standards/Spec 双轴复审关闭全部发现；依 [ADR 0013](../../adr/0013-autonomous-design-ai-ready-approval.md) 批准 Ready | `INFRA-01`、`INFRA-02`、`INFRA-001`、D25–D29、D46 | 设计 AI（项目负责人授权） |
| 2026-09-14 | `Ready for Development` | 全面设计审查补齐缺失资料、权重和可访问性验收的 canonical `AT-*`；不改变 ICI 契约 | `INFRA-01`、`INFRA-02`、`AT-ANALYSIS-01`、`AT-COMPARE-03`、`AT-SWITCH-01` | 项目负责人（本次审查） |
