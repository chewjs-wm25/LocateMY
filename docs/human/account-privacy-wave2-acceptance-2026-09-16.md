# Account Privacy — Wave 2 验收记录

日期：2026-09-16；Owner A。权威范围是 [Account Privacy 契约](../design/modules/account-privacy.md) 第 5.1 节，完成标准是 [开发规范](../design/development-standard.md) 第 3 节。设计仍为 Ready for Development；本模块达到 **Implemented**，经 [GPT-5.6 Luna High 独立审查](account-privacy-wave2-luna-review-2026-09-16.md) 确认，当前阻塞为零，不宣告 Integrated。

## 模块实现

已实现唯一入口 AccountPrivacy 的身份检查、范围生命周期、固定八项登记、关闭证明校验、逐项失败/异常/超时、并发幂等、已清项保留及持久恢复；接入真实 AUTH-001 和 Auth participant。Privacy 不读取参与者 payload，也不删除远端记录、Storage、其他设备会话、公共缓存或语言。

范围进入 opened 前持久化身份与 opened 阶段。普通同账户重建须重新验证当前 Auth，可以恢复 opened，保留未来需要跨重启的草稿。无会话、不可确认或不同账户时封锁并关闭旧范围；close 开始立即 closing，并在清理前持久化 closing 标记，标记只修改阶段字节以保留身份。closing 记录重启后不能 opened，需要同旧范围重新取得八项幂等证明。文件不可读/写/删或损坏时保持非 opened，修复后重读/重试；损坏身份不能由新 Auth 覆盖。

| 当期场景 | 本模块证据 | 联合责任 |
| --- | --- | --- |
| PRIV-W2-01 当前明确同账户开启；无会话/不可用/空白/不匹配不得开启 | [公开入口测试](../../test/features/account_privacy/account_privacy_test.dart)、[live 日志](evidence/account-privacy-wave2-2026-09-16/live-test.txt)、设备首屏及重启 | Shell 同账户门控，A，Wave 3 |
| PRIV-W2-02 同 scope 幂等、并发、晚到/过期响应 | 公开入口重复/并发 open/close、构造 scope 冒充拒绝、新生命周期旧 scope 拒绝、超时晚到证明及 dispose 后晚到清理测试；设备普通同账户协调器重建 | Shell A Wave 3；完整真实八项 A 主责/B 参与 Wave 7 |
| PRIV-W2-03 逐 Owner 全失败类型、缺项、重复 ID、登记异常、错 ID/scope、异常与恢复 | 8×5 故障矩阵、精确非空/唯一 incomplete、重试已清项不恢复、先 closing、全部证明才 closed；Linux 真实文件权限故障；设备具名 fake 文件清理失败 | Auth/Shell A Wave 3；Map A Wave 4；Cost B/Hazard A Wave 5；Infrastructure/Property B、Account Center A Wave 6；全员 Wave 7 |
| PRIV-W2-04 失效/身份不符、B 无法替换未关闭 A；真实当前设备退出证明 | 公开入口恢复/实时 Auth 失效及过期响应测试；[Auth participant 测试](../../test/features/account_privacy/authentication_privacy_participant_test.dart)；live 当前设备退出证明及另一设备保留；设备 real signOut/证明 | Shell 先屏蔽→signOut→close，A，Wave 3 |
| PRIV-W2-05 A→B、失败重试与新范围 | 公开入口双账户测试；live 生产缺七项不能闭合/B 不能开启；设备真实 A/B 身份 + 七个明确 TEST FAKE participant 完成协调流程 | 范围切换 Shell A Wave 3；真实旧 payload 不可见/提交/重放、保留公共缓存/语言/远端，全员 A 主责/B 参与 Wave 7 |
| PRIV-W2-06 清理中进程重启、普通同账户恢复、不可写/读/损坏恢复 | 公开入口协调器重建、权限故障、损坏屏障和晚到证明测试；设备真正 am force-stop/relaunch 读取同旧范围 closing 并恢复关闭 | Shell A Wave 3；Map 持久存储 A Wave 4；Property SQLite/照片故障 B Wave 6；全员 Wave 7 |

证据必须关联 [源码版本清单](evidence/account-privacy-wave2-2026-09-16/source-version.json)，其中记录基线 HEAD 和逐文件 SHA-256。当前测试、live、设备及 APK 对应该清单的实现源码；报告/HTML 不进入源码摘要。

## 验证操作与环境

