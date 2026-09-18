# Account Privacy Wave 2 — GPT-5.6 Luna High 独立审查

日期：2026-09-16
审查基线：`ab9ad1e`（工作区未提交变更；源码版本清单记录同一基线及逐文件 SHA-256）
审查范围：Account Privacy Wave 2 新增/修改实现、公开入口、Auth participant、确定性测试、live 测试、设备 harness、APK 与本次交付证据。未读取历史 `docs/human/` 文档或 `docs/old/`。

## 结论

结论：Account Privacy Wave 2 **达到 `Implemented`**。本模块当前没有实现验收阻塞，可以由实现者声明 `Implemented`；这不等于 `Integrated`，也不等于完整 Account Privacy 联合验收已经完成。

判定依据是开发规范第 3 节要求的生产行为、公开结果、失败/恢复、并发/过期、真实上游关键路径、格式/分析/测试/APK 与可追溯证据均已满足（[development-standard.md:35-44](../../docs/design/development-standard.md#L35-L44)）。模块契约将 Wave 2 范围限定为真实 scope 状态机、固定八项登记、关闭协调、结果校验和幂等恢复；七个未来 participant 与 Shell 接入明确留到后续 Wave（[account-privacy.md:181-196](../../docs/design/modules/account-privacy.md#L181-L196)）。

## 模块实现

实现与 `PRIVACY-001` 声明一致。唯一入口导出契约类型并提供装配/释放辅助入口（[account_privacy.dart:3-24](../../lib/features/account_privacy/account_privacy.dart#L3-L24)）；公开类型、八个 participant ID、typed outcomes 和 failure 枚举与契约第 3 节一致（[account_privacy_models.dart:3-127](../../lib/features/account_privacy/src/domain/account_privacy_models.dart#L3-L127)）。

逐项判定如下：

| 场景 | 判定 | 实现与证据 | 契约/门槛对应 |
| --- | --- | --- | --- |
| `PRIV-W2-01` 恢复/登录开启 | 通过 | `open` 重新取得 `AUTH-001`，校验非空且同账户；closing、失效、不可用和不匹配拒绝（[coordinator.dart:112-180](../../lib/features/account_privacy/src/application/account_privacy_coordinator.dart#L112-L180)）。公开入口测试覆盖无会话、不可用、空白和不匹配；live 证明真实身份/open；设备首轮及重启均通过（[live-test.txt:1-4](evidence/account-privacy-wave2-2026-09-16/live-test.txt#L1-L4)、[owner-a-device-launch.txt:1-5](evidence/account-privacy-wave2-2026-09-16/owner-a-device-launch.txt#L1-L5)）。 | 契约第 5.1 节 `PRIV-W2-01`；实现门槛要求本模块项全部通过。 |
| `PRIV-W2-02` 同 scope 幂等/并发/过期 | 通过 | `_revision` 使晚到 open 失效，`identical` 约束 close 必须使用当前生命周期 scope；重复 close 共用同一 future，已清 participant 不再调用（[coordinator.dart:95-109](../../lib/features/account_privacy/src/application/account_privacy_coordinator.dart#L95-L109)、[coordinator.dart:184-227](../../lib/features/account_privacy/src/application/account_privacy_coordinator.dart#L184-L227)、[coordinator.dart:230-299](../../lib/features/account_privacy/src/application/account_privacy_coordinator.dart#L230-L299)）。确定性测试覆盖并发、旧 scope、closing 时 open、超时晚到和 dispose 后晚到；两台设备日志均证明重复 open、普通重建和关闭流程通过（[owner-a-device-launch.txt:2-16](evidence/account-privacy-wave2-2026-09-16/owner-a-device-launch.txt#L2-L16)、[owner-b-emulator-restart.txt:4-18](evidence/account-privacy-wave2-2026-09-16/owner-b-emulator-restart.txt#L4-L18)）。 | 契约第 5.1 节 `PRIV-W2-02`；开发规范第 3 节并发/过期响应要求。 |
| `PRIV-W2-03` 固定八项、失败/异常/超时和恢复 | 通过 | 装配时冻结 participant ID；缺项或重复项不构成唯一匹配，登记 getter 异常使注册不可用；每个 participant 的返回 ID 与原 scope 均校验，异常/超时转换为 typed incomplete（[coordinator.dart:24-47](../../lib/features/account_privacy/src/application/account_privacy_coordinator.dart#L24-L47)、[coordinator.dart:230-299](../../lib/features/account_privacy/src/application/account_privacy_coordinator.dart#L230-L299)）。先进入 closing，只有全部八项成功且 barrier 删除成功才 closed；已清项不会回滚（[coordinator.dart:212-227](../../lib/features/account_privacy/src/application/account_privacy_coordinator.dart#L212-L227)、[coordinator.dart:301-323](../../lib/features/account_privacy/src/application/account_privacy_coordinator.dart#L301-L323)）。公开测试含 8×5 failure matrix、缺项/重复/错 ID/错 scope/异常及权限故障；全仓结果 86 项通过（3 项 opt-in live 跳过）（[tests.txt:69-91](evidence/account-privacy-wave2-2026-09-16/tests.txt#L69-L91)）。 | 契约第 5.1 节 `PRIV-W2-03`；`RISK-PRIVACY-01/02` 的 Wave 2 本模块关闭条件。 |
| `PRIV-W2-04` Auth 失效/身份不符 | 通过 | Auth participant 只验证当前设备已结束，不主动 `signOut`；活动或未知 session 返回 incomplete，明确 `UnauthenticatedSession` 才返回 cleared（[authentication_privacy_participant.dart:6-43](../../lib/features/authentication_session/src/application/authentication_privacy_participant.dart#L6-L43)）。Privacy 监听实时 Auth 失效并立即把 opened scope 置为 closing（[coordinator.dart:69-93](../../lib/features/account_privacy/src/application/account_privacy_coordinator.dart#L69-L93)）。live 日志证明当前设备退出和结束会话 proof；设备日志也通过真实 signOut/participant proof（[live-test.txt:2-4](evidence/account-privacy-wave2-2026-09-16/live-test.txt#L2-L4)、[owner-a-device-restart.txt:8-11](evidence/account-privacy-wave2-2026-09-16/owner-a-device-restart.txt#L8-L11)）。 | 契约第 5.1 节 `PRIV-W2-04`；Auth 边界与 `RISK-SESSION-01` 只接受可确认事实。 |
| `PRIV-W2-05` A→B barrier | 通过（Wave 2 子项） | 未完成旧 scope 时 `open(B)` 被 closing/identity barrier 拒绝；完整 fake 集合完成后 B 获得新 scope。live 生产登记仅有 Auth participant，七项缺失会阻止关闭和 B；真实另一设备会话保留（[account_privacy_live_test.dart:67-94](../../test/live/account_privacy_live_test.dart#L67-L94)）。设备 A/B 用真实 Auth + 七个明确 `TEST FAKE` 完成协调流程（[owner-a-device-launch.txt:10-15](evidence/account-privacy-wave2-2026-09-16/owner-a-device-launch.txt#L10-L15)）。 | 契约第 5.1 节 `PRIV-W2-05`；未来真实 payload 隔离属于 Wave 7。 |
| `PRIV-W2-06` 清理中重启/普通同账户恢复 | 通过（Wave 2 子项） | 屏障文件只保存版本、account id 和阶段；opened 重建必须重新验证同账户 Auth，closing 重建不可 open、只能用重建后的八项 proof 继续；flush + rename/读写/删除/损坏故障均保持非 opened（[account_scope_journal.dart:6-78](../../lib/features/account_privacy/src/data/account_scope_journal.dart#L6-L78)、[coordinator.dart:50-67](../../lib/features/account_privacy/src/application/account_privacy_coordinator.dart#L50-L67)）。两台目标设备均完成真正 force-stop/relaunch，首轮 `READY_RESTART`、重启 `ALL PASS`（[owner-a-device-restart.txt:1-18](evidence/account-privacy-wave2-2026-09-16/owner-a-device-restart.txt#L1-L18)、[owner-b-emulator-restart.txt:1-18](evidence/account-privacy-wave2-2026-09-16/owner-b-emulator-restart.txt#L1-L18)）。 | 契约第 5.1 节 `PRIV-W2-06`；契约第 5.3 节恢复和屏障要求。 |

账户范围没有吸收业务 payload、远端删除、公共缓存或语言；这符合数据所有权中 `STATE-ACCOUNT-SCOPE` 及“Account Privacy 不拥有参与者业务数据/队列 payload”的边界（[data-ownership.md:6-16](../../docs/design/system/data-ownership.md#L6-L16)）。生产 Auth factory 和 participant 位于 Auth 唯一入口（[authentication_session.dart:1-18](../../lib/features/authentication_session/authentication_session.dart#L1-L18)），七个 future owner 没有生产成功占位；设备 harness 中的七个 fake 有明确标记且只验证协调协议（[account_privacy_wave2-acceptance-2026-09-16.md:29-33](account-privacy-wave2-acceptance-2026-09-16.md#L29-L33)）。

源码版本清单共 47 个文件；本地 SHA-256 独立复算无 mismatch，且 `sourceSha256` 对应本次交付源码。格式、静态分析、测试、APK 构建和扫描均有日志：格式 45 files/0 changed（[format.txt:1](evidence/account-privacy-wave2-2026-09-16/format.txt#L1)），分析无问题（[analyze.txt:1](evidence/account-privacy-wave2-2026-09-16/analyze.txt#L1)），debug harness 与普通 APK 均构建并通过扫描（[device-build.txt:1-10](evidence/account-privacy-wave2-2026-09-16/device-build.txt#L1-L10)、[production-build.txt:1-10](evidence/account-privacy-wave2-2026-09-16/production-build.txt#L1-L10)）。这些结果符合 ADR 0011 允许 AI 审查/验证项目代码且由 Owner 保留 `Integrated` 决定的边界（[ADR 0011:14-18](../../docs/adr/0011-human-coded-ai-designed-delivery-process.md#L14-L18)）以及 ADR 0016 的实现授权（[ADR 0016:5-7](../../docs/adr/0016-ai-managed-supabase-development-environment.md#L5-L7)）。

审查中唯一的文档一致性观察是：Auth 公共 barrel 新增了两个装配 helper，而 Auth owning contract 的实现表仍写作“Functions / constructors：无”、公开入口“只导出声明与领域类型”（[authentication-and-session.md:317-323](../../docs/design/features/authentication-and-session.md#L317-L323)、[authentication-and-session.md:330-333](../../docs/design/features/authentication-and-session.md#L330-L333)）。本次 Account Privacy 契约已明确记录这些 helper 的 Wave 2 用途（[account-privacy.md:206-214](../../docs/design/modules/account-privacy.md#L206-L214)），且 `AUTH-001` 的 caller-visible declarations 没有改变；因此这不阻塞 Account Privacy Wave 2 `Implemented`，建议在下次 Auth 文档同步时补充装配 helper，避免触发 ADR 0015 所说的公共入口文档漂移（[ADR 0015:5-7](../../docs/adr/0015-contract-first-two-person-development-handoff.md#L5-L7)）。

## 本期集成

Wave 1 没有遗留至 Wave 2 到期的联合项；这一点与契约验收分配及交付记录一致（[account-privacy.md:196](../../docs/design/modules/account-privacy.md#L196)、[account-privacy-wave2-acceptance-2026-09-16.md:38-40](account-privacy-wave2-acceptance-2026-09-16.md#L38-L40)）。本期唯一真实上游 `AUTH-001` 与 Auth participant 已通过 live/设备公开入口验证；live 也证明当前设备退出 proof 和另一设备会话保留（[live-test.txt:1-4](evidence/account-privacy-wave2-2026-09-16/live-test.txt#L1-L4)）。

设备 Owner A 真机的直连路径曾因 Dozing/SocketException 不可用；最终证据采用受限 `adb reverse` CONNECT 到同一 Supabase 主机，TLS 端到端、无拦截，Dart/SDK 和文件存储仍为设备真实实现（[device-transport.txt:1](evidence/account-privacy-wave2-2026-09-16/device-transport.txt#L1)）。因此本报告把它判为已满足本期设备调用证据，同时明确不把它表述为手机直连网络成功。Shell 完整门控、退出顺序以及真实业务 payload 的八 Owner 清理没有在 Wave 2 提前宣告通过。

## 后续集成

这些事项均已在契约中指定 Owner 和最迟 Wave，属于未来联合验收范围，不构成当前 Wave 2 阻塞（开发规范第 3 节规定未来消费者未到期限时记为后续集成项，[development-standard.md:40-44](../../docs/design/development-standard.md#L40-L44)）：

- Wave 3：Owner A 接入 Shell/真实 Auth participant，完成冷启动同账户 opened 门控、先屏蔽私有 UI/意图再 `signOut` 再 `close` 的顺序及恢复流程。
- Wave 4：Owner A 接入 Map participant 与收藏私有 cache/create queue，证明账户分区和其真实本机 Adapter 的清理故障恢复。
- Wave 5：Cost（Owner B）与 Hazard（Owner A）接入真实 participant；验证各自内存、请求和私有副本清理，保留远端记录/公共去身份缓存。
- Wave 6：Infrastructure/Property（Owner B）与 Account Center（Owner A）接入真实 participant；验证 ICI/草稿/照片/待传/偏好边界及文件/SQLite 故障。
- Wave 7：Owner A 主责、Owner B 参与，完成八项真实 participant 的 A→B 隔离、旧 scope 不可读/提交/重放、公共缓存/语言/远端记录保留、部分清理与跨进程恢复联合验收。七个 fake 不能替代该证据。

## 当前阻塞

**无。** 当前实现验收的六项 `PRIV-W2-01` 至 `PRIV-W2-06` 均有本模块证据；格式、分析、86 项全仓测试（3 项 opt-in live 默认跳过）、20 项 Privacy/Auth 公开入口测试、Privacy live、Owner A 真机、Owner B API 36 模拟器、实际 force-stop/relaunch、debug APK/普通 APK 扫描及恢复安装均有可追溯记录。交付记录明确列出同一结果（[account-privacy-wave2-acceptance-2026-09-16.md:24-48](account-privacy-wave2-acceptance-2026-09-16.md#L24-L48)）。

当前结论是模块 `Implemented`、本期到期集成通过、完整跨 Wave 联合仍待后续期限；项目负责人仍需按 ADR 0011 和开发规范另行批准 `Integrated`。
