# Authentication & Session 开发协作契约

> 状态：`Ready for Development`（2026-09-14；设计 AI〔项目负责人授权〕，ADR 0013）<br>
> Owner：`A`；系统基线：`Baselined — 5d11769`；依赖波次：Wave 1<br>
> 实现：`Implemented`（2026-09-16；[Wave 1 验收证据](../../human/authentication-session-wave1-acceptance-2026-09-16.md)）；联合集成按第 5.1 节后续执行<br>
> 唯一公开入口：`package:locatemy/features/authentication_session/authentication_session.dart`<br>
> 定义完成：消费者可仅凭本文件的公开 seam 区分真实会话、确认状态和失败，并安全完成登录、退出和换号协作。

本文件是 Authentication & Session 唯一的跨 Owner 开发协作契约，也是人类阅读 HTML 的 Markdown 源。它固定公开 Dart 声明、结果语义、数据边界和联合验收；`lib/features/authentication_session/` 内的 Widget、状态管理、Supabase SDK 映射、重试、私有文件和测试组织由 Owner 决定。

## 0. 固定阅读顺序与四项 Readiness

实施者和审查者按以下顺序读取；后项只补充前项已固定的事实，不能改写其权威语义：

1. [产品认证事实](../../knowledge_base/locatemy_product/features/authentication.md)与[账户事实](../../knowledge_base/locatemy_product/features/account.md)；
2. [Feature map](../system/feature-map.md#authentication--session)、[Interface 注册表](../system/interfaces.md)、[FLOW-01](../system/flows.md#flow-01启动注册登录退出与账户切换)；
3. [Capability Traceability](../system/capability-traceability.md)、[数据所有权](../system/data-ownership.md)、[Schema Catalog](../data/schema-catalog.md#身份与账户业务对象)和[风险登记](../system/risks-and-decisions.md#risk-session-01-关闭证据)；
4. 本契约及其同名 HTML 导出；它们是同一内容的两种阅读形式。

| Readiness | 本 Feature 的可核查证据 | 结论 |
| --- | --- | --- |
| 责任与范围 | `AUTH-01`、`AUTH-02`、`AUTH-03`、`ACCOUNT-07` 唯一归属 A；门控、隐私清理和账户页分别仍归其 Owner | 已就绪 |
| 契约与消费者 | `AUTH-001` 的一个公开入口、声明、失败语义、调用顺序和 fake 场景均在第 3 节；消费者为 Shell、Privacy、Account Center | 已就绪 |
| 数据与安全 | `auth.users` 和 `profiles` 的访问及权限只引用 Schema Catalog；无 token、密码或 profile 字段泄漏至公开 seam | 已就绪 |
| 验收与风险 | 第 5 节覆盖 canonical `AT-*`；`RISK-SESSION-01` 已关闭，依赖版本改变时重新打开 | 已就绪 |

## 1. 任务成果、责任与依赖

- 用户可用邮箱密码登录当前设备；失败有可理解的修正或重试路径。
- 用户可注册；界面明确区分已建立会话、须查收验证邮件和未建立会话的失败；资料登记失败不否定认证结果。
- 账户页只依据 Auth 的真实邮箱与确认状态呈现；未知不显示“已验证”。
- 退出只结束当前设备会话；换号时先屏蔽和清理旧账户私有内容，不影响其他设备或远端业务记录。

| Owner | 负责 | 不负责 | 依赖 |
| --- | --- | --- | --- |
| Authentication & Session（A） | 邮箱密码认证、当前设备会话、真实邮箱/确认事实、可选注册资料、唯一公开入口 | 主应用门控/导航、私有 payload 清理、账户业务页面、其他设备会话 | 封装 Supabase Auth 和直接的 `profiles` 访问 |
| Application Shell | 认证门控、认证入口组合、退出/换号编排和私有 UI 屏障 | Auth SDK 与认证规则 | 消费 `AUTH-001`；认证后调用 `PRIVACY-001.open` |
| Account Privacy | account scope 的 opened/closed 与本机清理 | 认证与导航 | 消费 `AUTH-001` 的 account id；仅 Shell 发起 |
| Account Center | 呈现真实邮箱/确认状态及退出意图 | 直读 Auth 或 `profiles` | 消费 `AUTH-001`；退出交 Shell |

包含登录、注册、真实邮箱确认、会话恢复/结束、可选注册资料及 `ACCOUNT-07` 的认证一侧。不包含 Magic Link、游客、忘记密码、固定 Verified User 文案和 Account Privacy 的清理实现。产品事实见[认证](../../knowledge_base/locatemy_product/features/authentication.md)、[账户](../../knowledge_base/locatemy_product/features/account.md)；系统流程见[FLOW-01](../system/flows.md#flow-01启动注册登录退出与账户切换)。

## 2. 需要调用的 Interface

### Interface 卡：Supabase Auth seam（`AUTH-002`，仅 A）

| 卡项 | 固定内容 |
| --- | --- |
| 提供者 / 消费者 | Authentication & Session（A）/ Authentication & Session（A）；这是外部来源 seam，不向其他 Owner 暴露 SDK。 |
| 目的 | 将 Supabase Auth 的当前设备会话、真实邮箱和邮箱确认事实收敛为 `AUTH-001`。 |
| 输入 / 成功 | 邮箱密码动作或当前设备恢复；只有明确有效或成功恢复的会话才成为认证事实。 |
| 失败 / 恢复 | 过期缓存、刷新中、刷新失败、离线无法确认和远端拒绝均不打开私有 scope；映射为 `AUTH-001` 的类型化失败，用户按其恢复路径操作。 |
| 权限 / 副作用 | A 是唯一直接调用 Auth 与直接写 `profiles` 的 Owner；SDK 方法、token、刷新、取消、重试和错误映射都是 A 的内部实现。 |

| 直接访问对象 | 用途与不可变规则 |
| --- | --- |
| `auth.users` | 提供 account id、真实 email、email confirmed state 与当前设备会话。凭据/token 不复制到 public，且不由 `profiles` 推断邮箱或确认状态。 |
| `profiles` | 仅认证后写可选 username/avatar/bio；`id` 等于当前 Auth account id，owner-only CRUD。失败返回资料结果，不撤销或伪造认证结果。 |

字段、RLS 与迁移唯一权威为[Schema Catalog](../data/schema-catalog.md#身份与账户业务对象)。

## 3. 必须提供的 Interface

### Interface 卡：当前设备会话（`AUTH-001`）

**提供者：** Authentication & Session（A）<br>
**消费者：** Application Shell、Account Privacy、Account Center<br>
**唯一公开 import：** `package:locatemy/features/authentication_session/authentication_session.dart`

| 卡项 | 固定内容 |
| --- | --- |
| 目的 | 为消费者提供当前设备会话、不可伪造的 account id、真实邮箱及确认状态，并承载登录、注册和当前设备退出的类型化结果。 |
| 输入 | `restoreSession`、`watchSession`、邮箱密码登录、注册字段、退出意图；各调用的字段约束见“输入”表。 |
| 成功结果 | 明确 authenticated 的账户、明确无会话、注册后的 authenticated 或 verification-required，以及成功结束当前设备会话。 |
| 失败与恢复 | 失败由第 3 节 enums 区分修正、重试、升级或停在门控；消费者不解析字符串，也不从旧 snapshot、profile 或缓存推断授权。 |
| 权限与副作用 | 本 Interface 不导航、不打开/关闭 privacy scope、不清理其他 Owner 数据；`signOut` 只结束本设备会话，不删远端业务记录或其他设备会话。 |
| 次序与账户隔离 | Shell 以同一 account id 调用 `PRIVACY-001.open`，仅 `opened` 后可显示私有内容；退出/换号的屏蔽、Auth、close 顺序固定于“副作用、权限与调用次序”。 |

消费者只能 import 此入口，不得 import `lib/features/authentication_session/src/`。提供方应先提交下列**声明**及最小公共类型；函数体可由 AI 或 Owner 编写。

```dart
abstract interface class AuthenticationSession {
  Future<SessionSnapshot> restoreSession();
  Stream<SessionSnapshot> watchSession();
  Future<SignInOutcome> signIn({
    required String email, required String password,
  });
  Future<RegistrationOutcome> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    String? username,
  });
  Future<SignOutOutcome> signOut();
}

sealed class SessionSnapshot {
  const SessionSnapshot();
}
final class AuthenticatedSession extends SessionSnapshot {
  final AuthenticatedAccount account;
  const AuthenticatedSession(this.account);
}
final class UnauthenticatedSession extends SessionSnapshot {
  const UnauthenticatedSession();
}
final class SessionUnavailable extends SessionSnapshot {
  final SessionFailure failure;
  const SessionUnavailable(this.failure);
}

final class AuthenticatedAccount {
  final String accountId;
  final String email;
  final EmailConfirmation confirmation;
  const AuthenticatedAccount({
    required this.accountId,
    required this.email,
    required this.confirmation,
  });
}
enum EmailConfirmation { confirmed, verificationRequired, unavailable }

sealed class SignInOutcome {
  const SignInOutcome();
}
final class SignInSucceeded extends SignInOutcome {
  final AuthenticatedAccount account;
  const SignInSucceeded(this.account);
}
final class SignInRejected extends SignInOutcome {
  final SignInFailure failure;
  const SignInRejected(this.failure);
}

sealed class RegistrationOutcome {
  const RegistrationOutcome();
}
final class RegistrationAuthenticated extends RegistrationOutcome {
  final AuthenticatedAccount account;
  final ProfileRegistrationOutcome profile;
  const RegistrationAuthenticated(this.account, this.profile);
}
final class RegistrationVerificationRequired extends RegistrationOutcome {
  final String email;
  final ProfileRegistrationOutcome profile;
  const RegistrationVerificationRequired(this.email, this.profile);
}
final class RegistrationRejected extends RegistrationOutcome {
  final RegistrationFailure failure;
  const RegistrationRejected(this.failure);
}

sealed class ProfileRegistrationOutcome {
  const ProfileRegistrationOutcome();
}
final class ProfileRegistered extends ProfileRegistrationOutcome {
  const ProfileRegistered();
}
final class ProfileRegistrationSkipped extends ProfileRegistrationOutcome {
  const ProfileRegistrationSkipped();
}
final class ProfileRegistrationFailed extends ProfileRegistrationOutcome {
  final ProfileFailure failure;
  const ProfileRegistrationFailed(this.failure);
}

sealed class SignOutOutcome {
  const SignOutOutcome();
}
final class SignOutSucceeded extends SignOutOutcome {
  const SignOutSucceeded();
}
final class SignOutRejected extends SignOutOutcome {
  final SignOutFailure failure;
  const SignOutRejected(this.failure);
}

enum SessionFailure { retryableUnavailable, unsupportedClient, remoteRejected }
enum SignInFailure { invalidInput, invalidCredentials, retryableUnavailable, unsupportedClient }
enum RegistrationFailure { invalidInput, accountAlreadyExists, retryableUnavailable, unsupportedClient }
enum ProfileFailure { retryableUnavailable, permissionDenied, unknown }
enum SignOutFailure { retryableUnavailable, remoteRejected, unsupportedClient }
```

这规定协作形状，不规定 sealed-class 的内部文件组织、SDK enum 或错误文案。新增公共成员/结果变体须按第 7 节协商。

#### 输入

| 调用 | 输入与约束 | 调用者责任 |
| --- | --- | --- |
| `restoreSession` / `watchSession` | 无 | Shell 只在认证门控未打开私有路由时调用；每个 snapshot 都重新决定是否可开 scope。 |
| `signIn` | 非空 `email`、`password` | 密码仅本次表单/调用存在；不得记录、持久化或传给其他 Owner。 |
| `register` | 非空 `email`、`password`、`passwordConfirmation`；可空 `username` | confirmation 必须等于 password 才提交；无 username 表示跳过资料。密码强度与文案由 A 在产品事实范围内决定。 |
| `signOut` | 无 | 仅 Shell 在旧私有 UI 已屏蔽后调用；Account Center 不直接调用。 |

#### 输出、失败与处理

| 结果 | 意义 | 消费者必须处理 |
| --- | --- | --- |
| `AuthenticatedSession`、`SignInSucceeded`、`RegistrationAuthenticated` | 当前设备有明确有效会话；account 是不可变 Auth 身份和真实邮箱事实 | Shell 以同一 accountId 调 `PRIVACY-001.open`，仅 `opened` 后建私有 UI；Account Center 使用 confirmation。 |
| `UnauthenticatedSession` | 明确没有可用会话 | 显示认证入口，不显示私有 UI。 |
| `SessionUnavailable` | 无法安全确认会话；failure 区分可重试网络、客户端不支持、远端拒绝 | 停在门控并给恢复路径；不得降级为未认证或开放私有 UI。 |
| `RegistrationVerificationRequired` | 注册须查收验证邮件；email 是注册目标邮箱 | 呈现查收邮件状态，不声称已验证；若后来有明确 session，仍以 SessionSnapshot 开 scope。 |
| `confirmed` / `verificationRequired` / `unavailable` | Auth 确认、明确待验证、或无法给出确认事实 | 分别呈现已验证、待验证、状态不可得；未知不可猜测。 |
| 任一 `*Rejected` | 本次动作没有对应成功语义 | 使用 enum 区分修正、重试或升级；不解析错误字符串，不建立 scope。 |
| `ProfileRegistrationFailed` | 认证/验证结果仍有效，只有资料未登记 | 显示资料可重试，绝不说成登录/注册失败。 |

`watchSession` 的首个和后续 snapshot 语义一致；过去 authenticated 值不能授权继续显示私有内容。

#### 副作用、权限与调用次序

- `accountId` 唯一来自 Auth；公开类型不暴露密码、token、SDK payload 或 `profiles` 字段。
- 登录/注册/恢复只报告认证事实，不导航、不打开 scope、不清理别的模块数据。
- `signOut` 只结束**当前设备**会话；不会删除远端业务记录或结束其他设备会话。
- Shell 的退出/换号固定顺序：屏蔽旧私有 UI 和新业务意图 → `signOut` → `PRIVACY-001.close(oldAccountId)` → 两者成功后才显示普通登录入口。任一步失败仍无私有内容且可恢复。
- 已打开 scope 的 account id 与 `AuthenticatedSession` 不一致时，Shell 不为任何账户显示私有内容；按 FLOW-01 关闭旧范围后重新认证。

#### 最小调用示例（Shell）

```dart
final snapshot = await authenticationSession.restoreSession();
switch (snapshot) {
  case AuthenticatedSession(:final account):
    // 以 account.accountId 调用 PRIVACY-001.open；仅 opened 后进入主应用。
  case UnauthenticatedSession():
    // 显示登录/注册入口。
  case SessionUnavailable(:final failure):
    // 保持门控，按 failure 提供恢复路径。
}
```

这是 seam 用法说明，不是可提交的 Shell 实现。

#### Fake Adapter 场景

Shell 用 fake `AuthenticationSession` 分别返回 `AuthenticatedSession(account A)`、`UnauthenticatedSession`、`SessionUnavailable(retryableUnavailable)`，验证仅在 A 的 `PRIVACY-001.open` 返回 opened 后建立私有 UI。Account Center 用同一 fake 的三种 `EmailConfirmation`，验证 unavailable 不会被呈现为 verified。二者无需 Supabase 或 A 的生产实现。

## 4. 协作交付顺序

1. **A：先合入公开 seam。** 创建唯一入口、上述声明及最小 fake；合入前消费者不依赖 A 内部文件。
2. **A：完成真实 Adapter 与表单。** 映射 Supabase Auth/`profiles` 到这些结果，并由 A 亲自编写真实 Adapter 契约测试。
3. **消费者：并行使用 fake。** Shell 完成门控和 FLOW-01；Account Privacy 只接收 account id；Account Center 只用 `AuthenticatedAccount`。
4. **共同联调。** 接入生产 seam，仅为第 5 节保留必要跨模块流测试。

## 5. 联合验收

| 场景 | 参与 Owner | 操作 | 可观察结果 | 追踪 |
| --- | --- | --- | --- | --- |
| 冷启动恢复会话 | A、Shell、Privacy | 无会话、有效 A、不可确认会话 | 分别为认证入口、仅 scope opened 后主应用、无私有内容的恢复门控 | `AUTH-01`；`AT-AUTH-01` |
| 登录凭据或网络失败 | A、Shell | 非法/错误凭据、网络不可用、客户端不支持 | 可区分失败和恢复路径；无 scope；密码不泄露 | `AUTH-01`；`AT-AUTH-01`、`AT-OUT-02` |
| 注册与真实确认 | A、Shell、Account Center | authenticated、verification required、资料失败 | 认证/验证/资料状态分明；仅 Auth 确认事实可显示 verified | `AUTH-02`、`AUTH-03`；`AT-AUTH-02` |
| 当前设备退出 | A、Shell、Privacy | 确认退出；注入 Auth/清理失败 | 成功到普通登录；失败仍无私有 UI、可重试；远端/其他设备不变 | `ACCOUNT-07`；`AT-OUT-01`、`AT-OUT-02` |
| 从 A 换到 B | A、Shell、Privacy、私有 Owner | A 已打开后退出并登录 B | B scope opened 前 A 数据不可读；随后只呈现 B 数据 | `ACCOUNT-07`；`AT-SWITCH-01` |

### 5.1 Wave 1 验收分配（2026-09-16）

本期生产依赖为 Supabase Auth 与 `profiles`；确定性测试使用 SDK + HTTP mock，页面测试使用公开 `AuthenticationSession` fake。Wave 1 运行入口只呈现认证页面和真实身份状态，不建立任何私有业务 scope；Shell、Privacy 和 Account Center 为后续槽位。以下分配不修改第 3 节 Interface。

| 场景 / 当前模块子项 | 验证归属 | 依赖及用途 | 证据要求 | Owner | 最迟 Wave（本模块 / 联合） | 本模块证据 / 状态 | 联合证据 / 状态 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 冷启动恢复：无会话、有效身份、不可确认及晚到响应 | 两者 | 本期真实 Auth；测试 HTTP mock/fake；后续 Privacy/Shell | Adapter、VM、页面测试；真实恢复；设备首屏/重启 | A；联合 A（Shell/Privacy） | 1 / 3 | 已通过；[本次验收报告](../../human/authentication-session-wave1-acceptance-2026-09-16.md) | 待 Wave 3 同账户 open 门控 |
| 登录：输入、凭据、网络、客户端失败及恢复、防重复提交 | 两者 | 本期真实 Auth；测试 HTTP mock/fake；后续 Shell | 类型化失败、恢复与过期响应测试；真实登录；双语设备失败流程 | A；联合 A（Shell） | 1 / 3 | 已通过；[本次验收报告](../../human/authentication-session-wave1-acceptance-2026-09-16.md) | 待 Wave 3 无 scope 失败流程 |
| 注册：authenticated、verification-required、资料独立失败/重试及真实确认 | 两者 | 本期真实 Auth/profiles；测试 HTTP mock/fake；后续 Shell/Account Center | Adapter/VM/页面测试；真实注册/确认/资料写入；profiles owner allow、跨账户和匿名 deny | A；联合 A（Shell/Account Center） | 1 / 6 | 已通过；[本次验收报告](../../human/authentication-session-wave1-acceptance-2026-09-16.md) | Shell 门控 Wave 3；Account Center 真邮箱与三态 Wave 6 |
| 当前设备退出：local、失败阻断、重试、其他设备与远端资料保留 | 两者 | 本期真实 Auth；测试 HTTP mock/fake；后续 Shell/Privacy | local 请求测试；页面确认/取消/失败重试；真实双 session 与远端资料保留 | A；联合 A（Shell/Privacy） | 1 / 3 | 已通过；[本次验收报告](../../human/authentication-session-wave1-acceptance-2026-09-16.md) | 待 Wave 3 屏蔽 → signOut → close 联合流程 |
| A→B：当前 session 变化及晚到认证/资料反馈隔离 | 两者 | 本期真实 Auth；测试 fake；后续 Shell/Privacy/私有 Owner | 双账户真实认证；晚到操作结果不覆盖新身份；完整私有数据隔离联合验证 | A；联合 A 主责、B 参与 | 1 / 7 | 已通过；[本次验收报告](../../human/authentication-session-wave1-acceptance-2026-09-16.md) | scope 切换 Wave 3；全部私有 Owner 隔离 Wave 7 |
| 页面可访问性与双语 | 本模块 | 本期设备语言偏好；测试 fake | 360–430dp、200% 字体、首个错误焦点、屏幕阅读器字段标签；中英文认证状态与语言跨退出/重启 | A | 1 / 不适用 | 已通过；[本次验收报告](../../human/authentication-session-wave1-acceptance-2026-09-16.md) | 不适用 |

Wave 1 没有到期的跨模块联合场景；以上后续事项按表执行，不能用 fake 宣告联合通过。模块 `Implemented` 状态另按开发规范第 3 节证据判断，不由设计 Ready 状态推导。

## 6. 实现自由、阻塞项与参考

AI 或 Owner 可决定 `src/` 内的拆分、Widget、状态管理、SDK Adapter、刷新/重试/取消、局部校验和测试组织。以下情况必须暂停协商：变更唯一公开入口、公共声明/结果/次序/权限；需变更 `profiles` schema/RLS；或 Supabase 版本使 `RISK-SESSION-01` 的锁定结论失效。

当前阻塞项：无。依赖版本变化时重开 `RISK-SESSION-01`。权威参考：[Schema Catalog](../data/schema-catalog.md#身份与账户业务对象)、[Interface 注册表](../system/interfaces.md)、[会话风险](../system/risks-and-decisions.md#risk-session-01-关闭证据)。

## 7. 契约变更与完成检查

公共 Interface 变更须由提供方说明原因和受影响消费者，所有受影响消费者确认；同一 PR 更新公开声明、本契约、同名 HTML 导出和受影响 fake/Adapter 测试。Git/PR 保存历史；不使用文档版本、checksum、Manifest、Generation Gate 或 Development Release。

- [x] 四项 Readiness 在第 0 节均有可核查证据。
- [x] `AUTH-001` 和 `AUTH-002` 均有完整 Interface 卡；`AUTH-001` 只有一个公开 entry point。
- [x] 第 3 节 Dart 表达跨 Owner 的公开声明；第 8 节记录当前实现结构与证据入口。
- [x] fake 场景和联合验收覆盖恢复/门控、注册/验证、退出/清理和 A→B 换号。

## 8. MVVM 实现结构与职责

> 下列认证文件已实现。私有拆分可调整，验收以第 3 节公开 seam、第 5.1 节分配、真实代码及本次证据为准。原始 TODO 骨架已由实现入口替代，避免与当前生产状态混淆。

### 8.1 文件树（MVVM）

```text
lib/features/authentication_session/
├── authentication_session.dart
└── src/
    ├── domain/
    │   └── authentication_models.dart
    ├── application/
    │   ├── authentication_session.dart
    │   └── authentication_use_case.dart
    ├── data/
    │   └── supabase_authentication_session_adapter.dart
    └── presentation/
        ├── authentication_view_state.dart
        ├── authentication_view_model.dart
        └── authentication_page.dart

test/features/authentication_session/
├── authentication_view_model_test.dart
└── supabase_authentication_session_adapter_test.dart
```

MVVM 依赖方向为 `View → ViewModel → Application use case → Domain/Application seam ← Data Adapter`。`SupabaseClient` 只能出现在 Data Adapter；View 不直读 SDK，ViewModel 不返回 SDK payload。

### 8.2 每个代码文件的职责、Function 与 Variable

| 文件 | 职责 | Functions / constructors | Variables / fields |
| --- | --- | --- | --- |
| `authentication_session.dart` | 唯一公开 barrel；只导出 `AUTH-001` 声明和公开类型 | 无 | 无 |
| `src/domain/authentication_models.dart` | 保存第 3 节的不可变账户、session、outcome、failure 类型 | 各 `const` constructor | `accountId`、`email`、`confirmation`、`account`、`failure`、`profile` |
| `src/application/authentication_session.dart` | 声明供 use case 与消费者共用的 `AUTH-001` seam | `restoreSession`、`watchSession`、`signIn`、`register`、`signOut` | 无 |
| `src/application/authentication_use_case.dart` | 串联输入检查、调用 seam 和结果传递；不导航 | 同上 5 个用例函数 | `_session` |
| `src/data/supabase_authentication_session_adapter.dart` | 唯一调用 Supabase Auth/`profiles` 的 Adapter；把 SDK 结果和异常映射为公开类型 | 5 个 seam 函数；`_mapSession`、`_mapAccount`、`_writeOptionalProfile`及失败映射 helpers | `_client` |
| `src/presentation/authentication_view_state.dart` | 表达登录/注册页可呈现状态，不保存密码 | `initial`、`copyWith` | `mode`、`actionStatus`、`session`、`messageKey`、`fieldErrorKey` |
| `src/presentation/authentication_view_model.dart` | 接收 UI intent，调用 use case，发布页面状态，管理 session stream 订阅 | `initialize`、`showSignIn`、`showRegistration`、`signIn`、`register`、`clearFeedback`、`dispose` | `_useCase`、`_state`、`_sessionSubscription`、`state` getter |
| `src/presentation/authentication_page.dart` | 绑定控件与 ViewModel；管理表单/controller 生命周期；不直调 Supabase | `createState`、`initState`、`_submitSignIn`、`_submitRegistration`、`build`、`dispose` | `viewModel`、`_formKey`、`_emailController`、`_passwordController`、`_confirmationController`、`_usernameController` |
| `authentication_view_model_test.dart` | 用 fake seam 验证状态转换，不连 Supabase | `main` 与各 `test` callback | `fakeSession`、`useCase`、`viewModel` |
| `supabase_authentication_session_adapter_test.dart` | 验证 SDK 结果/异常到 `AUTH-001` 的映射，不使用生产账户 | `main` 与各 `test` callback | `fakeClient`、`adapter` |

### 8.3 实现与验证入口

- 生产实现：[`lib/features/authentication_session/`](../../../lib/features/authentication_session/)。公开入口只导出 `AUTH-001` 声明与领域类型。
- 启动与注入：[`lib/main.dart`](../../../lib/main.dart) → [`lib/app/app.dart`](../../../lib/app/app.dart)；本期仅运行认证与身份状态页面。私有 scope、主导航和账户业务页面按第 5.1 节后续接入。
- 确定性 Adapter 与 ViewModel 测试：[`test/features/authentication_session/`](../../../test/features/authentication_session/)；页面与双语验证见 [`test/widget_test.dart`](../../../test/widget_test.dart)、[`test/language_support_test.dart`](../../../test/language_support_test.dart)。
- 真实开发环境测试：[`test/live/authentication_session_live_test.dart`](../../../test/live/authentication_session_live_test.dart)，通过 `python3 tool/verify_authentication_live.py` 单独启用；普通测试默认跳过。secret key 仅用于创建、确认与清理本次专用账户，认证和 profiles 权限断言使用客户端 publishable key 与真实用户会话。
- 当期验收报告及设备证据：[`authentication-session-wave1-acceptance-2026-09-16.md`](../../human/authentication-session-wave1-acceptance-2026-09-16.md)。本模块状态、当前阻塞和后续联合责任分别记录。

### 8.4 Supabase 实现时必须核对的当前事实

- [`signInWithPassword`](https://supabase.com/docs/reference/dart/auth-signinwithpassword) 是 Flutter 邮箱密码登录入口。
- [`signUp`](https://supabase.com/docs/reference/dart/auth-signup) 在 Confirm email 开启时可返回 user 但 `session == null`；这是 `RegistrationVerificationRequired` 的主要映射分支。
- [`onAuthStateChange`](https://supabase.com/docs/reference/dart/auth-onauthstatechange) 会把离线刷新等网络错误作为 stream error 发出，订阅必须提供 `onError`。
- [`signOut`](https://supabase.com/docs/reference/dart/auth-signout) 在 Dart 默认是 local，但本 Feature 仍显式传 `SignOutScope.local` 来保护“只退出当前设备”的产品语义。
- 依赖升级前重新检查 [Supabase Changelog](https://supabase.com/changelog?types=breaking-change) 和 `RISK-SESSION-01`。
