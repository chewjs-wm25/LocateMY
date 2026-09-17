# Infrastructure Coverage 开发契约

> Owner：B；依赖顺序参考 Wave 6；2026-09-17 Issue #31 修订。
> 状态：Ready；生产实现及验收证据已交付，待 Luna High 独立审查判定 Implemented。

本契约按 [Issue #31](https://github.com/chewjs-wm25/LocateMY/issues/31) 与
[ADR 0017](../../adr/0017-minimal-account-and-online-user-records.md) 修订。
产品事实和公式以知识库为准；字段、权限和 migration 只在
[Schema Catalog](../data/schema-catalog.md) 定义。普通页面传参与具名服务替代通用导航／贡献框架。

产品事实源：[infrastructure](../../knowledge_base/locatemy_product/features/infrastructure.md)。

## 本轮分析页面精简（2026-09-17）

界面按 [UI 精简边界](../../knowledge_base/locatemy_product/ui_design_spec.md#分析页面精简边界2026-09-17) 调整；该节取代本契约中冲突的来源／时间／较旧提示展示要求。
指标、公式、输入、缓存时效和服务可用性不变。保留内部来源与日期用于取数／校验，取消用户页面技术明细，保留简短错误与重试。
验收沿用页面和公开服务边界，核对单点与 A/B 均无技术元数据／重复提示，并回归现有缓存、公式、失败恢复与账户行为。此轮仅更新文档，代码调整及验证待后续任务执行。

## 本期生产行为

保留供水／供电、医疗、教育和交通分项及 ICI；官方行政区资料与地点交通半径分别标示。
[ICI 模型](../../knowledge_base/locatemy_product/infrastructure_index_scoring.md) 固定公式、分项、60% 门槛与缺失处理。
医疗／教育／交通三个账号权重整数 1–10，默认 5，在线保存；当前页 preview 可变化，但失败不冒充保存成功。
权重只影响基础设施单点 ICI；地点摘要和 A/B 必须用中性权重，不改变原始分项。
交通复用 PublicTransportation 的 canonical 结果，不再计算另一份交通分。
唯一入口 `lib/features/infrastructure_coverage/infrastructure_coverage.dart`；消费明确地点、Geo、
PublicTransportation 服务与 SDK 当前账号，不消费 AccountScope、Shell、五项评估偏好或 Suitability。

## 公开入口与联合责任

实际 declarations 已固定于唯一 Dart 入口；读取 RPC 与三权重 migration 已部署真实开发 Supabase。生产装配消费现有 Geo/Transit/SDK，证据见本期报告。
本模块：原始统计、缺失与有效零、60% 门槛、三个默认／边界／在线保存失败、preview；
联合：A/B 和摘要中性读数、同坐标交通复用、换号权重重新读取，B 主责、A 配合；最迟 Wave 6。
旧数据库五个 0–1 权重不能视为目标三权重实现。

## 已固定公开 declarations

- `createInfrastructureCoverage(geographicContext, reader, transportation, weightsStore, database?, clock?)` 构造真实可注入的 `InfrastructureService`。
- `InfrastructureService.fetch(location, analysisDate, {policy, weights})` 返回 `InfrastructureLoadOutcome`；`summary(location, date)` 和 `compare(a, b, date, {policy})` 永远使用中性三权重，不读取账户草稿。
- `InfrastructureCoverage.score` 为可空整数；五项 `InfrastructureCategoryScore.score` 为可空完整精度读数，缺失列表及真实解析的州/行政区跟随结果。Coverage.sourceYears/populationYears由公开构造防御性复制为不可变Map，保留分项及人口实际统计年，预览及A/B仍保留；统计年份差异按精简边界集中说明。`InfrastructureAvailable` 表示满足3/5门槛；`InfrastructurePartial` 保留可用分项且综合为null；`InfrastructureUnavailable` 是短可重试失败。
- `InfrastructureInputsReader.read(state, district)` 隔离只读RPC；`InfrastructureWeightsStore.read/save` 隔离账户线上记录。SQLite公开缓存无需跨Owner业务消费。
- `InfrastructureCoveragePage(service, location, analysisDate, {locationB})` 是实际普通路由页面；单点保存/预览，A/B不建立权重编辑器。ViewModel公开动作保留于同一入口便于现有消费者测试，跨Feature不得导入src。

## 生命周期与验收责任

页面只在登录后的业务树内建立；退出成功或换账号后结束旧业务页面，新页面按当前 SDK 用户读取记录。
Widget／ViewModel 在 dispose 后忽略晚到结果。账号记录只在线保存，网络失败显示未保存并允许用户重试；
不建立自动同步、清理屏障或离线队列。公共分析内部保留真实来源、日期与可用性，不以零替代缺失；呈现按本轮 UI 精简边界。

主要验收 seam 为应用页面入口；使用可见内容、动作、导航与保存／读取结果断言。
复用仍有效的公式、地理、Adapter 与存储测试，完成格式、分析、测试、debug APK 构建。
本次重构的统一证据见 [Issue #31 执行检查](../system/issue-31-validation.md)；
设备、真实外部服务证据缺失时不得宣称新版本 `Implemented` 或 `Integrated`。

## 开发前 Ready Gate 与验收分配（2026-09-18）

本期固定最高公开 seam：InfrastructureService.fetch/compare/summary、账号权重 read/save、应用 InfrastructureCoveragePage。Issue #25 已确认最高公开 Interface，当前用户授权自主决策，Owner B 确认以下 seams。采用逐个公开行为 red → green；Adapter 仅验证 SDK 外部映射与权限。Ready Gate：公式/Geo/Transit 已固定；新增只读原始输入 RPC、三权重 additive migration；教育源空数组表示缺失。UI 对照 Penpot `09 · 基础设施`（f8bc3597-5a95-809e-8008-a3fa95046be3）。

| 场景 / 可观察结果 | 验证归属 | 依赖与用途 | 证据要求 | Owner | 最迟 Wave | 本模块状态 | 联合状态 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 原始行政区统计、零/缺失、人口年份、百分位、基础权重60% | 本模块 | 本期真实Geo/RPC；测试fake原始观测 | 公开service确定性测试/live | B | 6 | 已通过，见报告 | 不适用 |
| canonical交通复用且日期/坐标一致 | 两者 | 本期真实Transit；测试fake | service测试/live同坐标读取 | B，A参与 | 6 | 已通过，见报告 | 本期真实接线已通过，见报告 |
| 默认5、1–10边界、保存失败/重试、preview/恢复 | 本模块 | 本期真实SDK/RLS；测试fake权重 | 页面/service测试；真实allow/deny | B | 6 | 已通过，见报告 | 不适用 |
| A/B与摘要始终中性，分项不变 | 两者 | 本期真实页面/中性服务；未来首页摘要消费者 | service/Widget测试；设备A/B | B，A参与 | 6 | 已通过，见报告 | 首页完整摘要由A后续Wave6接入 |
| 登录门控、换号重新读取、dispose/过期响应 | 两者 | 本期真实登录树/SDK | Widget与两账户live/设备 | B，A参与 | 6 | 已通过，见报告 | 本期真实接线已通过，见报告 |
| 离线公共缓存/刷新恢复、短错误重试、中英文/放大文字/读屏 | 本模块 | SQLite公开输入3日缓存；真实设备 | 缓存/Widget测试/设备 | B | 6 | 已通过，见报告 | 不适用 |
| 格式/analyze/tests/debug APK/Java可读性 | 本模块 | Flutter工具链 | 命令与版本证据 | B | 6 | 已通过，见报告 | 不适用 |

本期证据：[Infrastructure Wave 6 报告](../../human/evidence/infrastructure-coverage-wave6-2026-09-18/report.md)。声明/SDK Adapter/页面均通过唯一入口导出；Implemented 独立审查待主Agent安排，Integrated 不自动批准。

Luna Spec三项阻塞修复证据见报告复审节：每数据集独立最新有效完整聚合、每cache key串行写防旧完成覆盖、分项/人口真实年份及必要呈现；待复审，不提前宣告Implemented。
