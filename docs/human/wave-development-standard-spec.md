# 各 Wave 开发规范规格

讨论结论：项目负责人于 2026-09-16 确认 Q1–Q8。执行规则以 [统一开发规范](../design/development-standard.md)为准；本文是讨论结论的规格交付，供 Issue 发布和实施验收使用。

## Problem Statement

AI 检查一个 Feature 时，经常将尚未接入其他 Feature 判为开发未完成。各 Wave 无法一次准备所有 Feature，当前模块实现责任与未来联合验收混在一起，导致完成边界不断扩大。现有流程虽有 Implemented 与 Integrated，却缺少逐项可检查的门槛。

## Solution

所有 Wave 采用既定分层和依赖方向，在开发前分配契约验收场景，以真实实现和证据判定模块 Implemented，按指定 Wave 完成接线与联合验收。AI 分别报告模块实现、本期集成、后续集成和当前阻塞。

## User Stories

1. As an 实现者, I want a 统一架构规范, so that 每个 Wave 的模块遵循相同依赖方向。
2. As an 实现者, I want a 明确的层职责, so that UI、用例、领域和外部 SDK 能分别维护。
3. As an shared module 实现者, I want a 按需保留层的规则, so that 无页面模块能避免空的 Presentation 层。
4. As an 模块 Owner, I want a 内部文件组织自由, so that 完成验收依据行为和边界。
5. As an 消费者 Owner, I want a 唯一公开 Interface, so that 我可以独立开发且不依赖提供方内部实现。
6. As an 消费者 Owner, I want a 测试 fake, so that 提供方尚未完成时也能验证消费行为。
7. As an 提供方 Owner, I want a 真实 Adapter 验证门槛, so that fake 通过不会掩盖真实生产能力缺失。
8. As an 实现者, I want a 真实开发环境验证要求, so that 关键外部调用及权限有实际证据。
9. As an 实现者, I want a 环境阻塞的准确状态, so that 实现已写完与验收完成可以区分。
10. As an 实现者, I want a 安全的独立运行入口, so that 未实现页面不会妨碍本模块运行验证。
11. As an 项目负责人, I want a 当前依赖和未来槽位的区分, so that 占位不会替代当期应接入的真实能力。
12. As an 模块 Owner, I want a 开发前验收分配, so that 当前开发范围可以稳定审查。
13. As an 模块 Owner, I want a 联合场景中的本模块子项, so that 后续集成不会推迟本模块已有责任。
14. As an 联合验收负责人, I want a 每项场景的 Owner 和最迟 Wave, so that 集成事项有明确期限。
15. As an 审查 AI, I want a 每项验收的证据要求和状态, so that 我可以给出可复核结论。
16. As an 实现者, I want a 本模块 Implemented 门槛, so that 未来消费者尚未接入时仍能结束当前开发。
17. As an 项目负责人, I want a Wave 完成门槛, so that 本期到期的真实联合验收不会遗留。
18. As an 项目负责人, I want a 保留 Integrated 批准权, so that 最终跨 Owner 集成仍由我验收。
19. As an 审查 AI, I want a 四项固定完成报告, so that 实现状态与集成状态始终分别呈现。
20. As an 实现者, I want a 关联条款的阻塞报告, so that 我知道当前缺口和解除条件。
21. As an 模块 Owner, I want a 范围变更规则, so that 新产品要求经过确认后才加入验收。
22. As an 测试维护者, I want a 使用最高现有公开 seam 的测试策略, so that 测试验证外部行为且避免逐层重复。
23. As an 项目负责人, I want a 已有契约采用新规范的入口, so that 设计 Ready 与实现完成可以明确区分。

## Implementation Decisions

- 沿用技术架构的 MVVM、Application use case、Domain/Application seam、Data Adapter 和 composition root。以 Authentication 为参考，统一职责和方向，内部拆分按需。
- 统一规范作为完成判定的唯一规则源；项目指令、设计入口和 Feature/shared-module 模板通过指针触发读取。
- 开发前为每项契约场景分配本模块、联合或两者验证，记录依赖用途、证据要求、负责 Owner、最迟 Wave，以及两类证据的独立状态。
- 真实外部调用、当前适用权限、适用设备证据及现有质量检查属于本模块 Implemented 门槛；未来消费者未接入作为未到期后续集成记录。
- 本期应接入的真实依赖完成接入，测试使用 fake，未来槽位可明确占位；所有运行入口保持适用安全条件。
- Wave 完成要求本 Wave 所有模块 Implemented，且截至该 Wave 到期的接线和联合验收通过，包括过去 Wave 延至本 Wave 的事项。
- Implemented 与集成状态分开记录，Integrated 仍由项目负责人批准。
- 现有 Ready contract 在首次按规范开发前补齐验收分配；本次不凭讨论直接改变其实现或集成状态，也不擅自指定所有既有联合场景期限。
- 公开 Interface、数据模型、产品语义沿用现有权威来源与变更协议。

## Testing Decisions

- 好测试验证公开可观察行为、结果、失败恢复和副作用，不依赖内部类名或文件数量。
- 采用用户在 Q2 确认的现有最高公开 Interface seam；AuthenticationSession 是参考。优先复用现有 seam，按实际外部边界保留必要 Adapter 验证，不强制逐层增加测试缝。
- Authentication 的 ViewModel/use case fake 测试、真实 SDK 配合 mock HTTP 的 Adapter 测试、Widget 交互测试是独立验证先例；mock HTTP 不构成在线 Supabase 联调证据。
- 外部 Adapter 使用确定性测试覆盖错误、边界和恢复；开发环境使用真实调用验证关键成功路径与适用权限。
- 联合验收接入相关真实模块，验证真实协作的顺序、生命周期、副作用、权限和失败恢复。
- 文档检查覆盖相对链接、模板指针和 Git diff。用边界案例核对规则：未来消费者缺失不阻塞模块；真实环境证据缺失阻塞 Implemented；过期联合项阻塞 Wave；无页面模块按公开入口验收；到期联合通过不自动批准 Integrated。
- 本次只修改文档，运行文档检查；实际模块按实施范围执行现有格式、分析、测试、APK 和设备要求。

## Out of Scope

实现全部后续 Feature；宣告 Authentication 或任意现有模块已 Implemented/Integrated；本次批量修改所有 owning contract 的验收分配；改变 DAG、产品语义、公开 Interface 或数据库；引入新架构框架；强制每层建立测试或固定内部文件数量。

## Further Notes

Q1–Q8 已获项目负责人确认。统一规则、读取入口和模板指针已经在当前工作区写入。发布的规格用于跟踪规范采用与后续模块开发验收，不代表任何既有模块已补齐证据。既有场景的具体分配应在对应模块开发前按其契约和 DAG 完成。
