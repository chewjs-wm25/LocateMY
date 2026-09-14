# 系统 Interface 注册表

> 状态：`Draft — Issue #4 complete registry`
> 最后更新：2026-09-13

本表是跨 Feature Interface 摘要与外部 seam 的唯一真相。动作族、可观察结果、授权和跨 Owner 副作用的完整协调语义留给 owning Feature/shared module 设计；语言级成员、内部运行时策略和 Adapter 规格由各 Owner 封装。数据字段只在 [Schema Catalog](../data/schema-catalog.md) 定义。表内无语言声明。

## 跨 Feature Interface

| ID | Owner | 消费者 | 用途 | 领域输入 | 领域输出与结果语义 | 权限 | 异步行为 | 副作用 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `AUTH-001` | Authentication & Session | Account Privacy；Application Shell；Account Center | 恢复/建立/结束当前设备会话并提供真实邮箱确认状态；协调契约见 [owning design](../features/authentication-and-session.md#3-对外协调契约) | 启动恢复；邮箱凭据；当前会话与本机退出意图 | 已认证、需要验证、未认证或分类失败；账户引用、邮箱与真实确认状态 | 恢复/登录可匿名；资料与退出须匹配当前会话；凭据不越过 Interface | 消费者可处理身份事实变化；内部交付机制由 Owner 决定 | 可更新或清除认证 SDK 本机状态；不影响其他设备或业务记录 |
| `PRIVACY-001` | Account Privacy | Application Shell；所有私有状态 Owner | 打开同账户 scope；退出/换号时关闭旧 scope 并证明本机私有状态已处理；协调契约见 [owning design](../modules/account-privacy.md#2-消费者依赖与协调契约) | `open` 输入当前已认证账户引用；`close` 输入已打开 scope 的不可变旧账户引用及原因。Account Privacy 维护完整登记 Owner 清单，各 Owner 仅返回自己的处理结果 | `opened`、`closed`、`identity mismatch` 或列出未完成、缺失或未知 Owner 的分类失败；重复调用保持幂等结果 | 仅 Shell 发起；参与者只能处理输入账户分区 | 关闭等待完整登记清单的所有 Owner；失败可重试且旧 scope 始终不可访问 | 打开匹配分区；关闭清除旧账户本机状态/队列/文件；不删远端记录、公共缓存或语言 |
| `SHELL-001` | Application Shell | 所有 Feature/shared module | 在认证门控内处理导航意图、返回上下文、双 Tab、图层/摘要槽位和组合工作流 | 目的地、不可变领域输入、来源上下文；声明式图层或摘要贡献 | `accepted`、`rejected(reason)`、`authentication required`；组合结果保留每项来源/日期/口径/可用性 | 主应用目的地须已认证且同账户 scope opened；登录/注册例外 | 导航即时分类；组合工作流等待所需提供方，允许独立分项渐进完成 | 更新导航/Tab/组合呈现；换号丢弃私有栈和过期响应，不改写 Feature 数据 |
| `LOCATION-001` | Map / Location | Application Shell；Cost；Crime；Facilities；Transit；Hazard；Socio；Infrastructure；Property；Suitability | 提供与可变选点隔离的合法单点、A/B 或房产地点引用 | 用户点选/候选坐标及角色；读取时指定 `single`、`A`、`B` 或 `property` | 不可变 `valid location reference`，或 `absent` / `outside Malaysia` / `invalid coordinate` / `same comparison point`；A/B 只表顺序 | 仅 opened 主应用 scope；不申请 GPS | 校验完成后发布引用；晚到候选不得覆盖较新请求 | 合法选择更新相应角色、Marker/卡片；读取快照无副作用；角色间不静默互改 |
| `LOCATION-002` | Map / Location | Hazard Reporting；Crime & Security；Nearby Facilities | 寄宿 Feature 的声明式地图图层、点击意图与长按坐标意图 | 图层内容、显示条件、稳定条目标识、点击意图；合法长按坐标 | `accepted`、`hidden`、`rejected(reason)`；点击回传领域标识，不泄漏地图内部对象 | 图层读取须符合提供 Feature 权限；长按创建须 authenticated | 图层可分页/增量更新；较旧 viewport 结果被忽略 | 更新地图覆盖物与相机；不改变分析地点，除非用户显式确认选点 |
| `GEO-001` | Geographic Context | Cost；Crime；Socio-economic；Infrastructure | 从坐标解析州、行政区或警区且保留边界资料版本；协调契约见 [owning design](../modules/geographic-context.md#2-消费者依赖与协调契约) | 合法地点坐标与请求口径 | `resolved(context, boundary version)`、`unresolved(reason)`、`ambiguous(candidates)`；行政区和警区分开 | opened 主应用流程；边界资料为公共只读 | 单次查询；可缓存确定性结果，版本变化使旧缓存失效 | 只读边界资料/缓存；不改写 Map 地点或分析结果 |
| `HOME-001` | Home & Relocation Outlook | Application Shell | 提供全国搬家时机、宏观卡与刷新状态 | `cache-allowed` 或用户 `refresh` | fresh/cached/stale、partial 或分类 unavailable；每项带单位、数据日期与原因；刷新冷却剩余时间 | opened 主应用流程 | 多源可独立完成；成功强刷后 60 秒内拒绝重复强刷 | 读写 Home 公共缓存和内存冷却；不写账户资料 |
| `COST-001` | Cost of Living & Budget | Application Shell；Personalized Location Suitability | 计算单点/A-B 成本、预算压力与临时 CPI 等效换算 | 地点引用、行政区 context、读取策略；可选当前预案；页面临时月支出 | 单点或 A/B 可比/不可比结果；金额、单位、覆盖率、日期、来源；预算压力或 prerequisite/data unavailable；临时换算单独标识 | 公共资料需 opened；预案须同账户 scope | 公共资料可缓存；预案变化使依赖结果重新计算；临时换算不等待保存 | 读写 Cost 公共缓存；临时值只在页面内存；不修改预案 |
| `COST-002` | Cost of Living & Budget | Account Center；Socio-economic；Personalized Location Suitability；Application Shell | 管理预算预案并提供唯一当前评估预案快照/变化事实 | 同账户 scope、预案 CRUD/选择动作 | 已保存预案与当前快照，或 validation/conflict/permission/retryable failure；变化事实含版本 | 仅 owner 账户；RLS 与 scope 双重限制 | 写入成功才发布变化；事件可重复处理，消费者按版本去重 | 写 Supabase 权威预案；更新同账户私有副本；不触碰其他账户或临时换算 |
| `SAFETY-001` | Crime & Security | Application Shell；Property Inspection；Personalized Location Suitability | 提供警区安全结果、趋势与声明式警区图层 | 地点引用、resolved police district、读取策略 | available/partial/cached 或 unresolved/data unavailable；带警区、年份、来源、完整性；A/B 可比性 | opened 主应用；公共只读资料 | 查询可缓存；晚到结果与地点引用绑定 | 读写 Crime 公共缓存；贡献图层；不写隐患或地点 |
| `FACILITY-001` | Nearby Facilities | Application Shell；Map / Location 摘要；Personalized Location Suitability | 提供 2 公里五类 OSM 覆盖结果 | 地点引用；`cache-allowed` 或 `refresh` | fresh/cached/complete empty/retryable unavailable/non-retryable unavailable；未知不等于零；A/B 可比性 | opened 主应用；OSM 资料非账户私有 | 刷新绕过缓存；失败可回落有效缓存；部分响应不完成请求 | 读写 Facility 公共缓存并贡献图层；不写账户或全局地点 |
| `TRANSIT-001` | Public Transportation | Application Shell；Infrastructure Coverage；Personalized Location Suitability | 提供 1.5 公里站点、有效路线、连通性分和局部站点选择 | 地点引用、分析日期、标准化 GTFS 快照 | available/stale/no stops/no active routes/incomplete/unavailable；带 feed 时间、范围、完整性；ICI 复用同一结果 | opened 主应用；公共只读资料 | 读取预计算结果；刷新失败可保留旧结果；站点选择为同步局部状态 | 更新 Transit 局部选择/图层；不改变全局地点；不重复为 ICI 计算交通分 |
| `HAZARD-001` | Hazard Reporting | Application Shell；Map / Location；Account Center | 创建/读取/管理公共隐患与每账户投票 | 地点/viewport/分页；报告字段；报告/投票动作 | 页面、详情、本人列表；created/updated/deleted/voted 或 validation/permission/conflict/retryable failure；计数源自投票记录 | authenticated 可读；作者改删本人报告；账户只改本人投票 | 在线写成功才返回成功；分页/viewport 晚到结果作废；首版不排队创建/编辑/删除 | 写 Supabase 报告/投票；贡献公共图层；不改安全指数 |
| `HAZARD-002` | Hazard Reporting | Property Inspection | 为风险快照计算地点附近公共隐患数 | 房产地点引用、固定查询口径、采集请求 | `available(count, radius, captured at)` 或 permission/retryable/non-retryable unavailable；明确零保留 | authenticated read；不要求报告作者身份 | 与 Safety 结果并行；调用方只在全部必需结果成功时替换快照 | 只读报告；不写房产或报告 |
| `SOCIO-001` | Socio-economic | Application Shell | 提供收入、结构、基尼、分布和账户收入位置 | 地点引用、行政 context；可选当前预案月净收入 | 各读数独立 available/unavailable；带统计层级、年份、单位、来源；A/B 可比性 | opened 主应用；预案输入须同账户 | 多数据集分项完成；一项失败不取消其他项 | 只读政府接口；不保存收入（由预案 Owner 保存） |
| `INFRA-001` | Infrastructure Coverage | Application Shell；Personalized Location Suitability | 计算账户权重 ICI 与中性 ICI，复用交通结果 | 地点/行政 context、政府资料、`TRANSIT-001` 结果；可选同账户 ICI 权重 | 五分项及 account-weighted/neutral 两个 ICI 语境，或 partial/unavailable；每项带日期和缺失原因 | opened 主应用；权重读写仅 owner | 政府分项与交通可并行；权重变化只重算账户 ICI | 读取公共资料、读写同账户 ICI 权重；不改交通或评估偏好 |
| `PROPERTY-001` | Property Inspection | Application Shell；Account Center | 管理实勘、草稿、照片、对比、回收站及风险快照 | 同账户 scope、实勘/照片动作、2–3 个标识；Safety 与 Hazard 风险结果 | persisted/queued-photo/retryable/conflict/permission；详情、比较、回收站；风险快照或 `preserved old snapshot` | owner-only；Storage 与元数据均校验父实勘 owner | 草稿可跨重启；照片上传前台重试；永久清空等待元数据和文件结果 | 写 Supabase/SQLite/文件/Storage；软删除可恢复，确认清空永久删除当前账户记录和文件 |
| `ACCOUNT-001` | Account Center | Application Shell；Personalized Location Suitability | 提供五项账户评估偏好快照/变化并组合账户页意图 | 同账户 scope、五项 `1–10` 值或读取动作 | complete snapshot、validation/permission/retryable failure；变化事实含版本 | owner-only；认证资料仍来自 `AUTH-001` | 保存成功才发布；Suitability 对重复事件按版本去重 | 写 Supabase 权威偏好与同账户副本；不写预案、ICI 权重或语言 |
| `SUITABILITY-001` | Personalized Location Suitability | Application Shell | 组合五项已拥有结果生成可解释适配度 | 地点、偏好、当前预案语境、安全/预算/设施/交通/中性 ICI 结果 | 0–100 结果与覆盖说明，或 prerequisite missing/dimension unavailable；A/B 两边均可用才并列，不判赢家 | opened 主应用且账户输入匹配同一 scope | 输入版本变化触发纯重算；不自行查询提供方内部存储 | 无持久化副作用；不改原始结果、偏好或预案 |

## 外部来源 seam

| ID | Owner | Adapter 对端 | 用途与结果边界 | 异步/副作用 |
| --- | --- | --- | --- | --- |
| `AUTH-002` | Authentication & Session | Supabase Auth | 邮箱密码注册/登录、会话恢复/结束和真实邮箱确认状态；协调契约见 [owning design](../features/authentication-and-session.md#3-对外协调契约)；SDK 结果在模块边界分类 | 可更新当前设备 SDK 本机会话；内部 Adapter 策略由 Owner 决定 |
| `LOCATION-003` | Map / Location | Geoapify | 返回限于马来西亚的候选名称与坐标；候选仍须 `LOCATION-001` 做最终空间校验 | 防抖且忽略过期响应；只发网络读取 |
| `GEO-002` | Geographic Context | 版本化行政区/警区边界读取对象；协调契约见 [owning design](../modules/geographic-context.md#2-消费者依赖与协调契约) | 给定坐标与口径返回零/一/多匹配及资料版本；不使用附近地区替代 | 可读公共缓存；测试 Adapter 使用固定边界样本 |
| `FACILITY-002` | Nearby Facilities | Overpass | 返回完整 OSM 原始元素集或限流/超时/网络/无效/部分响应；只有完整响应可产生空结果 | 生产 Adapter 网络读取；Feature 完成归类、去重和圆形过滤后才缓存 |

Supabase Data API、SQLite、文件和 Storage 是各 Owner 的 Data Adapter，不另建一个可绕过领域 Interface 的全局仓库。其可访问对象在 Schema Catalog 登记，Adapter 的内部 seam 由 Owner 封装。

## 依赖边覆盖

| Interface | 覆盖的直接依赖 |
| --- | --- |
| `AUTH-001` | `D01`、`D02`、`D36` |
| `PRIVACY-001` | `D03`、`D06`、`D10`、`D20`、`D29`、`D32`、`D37` |
| `SHELL-001` | `D04`、`D05`、`D07`、`D11`、`D14`、`D16`、`D18`、`D21`、`D25`、`D30`、`D35`、`D39` |
| `LOCATION-001` | `D08`、`D12`、`D15`、`D17`、`D22`、`D26`、`D31`、`D40` |
| `LOCATION-002` | `D19` |
| `GEO-001` | `D09`、`D13`、`D23`、`D27` |
| `COST-001` | `D42` |
| `COST-002` | `D24`、`D38` |
| `TRANSIT-001` | `D28`、`D45` |
| `SAFETY-001` | `D33`、`D43` |
| `HAZARD-002` | `D34` |
| `ACCOUNT-001` | `D41` |
| `FACILITY-001`、`INFRA-001` | `D44`、`D46` |

`D01`–`D46` 每条恰由上表一个 owning Interface 组覆盖；组合消费者可使用同一 Interface，不为每条边复制一个同义契约。

## Owning document Gate

每个 owning design 进入 `Ready for Development` 前补全其 Interface 的消费者、动作族、可观察结果、授权和跨 Owner 副作用/安全不变量。消费者只有在所需上游协调契约冻结后才能固定自己的依赖；不能在消费者文档复制提供方契约。
