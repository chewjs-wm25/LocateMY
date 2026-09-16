# Account Privacy 开发协作契约

> 状态：`Ready for Development`（2026-09-15；设计 AI〔项目负责人授权〕，ADR 0013）
> Owner：`A`；系统基线：`Baselined — 5d11769`；依赖波次：Wave 2
> 唯一公开入口：`package:locatemy/features/account_privacy/account_privacy.dart`
> 完成定义：Shell 仅凭本契约可在真实同账户认证后打开范围；退出、强制退出或换号时立即封锁旧账户，八个具名 Owner 都证明其本机私有状态已处理后才 closed。身份不符、不完整或不可用时绝不显示旧/新账户私有内容，且可恢复关闭同一旧范围。

本文件是 Account Privacy 唯一跨 Owner 开发协作契约和同名 HTML 的 Markdown 源。它冻结 `PRIVACY-001` 的公开 Dart seam：范围快照、Shell 发起的开关和八个 Owner 的 close-participant 合约。`lib/features/account_privacy/` 内的注册/注入、状态管理、SQLite/文件 Adapter、并发、取消、重试、私有文件和测试组织由 A 决定。它不拥有 Auth 会话、Shell UI、业务 payload、远端记录/Storage 删除、公共缓存或语言。

## 0. 固定阅读顺序与四项 Readiness

