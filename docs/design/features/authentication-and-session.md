# Authentication & Session

> 状态：`Ready for Development`
> Owner：`待项目负责人分配`
> 系统基线：`5d11769`
> 依赖波次：`1`
> 最后更新：`2026-09-14`
> Prototype 视觉参考：`origin/Prototype` 的登录、注册与账户页布局；固定验证徽章和演示跳转不复用

本文件协调 Authentication & Session 与其消费者。认证模块的内部文件、SDK 映射、状态管理、运行时策略和测试组织均由其 Owner 决定；消费者只依赖本文件的 `AUTH-001` 可观察契约。

## 1. 用户成果与范围

- 已注册用户可以用邮箱和密码在当前设备建立会话；新用户明确知道是已建立会话还是需要验证邮箱。
- 账户页只呈现真实的邮箱确认事实；退出只结束当前设备会话，并触发后续本机账户数据隔离。
- 包含：`AUTH-01`、`AUTH-02`、`AUTH-03`、`ACCOUNT-07`。
- 不包含：Magic Link、游客、忘记密码、主应用路由、账户业务资料、隐私清理 payload、其他设备会话与固定 “Verified User” 文案。
- 产品事实源：[认证](../../knowledge_base/locatemy_product/features/authentication.md)、[账户](../../knowledge_base/locatemy_product/features/account.md)、[协作](../../knowledge_base/locatemy_product/cross_feature_collaboration.md)。

## 2. 依赖、责任与文件边界

| 模块 / 文件边界 | Owner | 负责 | 不负责 | 与其他模块的沟通 |
| --- | --- | --- | --- | --- |
| `lib/features/authentication_session/` | Authentication & Session | 邮箱密码认证、当前设备会话事实、真实确认状态、可选注册资料登记 | 导航、其他账户数据清理、其他设备会话 | 提供 `AUTH-001`；封装 Supabase Auth 与 `profiles` 访问 |
| `lib/app/` 与 `lib/main.dart` | Application Shell | 认证门控、登录/注册入口、组合与导航 | 认证规则和 SDK 访问 | 消费 `AUTH-001`；在认证事实允许时协调 `PRIVACY-001` |
| `supabase/migrations/`（仅必要时） | 项目负责人 / 学生实现者 | 已批准的 `profiles` 一致性或 RLS 改动 | 定义认证模块内部结构 | 必须保持 Schema Catalog 中的 owner-only 边界 |

认证模块可在其目录内自行增补、合并或拆分文件；不得改变 `AUTH-001` 的可观察语义。

