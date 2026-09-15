# Application Shell 开发协作契约

> 状态：`Ready for Development`
> Owner：`A`
> 系统基线：`5d11769`
> 消费者：Home & Relocation Outlook、Map / Location、Cost of Living & Budget、Crime & Security、Nearby Facilities、Public Transportation、Hazard Reporting、Socio-economic、Infrastructure Coverage、Property Inspection、Account Center、Personalized Location Suitability
> 最后更新：`2026-09-15`

Application Shell 是所有 Feature 的唯一主应用协调 seam：在同账户已打开范围内执行首页/地图双 Tab、业务导航、返回语境和声明式组合；不拥有认证、地点、领域结果、缓存、队列或 Feature 业务写入。

**定义完成：** `AUTH-001` 确认当前设备会话且 `PRIVACY-001.open` 对同一不可变账户引用返回 `opened` 后才建立私有主应用。所有消费者从本文件的唯一公开入口调用同一套 `SHELL-001` 声明；不得以本地成员、结果或失败类型替换它。

## 1. 责任、依赖与边界

| 边界 | Owner | 负责 | 不负责 |
| --- | --- | --- | --- |
| `lib/app/` | Application Shell | 门控、`STATE-NAVIGATION`、两个一级 Tab、账户任务、返回、组合槽位、`PREF-LANGUAGE` | 会话 SDK、地点选择、领域计算/解释、业务 payload、缓存、队列、Feature 数据写入 |
| Authentication & Session | 其 Owner | 当前设备会话和认证事实（`AUTH-001`） | 主应用路由、scope 关闭证明 |
| Account Privacy | 其 Owner | 同账户 `opened`/`closed` 与关闭证明（`PRIVACY-001`） | Shell 导航清理、认证 SDK、Feature payload |
| 各 Feature 唯一公开入口 | 各自 Owner | 专有 intent/contribution、领域读取/写入、结果解释和可用性 | 全局门控、路由执行、其他 Owner 数据解释 |

**依赖顺序。** (1) Shell 只从 `AUTH-001` 和 `PRIVACY-001` 各自的唯一入口取得门控事实；(2) Shell 先合入本节的公开声明；(3) Feature 以同一声明的 fake Shell 开发自己的公开 marker；(4) Shell 从 Feature 的公开 seam 接入真实导航/组合；(5) 只保留第 6 节跨 Owner 流程验证。消费者不得 import `lib/app/` 内部文件。

## 2. Shell 必须调用的 Interface

### `AUTH-001` — 当前设备会话

按 [Authentication & Session 契约](../features/authentication-and-session.md) 的唯一入口恢复/结束当前设备会话，不从缓存、profile 或旧 snapshot 推断认证。只有明确 authenticated 的不可变账户引用可进入下一步；无会话显示认证入口，verification-required 或不可确认时保持认证/恢复态。

### `PRIVACY-001` — 账户范围

Shell 是 `open`/`close` 的唯一发起者；`open` 输入必须与 `AUTH-001` 的同一不可变账户引用相同，只有 `opened` 建立私有路由。退出、认证失效或换号时，先隐藏旧账户私有 UI、拒绝新业务意图并丢弃旧导航/组合响应，再结束会话并对旧范围调用 `close`。只有二者完成且所有参与 Owner 已关闭才显示普通登录入口；失败停在无私有内容的清理恢复态，重试同一旧范围。语言和公共缓存不属于 close payload。

## 3. Shell 必须提供的 Interface

### `SHELL-001` — Application Coordination

**提供者：** Application Shell（A）
**消费者：** 本页标题列出的全部 Feature/shared module
**唯一公开 import：** `package:locatemy/app/application_shell.dart`

该入口只导出调用 Shell 所需的以下公共声明，是 `SHELL-001` 的唯一规范。消费者可只调用自己所需的 `submit` 或 `publish`，但不得声明、改名、缩窄、扩展或以 `ShellPublishOutcome`、本地 `ShellContributionOutcome` 等变体替换这些类型。

```dart
abstract interface class ApplicationShell {
  Future<ShellIntentOutcome> submit(ShellIntent intent);
  Future<ShellContributionOutcome> publish(ShellContribution contribution);
}

abstract interface class ShellIntent {}
abstract interface class ShellContribution {}

sealed class ShellIntentOutcome {}
final class ShellIntentAccepted extends ShellIntentOutcome {}
final class ShellAuthenticationRequired extends ShellIntentOutcome {}
final class ShellIntentRejected extends ShellIntentOutcome {
  const ShellIntentRejected(this.reason);
  final ShellRejectionReason reason;
}

sealed class ShellContributionOutcome {}
final class ShellContributionAccepted extends ShellContributionOutcome {}
final class ShellContributionAuthenticationRequired extends ShellContributionOutcome {}
final class ShellContributionRejected extends ShellContributionOutcome {
  const ShellContributionRejected(this.reason);
  final ShellRejectionReason reason;
}

enum ShellRejectionReason {
  missingInput,
  staleInput,
  inapplicableDestination,
  scopeUnavailable,
}
```

