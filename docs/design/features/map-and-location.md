# Map / Location

> 状态：`Ready for Development`
> Owner：`A`
> 系统基线：`5d11769`
> 依赖波次：`4`
> 最后更新：`2026-09-14`
> Prototype 视觉参考：`N/A`（当前 Rework 工作树不含原型；产品事实源记录 Prototype 的差异）

本文件协调地图、地点角色、收藏与地图图层宿主。它冻结地点在跨 Owner 边界上的合法性、不可变引用、账户隔离及用户可见结果；不规定地图 SDK、空间库、状态机、同步算法、缓存实现或测试组织。

## 1. 用户成果与范围

- 用户成果：已开启账户范围的用户可在可缩放、可拖动的 OpenStreetMap 上浏览、点选或搜索马来西亚内地点；分别管理单点和中性的地点 A/B；保存、查看和删除账户收藏；从合法地点进入分析或比较；在地图中查看寄宿 Feature 的图层并按其意图继续操作。
- 包含的 Capability ID：`MAP-01`–`MAP-06`。`MAP-07` 的用户入口在地点详情，但计算、前提说明和结果的 Owner 是 Personalized Location Suitability；Map 只承载其声明式摘要，不拥有或重算适配度。
- 不包含及原因：行政区/统计州解析归 Geographic Context；六类分析、其数据、可用性、比较判断及适配度归相应分析 Feature；隐患图层内容与报告写入归 Hazard Reporting；应用级认证、路由和组合归 Application Shell。Map 不申请 GPS，不把图层点击静默变成分析地点，也不把收藏坐标伪装成行政区标识。
- 产品事实源：[地图、选址与收藏](../../knowledge_base/locatemy_product/features/map_location.md)、[大学提交承诺：地图、地点与收藏](../../knowledge_base/locatemy_product/submission_commitments.md#地图地点与收藏)、[地图和分析入口 UI 规则](../../knowledge_base/locatemy_product/ui_design_spec.md#地图和分析入口)。
- 原型差异：正式实现使用真实、可手势操作的地图及马来西亚限制的搜索候选，而非静态插图和预设地点；收藏为按账户的远端权威记录与本机同步，而非内存开关或固定列表；地图图层、合法性与分析入口按下述契约运行。

## 2. 依赖、责任与文件边界

| 模块 / 文件边界 | Owner | 负责 | 不负责 | 与其他模块的沟通 |
| --- | --- | --- | --- | --- |
| `lib/features/map_location/` | Map / Location | `STATE-LOCATION`、马来西亚范围校验、地图手势/Marker、单点/A/B/房产地点角色、收藏读写/缓存/create queue、图层宿主 | 分析或适配度计算、行政语境、图层内容、全局导航与认证 | 提供 `LOCATION-001`、`LOCATION-002`；消费 `SHELL-001`、`PRIVACY-001`；经 `LOCATION-003` 取得候选 |
| `lib/app/` | Application Shell | 已开启 scope 下地图 Tab、类型化分析/表单/返回导航及组合槽位 | 地点校验、收藏同步、图层业务语义 | 消费 `LOCATION-001`；按 `SHELL-001` 接收 Map 的导航意图与图层点击意图 |
| `lib/features/account_privacy/` | Account Privacy | 开启/关闭账户范围和关闭证明 | Map 的地点/收藏 payload 或地图缓存实现 | `PRIVACY-001` 要求 Map 清理旧账户 `STATE-LOCATION`、收藏缓存和创建队列 |
| Map / Location 外部搜索 seam | Map / Location | 取得限于马来西亚的候选名称与坐标 | 最终空间合法性、可变地点状态 | `LOCATION-003` 的候选仍须以 `LOCATION-001` 完成范围及坐标校验 |
| 寄宿图层 Feature | Hazard Reporting、Nearby Facilities、Public Transportation | 各自图层内容、权限、刷新、领域标识与点击后的业务意图 | 底图、相机、全局选点、其他图层的解释 | 经 `LOCATION-002` 提交声明式贡献；Map 只呈现并转交类型化意图 |

Owner 可在自己的目录内组织内部文件。受控边界只固定上述跨 Owner 入口，不规定内部符号、SDK/Adapter、缓存键、网络时序、冲突处理算法或测试实现。

### 依赖与未决项

| 依赖或问题 | 影响 | 验证方式 / 最迟解决点 |
| --- | --- | --- |
| `SHELL-001` 已 Ready | 地图 Tab、分析/表单导航和返回语境 | Map 将只传不可变合法引用和类型化意图；在 Ready 审查核对 `FLOW-02`、`FLOW-03`、`FLOW-05` |
| `PRIVACY-001` 已 Ready | 收藏与地点状态的账户隔离和换号清理 | 以八位 Owner 清单中的 Map 条目核对关闭结果；Map Ready 前完成 `AT-SAVED-04` 的设计验收 |
| `RISK-GEO-01` | DOSM/OpenDOSM 行政区边界联合范围已固定为最终马来西亚校验资料；边界点合法，海域与范围外坐标拒绝 | 资料版本与 hash 由 `government_dataset_imports` 审计；边境、岛屿、海域及明显范围外样本留实现/集成验收 |
| `RISK-SYNC-01` | 收藏 create-only 队列已固定客户端幂等键，远端版本为冲突权威，在线删除写入同步墓碑 | 双设备创建/删除、重放、进程终止、晚到响应、墓碑传播与换号留实现/集成验收；不得由旧缓存或队列复活删除项 |
| 地图、网络、SQLite 运行时依赖 | 真实底图、搜索、同步和离线 UX 的运行时证据 | `RISK-NFR-01` 的依赖、离线和可访问性证据留在实现/集成验收；不得把包或版本预先写入设计 |

## 3. 对外协调契约

### 提供

| ID | 消费者 | 动作与可观察事实 | 输入、结果与失败语义 | 权限与副作用边界 |
| --- | --- | --- | --- | --- |
| `LOCATION-001` | Application Shell；Cost；Crime；Facilities；Transit；Hazard；Socio-economic；Infrastructure；Property Inspection；Personalized Location Suitability | 接受用户点选、已选搜索候选或明确业务选点任务，校验后发布与可变选点隔离的不可变合法地点引用；维护 single、A、B、property 四种地点角色及相应 Marker/卡片。 | 输入为候选坐标和所请求角色，或读取时指定角色。输出为 `valid location reference`，或 `absent`、`outside Malaysia`、`invalid coordinate`、`same comparison point`。A/B 只表示呈现顺序；不同角色互不静默改写；读取已发布快照无副作用。候选的国家文字或来源声明不能代替最终空间校验。 | 只在 `PRIVACY-001` 对同一账户为 `opened` 的主应用流程接受或读取。合法选择只更新对应角色及地图呈现；不申请 GPS、不解析行政区、不计算分析结果。较旧候选或结果不得覆盖较新的用户请求；scope 关闭时丢弃地点状态与晚到结果。 |
| `LOCATION-002` | Hazard Reporting；Nearby Facilities；Public Transportation | 为寄宿 Feature 接收声明式图层、显示条件、稳定条目标识和点击意图；对合法长按坐标返回创建意图。Map 根据可见范围组织覆盖物和相机，但不解释业务内容。 | 图层贡献返回 `accepted`、`hidden` 或 `rejected(reason)`；点击仅回传提供方定义的领域标识和类型化意图，不暴露地图内部对象。Transit 贡献只描述当前交通页的分析中心、1.5km 圆、稳定 `feed_id + stop_id` Marker 与选中意图；合法长按产生地点/创建意图；非法或范围外坐标为 `rejected(reason)`。较旧 viewport 结果不得覆盖较新 viewport。 | 图层读取权限由提供方负责，长按创建须 authenticated。Map 更新覆盖物或相机，不改变单点/A/B/分析地点，除非用户明确确认选点；Transit 的选择仍属其页面局部状态。Map 不写报告、设施或交通结果。 |

### 消费

| ID | Owner | 使用目的 | 调用方依赖的结果与失败语义 |
| --- | --- | --- | --- |
| `SHELL-001` | Application Shell | 在地图 Tab 与分析、比较、收藏、图层详情或隐患表单之间执行导航并保留返回语境 | 仅在同账户 `opened` 时，合格目的地得到 `accepted`；输入缺失、过期或目标不适用时为可理解的 `rejected(reason)`，Map 不把导航拒绝伪装成地点或数据失败。 |
| `PRIVACY-001` | Account Privacy | 仅在同账户范围 opened 时读取/同步收藏；关闭时清理私有地点状态、收藏缓存与 create queue | `opened` 才允许私有呈现和同步；关闭开始即拒绝旧账户地点意图和晚到结果。Map 只有自身状态处理完成才报告自己的关闭结果；不删远端收藏、公共地图/边界缓存或语言。 |
| `LOCATION-003` | Map / Location（Geoapify） | 将用户地点名称转换为马来西亚限定的候选名称和坐标 | 候选可能为空、失败或过期；空候选不产生默认城市，失败可解释并允许重新搜索。候选仅是输入，必须再经 `LOCATION-001` 校验；防抖、取消与网络策略由 Owner 封装。 |

## 4. 用户可观察行为与跨模块流程

| 入口或用户动作 | 成功结果 | 空、不可用或失败结果 | 必须保持的可访问性 / 安全语义 |
| --- | --- | --- | --- |
| 浏览、拖动、缩放或点选地图 | 在合法地点显示相应 Marker，并更新用户明确指定的 single/A/B/property 角色 | 范围外、无效或尚未确认的候选不会创建地点角色；保留可理解原因和可重试入口 | 地图不是唯一信息载体：地点、选中角色、范围外反馈和主要操作均有文字/可访问名称；不请求 GPS。 |
| 搜索地点并选择候选 | 显示限于马来西亚的候选；确认后得到合法地点引用 | 空结果、网络失败或过期候选不替换已有地点，也不产生默认地点 | 候选名称、结果状态和选择行为可读；最终空间校验失败明确说明范围问题。 |
| 单点地点详情与操作 | 地图显示单点折叠/展开摘要；可收藏、查看完整分析或发起比较；适配度贡献可用时显示，否则保留其缺失说明 | 任一分析/适配度贡献 unavailable/partial 只影响该项，不被置零或合成为结论 | 摘要保留各提供方的来源、日期、口径、单位和可用性；不显示社会经济、用户隐患、推断性“优势/留意点”，不把点击图层改成地点。 |
| 设定、清空或交换地点 A/B | single 和 A/B 分离；两端合法且不同后可进入六类比较；交换只交换呈现顺序 | 缺 A/B 或相同地点时停留补全状态，按字段说明原因；不自动决定搬迁方向或推荐赢家 | 原引用随分析请求冻结，晚到结果按地点引用入槽；换点不改写已打开分析。 |
| 收藏合法地点 | 在线成功保存到 Supabase 权威记录；离线 create 显示 `queued`，前台同步成功后成为已同步收藏；列表可选择地点或在线删除 | 名称/地点非法不入队；网络/超时保留同账户队列与可重试原因；离线编辑/删除不支持且不伪装成功；冲突以远端为权威 | 收藏名称、坐标、创建时间和账户归属可解释；同步状态有文字。换设备通过前台同步恢复；切换账户时旧缓存/队列不可见、不可重放。 |
| 打开图层、点击图层或长按 | 合格声明式图层按提供方权限/条件呈现；点击到提供方定义的详情意图；合法长按可进入隐患创建任务 | 图层 `hidden` 或 `rejected` 保留原因；分页/加载不完整不称“无内容”；长按非法坐标拒绝 | 图层含义、筛选和写入权限归提供方；Map 不泄露条目内部对象或静默改变分析地点。 |

跨 Owner 完成条件：

1. 在 [FLOW-02](../system/flows.md#flow-02单点选址地点摘要与六类分析) 中，Map 先为用户明确选择的角色发布 `LOCATION-001` 合法快照；Shell 才能把同一快照交给各分析 Owner。各结果独立返回并以其原始元数据贡献摘要，Map/Shell 均不把缺失变为零。
2. 在 [FLOW-03](../system/flows.md#flow-03地点-ab-比较) 中，Map 保持 single 与 A/B 分离，并阻止相同地点；Shell 仅在两端有效时用 A/B 快照建立比较。交换不触发地点重算或改变地点身份，只改变显示槽位。
3. 在 [FLOW-04](../system/flows.md#flow-04收藏地点离线创建与前台同步) 中，Map 在冷启动已 opened、登录后、回到前台或用户手动重试时同步本账户：成功 create 转缓存、再拉取远端版本与删除墓碑；在线删除后更新本机状态。上述顺序及客户端幂等、远端权威和墓碑不复活语义已由 `RISK-SYNC-01` 固定，运行时证据留实现/集成验收。
4. 在 [FLOW-05](../system/flows.md#flow-05公共隐患投票与本人管理) 中，Map 只由 `LOCATION-002` 提供长按坐标和图层宿主；Hazard Reporting 负责表单、写入、详情及图层数据。图层不进入 `SAFETY-001` 或地点适配度。

## 5. 数据与确定性业务规则

| 目的 | 权威对象或事实源 | 访问 / 应用边界 | 必须保持的语义 |
| --- | --- | --- | --- |
| 合法地点与角色 | `STATE-LOCATION`；[地图、选址与收藏](../../knowledge_base/locatemy_product/features/map_location.md)；[Interface 注册表](../system/interfaces.md#跨-feature-interface) | Map 维护可变角色；消费者仅读取不可变 `LOCATION-001` 快照 | single、A、B、property、收藏和分析目标使用统一地点概念；角色之间不静默互改；A/B 中性且不可相同。 |
| 马来西亚搜索与范围校验 | `LOCATION-003`；[大学提交承诺](../../knowledge_base/locatemy_product/submission_commitments.md#地图地点与收藏)；`RISK-GEO-01` | 搜索候选限于马来西亚；最终校验以 DOSM/OpenDOSM 行政区边界联合范围完成，不信任候选文字 | 边界点合法，海域与范围外坐标拒绝；版本/hash 由导入审计记录，边境、岛屿、海域及明显范围外样本留实现/集成验收；不使用默认城市、国家名称或 GPS 作为替代。 |
| 收藏远端权威与离线 create | [`user_saved_locations`](../data/schema-catalog.md#身份与账户业务对象)、[`saved_location_cache` 与 `saved_location_create_queue`](../data/schema-catalog.md#本机对象)、[FLOW-04](../system/flows.md#flow-04收藏地点离线创建与前台同步) | Map 以 Supabase 为权威；每次 create 带同账户唯一客户端幂等键；本机仅保留同账户缓存与 create-only queue；删除在线执行 | 冲突取远端版本；删除写入同步墓碑，旧缓存或晚到队列不得复活已删除项。收藏是命名坐标而非行政区 ID；离线编辑/删除不建立队列。字段、RLS、迁移与具体同步算法只在 Schema Catalog/实现 Gate 定义。 |
| 私有关闭与公共缓存 | `PRIVACY-001`、[数据所有权：privacy barrier](../system/data-ownership.md#privacy-barrier-参与者清单) | Map 对旧账户清除地点状态、收藏缓存及 queue；公共地图/边界缓存不随关闭删除 | 范围关闭后旧账户坐标、名称、队列、请求和晚到结果均不得进入新账户；不删除远端收藏。 |
| 地点详情、六类入口与适配度摘要 | [地图产品事实](../../knowledge_base/locatemy_product/features/map_location.md)、[UI 规则](../../knowledge_base/locatemy_product/ui_design_spec.md#地图和分析入口)；各提供方 Interface | Map/Shell 仅寄宿声明式摘要/导航；各 Feature 拥有读数及可用性 | 单点仅在合法地点后进入六类分析；A/B 两端有效才进入比较总览。适配度仅由 `SUITABILITY-001` 计算；Map 不复制公式、不补默认偏好/预案/维度，且不产生自动推荐。 |

## 6. 验收与 Ready Gate

| Capability | 验收情景 | 用户操作 | 可观察结果 |
| --- | --- | --- | --- |
| `MAP-01`、`MAP-02`、`MAP-03` | 马来西亚境内点选/搜索、边境/离岛/海域/范围外坐标、空/失败/过期候选及快速换点 | 浏览地图、搜索、选择或连续选择候选 | 合法地点只更新明确角色和 Marker/摘要；范围外或无效地点被拒绝且无默认地点；过期响应不覆盖新选择。对应 `AT-LOC-01`、`AT-LOC-02`、`AT-RACE-01`。 |
| `MAP-04` | single 与 A/B 同时存在、缺端、相同点、交换与分析请求仍在进行 | 选择/清空 A/B、交换、进入比较 | 两端合法且不同才进入六类比较；交换仅改呈现顺序，缺端/同点有字段原因，分析按原快照入槽。对应 `AT-COMPARE-01`、`AT-COMPARE-02`。 |
| `MAP-05` | 在线 CRUD、双设备恢复、离线 create 后重启/重放、删除传播、冲突、换号和权限失败 | 命名收藏、手动/前台同步、删除、切换账户 | Supabase 结果为权威；离线只显示 queued；同一 create 不重复、删除传播到其他设备、旧账户缓存/队列不能在新账户呈现。对应 `AT-SAVED-01`–`AT-SAVED-04`。 |
| `MAP-06` | 有合法单点、有效 A/B、无地点，以及六类一项或多项 unavailable/partial/cached | 从详情进入完整分析或比较 | 只把不可变合法引用交给 Shell；无合法前置地点不可进入；每项结果独立保留来源/日期/口径/可用性，Map 不合成或置零。对应 `AT-ANALYSIS-01`、`AT-COMPARE-03`。 |
| `MAP-01`、`MAP-05` / `PRIVACY-001` | scope opened、关闭中、关闭失败重试、账户 A→B 切换与晚到搜索/同步结果 | 登录、退出/换号、重试关闭、恢复网络 | opened 前无私有地点/收藏；关闭开始即不可访问旧内容，Map 对自身私有状态处理完成后才报告；新账户不继承任何地点、名称或 queued create。对应 `AT-SAVED-04`、`AT-RACE-01`。 |
| `LOCATION-002` / Hazard、Facilities、Transit | 图层被允许、隐藏、拒绝、viewport 更新、点击、长按合法/非法坐标 | 显示/点击图层或长按 | Map 正确承载提供方图层和意图；Transit 仅提交当前页面的中心/圆/稳定站点 Marker/选中意图，旧 viewport 不覆盖新 viewport；点击/长按不静默改变地点，写入和业务语义仍归提供方。 |

- [x] `MAP-01`–`MAP-06` 可追踪至 Map Owner、`LOCATION-001`/`LOCATION-002`、事实源、数据对象及验收情景；`MAP-07` 明确追踪至 Suitability Owner 而非复制其契约。
- [x] Application Shell、Account Privacy、Map、图层提供方和分析提供方的责任、文件边界与可观察副作用无重叠。
- [x] 范围校验、收藏同步、账户隔离、分析快照、A/B 中性和图层不改地点已链接唯一事实源；字段、RLS、迁移、公式和内部同步策略未复制进本文档。
- [x] 正常与非正常路径覆盖缺失/范围外/过期候选、快速换点、A/B、离线 create、删除传播、冲突、权限/换号、图层及分析缺失。
- [x] 项目负责人已固定 `RISK-GEO-01` 的 DOSM/OpenDOSM 联合范围、边界点合法与海域拒绝；坐标样本证据留实现/集成验收。
- [x] 项目负责人已固定 `RISK-SYNC-01` 的客户端幂等、远端版本权威与删除墓碑传播；双设备/重放/换号证据留实现/集成验收。
- [x] 独立规格/边界审查已核对 `FM-MAP`、D05/D06、`LOCATION-001`–`003`、`SHELL-001`、`PRIVACY-001`、`FLOW-02`–`05`、数据对象、风险、产品事实与验收链；未发现未归属契约或直接可提交实现内容。
- [x] `RISK-GEO-01` 与 `RISK-SYNC-01` 的设计决定已由项目负责人确认；设计 AI 依 ADR 0013 批准 `Ready for Development`，运行时资料/同步证据仍留实现/集成验收。

## 7. Change Log

| 日期 | 状态 | 变更原因 | 受影响的 Capability / Interface / 数据对象 / Feature | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Draft` | Issue #11 建立 Wave 4 Map / Location owning design，冻结合法地点引用、地图图层宿主、账户隔离的收藏同步及分析导航边界 | `MAP-01`–`MAP-06`、`LOCATION-001`–`003`、`STATE-LOCATION`、`user_saved_locations`、`saved_location_cache`、`saved_location_create_queue`、`SHELL-001`、`PRIVACY-001`、D05/D06/D08/D12/D15/D17/D22/D26/D31/D40 | 待独立审查与设计 AI 依 ADR 0013 批准 |
| 2026-09-14 | `Ready for Development` | 项目负责人固定范围与收藏同步决定；独立规格/边界审查确认契约、资料、风险和验收链完整 | `MAP-01`–`MAP-06`、`LOCATION-001`–`003`、`RISK-GEO-01`、`RISK-SYNC-01`、`user_saved_locations`、`saved_location_cache`、`saved_location_create_queue` | 设计 AI（项目负责人依 ADR 0013 授权） |
| 2026-09-14 | `Ready for Development` | 项目负责人 Q12 确认 Public Transportation 经既有 `LOCATION-002` 提交声明式站点分布图；Map 的通用图层宿主语义不变 | `LOCATION-002`、Public Transportation、D17 | 项目负责人 |
