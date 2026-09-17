# Infrastructure Coverage 开发契约

> Owner：B；依赖顺序参考 Wave 6；2026-09-17 Issue #31 修订。
> 状态：Draft；设计目标，生产 Feature 尚未交付。

本契约按 [Issue #31](https://github.com/chewjs-wm25/LocateMY/issues/31) 与
[ADR 0017](../../adr/0017-minimal-account-and-online-user-records.md) 修订。
产品事实和公式以知识库为准；字段、权限和 migration 只在
[Schema Catalog](../data/schema-catalog.md) 定义。普通页面传参与具名服务替代通用导航／贡献框架。

产品事实源：[infrastructure](../../knowledge_base/locatemy_product/features/infrastructure.md)。

## 本轮分析页面精简（2026-09-17）

界面按 [UI 精简边界](../../knowledge_base/locatemy_product/ui_design_spec.md#分析页面精简边界2026-09-17) 调整；该节取代本契约中冲突的来源／时间／较旧提示展示要求。
指标、公式、输入、缓存时效和服务可用性不变。保留内部来源与日期用于取数／校验，取消用户页面技术明细，保留简短错误与重试。
验收沿用页面和公开服务边界，核对单点与 A/B 均无技术元数据／重复提示，并回归现有缓存、公式、失败恢复与账户行为。此轮仅更新文档，代码调整及验证待后续任务执行。

## 设计目标（未实现）

保留供水／供电、医疗、教育和交通分项及 ICI；官方行政区资料与地点交通半径分别标示。
[ICI 模型](../../knowledge_base/locatemy_product/infrastructure_index_scoring.md) 固定公式、分项、60% 门槛与缺失处理。
医疗／教育／交通三个账号权重整数 1–10，默认 5，在线保存；当前页 preview 可变化，但失败不冒充保存成功。
权重只影响基础设施单点 ICI；地点摘要和 A/B 必须用中性权重，不改变原始分项。
交通复用 PublicTransportation 的 canonical 结果，不再计算另一份交通分。
未来唯一入口 `lib/features/infrastructure_coverage/infrastructure_coverage.dart`；消费明确地点、Geo、
PublicTransportation 服务与 SDK 当前账号，不消费 AccountScope、Shell、五项评估偏好或 Suitability。

## 后续验收与开发前工作

B 固定实际 declarations、读取 RPC 与三权重 migration 后开发；当前不是已实现 Feature。
本模块：原始统计、缺失与有效零、60% 门槛、三个默认／边界／在线保存失败、preview；
联合：A/B 和摘要中性读数、同坐标交通复用、换号权重重新读取，B 主责、A 配合；最迟 Wave 6。
旧数据库五个 0–1 权重不能视为目标三权重实现。

## 生命周期与验收责任

页面只在登录后的业务树内建立；退出成功或换账号后结束旧业务页面，新页面按当前 SDK 用户读取记录。
Widget／ViewModel 在 dispose 后忽略晚到结果。账号记录只在线保存，网络失败显示未保存并允许用户重试；
不建立自动同步、清理屏障或离线队列。公共分析内部保留真实来源、日期与可用性，不以零替代缺失；呈现按本轮 UI 精简边界。

主要验收 seam 为应用页面入口；使用可见内容、动作、导航与保存／读取结果断言。
复用仍有效的公式、地理、Adapter 与存储测试，完成格式、分析、测试、debug APK 构建。
本次重构的统一证据见 [Issue #31 执行检查](../system/issue-31-validation.md)；
设备、真实外部服务证据缺失时不得宣称新版本 `Implemented` 或 `Integrated`。
