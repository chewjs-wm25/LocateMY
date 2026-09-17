# Home & Relocation Outlook 开发协作契约

> Owner：`A`<br>
> 模块实现：`Implemented`（2026-09-17）；集成状态：Home/Shell 当期子项通过，真实 Map 联验待 Owner A 于 Wave 4 完成，尚未批准 `Integrated`。<br>
> 依赖顺序：Wave 4；消费已冻结的 Application Shell `SHELL-001`，并向 Shell 提供 `HOME-001` 公共入口与 fake。<br>
> 定义完成：Shell 能只凭本文件读取、呈现和刷新全国首页结果，并安全提交“探索地图”意图；不需要 Home 的内部文件、Supabase Adapter 或缓存实现。

本文件是 Home & Relocation Outlook 唯一的跨 Owner 开发协作契约；同名 HTML 是供人阅读的等价导出，不是平行的发布或治理工件。它只固定可观察结果、公开 Dart seam、数据边界与联验；`lib/features/home_relocation_outlook/` 内的页面、状态管理、计算组织、缓存策略、并发/取消/重试和测试组织由 A 决定。公式正文只在产品知识库，字段、RLS 与迁移只在 Schema Catalog。

## 1. 任务成果

- 在已打开的主应用首页，用户可看到全国 `0–100` 搬家时机、状态、最多三条原因、三个宏观分项和家庭收入中位数；每项携带单位、真实观测日期、来源和可用性。
- 用户可以用按钮或下拉触发同一刷新语义；成功刷新后有 60 秒进程内冷却，失败保留已可用结果并如实标示缓存或过期状态。
- 用户可选择“探索地图”；Shell 只切换地图 Tab，不产生默认地点、坐标或分析目标。
- 包含 `HOME-01`、`HOME-02`、`HOME-03`；不拥有地点分析、个人化地点适配度、地图状态、语言偏好、认证门控或政府数据写入。

产品事实唯一来源：[首页](../../knowledge_base/locatemy_product/features/home.md)、[首页宏观指数](../../knowledge_base/locatemy_product/home_index_scoring.md)；系统追踪为 `HOME-001`、`D04`、`FLOW-08` 与 `AT-HOME-01`–`AT-HOME-03`。

## 2. 责任与依赖

| Owner | 负责 | 不负责 | 依赖次序 |
| --- | --- | --- | --- |
| Home & Relocation Outlook（A） | `HOME-001`、全国宏观读取、指数与原因、公共缓存、`STATE-HOME-REFRESH` | Shell 门控/导航、地图地点、语言、账户资料、镜像表写入 | Shell 先冻结 `SHELL-001`；A 先交付 Home seam/fake；Shell 再接入真实 Adapter。 |
| Application Shell（A） | 已打开账户范围的首页槽位、日期本地化、地图 Tab 切换及导航结果 | 宏观数据解释、公式、Home 缓存/冷却、资料可用性判定 | 只消费 `HOME-001` 的公开类型；仅在同账户 scope 为 `opened` 时呈现或触发读取。 |
| Supabase 公共读取对象 | 五个已导入资料集的只读输入 | 指数、缓存、Shell 呈现、Flutter 直读镜像表 | 仅 A 的 Home Adapter 调用 `read_home_metrics`。 |

Home 的受控实现边界是 `lib/features/home_relocation_outlook/`。消费者只使用下列公开入口；不导入该目录的 `src/` 或任何 Adapter 文件。

## 3. 需要调用 Interface

### `SHELL-001`：提交探索地图意图

