# Application Shell — Wave 3 验收记录

> 实现状态：Implemented；GPT-5.6 Luna High Standards / Spec 双轴复审通过。未批准 Integrated。
> 范围：docs/design/modules/application-shell.md 第 6.1 节。
> 代码基线：81ebb9bc7d6313c3229cfb4f0ad3d4e9df6f9a8b；工作树 source SHA-256 以 live/device/production 的 source.json 为准。

## 1. 模块实现

Implemented。当前证据：SHELL-001 canonical declarations、scope 门控/失效屏障、导航/返回与渐进组合、真实 Shell privacy participant、Auth/Privacy 接线和双语设备偏好均已实现。Implementation use case 不依赖 Flutter/SDK/文件 API；呈现由 ShellViewModel/Host 绑定。Feature 只消费 application_shell.dart；组合根通过 app.dart 装配辅助注册提供方 marker 投影与原输入 builder。

| 分配 | 验证证据 |
| --- | --- |
| SHELL-W3-01 | application_shell_test.dart 门控/identity mismatch/verification-required；Widget 认证页历史回归；live 与设备初始 opened |
| SHELL-W3-02 | 立即关闭、拒绝旧输入、同 scope 重试、Auth 失败仍 close、pending open 退出测试；真实 Privacy 缺六项精确阻断；设备 recovery → Retry |
| SHELL-W3-03 | scope 绑定旧 Shell 不可重放；真实 Privacy 持久 closing 重建；live A/B；两设备 restart 恢复旧 scope 后再新账户打开 |
| SHELL-W3-04 | IndexedStack 交互 count 保留；仅两 NavigationDestination；账户普通任务；Android 系统返回；设备首页/地图/账户实际 UI-tree tap |
| SHELL-W3-05 | 原 A/B 顺序 marker 原对象传目标 builder；missing/stale intent 保持导航与返回语境；设备 typed input/return |
| SHELL-W3-06 | public publish 保留原 marker、来源/日期/口径与 unavailable/partial；stale 不覆盖；任务与独立槽位 Widget；设备原贡献/过期响应 |
| SHELL-W3-07 | 双 locale 小屏 200%/可读 tooltip/恢复；language_support_test.dart 持久化/动态错误；Shell Widget 注入保存 false/异常，验证两语言提示、选中语言保留及重试持久化；设备 EN 跨退出/换号/重启 |
| SHELL-W3-08 | fake_application_shell.dart 只实现 canonical ApplicationShell；运行时 intent/contribution accepted/auth-required/rejected 三种结果；消费者实际恢复行为按 future Wave |

验证命令：dart format --output=none --set-exit-if-changed .；flutter analyze；flutter test --reporter expanded；flutter build apk --debug。确定性全量 105 passed / 4 opt-in live skipped；Shell opt-in live 1 passed。两设备完整实际 Auth/Privacy/Shell 流程通过。

临时测试命令：python3 tool/verify_application_shell_live.py --evidence-dir build/shell-wave3-final-evidence --devices emulator-5554 <Owner A wireless serial>。设备 transport 仅 host CONNECT 转发、限定 Supabase host、TLS 端到端；不替换 Auth/Privacy/Shell Adapter。Owner A 真实 Android 手机；Owner B Android Studio emulator。设备测试使用隔离偏好/屏障命名空间与临时 A/B 账户；未来六项证明有醒目标识，不是生产清理。

## 2. 本期集成

Auth 第 6.1 节截至 Wave 3 的启动/登录门控、退出屏障/当前设备 Auth 结束和 Privacy close，以及 Privacy PRIV-W2-01–06 的 Shell 子项通过。真实 Auth participant/Shell participant 和真实 Privacy 持久 journal 有公开调用/设备证据。生产六个未来 Owner 缺项时只报告 incomplete，不伪称全部退出成功。

## 3. 后续集成

- Wave 4（A）：Home ExploreMapIntent 与 Map/Location 真实页面/地点/收藏清理接入。
- Wave 5（A/B）：Cost、Crime、Facilities、Transportation、Hazard 真实 marker、返回与贡献；Cost/Hazard 各自真实 private cleanup。
- Wave 6（A/B）：Socio-economic、Infrastructure、Property、Account Center 接入；各自本机 Adapter 清理/故障/恢复。
- Wave 7（A 主责、B 参与）：Personalized Suitability；完整八项 payload/queue/file/远端保留与 A/B 隔离联合验收。当前 test future proofs 不代替这些证据。

## 4. 当前阻塞

无。首轮 Auth 内部测试 import 与语言保存失败证据两项阻塞已关闭；[Luna High 双轴复审](application-shell-wave3-luna-review-2026-09-16.md) 确认本模块达到 Implemented。截至 Wave 3 到期接线与联合验证通过，Wave 3 达到完成门槛。后续 Feature/participant 接入不等于 full Wave 7 已通过。

## 5. 审查修复与补充证据

首轮 Luna 审查指出应用消费者测试越过 Auth 公开入口，以及语言保存失败缺少证据。已统一使用 createAuthenticationViewModel；平台存储故障注入复现保存立即失败时提示使用旧语言，随后修复为使用当前选中 locale。四项失败/恢复 Widget 测试通过；补充 review-language-red.txt、review-language-regression.txt、review-full-tests.txt、review-analyze.txt、review-format.txt。测试所需 shared_preferences_platform_interface 明确列为 dev dependency，锁定版本不变。新生产/live/两设备全流程重跑已通过，证据归档于 [复审版本证据](evidence/application-shell-wave3-review-2026-09-16/final-audit.txt)。代码修复版本 b14b57b；源码 SHA-256 为 01947439d2ad3907f495ea9a9bba9f19c8808913bd3f18051846d89e6ccccefa；三个 source.json 均匹配当前源码且 exit 0。普通 APK 已通过凭据扫描并恢复两设备；隔离测试目录/临时账户/隧道已删除。
