# Hazard Reporting 开发协作契约

> 状态：`Ready for Development`（2026-09-15；设计 AI〔项目负责人授权〕，ADR 0013）  
> 实现状态：`Implemented`（2026-09-17；GPT‑5.6 Luna High Standards / Spec 双轴验收通过）；本期联合验收通过，Property Wave 6 待接入。
> Owner：`A`；系统基线：`Baselined — 5d11769`；依赖波次：Wave 5  
> 唯一公开入口：`package:locatemy/features/hazard_reporting/hazard_reporting.dart`  
> 完成定义：消费者仅凭本契约即可创建、读取、呈现及管理公共隐患、提交声明式图层，并取得可保存的附近隐患数；不会读取 Feature 内部状态、绕过 RLS，或把隐患混为官方治安结果。

本文件是 Hazard Reporting 对 Issue #23 的唯一 Development Contract；本 Markdown 是权威来源，[同名 HTML](../../human/hazard-reporting.html) 是语义等价的人类阅读导出，不是第二份规格或发布包。它固定公开 Dart 声明、输入约束、typed outcomes、权限/副作用、顺序、数据访问及联合验收；`lib/features/hazard_reporting/` 内的 Widget、状态管理、Supabase/空间 Adapter、分页、缓存、并发、取消、重试、文件拆分与测试组织由 A 决定。公式、字段、RLS、RPC SQL 和 migration 仍分别以产品知识库与 Schema Catalog 为唯一权威。

## 0. 固定阅读顺序与四项 Readiness

