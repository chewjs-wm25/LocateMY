# Application Shell Wave 3 — GPT-5.6 Luna High 实现审查

审查依据：`docs/design/development-standard.md` 第 3 节 Implemented 门槛；第 4 节截至 Wave 3 的接线与联合验收。规格范围：`docs/design/modules/application-shell.md` 第 6.1 节 SHELL-W3-01–08。基线：81ebb9bc7d6313c3229cfb4f0ad3d4e9df6f9a8b；实现 acc90916；修复 b14b57b；最终源码 SHA-256：01947439d2ad3907f495ea9a9bba9f19c8808913bd3f18051846d89e6ccccefa。

两个独立审查代理均使用 GPT-5.6 Luna / High，分别判断 Standards 与 Spec。首轮发现两项当前阻塞，修复后复审。

## Standards

首轮硬性问题：Shell Widget 测试越过 Auth 模块公开入口，直接构造内部 use case。Shell 与应用级测试已统一改用公开 `createAuthenticationViewModel`，删除跨模块内部 import。

首轮判断项：Shell intent/contribution 校验流程存在可能的重复代码；属于维护性建议，不构成 Implemented 阻塞。两条路径的不同公开结果类型保持清楚，当前没有为此扩大重构范围。

复审结论：首轮 hard violation 已关闭，未发现新的 documented-standard violation。唯一公开 ApplicationShell seam、依赖方向、旧 scope 屏障与状态机并发约束符合规范。Shell focused tests 19 项通过；真实设备、live、构建扫描及源码版本证据完整，达到 Implemented。

## Spec

首轮证据问题：SHELL-W3-07 语言保存失败没有实际故障注入，报告过度声明覆盖。已在 Shell 页面注入存储返回 false / 抛异常 × zh / en 初始语言。测试复现立即失败提示仍使用旧语言，随后修复为当前选中 locale。四项测试观察相应提示、当前语言不退回、双 Tab 仍可用、失败不持久化及重试持久化。

复审结论：SHELL-W3-07 证据阻塞已关闭；未发现新的 Spec 缺陷、错误实现或 scope creep。四项故障注入和恢复测试通过；SHELL-W3-01–08 本模块项及截至 Wave 3 的到期责任满足，达到 Implemented。

## 模块实现

`Implemented`；验收证据见 [Wave 3 验收记录](application-shell-wave3-acceptance-2026-09-16.md)。格式、静态分析、105 项确定性测试通过，4 项 opt-in live 按设计跳过；Shell live 单独执行通过。新生产 APK 与两设备证据归档于 evidence/application-shell-wave3-review-2026-09-16/。

## 本期集成

真实 Auth / Privacy / Shell 的启动、退出屏障、当前设备会话结束、持久 closing 恢复和换号联合验证通过。生产缺失未来六个 participant 时返回精确 incomplete。测试 future proofs 明确标识，不替代未来生产清理。

## 后续集成

Wave 4 A：Home、Map/Location；Wave 5 A/B：Cost、Crime、Facilities、Transportation、Hazard；Wave 6 A/B：Socio-economic、Infrastructure、Property、Account Center；Wave 7 A 主责、B 参与：Personalized Suitability 与完整八项真实清理、远端保留、换号联合验收。模块 `Integrated` 仍由项目负责人完成跨 Owner 验收后批准。

## 当前阻塞

无。首轮两项阻塞均已修复并经对应轴复审关闭。

审查计数：Standards 当前硬性违反 0，非阻塞 smell 1；Spec 当前缺陷/证据阻塞 0。
