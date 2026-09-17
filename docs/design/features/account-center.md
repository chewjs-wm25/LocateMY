# Account Center 开发契约

> Owner：A；依赖顺序参考 Wave 6；2026-09-17 Issue #31 修订。
> 状态：Draft；设计目标，生产 Feature 尚未交付。

本契约按 [Issue #31](https://github.com/chewjs-wm25/LocateMY/issues/31) 与
[ADR 0017](../../adr/0017-minimal-account-and-online-user-records.md) 修订。
产品事实和公式以知识库为准；字段、权限和 migration 只在
[Schema Catalog](../data/schema-catalog.md) 定义。普通页面传参与具名服务替代通用导航／贡献框架。

产品事实源：[account](../../knowledge_base/locatemy_product/features/account.md)。

## 当前最小账号 UI 与后续目标

当前账号入口显示真实邮箱、语言、确认退出及普通失败反馈，不展示验证徽章或清理恢复页。
保留后续房产／本人隐患与当前预算预案入口；未接入入口不得显示成功示例或空回调。
ACCOUNT-08 五项评估偏好和个人化总分已排除；ACCOUNT-09 当前预算预案保留。
当前预案显示名称、业务金额与缺失状态，进入预算页面切换；选择至多一份，在线成功后依赖读数更新。
三个 ICI 权重由基础设施服务管理，不以删除五项偏好为由取消。
当前最小账号页复用 AuthenticationPage；完整 Account Center Feature 尚未实现，状态 Draft。
未来入口 `lib/features/account_center/account_center.dart` 只消费具名预算／房产／隐患服务和 SDK 用户。

## 验收

A 本期：真实邮箱、无验证徽章、取消退出、退出失败普通重试、成功回登录与语言保留。
A 后续与 B 联合：current 预案显示／切换、房产档案、本人隐患；最迟 Wave 6。
不加入 ACCOUNT-03–06 已排除的历史／默认地点／对比／评论／点赞占位。

## 生命周期与验收责任

页面只在登录后的业务树内建立；退出成功或换账号后结束旧业务页面，新页面按当前 SDK 用户读取记录。
Widget／ViewModel 在 dispose 后忽略晚到结果。账号记录只在线保存，网络失败显示未保存并允许用户重试；
不建立自动同步、清理屏障或离线队列。公共分析保留真实来源、日期、缓存／部分／不可用状态，不以零替代缺失。

主要验收 seam 为应用页面入口；使用可见内容、动作、导航与保存／读取结果断言。
复用仍有效的公式、地理、Adapter 与存储测试，完成格式、分析、测试、debug APK 构建。
本次重构的统一证据见 [Issue #31 执行检查](../system/issue-31-validation.md)；
设备、真实外部服务证据缺失时不得宣称新版本 `Implemented` 或 `Integrated`。
