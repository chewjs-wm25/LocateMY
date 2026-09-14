# Cost of Living & Budget

> 状态：`Ready for Development`
> Owner：`B`
> 系统基线：`5d11769`
> 依赖波次：`5`
> 最后更新：`2026-09-14`
> Prototype 视觉参考：`N/A`（当前 Rework 工作树不含原型；产品事实源记录原型差异）

本文件协调生活成本、预算预案及其消费者。它冻结地点成本结果、当前评估预案和临时换算在跨 Owner
边界上的可观察语义；不规定 Flutter/Supabase 的内部结构、查询/缓存/并发策略、公式实现或测试组织。

## 1. 用户成果与范围

- 用户成果：已开启账户范围的用户可对合法单点看到本地价格、核心市场篮子估算月支出、覆盖率和可用时的地点成本指数；可对 A/B 按同一口径并列结果及差异；可管理按账户隔离的一份当前评估预案，使个人 `ScenarioSpend12`、预算压力和个人化地点适配度重算；没有可用预案金额时，仍可使用不保存的“当前月支出”CPI 等效换算。
- 包含的 Capability ID：`COST-01`、`COST-02`、`COST-03`、`ACCOUNT-09`。
- 不包含及原因：`COST-04`（商品/商家下钻）是 `excluded`，不显示入口；不拥有地点选择、行政区解析、家庭收入百分位、适配度总分或账户评估偏好；不以州级 CPI 称作行政区 CPI，不提供租金或交通的公共默认金额。
- 产品事实源：[生活成本与预算](../../knowledge_base/locatemy_product/features/cost_of_living.md)、[核心业务对象](../../knowledge_base/locatemy_product/domain_objects.md#budget-scenario-预算预案)、[提交承诺](../../knowledge_base/locatemy_product/submission_commitments.md#生活成本与预算)、[UI 规则](../../knowledge_base/locatemy_product/ui_design_spec.md#生活成本与预算)。
- 原型差异：移除 fixture、固定指数、错误的商品 `/月` 单位、未完成的预案选择及无回调“查看商家”。单项价格显示其真实商品单位；RM/月仅用于模型计算的月支出。临时输入不再冒充预案或预算压力输入。

## 2. 依赖、责任与文件边界

| 模块 / 文件边界 | Owner | 负责 | 不负责 | 与其他模块的沟通 |
| --- | --- | --- | --- | --- |
| `lib/features/cost_of_living_budget/` | Cost of Living & Budget | `COST-001`/`COST-002`、生活篮子和成本/预算压力规则应用、3 天公共缓存、`STATE-COST-TEMP`、预算预案 CRUD 与 current 事实 | 地点、行政区匹配、总适配度、偏好、Schema/RLS/migration | 消费 `SHELL-001`、`LOCATION-001`、`GEO-001`、`PRIVACY-001`；提供 `COST-001`、`COST-002` |
| `lib/app/` | Application Shell | 分析/比较/预算设置导航、返回语境和地点摘要/适配度组合 | 成本或预案语义、数据读取、缓存、预案写入 | 消费两项 Cost Interface，保留地点、来源、日期、口径与可用性 |
| `lib/features/map_location/` | Map / Location | 合法不可变 single/A/B 地点引用 | 成本资料、行政区、预案、预算压力 | `LOCATION-001` 向 Cost 提供指定角色快照 |
| `lib/modules/geographic_context/` | Geographic Context | 成本查询所需行政区/州及版本事实 | PriceCatcher 或收入回退、成本模型 | `GEO-001` 返回 resolved/unresolved/ambiguous 结果，Cost 不自行猜测地区 |
| `lib/features/account_privacy/` | Account Privacy | 同账户 scope 门闩与关闭证明 | Cost 的预案内容或公共缓存 | `PRIVACY-001` 要求 Cost 清除旧账户 current 内存选择和任何私有副本 |
| Supabase 公共/私有读取对象 | 数据 Owner / Cost | `read_cost_inputs`、`user_budget_scenarios` 的受控访问 | Flutter 直读镜像表、默认金额或匿名写入 | 字段、RLS、migration 与导入证据仅由 [Schema Catalog](../data/schema-catalog.md)定义 |

Owner 可在自己的 Feature 目录内组织文件；上述只是跨 Owner 受控边界，不冻结数据访问、缓存键、请求时序、冲突处理或测试实现。

### 依赖与未决项

| 依赖或问题 | 影响 | 验证方式 / 最迟解决点 |
| --- | --- | --- |
| `D07` / `SHELL-001` 已 Ready | 成本详情、A/B、预案设置及贡献只能在 opened 主应用中导航/组合 | 以 `FLOW-02`、`FLOW-03`、`FLOW-07` 与 `AT-ANALYSIS-01`/`AT-COMPARE-03` 核对；无阻塞 |
| `D08` / `LOCATION-001` 已 Ready | 查询、缓存和 A/B 结果必须绑定合法不可变地点 | 无/非法/同点不得读写结果；晚到结果按地点/输入版本丢弃；无阻塞 |
| `D09` / `GEO-001` 已 Ready | PriceCatcher 与行政区收入需要明确行政区；州 CPI 需明确州 | unresolved/ambiguous 不得以附近/州或名称猜测行政区；无阻塞 |
| `D10` / `PRIVACY-001` 已 Ready | 预案与 current 语境不得跨账户，关闭时不再作为预算压力或适配度输入 | 以 privacy 清单中的 Cost 条目、`FLOW-01`/`FLOW-07` 和 `AT-SUIT-06` 核对；无阻塞 |
| `read_cost_inputs` 与导入资料完整性 | 无稳定读取和可验证资料时，不能产生真实成本、比较或临时换算 | 按 [Schema 迁移计划](../system/baseline-review.md#schema-迁移计划) 在 Cost 实现前验证官方 schema/键、单位、覆盖率、最大日期，以及州/全国 CPI 的最新共同月份和完整/部分/空导入；这是实现 Gate，不以 fixture 替代 |
| 核心市场篮子版本及 `q(i)`、`w(i)`、全国代表价格/`BaseSpend12` | [统一生活篮子 v1](../../knowledge_base/locatemy_product/cost_basket_v1.md) 已固定 11 项、数量和导入批次冻结规则 | 导入审计验证 item-code/单位/全国代表价格；不可读项目按模型 unavailable/coverage 处理，不替换商品或调整单项数量 |
| CPI 等效换算 | 输入解释为全国基准月支出，结果是最新共同月份的选定地点所属州 Headline/Overall CPI ÷ 全国同口径 CPI 的等效金额 | 任一输入缺失或没有共同月份即分类 unavailable；不跨月补值，不保存、不影响预案/压力/适配度 |
| current 预案删除 | 最后一份预案允许删除；删除 current 后进入无 current 状态，直到用户显式选择仍存在的预案 | 不自动选择其他预案；无 current 时预算压力/适配度不可计算 |

## 3. 对外协调契约

### 提供

| ID | 消费者 | 动作与可观察事实 | 输入、结果与失败语义 | 权限与副作用边界 |
| --- | --- | --- | --- | --- |
| `COST-001` | Application Shell；Personalized Location Suitability | 对单一合法地点或 A/B 两端提供核心市场 `ObservedSpend12`、地点成本指数，以及可用时的个人 `ScenarioSpend12`/预算压力和不保存的 CPI 等效换算。结果逐项带地点、行政区/州口径、篮子/模型版本、来源、观测日期、单位、覆盖率和 fresh/cached/stale/partial/unavailable 状态。 | 输入为 `LOCATION-001` 不可变引用、对应 `GEO-001` 语境、`cache-allowed` 或用户 `refresh`、可选同账户 current 预案，以及仅页面内存的临时月支出。地点指数只比较同版核心市场篮子；A/B 的个人预案结果另带场景语境，只有模型/篮子版本、单位、资料口径和完整性相容时才提供相应差异。临时换算是独立读数，不改变预案、成本报告、预算压力或适配度。 | 只在 opened 主应用读取；公共资料可读写 `cost_public_cache`，但不含账户或预案输入。预算压力只消费同账户已保存 current 预案；不写地点、偏好、适配度或远端预案。预案/地点/语境版本变化后，旧结果不能覆盖新语境。 |
| `COST-002` | Account Center；Socio-economic；Personalized Location Suitability；Application Shell | 管理账户的预算预案，并提供每账户至多一份 current 评估预案或无 current 的快照及带版本的已保存变化事实。Account Center 的 current 摘要固定为名称、额外生活开销（RM/月）、住房支出、交通支出、月净收入、家庭月度总收入及各字段缺失状态。 | 输入为同账户 opened scope 中的读取、新建、重命名、可选非负额外生活开销、住房、交通、月净收入和家庭月度总收入编辑、选择或删除意图。输出为已保存预案/current 或无 current 快照，或 validation、conflict、permission、retryable failure；只有远端写入成功才发布新版本。名称为空白或超出 Catalog 限制、任何已填写金额为负数均为 validation failure；额外生活开销为空表示无额外开销。未保存编辑不冒充 current。 | 仅预案 owner 账户可读写；以 `user_budget_scenarios` 为权威，Feature 不建立离线写队列。月净收入仅供 `COST-001` 的个人预算压力，家庭月度总收入仅供 Socio 的收入位置，二者不互代；变化只使同账户依赖结果失效/重算，不触碰其他账户、临时换算、地点或评估偏好。消费者可重复处理变化，但按版本去重。 |

`COST-001` 的公式正文、资料边界和单位规则只在[生活成本与预算](../../knowledge_base/locatemy_product/features/cost_of_living.md)；`COST-002` 的字段/RLS/migration 只在[Schema Catalog](../data/schema-catalog.md#身份与账户业务对象)。

### 消费

| ID | Owner | 使用目的 | 调用方依赖的结果与失败语义 |
| --- | --- | --- | --- |
| `SHELL-001` | Application Shell | 接收单点/A-B 成本/预算页面与设置入口导航，提交结果或 current 变化后的重组意图 | 仅 opened scope 接受；拒绝/认证要求保留原因，Cost 不将其改写为资料失败；Shell 保留贡献元数据并使旧输入版本失效。 |
| `LOCATION-001` | Map / Location | 读取 single 或 A/B 合法不可变地点 | 只有 `valid location reference` 可查询；`absent`、`outside Malaysia`、`invalid coordinate`、`same comparison point` 不产生缓存写入或成本结果。 |
| `GEO-001` | Geographic Context | 取得行政区 PriceCatcher/收入语境及州 CPI 语境 | `resolved` 才能按所需层级读数；`unresolved`/`ambiguous` 保留来源版本和原因，不用相邻、州级或名称替代行政区。 |
| `PRIVACY-001` | Account Privacy | 仅在同账户 scope opened 时读取/写入预案；关闭时处理 Cost 私有状态 | 关闭开始即拒绝旧账户预案、current 选择和晚到写入/结果；Cost 只报告自身清理完成，不删除远端预案或公共缓存。 |

## 4. 用户可观察行为与跨模块流程

| 入口或用户动作 | 成功结果 | 空、不可用或失败结果 | 必须保持的可访问性 / 安全语义 |
| --- | --- | --- | --- |
| 从合法单点打开生活成本 | 显示地点、本地商品价格及真实单位、官方观测/模型假设/用户输入分组、核心市场或个人预案月支出、覆盖率、来源和日期；核心市场满足门槛时显示地点成本指数，个人预案满足门槛时另显示预算压力 | 行政区未解析、资料/月份/覆盖率不足、住房/交通或收入缺失时保留已知读数和精确原因；不把缺失、RM 0、完整结果或官方统计互换 | 指数、估算、输入、缓存及不可用均有文字；指数不是官方 CPI/评级，RM/月是主读数。 |
| 以 A/B 打开成本详情或总览卡 | 各端按同一不可变引用、核心市场篮子版本和月份窗口并列；个人结果另标同一 current 预案语境；资料可比才显示对应差异，可保留同名商品的单位价格对照 | 一端不可用、部分或口径/版本/单位不一致时保留可用原值与不可比原因，不显示差异或赢家 | A/B 顺序由 Map 定义；不以额外生活开销、住房或交通输入宣称纯地点价格差异。 |
| 填写/明确为 RM 0 的住房、交通、月净收入和家庭月度总收入，并选择 current | 保存成功后，月净收入变化使同账户 `ScenarioSpend12`、预算压力与 Suitability 输入重算；家庭月度总收入变化只使 Socio 收入位置重算 | 未填写住房/交通仍可显示核心市场 `ObservedSpend12` 和地点成本指数；缺月净收入只缺个人压力，缺家庭月度总收入只缺 Socio 收入位置；资料质量不足时不以部分金额计算压力；失败不发布变化 | 可选的额外生活开销为空表示无额外开销；“未填写”与 RM 0 可区分；两种收入的用途与缺失状态分别呈现，不能互代。 |
| 新建、重命名、编辑、选择或删除预案 | 对同账户远端成功保存后显示 current 或明确的无 current 事实与更新结果，并触发依赖读数重算 | 名称/金额校验、权限、冲突或网络失败显示原因，保留可恢复路径和最后已保存事实；不离线排队 | 预案只属于当前账户；临时输入绝不写入预案；删除 current 后不自动选择其他预案。 |
| 无可用预案金额时输入当前月支出 | 显示独立 CPI 等效换算结果及其州/全国同月 Headline/Overall CPI 来源、日期和口径，离开页面即清除 | 输入无效、任一 CPI 缺失或没有共同月份时显示分类原因；不以默认金额或跨月资料产生换算 | 临时输入只在 `STATE-COST-TEMP`；不改变成本报告、预算压力、current 或 Suitability。 |
| 刷新或网络失败 | 用户刷新时重新取得公共资料；有效公共缓存可展示 3 天内结果并标为 cached/stale | 无缓存或过期/版本不匹配缓存时显示 retryable/non-retryable unavailable；不得展示 fixture 或把缓存称 fresh | 刷新不改变地点、A/B、预案或临时输入；缓存只含公共地点/行政区、模型版本、资料日期、取得时间、完整性与结果。 |
| 退出、认证失效或换号 | 关闭时 Cost 的 current 内存选择与私有副本不可读；新账户只从自己的远端预案建立语境 | 关闭未完成时旧/新私有预案均不可用且可重试 | 公共成本缓存可保留但不得含账户、预案、自由文字或用户输入；旧请求/写入不进入新账户。 |

跨 Owner 完成条件：在 `FLOW-02`/`FLOW-03`，Shell 只把 `LOCATION-001` 的 immutable single/A/B 引用交给 Cost；Cost 请求 `GEO-001` 所需层级并独立返回带元数据的各端成本结果，Shell 不替它判定可比性。在 `FLOW-07`，`COST-002` 只有在远端保存成功后发布 current 的版本变化；Shell 使当前账户相关成本/适配度请求失效，Suitability 仅消费同账户、同版本 current 预案及 `COST-001` 产生的合格个人预算压力。范围关闭时按 `FLOW-01` 丢弃私有语境与晚到结果。

## 5. 数据与确定性业务规则

| 目的 | 权威对象或事实源 | 访问 / 应用边界 | 必须保持的语义 |
| --- | --- | --- | --- |
| 成本资料、行政区与收入语境 | [`read_cost_inputs`](../data/schema-catalog.md#稳定公共读取对象)；`LOCATION-001`；`GEO-001` | Flutter 仅经稳定读取对象取得 PriceCatcher、lookup、行政区收入及州/全国 CPI；Cost 请求 Geo 语境，不直读镜像/边界表 | 结果标明实际资料集、统计层级、最大实际 `date` 与来源；州 CPI 不称行政区 CPI；行政区收入的金额单位按官方 metadata 归一化，年度日期不自动除以 12。 |
| 本地价格、月支出、覆盖率、指数和压力 | [生活成本模型](../../knowledge_base/locatemy_product/features/cost_of_living.md#已确认的单点生活成本模型) | 对单一地点、指定篮子版本和最近 12 个月窗口应用唯一模型；不复制公式正文 | 逐商户中位数后再取商户中位数；缺商品删项而非零/最近月/州/全国替代；至少 6 个月和平均覆盖率至少 80% 才显示核心市场地点成本指数；住房与交通存在、核心市场完整且使用已保存月净收入才显示个人预算压力。 |
| A/B 口径 | [生活成本模型：结果与默认场景](../../knowledge_base/locatemy_product/features/cost_of_living.md#结果与默认场景)；`COST-001` | 两端复用同一篮子版本和月份窗口；地点指数只使用核心市场结果，个人 `ScenarioSpend12`/压力另带同一 current 预案语境 | 额外生活开销、住房或交通不进入地点指数；任何一端核心市场不完整或元数据不相容时不生成地点指数差异。个人场景不相容时保留原值与原因，不称纯地点差异。 |
| 临时 CPI 等效换算 | `STATE-COST-TEMP`；`read_cost_inputs` 的州/全国 Headline/Overall CPI | 输入仅留页面内存；以最新共同月份的州 CPI ÷ 全国 CPI 换算；不访问或改变 `user_budget_scenarios` | 任一同口径输入缺失或没有共同月份即 unavailable；不跨月补值；离页清除，绝不参与预算压力或适配度。 |
| 预算预案与 current | [`user_budget_scenarios`](../data/schema-catalog.md#身份与账户业务对象)；[预算预案](../../knowledge_base/locatemy_product/domain_objects.md#budget-scenario-预算预案) | Supabase 为权威；首版无本机副本/离线写队列；字段、RLS 和 migration 不在本文重复 | 每账户至多一份 current；名称非空且金额非负；月净收入只供个人预算压力，家庭月度总收入只供 Socio 收入位置，均可缺失且不互代；成功保存才发布版本变化。删除 current 后保持无 current，直到用户显式选择；最后一份也可删除。 |
| 公共缓存与私有关闭 | [`cost_public_cache`](../data/schema-catalog.md#本机对象)；`PRIVACY-001` | 公共结果仅保存 location/admin key、模型版本、来源日期、取得时间、3 天 expiry/完整性；关闭只清私有预案选择/副本 | 缓存不含预案、收入、临时输入、账户 ID 或用户名称；资料/模型/地点不匹配或已过期不得当作 fresh。 |

## 6. 验收与 Ready Gate

| Capability | 验收情景 | 用户操作 | 可观察结果 |
| --- | --- | --- |
| `COST-01` | 合法单点、resolved 行政区、核心市场完整 12 月资料且覆盖率 ≥80%；另有 current 的住房/交通与月净收入 | 打开成本分析 | 显示真实单位本地价格、核心市场 `ObservedSpend12`、覆盖率和可解释地点成本指数；同时显示个人 `ScenarioSpend12`、地点基线与个人预算压力；每项带地点、资料/模型来源和日期，不称官方 CPI/评级。 |
| `COST-01` | 核心市场缺商品、少于 6 个月、覆盖率不足、Geo unresolved/ambiguous 或资料不可读；或住房/交通/收入未填写 | 打开或刷新分析 | 显示可得 observed/partial 读数和覆盖/Geo 原因；核心市场完整时仍显示地点成本指数，即使个人预案不完整；个人输入缺失时只省略 `ScenarioSpend12`/压力及适配度成本输入，不以零、最近月、州/全国价格或家庭收入补齐。 |
| `COST-01` | A/B 均完整且同口径；一侧缺失/部分；篮子/单位/日期或预算场景不相容；交换 A/B | 打开比较、切换显示顺序 | 两端保留原地点和元数据；只有相容时显示差异；不相容时显示不可比原因及可用原值，无赢家或自动推荐。对应 `AT-COMPARE-01`、`AT-COMPARE-03`。 |
| `COST-01` | 3 天缓存命中、用户刷新、网络失败有有效缓存、无缓存/过期缓存 | 重开或刷新同一地点 | 结果准确标为 fresh/cached/stale/partial/unavailable，含资料日期与取得时间；刷新不改地点/预案；不用 fixture。对应 `AT-ANALYSIS-01`。 |
| `COST-02` | 无可用预案金额时的有效/无效临时输入，最新共同月份州/全国 Headline/Overall CPI 可用/缺失/不同月，离页返回 | 输入当前月支出 | 仅同月、同口径 CPI 可得时显示 `EquivalentRM = InputRM × StateHeadlineCPI / NationalHeadlineCPI` 的独立且不保存结果；无效/不可用有原因；离页清除，绝不改变预案、压力或 Suitability。 |
| `COST-03`、`ACCOUNT-09` | 两账户分别新建、重命名、编辑、选择、删除最后一份、删除 current；月净/家庭总收入分别缺失或明确为 RM 0；保存失败；current 变化；退出/换号 | 管理预算预案并返回地点摘要/A-B | 仅 owner 看见/修改自己的已保存预案；最后一份可删除；删除 current 后为无 current，直到显式选择且绝不自动选择其他预案；月净收入仅重算预算压力/Suitability，家庭月度总收入仅重算 Socio 收入位置；旧预案缺字段保持缺失；失败不发布；关闭后 A 的 current/副本不进入 B。对应 `AT-SUIT-02`、`AT-SUIT-04`、`AT-SUIT-06`。 |
| `COST-01`–`03` | 中文/English、动态文字、颜色不可用、长数字/金额/百分比 | 阅读正常、部分、缓存、不可用和保存失败状态 | 同一功能/状态均有完整文字和可访问名称；单位、日期、估算/官方/输入边界及错误原因不只靠颜色。 |

- [x] `COST-01`–`03`、`ACCOUNT-09` 均映射至 Cost Owner、`COST-001`/`COST-002`、唯一事实源、数据对象和验收情景。
- [x] `D07`–`D10`、`SHELL-001`、`LOCATION-001`、`GEO-001`、`PRIVACY-001` 的责任、账户边界和副作用不重叠。
- [x] 地点成本指数只使用同版核心市场 `ObservedSpend12`/`BaseSpend12`；额外生活开销、住房和交通只进入个人 `ScenarioSpend12` 与预算压力。
- [x] 公式、单位、资料边界、公共缓存、预案字段/RLS 与隐私关闭均链接各自唯一权威，未复制 SQL、可编译实现、内部缓存/同步策略或公式正文。
- [x] 覆盖单点、A/B、partial/unknown、缓存/刷新、临时输入、保存失败、账户切换、晚到结果及可访问性。
- [x] 项目负责人已批准统一篮子 v1 的项目、数量、权重和导入批次冻结规则；不可读项目按既定 coverage/unavailable 规则处理。
- [x] 项目负责人已批准 CPI 等效换算的全国基准、最新共同月份和 Headline/Overall 口径；`read_cost_inputs` 登记州/全国同月输入。
- [x] 项目负责人已批准 current 预案删除后保持无 current、直到显式选择，以及最后一份允许删除的语义。
- [x] Q18 的 additive 预案字段及其 Cost/Account/Socio 影响已完成独立 Standards/Spec 双轴规格与边界复审；家庭月度总收入和月净收入保持独立、不可替代。

## 7. Change Log

| 日期 | 状态 | 变更原因 | 受影响的 Capability / Interface / 数据对象 / Feature | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Draft` | Issue #13 建立 Wave 5 Cost owning design，冻结成本结果、预算预案/current、临时换算、公共缓存和跨 Owner 边界；初始登记篮子、CPI 换算和 current 删除的决策缺口 | `COST-01`–`03`、`ACCOUNT-09`、`COST-001`、`COST-002`、`STATE-COST-TEMP`、`user_budget_scenarios`、`read_cost_inputs`、`cost_public_cache`、D07–D10 | 后续决定见下一行；独立审查待完成 |
| 2026-09-14 | `Draft` | 项目负责人批准统一篮子 v1、临时换算的全国基准/最新共同月份 Headline/Overall CPI 口径，以及 current 删除后无 current 的显式选择语义；移除相反或待决定表述 | `COST-01`–`03`、`ACCOUNT-09`、`COST-001`、`COST-002`、`STATE-COST-TEMP`、`user_budget_scenarios`、`read_cost_inputs`、`cost_public_cache` | 项目负责人；独立审查待完成 |
| 2026-09-14 | `Draft` | 项目负责人批准地点成本指数仅使用同版核心市场 `ObservedSpend12`/`BaseSpend12`，并固定可空、非负额外生活开销的个人预案语义；据此修正公式口径、可用门槛、A/B 文案和验收 | `COST-01`–`03`、`ACCOUNT-09`、`COST-001`、`COST-002`、`user_budget_scenarios`、`cost_public_cache` | 项目负责人；复审待完成 |
| 2026-09-14 | `Ready for Development` | 独立 Standards/Spec 双轴复审关闭全部发现；同步修正 Geographic Context 的继承索引状态；依 [ADR 0013](../../adr/0013-autonomous-design-ai-ready-approval.md) 批准 Ready | `COST-01`–`03`、`ACCOUNT-09`、`COST-001`、`COST-002`、D07–D10 | 设计 AI（项目负责人授权） |
| 2026-09-14 | `Ready for Development` | Account Center 双轴审查将 `COST-002` 的账户摘要字段显式冻结为名称、额外生活开销、住房、交通、月净收入及缺失状态；不改变预案模型或所有权 | `COST-002`、`ACCOUNT-09`、Account Center | 设计 AI（项目负责人授权） |
| 2026-09-14 | `Draft` | 项目负责人 Q18 批准 additive 的可空非负家庭月度总收入；它仅供 Socio 收入位置，月净收入仍仅供个人预算压力；旧预案不猜测补齐，等待影响复审 | `COST-002`、`ACCOUNT-09`、`SOCIO-001`、`user_budget_scenarios`、Account Center、Socio-economic | 项目负责人 |
| 2026-09-14 | `Ready for Development` | Q18 additive 字段的独立 Standards/Spec 双轴影响复审通过；恢复 Ready，migration 与旧资料导入仍为实现 Gate | `COST-002`、`ACCOUNT-09`、`SOCIO-001`、`user_budget_scenarios`、Account Center、Socio-economic | 设计 AI（项目负责人授权） |