`ShellIntent` 与 `ShellContribution` 是 Feature 定义的公开 marker 基类；具体 marker 只从该 Feature 的唯一公开入口导出，Shell 不拥有或重述其领域字段。每个 concrete 输入必须精确声明目的地、适用时的 immutable single 或保留原顺序的 A/B 地点、stable 业务 ID、返回语境、账户范围绑定，以及 contribution 的地点/角色、来源、日期、单位或口径、缓存/估算和可用性。不得携带可变地图对象、账户资料、原始数据库行、SDK 对象或其他 Feature 私有 payload。

| 成员 | 输入约束 | typed 结果与调用者处理 | 状态与副作用 |
| --- | --- | --- | --- |
| `submit(intent)` | 非空；目的地由 concrete marker 唯一确定；stable ID、地点与返回语境均属当前 opened scope、完整且未过期。无地点 Home/账户任务可不带地点。 | `ShellIntentAccepted`：目标接收原输入并转场。`ShellAuthenticationRequired`：保持当前状态并显示登录/恢复。`ShellIntentRejected(reason)`：保持原状态并按 reason 恢复；不是领域资料失败。 | 只更新门控、选定 Tab 和导航/返回栈；不写 Feature 数据、不改地点、不计算或改写领域结论。 |
| `publish(contribution)` | 非空；绑定当前 opened scope 与仍当前的请求/地点/角色/返回语境；保留提供方来源、日期、口径/单位、缓存/估算和 available/empty/partial/unavailable。 | `ShellContributionAccepted`：在匹配槽位组合/渐进呈现。`ShellContributionAuthenticationRequired`：调用方保留结果、不发布。`ShellContributionRejected(reason)`：不覆盖当前槽位，保留结果/重试路径；不是领域 unavailable。 | 只更新组合槽位；不读提供方内部存储、置零、判定可比性或触发业务写入。 |

**顺序、权限与失效。** 认证页面是唯一不要求 opened scope 的 Shell 呈现；全部私有 intent/contribution 要求当前 authenticated 账户和同账户 `opened`。范围关闭开始后不接受旧输入，待处理 intent、贡献和晚到响应均丢弃。新账户不得继承旧 Tab、栈、ViewModel、返回语境或组合内容。分析/A-B 页面只使用调用时不可变地点；之后全局选点不得改写它。Shell 可渐进显示独立贡献，但空、未知、partial、unavailable 与零不可互换；图层点击只能产生提供方 typed intent，不能静默改变全局地点。

| 消费者 | 可调用成员 | 真实协调需要 |
| --- | --- | --- |
| Home & Relocation Outlook | `submit` | `ExploreMapIntent` 切至地图 Tab，不生成默认地点。 |
| Cost of Living & Budget、Crime & Security、Account Center | `submit` | 分析/账户/房产等类型化目的地和原返回语境。 |
| Map / Location、Nearby Facilities、Public Transportation、Hazard Reporting、Socio-economic、Infrastructure Coverage、Property Inspection、Personalized Location Suitability | `submit`、`publish` | 类型化导航/返回，以及带提供方元数据的详情、A/B 或摘要槽位贡献。 |

最小调用示例（`OpenCostIntent` 由 Cost 的公开入口定义）：

```dart
final ShellIntentOutcome outcome = await applicationShell.submit(
  OpenCostIntent(location: location, returnContext: returnContext),
);
// 只有 ShellIntentAccepted 才转场；其余结果保留当前页和恢复路径。
```

**fake Adapter 场景。** Feature 以实现同一 `ApplicationShell` 声明的 fake 分别返回 intent/contribution 的 accepted、authentication-required、`staleInput` rejected：验证 accepted 才导航/组合；后两者保留原 immutable 输入、草稿或结果及文字恢复路径；旧地点/旧账户贡献不覆盖当前槽位；没有业务写入、上传或领域失败被伪装。生产 Shell 必须证明相同 public Interface 的这些可观察结果。

## 4. 直接数据、规则与可观察结果

