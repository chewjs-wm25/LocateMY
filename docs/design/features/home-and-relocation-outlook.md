# Home & Relocation Outlook 开发契约

> Owner：A；依赖顺序参考 Wave 4；2026-09-17 Issue #31 修订。
> 状态：实现重构完成，本轮证据与未交付边界见执行检查。

本契约按 [Issue #31](https://github.com/chewjs-wm25/LocateMY/issues/31) 与
[ADR 0017](../../adr/0017-minimal-account-and-online-user-records.md) 修订。
产品事实和公式以知识库为准；字段、权限和 migration 只在
[Schema Catalog](../data/schema-catalog.md) 定义。普通页面传参与具名服务替代通用导航／贡献框架。

产品事实源：[home](../../knowledge_base/locatemy_product/features/home.md)。

## 本轮分析页面精简（2026-09-17）

界面按 [UI 精简边界](../../knowledge_base/locatemy_product/ui_design_spec.md#分析页面精简边界2026-09-17) 调整；该节取代本契约中冲突的来源／时间／较旧提示展示要求。
指标、公式、输入、缓存时效和服务可用性不变。保留内部来源与日期用于取数／校验，取消用户页面技术明细，保留简短错误与重试。
验收沿用页面和公开服务边界，核对单点与 A/B 均无技术元数据／重复提示，并回归现有缓存、公式、失败恢复与账户行为。Issue #31 同步调整已有代码与接线；实际验收结果见执行检查。

## 成果与协作

保留五项全国宏观卡、搬迁时机、趋势、下拉刷新和冷却；期间标签可集中表达，不展示技术来源／时间明细。
[首页宏观模型](../../knowledge_base/locatemy_product/home_index_scoring.md) 是公式唯一来源。
SQLite 公共缓存不含账户业务记录，退出和换号保留；离线／刷新失败显示已有缓存及其状态。
唯一入口 `lib/features/home_relocation_outlook/home_relocation_outlook.dart`；`HomeRelocationOutlook.load`
返回现有可用／部分／失败／冷却结果。首页通过 `onExploreMap` 普通回调切换地图 Tab。
没有 ExploreMapIntent、scope-bound wrapper、贡献槽位或导航结果包装。

## 验收

A 本模块：五卡单位、内部来源日期、精简期间标签、模型缺失、趋势、冷却、公共 SQLite 缓存与刷新失败。
A 应用联验：探索地图、返回首页、双语切换、重启／退出保留公共缓存；最迟 Wave 4。
仍复用 `test/features/home_relocation_outlook/` 与 opt-in Home live smoke。

## 生命周期与验收责任

页面只在登录后的业务树内建立；退出成功或换账号后结束旧业务页面，新页面按当前 SDK 用户读取记录。
Widget／ViewModel 在 dispose 后忽略晚到结果。账号记录只在线保存，网络失败显示未保存并允许用户重试；
不建立自动同步、清理屏障或离线队列。公共分析内部保留真实来源、日期与可用性，不以零替代缺失；呈现按本轮 UI 精简边界。

主要验收 seam 为应用页面入口；使用可见内容、动作、导航与保存／读取结果断言。
复用仍有效的公式、地理、Adapter 与存储测试，完成格式、分析、测试、debug APK 构建。
本次重构的统一证据见 [Issue #31 执行检查](../system/issue-31-validation.md)；
设备、真实外部服务证据缺失时不得宣称新版本 `Implemented` 或 `Integrated`。
