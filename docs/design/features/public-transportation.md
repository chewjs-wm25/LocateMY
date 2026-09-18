# Public Transportation 开发契约

> Owner：A；依赖顺序参考 Wave 5；2026-09-17 Issue #31 修订。
> 状态：实现重构完成，本轮证据与未交付边界见执行检查。

本契约按 [Issue #31](https://github.com/chewjs-wm25/LocateMY/issues/31) 与
[ADR 0017](../../adr/0017-minimal-account-and-online-user-records.md) 修订。
产品事实和公式以知识库为准；字段、权限和 migration 只在
[Schema Catalog](../data/schema-catalog.md) 定义。普通页面传参与具名服务替代通用导航／贡献框架。

产品事实源：[transportation](../../knowledge_base/locatemy_product/features/transportation.md)。

## 本轮分析页面精简（2026-09-17）

界面按 [UI 精简边界](../../knowledge_base/locatemy_product/ui_design_spec.md#分析页面精简边界2026-09-17) 调整；该节取代本契约中冲突的来源／时间／较旧提示展示要求。
指标、公式、输入、缓存时效和服务可用性不变。保留内部来源与日期用于取数／校验，取消用户页面技术明细，保留简短错误与重试。
验收沿用页面和公开服务边界，核对单点与 A/B 均无技术元数据／重复提示，并回归现有缓存、公式、失败恢复与账户行为。Issue #31 同步调整已有代码与接线；实际验收结果见执行检查。

## 成果与协作

保留固定 1.5 km 的站点／有效路线、连通性、局部站点图、完整计数、最近 30 项和选中描述。
全部预期 16 feed 及同 snapshot/date/grid 的来源完整性规则继续适用。
[ICI／交通模型](../../knowledge_base/locatemy_product/infrastructure_index_scoring.md) 为分数唯一来源。
no_stops 与 no_active_routes 是已知服务结果，分数仍不可用；incomplete 基于成功部分计算并显示部分交通分；缺同日期网格时仅距离项归一化，明确标示缺项。A/B 并列显示部分分数，不计算差异。
固定参照组是可用 feed 站点 1.5 km 圆并集中的固定 1 km 米制网格，不随用户地点变化。

唯一入口 `lib/features/public_transportation/public_transportation.dart`。`PublicTransportation.load/compare`
作为具名服务被页面和未来 ICI 调用。页面直接接收 location/date 或 A/B 输入，
`AnalysisReturnContext` 只保留 location、role、analysisDate，不含 opaque Shell 请求身份。
返回使用 Navigator，站点页面和比较详情使用普通路由，不发布贡献或导航包装。
局部 MapLayerHost／MapWorkspace 可用于站点呈现，不改变全局选点；late response 在页面 dispose 后忽略。

## 验收

A 本模块：feed 服务日期、跨 feed 去重、缺失／解析失败／旧来源、空服务、完整参照组资格、
canonical 分数、列表截断不改统计、站点图高亮、刷新失败保留此前结果、A/B 可比性。
A 与地图联验及 B 未来 ICI 消费：同坐标／日期复用 canonical 结果、普通返回、双语；最迟 Wave 5／6。
复用 `test/features/public_transportation/` 和交通 live smoke，保留 SQL 来源／公式测试。

## 生命周期与验收责任

页面只在登录后的业务树内建立；退出成功或换账号后结束旧业务页面，新页面按当前 SDK 用户读取记录。
Widget／ViewModel 在 dispose 后忽略晚到结果。账号记录只在线保存，网络失败显示未保存并允许用户重试；
不建立自动同步、清理屏障或离线队列。公共分析内部保留真实来源、日期与可用性，不以零替代缺失；呈现按本轮 UI 精简边界。

主要验收 seam 为应用页面入口；使用可见内容、动作、导航与保存／读取结果断言。
复用仍有效的公式、地理、Adapter 与存储测试，完成格式、分析、测试、debug APK 构建。
本次重构的统一证据见 [Issue #31 执行检查](../system/issue-31-validation.md)；
设备、真实外部服务证据缺失时不得宣称新版本 `Implemented` 或 `Integrated`。

## 2026-09-18 部分资料评分变更与验收

用户要求资料不完整仍计算并显示交通分，取代旧 incomplete 不评分规则。公共 seam `TransitPartialSnapshot` 增加可空 score 和 distanceOnly，仍保留 TransitIncomplete，不冒充完整资料。已有请求和比较调用方式不变。

| 场景 | 验证责任 | 依赖与证据 | 状态 |
| --- | --- | --- | --- |
| 部分 feed 成功仍按原公式评分 | A 本模块 | 服务 fake + 开发 Supabase SQL 受控算例 | 已通过 |
| 同日期网格缺失，16 feed 也可返回 incomplete 距离分 | A 本模块 | 页面 fake + 开发 Supabase SQL | 已通过 |
| 部分交通分、缺项双语及 A/B 并列 | A 本模块 | 页面 Widget 与原 A/B 回归 | 已通过；本次未重跑设备实测 |
| ICI 消费同一部分分数并保留提示 | A/B 联合 | 真实 InfrastructureService + canonical seam fake | 自动验证通过；本次未重跑设备实测 |

证据与实际吉隆坡查询见 `docs/human/transit-partial-score-2026-09-18.md`。本次不重新判定完整 Wave / Integrated 状态。
