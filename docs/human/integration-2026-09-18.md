# LocateMY 全模块集成验收

日期：2026-09-18。范围：当前 ADR 0017 保留的全部生产模块。本报告与实现由同一 Git 提交追踪，父提交为 `ffd28a1`；精确源码及 APK 指纹见 evidence。

生产装配已连接 Authentication、Geo、Home、Map、六类分析、预算与 JSON、Hazard、Property 和 Account。账户新增本人隐患入口及完整当前预案金额；地图展开详情的五项摘要调用真实服务，替换固定不可用占位。全国宏观首页保持原职责，旧契约中“Home 地点摘要”追踪修正为地图消费者。

## 模块实现

本次账户入口与地图摘要已实现；其他模块沿用 owning contract 的真实业务实现。生产能力不使用测试 fake。

| 联合路径 | 实际接线与观察结果 | 证据 |
| --- | --- | --- |
| Account → Auth / Budget / Property / Hazard | 真实邮箱、语言、确认退出；当前预案五金额及未填写；真实管理入口 | account integration、设备旅程 |
| Budget → Account / Cost / Socio | 共用 CurrentBudgetReader；成功切换更新，月净收入只用于个人压力，家庭收入只用于收入位置；null 取消计算 | cost live、account integration、既有 Cost/Socio 页面测试 |
| Map → Crime / Cost / Facilities / Transit / Infrastructure | 五项原生单位；设施未知不填零，部分篮子保留项目/月数；交通直线距离粗估步行；中性 ICI 与最低/缺失分项 | summary integration、设备摘要 |
| Infrastructure → Geo / Transit | 同地点同日期 canonical 交通，摘要/A-B 使用中性权重 | infrastructure live、既有 service/widget 测试 |
| Property → Geo / Crime / Hazard / Storage | 真实风险快照、照片归属、软删/恢复/永久清空；账户与治安页面进入实勘 | property live、设备档案与既有房产页面测试 |
| App / Home / Map → 六类分析 | 登录门控、首页地图往返、合法坐标路由、单点/A-B、换号与退出结束旧树 | 全量测试、生产设备六类路径 |

## 本期集成

当前真实接线与到期联合验收已通过。Android 14 真机（Owner A）和 Android 16 模拟器（Owner B）均通过账户入口、五项真实地图摘要与六类分析进入/返回旅程。

| 检查 | 命令或入口 | 结果 |
| --- | --- | --- |
| 格式 | 本次修改/新增的 12 个手写 Dart 文件 format 检查 | 0 changes |
| 静态分析 | `flutter analyze` | No issues found |
| 全量测试 | `flutter test --reporter expanded` | 348 passed，14 个 opt-in live 默认跳过 |
| 真实预算/成本/社会经济联验 | `python3 tool/verify_cost_budget_live.py` | PASS；有效零、两个独立收入、切换通知、缺失、owner allow/deny 与恢复 |
| 真实房产风险/照片/回收站 | `python3 tool/verify_property_live.py` | PASS |
| 真实基础设施/交通/权重 | `python3 tool/verify_infrastructure_live.py` | PASS |
| 生产 debug APK | `python3 tool/verify_integration_build.py` | PASS；源码指纹匹配最终 lib，敏感信息扫描 PASS |
| Android 真机与模拟器 | `python3 tool/verify_integration_devices.py --devices <serial>` | 两端 PASS；成本与中性 ICI 实际可见；APK 源码指纹匹配最终 lib，敏感信息扫描 PASS |
| 文档与脚本 | relative links、`git diff --check`、Python compile | PASS |

新增测试从公开账户页、地图页与业务摘要入口验证外部行为，覆盖 320px/200% 中英文、预算金额/缺失、退出取消/失败/重试/成功、提供方异常隔离、坐标切换的旧响应与 dispose 后完成。

真实测试读取本地凭据，仅使用脱敏日志；测试账号/记录按既有脚本清理或恢复。设备 APK 使用隔离 application id，凭据通过运行时 loopback fixture 提供，未写入 APK。

## Standards

审查模型：GPT‑5.6 Luna，High。代码 PASS：公开入口、分层依赖、Java 阅读习惯、只读字段、账号生命周期和滚动布局无硬性违规。

两项非阻塞启发式建议：预算五金额展示可在 Cost 内复用 helper；Facilities 类别标签映射可考虑公开共享。当前遵循既有接口，不为消除建议扩大公开接口或重构范围。

## Spec

审查模型：GPT‑5.6 Luna，High。PASS，无当前阻塞。真实模块接线、当前预案联动、五项地图原生摘要、中性 ICI、缺失与失败处理符合契约；不向 Home 添加地点功能，不将 Socio/Hazard 混入地图摘要。

两轴汇总：Standards 0 硬性违规、2 非阻塞建议；Spec 0 缺陷。

## 后续集成与当前阻塞

后续集成：本轮范围内无剩余生产接线。当前技术阻塞：无。`Integrated` 状态仍按 development-standard 第 4 节，由项目负责人审阅本报告并完成跨 Owner 验收后批准；本报告不替代负责人批准。

最终生产 Dart SHA-256：`13b45c053e83a3573db07c2b498cdb0d2eafde387eeaf356c2fc770ac8c3bfcc`。Luna High 已对最终测试与脚本增量再次确认规范 PASS。

原始脱敏日志、设备证据及版本指纹存于 `docs/human/evidence/integration-2026-09-18/`；[证据清单](evidence/integration-2026-09-18/manifest.json)包含最终源码和各 APK 的指纹。