| 目的 | 权威事实 | Shell 边界与不变量 |
| --- | --- | --- |
| 认证/范围门控 | `AUTH-001`、`PRIVACY-001`、`STATE-SESSION`、`STATE-ACCOUNT-SCOPE` | 只消费结果；关闭/不确定时不读取、呈现或重放私有内容。 |
| 导航/返回 | `STATE-NAVIGATION`、`LOCATION-001`、Feature typed marker | 只有首页、地图两个一级 Tab；账户不是第三 Tab；A/B 原顺序和快照地点不改写。 |
| 语言 | `PREF-LANGUAGE`、[全局导航](../../knowledge_base/locatemy_product/features/global_navigation.md)、[UI 双语规则](../../knowledge_base/locatemy_product/ui_design_spec.md#双语与内容规则) | `device_preferences` 仅保存无身份语言偏好；中文/English 同功能、状态、错误和归因，跨重启/退出保留。 |
| 组合 | Feature 公共 contribution | 只组织呈现；每项保留地点、来源、日期、口径、状态及可访问文字。 |

## 5. 推荐实施顺序

1. 从 Auth/Privacy 唯一入口接入门控，并先合入 `application_shell.dart` 的声明。
2. 实现 same-account `opened` 门控和关闭开始即隐藏私有内容的 barrier。
3. 完成两个 Tab、返回语境、账户任务和语言偏好，不触碰 Feature 数据。
4. 以固定 `submit`/`publish` 接入 marker 和渐进组合；消费者先用同一 fake 并行开发。
5. 用第 6 节验证真实 Adapter；Widget、状态管理、SDK、并发、取消、重试和测试组织仍归 Owner。

## 6. 联合集成与验收

| 情景 | 操作 | 可观察结果 |
| --- | --- | --- |
| 启动、登录与换号（`AT-AUTH-01`、`AT-SWITCH-01`、`AT-OUT-01/02`） | 无/有效/不可确认会话、同账户 open、identity mismatch、退出及 A→B 换号；注入 close 失败。 | 仅 authenticated + same-account `opened` 建主应用；关闭起旧内容消失，close 与 sign-out 完成才普通登录；失败可重试且不泄漏新账户。 |
| Tab、分析和返回（`AT-HOME-03`、`AT-LOC-01/02`、`AT-ANALYSIS-01`、`AT-COMPARE-01/03`） | 探索地图、single/A-B intent、返回以及 contribution unavailable/partial。 | 两个 Tab 保留局部状态；探索地图不选点；快照地点/返回语境不变；分项渐进且不置零。 |
| Hazard、Property、Account（`AT-HAZARD-01/03/05`、`AT-PROP-01/04`） | 从入口/图层发起创建、详情、本人列表、返回式选点、档案和危险退出。 | typed intent 保留业务语境；拒绝不创建或重放私有任务；账户入口不是 Tab。 |
| fake seam | 每消费者使用同一 public declaration 的 fake，返回三种 intent 和三种 contribution outcome。 | 只接受 canonical outcome 名称；submit-only 不需要 publish；无人 import 内部 Shell 或自定义结果类型。 |

## 7. Ready Gate、变更与参考

- [x] Owner、消费者、依赖顺序及 `lib/app/` 公共边界明确。
- [x] `SHELL-001` 有唯一 import、声明级成员/types、精确输入、typed results/failures、状态/副作用、顺序/权限、示例和 fake。
- [x] Interface 注册表、`FLOW-01/02/03/05/06/07/08` 与 12 个消费者真实 submit-only/submit+publish 需要对齐；`ShellPublishOutcome` 等副本不是契约来源。
- [x] 数据/权限边界和联合验收完整；原 HTML blocker 已随 Markdown 关闭，独立复审后依 ADR 0013 维持 `Ready for Development`。

公开 seam 变更须由 Shell 提供者说明影响、每名受影响消费者确认，并在同一 PR 更新声明、消费者契约、HTML 与相关测试。函数体、Widget 实现、私有实现、SDK 映射、迁移和测试实现不属于本契约。

权威阅读顺序：[`CONTEXT.md`](../../../CONTEXT.md)、[Interface 注册表](../system/interfaces.md)、[关键流程](../system/flows.md)、[Authentication & Session](../features/authentication-and-session.md)、[Account Privacy](account-privacy.md) 与各消费者契约。

## 8. Change Log

| 日期 | 状态 | 变更原因 | 受影响对象 | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Ready for Development` | Issue #9 冻结门控、导航、组合、语言与跨 Owner 工作流 | `NAV-01`–`NAV-03`、`SHELL-001` | 项目负责人 |
| 2026-09-15 | `Ready for Development` | Issue #23 全审：冻结唯一 `application_shell.dart` 与 canonical `submit`/`publish` outcome，消除 submit-only、`ShellPublishOutcome` 和本地 contribution outcome 的不兼容副本；Markdown/HTML blocker 同步关闭 | `SHELL-001`、12 个消费者、`FLOW-01/02/03/05/06/07/08` | 设计 AI（项目负责人授权） |