1. [领域词汇](../../../CONTEXT.md#本地数据库)及[账户产品事实](../../knowledge_base/locatemy_product/features/account.md)；
2. [Feature map](../system/feature-map.md#fm-privacy)、[Interface 注册表](../system/interfaces.md)、[FLOW-01](../system/flows.md#flow-01启动注册登录退出与账户切换)；
3. [Capability Traceability](../system/capability-traceability.md)、[数据所有权参与者清单](../system/data-ownership.md#privacy-barrier-参与者清单)、[Schema Catalog](../data/schema-catalog.md)及[privacy 风险](../system/risks-and-decisions.md#风险与关闭条件)；
4. 本契约及同名 HTML；后项不能改写前项。

| Readiness | 可核查证据 | 结论 |
| --- | --- | --- |
| 责任与依赖顺序 | A 只拥有 `STATE-ACCOUNT-SCOPE`、关闭协调/证明；Auth、Shell 和八类 payload 均保留原 Owner；第 4 节固定次序 | 已就绪 |
| 契约与消费者 | 第 3 节含唯一 import、声明、Shell 调用及八项 participant 合约 | 已就绪 |
| 数据与权限 | 第 2/3 节固定同账户范围、payload 不可见和保留项；不暴露 token、字段或远端删除能力 | 已就绪 |
| 联调与验收 | 第 5 节覆盖恢复、幂等、逐 Owner 失败/重试、强制退出和 A→B，且提供 fake 场景 | 已就绪 |

## 1. 成果、责任与直接边界

- 只有 `AUTH-001` 明确认证的同一账户可为 `opened`；`closing` 从开始即不可访问，不是“仍可读的清理中”。
- Application Shell 是 lifecycle 唯一发起者；A 汇总基线固定八名 participant。participant 只处理/证明自己的旧账户分区，不能读、替代或汇总别人的 payload。
- `AUTH-001` 是 account id 唯一来源；`UnauthenticatedSession`、`SessionUnavailable`、旧快照或 cache 都不能打开范围。完整 Auth 声明见 [AUTH-001](../features/authentication-and-session.md#interface-当前设备会话auth-001)。

| 直接对象 / Owner | 本模块边界 | 保留 / 不做 |
| --- | --- | --- |
| `STATE-ACCOUNT-SCOPE` / A | 本机 opened/closing/closed 事实；`accountId` 来自 Auth，非空且非空白 | 不能从 profile/cache 推测 opened |
| 八项私有本机状态 / 各 participant | A 只接收类型化处理结果，不读 payload/字段/路径 | 未完成、未知或重复 participant 不能 closed |
| 公共缓存、语言、远端记录、其他设备会话 | 不属于 close payload | 不删除、不跨账户混入；公共缓存不得含 account ID、自由文字或用户命名 |

## 2. 需要调用的 Interface

### `AUTH-001` — 明确认证的账户事实

**提供者：** Authentication & Session；**消费者：** Account Privacy（A）。
**唯一公开 import：** `package:locatemy/features/authentication_session/authentication_session.dart`。

Privacy 只消费该入口的公开 Auth 事实，不主动调用其他 Owner 的内部接口、缓存、profile、token 或 SDK。Shell 是账户范围的唯一 lifecycle 发起者：它取得明确认证的同一账户后调用 `PRIVACY-001.open`；Privacy 不自行登录、恢复会话、导航或结束会话。

```dart
abstract interface class AuthenticationSession {
  Future<SessionSnapshot> restoreSession();
  Stream<SessionSnapshot> watchSession();
}
sealed class SessionSnapshot { const SessionSnapshot(); }
final class AuthenticatedSession extends SessionSnapshot {
  final AuthenticatedAccount account;
  const AuthenticatedSession(this.account);
}
final class UnauthenticatedSession extends SessionSnapshot { const UnauthenticatedSession(); }
final class SessionUnavailable extends SessionSnapshot {
  final SessionFailure failure;
  const SessionUnavailable(this.failure);
}
final class AuthenticatedAccount {
  final String accountId;
  final String email;
  final EmailConfirmation confirmation;
  const AuthenticatedAccount({required this.accountId, required this.email, required this.confirmation});
}
enum EmailConfirmation { confirmed, verificationRequired, unavailable }
enum SessionFailure { retryableUnavailable, unsupportedClient, remoteRejected }
```

**输入、结果、权限与顺序。** `open` 只接受当前 `AuthenticatedSession` 的非空 `accountId`；该不可变 Auth 账户是范围身份唯一来源。`UnauthenticatedSession` 与 `SessionUnavailable`（包括 retryable、unsupported、remote-rejected）都不是可打开范围的事实，必须保持无私有内容，不能降级为旧账户、profile 或缓存身份。认证事实与已 opened scope 的 account id 不同、认证变为无会话或不可确认时，Shell 按固定关闭顺序屏蔽私有内容、结束当前设备会话并关闭旧范围；Privacy 只拒绝不匹配/过期的 open 或私有访问，不能替 Shell 推断或替换账户。

```dart
final snapshot = await authenticationSession.restoreSession();
if (snapshot case AuthenticatedSession(:final account)) {
  // Shell 以同一 account 调用 privacy.open(account)；仅 opened 后建立私有应用。
}
```

**fake 场景：** fake Auth 依次给 `AuthenticatedSession(A)`、`UnauthenticatedSession`、`SessionUnavailable(retryableUnavailable)` 与 B；Shell/Privacy 验证只有 A 的成功 open 可建立 A 范围，未知或无会话不开放私有内容，A→B 前必须先关闭 A，Privacy 不读取其他来源补充身份。

## 3. 必须提供的 Interface

### `PRIVACY-001` — 账户范围与关闭参与者

**提供者：** Account Privacy（A）；**消费者：** Application Shell、Map / Location、Cost of Living & Budget、Infrastructure Coverage、Hazard Reporting、Property Inspection、Account Center。
**唯一公开 import：** `package:locatemy/features/account_privacy/account_privacy.dart`。

消费者只能 import 此入口，不得 import `lib/features/account_privacy/src/`。A 先合入以下声明及最小 fake；这是协作形状，不是函数体、注册实现、SDK/SQLite/文件调用、迁移或测试实现。

```dart
abstract interface class AccountPrivacy {
  AccountScopeSnapshot readScope();
  Future<OpenAccountScopeOutcome> open(AuthenticatedAccount account);
  Future<CloseAccountScopeOutcome> close(
    AccountScope scope, AccountScopeCloseReason reason,
  );
}
final class AccountScope { final String accountId; const AccountScope(this.accountId); }
sealed class AccountScopeSnapshot { const AccountScopeSnapshot(); }
final class AccountScopeOpened extends AccountScopeSnapshot { final AccountScope scope; const AccountScopeOpened(this.scope); }
final class AccountScopeClosing extends AccountScopeSnapshot { final AccountScope scope; const AccountScopeClosing(this.scope); }
final class AccountScopeClosed extends AccountScopeSnapshot { final AccountScope scope; const AccountScopeClosed(this.scope); }
final class AccountScopeUnavailable extends AccountScopeSnapshot { final AccountScopeFailure failure; const AccountScopeUnavailable(this.failure); }
enum AccountScopeFailure { identityMismatch, scopeNotOpen, scopeClosing, retryableUnavailable }
enum AccountScopeCloseReason { signOut, sessionInvalidated, accountSwitch }
sealed class OpenAccountScopeOutcome { const OpenAccountScopeOutcome(); }
final class AccountScopeOpenedForAccount extends OpenAccountScopeOutcome { final AccountScope scope; const AccountScopeOpenedForAccount(this.scope); }
final class AccountScopeOpenRejected extends OpenAccountScopeOutcome { final AccountScopeFailure failure; const AccountScopeOpenRejected(this.failure); }
sealed class CloseAccountScopeOutcome { const CloseAccountScopeOutcome(); }
final class AccountScopeClosedForAccount extends CloseAccountScopeOutcome { final AccountScope scope; const AccountScopeClosedForAccount(this.scope); }
final class AccountScopeCloseIncomplete extends CloseAccountScopeOutcome { final AccountScope scope; final List<PrivateStateClearIncomplete> incomplete; const AccountScopeCloseIncomplete(this.scope, this.incomplete); }
final class AccountScopeCloseRejected extends CloseAccountScopeOutcome { final AccountScope scope; final AccountScopeFailure failure; const AccountScopeCloseRejected(this.scope, this.failure); }

abstract interface class AccountPrivacyParticipant {
  AccountPrivacyParticipantId get participantId;
  Future<PrivateStateClearOutcome> clearPrivateState(AccountScope scope);
}
enum AccountPrivacyParticipantId { authenticationSession, applicationShell, mapLocation, costLivingBudget, infrastructureCoverage, hazardReporting, propertyInspection, accountCenter }
sealed class PrivateStateClearOutcome { const PrivateStateClearOutcome(); }
final class PrivateStateCleared extends PrivateStateClearOutcome { final AccountPrivacyParticipantId participantId; final AccountScope scope; const PrivateStateCleared(this.participantId, this.scope); }
final class PrivateStateClearIncomplete extends PrivateStateClearOutcome { final AccountPrivacyParticipantId participantId; final AccountScope scope; final PrivateStateClearFailure failure; const PrivateStateClearIncomplete(this.participantId, this.scope, this.failure); }
enum PrivateStateClearFailure { localStoreUnavailable, fileCleanupIncomplete, queuedWorkCleanupIncomplete, scopeUnavailable, retryableUnavailable }
```

`AuthenticatedAccount` 是 `AUTH-001` 的公开类型。`open` 的 account id 必须非空且等于当前明确 Auth 事实；`AccountScope` 只能来自成功 open 或 snapshot，不能由调用者的任意字符串构造、替换或跨账户使用。`incomplete` 必须非空，只含八名基线 participant 中尚未完成者，且不能重复 ID。

| 成员 | 输入与约束 | outputs / typed failures | 状态、副作用、权限与顺序 |
| --- | --- | --- | --- |
| `readScope()` | 无 | `Opened`、`Closing`、`Closed`、`Unavailable(failure)`；非 nullable/空字符串暗号 | 非 opened 永不授权私有读写；不触发清理。 |
| `open(account)` | 仅 Shell；当前 Auth 同账户；closing 时不得替换账户 | `OpenedForAccount` 或 `OpenRejected(identityMismatch/scopeClosing/retryableUnavailable)` | 同账户重复 open 返回同一范围，不重置 payload；成功前不建私有 Feature。 |
| `close(scope, reason)` | 仅 Shell；该轮 immutable old scope；reason 为 signOut/sessionInvalidated/accountSwitch | `ClosedForAccount`、逐项 `CloseIncomplete` 或 `CloseRejected` | 一开始转 closing 并拒旧读写/意图；全八项 cleared 才 closed；已清项不回滚；incomplete 仅可重试同 scope。 |
| participant `clearPrivateState(scope)` | 只由 A 在 close 对固定完整集合调用；只处理 scope 的自己分区 | `Cleared` 或 `Incomplete`，均回带同一 id/scope | 不可 open/close、替换集合或代表他人；失败不恢复旧内容。 |

### 八项关闭证明

| participant / Owner | 必须处理旧账户本机内容 | 明确保留 |
| --- | --- | --- |
| `authenticationSession` / Auth | 当前设备会话已结束 | 其他设备会话、远端记录 |
| `applicationShell` / Shell | 私有导航、意图、组合请求、ViewModel、晚到结果 | 语言、无身份配置 |
| `mapLocation` / Map | `STATE-LOCATION`、收藏 cache/create queue | 公共地图/边界 cache |
| `costLivingBudget` / Cost | current 预案内存选择及私有副本 | Cost 公共 cache、远端预案 |
| `infrastructureCoverage` / Infrastructure | ICI 权重内存/副本 | 公共 cache、远端权重 |
| `hazardReporting` / Hazard | 本人/投票视图及未完成请求 | 去身份公共 cache、远端报告/投票 |
| `propertyInspection` / Property | 草稿、照片、本机副本、比较、待传 queue/文件 | 已上传远端实勘、元数据/Storage |
| `accountCenter` / Account Center | 偏好内存/副本与账户组合状态 | 远端偏好 |

**最小调用（Shell）：**

```dart
final opened = await privacy.open(authenticatedAccount);
if (opened case AccountScopeOpenedForAccount(:final scope)) {
  // 仅现在建立 scope.accountId 的私有主应用。
}
final result = await privacy.close(oldScope, AccountScopeCloseReason.signOut);
// 仅 ClosedForAccount 才可到普通登录；其余保持无私有内容恢复态。
```

**Fake Adapter 场景：** Shell fake 返回 A opened、A `CloseIncomplete(propertyInspection, fileCleanupIncomplete)`、A closed、B opened；验证 incomplete 起 A UI/意图/晚到结果均不可用，重试只针对 A，B 不继承 A。Privacy 的 participant fake 返回完整八项、任一 incomplete、未知/重复 ID 或不同 scope；仅完整八项可 closed，其余保持 closing。Property fake 用 A 草稿/待传文件和 B opened 验证 A 文件、queue、比较及晚到成功不可提交/重放，也不删 A 远端实勘；其余 Owner 以同一接口验证自己的保留项。

## 4. 推荐实现与调用顺序

1. A 合入唯一 entry point、声明和最小 fake；消费者不得依赖 `src/`。
2. 八个 Owner 并行实现自己的 participant，并用真实 Adapter 证明本结果语义；不读其它 payload。
3. 启动/登录：Shell 先获得明确 `AUTH-001`，以同一账户 `open`，仅 opened 后建私有应用。
4. 退出/失效/换号：Shell 立即屏蔽旧私有 UI、意图和晚到结果 → `AUTH-001.signOut()` → `close(oldScope, reason)`。两者成功才普通登录；任何失败仍无私有内容并可重试。B 必须重新认证后才可 open。
5. 接入生产 seam，只保留第 4 节所需跨模块流；Adapter 细节和测试组织仍归 Owner。

## 5. 联合验收

| 场景 | 操作 | 可观察结果 | 追踪 |
| --- | --- | --- | --- |
| 恢复/登录开启 | 无会话、明确 A、不可确认或身份不符 | 只有明确 A + opened 建私有应用；其余无私有内容 | `ACCOUNT-07`；`AT-AUTH-01` |
| 同 scope 幂等 | 重复 A open；完整关闭后重复 close | 与当前 scope 一致；不重建/混入 payload | `ACCOUNT-07` |
| 逐 Owner 失败/重试 | 八人逐一 incomplete，再重试 A | 首次 closing/不可读；精确 owner/failure；已清项不恢复；全员完成才 closed | `AT-OUT-02` |
| 强制退出/身份不符 | Auth 拒绝/失效或 opened A 与 Auth B 不符 | 不展示任一账户；关闭 A 恢复，不用 B 打开 | `AT-OUT-01/02` |
| A 换 B | A opened → 屏蔽/结束/关闭 → B 认证/open | A 八类状态不可见/提交/重放；B 只见 B；公共 cache/语言保留 | `AT-SWITCH-01` |

`RISK-PRIVACY-01` 的完整集合/证明和 `RISK-PRIVACY-02` 的先封锁/可恢复语义已关闭设计风险。SQLite/文件不可用、部分处理和进程重启的故障注入仍为实现后的集成证据，不能改变上述结果。

### 5.1 Wave 2 验收分配（2026-09-16）

本期开发范围是 Privacy 的真实账户范围状态机、固定八项 participant 登记、关闭协调、结果校验及幂等恢复。真实上游只消费 `AUTH-001`；Auth participant 验证当前设备会话已经结束，不代替 Shell 发起 signOut。Shell 是后续 Wave 3 lifecycle 调用方，本期使用开发 harness 经公开入口验证，不开放私有业务页面。

尚未开发的七个 participant 使用明确标识的测试 fake 验证协调协议；生产登记缺项必须拒绝关闭完成，不能把占位 participant 的成功当作真实清理证明。各业务模块在自身 Wave 实现真实 participant 和本机 Adapter，并承担各自 payload、SQLite/文件清理证据。Privacy 不提前实现这些业务存储，也不为它们提供生产成功占位。

| 场景 ID / 可观察结果 | 验证归属 | 所需依赖及用途 | 证据要求 | 负责 Owner | 最迟 Wave | 本模块证据/状态 | 联合证据/状态 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PRIV-W2-01 恢复/登录开启：只接受当前明确同账户；无会话、不可确认、空白身份和不匹配不打开 | 两者 | 本期真实 AUTH-001；Auth fake 注入过期/不可用事实；后续 Shell | 公开入口测试；真实 Auth 身份传入及拒绝路径；A 设备调用入口首屏/重启证据 | A（Privacy/Auth/Shell） | 本模块 2；Shell 联合 3 | 待验证 | 待 Wave 3 同账户 opened 门控 |
| PRIV-W2-02 同 scope 幂等：重复 open/close 不重置内容、不重复冒充完成 | 两者 | 测试完整八项 participant fake；后续真实 participant | 公开入口重复调用、并发 open/close、closing 时 open 拒绝、晚到结果测试 | A；业务 participant 各 Owner 参与 | 本模块 2；Shell 3；全员 7 | 待验证 | 待 Wave 3/7 |
| PRIV-W2-03 逐 Owner 失败/重试：先 closing，精确 incomplete，已清项不恢复，全八项才 closed | 两者 | 本期真实协调器；八项 fake 逐一注入所有适用失败、异常、缺项、重复 ID、错 scope | 公开入口故障/恢复测试；结果非空且 ID 唯一；调用开始即不可访问；失败后仅同旧 scope 可恢复；不得误报 closed | A 主责；真实清理由各业务 Owner 承担 | 本模块 2；Auth/Shell 3；Map 4；Cost/Hazard 5；Infrastructure/Property/Account Center 6；全员 7 | 待验证 | 待各 owning Wave 的真实 Adapter 故障证据及 Wave 7 全员联合 |
| PRIV-W2-04 强制退出/身份不符：A 关闭恢复期间 B 不得打开 | 两者 | 本期 AUTH-001 真实类型/调用；Auth fake 注入失效/换号；后续 Shell | 不匹配/过期 open 拒绝；旧 scope 保持不可访问；Auth 真实当前设备退出与 participant 证明；Shell 先屏蔽→signOut→close 另行联验 | A | 本模块 2；Shell 联合 3 | 待验证 | 待 Wave 3 强制退出及顺序验证 |
| PRIV-W2-05 A→B：关闭 A 全部证明前禁止 B，完成后 B 使用新范围 | 两者 | 本期双账户 Auth 与 participant fake；后续全部真实 Owner | 状态机双账户、失败重试、过期结果测试；真实 Auth A/B 调用；逐 Owner 旧内容不可读/提交/重放、公共缓存/语言/远端保留另行联验 | A 主责；B 负责 Cost/Infrastructure/Property | 本模块 2；范围切换 3；全员隔离 7 | 待验证 | 待 Wave 3/7 |
| PRIV-W2-06 清理中进程重启：不重新开放未完成旧范围，可恢复关闭 | 两者 | 本期协调器重建/harness；后续 Shell 启动恢复及业务持久存储 | 重建后非 opened；可恢复同旧范围、不接受晚到证明；真实文件/SQLite 不可写与部分处理后重启由持久存储 Owner 验证 | A 主责；Map A、Property B 负责存储故障 | 本模块 2；Shell 3；Map 4；Property 6；全员 7 | 待验证 | 待 Wave 3/4/6/7；不得以纯内存重建替代持久存储证据 |

Wave 1 分配没有截至 Wave 2 到期的联合事项。本期真实 Auth 消费及 Auth participant 的公开调用证据归本模块验收；完整 Shell 工作流最迟 Wave 3。八项集合从 Wave 2 起固定，fake 只证明协调器行为，不证明未来业务清理。各真实 participant 在自身 owning Wave 接入并验证，完整八项退出/切换联合场景最迟 Wave 7，由 A 主责、B 参与。

### 5.2 开发顺序与当期完成要求

1. 建立唯一公开入口及契约全部 declarations、消费者测试 fake，验证调用方只依赖公开入口。
2. 实现真实范围状态机、身份校验、八项登记与结果校验、关闭协调和同 scope 并发/重试；通过第 5.1 节本模块测试。
3. 接入真实 AUTH-001 和 Auth participant，经无私有业务内容的开发 harness 完成真实调用与 A 目标设备故障/恢复/重启验证。
4. 运行格式检查、静态分析、测试和 debug APK 构建；记录命令、环境、结果和代码版本，证据不得包含凭据。
5. 按开发规范报告模块实现、本期集成、后续集成和当前阻塞。第 5.1 节本模块全部通过才可声明 `Implemented`；未来 participant 或 Shell 未到期不阻塞本模块，但不能宣告完整联合验收通过或 `Integrated`。

## 6. 实现自由、阻塞项与变更

A 可决定 `src/`、participant 注入、内部状态机、Adapter、并发、取消、重试、日志和测试组织。变更唯一 import、公开声明/result variant、八人集合、隔离/顺序/保留项，须说明影响、由提供方和受影响 Owner 确认，并在同一 PR 更新声明、本契约、HTML 与相关 fake/Adapter 测试。

当前阻塞项：无。参考：[FLOW-01](../system/flows.md#flow-01启动注册登录退出与账户切换)、[数据所有权](../system/data-ownership.md#privacy-barrier-参与者清单)、[风险登记](../system/risks-and-decisions.md#风险与关闭条件)、[ADR 0013](../../adr/0013-autonomous-design-ai-ready-approval.md)。

## Change Log

| 日期 | 状态 | 变更原因 | 受影响对象 |
| --- | --- | --- | --- |
| 2026-09-15 | `Ready for Development` | Issue #23 全审返工：唯一 import、声明级 seam、typed results、participant、顺序、fake 和四项 Readiness；不改产品/Schema/payload Owner | `PRIVACY-001`、`STATE-ACCOUNT-SCOPE`、八位 participant、`ACCOUNT-07` |
| 2026-09-16 | `Ready for Development`；尚未实现 | Wave 2 开发准备：按开发规范分配全部场景、本期真实 Auth 与未来 participant、证据责任及最迟 Wave | PRIVACY-001、Auth participant、Wave 3–7 联合接入；公开声明及产品/Schema 不变 |
