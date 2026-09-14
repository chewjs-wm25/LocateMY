# Account Center

> 状态：`Ready for Development`
> Owner：`A`
> 系统基线：`5d11769`
> 依赖波次：`6`
> 最后更新：`2026-09-14`
> Prototype 视觉参考：`origin/Prototype` 的账户页布局；固定资料、占位入口和演示数据不复用

本文件协调 Account Center 与其消费者。它冻结真实账户资料呈现、评估偏好、预算预案摘要和账户业务意图的可观察语义；认证、退出完成、预案、ICI 权重、语言和目标 Feature 数据仍各归其 Owner。内部文件、状态管理、数据访问时序和测试组织由实现 Owner 决定。

## 1. 用户成果与范围

- 用户在已开启的账户范围中看到 Auth 提供的真实邮箱与验证状态；可进入房产实勘档案、本人隐患报告和当前评估预案管理，并能发起确认退出。
- 用户可一次确认安全、成本、日常便利、公共交通可达性和基础设施五项 `1–10` 评估偏好；成功后跨设备恢复，作为个人化地点适配度唯一的偏好输入。
- 包含：`ACCOUNT-01`、`ACCOUNT-02`、`ACCOUNT-08`。
- 不包含：`ACCOUNT-07` 的认证/退出完成、`ACCOUNT-09` 的预案 CRUD/current、ICI 权重、语言偏好，以及房产、隐患或预案的目标数据和规则。`ACCOUNT-03`–`ACCOUNT-06` 已 excluded，不呈现固定示例、统计或空回调。
- 产品事实源：[账户中心](../../knowledge_base/locatemy_product/features/account.md)、[评估偏好](../../knowledge_base/locatemy_product/domain_objects.md#assessment-preferences-评估偏好)、[预算预案](../../knowledge_base/locatemy_product/domain_objects.md#budget-scenario-预算预案)。

## 2. 依赖、责任与文件边界

| 模块 / 文件边界 | Owner | 负责 | 不负责 | 与其他模块的沟通 |
| --- | --- | --- | --- | --- |
| `lib/features/account_center/` | Account Center | 账户页组合、五项偏好读取/完整确认/已保存变化、业务和退出意图 | Auth/预案/语言/ICI/目标资料的读取、规则或写入 | 提供 `ACCOUNT-001`；消费 `AUTH-001`、`PRIVACY-001`、`COST-002`、`SHELL-001` |
| `lib/app/` | Application Shell | 账户入口、接受导航/退出意图、门控及返回语境 | 偏好持久化、Auth 或预案语义 | 接收 `ACCOUNT-001` 贡献和类型化意图；按 `SHELL-001` 返回 accepted/rejected/authentication-required |
| `supabase/migrations/` | 项目负责人 / 学生实现者 | 将已批准的 `configured_at` 契约迁移至表与访问控制 | 定义 Account Center 内部结构 | 方向与字段权威见 Schema Catalog；本设计不含 migration |

| 依赖或问题 | 影响 | 验证方式 / 最迟解决点 |
| --- | --- | --- |
| `D35` / `SHELL-001` | 账户入口、房产/隐患/预案和退出均须是已开启范围中的类型化意图 | 门控、目标缺失、返回及退出失败保留 Shell 的分类结果；无阻塞 |
| `D36` / `AUTH-001` | 邮箱、验证状态与会话/退出事实必须真实 | 验证未知不冒充已验证或未验证；无阻塞 |
| `D37` / `PRIVACY-001` | 偏好内存和账户组合状态只能属于已开启账户 | 关闭起即拒绝读写并清理；无阻塞 |
| `D38` / `COST-002` | 当前预案摘要与进入管理页必须来自预案 Owner | current/no-current、读取失败和写入后变化不由 Account 猜测；无阻塞 |
| `RISK-PREF-01` / `configured_at` | 默认 `5` 不能成为未确认用户的 Suitability 输入 | migration、旧行和首次完整确认均须满足 Schema Catalog 与本设计；Account Center Ready 前关闭 |

## 3. 对外协调契约

### 提供：`ACCOUNT-001` Account Center

| 消费者 | 动作与可观察事实 | 输入、结果与失败语义 | 权限与副作用边界 |
| --- | --- | --- | --- |
| Application Shell；Personalized Location Suitability | 为当前 opened 账户读取五项偏好；一次确认完整五项；发布带版本的已保存 complete snapshot；提交账户业务、预案设置或退出意图。 | 输入是同账户 scope、五项值或类型化意图。读取返回 `complete snapshot`（五项 `1–10`、已配置事实和版本）、`prerequisite missing`（没有 `configured_at`）或分类 failure。确认必须同时验证五项；任一缺失、非整数或范围外为 validation failure。只有远端一次成功保存完整五项并写入 `configured_at` 后发布 complete snapshot；之后的成功修改保留已配置事实并发布新版本。 | 仅 owner 账户可读写自己的 `user_assessment_preferences`；没有离线写队列。`configured_at` 为 null 的行与不存在的行都不得作为 Suitability 输入。变化只使同账户 Suitability 失效；不写预案、ICI 权重、语言、Auth 或目标 Feature 数据。 |

`ACCOUNT-001` 的时间字段、RLS 和 migration 仅由 [Schema Catalog](../data/schema-catalog.md#身份与账户业务对象)定义。Suitability 只能消费此 Interface 返回的同账户 complete snapshot，不能读取默认值、表存在或页面草稿推断偏好。

### 消费

| ID | Owner | 使用目的 | 调用方依赖的结果与失败语义 |
| --- | --- | --- | --- |
| `SHELL-001` | Application Shell | 进入账户、请求房产档案/本人隐患/预案管理、提交退出并保留来源/返回语境 | 仅 opened scope 接受；目标不可用、过期或输入不完整时 Shell 返回 `rejected(reason)`，Account 保留原因而不伪装为资料失败。退出结果仍由 Shell、Auth 和 Privacy 协调。 |
| `AUTH-001` | Authentication & Session | 呈现当前账户真实邮箱及真实确认状态 | 认证事实不可得时显示明确 unknown/unavailable；Account 不读取 `auth.users` 或 `profiles`。 |
| `PRIVACY-001` | Account Privacy | 限定账户组合和偏好读写的 scope，处理关闭 | 未 opened、关闭中、identity mismatch 或关闭失败时不可读写/发布；旧账户状态不进入新账户。 |
| `COST-002` | Cost of Living & Budget | 显示 current 预案摘要或无 current，并提交进入预案管理的意图 | 摘要字段、版本、无 current、permission 和 retryable failure 均严格按 [Cost 的 `COST-002` 契约](cost-of-living-and-budget.md#提供)呈现；Account 不创建默认预案或修改 current。 |

## 4. 用户可观察行为与跨模块流程

| 入口或用户动作 | 成功结果 | 空、不可用或失败结果 | 必须保持的可访问性 / 安全语义 |
| --- | --- | --- | --- |
| 打开账户中心 | 组合真实邮箱、验证状态、已配置偏好或设置入口、current 预案摘要和业务入口 | 任一来源不可用时其他独立内容可保留；未知验证、未配置偏好、无 current 和失败分别说明 | 不显示固定姓名/邮箱/验证徽章或演示统计；状态、错误和操作不只依赖颜色。 |
| 首次确认五项偏好 | 全部有效值经远端成功保存后显示已配置快照，并使同账户 Suitability 请求失效 | 表单可用预填 `5`，但在成功确认前明确为未配置；验证、权限、冲突或网络失败保留最后已保存事实，不发布变化 | 五项有名称、当前值、范围和低/中/高文字说明；可通过辅助技术逐项操作并理解一次确认结果。 |
| 修改已配置偏好或跨设备恢复 | 成功修改发布新版本；另一设备/重启按远端 complete snapshot 恢复 | `configured_at` 为 null 的旧行仍为未配置；读取或保存失败不使用草稿/旧账户值冒充已保存快照 | 不猜测旧默认行曾获确认；换号后仅显示新账户远端状态。 |
| 查看当前评估预案并进入管理 | 显示 Cost 所给 current 的名称、额外生活开销（RM/月）、住房、交通、月净收入、家庭月度总收入及缺失值，或清晰的无 current；accepted 后进入预算 Owner 的管理任务并能返回账户 | Cost unavailable 或 Shell rejected 时保留原因与重试/返回路径 | 摘要不是 Account 的副本；两种收入的用途与缺失状态分开说明，不把无 current 自动替换为其他预案，且严格使用 Cost 所定义的字段术语。 |
| 进入房产档案或本人隐患报告 | Shell accepted 后进入目标 Feature，返回账户任务语境 | 目标尚未组合、范围变化或目的地不适用时 rejected；不读取/展示目标数据 | 房产与隐患的数据、权限、加载及空态由各 Owner 呈现；入口有可访问名称。 |
| 请求退出并确认 | 向 Shell 提交退出意图；完成后由 Shell/`AUTH-001`/`PRIVACY-001` 回到登录入口 | 取消保持当前账户；任一阶段失败进入无私有内容的清理恢复态 | Account Center 不声明退出成功，也不结束其他设备会话；关闭起旧账户组合不可再见。 |

跨 Owner 完成条件：Account 只在同账户 `PRIVACY-001 opened` 中组合资料和写偏好。偏好或 current 的成功版本变化交由 Shell 使相关 Suitability 请求失效；任何晚到的旧账户读取、写入成功或导航意图均不得发布、显示或进入新账户。

## 5. 数据与确定性业务规则

| 目的 | 权威对象或事实源 | 访问 / 应用边界 | 必须保持的语义 |
| --- | --- | --- | --- |
| 真实身份资料 | `AUTH-001`；[认证设计](authentication-and-session.md#3-对外协调契约) | Account 只消费 Auth 当前账户的邮箱与确认事实 | Account 不直读 `auth.users` 或 `profiles`，也不从其他资料推导邮箱/验证。 |
| 评估偏好与完成语义 | `user_assessment_preferences`；[评估偏好领域对象](../../knowledge_base/locatemy_product/domain_objects.md#assessment-preferences-评估偏好) | Supabase 是跨设备权威；字段、RLS 与 migration 只见 Schema Catalog | null `configured_at` 意味未配置；默认 `5` 只可预填。完整确认成功才产生 complete snapshot；后续成功修改保持 configured。 |
| 当前评估预案 | `COST-002`；[预算预案领域对象](../../knowledge_base/locatemy_product/domain_objects.md#budget-scenario-预算预案) | Account 不直读或写 `user_budget_scenarios` | 只显示 Cost 的 `COST-002` 已冻结 current/no-current 摘要及状态；管理与 current 变化归 Cost。 |
| 本机私有状态 | `PRIVACY-001`；[数据所有权](../system/data-ownership.md#privacy-barrier-参与者清单) | Account 只清理自己的偏好内存/副本和组合状态 | 远端偏好不因退出删除；语言不属于该关闭 payload。 |

## 6. 验收与 Ready Gate

| Capability | 验收情景 | 用户操作 | 可观察结果 |
| --- | --- | --- | --- |
| `ACCOUNT-01` / `AT-AUTH-02`、`AT-SWITCH-01` | 已验证、未验证、验证未知及 Auth 读取失败 | 打开账户中心 | 仅显示真实邮箱和 Auth 确认事实；未知有明确状态，不显示固定 verified。 |
| `ACCOUNT-02` / `AT-HAZARD-01`、`AT-PROP-01` | 房产/本人隐患目标可用、未组合、被门控拒绝及返回 | 选择两个业务入口 | accepted 时交给目标 Owner 并可返回；rejected 保留原因，不显示目标 fixture 或泄露数据。 |
| `ACCOUNT-08` / `AT-SUIT-01`–`AT-SUIT-03`、`AT-SUIT-06` | 新账户、首次完整五项确认、任一无效值、远端写失败、已配置后修改、旧默认行、跨设备恢复与两账户切换 | 查看、确认或修改偏好 | 未配置不输入 Suitability；成功完整确认才发布跨设备 complete snapshot；失败不发布；旧行保持未配置；A 的状态不进入 B。 |
| `ACCOUNT-09` 入口 / `AT-SUIT-02`、`AT-SUIT-04`、`AT-SUIT-06` | current、无 current、摘要字段缺失、Cost unavailable 与 Shell rejected | 查看预案行并进入管理 | 精确呈现 Cost 提供的名称、额外生活开销、住房、交通、月净收入、家庭月度总收入及缺失；月净收入只用于预算压力，家庭月度总收入只用于 Socio 收入位置；无 current 仍有管理入口；拒绝/不可用保留原因且不创建/选择预案。 |
| `ACCOUNT-07` 入口 / `AT-OUT-01`、`AT-OUT-02`、`AT-SWITCH-01` | 确认、取消、Auth 会话结束失败、Privacy 关闭失败和 Shell 协调失败 | 请求退出 | 取消保持当前账户；确认后 Account 不再显示私有组合；只有 Shell 协调 Auth 与 Privacy 全部成功才到登录，任一失败显示无私有内容的恢复态。 |
| `ACCOUNT-01`–`08` / 上述 `AT-*` | 中文/English、屏幕阅读器、键盘/替代输入、200% 字体、长邮箱和错误状态 | 浏览账户页并完成主要动作 | 同一功能和状态有完整文字、可访问名称和可理解顺序；长内容不遮挡主要操作，信息不只由颜色或图标传达。 |

- [x] `ACCOUNT-01`、`ACCOUNT-02`、`ACCOUNT-08` 具有唯一 Owner、Interface、事实源与验收情景；已排除入口不重新引入。
- [x] Auth、退出、预算预案、ICI 权重、语言和目标数据仍属于原 Owner。
- [x] `configured_at` 的完整语义、既有行处理和迁移方向已由项目负责人 Q13 固定，并在知识库、Schema Catalog、数据所有权和风险记录同步。
- [x] `RISK-PREF-01` 的独立 Standards/Spec 双轴审查及 migration 方向复核已完成。
- [x] Q18 的 current 预案摘要字段与 Cost/Socio 影响已完成独立 Standards/Spec 双轴规格与边界复审；家庭月度总收入和月净收入分别显示缺失且不可互相替代。
- [x] 独立 Standards/Spec 双轴审查发现已关闭，且 Q18 影响复审已通过。
- [x] 阻塞问题已关闭；设计 AI 已依 ADR 0013 批准 `Ready for Development`。

## 7. Change Log

| 日期 | 状态 | 变更原因 | 受影响的 Capability / Interface / 数据对象 / Feature | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Draft` | Issue #17 建立 Account Center owning design，冻结真实资料、偏好、预案摘要和账户意图的协调边界 | `ACCOUNT-01`、`ACCOUNT-02`、`ACCOUNT-08`、`ACCOUNT-001`、D35–D38、D41 | 待审查 |
| 2026-09-14 | `Draft` | 项目负责人 Q13 决定以 nullable `configured_at` 区分默认预填与完整确认；旧记录保持未配置 | `ACCOUNT-08`、`ACCOUNT-001`、`user_assessment_preferences`、`RISK-PREF-01`、Suitability | 项目负责人 |
| 2026-09-14 | `Draft` | 双轴审查修复：账户入口只经 Shell 导航；Suitability 只消费 `ACCOUNT-001`；预案摘要回指 Cost 的已冻结字段 | `ACCOUNT-001`、`COST-002`、`SHELL-001`、`ACCOUNT-02`、`ACCOUNT-08`、D35–D38、D41 | 待复审 |
| 2026-09-14 | `Draft` | 标准审查移除 Account 对认证底表的错误读取路径，真实身份资料只来自 `AUTH-001` | `ACCOUNT-01`、`AUTH-001`、`auth.users`、`profiles`、D36 | 待复审 |
| 2026-09-14 | `Ready for Development` | 独立 Standards/Spec 双轴复审关闭全部发现；依 [ADR 0013](../../adr/0013-autonomous-design-ai-ready-approval.md) 批准 Ready | `ACCOUNT-01`、`ACCOUNT-02`、`ACCOUNT-08`、`ACCOUNT-001`、D35–D38、D41 | 设计 AI（项目负责人授权） |
| 2026-09-14 | `Draft` | 项目负责人 Q18 批准 current 摘要新增家庭月度总收入；它与月净收入分别服务 Socio 收入位置和预算压力，等待影响复审 | `ACCOUNT-09`、`COST-002`、`user_budget_scenarios`、Socio-economic | 项目负责人 |
| 2026-09-14 | `Ready for Development` | Q18 current 摘要与 Cost/Socio 边界的独立 Standards/Spec 双轴影响复审通过；恢复 Ready，migration 与旧资料处理仍为实现 Gate | `ACCOUNT-09`、`COST-002`、`ACCOUNT-001`、`user_budget_scenarios`、Socio-economic | 设计 AI（项目负责人授权） |
| 2026-09-14 | `Ready for Development` | 全面设计审查补齐正文 Ready Gate、canonical 验收追踪、表格与 Auth 锚点；不改变可观察契约 | `ACCOUNT-01`、`ACCOUNT-02`、`ACCOUNT-07`–`09`、`ACCOUNT-001`、`AT-*` | 项目负责人（本次审查） |
