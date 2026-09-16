# Wave 1 Authentication & Session 开发与验证

日期：2026-09-16。认证 Feature 已实现；跨 Wave 的 Account Privacy、Application Shell 和 Account Center 集成仍由后续 owning contract 验收。本次保留既有 AUTH-001 的唯一入口和全部公开声明，没有修改数据模型、RLS 或 Supabase 依赖版本。

## 已实现与修复

- MVVM 登录/注册表单、必填与邮箱校验、确认密码、提交锁、类型化错误反馈和注册验证邮件提示。
- 恢复通过 SDK `getSession()` 按需刷新，并向 Auth 校验真实用户；离线、过期、远端拒绝及未知失败都不能授权缓存身份。
- watchSession 首个快照也经过校验；SDK 失败、非自愿退出、会话过期和新账户快照替换旧事实。取消订阅会释放计时器。
- 防止初始化重复订阅，以及恢复/登录请求晚到时重新显示已失效的账户。
- 会话状态页显示真实邮箱与确认事实；未知确认状态不会显示“已验证”。认证后隐藏登录表单，当前页面不创建私有业务 scope。
- composition root 发起当前设备退出：先隐藏身份，失败时阻止普通登录并给重试入口；取消退出保持会话。
- 可选 username 资料失败不撤销认证；当前进程内可单独重试资料写入，采用 owner-only upsert。待验证期间不以匿名身份写 profiles。
- 表单切换和提交结束后清除密码；页面销毁后的异步完成不再访问已销毁的 controller。
- Supabase 配置支持本机 `.env` 和 `--dart-define-from-file`，缺少配置时显示可理解提示；只接受 publishable key。补齐 Android INTERNET 权限及 CI 的公开配置占位文件。

## 自动化检查

以下检查全部通过：

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
git diff --check
```

30 项测试由 15 项真实 SDK HTTP Adapter 测试、9 项 ViewModel 测试和 6 项 Widget 测试组成。Adapter 测试通过 SupabaseClient 和 MockClient 驱动真正的认证请求与结果映射，不使用生产 Adapter 的假实现。覆盖无会话、真实确认、离线、刷新成功/失败、远端拒绝、凭据错误、验证注册、资料失败/重试、当前设备退出、限流、弱密码及晚到请求。Widget 测试还验证小屏和大字体布局。

## Android 实际 UI 测试

设备：Android 36 Google APIs x86_64 模拟器 `LocateMY_QA`，1080×2400；以 adb 操作。每次点击由 UI tree bounds 推导坐标，并保留步骤截图。安装真实 Flutter debug APK，接入仓库已经运行的本地 Supabase 开发栈（模拟器访问 `10.0.2.2:54321`）。未向远端生产项目创建测试账户或修改配置。

| 场景 | 结果 |
| --- | --- |
| 无会话首屏、空字段提交 | 登录入口；字段错误可见，未提交认证 |
| 注册密码不一致 | 显示修正提示，不创建账户 |
| 实际注册与可选 username | 认证成功；真实邮箱和已确认状态可见；本地 profiles 资料已保存 |
| 错误密码与正常登录 | 错误凭据可修正；重新输入密码后登录成功 |
| 进程停止后重新启动 | 恢复同一账户及真实确认事实 |
| 取消退出、确认退出 | 分别保留当前会话、返回无旧身份的登录入口 |
| 关闭模拟器 Wi-Fi/移动数据后重启 | 显示不可确认会话的门控，不显示缓存账户 |
| 恢复网络并重试 | 重新校验后恢复会话 |
| A 退出后注册 B，再重启 | 只显示 B 的邮箱，A 身份不再出现 |
| 离线退出失败、恢复网络后重试 | 隐藏身份及登录入口；重试完成后返回登录 |
| profiles 跨账户读取 | A 的 username 已保存；B 无法读取 A 的 profile |
| 同账户另一个会话 | 本设备退出后，另一个会话仍可使用 refresh token 刷新 |

截图：

- [空字段校验](authentication-session-qa-2026-09-16/02-validation.png)
- [密码不一致](authentication-session-qa-2026-09-16/38-b-password-mismatch.png)
- [恢复真实会话](authentication-session-qa-2026-09-16/14-restored.png)
- [错误凭据](authentication-session-qa-2026-09-16/24-invalid-credentials.png)
- [离线恢复门控](authentication-session-qa-2026-09-16/28-offline-restore.png)
- [换号后恢复 B](authentication-session-qa-2026-09-16/42-b-restored.png)
- [退出失败屏障](authentication-session-qa-2026-09-16/45-signout-incomplete.png)
- [退出重试成功](authentication-session-qa-2026-09-16/47-signout-recovered.png)

最终应用进程 logcat 检查未发现 Flutter 未处理异常、应用崩溃或布局溢出。

## 验收边界

- 本地 Auth 配置关闭注册邮件确认，实际注册产生 authenticated 结果；verification-required 分支由真实 SDK HTTP 测试和 Widget 测试验证，未宣称已实测真实邮件点击回流。
- username 待补写信息仅存在于当前进程，重启后不保留；认证账户仍然有效，且不会将资料失败显示成认证失败。
- 本次没有任何私有业务 Owner 或本地私有 payload。账户身份替换及退出屏障已验证；PRIVACY-001.open/close、全 Owner 私有缓存清理、重启后的持久清理 barrier 和主应用导航仍需 Wave 2/3 联调，不将认证状态页当作 Integrated 主应用。
- 当前版本只结束本设备会话，不删除远端业务记录；完整生产设备联调需使用各 Owner 自己的目标设备验收。
