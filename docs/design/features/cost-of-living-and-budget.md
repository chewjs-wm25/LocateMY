# Cost of Living & Budget 开发契约

> Owner B；Wave 5；Implemented；GPT‑5.6 Luna High 规格与规范复审通过（2026-09-18，代码 `bbf2e6e`）；Integrated 未批准。

本契约按 [Issue #31](https://github.com/chewjs-wm25/LocateMY/issues/31) 与
[ADR 0017](../../adr/0017-minimal-account-and-online-user-records.md) 修订。
产品事实和公式以知识库为准；字段、权限和 migration 只在
[Schema Catalog](../data/schema-catalog.md) 定义。普通页面传参与具名服务替代通用导航／贡献框架。
产品事实源：[生活成本与预算](../../knowledge_base/locatemy_product/features/cost_of_living.md)、
[生活篮子 v1](../../knowledge_base/locatemy_product/cost_basket_v1.md)。

## 本轮分析页面精简（2026-09-17）

界面按 [UI 精简边界](../../knowledge_base/locatemy_product/ui_design_spec.md#分析页面精简边界2026-09-17) 调整；该节取代本契约中冲突的来源／时间／较旧提示展示要求。
指标、公式、输入、缓存时效和服务可用性不变。保留内部来源与日期用于取数／校验，取消用户页面技术明细，保留简短错误与重试。
验收沿用页面和公开服务边界，核对单点与 A/B 均无技术元数据／重复提示，并回归现有缓存、公式、失败恢复与账户行为。本期生产页面按此边界实现并验证。

## 单点、A/B 与在线预案

保留本地价格、统一核心篮子 RM/月、相对同组全国基准的成本指数与当前预案的预算压力。
缺失项目不补零／最近月份／州或全国价；每月以实际有地点价格且有全国代表价的同一商品子集计算部分篮子指数。资料不完整仍显示部分篮子指数及部分篮子预算压力，并提示不完整、显示可观测项目数（/11）和月份数；住房、交通或月净收入缺失仍不能计算预算压力。
A/B 保持同篮子／来源日期／当前预案口径并列；各边可直接显示部分篮子指数，但须保留其各自资料不完整提示，不能暗示观察到相同商品集合。
没有 current 时仍可查看成本；不以临时金额或默认预案制造预算压力。
预算预案在线新增、编辑、重命名、选择和删除；名称 1–120，金额可空且非负，null 与零区分。
账户至多一份 current，删除 current 后不自动选另一份，最后一份允许删除。
月净收入只供个人预算压力；家庭月度总收入只供社会经济收入位置，不能互代或猜测补齐。
选择成功后依赖读数更新，失败保留上次已保存选择并显示失败；无账号同步队列。

## 服务与接线

唯一入口 `lib/features/cost_of_living_budget/cost_of_living_budget.dart`。
B 提供具名成本／预算服务、当前预案读取和成功修改的变化通知；A 页面通过 location／A/B 参数组合结果。
Account 与 Socio 仅读 current 服务，不各自写预案表。接口需在开发前固定实际可编译声明及字段映射；
本次不保留庞大的旧 Shell／Privacy／Suitability declarations，不宣称它们 Ready。
公共模型缓存可用 SQLite，预案及个人输入不能进入公共缓存。

## 后续验收分配

| 可观察场景 | 责任／证据 | 最迟 |
| --- | --- | --- |
| 成本口径、部分篮子指数／压力、缺失、有效零和 A/B 提示 | B 本模块；公式与页面测试 | Wave 5 |
| 在线预案 CRUD、current 唯一／删除、失败不切换 | B 本模块；页面与真实归属 smoke | Wave 5 |
| 临时换算无预案可用、同月与缺失失败、不写入 | B 本模块；页面行为 | Wave 5 |
| Account current、预算压力与 Socio 家庭收入位置随切换更新 | B 主责、A 接线联合验证 | Wave 6 |

预算业务本期实现，验收证据见本次交付报告。预算 JSON 导出与本机文件读取已于 2026-09-18 按用户要求移除。
## 生命周期与验收责任

页面只在登录后的业务树内建立；退出成功或换账号后结束旧业务页面，新页面按当前 SDK 用户读取记录。
Widget／ViewModel 在 dispose 后忽略晚到结果。账号记录只在线保存，网络失败显示未保存并允许用户重试；
不建立自动同步、清理屏障或离线队列。公共分析内部保留真实来源、日期与可用性，不以零替代缺失；呈现按本轮 UI 精简边界。

主要验收 seam 为应用页面入口；使用可见内容、动作、导航与保存／读取结果断言。
复用仍有效的公式、地理、Adapter 与存储测试，完成格式、分析、测试、debug APK 构建。
本次重构的统一证据见 [Issue #31 执行检查](../system/issue-31-validation.md)；
设备、真实外部服务证据缺失时不得宣称新版本 `Implemented` 或 `Integrated`。


### 为 Socio 本期固定的最小只读 current 边界

`CurrentBudgetReader.readCurrent(): Future<BudgetScenariosOutcome>` 与 `watchCurrent(): Stream<BudgetScenariosOutcome>` 从唯一入口导出。
`createSupabaseCurrentBudgetReader(client)` 提供真实 owner-only 在线读取；null 家庭收入与 0 区分，网络失败 typed unavailable，不以月净收入替代。
观察期间每 10 秒在线检查已保存的 current；消费者取消订阅后停止。当前读取与预算 writer 共用同一真实 store；本期联合验证覆盖成功变更通知及 Socio 的独立家庭收入用途。
完整预算 CRUD 与成本服务现已实现；字段以 Schema Catalog 为准。

## 本次开发固定范围（2026-09-18）

Ready Gate 自主固定：沿用 COST-001、COST-002 与 CurrentBudgetReader。
最高验收 seams 为上述服务和应用页面；Issue #25 Q2 已确认此策略，本次用户授权自行决策。
生产成本 factory 注入 GeographicContext、CostPublicReader、CurrentBudgetReader、可选 SQLite；
预算 factory 注入 SupabaseClient，同一 writer 实现 CurrentBudgetReader 并在成功变更后通知消费者。

| 场景 ID / 可观察结果 | 验证归属 | 依赖与证据 | Owner / 最迟 | 本模块状态 | 联合状态 |
| --- | --- | --- | --- | --- | --- |
| C01 商户双中位数、固定11项、逐月/12月部分子篮子指数与不完整提示 | 本模块 | 本期真实RPC/SQLite；服务公式与live | B / Wave 5 | 已验证 | 不适用 |
| C02 current住房/交通缺失、有效零、两个收入与连续压力 | 两者 | 本期真实Budget；服务/页面 | B / Wave 5 | 已验证 | Wave 6 共享接线及真实 Cost/Socio/Account 联验通过 |
| C03 A/B同篮子/日期/current与不可比、过期响应 | 本模块 | 真实Geo/RPC；服务/页面 | B / Wave 5 | 已验证 | 不适用 |
| B01 在线CRUD/current原子唯一、失败保留、删除不自动选 | 本模块 | Supabase开发环境allow/deny与恢复 | B / Wave 5 | 已验证 | 不适用 |
| B02 成功通知与Account/Socio立即联动 | 两者 | 本期真实writer/reader接线、设备 | B主责 A参与 / Wave 6 | 已验证 | 本期writer/reader、Account current设备及Socio live已验证；Wave 6 真实选择及缺失联验通过 |
| U01 中英文小屏200%/读屏、离线权限恢复、dispose晚响应 | 本模块 | emulator-5554/页面测试 | B / Wave 5 | 已验证 | 不适用 |
| H01 地图地点摘要消费（按现行 UI 事实源修正消费者） | 联合 | 本期真实Map与Cost | A主责 B参与 / Wave 6 | 不适用 | 已接线；summary integration 测试与设备验证，见全模块报告 |

Penpot 已读取 Mobile UI 的 05生活成本与UI Foundations，导出实际截图；沿用 SourceSansPro、#F6F8FB、#172033、#155EEF、#0B1F44、16px圆角、16px页面边距。按精简边界移除日期来源技术字段，按事实源修正原型fixture的RM指数与压力等级。

2026-09-18 全模块联合：共享 CurrentBudgetReader 的在线预案切换已真实验证 Cost 月净收入压力与 Socio 家庭收入位置，零值及缺失保持原义；账户展示五金额并进入预算管理。证据见 [全模块报告](../../human/integration-2026-09-18.md)。
