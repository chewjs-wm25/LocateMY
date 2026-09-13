# 系统设计规范

本入口规定第一阶段如何把产品事实变成可供滚动 Feature 设计消费的系统基线。系统设计状态为
`Draft → Under Review → Baselined`；只有项目负责人可以设为 `Baselined`。

## 当前进度

| 步骤 | 状态 | 依据 |
| --- | --- | --- |
| 1. 关闭产品边界 | `Completed` — 2026-09-13 | [产品范围基线](../../knowledge_base/locatemy_product/capability_catalog.md#产品范围基线2026-09-13)：52 项已知 Capability 均已分类；45 项 `required` 均有权威事实源和可观测成果；项目负责人已在 Issue #1 确认。 |
| 2. 建立 Capability 追踪 | `In Progress` — 2026-09-13 | [Issue #2 tracer 追踪](capability-traceability.md)：8 项 required Capability 已形成完整链；其余 37 项待处理。 |
| 3. 划分 Feature 与 shared module | `In Progress` — 2026-09-13 | [Tracer Feature map](feature-map.md)：经过的 3 个 Feature、2 个 shared module 已唯一归属。 |
| 4. 确定状态与数据所有权 | `In Progress` — 2026-09-13 | [Tracer 数据所有权](data-ownership.md)：经过的状态、公共缓存及退出清理责任已关闭。 |
| 5. 登记系统 Interface | `In Progress` — 2026-09-13 | [Tracer Interface](interfaces.md)：5 个跨 Feature Interface 和 1 个外部来源 seam 已登记；其余 seam 待处理。 |
| 6. 确定技术架构 | `Not Started` | Issue #2 只记录 tracer 直接暴露的外部来源和存储边界。 |
| 7. 描述关键流程 | `In Progress` — 2026-09-13 | [TRACER-01](flows.md#tracer-01启动登录选址查看周边设施并退出) 已覆盖；其余规定流程待处理。 |
| 8. 建立依赖 DAG 与波次 | `Not Started` | 等完整 Feature/shared module 边界。 |
| 9. 审计追踪与风险 | `In Progress` — 2026-09-13 | [Tracer 风险](risks-and-decisions.md)已有关闭条件；全量审计待处理。 |
| 10. 批准基线 | `Not Started` | 系统整体仍为 `Draft`。 |

## 固定步骤与完成条件

1. **关闭产品边界**：读取 Capability Catalog、提交承诺、已知缺口和相关 Feature 事实源；每项
   已知 Capability 归为 `required`、`excluded`、`deferred` 或 `superseded`。大学承诺全部为
   `required`，无未分类项时完成。
2. **建立 Capability 追踪**：为每个 Capability 指定 owning Feature、验收成果和适用产品事实源；
   每项都有唯一 Owner 时完成。
3. **划分 Feature 与 shared module**：Feature 按可独立验证的用户能力纵切；shared module 只在
   跨 Feature 且拥有状态、规则、数据访问或公开契约时建立。所有责任唯一归属时完成。
4. **确定状态与数据所有权**：区分瞬时 UI state、可变地点上下文、账户私有资料、公共资料、
   离线队列和权威远端记录；每项状态和数据只有一个 Owner 时完成。
5. **登记系统 Interface**：记录 ID、Owner、消费者、用途、领域输入输出、结果语义、权限、
   副作用和状态，不写精确语言声明。所有跨 Feature 边界均有已登记契约时完成。
6. **确定技术架构**：记录外部系统、`app/core/features` 责任、MVVM 依赖方向、composition root、
   Supabase/SQLite/Storage 边界，以及安全、离线、国际化和可观测性约束；每项约束可被后续
   Feature 设计引用时完成。
7. **描述关键流程**：至少覆盖启动与会话、选址与分析、A/B 比较、账户切换、离线创建与同步、
   以及大学承诺中的跨 Feature 流程；每个流程明确成功、失败和降级时完成。
8. **建立依赖 DAG 与波次**：每个 Feature 标出直接阻塞边，循环依赖已消除，所有节点都有设计
   波次时完成。
9. **审计追踪与风险**：每个 required Capability 均可追踪到 Feature、Interface、数据对象、
   验收场景和计划设计波次；所有阻塞缺口归零时完成。
10. **批准基线**：独立审查已完成，项目负责人解决或明确接受全部发现，并记录基线版本后设为
    `Baselined`。

前置步骤没有满足完成条件时，不开始依赖它的步骤。

## 系统设计产物

实际设计时按需要建立下列专题文件；`README.md` 只维护状态、基线版本、步骤进度和链接，不复制
专题正文。

| 建议文件 | 唯一责任 |
| --- | --- |
| `capability-traceability.md` | Capability 分类、Owner、验收成果与完整追踪链 |
| `feature-map.md` | Feature/shared module 边界、责任、非责任、依赖 DAG 与波次 |
| `architecture.md` | 外部系统、运行时边界、分层、依赖方向和非功能约束 |
| `interfaces.md` | 系统 Interface 注册表和 owning document 链接 |
| `data-ownership.md` | 状态、Supabase、SQLite、Storage、缓存和离线队列所有权 |
| `flows.md` | 关键跨 Feature 端到端流程及失败/降级语义 |
| `risks-and-decisions.md` | 阻塞缺口、非阻塞假设、风险、验证方式和 ADR 链接 |

## 当前 Draft 入口

- [Capability 追踪](capability-traceability.md)
- [Feature 与 shared module 边界](feature-map.md)
- [系统 Interface 注册表](interfaces.md)
- [状态与数据所有权](data-ownership.md)
- [关键流程](flows.md)
- [风险与待决项](risks-and-decisions.md)

上述文件当前只完成 Issue #2 的关键旅程 tracer，不代表系统 Baseline Gate 已通过。

使用短文、表格和小型 Mermaid 图表达重要关系；不制作不驱动决策或验收的图。产品事实留在知识
库，难以逆转且存在真实取舍的决定写入 ADR，系统文件只引用它们。

## 系统 Interface 注册规则

Interface ID 使用全局可搜索的 `<OWNER>-<NNN>`。系统注册表只保存摘要；精确成员、领域类型、
失败码、幂等性和副作用在第二阶段的 owning Feature/shared module 中补全。消费者只有在所需
上游精确契约进入 `Ready for Development` 后，才能开始自己的详细设计。

Capability ID 沿用产品知识库现有编号。两种 ID 不互换：Capability 表示用户能力，Interface
表示实现边界。

## 多模型设计与上下文包

强模型负责系统基线、上下文包、综合与冲突消解。经济模型只设计分配的 Feature，不改变系统
边界或上游契约。每个 Feature 上下文包只包含：

- 对应 Capability 与产品事实指针；
- 相关系统基线章节；
- 已冻结的上游 Interface 与数据所有权；
- Feature 模板和 Ready Gate；
- Prototype 视觉引用；
- 禁止进入的范围；
- 指定输出位置与允许修改的设计文件。

不把完整仓库资料无差别复制进上下文包；通过明确触发条件链接分支资料。

## 审查记录

独立审查至少覆盖范围、领域语义、架构、契约、数据、追踪、可实施性和“无可提交代码”边界。
只保存结构化结果：审查维度、问题与严重度、受影响追踪项、处理决定和未关闭项。模型对话和
推理不作为事实源。

## Baseline Gate

- [ ] 所有已知 Capability 已分类，required 项无遗漏。
- [ ] Feature/shared module、状态和数据均有唯一 Owner。
- [ ] 跨 Feature Interface、关键流程和直接阻塞边完整且无循环依赖。
- [ ] 技术架构及非功能约束足以约束第二阶段设计。
- [ ] required Capability 的追踪链无断点。
- [ ] 阻塞问题为零；非阻塞假设有影响范围、验证方式和最迟解决点。
- [ ] 独立审查发现已关闭或由项目负责人明确接受。
- [ ] 项目负责人记录基线版本并批准 `Baselined`。

## 基线变更

变更提案必须记录原因、受影响的 Capability、Feature、Interface、数据对象和工作包。项目负责人
批准后才修改；相关 Ready 设计退回 `Draft`，工作包标记 `Invalidated`。重新完成受影响审查后
才能恢复状态。Interface 演进优先 add–migrate–remove。