| 依赖或问题 | 影响 | 验证方式 / 最迟解决点 |
| --- | --- | --- |
| Supabase Auth | 建立、恢复及结束当前设备会话；提供真实确认状态 | 认证模块封装 SDK；[`RISK-SESSION-01`](../system/risks-and-decisions.md#risk-session-01-关闭证据) 已用项目锁定版本确认冷启动、token 过期、离线与远端拒绝的会话语义；依赖版本改变时重新打开 Gate |
| `profiles` | 可选用户名等注册资料 | 访问规则和字段定义见 [Schema Catalog](../data/schema-catalog.md#身份与账户业务对象)；资料写入异常不得改变认证事实 |

## 3. 对外协调契约

### 提供：`AUTH-001` Authentication Session

| 消费者 | 动作与可观察事实 | 输入、结果与失败语义 | 权限与副作用边界 |
| --- | --- | --- | --- |
| Application Shell；Account Privacy；Account Center | 恢复当前设备会话；提交邮箱密码登录或注册；读取或订阅当前身份事实；结束当前设备会话 | 认证事实为账户引用、Auth 返回的真实邮箱及真实确认状态；结果区分已认证、未认证、需要验证、可恢复失败与不可恢复失败。注册资料尚未完成不能否定已经成立的认证事实。 | 匿名用户可恢复、登录和注册；资料与退出只能作用于当前会话。凭据、token、SDK payload 和内部异常不越过边界；退出不影响其他设备或远端业务记录。 |

`AUTH-001` 的消费者必须把确认状态不可得视为不可得，而非已验证或未验证。账户引用是不可变 Auth 身份；`profiles` 不能成为邮箱或确认状态的来源。

### 消费

| ID / Owner（Adapter 对端） | 使用目的 | 调用方依赖的结果与失败语义 |
| --- | --- | --- |
| `AUTH-002` / Authentication & Session（Supabase Auth） | 建立、恢复、结束会话并取得真实确认资料 | SDK 细节由认证模块封装；只有明确有效的会话可成为已认证事实。 |

## 4. 用户可观察行为与跨模块流程

| 入口或用户动作 | 成功结果 | 空、不可用或失败结果 | 必须保持的可访问性 / 安全语义 |
| --- | --- | --- | --- |
| 冷启动或显式恢复 | 已认证时向 Shell 提供当前身份事实；未认证时显示认证入口 | 会话不可确认时保持无私有内容并提供恢复路径 | 不以缓存或推测显示已登录；不可用不等于未验证。 |
| 登录 | 建立当前设备会话，Shell 可据事实继续门控流程 | 显示可理解的凭据或可恢复/不可恢复失败结果 | 密码只用于本次输入，不能被记录、持久化或传给其他模块。 |
| 注册 | 明确显示已建立会话；需要验证时进入查收验证邮件状态；可选资料登记可在认证后完成 | 不把注册资料失败表述为认证失败；需要验证时不显示为已验证 | 注册字段、密码确认和错误说明可访问，且不只依赖颜色。 |
| 查看账户确认状态 | 呈现 Auth 的真实确认事实 | 不可得时明确说明，而不呈现验证徽章 | `profiles` 的资料不改变确认状态。 |
| 退出或换号 | 用户确认退出后，当前设备会话结束；Shell 协调关闭旧账户 scope 并回到登录页 | 用户取消则保持当前会话；任一执行方未完成时保持无私有内容并提供恢复路径 | 不复用旧账户的私有呈现；不影响其他设备会话。 |

退出与换号由 Shell 协调：它先阻断旧账户私有入口，认证模块结束当前设备会话，Account Privacy 关闭旧 scope。任一步未完成都不能开放新账户私有内容。

## 5. 数据与确定性业务规则

| 目的 | 权威对象或事实源 | 访问 / 应用边界 | 必须保持的语义 |
| --- | --- | --- | --- |
| 身份与确认事实 | `auth.users`；[认证产品事实](../../knowledge_base/locatemy_product/features/authentication.md) | 仅通过 Supabase Auth 获取当前设备身份和真实确认资料 | 不复制凭据；真实邮箱与确认状态不从 `profiles` 推导。 |
| 可选注册资料 | `profiles`，[Schema Catalog](../data/schema-catalog.md#身份与账户业务对象) | 只登记当前认证账户的资料；具体字段与 RLS 仅见 Catalog | 资料失败可恢复，且不能回滚或伪造认证结果。 |
| 邮箱、密码与注册字段规则 | [认证产品事实](../../knowledge_base/locatemy_product/features/authentication.md) 与 Schema Catalog | 实现者负责具体校验方式 | 用户必须获得可理解的字段或提交失败结果；密码不得记录或持久化。 |

本 Feature 没有自定义指数或公式。

## 6. 验收与 Ready Gate

| Capability | 验收情景 | 用户操作 | 可观察结果 |
| --- | --- | --- | --- |
| `AUTH-01` | 当前设备无会话、有有效会话、凭据错误和会话不可用 | 启动或登录 | 认证入口、真实身份事实或可理解的失败恢复路径；不泄露凭据。 |
| `AUTH-02` | 注册后有会话、需要邮箱验证及资料登记失败 | 注册 | 明确区分认证结果和资料状态；需要验证时进入查收验证邮件状态；不显示虚假的验证状态。 |
| `AUTH-03` | 真实确认状态改变或暂时不可得 | 打开账户资料或恢复会话 | 仅据 Auth 呈现确认状态；未知有明确语义。 |
| `ACCOUNT-07` | 取消退出、当前设备退出、退出或本机清理失败、随后登录另一账户 | 确认退出并换号 | 取消时保持当前会话；成功时回到登录页且不影响其他设备；任一阶段失败时不显示旧账户或新账户私有内容。 |

- [x] `RISK-SESSION-01` 版本锁定证据已确认，且不与本契约冲突。
- [x] `AUTH-001`、`PRIVACY-001` 和 Shell 的责任、结果语义及账户边界一致。
- [x] `auth.users` 和 `profiles` 的访问遵从 Schema Catalog。
- [x] 验收情景覆盖认证、验证、资料失败、退出与换号的可观察结果。
- [x] 独立标准/规格审查发现已关闭。
- [x] 项目负责人已于 2026-09-14 批准 `Ready for Development`。

## 7. Change Log

| 日期 | 状态 | 变更原因 | 受影响的 Capability / Interface / 数据对象 / Feature | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-13 | `Under Review` | 选择 Wave 1 pilot | `AUTH-01`–`03`、`ACCOUNT-07`、`AUTH-001`、`auth.users`、`profiles` | 项目负责人 |
| 2026-09-14 | `Under Review` | 采用高层协调设计：移除内部实现预设，保留可观察契约、不变量和受控边界 | `AUTH-001`、`AUTH-002`、`PRIVACY-001`、`profiles` | 项目负责人 |
| 2026-09-14 | `Under Review` | 关闭版本锁定会话风险与独立审查发现；提交 Ready 决定 | `AUTH-01`–`03`、`ACCOUNT-07`、`AUTH-001`、`AUTH-002`、`RISK-SESSION-01` | 待项目负责人批准 |
| 2026-09-14 | `Ready for Development` | 项目负责人确认全部 Ready Gate 与独立审查处置 | `AUTH-01`–`03`、`ACCOUNT-07`、`AUTH-001`、`AUTH-002` | 项目负责人 |
