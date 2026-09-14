# Application Shell

> 状态：`Ready for Development`
> Owner：`待项目负责人分配（实现学生分配不阻碍设计 Ready）`
> 系统基线：`5d11769`
> 消费 Feature：Home & Relocation Outlook、Map / Location、Cost of Living & Budget、Crime & Security、Nearby Facilities、Public Transportation、Hazard Reporting、Socio-economic、Infrastructure Coverage、Property Inspection、Account Center、Personalized Location Suitability
> 最后更新：`2026-09-14`

本文件协调 Application Shell 与所有 Feature。它固定认证/账户范围门控、一级导航、类型化业务导航、组合槽位及跨 Feature 工作流的可观察结果；认证、地点、领域结果、业务资料、缓存、队列和各 Feature 内部策略仍归各自 Owner。

## 1. 建立理由、责任与文件边界

- 所有 Feature 需要同一条安全入口：只有 `AUTH-001` 已确认当前设备会话，且 `PRIVACY-001` 已为同一账户返回 `opened`，才可建立主应用及其私有呈现。退出或换号时，Shell 先撤去旧账户私有 UI 和业务意图，再协调会话结束及旧范围关闭。
- 所有 Feature 还共用首页/地图两个一级 Tab、子页面返回语境、账户任务入口，以及领域结果的图层与摘要组合位置。删除本模块会把相同的门控、路由、A/B 返回和组合次序散入各页面，无法保持一致的跨账户结果。
- Shell 不拥有认证凭据或会话事实、可变地点、地点/分析/适配度结果的算法与可用性、Feature 私有资料或队列、公共缓存、离线能力、RLS/迁移，也不把下游 Feature 的详细设计或实现策略提前固定。
- 对应系统基线：[FM-SHELL](../system/feature-map.md#fm-shell)、`NAV-01`–`NAV-03`、`D02`–`D05`、`D07`、`D11`、`D14`、`D16`、`D18`、`D21`、`D25`、`D30`、`D35`、`D39`；运行时状态以[数据所有权](../system/data-ownership.md#运行时状态与派生结果)为准，跨 Owner 旅程以[流程](../system/flows.md)为准。

| 模块 / 文件边界 | Owner | 负责 | 不负责 | 与消费者的沟通 |
| --- | --- | --- | --- | --- |
| `lib/app/` | Application Shell | 门控、`STATE-NAVIGATION`、首页/地图双 Tab、账户任务入口、业务导航和组合槽位、`PREF-LANGUAGE` | 会话 SDK、地点选择、领域计算/资料、业务 payload、缓存与队列 | 提供 `SHELL-001`；消费 `AUTH-001`、`PRIVACY-001`；接收 Feature 的类型化意图或声明式贡献 |
| `lib/features/authentication_and_session/` | Authentication & Session | 当前设备会话与真实认证事实 | 主应用路由、账户范围关闭证明 | 提供 `AUTH-001`；Shell 只按其账户与结果门控 |
| `lib/features/account_privacy/` | Account Privacy | 同账户 scope 的 `opened`/`closed` 事实及关闭证明 | Shell 私有导航清理、认证 SDK、任何参与者 payload | 提供 `PRIVACY-001`；Shell 是唯一发起者 |
| 各 Feature 目录 | 相应 Feature | 自己的领域输入、结果、刷新、私有状态、业务导航意图和声明式贡献 | 全局门控、路由执行、其他 Owner 数据解释 | 通过 `SHELL-001` 请求导航或提交具有来源、日期、口径和可用性的贡献 |

Owner 可在自己的目录内组织实现；受控边界只限制上表跨 Owner 入口，不规定内部文件、类型、状态机、SDK/Adapter、并发、重试、取消或测试组织。

## 2. 消费者、依赖与协调契约

| 消费 Feature | 使用目的 | 依赖的 Interface / 事实源 | 所需结果与安全边界 |
| --- | --- | --- | --- |
| Authentication & Session、Account Privacy | 启动、登录后开放、退出/换号和清理恢复 | `AUTH-001`、`PRIVACY-001`、[FLOW-01](../system/flows.md#flow-01启动注册登录退出与账户切换) | 私有主应用只在同账户 `opened` 时存在；关闭开始即拒绝旧意图和旧结果，失败保持无私有内容并可恢复。 |
| Home & Relocation Outlook | 首页、刷新语境与“探索地图” | `SHELL-001`、`HOME-001`、[FLOW-08](../system/flows.md#flow-08首页刷新与探索地图) | 首页是 Tab；探索地图切换 Tab 而不生成默认地点。 |
| Map / Location | 地图 Tab、单点/A-B/分析导航、返回语境及图层/摘要宿主 | `SHELL-001`、`LOCATION-001`、[FLOW-02](../system/flows.md#flow-02单点选址地点摘要与六类分析)、[FLOW-03](../system/flows.md#flow-03地点-ab-比较) | Shell 只传不可变合法地点引用；Tab 切换保持同进程局部状态，退出/换号丢弃私有地点呈现。 |
| Cost、Crime、Facilities、Transit、Socio-economic、Infrastructure、Suitability | 单点/A-B 分析页和地点详情摘要组合 | `SHELL-001`、各自提供 Interface、[FLOW-02](../system/flows.md#flow-02单点选址地点摘要与六类分析)、[FLOW-03](../system/flows.md#flow-03地点-ab-比较) | 各项独立保留来源、日期、统计口径与 available/empty/unavailable；Shell 不把缺失改写为零或替提供方判定可比性。 |
| Hazard Reporting | 新建、详情、本人列表、地图图层点击与返回 | `SHELL-001`、`HAZARD-001`、[FLOW-05](../system/flows.md#flow-05公共隐患投票与本人管理) | 主应用范围内才接受业务意图；公共图层不改变安全结果或全局地点。 |
| Property Inspection | 档案/表单/详情/比较、地图返回式选点及风险刷新旅程 | `SHELL-001`、`PROPERTY-001`、[FLOW-06](../system/flows.md#flow-06房产实勘照片风险快照与回收站) | 返回式选点保留表单任务语境；范围关闭后旧草稿、表单和晚到结果不可进入新账户。 |
| Account Center | 顶栏账户入口、业务入口、语言与退出意图 | `SHELL-001`、`ACCOUNT-001`、`AUTH-001`、[FLOW-01](../system/flows.md#flow-01启动注册登录退出与账户切换) | 账户不是第三个 Tab；认证资料与领域内容仍由提供方解释，语言不随账户关闭。 |

### 提供：`SHELL-001` Application Coordination

| 消费者 | 动作与可观察事实 | 输入、结果与失败语义 | 权限与副作用边界 |
| --- | --- | --- | --- |
| 所有 Feature/shared module | 接收目的地、不可变领域输入与来源上下文，执行首页/地图 Tab、子页、账户任务、返回与组合槽位导航；接收声明式图层/摘要贡献并协调显示。 | 输入为类型化目的地、不可变地点/账户范围相关引用（如适用）、返回上下文，以及带来源、日期、口径和可用性的贡献。结果为 `accepted`、`rejected(reason)` 或 `authentication required`。目标不可用、输入不完整、已过期或不符合当前语境时为 `rejected`，并保留可理解的原因；Shell 不把该结果伪装为领域数据失败。 | 主应用目的地只接受当前已认证且同账户 scope `opened` 的请求；认证页面为例外。Shell 只更新门控、Tab、导航栈和组合呈现；不写 Feature 数据、不改变地点或领域结果。退出/换号时丢弃私有栈、待处理意图、组合请求和过期响应。 |

`SHELL-001` 的组合贡献是声明式呈现输入，不是数据转移：贡献仍由提供方拥有并独立决定其读取、刷新、可用性和领域语义。Shell 等待组成某一用户旅程所需的贡献，但允许独立分项渐进完成；每个已显示分项继续携带提供方给出的来源、日期、口径和可用性。图层点击仅返回提供方定义的类型化意图；Shell 不解释图层业务含义或以点击静默更新全局地点。

### 门控与范围次序

1. 启动或认证事件先消费 `AUTH-001`。没有明确有效的当前设备会话、会话需要验证或会话不可确认时，只呈现认证相关状态，不建立私有路由或组合请求。
2. `AUTH-001` 已认证后，Shell 以相同不可变账户引用发起 `PRIVACY-001.open`；只有 `opened` 才建立该账户主应用和私有 Feature 呈现。`identity mismatch` 或分类失败保持门控，不用缓存或推测补足。
3. 退出、认证失效或换号一开始，Shell 立即阻断旧账户私有 UI、导航、组合请求和新业务意图，保留已打开范围的不可变旧账户引用；随后协调 `AUTH-001` 当前设备会话结束与 `PRIVACY-001.close`。只有会话结束及完整八位参与 Owner 的旧范围关闭均已确认，才显示普通登录入口；任一阶段失败时停在无私有内容的清理恢复态并可重试同一旧范围。
4. 新账户只能从新的明确认证事实重新开始以上开启步骤；旧 Tab、栈、ViewModel、待处理意图或晚到贡献不能作为新账户的内容。语言偏好及无身份 Shell 配置不属于旧范围关闭 payload。

## 3. 数据、确定性规则与用户结果

| 目的 | 权威对象或事实源 | 访问 / 应用边界 | 必须保持的语义 |
| --- | --- | --- | --- |
| 认证与账户范围门控 | `AUTH-001`、`PRIVACY-001`、`STATE-SESSION`、`STATE-ACCOUNT-SCOPE` | Shell 消费认证与 scope 结果，不复制会话或关闭证明 | 只有同账户明确 `opened` 才开放主应用；关闭或不确定时不读、不呈现、不重放私有内容。 |
| 导航与返回语境 | `STATE-NAVIGATION`、`LOCATION-001` 及各 Feature 的类型化意图 | Shell 保存进程内导航事实；分析仅接收快照地点而不回读可变全局选点 | 两个一级 Tab 为首页和地图；子页面统一返回来源任务，A/B 的顺序和原引用不被 Shell 改写。 |
| 语言 | `PREF-LANGUAGE`、[全局导航产品事实](../../knowledge_base/locatemy_product/features/global_navigation.md)与[UI 双语规则](../../knowledge_base/locatemy_product/ui_design_spec.md#双语与内容规则) | `device_preferences` 仅保存设备语言和小型无身份偏好 | 中文/English 覆盖同一功能、状态、错误和归因；选择跨重启与退出保留，不绑定账户；每次只显示一种语言。 |
| 摘要、图层与跨 Feature 组合 | 各 Feature 提供 Interface 的结果或贡献 | Shell 只组织位置与工作流，不读取提供方内部存储或推导领域结果 | 每项保留其地点、来源、日期、单位/口径、缓存/估算及可用性；空、未知、部分和失败不互换。 |

| 用户或消费者动作 | 成功结果 | 空、不可用或失败结果 | 必须保持的安全 / 可访问性语义 |
| --- | --- | --- | --- |
| 冷启动、恢复或登录 | 明确同账户会话加 `opened` 后进入主应用 | 无会话、需要验证、不可确认、identity mismatch 或开启失败时停在认证/恢复状态 | 登录前不能通过深链或业务意图进入主应用；状态和恢复操作有文字，不只依赖颜色。 |
| 切换首页/地图 Tab 或从首页探索地图 | 保留同进程 Tab 的滚动、地图和局部页面状态；探索地图切换至地图 Tab | 缺少有效地点时不产生分析导航或默认城市 | 只有两个一级 Tab；账户入口不是第三个 Tab；图标有文字名称与可访问名称。 |
| 发起分析、详情、业务表单或返回 | `accepted` 后目标接收原始不可变输入及返回语境；返回回到发起任务 | 输入缺少、目的地未提供、目标不适用或范围失效时 `rejected(reason)` | 不以新选点改写已打开分析；返回不丢失必要的表单/比较上下文；拒绝原因可理解。 |
| 等待或刷新组合贡献 | 可用分项渐进呈现并保留提供方元数据 | 单项 unavailable/empty/partial 只影响该项，保留其他可用分项及其重试入口 | 地图、图表与评分有文字摘要；数据状态、风险、趋势或选中不只以颜色区分。 |
| 更换语言 | 当前页面与其可见状态以所选语言重新呈现，跨重启保持 | 偏好保存失败时清楚说明，并保留本次可用语言状态 | 不混用未翻译文案；动态复数和日期按 locale 规则呈现；动态字体 200% 时主要操作与数值不截断。 |
| 退出、强制退出或换号 | 完整关闭旧范围并结束当前设备会话后回到登录；新账户从干净门控开始 | 任一阶段失败时显示清理恢复态与可重试路径 | 旧账户私有内容从关闭开始不可访问，其他设备会话、远端记录、公共缓存和语言不被误删。 |

## 4. 验收与 Ready Gate

| Capability / 消费者 | 验收情景 | 操作 | 可观察结果 |
| --- | --- | --- | --- |
| `NAV-01` / Authentication & Session、Account Privacy | 冷启动无会话、有效会话、会话不可确认、同账户开启、identity mismatch | 启动或完成登录 | 仅在认证和同账户 `opened` 后进入主应用；其余情况没有私有 UI/业务路由且有认证或恢复路径。 |
| `NAV-01` / 全部私有 Owner | 退出、认证失效、两账户切换与任一关闭 Owner 失败 | 从账户页退出、会话失效或登录另一账户 | 旧 UI/意图/晚到结果立即失效；八位参与 Owner 完整关闭且会话结束后才进入普通登录；失败可重试且新账户不继承旧内容。 |
| `NAV-02` / Home、Map / Location | 首页/地图互切、探索地图、从单点/A-B 分析或地图图层返回 | 切换 Tab、发起导航、返回 | 首页/地图是仅有的一级 Tab，局部状态保留；探索地图不选点；分析使用原不可变引用并回到原任务语境。 |
| `SHELL-001` / 分析与适配度 Feature | 单点、A/B、地点详情摘要与六类分析组合；一项或多项不可用 | 提交类型化导航和带元数据的贡献 | Shell 接受合格请求，分项可渐进显示；提供方的日期、来源、口径和可用性不丢失，缺失不被置零或混成总结果。 |
| `SHELL-001` / Hazard、Property、Account | 新建/详情/本人列表、地图返回式选点、账户业务入口与危险退出 | 从入口或图层点击进入并返回 | 意图保留类型和返回语境；账户不是 Tab；危险退出有确认，拒绝或失败不泄漏或重放私有任务。 |
| `NAV-03` / 全部消费者 | 中文与 English、跨重启、退出、账户切换及保存失败 | 在首页或账户入口更换语言 | 同一功能和可见状态以一种选定语言呈现；偏好跨重启/退出且不跨账户混入业务资料；关键图标、状态和动态文字可访问。 |

- [x] 共享必要性、消费者、受控文件边界、责任与排除项与 `FM-SHELL`、`NAV-01`–`NAV-03`、`D02`、`D03` 及全部 Shell 下游边一致。
- [x] `SHELL-001` 的完整协调语义仅在本文件定义；系统注册表只保留摘要，且 `AUTH-001`、`PRIVACY-001`、地点和领域契约仍由各 Owner 定义。
- [x] 门控、退出/换号、双 Tab、业务导航、组合、语言和可访问性分别链接唯一事实源；不包含可编译代码、可直接复用实现、公式正文、字段/RLS/migration 或内部运行时策略。
- [x] 以规格/边界审查逐项核对 `FM-SHELL`、`D02`–`D05`、`D07`、`D11`、`D14`、`D16`、`D18`、`D21`、`D25`、`D30`、`D35`、`D39`、`AUTH-001`、`PRIVACY-001`、`SHELL-001`、`FLOW-01`–`05`、数据所有权与 `RISK-NFR-01`；未发现未归属的契约或冲突。项目负责人接受本设计的本地化/可访问性契约审查；运行时依赖、两 locale 流程和可访问性证据留待 Application Shell 实现/集成验收。
- [x] 项目负责人于 2026-09-14 审阅并批准 `Ready for Development`；实现 Owner 仍待全部 owning design 完成后统一分配。

## 5. Change Log

| 日期 | 状态 | 变更原因 | 影响的 Feature / Interface / 数据对象 | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Draft` | Issue #9 建立 Wave 3 owning design，冻结门控、导航、组合、语言与跨 Owner 工作流的可观察协调契约 | `NAV-01`–`NAV-03`、`SHELL-001`、`AUTH-001`、`PRIVACY-001`、`STATE-NAVIGATION`、`PREF-LANGUAGE`、`device_preferences`、D02/D03/D04/D05/D07/D11/D14/D16/D18/D21/D25/D30/D35/D39 | 待项目负责人批准 |
| 2026-09-14 | `Ready for Development` | 项目负责人确认独立规格/边界复核无未关闭发现，并接受 `RISK-NFR-01` 的运行时证据在实现/集成验收取得 | `NAV-01`–`NAV-03`、`SHELL-001`、`RISK-NFR-01`、所有 Shell 依赖边 | 项目负责人 |
