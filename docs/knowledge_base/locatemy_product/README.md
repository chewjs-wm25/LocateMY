---
kb_id: locatemy-product-index
kind: agent-index
language: zh-CN
canonical: true
---

# LocateMY 产品功能知识库

## 当前项目阶段

LocateMY 当前处于前期研究与 UI 原型阶段。原型用于展示页面结构、功能意图、指数形态和研究口径；正式产品开发、真实数据服务、持久化和生产认证尚未开始。本文档中的“当前功能”应理解为“原型展示内容”，不能据此声称生产功能已经实现。

## 项目交付边界

LocateMY 是一次性的大学项目。交付重点是学生对 Flutter，以及 SQLite、设备本地文件、键值存储和 Supabase 的数据处理能力；不以长期运营、自动化数据同步或额外安全能力为目标。设计应保持技术栈和数据规模最小，仅实现已确认的产品行为与基础账号隔离。

所有可提交的应用、migration、测试和含程序逻辑的配置必须由两名学生亲自编写。AI 只参与系统与 Feature 设计、工作包生成、只读代码审查和测试执行；不能生成或修改可提交代码。

政府数据的一次性导入范围仅限本知识库已列为 LocateMY 功能输入的全部政府开放数据集，不扩展至整个政府开放数据目录。OSM 设施数据不属于政府数据镜像；GTFS 按运营方官方 feed 的既有数据边界处理。任何首次导入失败的数据集在 Flutter 中必须显示“资料暂不可用”，不得以空值或部分数据伪装完整结果。

## Agent 必读

此知识库服务于 LocateMY 重新开发。它将截图中的产品形态与代码验证结果合并，明确区分“真实功能”“部分功能”“界面占位”和“明确排除”。

涉及地图、收藏、隐患、预算或房产实勘的范围、删除、降级或实现取舍时，必须先读[大学提交承诺基线](./submission_commitments.md)。其中列出的能力未经用户明确授权不得移除、降级或用原型替代。

回答或实施前：

1. 先读本页和 [capability_catalog.md](./capability_catalog.md)。
2. 只加载与任务相关的 `features/` 文件。
3. 涉及数据保留、账号隔离或同步时，再读 [persistence_matrix.md](./persistence_matrix.md)。
4. 涉及缺陷修复、重建取舍或范围判断时，再读 [known_gaps.md](./known_gaps.md) 与 [redevelopment_scope.md](./redevelopment_scope.md)。
5. 可见界面不等于生产可用功能；实现架构不属于本知识库。

当前 UI 原型的页面、指数、公式和数据来源完整性矩阵见
[completeness_audit.md](./completeness_audit.md)。该矩阵同时标明已记录项、原型缺口和代码—口径不一致项。

涉及 UI 设计或实现时，再读 [ui_design_spec.md](./ui_design_spec.md)。

涉及实施设计、Feature 边界、MVVM、Interface 或数据访问规格时，产品事实仍以
本知识库为准；实现设计规范见 [docs/design/README.md](../../../design/README.md)。

划分跨 Feature 产品边界或定义组合用例前，读[协作规范](./cross_feature_collaboration.md)。

## 状态词

| 状态 | 含义 | Agent 行为 |
| --- | --- | --- |
| `working` | 当前代码中存在可操作、可见的真实行为 | 可作为当前功能事实 |
| `partial` | 核心行为存在，但有明显限制、临时实现或不一致 | 实施时保留产品意图，并处理已知限制 |
| `prototype` | 仅内存、模拟内容或临时图片等原型实现 | 不可描述为可靠或持久功能 |
| `placeholder` | 截图可见，但无有效回调或仅改变外观 | 不可描述为已实现功能 |
| `excluded` | 未在当前产品中实现，或明确不纳入重开发基线 | 除非用户明确要求，否则不要实现 |

## 产品定位

LocateMY 是面向马来西亚搬迁和居住选址的移动应用。核心是地图选址，以及围绕选中地点提供宏观经济、生活成本、治安、社会经济、基础设施、周边设施和公共交通信息。用户内容包括收藏地点、预算预案、房产实勘和众包隐患。

## 功能文件

| 功能域 | 文档 |
| --- | --- |
| 全局导航与语言 | [features/global_navigation.md](./features/global_navigation.md) |
| 登录与注册 | [features/authentication.md](./features/authentication.md) |
| 首页 | [features/home.md](./features/home.md) |
| 地图、选址与收藏 | [features/map_location.md](./features/map_location.md) |
| 生活成本与预算 | [features/cost_of_living.md](./features/cost_of_living.md) |
| 治安与犯罪 | [features/crime_security.md](./features/crime_security.md) |
| 社会经济 | [features/socio_economic.md](./features/socio_economic.md) |
| 基础设施 | [features/infrastructure.md](./features/infrastructure.md) |
| 周边设施 | [features/nearby_facilities.md](./features/nearby_facilities.md) |
| 公共交通 | [features/transportation.md](./features/transportation.md) |
| 房产实勘 | [features/property_inspection.md](./features/property_inspection.md) |
| 隐患上报 | [features/hazard_reporting.md](./features/hazard_reporting.md) |
| 账户中心 | [features/account.md](./features/account.md) |
| 明确排除功能 | [features/excluded_features.md](./features/excluded_features.md) |

首页宏观指数的公式、数据集 ID、数据边界和缺失规则见 [home_index_scoring.md](./home_index_scoring.md)。

单个地点基础设施 ICI 的公式、数据集 ID、数据边界和缺失规则见 [infrastructure_index_scoring.md](./infrastructure_index_scoring.md)。

单个地点周边设施覆盖的公式、OSM 标签、数据源、缓存和缺失规则见 [nearby_facilities_scoring.md](./nearby_facilities_scoring.md)。

生活成本统一篮子的版本化项目、数量、权重与基准冻结规则见 [cost_basket_v1.md](./cost_basket_v1.md)。

## 横向知识

- [completeness_audit.md](./completeness_audit.md)：当前 UI 原型的页面、读数、公式、数据源与缺口审计矩阵。
- [capability_catalog.md](./capability_catalog.md)：稳定功能 ID、状态、范围分类与权威事实源。
- [domain_objects.md](./domain_objects.md)：业务对象和字段语义。
- [cross_feature_collaboration.md](./cross_feature_collaboration.md)：跨 Feature 的协作边界、契约语义、组合用例和验证责任。
- [persistence_matrix.md](./persistence_matrix.md)：内存、本机、远端与账号隔离边界。
- [known_gaps.md](./known_gaps.md)：无操作控件、数据混用、文案与行为不一致。
- [redevelopment_scope.md](./redevelopment_scope.md)：重开发默认包含、已决定排除与默认排除项。
- [ui_design_spec.md](./ui_design_spec.md)：信息架构、视觉令牌、交互约束、中英文内容与页面决策。
- [submission_commitments.md](./submission_commitments.md)：不可修改大学提交稿的功能承诺、冲突处置与保护规则。
