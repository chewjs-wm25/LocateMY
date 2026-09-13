# LocateMY 实施设计索引

本目录是 LocateMY 中文实施设计的唯一权威。每个可独立交付的 Feature 在
`features/` 有一份完整纵切面设计；只有跨 Feature 且拥有状态、规则、数据访问
或公开契约的能力才在 `modules/` 有文档。数据对象的完整定义在
`data/schema-catalog.md`。

开始或修改实现设计前，先读 [ADR 0010](../adr/0010-feature-first-implementation-design-standard.md)。
产品范围、领域语义、数据边界和公式事实仍以 `CONTEXT.md` 与
`docs/knowledge_base/locatemy_product/` 为准。

## 文档状态

`Draft` 表示规格仍有未决实现事实；`Ready for Development` 表示可以无猜测地
开始实现；`Implemented` 表示代码已完成；`Integrated` 表示验收、接口引用和
File Manifest 已同步。

| Feature | 状态 | 文档 | 公开 Interface | 数据对象 |
| --- | --- | --- | --- | --- |
| 尚未迁移 | N/A | 现有页面设计仅作迁移输入 | N/A | N/A |

## 模板与单一真相

- 新 Feature 从 [Feature 模板](features/_template.md) 开始。
- 新共享模块从 [共享模块模板](modules/_template.md) 开始。
- 每个数据对象先登记到 [Schema Catalog](data/schema-catalog.md)，再被 Feature
  的 Data Access Matrix 引用。
- Interface 的完整契约只写在其 owning Feature 或 shared module；索引表只列 ID
  和链接。
