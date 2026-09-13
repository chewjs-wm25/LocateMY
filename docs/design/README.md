# LocateMY 设计工作入口

本目录是 LocateMY 中文设计的唯一权威。产品范围、领域语义、公式和数据边界仍以
[`CONTEXT.md`](../../CONTEXT.md) 与
[`docs/knowledge_base/locatemy_product/`](../knowledge_base/locatemy_product/) 为准；本目录规定
如何把这些事实变成系统基线、Feature 实施设计和人类开发工作包。

开始设计或审查前先读 [ADR 0011](../adr/0011-human-coded-ai-designed-delivery-process.md)。按任务
继续读取：

- 系统设计、Capability 追踪、依赖波次或基线变更：[`system/README.md`](system/README.md)
- Feature 设计：[`features/_template.md`](features/_template.md)
- shared module 设计：[`modules/_template.md`](modules/_template.md)
- 数据对象设计：[`data/schema-catalog.md`](data/schema-catalog.md)
- 人类工作包生成或失效：[`handoff/README.md`](handoff/README.md)

## 代码边界

AI 产出**可实现规格，不产出可提交代码**。设计可以规定路径、符号名、参数与返回语义、
状态、公式、流程和测试场景；使用表格、自然语言、数学表达式、状态机和必要的语言无关
伪代码表达。设计不得包含完整类、可编译函数体、SQL migration、测试代码或带程序逻辑的
配置。两名学生亲自编写和修改所有可提交代码与测试。

AI 可以只读检查代码、运行测试、比较设计与实现并报告缺陷。报告描述问题、预期行为和
验证方式，不提供可直接粘贴的修复实现。

## 权威与角色

- **项目负责人**：唯一产品与架构决策人；批准 `Baselined`、`Ready for Development` 和
  `Integrated`；维护 shared file、composition root、migration 顺序与最终整合。
- **学生实现者**：只实现已分配的代码和测试；可声明 `Implemented`；发现设计问题时按固定
  格式上报，不自行改变公开契约、数据模型或可观察行为。
- **设计 AI**：提出和编辑设计、生成上下文包与工作包、执行审查；只有项目负责人批准的
  综合结论进入权威设计。

当前两名学生的具体 Feature 分配等待项目负责人提供分工资料后决定。

## 交付节奏

1. 一次完成整个系统设计并由项目负责人设为 `Baselined`。
2. 按依赖 DAG 设计基础波次；详细 Feature 设计只领先人类实现一个波次。
3. 每份 Feature 经独立审查、综合修订及项目负责人批准后进入 `Ready for Development`。
4. 从锁定版本生成工作包；学生在独立短期分支中亲自实现代码和测试。
5. 每波完成功能测试与集成；最终执行系统验收、回归和大学提交检查。

## 单一真相

- Capability 的产品含义只在产品知识库定义。
- 系统 Interface 注册表只列 ID、Owner、消费者、用途、状态及 owning document 链接。
- Interface 完整契约只在 owning Feature 或 shared module 中定义。
- 数据对象完整定义只在 Schema Catalog；Feature 只写自身访问方式。
- 人类工作包只摘录当前任务所需内容并链接锁定版本，不产生设计决定。
- 模型对话与推理不入库；只保留审查维度、问题、影响、决定和未关闭项。

## 变更规则

基线后变更必须记录原因以及受影响的 Capability、Feature、Interface、数据对象和工作包，并由
项目负责人批准。相关 `Ready for Development` 文档退回 `Draft`；受影响工作包标记
`Invalidated`。契约变更优先采用 add–migrate–remove，完成重新审查后才能恢复状态。

## 设计索引

系统设计尚未建立，状态为 `Draft`。下列 Feature 与 shared module 的责任边界和依赖波次已由
项目负责人在 Issue #3 批准；波次表示详细设计的最早起点，不是两名学生的分工。各 owning design
仍须独立达到 Ready Gate；测试用的认证与异步结果设计已删除，不代表当前设计完成度。

| 类型 | 名称 | 状态 | Owner | 依赖波次 | 文档 |
| --- | --- | --- | --- | --- | --- |
| System | LocateMY | `Draft` | 项目负责人 | N/A | [系统设计入口](system/README.md) |
| Feature | Authentication & Session | `Draft` | 待项目负责人分配 | 1 | [责任卡](system/feature-map.md#fm-auth) |
| Module | Geographic Context | `Draft` | 待项目负责人分配 | 1 | [责任卡](system/feature-map.md#fm-geo) |
| Module | Account Privacy | `Draft` | 待项目负责人分配 | 2 | [责任卡](system/feature-map.md#fm-privacy) |
| Module | Application Shell | `Draft` | 待项目负责人分配 | 3 | [责任卡](system/feature-map.md#fm-shell) |
| Feature | Home & Relocation Outlook | `Draft` | 待项目负责人分配 | 4 | [责任卡](system/feature-map.md#fm-home) |
| Feature | Map / Location | `Draft` | 待项目负责人分配 | 4 | [责任卡](system/feature-map.md#fm-map) |
| Feature | Cost of Living & Budget | `Draft` | 待项目负责人分配 | 5 | [责任卡](system/feature-map.md#fm-cost) |
| Feature | Crime & Security | `Draft` | 待项目负责人分配 | 5 | [责任卡](system/feature-map.md#fm-safety) |
| Feature | Nearby Facilities | `Draft` | 待项目负责人分配 | 5 | [责任卡](system/feature-map.md#fm-facilities) |
| Feature | Public Transportation | `Draft` | 待项目负责人分配 | 5 | [责任卡](system/feature-map.md#fm-transit) |
| Feature | Hazard Reporting | `Draft` | 待项目负责人分配 | 5 | [责任卡](system/feature-map.md#fm-hazard) |
| Feature | Socio-economic | `Draft` | 待项目负责人分配 | 6 | [责任卡](system/feature-map.md#fm-socio) |
| Feature | Infrastructure Coverage | `Draft` | 待项目负责人分配 | 6 | [责任卡](system/feature-map.md#fm-infra) |
| Feature | Property Inspection | `Draft` | 待项目负责人分配 | 6 | [责任卡](system/feature-map.md#fm-property) |
| Feature | Account Center | `Draft` | 待项目负责人分配 | 6 | [责任卡](system/feature-map.md#fm-account) |
| Feature | Personalized Location Suitability | `Draft` | 待项目负责人分配 | 7 | [责任卡](system/feature-map.md#fm-suitability) |
