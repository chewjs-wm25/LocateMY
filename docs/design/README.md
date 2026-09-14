# LocateMY 设计工作入口

本目录是 LocateMY 中文设计的唯一权威。产品范围、领域语义、公式和数据边界仍以
[`CONTEXT.md`](../../CONTEXT.md) 与
[`docs/knowledge_base/locatemy_product/`](../knowledge_base/locatemy_product/) 为准；本目录规定
如何把这些事实变成系统基线、Feature 实施设计和人类开发工作包。

开始设计或审查前先读 [ADR 0011](../adr/0011-human-coded-ai-designed-delivery-process.md) 与
[ADR 0013](../adr/0013-autonomous-design-ai-ready-approval.md)。按任务
继续读取：

- 系统设计、Capability 追踪、依赖波次或基线变更：[`system/README.md`](system/README.md)
- Feature 设计：[`features/_template.md`](features/_template.md)
- shared module 设计：[`modules/_template.md`](modules/_template.md)
- 数据对象设计：[`data/schema-catalog.md`](data/schema-catalog.md)
- 人类工作包生成或失效：[`handoff/README.md`](handoff/README.md)

## 代码边界

AI 产出**高层协调设计，不产出可提交代码**。Feature/shared module 设计规定用户可观察成果、
模块职责、跨 Owner 契约、受控文件边界、验收情景及不可自由发挥的业务规则。它不预先规定
内部文件拆分、符号、状态机、SDK 映射、运行时策略或测试组织；这些由代码 Owner 在不改变
可观察契约的前提下决定。

公式、输入口径、单位、边界和结果语义仍须固定，但公式正文只在产品知识库维护；数据字段、
RLS 和迁移只在 Schema Catalog 维护。设计不得包含完整类、可编译函数体、SQL migration、
测试代码或带程序逻辑的配置。两名学生亲自编写和修改所有可提交代码与测试。

AI 可以只读检查代码、运行测试、比较设计与实现并报告缺陷。报告描述问题、预期行为和
验证方式，不提供可直接粘贴的修复实现。

## 权威与角色

- **项目负责人**：唯一产品与架构决策人；批准 `Baselined` 和 `Integrated`；维护 shared file、
  composition root、migration 顺序与最终整合。
- **学生实现者**：只实现已分配的代码和测试；可声明 `Implemented`；发现设计问题时按固定
  格式上报，不自行改变公开契约、数据模型或可观察行为。
- **设计 AI**：提出和编辑设计、生成上下文包与工作包、执行审查，并依 ADR 0013 在独立审查
  完成后批准 remaining owning designs 的 `Ready for Development`。

Owner 字段中的 `A` 代表项目负责人本人，`B` 代表另一名组员；该别名只用于人员归属，正文中的
地点 A/B 仍表示两地比较角色。

实现 Owner 在全部 owning design 完成后由项目负责人统一分配；当前 owning design 已由项目负责人以 A、B 完成分配。Owner 分配不改变已冻结的协调契约；人类工作包仍须按锁定版本生成并经 Development Release 才能派发。

## 交付节奏

1. 一次完成整个系统设计并由项目负责人设为 `Baselined`。
2. 按依赖 DAG 设计基础波次；详细 Feature 设计只领先人类实现一个波次。
3. 每份 Feature 经独立审查、综合修订及设计 AI 依 ADR 0013 批准后进入 `Ready for Development`。
4. 从锁定版本生成工作包；学生在独立短期分支中亲自实现代码和测试。
5. 每波完成功能测试与集成；最终执行系统验收、回归和大学提交检查。

## Pilot 校准

Wave 1 的首份 owning design 必须把每个外部 seam 的可验证运行时风险留作 Ready Gate 阻塞项，
并冻结其跨 Owner 可观察语义与安全不变量。超时、取消/过期响应、去重、补偿和 Adapter 细节
属于 owning module 的内部策略。后续 Feature 只读取所消费上游的 owning design；系统注册表继续
只保留摘要与链接。详见 [ADR 0012](../adr/0012-high-level-design-coordination-boundaries.md)。

## 单一真相

- Capability 的产品含义只在产品知识库定义。
- 系统 Interface 注册表只列 ID、Owner、消费者、用途、状态及 owning document 链接。
- Interface 的完整协调语义只在 owning Feature 或 shared module 中定义。
- 数据对象完整定义只在 Schema Catalog；Feature 只写自身访问方式。
- 人类工作包只摘录当前任务所需内容并链接锁定版本，不产生设计决定。
- 模型对话与推理不入库；只保留审查维度、问题、影响、决定和未关闭项。