**提供者：** Application Shell；**消费者：** Home；**唯一公开 import：** `package:locatemy/app/application_shell.dart`。下列是 [Application Shell 的 canonical `SHELL-001` 声明](../modules/application-shell.md#shell-001--application-coordination)；Home 只调用其中的 `submit`，不调用 `publish`，也不重述、缩窄或另定义任何 Shell 类型。

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

enum ShellRejectionReason {
  missingInput,
  staleInput,
  inapplicableDestination,
  scopeUnavailable,
}
```

`ApplicationShell`、两组 outcome、两种 marker 与 `ShellRejectionReason` 均归 Shell 所有；完整声明以链接的 Shell owning contract 为唯一规范。Home 从自己的唯一公开入口导出下列无地点 intent marker：

```dart
final class ExploreMapIntent implements ShellIntent {
  const ExploreMapIntent();
}
```

Home 只在用户明确选择“探索地图”、且当前 Home 呈现仍处于 Shell opened scope 时调用：

```dart
final ShellIntentOutcome outcome = await applicationShell.submit(
  const ExploreMapIntent(),
);
```

| 输入约束 | 输出 / typed failures | 状态与副作用 | 顺序、权限与最小处理 |
| --- | --- | --- | --- |
| 恒为无字段的 `const ExploreMapIntent()`；不得携带或生成城市、坐标、地点引用或分析目标。 | `ShellIntentAccepted` 表示 Shell 已切换地图 Tab；`ShellIntentRejected(reason)` 或 `ShellAuthenticationRequired` 是导航结果，不是 Home 数据失败。 | Shell 只更新其导航状态；Home 不改变结果、缓存、冷却或地点状态。 | 仅 opened 主应用可请求。被拒绝或需认证时留在首页并呈现原因；不得重试成隐式导航。 |

**Fake 场景：** Home 使用 fake Shell 分别返回 accepted、rejected 和 authentication-required；断言 accepted 只发出上述无地点意图，另外两种结果保持首页原状且可读出原因。测试不需要地图或真实 Shell。

## 4. 必须提供 Interface

### `HOME-001`：全国搬家时机与宏观首页

**提供者：** Home & Relocation Outlook（A）；**消费者：** Application Shell；**唯一公开 import：** `package:locatemy/features/home_relocation_outlook/home_relocation_outlook.dart`。

消费者只能 import 此入口。A 应先合入下列声明与最小 fake；这些是协作形状，不是可提交实现体。

```dart
abstract interface class HomeRelocationOutlook {
  Future<HomeLoadOutcome> load(HomeLoadRequest request);
}

enum HomeLoadRequest { cacheAllowed, refresh }

sealed class HomeLoadOutcome {}
final class HomeLoaded extends HomeLoadOutcome {
  final HomeOutlookSnapshot snapshot;
}
final class HomeRefreshCoolingDown extends HomeLoadOutcome {
  final HomeOutlookSnapshot snapshot;
  final int remainingSeconds;
}
final class HomeUnavailable extends HomeLoadOutcome {
  final HomeUnavailableReason reason;
}

final class HomeOutlookSnapshot {
  final HomeDataFreshness freshness;
  final HomeCompleteness completeness;
  final RelocationTimingCard relocationTiming;
  final MacroMetricCard costPressure;
  final MacroMetricCard employmentStability;
  final MacroMetricCard economicMomentum;
  final HouseholdIncomeCard householdMedianIncome;
  final DateTime fetchedAt;
}

enum HomeDataFreshness { fresh, cached, stale }
enum HomeCompleteness { complete, partial }
enum MetricAvailability { available, unavailable }
enum HomeUnavailableReason {
  retryableUnavailable, noCachedResult, sourceSchemaChanged, sourceDataUnverifiable,
}
enum MetricUnavailableReason {
  sourceMissing, sourceSchemaChanged, insufficientHistory,
  sourceDataUnverifiable, retryableUnavailable,
}

final class RelocationTimingCard {
  final MetricAvailability availability;
  final int? score;
  final String? scoreUnit;
  final String? status;
  final List<RelocationReason> reasons;
  final List<MetricSource> sources;
  final MetricUnavailableReason? unavailableReason;
}
final class RelocationReason {
  final String text;
  final MetricSource source;
}
final class MacroMetricCard {
  final MetricAvailability availability;
  final int? score;
  final String? scoreUnit;
  final String? directionExplanation;
  final MetricSource source;
  final MetricUnavailableReason? unavailableReason;
}
final class HouseholdIncomeCard {
  final MetricAvailability availability;
  final num? medianIncome;
  final String? currencyUnit;
  final int? surveyYear;
  final String? priceBasisExplanation;
  final MetricSource source;
  final MetricUnavailableReason? unavailableReason;
}
final class MetricSource {
  final String datasetId;
  final DateTime observedAt;
}
```

`HomeOutlookSnapshot` 的五个字段始终存在；`MetricAvailability.unavailable` 时该卡数值字段为 null，并提供分类原因。`HomeCompleteness.partial` 表示至少一张卡不可用，并与 `fresh`、`cached` 或 `stale` 的资料新旧事实独立；卡来源日期仍由 `MetricSource` 表示。

#### 输入与调用次序

| 调用 | 输入约束 | 调用者责任 |
| --- | --- | --- |
| `load(HomeLoadRequest.cacheAllowed)` | 仅在 Shell 已确认当前账户 scope 为 `opened` 后调用；无账户 ID、地点或语言输入。 | 可先呈现 `HomeLoaded` 中可用卡；按 Shell 当前语言格式化日期与文案，不篡改来源、单位或可用性。 |
| `load(HomeLoadRequest.refresh)` | 仅由按钮或下拉的明确用户动作触发；两个入口等价。刷新进行中不得并发重复触发。 | 接受 `HomeRefreshCoolingDown` 的剩余秒数，不再次强刷；失败不清空既有快照。 |

#### 输出、失败、状态与副作用

| 结果 | 可观察含义 | Shell 必须处理 |
| --- | --- | --- |
| `HomeLoaded(fresh)` | 可验证的在线结果；各卡保留各自观测日期。 | 显示真实资料日期、来源、单位和趋势/方向文字；不将异频资料伪装为同一日期。 |
| `HomeLoaded(cached)` / `HomeLoaded(stale)` | 可用公共缓存；stale 已过期。 | 明确标示 cached/stale、观测日期及 `fetchedAt`；不称为 fresh 或实时统计。 |
| `HomeLoaded(snapshot.completeness == partial)` | 其他卡可用，至少一张卡有分类 unavailable。 | 保留每张可用卡；不以零补未知。三项主分项任一 unavailable 时综合卡也 unavailable；收入卡缺失不阻断主分项。 |
| `HomeRefreshCoolingDown` | 上次成功 refresh 后 60 秒内的同一快照与剩余整秒。 | 显示剩余秒数并阻止重复强刷；可继续显示快照。 |
| `HomeUnavailable` | 无可安全呈现的结果。 | 显示分类原因与重试入口；不得展示样例、固定数值或伪造 fresh。 |

- A 只读 `read_home_metrics`，仅读写无账户字段的 `home_public_cache`，并在进程内拥有 `STATE-HOME-REFRESH`；退出可保留公共缓存，重启不恢复冷却倒计时。
- 一次成功 `refresh` 才开始 60 秒冷却。网络失败、资料不可验证、字段变化或无结果均不报告刷新成功；在线结果只以资料日期更近者替换缓存。
- 综合分仅在三项主分项均可用时提供；原因最多三条，按模型影响排序。家庭收入中位数为背景卡，绝不参与综合分。
- Home 不读取账户资料、不写政府镜像表、不执行导航、不生成地点，也不把缓存或一次性导入称为官方实时统计。

#### 最小调用示例（Shell）

```dart
final outcome = await homeRelocationOutlook.load(HomeLoadRequest.cacheAllowed);
switch (outcome) {
  case HomeLoaded(:final snapshot):
    // 保留每张卡的 availability、source、observedAt 与 freshness。
  case HomeRefreshCoolingDown(:final remainingSeconds):
    // 呈现剩余秒数，不再次发起 refresh。
  case HomeUnavailable(:final reason):
    // 显示分类原因与可访问的重试入口。
}
```

**Fake 场景：** Shell 以 fake `HomeRelocationOutlook` 返回：（1）三主分项与收入均 available、异频日期的 fresh snapshot；（2）一个主分项 unavailable 的 partial snapshot；（3）stale snapshot；（4）`HomeUnavailable(noCachedResult)`；（5）`HomeRefreshCoolingDown(remainingSeconds: 42)`。断言分别保留日期/来源、使综合卡 unavailable 而保留其他卡、标示 stale、提供重试、显示 42 秒且不再调用 refresh；无需 Supabase 或 A 的生产计算。

## 5. 直接使用数据

| 对象 / 事实源 | 访问者与权限 | 用途 | 不可改变的语义 |
| --- | --- | --- | --- |
| [`read_home_metrics`](../data/schema-catalog.md#稳定公共读取对象) | 仅 A 的 Home Adapter；authenticated、security-invoker、只读 | 取得 CPI、劳动力、经济指标、实际 GDP 与家庭收入五个资料集。 | Flutter 不直读政府镜像；结果用每个资料集实际最大 `date`，不是 Supabase 刷新时间或目录年份。 |
| [`home_public_cache`](../data/schema-catalog.md#本机对象) | 仅 A；无账户字段，退出保留 | 保存公共 result payload/version、各 source date、fetched at、expiry/completeness。 | 不保存账户 ID、地点、自由文字或私有资料；在线只以较新资料替换。 |
| `STATE-HOME-REFRESH` | 仅 A；页面/进程内存 | 加载、刷新与成功后的 60 秒冷却。 | 重启不恢复；不跨账户传递 Home 呈现状态。 |
| [首页宏观指数](../../knowledge_base/locatemy_product/home_index_scoring.md) | A 应用；Shell 仅呈现结果 | 三主分项、综合、原因、趋势与家庭收入背景语义。 | 严格遵循五年/最小历史、百分位、重归一化、60% 权重门槛、取整和综合条件；公式正文不复制到此处。 |

## 6. 推荐实现顺序

1. **A：先合入公共 seam。** 创建唯一入口、上述声明和最小 fake；Shell 不依赖 A 的内部文件。
2. **Shell：用 fake 完成首页槽位。** 处理 loaded、partial、stale、unavailable、冷却及探索地图的 accepted/rejected/authentication-required。
3. **A：实现实际读取与模型。** 只经 `read_home_metrics` 取得输入，按知识库应用模型；实现公共缓存、成功刷新冷却和来源元数据。
4. **共同联调。** 在 opened scope 下接入实际 seam，执行下节的 Interface 级场景；只为该联验保留跨 Owner 流程测试。

## 7. 联合验收

| 场景 | 参与 Owner | 操作 | 可观察结果 | 追踪 |
| --- | --- | --- | --- | --- |
| 完整首页与异频资料 | A、Shell | opened scope 后读取；三主分项和收入均可用，但月/季/年日期不同。 | 全国 `0–100`、状态、最多三条原因和卡片均显示；每项显示真实日期、来源、单位/方向；不称为实时或同一观测期。 | `HOME-01`、`HOME-02`；`AT-HOME-01`、`FLOW-08` |
| partial 与缺失边界 | A、Shell | 分别令主分项、收入、字段或历史资料不足。 | 每一失败卡有分类 unavailable；任一主分项使综合 unavailable，其他卡保留；收入缺失不阻断主分项；未知不置零。 | `HOME-01`、`HOME-02`；`AT-HOME-01` |
| 缓存与无缓存失败 | A、Shell | 网络失败时分别存在 cached/stale 快照或没有快照。 | 前两者明确资料日期与上次成功时间；无缓存时显示 retryable unavailable 和重试；均不伪造 fresh。 | `HOME-01`、`HOME-02`；`AT-HOME-01`、`FLOW-08` |
| 双入口刷新与冷却 | A、Shell | 依次使用按钮、下拉、进行中重复动作、60 秒内 refresh、刷新失败。 | 两入口调用相同 request；成功后显示剩余秒数，重复强刷被阻止；失败保留既有结果并不报告成功。 | `HOME-03`；`AT-HOME-02`、`FLOW-08` |
| 门控、范围关闭与探索地图 | A、Shell | 在 opened、未认证、scope 关闭时进入首页；再选择探索地图并注入 Shell 拒绝。 | 仅 opened 时读取/呈现；关闭后旧结果不进入后续账户；accepted 只切地图 Tab、不设地点；拒绝仍在首页且可读原因。 | `HOME-01`–`HOME-03`；`AT-HOME-03`、`D04`、`FLOW-08` |

### 7.1 Wave 4 验收分配

项目负责人于 2026-09-17 确认四个 TDD seam：HOME-001 load、首页公开页面、Home/真实 Shell 公开组合入口、通过 HOME-001 真实 RPC 及数据库权限。仅在这些边界观察行为；外部 HTTP、SQLite 和时钟可使用确定性 Adapter。

| 场景 / 可观察结果 | 验证归属 | 依赖分类 | 证据要求 | Owner | 最迟 Wave | 本模块状态 | 联合状态 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| HOME-W4-01 完整首页、独立数据日期/来源/单位、模型与原因 | 两者 | 本期真实 RPC/Home/Shell；HTTP 测试边界 | load 已知例、页面、live 与设备 | A | 4 | 已通过；见 7.3 | Home/Shell 当期子项已通过；见 7.3 |
| HOME-W4-02 缺失/字段变化/历史不足、60% 门槛、收入独立 | 两者 | 本期真实计算；HTTP 确定性数据 | load 与页面保留可用卡、未知不置零 | A | 4 | 已通过；见 7.3 | Home/Shell 当期子项已通过；见 7.3 |
| HOME-W4-03 cached/stale/无缓存、较新替换、进程重启 | 两者 | 本期真实 SQLite；网络故障测试边界 | 持久缓存/失败恢复、离线设备 | A | 4 | 已通过；见 7.3 | Home/Shell 当期子项已通过；见 7.3 |
| HOME-W4-04 双入口刷新、进行中去重、仅成功60秒冷却 | 两者 | 本期真实 Home/Shell；测试时钟/网络 | load、按钮/下拉、失败保留、设备 | A | 4 | 已通过；见 7.3 | Home/Shell 当期子项已通过；见 7.3 |
| HOME-W4-05 opened门控、关闭丢弃响应、无地点探索/拒绝 | 两者 | 本期真实 Auth/Privacy/Shell/Home；Map 后续槽位 | 公开组合测试与设备关闭/重启；真实 Map 联验 | A | Home/Shell 4；Map 4 | 已通过；见 7.3 | Home/Shell 已通过；真实 Map 待接入，A / Wave 4 |
| HOME-W4-06 中英日期/动态状态、小屏200%、文字可读性 | 本模块 | 本期真实本地化 | Widget与两目标设备 | A；B模拟器 | 4 | 已通过；见 7.3 | 不适用 |
| HOME-W4-07 外部映射和RPC读权限、镜像写入/匿名deny | 本模块 | 本期真实开发环境；HTTP确定性错误 | 官方schema/键/行数/日期审计、live allow/deny | A | 4 | 已通过；见 7.3 | 不适用 |

Map 的地图状态和真实页面不在本任务开发范围；其 Wave 4 联合责任仍由 A 承担，Home 不制造地点或成功占位。

### 7.2 Wave 4 实现接线

Feature 分层实现 HOME-001：Domain 管理百分位、历史、权重和卡片规则；Application use case 管理读取、去重、缓存替换、降级与成功冷却；Data Adapter 隔离 Supabase/SQLite；HomeViewModel 管理呈现和用户动作，公开 HomeOutlookPage 提供 Shell 首页槽位。
唯一公开入口补充生产装配 factory 和页面 helper；HOME-001/SHELL-001 的成员和结果不变。
测试 fake 仅位于 test/support，不接入生产。SQLite TTL 为 24 小时，成功冷却仅内存保存。

组合根在每个 opened scope 创建独立 Home provider/ViewModel，以弱 scope key 复用当前页面；只共享无账户字段的持久公共缓存，旧账户请求不与新账户合并。探索 marker 由组合根精确投影为 Map Tab，不构造地点、分析语境或默认坐标。
页面中英文同等呈现各自数据日期、来源/单位、方向、原因与 fresh/cached/stale/partial/typed failure；指数有文字和读屏摘要，不只靠颜色。三个宏观图按各自最后六个月的有效观测重算，明确标示 currentObservationsApproximation，逐期日期/分数可供读屏；缺失月不复制前值，缓存重启缺少序列时显示趋势不可用和方向摘要。

当前官方 GDP CSV 只有 abs，RPC 不将其作为 growth_qoq；经济动能使用其余可用 70% 原权重归一化。这是可用输入的如实处理，不改变模型、数据或公共结果。

### 7.3 Implemented 验收记录（2026-09-17）

四个已确认测试边界均通过：HOME-001 公开 load（26 项）、公开页面（6 项）、真实 Shell 组合（2 项）、真实 Supabase RPC/权限（1 项 live）；另有真实 provider 的趋势页面测试 2 项。共 36 项定向测试、145 项全量通过（5 项显式 opt-in 跳过）；Home live 单独启用通过。格式、静态分析、diff 检查和普通 debug APK 构建通过。

Owner A 真机及 Owner B 目标模拟器均通过：首页双语、实际下拉刷新/冷却、离线 stale、过期公共缓存进程重启、在线恢复、无地点 Map Tab/返回、关闭 scope 后旧意图拒绝。正常 APK 已恢复、测试账户已清理；凭据扫描通过。

历史月/季窗口回退、GDP schema/data 异常不成功冷却、缓存分数/日期损坏拒绝、SQLite 临时失败恢复和跨 scope 晚到写入回退防护均有公开 TDD 证据。稳定诊断事件仅含固定分类、耗时桶和生成关联号，敏感字段 deny-list 测试通过。

基线 HEAD `66f4ffc1e9392a1cdf9e01b054cbd81b713e82b9`；测试/live/两设备及 APK 的 App source SHA-256 为 `931fc6856e6301ea59975c2ca7ceee2ecf918c559d54f909ca8a8d449424ac1a`，迁移和 Python runner 另有 revision 清单。
证据：[验收报告](../../human/home-and-relocation-outlook-wave4-acceptance-2026-09-17.md)、[GPT-5.6 Luna High 两轴审查](../../human/home-and-relocation-outlook-wave4-review-2026-09-17.md)、[命令与版本](../../human/evidence/home-and-relocation-outlook-wave4-2026-09-17/checks.source.json)、[设备与清理](../../human/evidence/home-and-relocation-outlook-wave4-2026-09-17/device-verification-summary.json)、[迁移/工具版本](../../human/evidence/home-and-relocation-outlook-wave4-2026-09-17/schema-and-tool-revision.json)。

Home 模块当前阻塞：无。整个 Wave 4 尚未完成：真实 Map 页面及 HOME-W4-05 完整联合场景仍由 Owner A 在 Wave 4 交付，不能把 Tab 槽位证据当作真实 Map 联验或 Integrated 批准。

### 7.4 Penpot 首页风格对照（2026-09-17）

通过 Penpot MCP 读取 `LocateMY Mobile UI` / `02 · 首页`（board `f8bc3597-5a95-809e-8008-a3e627fc0313`），实现 Source Sans Pro、蓝色/深蓝色与浅灰底、评分卡 20 圆角、指标卡 14 圆角、探索按钮前置和 Shell 品牌/账户/导航样式。真实指标、独立日期、收入与趋势继续遵守合同；200% 字号采用自适应布局。

UI 更新后全量 146 项通过、5 项 opt-in 跳过，live 1 项通过；静态分析与格式检查通过。Owner A 真机和 Owner B 模拟器均通过双语、实际下拉/冷却、离线/重启/恢复、探索与 scope 关闭；普通 APK 恢复、临时凭据清理及扫描通过。GPT-5.6 Luna High 的 Spec/Standards 两轴均通过；Home 维持 Implemented，真实 Map 联验责任不变。

当前含字体 App SHA-256：`aa0ebdfff9b062e5c0c499d5f6f9ff732b78a37605cc99e1f9e91df8af183825`；7.3 为此前核心实现记录。[UI 对照报告与截图](../../human/home-penpot-alignment-2026-09-17.md)、[最终设备记录](../../human/evidence/home-penpot-alignment-2026-09-17/penpot-device-summary.json)。

## 8. 内部自由

A 可决定 Feature 内的文件拆分、Widget、状态管理、Adapter、缓存序列化、TTL、请求调度、取消、重试、去重、局部验证和测试组织。Shell 可决定其槽位布局、日期本地化和导航 UI。以下事项须先协商：唯一公开 import、公开声明/结果变体、60 秒成功冷却、三主分项/收入的可用性边界、来源元数据、探索地图的无地点约束、`read_home_metrics`/`home_public_cache` 的 schema 或权限。

## 9. 阻塞与权威参考

**当前阻塞项：无。** `read_home_metrics` 与 `home_public_cache` 已实现：官方 schema/键/行数、最大日期与完整/部分/空输入由 Schema Catalog 的 Home Wave 4 条目及验收证据追踪。运行时依赖、离线与可访问性证据由 `RISK-NFR-01` 在实现/集成验收关闭；它们不改变本契约。

权威参考：[Application Shell](../modules/application-shell.md#shell-001--application-coordination)、[系统 Interface 注册表](../system/interfaces.md)、[FLOW-08](../system/flows.md#flow-08首页刷新与探索地图)、[Capability 追踪](../system/capability-traceability.md)、[数据所有权](../system/data-ownership.md)、[Schema Catalog](../data/schema-catalog.md#稳定公共读取对象)、[风险与决定](../system/risks-and-decisions.md)、[首页产品事实](../../knowledge_base/locatemy_product/features/home.md)、[指数事实](../../knowledge_base/locatemy_product/home_index_scoring.md)。

### Ready 检查

- [x] Owner、消费者、受控边界和 Wave 4 依赖次序明确。
- [x] `HOME-001` 与消费的 `SHELL-001` 均有唯一公开 import、声明或精确调用、输入约束、typed 结果/失败、状态/副作用、次序、权限、最小示例与 fake 场景。
- [x] `read_home_metrics`、`home_public_cache`、`STATE-HOME-REFRESH` 和模型的访问/权限/数据边界均链接唯一权威，且不复制字段、RLS、迁移或公式正文。
- [x] 联合验收覆盖完整/partial、缓存/无缓存、双入口刷新与冷却、范围门控和无地点地图导航，双向追踪 `AT-HOME-01`–`AT-HOME-03`。

## 10. Change Log

| 日期 | 状态 | 变更原因 | 受影响对象 | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Ready for Development` | 初始 Feature 协作设计冻结。 | `HOME-001`、`SHELL-001`、`FLOW-08` | 项目负责人 |
| 2026-09-15 | `Ready for Development` | Issue #23 单一 Development Contract 复审：移除旧 PDF/ADR 0014/handoff 发布治理表述，改为同名等价 HTML；消费卡改为引用并完整镜像已冻结的 canonical `SHELL-001` 声明，明确 Home 仅调用 `submit`。 | `HOME-001`、`SHELL-001`、Home HTML、`FLOW-08` | 设计 AI（项目负责人授权） |
