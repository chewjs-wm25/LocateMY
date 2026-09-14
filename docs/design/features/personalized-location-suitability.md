# Personalized Location Suitability

> 状态：`Ready for Development`
> Owner：`B`
> 系统基线：`5d11769`
> 依赖波次：`7`
> 最后更新：`2026-09-14`
> Prototype 视觉参考：`N/A`（既有原型/fixture 只可作页面结构参考，不是适配度资料或结果）

本文件协调个人化地点适配度与其输入、消费者的可观察语义。它冻结五维前置门槛、转换、加权、缺失重归一化、解释与 A/B 并列资格；不规定查询编排、缓存、状态机、Widget、公式实现或测试组织。

## 1. 用户成果与范围

- 用户成果：在已开启账户范围中，用户可对一个合法地点查看可解释的 `0–100` 个人化地点适配度，或准确看到偏好、当前预案或具体维度为何不可用；在 A/B 中，仅两端均合格且可比时并列显示，绝不标示赢家或自动推荐。
- 包含的 Capability ID：`MAP-07`。
- 不包含及原因：不产生安全、成本、设施、交通或 ICI 的原始结果；不读取/保存偏好、预案或 ICI 权重；不控制地图选点、地点详情导航或六类分析；不提供客观宜居评级、推荐或排序。它们分别属于上游 Feature 或 Application Shell。
- 产品事实源：[个人化地点适配度领域对象](../../knowledge_base/locatemy_product/domain_objects.md#personalized-location-suitability-个人化地点适配度)、[地图适配度规则](../../knowledge_base/locatemy_product/features/map_location.md#个人化地点适配度map-07)、[UI 规则](../../knowledge_base/locatemy_product/ui_design_spec.md#地图和分析入口)、[生活成本规则](../../knowledge_base/locatemy_product/features/cost_of_living.md#预算压力)。
- 原型差异：移除以 fixture、默认偏好、默认预算或其余四维拼出的读数；地点详情只显示实际可计算结果或精确原因，社会经济和用户隐患不加入输入。

## 2. 依赖、责任与文件边界

| 模块 / 文件边界 | Owner | 负责 | 不负责 | 与其他模块的沟通 |
| --- | --- | --- | --- | --- |
| `lib/features/personalized_location_suitability/` | Personalized Location Suitability | `SUITABILITY-001`、五维输入门控、转换/加权/重归一化、解释和 A/B 资格 | 原始分析、账户输入持久化、ICI 内部权重、地图/导航、推荐 | 消费 `SHELL-001`、`LOCATION-001`、`ACCOUNT-001`、`COST-001`/`COST-002`、`SAFETY-001`、`FACILITY-001`、`TRANSIT-001`、`INFRA-001`；提供 `SUITABILITY-001` |
| `lib/app/` | Application Shell | 在地点详情和 A/B 总览请求并组合结果，提供设置入口与返回语境 | 计算、输入回退、可比性或输入解释 | 消费 `SUITABILITY-001`，原样保留其覆盖、警告及不可用原因 |
| 上游 Feature | 各自 Owner | 提供带地点、版本、来源/日期、完整性和可用性的 canonical 输入 | Suitability 转换、偏好加权或总分 | 只通过本节所列 Interface 传递结果；Suitability 不直读其表/缓存 |

| 依赖或问题 | 影响 | 验证方式 / 最迟解决点 |
| --- | --- | --- |
| `D39` / `SHELL-001` 已 Ready | 地点详情/A-B 槽位、设置入口和账户门控归 Shell | 以 `FLOW-02`、`FLOW-03`、`FLOW-07` 和 `AT-SUIT-01`–`06` 核对；无阻塞 |
| `D40` / `LOCATION-001` 已 Ready | 每次单点或 A/B 计算只绑定合法不可变地点引用 | 缺地点、非法、范围外、同点 A/B 或过期引用不产生结果；无阻塞 |
| `D41` / `ACCOUNT-001` 已 Ready | 只能使用同账户 complete preference snapshot | `configured_at` 缺失、页面预填或未保存草稿均为 prerequisite missing；无阻塞 |
| `D42` / `COST-001`、`COST-002` 已 Ready | 当前预案和个人预算压力的输入/质量门槛由 Cost 唯一决定 | 无 current、未保存编辑、字段缺失、partial basket 和临时 CPI 输入都不能生成成本维度；无阻塞 |
| `D43`–`D46` / Safety、Facilities、Transit、Infrastructure 已 Ready | 四项公共维度须复用 canonical 结果及其原因 | 以同地点、输入版本、范围/模型及状态核对；未知不补零，stale warning 不丢失；无阻塞 |
| `RISK-PREF-01` 已关闭为设计决定 | 默认 `5` 不能冒充用户确认偏好 | 实现/集成仍须验证 `configured_at` migration、跨设备与换号；不以设计 Ready 冒充运行证据 |

## 3. 对外协调契约

### 提供：`SUITABILITY-001` 个人化地点适配度

| 消费者 | 动作与可观察事实 | 输入、结果与失败语义 | 权限与副作用边界 |
| --- | --- | --- | --- |
| Application Shell | 为一个合法 single 地点，或 A/B 的每一端，提供五维覆盖说明、各可用原始/转换读数、偏好权重语境、`0–100` 适配度或分类不可用原因；对 A/B 提供并列资格或不可比原因。 | 输入为 `LOCATION-001` 不可变引用、同账户 `ACCOUNT-001 complete snapshot`、`COST-002` current 语境，以及同一地点的 `SAFETY-001`、`COST-001` personal budget burden、`FACILITY-001`、`TRANSIT-001` 和 `INFRA-001 neutral ICI`。输出为 `available(score, explanation)`、`prerequisite missing`、`dimension unavailable`、全维不可用的固定状态，或 A/B `incomparable(reason)`；每项保留地点、输入版本、来源/日期、覆盖/完整性和 stale warning。 | 只在 opened 同账户范围内组合账户输入；不写地点、偏好、预案、ICI 权重、上游结果或推荐。账户/地点/输入版本变化或 scope close 后，旧结果不得发布；公共上游资料不携带其他账户输入。 |

`available` 只表示本产品的个人化读数可以显示，不表示客观宜居、政府评级或推荐。A/B 两端均为 `available` 不产生赢家；仅在本节的 A/B 可比性条件同时满足时才作为可比结果并列，任何情形都不派生数值差值。

### 消费

| ID | Owner | 使用目的 | 调用方依赖的结果与失败语义 |
| --- | --- | --- | --- |
| `SHELL-001` | Application Shell | 进入地点详情/A-B 槽位、提交设置入口和组合结果 | 仅 opened scope 的合格地点/任务可被接受；rejected/authentication required 保留 Shell 原因，不改写为分析资料失败。 |
| `LOCATION-001` | Map / Location | 取得 single 或 A/B 合法不可变地点引用 | 仅 valid reference 可计算；absent、outside Malaysia、invalid coordinate、same comparison point 或过期引用均不产出适配度。 |
| `ACCOUNT-001` | Account Center | 取得同账户五项已配置偏好与版本 | 只接受五项完整 `1–10` 且有 `configured_at` 的 complete snapshot；不存在、null、草稿、保存失败或身份不符为 `prerequisite missing`。 |
| `COST-001` | Cost of Living & Budget | 取得同地点完整 `PersonalBudgetBurden(%)`、地点/预案/资料质量元数据 | 仅 Cost 已发布且满足其完整篮子、住房、交通和月净收入条件的预算压力可形成成本维度；partial/unavailable、家庭月度总收入和临时 CPI 等效换算都不可替代。 |
| `COST-002` | Cost of Living & Budget | 取得同账户 current 或无 current 的已保存预案事实及版本 | 无 current、未保存编辑、scope 不符或保存失败为 prerequisite missing；Suitability 不直接读取预案表，也不将家庭月度总收入作为成本输入。 |
| `SAFETY-001` | Crime & Security | 复用同地点州级安全指数及可用性 | 只接受 Safety 已提供的可用指数和其州/年份/来源/完整性；unresolved、partial 或 unavailable 保留为安全维度原因，不以隐患数、犯罪原始数或 0 替代。 |
| `FACILITY-001` | Nearby Facilities | 复用 2,000m 五类设施的确认覆盖事实 | 只有所有五类查询完整时，才以已确认覆盖类别数形成日常便利维度；任一类别 unknown/unavailable 则整个维度 unavailable，complete-empty 的明确零覆盖仍为 `0`。 |
| `TRANSIT-001` | Public Transportation | 复用同地点 canonical connectivity score 与资料状态 | 只有 availability `available`、service outcome `served` 且连通性分可用时形成交通维度；`incomplete`、`unavailable`、`no_stops`、`no_active_routes` 及上游拒绝均为维度 unavailable。实际使用 stale feed 的 warning 随可用分保留，不改作零或 missing。 |
| `INFRA-001` | Infrastructure Coverage | 复用同地点固定 `5/5/5` 的 neutral ICI | 只接受 neutral ICI；account-weighted ICI、已保存自定义权重和 `unsaved preview` 一律不可输入。neutral ICI unavailable 时保留 Infrastructure 原因。 |

## 4. 用户可观察行为与跨模块流程

| 入口或用户动作 | 成功结果 | 空、不可用或失败结果 | 必须保持的可访问性 / 安全语义 |
| --- | --- | --- | --- |
| 打开有合法地点的详情卡 | 已配置偏好、current 预案和所有中/高维度合格时，显示 `0–100` 读数、五维输入/权重/覆盖说明及来源警告 | 先显示 prerequisite missing，再显示各维度原因；中/高维度缺失不显示总分，不能用默认值或其余维度补齐 | 明确这是个人化读数而非推荐；分数、权重、覆盖、来源、日期和原因均有文字/可访问名称。 |
| 某个低优先级维度不可用 | 在其余合格维度上显示按可用权重重归一化的读数，并指出该低优先级维度未纳入 | 若所有维度不可用或可用权重为零，显示固定“目前没有可用的评估维度”状态，不显示 `0` 或伪部分分 | 低/中/高及被排除原因不只靠颜色；不把 unknown 显示为明确零。 |
| 调整偏好、切换/删除 current，或上游资料/地点刷新 | 上游成功发布的新版本后，Shell 使同账户/同地点旧请求失效并重算；结果绑定新的完整输入语境 | 保存失败、未保存偏好/预案编辑、无 current 或晚到旧结果不发布为新适配度 | 设置入口只交给其 Owner；Suitability 不保存草稿、不反写上游，换号后不见旧账户结果。 |
| 查看 A/B 比较 | 两端各自合格，且纳入/排除的维度集合、上下文和定义完全相容时，独立并列显示两个原始读数、覆盖和输入说明；交换仅改变呈现顺序 | 任一端不合格时指出该端 prerequisite/dimension 原因；两端可算但纳入/排除集合、模型、版本或可比条件不一致时为 `incomparable`，保留各自原分和覆盖说明，不显示数值差值、赢家或推荐 | A/B 保留各自地点与上游元数据；不将适配度并入六类分析总分。 |
| 请求关闭账户或快速换点/换预案 | scope 或输入版本仍匹配时才呈现结果 | 关闭开始即丢弃私有偏好/current 与旧请求；公共上游结果可按其 Owner 继续存在，但不可与旧账户输入重新组合 | 不泄露偏好、收入、预案名称或其他账户信息；恢复后从新账户 complete snapshot/current 重新开始。 |

跨 Owner 完成条件：Shell 按 `FLOW-02` 对同一 single 引用组合摘要，并按 `FLOW-03` 把 A/B 两端独立交给本 Feature；按 `FLOW-07`，偏好或 current 的成功版本变化使旧适配度失效。Suitability 只消费上游已冻结结果和版本事实，集中应用门槛与解释；Shell 不重新计算任一维度或掩盖其状态。

## 5. 数据与确定性业务规则

| 目的 | 权威对象或事实源 | 访问 / 应用边界 | 必须保持的语义 |
| --- | --- | --- | --- |
| 五维、转换与权重 | [个人化地点适配度领域对象](../../knowledge_base/locatemy_product/domain_objects.md#personalized-location-suitability-个人化地点适配度) | 对上游 canonical 读数应用该唯一事实源规定的转换、偏好权重与重归一化 | 输入依序为安全指数、个人预算压力、五类设施确认覆盖、交通连通性和 neutral ICI；输出为可解释的 `0–100` 读数及其已纳入/排除维度。公式正文、边界值与权重计算不在本设计复制。 |
| 偏好和 current 前置条件 | `ACCOUNT-001`、`COST-002`；[评估偏好](../../knowledge_base/locatemy_product/domain_objects.md#assessment-preferences-评估偏好) | 仅使用同账户远端已发布事实 | 五项 complete snapshot 和 current 预案都是计算必要前置条件；无 configured snapshot/current 时为 `prerequisite missing`，不使用默认 `5`、其他预案、草稿或临时输入。家庭月度总收入只属于 Socio 收入位置，永不代替月净收入或成本输入。 |
| 维度可用性与重归一化 | [地图适配度规则](../../knowledge_base/locatemy_product/features/map_location.md#个人化地点适配度map-07) | 逐一保留每个输入 Owner 的 availability/coverage/reason | 缺少任一中/高优先级维度，总分 unavailable；缺少低优先级维度可排除后重归一化并披露；所有不可用或可用权重为零时使用固定不可用文案。明确零分仍是可用输入，未知、partial 或无服务不当作零。 |
| 上游口径与 stale | `SAFETY-001`、`COST-001`、`FACILITY-001`、`TRANSIT-001`、`INFRA-001` | 不重查原始资料或复算上游指标 | 保留州级安全、2km 设施、1.5km 交通、neutral ICI、地点/资料/模型版本、来源、日期、完整性与 stale warning。stale 但上游仍明确可用的读数可参与计算并以警告呈现；partial/unavailable 则按维度规则处理。 |
| A/B 并列资格 | `SUITABILITY-001`；[地点比较](../../knowledge_base/locatemy_product/domain_objects.md#location-comparison-地点对比) | 先独立计算每端，再核对可比较的共同输入语境 | 两端均 `available`、纳入/排除的维度集合完全一致，且来自同一账户的同一 complete preference snapshot、同一 current 预案版本、相同适配度规则版本，并且每个纳入维度的转换定义与上游模型/篮子/类别映射/参照组版本相容时，才是可比并列。不同地点本身的来源/日期/stale 警告必须并列披露，且只呈现两端原始读数与覆盖说明、不派生数值差值；集合或任一条件不相容即为 `incomparable`，仍保留各自原分和覆盖说明。仅一侧不可算是该侧不可用，不伪装成两侧可比。 |
| 状态与私有边界 | `RESULT-*`、[数据所有权](../system/data-ownership.md#运行时状态与派生结果)、`PRIVACY-001` | 当前结果只在页面/ViewModel 内存中，绑定地点和输入版本 | 不建立 Suitability 远端权威对象、离线写队列或跨账户缓存；结果在 scope close 时释放。上游公共缓存不可包含偏好、月净收入、预案或总分。 |

## 6. 验收与 Ready Gate

| Capability | 验收情景 | 用户操作 | 可观察结果 |
| --- | --- | --- | --- |
| `MAP-07` / `AT-SUIT-01` | 同账户 complete 五项偏好、current 预案、五个合格 canonical 维度，含明确 `0` 分和 Transit stale warning | 打开地点详情 | 唯一事实源规则生成 `0–100`；五维、转换、权重、口径/日期/来源和 stale warning 可解释；明确零保留，stale 不静默消失。 |
| `MAP-07` / `AT-SUIT-02` | 偏好不存在/`configured_at` null、无 current、未保存偏好或预案编辑、current 保存失败 | 打开详情或完成设置动作 | 分别显示 `prerequisite missing`，有对应设置/恢复入口；默认 `5`、其他预案、临时 CPI 和家庭月度总收入都不代替输入。 |
| `MAP-07` / `AT-SUIT-03` | 安全、成本、设施、交通、ICI 各自 unavailable/partial/unknown/no route；缺失维度优先级分别为低、中、高；所有维度不可用 | 打开或刷新详情 | 低优先级缺失排除并重归一化且披露；中/高缺失无总分；所有无可用维度使用固定不可用文案。设施 unknown、不完整交通和 neutral ICI missing 不作为 `0`。 |
| `MAP-07` / `AT-SUIT-04` | current 切换、删除 current、补齐/清空住房/交通/月净收入、完整/partial basket，以及地点或上游版本变化 | 管理预案后返回或刷新地点 | 仅已保存 current 的完整个人预算压力可供成本维度；成功版本变化即时使旧结果失效并重算；失败/旧结果不覆盖新语境。 |
| `MAP-07` / `AT-SUIT-05` | A/B 两端均可算且纳入/排除集合完全一致、共同输入相容；单侧 prerequisite/dimension 缺失；两端可算但纳入/排除集合、偏好/current/模型或规则版本不相容；交换 | 进入/交换 A/B | 合格时只并列两个原始读数和覆盖说明；不可用与 incomparable 原因区分。incomparable 时仍保留各自原分和覆盖说明；任何情况不显示数值差值、赢家或自动推荐，交换不重算或混淆地点。 |
| `MAP-07` / `AT-SUIT-06` | 账户 A/B 不同偏好/current，保存中换号、scope close、晚到请求 | 切换账户、退出或快速换点 | A 的偏好、预案、总分和晚到结果不进入 B；关闭期间无个人化总分；公共结果不泄露私有输入。 |
| `MAP-07` / `AT-SUIT-01`–`AT-SUIT-06` | 中文/English、读屏/键盘、200% 字体、长原因/日期/金额、颜色不可见 | 阅读可用、部分和不可用状态 | 分数不是唯一表达；五维、权重、覆盖、限制、状态和设置入口均有可访问文字和合理顺序。 |

- [x] `MAP-07` 可追踪至唯一 Owner、`SUITABILITY-001`、D39–D46、产品事实、运行时状态与验收情景。
- [x] 原始分析、偏好/预案持久化、ICI 内部权重、地图导航和推荐仍分别归既有 Owner。
- [x] 五维转换、偏好门槛、低优先级重归一化、明确零/未知、stale、A/B 和 no-winner 语义均链接唯一事实源。
- [x] 覆盖 prerequisite missing、单维 unavailable、全维不可用固定状态、partial、stale、A/B incomparable、地点/账户/版本变化和可访问性。
- [x] 独立 Standards/Spec 双轴审查及修订复审已关闭全部发现。
- [x] 所有上游阻塞设计均为 Ready；设计 AI 已依 ADR 0013 批准 `Ready for Development`，实现与集成验收仍保留为后续 Gate。

## 7. Change Log

| 日期 | 状态 | 变更原因 | 受影响的 Capability / Interface / 数据对象 / Feature | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Draft` | Issue #21 建立 Wave 7 Personalized Location Suitability owning design，冻结五维门槛、转换/重归一化、解释及 A/B 无赢家边界 | `MAP-07`、`SUITABILITY-001`、`RESULT-*`、D39–D46、Account、Cost、Crime、Facilities、Transit、Infrastructure、Application Shell、Map | 待独立审查 |
| 2026-09-14 | `Ready for Development` | 独立 Standards/Spec 双轴审查关闭公式重复、未定义状态与 A/B 可比性歧义；依 [ADR 0013](../../adr/0013-autonomous-design-ai-ready-approval.md) 批准 Ready | `MAP-07`、`SUITABILITY-001`、`RESULT-*`、D39–D46、`AT-SUIT-01`–`06` | 设计 AI（项目负责人授权） |
| 2026-09-14 | `Ready for Development` | 全面设计审查修复表格、UI 锚点并补齐全域可访问性验收追踪；不改变适配度规则 | `MAP-07`、`SUITABILITY-001`、`AT-SUIT-01`–`06` | 项目负责人（本次审查） |
