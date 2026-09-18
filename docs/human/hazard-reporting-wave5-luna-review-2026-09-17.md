# Hazard Reporting — GPT‑5.6 Luna High 双轴审查

2026-09-17；模型 `gpt-5.6-luna`，reasoning effort `high`；审查基点 `29eec8d61a42fd85c809014b4fb8b3b66e2d9a69`。两个只读审查 agent 分别按 Standards（Development Standard、架构、Dart §7）和 Spec（Hazard owning contract、事实源、AT 分配）审查；没有让审查者代写实现。

## 发现与修正

| 发现 | 修正及验证 |
| --- | --- |
| provider callback 固定写 map 返回 ID | composer / detail / mine 贯穿 returnContextId；Shell 使用当前 context 保留任务栈；Map marker 无额外 context 参数，保持 Map 入口；真实 Shell 返回测试 |
| 投票聚合缺少非负边界 | 共用整数且非负的 vote parser；负值 Adapter 断言 red → green |
| 投票写成功但补刷失败丢失新票 | 使用权威 HazardVoteChanged.state 更新详情后再补刷；公开详情 Widget 验证失败仍显示新计数 red → green |
| count reference 输入验证不足 | 空 opaque locationId 拒绝；RPC 马来西亚行政边界验证拒绝伪造境外点；真实调用 red → migration → green |
| 生产 partial 页缺少可用子集 | 单行 decode 失败保留合法行、cursor / viewport、typed HazardPagePartial；后页失败 / 原 cursor 重试保留与合并既有图层 |
| MapLayerRejected 全部当作账户失败 | staleViewport 等待新 viewport、保留报告；scope / authentication / invalid 精确映射；公开 panel 测试 red → green |
| 正文未继承 Penpot 字体 | app 全局 textTheme 使用 SourceSansPro，普通标签 / 正文 / 按钮继承；核对 Penpot 12 / 13 / 14 boards 与设备截图 |
| partial 使用一般 retryable failure | 改用契约 incompletePage；专用 failure 断言 red → green |

复审确认前述代码问题均修复；Hazard 28 tests、静态分析、真实 live 3 tests、debug APK / secret scan 通过，没有新增 Hazard 代码缺陷。审查者明确：并行 Transit / Facilities 新测试失败不属于 Hazard 本模块缺陷，但仍影响全仓 CI / Wave 5 完成，不据此宣告整个 Wave 完成。

## 最终判定

两轴最终均批准 **Implemented**；当前未修复发现为 0、实现阻塞为 0。

| 审查轴 | 最终结果 | 依据 |
| --- | --- | --- |
| Standards | 通过；Implemented | MVVM / Adapter 分层、Dart §7、scope 生命周期；28 Hazard tests、全仓 263 passed / 11 skipped、analyze、156-file format 0 changes、live 3、双设备、最新 APK / secret scan |
| Spec | 通过；Implemented | AT-HAZARD-01–05、AT-PROP-03 提供方、partial / stale / 权限 / 恢复 / Penpot UI；真实 Shell / Map / Privacy 接线；未来 Property 明确 Wave 6 |

末次收尾发现完整分页后 Refresh 无动作，已额外 red → green 修复：Refresh 始终加载第一页，Retry 保留后页 cursor；invalidViewport / expired cursor 重置第一页。最高公开 HazardMapPanel 测试覆盖两分支，Luna 两轴增补复审确认不改变样式 / 正常成功 / 已验证设备流程，维持 Implemented。

双设备完整流程 PASS；此前并行 Feature 测试失败已修正，最新全仓质量 PASS。QA APK 快照、后续并行 root 与最后非视觉恢复 delta 的差异如实记录在 source-difference.txt；最终 production APK / quality 的 Hazard hash 相同。

验收与代码版本追溯见 [验收报告](hazard-reporting-wave5-acceptance-2026-09-17.md)。Property 的 Wave 6 snapshot consumer 属于后续集成；Integrated 需项目负责人批准。
