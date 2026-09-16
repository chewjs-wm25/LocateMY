# LocateMY 设计与开发入口

本目录是 LocateMY 中文设计的唯一权威。产品范围、领域语义、公式和数据边界仍以
[`CONTEXT.md`](../../CONTEXT.md) 与
[`docs/knowledge_base/locatemy_product/`](../knowledge_base/locatemy_product/) 为准；本目录把这些事实转成可由两名 Owner 独立实现并集成的 Development Contract。

开始前先读 [ADR 0011](../adr/0011-human-coded-ai-designed-delivery-process.md)、
[ADR 0015](../adr/0015-contract-first-two-person-development-handoff.md) 与
[ADR 0016](../adr/0016-ai-managed-supabase-development-environment.md)，再按任务读取：

- 系统边界、依赖波次或基线变更：[`system/README.md`](system/README.md)
- Feature Development Contract：[`features/_template.md`](features/_template.md)
- shared-module Development Contract：[`modules/_template.md`](modules/_template.md)
- 数据对象、RLS 与 migration：[`data/schema-catalog.md`](data/schema-catalog.md)
- 给人阅读的 HTML 导出：[`handoff/README.md`](handoff/README.md)

## 权威产物与代码边界

每个 owning Feature/shared module 的 Markdown 是唯一 Development Contract；`docs/human/` 中同 basename HTML 只是语义等价的阅读导出。Git 与 PR 保存历史，不建立 PDF、Manifest、checksum 或独立发布生命周期。

AI 可以固定跨 Owner 所必需的精确 `import`、公开 Dart declaration、调用方可见类型、结果、失败、生命周期、权限、副作用和联合情景，也可以编写、修改和测试 Flutter 函数体、Widget、私有 helper、SDK 映射及应用测试实现。

AI 可以建立和保护 Supabase 开发环境，包括 CLI/config、migration、RLS、导入支持及环境验证；其边界见 ADR 0016。Flutter 中的 Supabase client 装配可由 AI 或 Owner 编写，并须使用运行时注入的项目 URL 与 publishable key，不能提交 service-role key 或继续依赖硬编码 legacy anon key。

公式正文只在产品知识库维护；字段、RLS 和 migration 只在 Schema Catalog 维护。Development Contract 引用它们并固定调用方必须遵守的口径。

## 角色与协作

- **项目负责人 / Owner A**：产品与架构决策、shared file、composition root、migration 顺序和最终整合。
- **Owner B**：实现分配给 B 的契约；与 A 共同确认所消费的公开 Interface 变更。
- **AI**：可维护设计和 HTML、执行审查、编写及测试全部项目代码，并依 ADR 0013 批准 owning contract 的 `Ready for Development`。

提供方先合并一个模块唯一的公开入口和契约 declarations，再实现真实 Adapter；消费方只依赖该入口并用 fake 开发。公开 Interface 变更由提供方说明原因和受影响消费者，全部消费者确认，并在同一 PR 更新 declarations、owning contract、同名 HTML 与受影响测试。

## Ready for Development

一份 owning contract 只有同时满足以下四项才可进入开发：

1. **成果可观察**：范围、成功、空、失败、离线/权限及恢复结果明确。
2. **边界可编译**：唯一公开入口、完整 declarations、结果/失败/lifecycle/权限和依赖均无猜测。
3. **资料可复现**：数据对象、公式 ID、单位、边界和来源指向唯一事实源。
4. **协作可验收**：Owner、fake/Adapter 分工、联合场景、变更协议和阻塞项明确。

正文 Ready Gate 必须自证这四项；Issue 评论和 Change Log 只保留历史，不能替代正文。

## 开发节奏