## 设计文档一致性规则

- 系统基线中的注册表使用 `Baselined — <version>`；Interface 的设计成熟度仍逐行记录，运行时实现证据不得把已批准的系统契约降回 `Draft`。
- owning Feature 从自身依赖方向描述契约：对应用消费者提供产品 Interface，消费外部来源 seam；外部 Adapter 的内部策略仍归该 owning Feature。
- Feature 验收表保留具体场景，并显式标出 `flows.md` / Capability Traceability 中对应的 canonical `AT-*`，使系统验收与 owning design 可双向追踪。
- `Ready for Development` 文档必须在正文 Ready Gate 中明确确认独立审查、阻塞关闭及批准事实；Issue 评论和 Change Log 只保留历史证据，不能代替正文自证。

## 变更规则

基线后变更必须记录原因以及受影响的 Capability、Feature、Interface、数据对象和工作包，并由
项目负责人批准。相关 `Ready for Development` 文档退回 `Draft`；受影响工作包标记
`Invalidated`。契约变更优先采用 add–migrate–remove，完成重新审查后才能恢复状态。

## 设计索引

系统设计为 `Baselined`（`5d11769`）。Feature/shared module 边界和依赖波次已由项目负责人在 Issue #3
批准；系统 Interface、数据所有权、技术架构与关键流程已在 Issue #4 补齐；Issue #5 已完成全量追踪、
独立审查与 Baseline 阻塞关闭，项目负责人已记录并批准该基线。波次表示详细设计的最早起点，不是两名学生的分工；
各 owning design 仍须独立达到 Ready Gate。

| 类型 | 名称 | 状态 | Owner | 依赖波次 | 文档 |
| --- | --- | --- | --- | --- | --- |
| System | LocateMY | `Baselined` (`5d11769`) | 项目负责人 | N/A | [系统设计入口](system/README.md) |
| Feature | Authentication & Session | `Ready for Development`（2026-09-14） | A | 1 | [实施设计](features/authentication-and-session.md) |
| Module | Geographic Context | `Ready for Development`（2026-09-14） | B | 1 | [实施设计](modules/geographic-context.md) |
| Module | Account Privacy | `Ready for Development`（2026-09-14） | A | 2 | [实施设计](modules/account-privacy.md) |
| Module | Application Shell | `Ready for Development`（2026-09-14） | A | 3 | [实施设计](modules/application-shell.md) |
| Feature | Home & Relocation Outlook | `Ready for Development`（2026-09-14） | A | 4 | [实施设计](features/home-and-relocation-outlook.md) |
| Feature | Map / Location | `Ready for Development`（2026-09-14） | A | 4 | [实施设计](features/map-and-location.md) |
| Feature | Cost of Living & Budget | `Ready for Development`（2026-09-14） | B | 5 | [实施设计](features/cost-of-living-and-budget.md) |
| Feature | Crime & Security | `Ready for Development`（2026-09-14） | B | 5 | [实施设计](features/crime-and-security.md) |
| Feature | Nearby Facilities | `Ready for Development`（2026-09-14） | A | 5 | [实施设计](features/nearby-facilities.md) |
| Feature | Public Transportation | `Ready for Development`（2026-09-14） | A | 5 | [实施设计](features/public-transportation.md) |
| Feature | Hazard Reporting | `Ready for Development`（2026-09-14） | A | 5 | [实施设计](features/hazard-reporting.md) |
| Feature | Socio-economic | `Ready for Development`（2026-09-14） | B | 6 | [实施设计](features/socio-economic.md) |
| Feature | Infrastructure Coverage | `Ready for Development`（2026-09-14） | B | 6 | [实施设计](features/infrastructure-coverage.md) |
| Feature | Property Inspection | `Ready for Development`（2026-09-14） | B | 6 | [实施设计](features/property-inspection.md) |
| Feature | Account Center | `Ready for Development`（2026-09-14） | A | 6 | [实施设计](features/account-center.md) |
| Feature | Personalized Location Suitability | `Ready for Development`（2026-09-14） | B | 7 | [实施设计](features/personalized-location-suitability.md) |