- `dart format --output=none --set-exit-if-changed .`：[格式日志](evidence/account-privacy-wave2-2026-09-16/format.txt)。
- `flutter analyze`：[分析日志](evidence/account-privacy-wave2-2026-09-16/analyze.txt)。
- `flutter test --reporter expanded`：[全仓测试日志](evidence/account-privacy-wave2-2026-09-16/tests.txt)。Privacy 公开入口和 Auth participant 共 20 项；8×5 失败矩阵是单个公开行为测试中的已知失败枚举场景。默认跳过三项 opt-in live；本次 Privacy live 单独执行。
- `python3 tool/verify_account_privacy_live.py --devices <Owner A serial> emulator-5554`：[live](evidence/account-privacy-wave2-2026-09-16/live-test.txt)、[harness APK](evidence/account-privacy-wave2-2026-09-16/device-build.txt)、[普通 debug APK](evidence/account-privacy-wave2-2026-09-16/production-build.txt)、[恢复安装](evidence/account-privacy-wave2-2026-09-16/restoration.txt)。

开发环境为 Linux / Flutter 3.47.2 / Dart 3.13.2，Supabase Flutter 2.17.2，路径插件固定 2.1.6。live 使用本地 test_credentials.local.md 原变量名注入，真实登录/退出，不读写业务表。B 与设备 A/B 是临时确认账户，结束后删除；个人登录、密钥、token 和临时密码不写入报告、截图或普通 APK。

设备 harness 没有私有业务页面。Auth、Auth participant、Privacy 协调器与本机文件真实；七个未来 Owner 是显示标记的 TEST FAKE，仅证明关闭协议，不证明业务清理。生产登记只放真实 Auth participant，返回其余七项 incomplete。

Owner A 目标为 Samsung SM-A528B；Owner B 补充目标为 LocateMY_QA Android API 36 模拟器。真机先前处于 Dozing，直接网络出现 SocketException。最终验收唤醒设备、临时延长熄屏时间，通过 adb reverse 的受限 CONNECT 隧道路由到同一真实 Supabase，TLS 端到端且无拦截，设备 Dart/SDK 与私有文件仍真实；[网络条件](evidence/account-privacy-wave2-2026-09-16/device-transport.txt)。这不是直连网络成功证据。结束后恢复熄屏设置和普通 APK，并删除隧道。

- Owner A：[首轮退出/失败/恢复日志](evidence/account-privacy-wave2-2026-09-16/owner-a-device-launch.txt)、[进程重启日志](evidence/account-privacy-wave2-2026-09-16/owner-a-device-restart.txt)、[首屏截图](evidence/account-privacy-wave2-2026-09-16/owner-a-device-launch.png)、[重启截图](evidence/account-privacy-wave2-2026-09-16/owner-a-device-restart.png)。
- Owner B 补充：[首轮日志](evidence/account-privacy-wave2-2026-09-16/owner-b-emulator-launch.txt)、[重启日志](evidence/account-privacy-wave2-2026-09-16/owner-b-emulator-restart.txt)、[首屏截图](evidence/account-privacy-wave2-2026-09-16/owner-b-emulator-launch.png)、[重启截图](evidence/account-privacy-wave2-2026-09-16/owner-b-emulator-restart.png)。

## 本期集成

Wave 1 未留下截至 Wave 2 到期的联合项。本模块当期真实 Auth 消费与退出证明由 live/设备公开入口验证。完整 Shell 工作流不在 Wave 2 到期；完整八类 payload 联合清理不能由七项 fake 宣告通过。

## 后续集成

依契约第 5.1 节：Shell/真实 Auth participant 接线和冷启动/退出顺序 A Wave 3；Map participant/私有收藏存储 A Wave 4；Cost B 与 Hazard A Wave 5；Infrastructure/Property B、Account Center A Wave 6；全员真实隔离、清理、保留项和联合恢复 A 主责、B 参与 Wave 7。没有提前提供生产成功占位。

## 当前阻塞与审查

最终格式、分析、86 项全仓测试（3 项 opt-in live 默认跳过）、20 项 Privacy 公开入口测试、Privacy live 1 项、真机/模拟器首轮与实际重启、普通 APK 构建及凭据扫描均通过。设备恢复安装通过，临时账户与隧道已删除。GPT-5.6 Luna High 已独立审查通过，未发现需立即修复的真实实现缺陷；本模块 Implemented，当前阻塞：无。后续联合期限保持原分配，不宣告 Integrated。
