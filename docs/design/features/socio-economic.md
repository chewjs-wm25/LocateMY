# Socio-economic 开发契约

> Owner：B；依赖顺序参考 Wave 6；2026-09-17 Issue #31 修订。
> 状态：Draft；设计目标，生产 Feature 尚未交付。

本契约按 [Issue #31](https://github.com/chewjs-wm25/LocateMY/issues/31) 与
[ADR 0017](../../adr/0017-minimal-account-and-online-user-records.md) 修订。
产品事实和公式以知识库为准；字段、权限和 migration 只在
[Schema Catalog](../data/schema-catalog.md) 定义。普通页面传参与具名服务替代通用导航／贡献框架。

产品事实源：[socio_economic](../../knowledge_base/locatemy_product/features/socio_economic.md)。

## 本轮分析页面精简（2026-09-17）

界面按 [UI 精简边界](../../knowledge_base/locatemy_product/ui_design_spec.md#分析页面精简边界2026-09-17) 调整；该节取代本契约中冲突的来源／时间／较旧提示展示要求。
指标、公式、输入、缓存时效和服务可用性不变。保留内部来源与日期用于取数／校验，取消用户页面技术明细，保留简短错误与重试。
验收沿用页面和公开服务边界，核对单点与 A/B 均无技术元数据／重复提示，并回归现有缓存、公式、失败恢复与账户行为。此轮仅更新文档，代码调整及验证待后续任务执行。

## 设计目标（未实现）

行政区家庭收入中位数、州级 P1–P100 分布、收入结构和基尼保留。
SOCIO-02 用户收入位置仅读取当前预算预案的家庭月度总收入；月净收入不能替代。
行政区缺失时只按事实源展示允许的州级参考，ambiguity 不选择默认候选。
A/B 不同年份／版本／缺失状态明确不可比；单位和调查年份可见。
未来唯一入口 `lib/features/socio_economic/socio_economic.dart`，页面显式地点参数，
具名服务消费 Geo 与预算 current，不消费 Privacy、Shell 或 Suitability。

## 后续验收与开发前工作

B 固定真实服务声明、数据映射与只读 RPC 后开发；当前没有生产 Feature，状态为 Draft。
本模块：分位组、单位／年份／缺失、收入位置边界、A/B；联合：Geo 与预算切换后更新，
B 主责、A 页面接线；最迟 Wave 6。在线预案失败不能制造成功的收入位置。

## 生命周期与验收责任

页面只在登录后的业务树内建立；退出成功或换账号后结束旧业务页面，新页面按当前 SDK 用户读取记录。
Widget／ViewModel 在 dispose 后忽略晚到结果。账号记录只在线保存，网络失败显示未保存并允许用户重试；
不建立自动同步、清理屏障或离线队列。公共分析内部保留真实来源、日期与可用性，不以零替代缺失；呈现按本轮 UI 精简边界。

主要验收 seam 为应用页面入口；使用可见内容、动作、导航与保存／读取结果断言。
复用仍有效的公式、地理、Adapter 与存储测试，完成格式、分析、测试、debug APK 构建。
本次重构的统一证据见 [Issue #31 执行检查](../system/issue-31-validation.md)；
设备、真实外部服务证据缺失时不得宣称新版本 `Implemented` 或 `Integrated`。