1. [领域词汇](../../../CONTEXT.md#项目自有表)、[隐患产品事实](../../knowledge_base/locatemy_product/features/hazard_reporting.md)；
2. [Feature map（Hazard）](../system/feature-map.md#fm-hazard)、[Interface 注册表](../system/interfaces.md)、[FLOW-05](../system/flows.md#flow-05公共隐患投票与本人管理)、[FLOW-06](../system/flows.md#flow-06房产实勘照片风险快照与回收站)；
3. [Capability Traceability](../system/capability-traceability.md)、[数据所有权](../system/data-ownership.md)、[Schema Catalog](../data/schema-catalog.md)、[风险登记](../system/risks-and-decisions.md#风险与关闭条件)；
4. 本契约与同名 HTML；HTML 只是本 Markdown 的人类可读、语义等价导出，不另行引入发布治理。

| Readiness | 可核查证据 | 结论 |
| --- | --- | --- |
| 责任与范围 | `HAZ-01`–`HAZ-04` 唯一归属 Hazard；地图、Shell、账户 scope、官方安全与 Property snapshot 属于其他 Owner | 已就绪 |
| 契约与消费者 | `HAZARD-001`、`HAZARD-002` 的唯一入口、声明、次序和 fake 在第 3 节；上游仅 `SHELL-001`、`LOCATION-002`、`PRIVACY-001` | 已就绪 |
| 数据与安全 | 仅使用 `crowdsourced_hazards`、`crowdsourced_hazard_votes`、`hazard_vote_counts`；Schema Catalog 定义 status-only、RLS 与安全 RPC | 已就绪 |
| 验收与风险 | 第 5 节覆盖 canonical `AT-HAZARD-*`、`AT-PROP-03`；`RISK-HAZARD-01/02` 留作实现/集成运行时证据 | 已就绪 |

## 1. 成果、责任与冻结边界

- 已开启账户范围的用户可在线创建五类公共报告、按 viewport 分页读取图层与详情、对每份报告投赞成/反对/撤回，并只管理自己的 `pending/resolved` 状态或删除自己的报告。
- 发布后报告的 type、trim 后 title、description、location、report time 与 author 均不可编辑。`pending/resolved` 是作者处理标记，不是平台验证、审核、隐藏或删除决定；没有维护者例外。
- 房产只经 `HAZARD-002` 请求同一合法房产坐标周围的完整 pending 数，Hazard 不写房产风险快照。隐患绝不进入 `SAFETY-001`、地点摘要或适配度。

| Owner / 受控边界 | 负责 | 不负责 | 协作 |
| --- | --- | --- | --- |
| `lib/features/hazard_reporting/`（A） | 报告、详情、图层读取/分页、作者状态/删除、本人投票、`HAZARD-001/002` | 地图手势/底图、导航、账户 scope、官方犯罪、房产写入 | 消费 Shell、Map、Privacy；提供 Hazard Interface |
| Application Shell | opened 门控、新建/详情/本人列表/返回导航和组合 | 报告字段、RLS、投票、计数、图层数据 | `SHELL-001` |
| Map / Location | 长按产生合法创建意图、寄宿声明式图层并回传点击 | 报告读取/写入、内容/权限、详情语义 | `LOCATION-002` |
| Account Privacy | 同账户 opened/closing 和旧账户私有状态清理证明 | 远端报告/投票删除或公共缓存 | `PRIVACY-001` |
| Property Inspection | 何时将完整附近数写入原子风险快照 | 报告、计数口径、公共图层 | 消费 `HAZARD-002` |

## 2. 需要调用的 Interface

### `SHELL-001` — Hazard 导航与组合

**提供者：** Application Shell；**消费者：** Hazard Reporting；**唯一公开 import：** `package:locatemy/app/application_shell.dart`。

```dart
abstract interface class ApplicationShell {
  Future<ShellIntentOutcome> submit(ShellIntent intent);
  Future<ShellContributionOutcome> publish(ShellContribution contribution);
}
abstract interface class ShellIntent {}
abstract interface class ShellContribution {}
sealed class ShellIntentOutcome { const ShellIntentOutcome(); }
final class ShellIntentAccepted extends ShellIntentOutcome {}
final class ShellAuthenticationRequired extends ShellIntentOutcome {}
final class ShellIntentRejected extends ShellIntentOutcome {
  const ShellIntentRejected(this.reason);
  final ShellRejectionReason reason;
}
sealed class ShellContributionOutcome { const ShellContributionOutcome(); }
final class ShellContributionAccepted extends ShellContributionOutcome {}
final class ShellContributionAuthenticationRequired extends ShellContributionOutcome {}
final class ShellContributionRejected extends ShellContributionOutcome {
  const ShellContributionRejected(this.reason);
  final ShellRejectionReason reason;
}
enum ShellRejectionReason { missingInput, staleInput, inapplicableDestination, scopeUnavailable }
```

上方是 Application Shell owning contract 的**完整 canonical 声明**；Hazard 与 fake 不得截断、复制或改形。Hazard 实际只调用 `submit`（开新建、详情、我的报告、返回）与 `publish`（已创建报告或可用图层/详情贡献）。Hazard 从自己的唯一入口导出 `OpenHazardComposerIntent`、`OpenHazardDetailIntent`、`OpenMyHazardsIntent`、`ReturnToHazardMapIntent`（均为 `ShellIntent`）和 `HazardShellContribution`（为 `ShellContribution`）；详情/返回 intent 只带稳定 `HazardReportId` 或原返回语境，不得携带可变地图对象、另一账户作者/投票状态或未验证计数。

| 输入约束 | 输出 / typed failures | 状态与副作用 | 顺序、权限与最小示例 |
| --- | --- | --- | --- |
| intent/contribution 是当前 opened scope 的未过期事实；贡献保留来源、时间、完整性。 | `accepted`、`authenticationRequired`、`rejected(reason)`；后两者是 Shell 结果，不是 Hazard 资料失败。 | Shell 只改门控、栈和组合；Hazard 不改报告、投票、地点或房产。 | 先收到 Map 合法 intent/stable id，再 submit；仅 accepted 进入目标。`await shell.submit(OpenHazardDetailIntent(id, context));` |

**Fake 场景：** fake Shell 回 accepted、authentication-required、stale-input rejected；rejected 时保留表单/已读页及原因，不创建/更新报告，不把导航拒绝显示为网络错误。

### `LOCATION-002` — 长按、图层宿主与点击意图

**提供者：** Map / Location；**消费者：** Hazard Reporting；**唯一公开 import：** `package:locatemy/features/map_location/map_location.dart`。

下列是 Map / Location owning contract 的**完整 canonical 声明**；Hazard 实际调用的子集只有 `MapLayerHost.contribute` 与 `MapLayerHost.requestLongPress`，但生产 Adapter、Hazard 和 fake 必须使用整套相同类型、成员、输入及 result variant，不得复制、截断或改形。长按先由 Map 空间校验，成功才返回带 `ValidLocationReference` 的 `CreateHazardIntent`；Hazard 不把裸坐标变为可提交写入。items 必有稳定 report id、合法坐标、viewport version 和 provider-defined detail intent。

```dart
abstract interface class MapLayerHost {
  Future<MapLayerContributionOutcome> contribute(MapLayerContribution contribution);
  Future<MapLayerIntentOutcome> requestLongPress(GeographicPoint point);
}
final class MapLayerContribution {
  final String providerId; final String layerId; final String viewportVersion;
  final MapLayerVisibility visibility; final List<MapLayerItem> items;
}
enum MapLayerVisibility { visible, hidden }
final class MapLayerItem {
  final String stableItemId; final GeographicPoint point; final MapLayerIntent intent;
}
sealed class MapLayerIntent {}
final class ProviderDefinedIntent extends MapLayerIntent {
  final String providerId; final String action; final String stableItemId;
}
final class CreateHazardIntent extends MapLayerIntent { final ValidLocationReference location; }
sealed class MapLayerContributionOutcome {}
final class MapLayerAccepted extends MapLayerContributionOutcome {}
final class MapLayerHidden extends MapLayerContributionOutcome {}
final class MapLayerRejected extends MapLayerContributionOutcome { final MapLayerFailure failure; }
sealed class MapLayerIntentOutcome {}
final class MapLayerIntentAccepted extends MapLayerIntentOutcome { final MapLayerIntent intent; }
final class MapLayerIntentRejected extends MapLayerIntentOutcome { final MapLayerFailure failure; }
enum MapLayerFailure { invalidContribution, invalidCoordinate, outsideMalaysia, scopeUnavailable, staleViewport, unauthenticated }
```

| 输入约束 | 输出 / typed failures | 状态与副作用 | 顺序、权限与最小示例 |
| --- | --- | --- | --- |
| 创建只接受 Map immutable location；图层 items 为当前 viewport 成功页，id 不复用。 | accepted、hidden、rejected(`invalidContribution/invalidCoordinate/outsideMalaysia/scopeUnavailable/staleViewport/unauthenticated`)；长按结果同 Map 契约。 | Map 只更新覆盖物/回传意图；点击、长按、贡献均不改 single/A/B/property，Hazard 不写 Map。 | 先读页再 contribute；旧 viewport 不发布/覆盖新图层。`await host.contribute(hazardLayer);` |

**Fake 场景：** fake Map 给合法/范围外长按、visible/hidden/rejected、两个 viewport version；Hazard 仅对合法 intent 开表单，旧页不能覆盖新图层，partial 页不称范围为空。

### `PRIVACY-001` — 账户范围

**提供者：** Account Privacy；**消费者：** Hazard Reporting；**唯一公开 import：** `package:locatemy/features/account_privacy/account_privacy.dart`。

下列是 Account Privacy owning contract 的**完整 canonical 声明**；Hazard 不调用 `open` 或 `close`，只消费 `readScope()` 及作为基线八名 participant 之一实现 `clearPrivateState(scope)`，但不得因此创造缩窄的 scope 或 close 变体。

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

`AuthenticatedAccount` 是 `AUTH-001` 的公开类型。Hazard 的 participant id 固定为 `hazardReporting`，只清理“本人报告/投票私有视图状态与未完成请求”；不能读或代表其他 participant。closing 开始即阻断旧账户作者/投票读取、提交、重放和晚到响应；完全去身份公共读缓存可留，远端报告/投票不因退出删除。

**Fake 场景：** A 创建/投票中 close，fake Privacy 令 B opened；A 输入、本人列表、投票选择和晚到成功均不可呈现/提交，B 只见 B 私有状态，公共去身份页可重新读取。

## 3. 必须提供的 Interface

### `HAZARD-001` — 公共报告、作者管理、投票与图层

**提供者：** Hazard Reporting（A）；**消费者：** Application Shell、Map / Location；**唯一公开 import：** `package:locatemy/features/hazard_reporting/hazard_reporting.dart`。

消费者只能 import 此入口。A 应先合入以下声明与最小 fake；它们是协作形状，不是可提交实现体、SQL 或 SDK 映射。

```dart
final class OpenHazardComposerIntent extends ShellIntent {
  final ValidLocationReference location; final String returnContextId;
  const OpenHazardComposerIntent({required this.location, required this.returnContextId});
}
final class OpenHazardDetailIntent extends ShellIntent {
  final HazardReportId id; final String returnContextId;
  const OpenHazardDetailIntent({required this.id, required this.returnContextId});
}
final class OpenMyHazardsIntent extends ShellIntent {
  final String returnContextId; const OpenMyHazardsIntent(this.returnContextId);
}
final class ReturnToHazardMapIntent extends ShellIntent {
  final String returnContextId; const ReturnToHazardMapIntent(this.returnContextId);
}
final class HazardShellContribution extends ShellContribution {
  final String contributionId; final String source; final DateTime observedAt;
  final String availability; const HazardShellContribution({required this.contributionId, required this.source, required this.observedAt, required this.availability});
}

abstract interface class HazardReporting {
  Future<HazardCreateOutcome> create(HazardCreateRequest request);
  Future<HazardPageOutcome> loadPublic(HazardPageRequest request);
  Future<HazardDetailOutcome> loadDetail(HazardReportId id);
  Future<MyHazardsOutcome> loadMine(HazardPageRequest request);
  Future<HazardStatusOutcome> changeMyStatus(HazardStatusRequest request);
  Future<HazardDeleteOutcome> deleteMine(HazardReportId id);
  Future<HazardVoteOutcome> vote(HazardVoteRequest request);
}
enum HazardType { flood, crime, traffic, infrastructure, other }
enum HazardAuthorStatus { pending, resolved }
enum HazardVote { up, down, none }
final class HazardReportId { final String value; const HazardReportId(this.value); }
final class HazardCreateRequest { final ValidLocationReference location; final HazardType type; final String title; final String? description; const HazardCreateRequest({required this.location, required this.type, required this.title, this.description}); }
final class HazardPageRequest { final String viewportVersion; final HazardViewport viewport; final String? cursor; const HazardPageRequest({required this.viewportVersion, required this.viewport, this.cursor}); }
final class HazardViewport { final GeographicPoint southWest; final GeographicPoint northEast; const HazardViewport(this.southWest, this.northEast); }
final class HazardStatusRequest { final HazardReportId id; final HazardAuthorStatus status; const HazardStatusRequest(this.id, this.status); }
final class HazardVoteRequest { final HazardReportId id; final HazardVote vote; const HazardVoteRequest(this.id, this.vote); }
final class HazardReport { final HazardReportId id; final HazardType type; final String title; final String? description; final GeographicPoint location; final HazardAuthorStatus status; final DateTime reportedAt; final HazardAuthorView author; final HazardVoteState vote; const HazardReport({required this.id, required this.type, required this.title, this.description, required this.location, required this.status, required this.reportedAt, required this.author, required this.vote}); }
enum HazardAuthorView { mine, other }
final class HazardVoteState { final HazardVote mine; final int upvotes; final int downvotes; const HazardVoteState(this.mine, this.upvotes, this.downvotes); }
sealed class HazardCreateOutcome { const HazardCreateOutcome(); }
final class HazardCreated extends HazardCreateOutcome { final HazardReport report; const HazardCreated(this.report); }
final class HazardCreateRejected extends HazardCreateOutcome { final HazardWriteFailure failure; const HazardCreateRejected(this.failure); }
sealed class HazardPageOutcome { const HazardPageOutcome(); }
final class HazardPageAvailable extends HazardPageOutcome { final HazardPage page; const HazardPageAvailable(this.page); }
final class HazardPagePartial extends HazardPageOutcome { final HazardPage page; final HazardReadFailure failure; const HazardPagePartial(this.page, this.failure); }
final class HazardPageUnavailable extends HazardPageOutcome { final HazardReadFailure failure; const HazardPageUnavailable(this.failure); }
final class HazardPage { final List<HazardReport> reports; final String? nextCursor; final String viewportVersion; const HazardPage(this.reports, this.nextCursor, this.viewportVersion); }
sealed class HazardDetailOutcome { const HazardDetailOutcome(); }
final class HazardDetailAvailable extends HazardDetailOutcome { final HazardReport report; const HazardDetailAvailable(this.report); }
final class HazardDetailUnavailable extends HazardDetailOutcome { final HazardReadFailure failure; const HazardDetailUnavailable(this.failure); }
sealed class MyHazardsOutcome { const MyHazardsOutcome(); }
final class MyHazardsAvailable extends MyHazardsOutcome { final HazardPage page; const MyHazardsAvailable(this.page); }
final class MyHazardsUnavailable extends MyHazardsOutcome { final HazardReadFailure failure; const MyHazardsUnavailable(this.failure); }
sealed class HazardStatusOutcome { const HazardStatusOutcome(); }
final class HazardStatusChanged extends HazardStatusOutcome { final HazardReport report; const HazardStatusChanged(this.report); }
final class HazardStatusRejected extends HazardStatusOutcome { final HazardWriteFailure failure; const HazardStatusRejected(this.failure); }
sealed class HazardDeleteOutcome { const HazardDeleteOutcome(); }
final class HazardDeleted extends HazardDeleteOutcome { final HazardReportId id; const HazardDeleted(this.id); }
final class HazardDeleteRejected extends HazardDeleteOutcome { final HazardWriteFailure failure; const HazardDeleteRejected(this.failure); }
sealed class HazardVoteOutcome { const HazardVoteOutcome(); }
final class HazardVoteChanged extends HazardVoteOutcome { final HazardReportId id; final HazardVoteState state; const HazardVoteChanged(this.id, this.state); }
final class HazardVoteRejected extends HazardVoteOutcome { final HazardWriteFailure failure; const HazardVoteRejected(this.failure); }
enum HazardReadFailure { authenticationRequired, invalidViewport, notFound, retryableUnavailable, incompletePage, scopeUnavailable }
enum HazardWriteFailure { invalidType, emptyTitle, titleTooLong, descriptionTooLong, invalidLocation, authenticationRequired, permissionDenied, conflict, notFound, retryableUnavailable, scopeUnavailable, immutableContent }
```

| 调用 | 输入约束 | typed output / failure | 状态、副作用、权限与顺序 |
| --- | --- | --- | --- |
| `create` | opened；type 必选；title trim 后 1–120；description 可空且 ≤2000；location 是 Map immutable reference；在线。 | `HazardCreated` 或字段/权限/服务分类的 `HazardCreateRejected`。 | author-only insert；成功后权威 `reportedAt/author/status` 不由客户端改写。失败留输入；无离线队列/伪 created。 |
| `loadPublic` / `loadDetail` | authenticated；有效 viewport/cursor 或稳定 id；旧 viewport 不采用。 | available、partial（成功页加 failure）、unavailable；空 reports 仅成功页为空。 | authenticated 公读；先完成当前页再贡献图层，不能把失败/partial 置 0 或范围无报告。 |
| `loadMine` | opened；请求只代表当前账户。 | available 或 unavailable；不以空列表表示权限/网络失败。 | 仅当前 author；close 后丢弃响应。 |
| `changeMyStatus` | opened；稳定 id；仅 `pending/resolved`。 | changed（权威 report）或 rejected。 | 仅 author update status；type/title/description/location/reportedAt/author 无编辑路径，写入为 immutableContent/permission failure。成功后详情、mine、图层一致刷新。 |
| `deleteMine` | opened；稳定 id；用户已确认。 | deleted 或 rejected。 | 仅 author delete；取消无副作用；级联本人 votes；并发 delete 为 notFound/conflict，不假称成功。 |
| `vote` | opened；稳定 id；`up/down/none`；一账户一报告。 | changed（本人选择与 aggregate counts）或 rejected。 | 只写本人 vote；none 撤回。counts 只经 `hazard_vote_counts` RPC 读，客户端不写 count、不读他人 vote/身份。 |

**最小调用：** `await hazards.create(HazardCreateRequest(location: intent.location, type: HazardType.flood, title: title, description: description));`。只有 `HazardCreated` 才 publish 图层/详情贡献；其他 outcome 原样进入字段或恢复路径。

**Fake 场景：** Shell fake 消费 created、empty successful page、partial、authentication-required、permission、conflict、retryable；仅 successful empty 显示“暂无”。Map fake 验证 item 只有 id/location/provider-defined intent，旧 viewport 不发布。双账户 fake 改票/撤回并验证同一 counts、无匿名/他人 vote 枚举。author fake 验证仅本人 status/delete，A close 后成功不可落入 B。

### `HAZARD-002` — 房产风险附近 pending 数

**提供者：** Hazard Reporting（A）；**消费者：** Property Inspection；**唯一公开 import：** `package:locatemy/features/hazard_reporting/hazard_reporting.dart`。

```dart
abstract interface class HazardRiskCounter { Future<HazardNearbyCountOutcome> countPending(HazardNearbyCountRequest request); }
final class HazardNearbyCountRequest { final ValidLocationReference propertyLocation; const HazardNearbyCountRequest(this.propertyLocation); }
sealed class HazardNearbyCountOutcome { const HazardNearbyCountOutcome(); }
final class HazardNearbyCountAvailable extends HazardNearbyCountOutcome { final int count; final int radiusMeters; final DateTime countedAt; const HazardNearbyCountAvailable(this.count, this.radiusMeters, this.countedAt); }
final class HazardNearbyCountUnavailable extends HazardNearbyCountOutcome { final HazardNearbyCountFailure failure; const HazardNearbyCountUnavailable(this.failure); }
enum HazardNearbyCountFailure { invalidLocation, authenticationRequired, partialResult, retryableUnavailable, scopeUnavailable }
```

| 输入约束 | output / failure | 状态与副作用 | 顺序、权限与最小示例 |
| --- | --- | --- | --- |
| propertyLocation 是 `LOCATION-001` 合法 immutable property reference。 | available 带 count/radiusMeters/countedAt；unavailable 区分 invalid、partial、scope、retryable。 | 只读公开 reports；不写报告、票、图层、官方安全或 Property snapshot。 | Haversine `d <= 2,000m` 含边界；仅 pending。Property 仅在同坐标完整 `SAFETY-001` 也 available 时整体写 snapshot。`await counter.countPending(HazardNearbyCountRequest(location));` |

**Fake 场景：** Property fake 提供内/外/恰 2,000m、pending/resolved；仅内/边界 pending 计入。partial/failure 不返回 0，Property 保留旧原子快照并显示不可用。

## 4. 数据与固定流程

| 目的 | 权威对象 / 精确访问 | 固定语义 |
| --- | --- | --- |
| 报告 | `crowdsourced_hazards`；authenticated 读，author-only insert/delete/status update | 五类、WGS84、pending/resolved、report time；发布后内容/位置/时间/author 不可变；无审核/verified/rejected/维护者例外。 |
| 投票 | `crowdsourced_hazard_votes`；本人行读写、撤回删除 | `(hazard_id,user_id)` 唯一；`-1/+1`；一账户一票。 |
| 计数 | `hazard_vote_counts`；authenticated 执行的受控 `SECURITY DEFINER` RPC | 仅 hazard_id/upvotes/downvotes；安全/空 search_path、调用者验证、撤销 anon/default execute；不返回投票者身份。 |
| 私有本机状态 | `PRIVACY-001` 与 [data ownership](../system/data-ownership.md#privacy-barrier-参与者清单) | mine/vote view 与未完成请求按账户隔离并 close 清理；完全去身份公共缓存可留；业务写全在线。 |

固定顺序：① Shell 确认 opened；② 入口或 Map 合法长按经 `SHELL-001.submit` 开 composer；③ create 写远端，成功才 publish 图层/详情；④ public page 成功后 `LOCATION-002.contribute`，点击稳定 id 经 Shell 开详情；⑤ status/delete/vote 先收权威 outcome 再刷新；⑥ close 即阻断私有操作与晚到响应；⑦ Property 仅消费 HAZARD-002 complete available，和同坐标 SAFETY-001 一起自行保存。对应 `FLOW-05/06`。

## 5. 联合验收、Ready Gate 与变更

### Wave 5 验收分配（Issue #25）

| 场景 ID / 可观察结果 | 验证归属 | 所需依赖及用途 | 证据要求 | 负责 Owner | 最迟 Wave | 本模块证据/状态 | 联合证据/状态 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `AT-HAZARD-01` 创建、校验与恢复 | 两者 | 本期真实 Shell、Map、Supabase；测试 fake / HTTP mock | service、widget、Adapter；真实创建与长按路由 | A（Shell / Map 协作） | 5 | 测试及真实调用已通过；见 [验收报告](../../human/hazard-reporting-wave5-acceptance-2026-09-17.md) | 真实 Shell / Map 接入与双目标设备已通过 |
| `AT-HAZARD-02` viewport / 详情 / 多页 / partial | 两者 | 本期真实 MapLayerHost、Shell、Supabase；分页 / partial / stale fake | 公共页面、partial 保留、后页失败恢复、Refresh 第一页 / expired cursor 恢复、过期响应；真实图层贡献 | A（Map 协作） | 5 | Adapter / 图层测试及真实读取已通过 | 真实 Map 层、详情路由及双目标设备已通过 |
| `AT-HAZARD-03` 作者管理与返回语境 | 两者 | 本期真实 Shell / Supabase；页面 fake | status、确认 / 取消删除、immutable allow / deny、mine | A（Shell 协作） | 5 | widget / Adapter / 双账户 RLS 已通过 | 返回列表、地图及双目标设备已通过 |
| `AT-HAZARD-04` 投票 / 账户隔离 / scope close | 两者 | 本期真实 Auth、Privacy、Supabase；晚到响应 fake | 双账户改票 / 撤回 / 匿名拒绝；close 丢弃 A 响应 | A（Privacy 协作） | 5 | service / Adapter / 真实权限已通过 | 真实 Privacy 清理、旧 seam 阻断及双目标设备已通过 |
| `AT-HAZARD-05` online-only / 恢复 / 本地化与可访问性 | 两者 | 本期真实 App / 两目标设备；HTTP 离线边界注入；widget 文本缩放 | 失败保留输入、无队列；中英文、360dp / 200%、重启 | A（B 的 emulator 协作） | 5 | widget 测试已通过 | 双目标设备已通过 |
| `AT-PROP-03` 2km pending count 提供方 | 本模块 | 本期真实 Supabase；complete / partial HTTP mock | 1,999 / 2,000 / 2,001m、pending / resolved、radius / timestamp、无身份拒绝 | A | 5 | 真实 Haversine 边界和 Adapter partial 已通过 | 不适用；不替消费者写 snapshot |
| `AT-PROP-03` Property 原子 snapshot 联合 | 联合 | 后续 Wave Property + 官方 Safety consumer；本模块提供真实 HAZARD-002 | 同坐标两个 available 才存；失败保留旧 snapshot | B（Property 主责）；A（Hazard / Safety 协作） | 6 | 提供方 seam 已实现 | 待接入；Wave 6 到期，不阻塞 Hazard Implemented |

| Capability / canonical AT | 情景与操作 | 可观察完成条件 |
| --- | --- | --- |
| `HAZ-01` / `AT-HAZARD-01`、`AT-HAZARD-05` | 入口和合法长按创建；未选 type、trim 空/超长、非法点、离线 | 五类不预选；字段错误明确；online 成功才 created；失败留输入/重试，无离线伪队列。 |
| `HAZ-01`、`HAZ-04` / `AT-HAZARD-01`、`AT-HAZARD-03` | A status/delete；B/维护者尝试更新/改已发布字段 | 仅 A pending/resolved 与确认删除成功；内容/位置/时间/author 不可变；状态非审核，取消无副作用。 |
| `HAZ-02` / `AT-HAZARD-01`、`AT-HAZARD-02` | viewport、多页、点击、后页失败 | 图层/详情远端；empty/partial/failure 分开，成功页保留；点击/长按不改分析地点。 |
| `HAZ-03` / `AT-HAZARD-03`、`AT-HAZARD-04` | 两账户投票、改票/撤回；匿名/无效 caller、并发 | 一账户一票、counts 一致；枚举他票和无身份被拒；冲突/删除不虚构 count。 |
| `HAZ-04` / `AT-HAZARD-01`、`AT-HAZARD-03` | mine、定位、A close→B open、晚到请求 | 仅当前 author 管理；返回语境保留；A 私有状态不呈现/提交/重放到 B。 |
| `HAZARD-002` / `AT-PROP-03` | 内/外/恰 2km、pending/resolved、partial/failure | 只计含边界 pending；带半径/时间/available；partial/failure 非 0，不写部分 snapshot。 |

- [x] `HAZ-01`–`04`、`HAZARD-001/002`、D18–D20、Schema、`FLOW-05/06`、canonical `AT-*` 可双向追踪。
- [x] 唯一 import、声明、输入、typed outputs/failures、不可变、作者 status/delete、投票/RLS、账户隔离、顺序、示例/fake 均冻结；无函数体、SQL 或 SDK 实现。
- [x] `RISK-HAZARD-01` 两账户/匿名/search-path 与 `RISK-HAZARD-02` status-only migration/跨视图证据为实现/集成 Gate，不阻塞 Ready。
- [x] 独立 Standards/Spec 双轴复审通过；设计 AI 依 ADR 0013 批准 Ready。

公共 Interface 变更由提供方说明原因和受影响消费者，所有受影响消费者确认；同一 PR 更新声明、本契约、同名 HTML 与受影响 fake/Adapter 测试。Git/PR 保存历史；不引入独立发布、版本锁定或同步治理流程。

| 日期 | 状态 | 变更原因 | 受影响对象 | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Ready for Development` | Issue #14：冻结五类公共报告、发布后不可变、作者 status/delete、单票和 2,000m pending-only count | `HAZ-01`–`04`、`HAZARD-001/002`、Hazard 数据对象、Property | 设计 AI（项目负责人授权） |
| 2026-09-15 | `Ready for Development` | Issue #23 返工：收束为单一 Development Contract 与等价 HTML；改为引用 Shell、Map / Location 与 Account Privacy 的完整 canonical 声明并说明调用子集；移除 PDF、ADR 0014、handoff 与发布治理，产品/Schema 语义不变 | `HAZ-01`–`04`、`HAZARD-001/002`、`SHELL-001`、`LOCATION-002`、`PRIVACY-001`、同名 HTML | 设计 AI（项目负责人授权） |
| 2026-09-17 | `Implemented`（实现状态） | Issue #25 Wave 5：真实 Supabase Adapter / RPC、Auth 单一身份 FK、在线页面、Shell / Map / Privacy 接线、分页与恢复、权限及双设备证据；Luna High 双轴审查通过，设计 Ready 与产品口径保持 | HAZ-01–04、HAZARD-001/002、Schema Catalog、生产 root、公开测试、同名 HTML；Property consumer 留 Wave 6 | 项目负责人授权开发；GPT‑5.6 Luna High 完成度审查 |

### Wave 5 实现组织与可读性

唯一入口导出 contract 类型、scope-aware factories、runtime 和 root 注册的页面 / 图层寄宿 Widget。内部按 Domain 类型、Application service / runtime / Map layer controller、Data Supabase Adapter、Presentation ViewModel / View 分层；SDK 不进入 View 或消费者。图层只贡献 immutable item 与 provider intent，不修改分析地点。

手写 Dart 采用显式局部类型、完整方法体、显式构造初始化。必要例外：Flutter `super.key` 与 framework collection-if，marker 跨 library `implements ShellIntent`（Dart `interface` 限制）；`noSuchMethod` 只在明确未调用的测试 fake 操作中使用。生产能力没有 `UnimplementedError` 或 fake；在线写失败不排队。
