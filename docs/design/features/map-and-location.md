# Map / Location 开发契约

> Owner：A；依赖顺序参考 Wave 4；2026-09-17 Issue #31 修订。
> 状态：实现重构完成，本轮证据与未交付边界见执行检查。

本契约按 [Issue #31](https://github.com/chewjs-wm25/LocateMY/issues/31) 与
[ADR 0017](../../adr/0017-minimal-account-and-online-user-records.md) 修订。
产品事实和公式以知识库为准；字段、权限和 migration 只在
[Schema Catalog](../data/schema-catalog.md) 定义。普通页面传参与具名服务替代通用导航／贡献框架。

产品事实源：[map_location](../../knowledge_base/locatemy_product/features/map_location.md)。

## 地点与在线收藏

地图真实浏览、搜索和坐标选点。单点、A、B 独立保留；合法马来西亚地点才可分析，
无地点不套默认城市，相同点不能比较，交换只改变 A/B 顺序。
收藏在线命名保存、读取、选择和删除；同账号登录后重新读取云端。
无私有 SQLite 收藏缓存、离线创建、重放或同步状态。联网失败明确未保存／读取失败。

## 公开协作

唯一入口 `lib/features/map_location/map_location.dart`。`LocationCoordinator` 管理选择、角色、收藏；
`loadSavedLocations` 只在线读取。`MapLocationRuntime` 由登录页面树创建，按账号注入在线存储。
页面接收 `onAnalysis(location)`、`onComparison(a,b)`、`onLayerSelected(intent)` 三个明确回调。
普通 Navigator 路由携带不可变 `ValidLocationReference`；地图专属 marker action 是必要业务对象，
不再实现 ShellIntent。地理服务保留行政候选的 resolved／unresolved／ambiguous 口径。
六类分析入口和比较目录保留；未接入的分析明确标明尚未实现，不能用成功 fixture 替代。

## 图层与 UI

保留 MapLayerHost／MapWorkspace 作为地图业务接口，provider 不改全局选点。
viewport version 防止旧视口结果覆盖新视口；分类聚合、点击放大／列表和隐藏仍可观察。
`markerKind` 为可选呈现元数据，默认 generic；设施和隐患各五种分类图标。
分类来自提供方的原始业务类型，不从 id 或 action 猜测。混合聚合保留原始每项分类和动作。
右侧工具栏按钮至少 48×48，含双语 tooltip／读屏名；上报、确认／取消与管理操作在地图下方。
详情突出地点名与精确坐标，不展示内部 id；小屏／放大文字支持换行和滚动。

## 验收

A 本模块：合法／范围外／缺失候选、晚到选点、独立角色、相同点拒绝、A/B 交换，
在线收藏成功／失败／删除、无离线重放，五类分类／混合聚合与视口过期。
A 应用联验：首页往返、退出结束页面、换号读取所属收藏、设施／隐患图层及分析入口；最迟 Wave 4／5。
复用 `test/features/map_location/`；在线归属 smoke 为 `test/live/map_location_live_test.dart`。

## 生命周期与验收责任

页面只在登录后的业务树内建立；退出成功或换账号后结束旧业务页面，新页面按当前 SDK 用户读取记录。
Widget／ViewModel 在 dispose 后忽略晚到结果。账号记录只在线保存，网络失败显示未保存并允许用户重试；
不建立自动同步、清理屏障或离线队列。公共分析保留真实来源、日期、缓存／部分／不可用状态，不以零替代缺失。

主要验收 seam 为应用页面入口；使用可见内容、动作、导航与保存／读取结果断言。
复用仍有效的公式、地理、Adapter 与存储测试，完成格式、分析、测试、debug APK 构建。
本次重构的统一证据见 [Issue #31 执行检查](../system/issue-31-validation.md)；
设备、真实外部服务证据缺失时不得宣称新版本 `Implemented` 或 `Integrated`。

## Wave 6 地点摘要接线（2026-09-18）

按 UI 事实源，展开地点详情读取五项原生业务摘要，不生成个人化总分。
唯一入口新增 `LocationSummaryReader.read(location, date)`、不可变字段的 `LocationSummaryReading` 和五值 `LocationSummaryMetric`；
`MapLocationPage.summaryReader` 由 app 注入 `BusinessLocationSummaryReader`，仅消费各模块唯一入口。
安全为统计州指数；成本为同子集全国基准 100 的指数，部分篮子保留项目数与月份数；设施保留各类计数／未知与最近直线距离；
交通为 1.5 km 站点与直线距离粗估步行提示；基础设施调用中性 `summary` 并显示最低或缺失分项。
Socio 不进入摘要，Hazard 保留独立图层。任一提供方失败不抹去其他读数；可重试，切换坐标或退出后旧完成不覆盖当前页。
本期 A 主责、B 参与，最迟 Wave 6；验证为 `test/app/location_summary_integration_test.dart`、既有提供方测试、生产设备摘要旅程。
本项替代 Cost H01 与 Infrastructure 中错误记作 Home 消费者的历史追踪文字；首页全国宏观职责不变。
