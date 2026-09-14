# Account Privacy

> 状态：`Draft`
> Owner：`待项目负责人分配`
> 系统基线：`5d11769`
> 消费 Feature：Application Shell、Map / Location、Cost of Living & Budget、Infrastructure Coverage、Hazard Reporting、Property Inspection、Account Center
> 最后更新：`2026-09-14`

本文件协调 Account Privacy 与其消费者。它以一个小的 `PRIVACY-001` Interface 集中账户范围的门闩和关闭证明；每个参与 Owner 仍独占自己的私有 payload、队列与清理执行。本模块不规定内部类型、注册机制、并发策略、文件拆分、Storage/SQLite Adapter 或测试组织。

## 1. 建立理由、责任与文件边界

- 跨 Feature 共享的规则是：只有当前已认证账户的本机私有状态可读；退出或换号时，先阻断旧账户读取，再由每个业务 Owner 清理其私有本机内容，最后才证明旧范围已关闭。
- Map / Location、Cost of Living & Budget、Infrastructure Coverage、Hazard Reporting、Property Inspection 和 Account Center 分别拥有不同的账户私有状态。若删除本模块，privacy barrier、完成判断和失败恢复会散落在 Application Shell 与所有 Owner，无法作为一项可验证的跨 Owner 不变量。
- 本模块不拥有认证凭据或会话结束、任何业务 payload 或同步、远端记录或 Storage 对象的删除、公共缓存、语言偏好，亦不把未来离线能力推导给没有明示队列的 Feature。
- 对应系统基线：[FM-PRIVACY](../system/feature-map.md#fm-privacy)、`D01`、`D03`、`D06`、`D10`、`D20`、`D29`、`D32`、`D37`；私有状态和参与者清单以[数据所有权](../system/data-ownership.md#privacy-barrier-参与者清单)为准。

| 模块 / 文件边界 | Owner | 负责 | 不负责 | 与消费者的沟通 |
| --- | --- | --- | --- | --- |
| `lib/features/account_privacy/` | Account Privacy | 账户范围 `opened`/`closed` 事实、参与 Owner 清单、先阻断再清理、按 Owner 汇总结果 | 参与者 payload、会话 SDK、导航、远端删除、公共缓存 | 提供 `PRIVACY-001`；接受 `AUTH-001` 的账户身份事实 |
| `lib/app/` | Application Shell | 认证门控、私有 UI/意图入口阻断、发起范围开启/关闭、据结果显示登录或清理恢复态 | 替任何业务 Owner 清理 payload 或判定其已清理 | 唯一发起 `PRIVACY-001`，只在同账户 `opened` 时建立私有 Feature |
| 各参与 Owner 的 Feature 目录 | 相应业务 Feature | 自己的账户分区、payload 与清理执行，并返回自身处理结果 | 汇总其他 Owner 或打开/关闭账户范围 | 接收自己的账户目标和关闭请求；不向其他 Owner 暴露 payload |

Owner 可在自己的目录内组织实现，但不得改变 `PRIVACY-001` 的可观察语义或把未登记的私有本机状态带入集成。

## 2. 消费者、依赖与协调契约

| 消费 Feature | 使用目的 | 依赖的 Interface / 事实源 | 所需结果与安全边界 |
| --- | --- | --- | --- |
| Application Shell | 在认证后开放同账户主应用；退出/换号时维持隐私屏障与恢复入口 | `PRIVACY-001`；`AUTH-001`；[FLOW-01](../system/flows.md#flow-01启动注册登录退出与账户切换) | 只在 `opened` 创建私有呈现；只有 `closed` 才完成旧范围关闭。失败或 identity mismatch 时没有任何旧/新账户私有内容可访问。 |
| Map / Location | 按账户隔离收藏缓存和离线创建队列 | `PRIVACY-001`；[数据所有权](../system/data-ownership.md#privacy-barrier-参与者清单) | 同账户 opened 才读取；关闭结果须证明旧账户状态、缓存与队列已处理，公共地图/边界缓存保留。 |
| Cost of Living & Budget | 隔离预案的内存选择及任何未来私有副本 | `PRIVACY-001`；Schema Catalog 的 `user_budget_scenarios` | 不清除远端预案；关闭时旧账户本机选择/副本不再可读。 |
| Infrastructure Coverage | 隔离账户 ICI 权重的内存或副本 | `PRIVACY-001`；Schema Catalog 的 `user_ici_preferences` | 公共分项缓存不属于关闭 payload。 |
| Hazard Reporting | 隔离本人/投票私有视图状态与未完成请求 | `PRIVACY-001`；Schema Catalog 的隐患对象 | 去身份公共读缓存可留；旧账户作者或投票状态不可重放。 |
| Property Inspection | 隔离草稿、私有副本、比较选择、待传队列与文件 | `PRIVACY-001`；Schema Catalog 的房产/照片对象 | 未同步本机文件与队列处理后不可读取；退出不删除远端实勘或已上传照片。 |
| Account Center | 隔离评估偏好内存/副本和账户页组合状态 | `PRIVACY-001`；Schema Catalog 的 `user_assessment_preferences` | 不清除远端偏好；旧账户资料组合不可显示。 |

### 提供：`PRIVACY-001` Account Scope

| 消费者 | 动作与可观察事实 | 输入、结果与失败语义 | 权限与副作用边界 |
| --- | --- | --- | --- |
| Application Shell；所有已登记私有状态 Owner | 对认证账户打开范围；对旧账户关闭范围。关闭一开始，该账户范围即不可访问；只有 Account Privacy 的完整参与 Owner 清单中的每一项都报告自身旧账户本机内容已处理，才产生 `closed`。 | Shell 输入为不可变账户引用及 `open` 或 `close` 原因。Account Privacy 独占当前基线八个参与 Owner 的完整清单；参与 Owner 只返回自己的处理结果。`open` 仅接受与 `AUTH-001` 当前已认证事实相同的账户，返回 `opened`、`identity mismatch` 或分类失败。`close` 针对已打开范围的不可变旧账户引用，返回 `closed`，或列出未完成、缺失或未知 Owner 的分类失败。重复同账户 open/close 返回与该账户范围事实一致的幂等结果；不同账户、过期或不相符的身份不被提升为 opened。 | 仅 Application Shell 可发起，不能缩减或替换参与清单。参与 Owner 只能处理指定账户分区并保留 payload 归属；本模块不读取 payload。关闭先阻断私有读取和新业务意图，随后汇总 Owner 处理；失败可重试，已处理项目不恢复。`closed` 不删除远端记录、其他设备会话、公共缓存或语言偏好。 |

`AUTH-001` 是账户引用与当前设备会话事实的唯一来源。Shell 在认证结束前保留已打开范围的不可变旧账户引用，以便即使 Auth 已结束，`PRIVACY-001.close` 仍只针对该旧账户处理；它不能据此重新打开范围或恢复会话。若认证账户与已打开范围不一致，结果为 `identity mismatch`，旧范围保持不可访问并走关闭恢复，而非向任一账户呈现私有内容。

## 3. 数据、确定性规则与用户结果

对象字段、RLS 和迁移只在 [Schema Catalog](../data/schema-catalog.md) 定义；本模块只协调本机账户范围。以下清单是当前系统基线中每类私有本机状态的关闭证明，不创建第二个 payload Owner。

| 私有状态类别 | 业务 Owner | 关闭时的可检查结果 | 明确保留 / 不处理 |
| --- | --- | --- | --- |
| 当前设备认证会话 | Authentication & Session | `AUTH-001` 已结束当前设备会话；该结果与 privacy 关闭共同决定能否回到普通登录入口 | 其他设备会话、远端业务记录 |
| 私有导航栈、待处理意图、组合请求、私有 ViewModel | Application Shell | 旧账户私有 UI/意图不可再进入，旧请求结果被丢弃，且不以旧实例建立新账户内容 | 语言偏好、无身份 Shell 配置 |
| 地点状态、收藏私有缓存与离线创建队列 | Map / Location | `STATE-LOCATION`、旧账户收藏缓存和创建队列已清除或不可再读取/重放 | 公共地图和边界缓存 |
| 当前评估预案的内存选择及任何私有副本 | Cost of Living & Budget | 旧账户选择/副本不可读，不能成为新账户预算压力或适配度输入 | Cost 公共缓存、远端预算预案 |
| 账户 ICI 权重内存或副本 | Infrastructure Coverage | 旧账户权重不可读，不能影响新账户单点 ICI | 公共基础设施分项缓存、远端权重 |
| 本人报告/投票私有视图状态与未完成请求 | Hazard Reporting | 旧账户作者或投票状态不可呈现、提交或重放 | 完全去身份的公共隐患读缓存、远端报告/投票 |
| 房产草稿、私有副本、比较选择、照片待传队列与应用目录文件 | Property Inspection | 旧账户上述内容已删除或不可再访问；未完成上传不得在新账户恢复或重放 | 已上传的远端实勘、照片元数据与 Storage 对象 |
| 评估偏好内存/副本和账户页组合状态 | Account Center | 旧账户偏好与资料组合不可显示或作为适配度输入 | 远端评估偏好 |

确定性规则：每一项 close 以该次已打开范围的不可变旧账户引用为目标；Account Privacy 的完整参与清单是 `closed` 判断的唯一集合，当前为上表八个 Owner。每个 Owner 的“已处理”只证明它自己的清单项，不能代表其他 Owner；缺失、未知或不在完整清单中的结果均为分类失败。只有完整清单的所有 Owner 已处理才可返回 `closed`。任一 Owner 未完成时，范围保持关闭、已处理项不回滚，结果保留未完成 Owner 以供同一关闭目标重试。公共数据缓存不得含账户 ID、自由文字或用户命名；其对象定义和验证责任仍归相应公共缓存 Owner。

| 用户或消费者动作 | 成功结果 | 空、不可用或失败结果 | 必须保持的安全 / 可访问性语义 |
| --- | --- | --- | --- |
| 首次恢复/登录后开启同账户范围 | `opened` 后 Shell 建立同账户私有 ViewModel 并进入主应用 | 无会话、身份不符或可恢复失败时不建立私有内容 | 认证事实不可确认不等于已认证；不以缓存推测 opened。 |
| 重复开启同一账户 | 返回同一 `opened` 事实，不重复暴露或混入新的账户分区 | 不同/过期账户引用为 identity mismatch 或分类失败 | 调用可重复，账户引用不可替换。 |
| 退出、强制退出或换号关闭旧范围 | 所有 Owner 已处理后 scope 为 `closed`；只有 `AUTH-001` 也已确认当前设备会话结束，普通登录入口才可显示。换号随后重新认证并为新账户开启范围 | 任一 Owner 未完成时停在无私有内容的清理恢复态，列出 Owner；Auth 尚未确认结束时不把 `closed` 误呈现为已退出 | 旧范围在清理前已不可读；不影响远端记录或其他设备会话。 |
| 对未完成 Owner 重试关闭 | 仅针对同一旧账户重试，完成后返回 `closed` | 仍失败时保持关闭并保留分类结果 | 不恢复已处理内容，不允许新账户私有入口。 |

## 4. 验收与 Ready Gate

| Capability / 消费者 | 验收情景 | 操作 | 可观察结果 |
| --- | --- | --- | --- |
| `ACCOUNT-07` / Application Shell | 首次开启 | 恢复或登录得到明确同账户 `AUTH-001` 事实后开启范围 | 仅收到 `opened` 后进入主应用；无会话或不可确认时没有私有内容。 |
| `ACCOUNT-07` / 全部 Owner | 重复 open/close | 对同一账户重复开启；完整关闭后重复关闭 | 结果与现有范围事实一致；没有重复 payload、重放或跨账户内容。 |
| `ACCOUNT-07` / 全部 Owner | 部分清理失败与重试 | 对完整清单中每一个 Owner 分别报告未完成结果，再重试 | 首次即阻断旧内容和新登录；结果准确列出 Owner；缺失/未知 Owner 同为失败；已处理项不恢复；成功重试后才 `closed`。 |
| `ACCOUNT-07` / Authentication & Session、Application Shell | 强制退出或认证/scope 身份不符 | 会话远端拒绝，或认证账户与已打开范围不一致 | 旧范围不可读，转入关闭恢复；不会用不符身份开启或显示私有内容。 |
| `ACCOUNT-07` / Application Shell、全部 Owner | 两账户切换 | A 已开启时退出/关闭，再登录 B 并开启 B | A 的八类私有本机状态均不可见、不可提交、不可重放；B 只见自己的数据；公共缓存和语言按其规则保留。 |

- [x] 共享必要性、消费者、Owner、受控文件边界与 `FM-PRIVACY`、`D01` 及全部下游 privacy 边一致。
- [x] `PRIVACY-001` 与 `AUTH-001` 的账户引用、会话结束和 Shell 协调责任一致；Interface 正文只在本文件定义。
- [x] 系统基线的八个参与 Owner 与其私有本机状态均有唯一业务 Owner 和可检查 close 结果；公共缓存、语言、远端记录及其他设备会话明确在范围外。
- [x] 验收覆盖首次/重复 open-close、逐 Owner 部分失败、重试、强制退出与两账户切换。
- [x] `RISK-PRIVACY-01` 与 `RISK-PRIVACY-02` 的可观察风险情景已固定：完整清单不得漏项；任一 Owner 未完成、SQLite/文件不可用、部分处理或重启后均保持旧范围不可访问，且同一旧账户可恢复关闭。
- [ ] 项目负责人须处置系统风险登记的时序：`risks-and-decisions.md` 当前把 `RISK-PRIVACY-01` 的逐 Owner 验证和 `RISK-PRIVACY-02` 的本机故障验证列为 Account Privacy Ready 前关闭，但 ADR 0012 将 Adapter、运行时策略和测试组织留给实现 Owner。负责人应记录这些证据是设计审查即可关闭，还是移至实现后的集成验收；在该处置前本设计不能进入 Ready。
- [ ] 独立标准/规格审查发现已关闭或由项目负责人明确接受。
- [ ] 项目负责人已批准 `Ready for Development` 并分配实现 Owner。

## 5. Change Log

| 日期 | 状态 | 变更原因 | 影响的 Feature / Interface / 数据对象 | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Draft` | Issue #8 建立 Wave 2 owning design，冻结账户范围 lifecycle、Owner-attributed close 结果与 privacy barrier；不改变各 Feature payload 所有权 | `PRIVACY-001`、`AUTH-001`、`STATE-ACCOUNT-SCOPE`、`ACCOUNT-07`、D01/D03/D06/D10/D20/D29/D32/D37 | 待项目负责人批准 |
