# Authentication & Session 开发契约

> Owner：A；依赖顺序参考 Wave 1；2026-09-17 Issue #31 修订。
> 状态：实现重构完成，本轮证据与未交付边界见执行检查。

本契约按 [Issue #31](https://github.com/chewjs-wm25/LocateMY/issues/31) 与
[ADR 0017](../../adr/0017-minimal-account-and-online-user-records.md) 修订。
产品事实和公式以知识库为准；字段、权限和 migration 只在
[Schema Catalog](../data/schema-catalog.md) 定义。普通页面传参与具名服务替代通用导航／贡献框架。

产品事实源：[authentication](../../knowledge_base/locatemy_product/features/authentication.md)。

## 账号入口

保留邮箱密码注册、登录、当前设备退出和读取当前用户；SDK 默认保持登录、刷新 token 和发出身份变化。
本地 Supabase `auth.email.enable_confirmations = false`；开发环境也必须关闭注册邮箱确认。
注册有 session 即进入业务树；意外返回无 session 时给普通注册失败，不增加待验证页或徽章。
用户名可选，写资料失败不能取消已经成功的账号注册，不保留专用资料恢复／重试协议。
登录／注册保留邮箱格式、密码与确认密码校验、加载及普通错误反馈。
账户页面显示 SDK 的真实邮箱；确认退出成功后回登录，只有 SDK 仍保留身份的失败才保留页面并给普通重试。SDK 当前设备身份已清除时，远端撤销请求失败也按设备退出完成返回登录，不恢复假身份。

## 公开协作

唯一入口 `lib/features/authentication_session/authentication_session.dart`。
`AuthenticationSession` 提供 `restoreSession`、`watchSession`、`signIn`、`register`、`signOut`；
`restoreSession` 仅读取 SDK 当前会话，不请求额外 getUser、不自建到期计时。
`SessionSnapshot` 仅 authenticated／unauthenticated；必要的表单结果仍区分成功及普通失败。
应用 root 消费身份；业务服务只读取 SDK 当前用户 id。取消 `AUTH-002` 与任何 privacy participant。
SDK refresh 的流错误有 onError 处理，保留 SDK 仍持有的身份并反馈连接问题。

## 本模块与联合验收

| 场景 | 责任与证据 | 最迟 |
| --- | --- | --- |
| 注册／登录校验、成功、网络失败；无验证徽章 | A；账号页面测试与 SDK Adapter 测试 | Wave 1 |
| SDK 重启保持登录；当前设备退出 | A；真实 SDK smoke 与设备重启 | Wave 1／应用联验 |
| 退出失败重试、取消退出无副作用 | A；页面动作断言 | 应用联验 |
| 换号后记录按新用户在线读取，晚到结果不复活旧页面 | A；应用页面测试、双账户 RLS smoke | 应用联验 |

## 生命周期与验收责任

页面只在登录后的业务树内建立；退出成功或换账号后结束旧业务页面，新页面按当前 SDK 用户读取记录。
Widget／ViewModel 在 dispose 后忽略晚到结果。账号记录只在线保存，网络失败显示未保存并允许用户重试；
不建立自动同步、清理屏障或离线队列。公共分析保留真实来源、日期、缓存／部分／不可用状态，不以零替代缺失。

主要验收 seam 为应用页面入口；使用可见内容、动作、导航与保存／读取结果断言。
复用仍有效的公式、地理、Adapter 与存储测试，完成格式、分析、测试、debug APK 构建。
本次重构的统一证据见 [Issue #31 执行检查](../system/issue-31-validation.md)；
设备、真实外部服务证据缺失时不得宣称新版本 `Implemented` 或 `Integrated`。
