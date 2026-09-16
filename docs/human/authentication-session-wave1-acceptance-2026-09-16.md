# Authentication & Session — Wave 1 实现验收

日期：2026-09-16。Owner A。判定依据：[开发规范第 3–5 节](../design/development-standard.md)、[owning contract 第 5.1 节](../design/features/authentication-and-session.md#51-wave-1-验收分配2026-09-16)。代码基准为 `7d84e4d` 加本次工作区修改，生产与测试补丁保存在 [implementation.patch](evidence/authentication-session-wave1-2026-09-16/implementation.patch)。未提交、未宣告 Integrated，也未验收 Geographic Context 或整个 Wave 1。

## 1. 模块实现：Implemented

本 Feature 的当期实现及验收通过。生产依赖为真实 Supabase Auth 和 profiles，页面测试 fake 不替代生产能力。公开 `AUTH-001` declarations、schema、权限与产品范围未改变。

修复了晚到登录成功/失败覆盖另一账户、资料重试反馈跨账户、注册过期 session 被当作认证成功、空白可选 username 被当作资料失败，以及 Auth 身份异常时先写资料的问题。注册等待资料写入期间账户改变时，不再返回旧账户成功。启动与装配移入 `lib/app/app.dart`，`lib/main.dart` 只调用启动入口。页面为首个无效字段设置焦点和滚动，为可编辑字段关联双语语义标签；中文 200% 字体测试改为实际生效的系统字体设置。契约补齐验收分配，以实现入口替代过时 TODO 骨架，并重新导出 HTML。

| 契约当前责任 | 验证结果与证据 |
| --- | --- |
| 冷启动恢复、无会话、有效身份、离线/远端拒绝、过期刷新、晚到恢复 | Adapter、VM 和页面测试通过；真实 getUser 恢复通过；两设备冷启动/重启见下面设备证据 |
| 登录输入、凭据、网络、客户端及限流失败；防重复、晚到结果隔离 | Adapter/VM 测试通过；真实 A/B 邮箱密码登录通过；真机真实错误凭据反馈通过 |
| 注册 authenticated / verification-required、确认事实、资料独立失败与重试 | 确定性测试通过全部适用结果；真实注册无 session、确认后登录、资料重试成功见真实环境说明；未知确认页面不显示 verified |
| profiles owner-only 权限 | 真实本人 select/insert/update/delete 成功；另一账户读取/更新/删除不可触及旧账户行，越权 upsert 和 owner id 改写返回 42501；匿名 CRUD 被拒绝；没有修改 RLS/grants |
| 仅当前设备退出、失败屏障与恢复 | local scope 请求、失败重试及页面确认/取消测试通过；真实双 session 验证本设备退出、另一 session 可继续恢复及读取未删除资料，另一账户会话不变 |
| 双账户变化、过期操作反馈 | VM 测试验证 A 的晚到登录成功/失败和资料反馈不覆盖 B；恢复响应不复活已退出身份 |
| 页面、双语与可访问性 | 中英文表单、验证反馈、身份三态、重试、退出流程及偏好保存测试通过；小屏/200% 字体、首个错误焦点、输入控件语义标签测试通过；模拟器与真机证据如下 |

质量检查：

- `dart format --output=none --set-exit-if-changed .`：29 文件，零格式改动，[日志](evidence/authentication-session-wave1-2026-09-16/format.log)。
- `flutter analyze`：No issues found，[日志](evidence/authentication-session-wave1-2026-09-16/analyze.log)。
- `flutter test --reporter expanded`：55 项通过、1 项 opt-in live 测试默认跳过，[日志](evidence/authentication-session-wave1-2026-09-16/tests.log)。
- `python3 tool/verify_authentication_live.py`：真实环境测试通过，[日志](evidence/authentication-session-wave1-2026-09-16/live.log)。
- `python3 tool/build_authentication_verification.py`：底层 `flutter build apk --debug` 通过；APK 扫描无本机 secret key，[记录](evidence/authentication-session-wave1-2026-09-16/build.log)。构建期间 .env 临时仅含 URL/publishable key，完成后恢复原文件。依用户要求保留原 .env 配置方式；secret key 不属于应用公开配置。
- Markdown/HTML 标题数量和全部 Dart declarations 等价检查、`git diff --check` 通过。

### 真实 Supabase 环境说明

项目为 `ntlhjfljkjeefzzqutbc`，Flutter 3.47.2、锁定 SDK 版本未升级。测试经生产 Adapter 与客户端权限执行认证和资料断言，secret key 只供管理员创建、确认和清理专用测试账户。每次成功创建的测试账户都在 finally 删除；清理核查无遗留 QA 账户。

首次真实注册成功运行已通过 `RegistrationVerificationRequired`、管理员确认、真实登录与 getUser、`retryOptionalProfile → ProfileRegistered`、本人资料写入/更新及跨账户拒绝断言。整次命令随后因测试错误地要求匿名 SELECT 返回空列表而失败；实际环境因匿名没有 table grant 返回 42501，属于正确拒绝。该失败是测试权限期望问题，不能称为整次测试通过。

修正匿名拒绝断言后，邮件服务返回 `429 / over_email_send_rate_limit`；Adapter 正确返回 retryableUnavailable。最后绿色运行使用管理员创建专用 A/B fixtures 继续完成真实登录、恢复、profiles 完整权限和双 session 退出验证。其绿色结果不单独证明本次 signUp 成功；注册成功证据来自前述首次真实运行，两项证据合并覆盖当前环境适用行为。没有调整邮件限流、关闭 Confirm email 或绕过客户端 RLS。当前生产配置开启确认，因此带 session 的注册结果通过确定性 Adapter 测试验证。

上述确认步骤验证 Auth 确认事实和后续登录，不验证用户邮箱中的邮件正文或链接跳转；它们不属于本 Feature 的已批准应用界面验收范围。SDK 行为核对见 [signUp](https://supabase.com/docs/reference/dart/auth-signup)、[signOut](https://supabase.com/docs/reference/dart/auth-signout)、[onAuthStateChange](https://supabase.com/docs/reference/dart/auth-onauthstatechange)。

### 设备证据

使用上述公开配置 APK，模拟器 `LocateMY_QA`（Android 36，约 411dp）与 Owner A 真机 Samsung A52s（SM_A528B，约 384dp）。每台均执行首屏、失败、返回/重启；模拟器额外检查 200% 字体。页面 Widget 测试覆盖中文与 English 的 200% 注册布局、输入焦点、语义标签以及退出确认/取消/重试。

- 模拟器：[中文首屏](evidence/authentication-session-wave1-2026-09-16/emulator-zh-initial.png)、[中文空输入失败/键盘](evidence/authentication-session-wave1-2026-09-16/emulator-zh-invalid.png)、[切换后的英文失败](evidence/authentication-session-wave1-2026-09-16/emulator-en-invalid.png)、[返回并重启保留 English](evidence/authentication-session-wave1-2026-09-16/emulator-en-restart.png)、[English 200% 注册](evidence/authentication-session-wave1-2026-09-16/emulator-en-large-register.png)、[最终 APK 首屏](evidence/authentication-session-wave1-2026-09-16/emulator-en-final.png)。
- 真机：[中文首屏](evidence/authentication-session-wave1-2026-09-16/phone-zh-initial.png)、[中文失败/键盘](evidence/authentication-session-wave1-2026-09-16/phone-zh-invalid.png)、[返回并重启](evidence/authentication-session-wave1-2026-09-16/phone-zh-restart.png)、[English 真实错误凭据](evidence/authentication-session-wave1-2026-09-16/phone-en-invalid-credentials.png)、[最终 APK 首屏](evidence/authentication-session-wave1-2026-09-16/phone-en-final.png)。图中的错误凭据邮箱为虚构测试输入；密码在提交后清空。

首组截图在最终语义标签补充前采集，视觉流程相同；最后两张是最终 APK 的安装/启动复核。真实身份成功和权限通过脚本验证，设备上不保留专用真实测试账户。没有将页面 fake 证据记为真实模块集成证据。

## 2. 本期集成：不适用

Wave 1 无到期的跨模块联合场景。Authentication 运行入口只显示认证和身份状态，不建立私有业务 scope。未用未来消费者缺失阻塞本模块，也未据此宣告完整 Wave 1 完成。

## 3. 后续集成

| 待接入项 | 负责 Owner | 最迟 Wave |
| --- | --- | --- |
| Shell/Privacy 同账户 open 门控、恢复与登录失败流程 | A（Shell/Privacy） | 3 |
| 退出屏蔽 → signOut → close，失败重试及 scope 换号 | A（Shell/Privacy） | 3 |
| Account Center 使用真实 email、confirmation 三态及退出意图 | A（Account Center） | 6 |
| A→B 全部私有 Owner 的内存/文件/队列隔离 | A 主责，B 参与 | 7 |

Integrated 仍由项目负责人完成相应跨 Owner 验收后批准。

## 4. 当前阻塞：无

Wave 1 本 Feature 所需证据已具备。邮件限流影响立即重跑注册成功路径，已保留真实注册成功与当前限流失败的分别证据；绿色 live 测试明确标识管理员 fixture 回退，不能用回退替代其他项目未来的真实注册成功证据。