1. 系统基线和全部 owning contract 已就绪；按依赖 DAG 从 Wave 1 开始。
2. 每个 provider 先交付公开 seam 与 fake 所需 declaration，再并行开发 provider/consumer。
3. Owner 或 AI 可在分支中实现 Flutter 代码和测试；共享接线由 A 整合。
4. 每个 PR 运行格式检查、静态分析、测试和 debug APK 构建；仓库已有 [Flutter CI](../../.github/workflows/flutter.yml)。
5. 实现者可声明 `Implemented`；项目负责人完成跨 Owner 验收后批准 `Integrated`。

设备策略不构成开发阻塞：Owner B 使用 Android Studio 自带虚拟设备；Owner A 使用真实 Android 设备进行无线调试。两人均需在自己的目标设备保留首屏、失败分支和返回/重启流程证据。

## 单一真相与变更规则

- Capability 产品含义只在产品知识库定义。
- 系统 Interface 注册表只列 ID、Owner、消费者、用途、状态及 owning contract 链接。
- 完整 Interface declarations 和协调语义只在 owning contract 定义。
- 数据对象完整定义只在 Schema Catalog；Feature 只写访问方式和业务口径。
- 模型对话与推理不入库；只保留决定、影响、验证证据和未关闭项。

基线后变更必须记录原因及受影响的 Capability、Feature、Interface、数据对象和测试。发生公开 Interface 或数据模型变化时，受影响 contract 退回 `Draft`，完成影响审查和同 PR 同步后才能恢复。

## 设计索引

系统设计为 `Baselined`（`5d11769`）。以下全部 owning contract 已达到 `Ready for Development`；波次表示依赖顺序，不表示人员工期。

| 类型 | 名称 | Owner | 波次 | Development Contract |
| --- | --- | --- | --- | --- |
| Feature | Authentication & Session | A | 1 | [Markdown](features/authentication-and-session.md) · [HTML](../human/authentication-and-session.html) |
| Module | Geographic Context | B | 1 | [Markdown](modules/geographic-context.md) · [HTML](../human/geographic-context.html) |
| Module | Account Privacy | A | 2 | [Markdown](modules/account-privacy.md) · [HTML](../human/account-privacy.html) |
| Module | Application Shell | A | 3 | [Markdown](modules/application-shell.md) · [HTML](../human/application-shell.html) |
| Feature | Home & Relocation Outlook | A | 4 | [Markdown](features/home-and-relocation-outlook.md) · [HTML](../human/home-and-relocation-outlook.html) |
| Feature | Map / Location | A | 4 | [Markdown](features/map-and-location.md) · [HTML](../human/map-and-location.html) |
| Feature | Cost of Living & Budget | B | 5 | [Markdown](features/cost-of-living-and-budget.md) · [HTML](../human/cost-of-living-and-budget.html) |
| Feature | Crime & Security | B | 5 | [Markdown](features/crime-and-security.md) · [HTML](../human/crime-and-security.html) |
| Feature | Nearby Facilities | A | 5 | [Markdown](features/nearby-facilities.md) · [HTML](../human/nearby-facilities.html) |
| Feature | Public Transportation | A | 5 | [Markdown](features/public-transportation.md) · [HTML](../human/public-transportation.html) |
| Feature | Hazard Reporting | A | 5 | [Markdown](features/hazard-reporting.md) · [HTML](../human/hazard-reporting.html) |
| Feature | Socio-economic | B | 6 | [Markdown](features/socio-economic.md) · [HTML](../human/socio-economic.html) |
| Feature | Infrastructure Coverage | B | 6 | [Markdown](features/infrastructure-coverage.md) · [HTML](../human/infrastructure-coverage.html) |
| Feature | Property Inspection | B | 6 | [Markdown](features/property-inspection.md) · [HTML](../human/property-inspection.html) |
| Feature | Account Center | A | 6 | [Markdown](features/account-center.md) · [HTML](../human/account-center.html) |
| Feature | Personalized Location Suitability | B | 7 | [Markdown](features/personalized-location-suitability.md) · [HTML](../human/personalized-location-suitability.html) |
