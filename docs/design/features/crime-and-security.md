# Crime & Security 开发契约

> Owner：B；依赖顺序参考 Wave 5；2026-09-17 Issue #31 修订。
> 状态：Implemented；Wave 5 本期责任验收通过；Integrated 尚待项目负责人批准。

本契约按 [Issue #31](https://github.com/chewjs-wm25/LocateMY/issues/31) 与
[ADR 0017](../../adr/0017-minimal-account-and-online-user-records.md) 修订。
产品事实和公式以知识库为准；字段、权限和 migration 只在
[Schema Catalog](../data/schema-catalog.md) 定义。普通页面传参与具名服务替代通用导航／贡献框架。

产品事实源：[crime_security](../../knowledge_base/locatemy_product/features/crime_security.md)。

## 本轮分析页面精简（2026-09-17）

界面按 [UI 精简边界](../../knowledge_base/locatemy_product/ui_design_spec.md#分析页面精简边界2026-09-17) 调整；该节取代本契约中冲突的来源／时间／较旧提示展示要求。
指标、公式、输入、缓存时效和服务可用性不变。保留内部来源与日期用于取数／校验，取消用户页面技术明细，保留简短错误与重试。
验收沿用页面和公开服务边界，核对单点与 A/B 均无技术元数据／重复提示，并回归现有缓存、公式、失败恢复与账户行为。本次 Wave 5 已按该边界实现单点/A-B 页面；证据见验收报告。

## 当前实现与公开行为

按地点所属统计州聚合 crime_district 的警区原始记录；不解析警区多边形。
保留州级安全指数、类别与趋势、必要年份／完整性和 A/B；重复年份可集中表达，取消技术来源明细。未知、年份不足或来源不可验证时不补零。
[治安事实源](../../knowledge_base/locatemy_product/features/crime_security.md) 是公式与口径权威。
唯一公开入口 `lib/features/crime_security/crime_security.dart`；使用具名安全分析服务，
显式输入合法地点／地理语境，提供州级可用／部分／不可用结果供页面与房产新增／坐标修改使用。
实际 declarations 见唯一入口代码；不要求 SHELL-001、PRIVACY-001、AccountScope 或个人化适配度消费者。

## 后续验收与开发前工作

B 已固定实际声明并实现只读 RPC／来源 Adapter；验收按下方分配逐项检查。
本模块测试：州级聚合、缺失／来源／年份、公式与 A/B；联合：Geo 正确口径、页面普通返回、
房产风险消费，B 主责、A 配合；最迟 Wave 5／6。Supabase schema/read RPC 已 implemented，真实 allow/deny 证据见本次验收报告。

## 生命周期与验收责任

页面只在登录后的业务树内建立；退出成功或换账号后结束旧业务页面，新页面按当前 SDK 用户读取记录。
Widget／ViewModel 在 dispose 后忽略晚到结果。账号记录只在线保存，网络失败显示未保存并允许用户重试；
不建立自动同步、清理屏障或离线队列。公共分析内部保留真实来源、日期与可用性，不以零替代缺失；呈现按本轮 UI 精简边界。

主要验收 seam 为应用页面入口；使用可见内容、动作、导航与保存／读取结果断言。
复用仍有效的公式、地理、Adapter 与存储测试，完成格式、分析、测试、debug APK 构建。
本次重构的统一证据见 [Issue #31 执行检查](../system/issue-31-validation.md)；
设备、真实外部服务证据缺失时不得宣称新版本 `Implemented` 或 `Integrated`。

## Wave 5 开发固定范围与验收分配（2026-09-17）

测试边界由项目负责人本任务确认：单点/A-B 页面、唯一安全分析服务、真实只读 Adapter/RPC。
唯一入口 `crime_security.dart`：`CrimeSecurity.analyse(location, refresh: false)`、
`compare(a,b, refresh: false)`；返回不可变 `SafetyAnalysis` / `SafetyComparison`。
结果保留地点、统计州、完整年度、分数/部分/不可用原因、类别年度计数、模型/边界/来源版本、采集时间。
`createCrimeSecurity(geographicContext, reader, database, clock)` 注入 Geo、外部输入及 SQLite。
读取 RPC 无参数，按完整年度/州/类别/type 聚合原始警区叶记录；排除 Malaysia、district=All 和 type=all，
避免汇总与叶记录重复计数。官方 CSV 与已有镜像业务键/字段/完整内容校验通过后登记来源，未知来源不评分。
Y 固定来自已验证官方快照的最新完整年度；缺失 category 或 type 年份不补零，空趋势留下缺口。
A/B 同一次输入快照和模型/边界版本且双方 complete 才提供 B-A 差值；部分/不可用保留双方读数和原因。
缓存保存公共输入及按坐标已解析的分析上下文，按模型版本分区，TTL 3 天；正常取数重新通过当前 Geo，临时离线仅恢复同坐标、未过期、已验证来源/边界的结果；不存地点名称/账户。明确 unresolved/ambiguous 不回退旧结果。
主地图操作返回根页面、切换地图并选中本页分析坐标；普通返回保留原地图选点。
房产两个入口导航明确标注尚未实现的独立槽位，由 B 在 Wave 6 替换。

| 场景 / 结果 | 验证归属 | 依赖 | 证据 | Owner | 最迟 Wave | 本模块状态 | 联合状态 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CS01 州聚合/排名/60:40/平分/零值/territory 映射 | 本模块 | 测试外部输入，真实 Geo | public service 测试+live | B | 5 | 已通过 [报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md) | 不适用 |
| CS02 缺失/部分/空/无来源/完整年度/5年缺口 | 本模块 | 外部输入/来源 | service+页面 | B | 5 | 已通过 [报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md) | 不适用 |
| CS03 动态 type/类别筛选不改变分数 | 本模块 | 真实分析/页面 | widget+设备 | B | 5 | 已通过 [报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md) | 不适用 |
| CS04 Geo resolved/unresolved/ambiguous/来源不可用 | 两者 | 本期真实 Geo；fake 只作边界案例 | service+真实坐标解析 | B 主责 A 配合 | 5 | 已通过 [报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md) | 已通过 [报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md) |
| CS05 3天 SQLite/损坏/过期/离线/重试/并发 | 本模块 | 本期真实 SQLite、只读 Adapter | service+Adapter | B | 5 | 已通过 [报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md) | 不适用 |
| CS06 A/B 同口径/部分侧/不可比/交换 | 两者 | 本期地图 A/B、真实 service | widget+live+设备 | B 主责 A 配合 | 5 | 已通过 [报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md) | 已通过 [报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md) |
| CS07 普通返回/主地图选中当前分析点 | 两者 | 本期真实地图+普通路由 | 页面入口/设备 | B 主责 A 配合 | 5 | 已通过 [报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md) | 已通过 [报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md) |
| CS08 登录业务树/退出换号/dispose晚到忽略 | 两者 | 本期真实 App/Auth | lifecycle widget+设备 | B 主责 A 配合 | 5 | 已通过 [报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md) | 已通过 [报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md) |
| CS09 RPC来源校验/映射/错误恢复/allow-deny | 本模块 | 本期真实 Supabase | HTTP确定性+真实authenticated/anon/写deny | B | 5 | 已通过 [报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md) | 不适用 |
| CS10 中英文/精简UI/读屏/小屏200%字体/Penpot | 本模块 | 本期页面 | widget+Owner A Android及Owner B模拟器 | B | 5 | 已通过 [报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md) | 不适用 |
| CS11 房产公开风险读数/入口参数 | 两者 | 测试消费公开结果，后续真实房产 | 本期service与槽位；Wave6真实快照流程 | B | 6 | 已通过 [报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md) | 待接入 |

Ready Gate：实际声明按上述边界实施；真实只读 RPC 在当前任务建立并验证，所有场景责任已分配。

页面入口 `CrimeSecurityPage(crime,location,locationB?,onShowMap?,onPortfolio?,onAddProperty?)`；
主地图回调携带当前侧合法地点；房产新增回调携带原单点地点。
默认房产槽位明确标注 Wave 6 尚未实现；未来真实消费由 B 替换，不能将槽位视为房产功能。
Penpot 节点 `f8bc3597-5a95-809e-8008-a3fa91b70d32`（07 · 治安与犯罪），
使用其 Source Sans Pro、Canvas #F6F8FB、Hero #0B1F44/18dp、Primary #155EEF、白色图表/16dp、说明底色 #EAF1FF、16dp页边距。
数值/年份来自真实服务；不复制原型示例评分/2025。无已批准分级阈值，状态使用完整/部分/暂不可用，避免制造评级。
趋势沿用事实源折线，保留原型白色圆角图表与蓝色趋势；缺失年份断线并有逐年文字摘要。

Wave 5 完成证据：[验收报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md)、[GPT‑5.6 Luna High 双轴审查](../../human/crime-and-security-wave5-luna-review-2026-09-17.md)。当前阻塞无；真实房产消费 B / Wave 6 待接入；本模块不代表其他 Wave 5 Feature 已完成。
