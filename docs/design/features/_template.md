# <Feature 名称>

> 状态：`Draft`
> Owner：`<项目负责人确认的学生>`
> 系统基线：`<commit 或版本>`
> 依赖波次：`<编号>`
> 最后更新：`YYYY-MM-DD`
> Prototype 视觉参考：`<分支、文件或 N/A>`

设计使用中文，代码标识符保留英文。本文件只写可实现规格，不写完整类、函数体、migration、
测试代码或可直接提交的配置。

## 1. 用户成果与追踪

- 用户成果：
- 包含的 Capability ID：
- 不包含及原因：
- 路由与输入/输出：
- 产品事实源：
- 原型差异：产品事实和已批准设计优先；列出需要修改的原型表现。

每个 Capability 必须能追踪到 owning Feature、Interface、数据对象、验收场景和计划文件/符号。

## 2. 依赖与设计前提

| 依赖 Feature / Module | Interface ID | 所需状态 | 用途 | 已满足 |
| --- | --- | --- | --- | --- |
| | | `Ready for Development` | | |

### 未决项

阻塞项必须在 Ready 前归零。非阻塞假设写明影响范围、验证方式和最迟解决点。

| 项目 | 阻塞性 | 影响范围 | 验证方式 | 最迟解决点 |
| --- | --- | --- | --- | --- |
| | | | | |

## 3. 责任与边界

| 层 | 类型或计划文件 | 职责 | 明确不负责 |
| --- | --- | --- | --- |
| Presentation | | | |
| Application | | | |
| Domain | | | |
| Data | | | |

只创建有真实责任的层。Feature 不读取其他 Feature 的内部 ViewModel、Widget、Adapter、DTO 或
本地存储；跨 Feature 行为只通过已批准的 Interface、类型化路由输入/结果或重新读取持久化数据。

## 4. UI 与状态

逐个列出页面、组件、用户操作、文案、可访问性、初始加载和释放时机。Loading 属于 UI state；
资料未知、明确为零、空结果、失败、无权限和可用离线缓存必须保持不同语义。

| ViewModel / 状态 | 触发条件 | UI 表现 | 可用操作 | 下一状态 |
| --- | --- | --- | --- | --- |
| Initial | | | | |
| Loading | | | | |
| Data | | | | |
| Empty | | | | |
| Failure | | | | |
| Permission denied / Offline cache | `N/A` 或规则 | | | |

## 5. Interfaces

### 对外提供

| ID | 符号名与成员种类 | 调用者 | 输入语义 | 输出及失败语义 | 权限、异步与副作用 |
| --- | --- | --- | --- | --- | --- |
| `<OWNER>-001` | | | | | |

### 消费

| ID | Owner | 使用的成员 | 调用时机 | 成功、空与失败处理 |
| --- | --- | --- | --- | --- |
| | | | | |

为本 Feature 拥有的每个 Interface 写完整契约：参数名、领域类型、约束、返回分支、稳定失败码、
授权、时序、幂等性和全部可观察副作用。使用字段表或成员表，不写可编译声明，不暴露 DTO、
数据库行、无类型 `Map` 或 Storage 路径拼接。

## 6. Data Access Matrix

对象完整定义链接至 [`../data/schema-catalog.md`](../data/schema-catalog.md)；这里只写实际访问。

| 业务目的 | 对象与状态 | 操作 | 字段 | 筛选/排序 | 权限与账户边界 | 缓存、队列或写入影响 |
| --- | --- | --- | --- | --- | --- | --- |
| | | `select/insert/update/delete/RPC/storage` | | | | |

## 7. 业务规则与计算

每条规则列出输入、来源、单位、编号步骤、边界条件和权威产品事实链接。计算还必须说明公式、
归一化、缺失处理、版本和一个可手工验算的例子。必要伪代码必须与具体语言无关且不可直接粘贴。

## 8. 调用流

写操作、跨 Feature 导航或超过两个外部 Interface 的流程使用编号步骤或简短 Mermaid sequence，
逐步标明 payload 语义、成功、空、失败、重试与状态回落。

## 9. File Manifest

| 精确路径 | 动作 | 文件 Owner | 责任与公开 Interface | 访问范围 |
| --- | --- | --- | --- | --- |
| | `create/modify/reuse/prohibited` | | | `allowed/shared/prohibited` |

Manifest 必须覆盖本 Feature 的全部计划文件，且不得有无人负责的责任。

## 10. Symbol Plan

| 文件 | 符号 | 种类/可见性 | 构造输入或字段 | 公开成员及语义 | 责任 |
| --- | --- | --- | --- | --- | --- |
| | | | | | |

列出类、公开构造函数、公开方法、重要状态字段和已批准 Interface。私有 helper 通常只描述责任；
只有需要固定纯算法边界时才指定其名称和输入输出。

## 11. 验收、测试与追踪

| Capability | Interface / 数据对象 | 场景 | 前置条件 | 学生操作 | 预期结果 | 计划测试层级 |
| --- | --- | --- | --- | --- | --- | --- |
| | | | | | | `unit/ViewModel/contract/integration/manual` |

至少覆盖成功、空、可重试失败、不可重试失败，以及适用的无权限、账户切换和离线缓存。记录仓库
已经存在的执行命令；尚不存在的测试由学生按场景亲自建立，不在设计中生成测试代码。

## 12. 审查与 Ready Gate

- [ ] 每个 Capability 的追踪链完整。
- [ ] 所有上游 Interface 已 Ready，消费语义与 owning document 一致。
- [ ] 每个数据对象已登记或明确标记 `proposed`。
- [ ] 规则和公式可复现，非正常 UI 状态已覆盖。
- [ ] File Manifest 与 Symbol Plan 无无人负责项或越界修改。
- [ ] 阻塞问题为零，非阻塞假设有关闭条件。
- [ ] 独立审查的问题已关闭或由项目负责人明确接受。
- [ ] 文档不含可提交代码。
- [ ] 项目负责人已批准 `Ready for Development`。

## 13. Change Log

| 日期 | 状态 | 变更原因 | 影响的 Capability / Interface / 数据对象 / Feature / 工作包 | 批准者 |
| --- | --- | --- | --- | --- |
| | | | | |
