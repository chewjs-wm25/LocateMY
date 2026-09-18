# Hazard Reporting 开发契约

> Owner：A；依赖顺序参考 Wave 5；2026-09-17 Issue #31 修订。
> 状态：实现重构完成，本轮证据与未交付边界见执行检查。

本契约按 [Issue #31](https://github.com/chewjs-wm25/LocateMY/issues/31) 与
[ADR 0017](../../adr/0017-minimal-account-and-online-user-records.md) 修订。
产品事实和公式以知识库为准；字段、权限和 migration 只在
[Schema Catalog](../data/schema-catalog.md) 定义。普通页面传参与具名服务替代通用导航／贡献框架。

产品事实源：[hazard_reporting](../../knowledge_base/locatemy_product/features/hazard_reporting.md)。

## 成果与协作

五类公开报告、地图图层、详情、本人 pending／resolved 和删除、赞成／反对／撤回投票保持。
创建者位置、类型、正文与上报时间发布后不可编辑，无维护者审核／隐藏／删除例外。
所有写入在线；每账户每报告至多一票，撤回删除本人票，计数不是本机累计。
唯一入口 `lib/features/hazard_reporting/hazard_reporting.dart`。`HazardReporting` 与
`HazardRiskCounter` 是具名业务服务；SDK 当前 account id 保证本人请求按当前身份进行。
页面参数直接传 location／report id 和 onCreated／onChanged／onLocate 回调。
没有 ShellIntent、HazardShellContribution 或 privacy participant。地图专属分类图层仍保留。地图未选地点时不查询图层；选点后以当前活动地点角色为中心，仅查询并展示 2,000 米圆形范围内的报告（含边界），分页仍保留。
`HazardPageRequest.mapCenter` 为地图请求的可选坐标；地图图层据此限定查询边界及过滤圆形距离，其他分页读取维持原有 viewport 语义。
新增成功返回本人报告，定位回地图，旧页面结果不在新账号页面展示。
风险计数保留 2,000 m、pending、Haversine 边界、完整性和采集时间，不混入官方安全指数。

## 验收

A 本模块：五类、输入校验、分页／缺失／失败、不可变正文、作者状态／删除、本人票切换／撤回、
成功投票后详情刷新失败仍保留真实结果、图层不完整不称空内容。
A 应用联验：地图上报／长按／详情／本人列表／返回定位、换号、在线失败；最迟 Wave 5。
A 与 B 房产联验：只在新增／坐标变化请求真实 pending count；最迟 Wave 6。
复用 `test/features/hazard_reporting/` 与双账号 live smoke。

## 生命周期与验收责任

页面只在登录后的业务树内建立；退出成功或换账号后结束旧业务页面，新页面按当前 SDK 用户读取记录。
Widget／ViewModel 在 dispose 后忽略晚到结果。账号记录只在线保存，网络失败显示未保存并允许用户重试；
不建立自动同步、清理屏障或离线队列。公共分析保留真实来源、日期、缓存／部分／不可用状态，不以零替代缺失。

主要验收 seam 为应用页面入口；使用可见内容、动作、导航与保存／读取结果断言。
复用仍有效的公式、地理、Adapter 与存储测试，完成格式、分析、测试、debug APK 构建。
本次重构的统一证据见 [Issue #31 执行检查](../system/issue-31-validation.md)；
设备、真实外部服务证据缺失时不得宣称新版本 `Implemented` 或 `Integrated`。
