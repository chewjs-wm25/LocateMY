# <Feature 名称>

> 状态：`Draft`  
> Owner：`<角色或姓名>`  
> 最后更新：`YYYY-MM-DD`  
> 迁移输入：`<历史设计文档或 N/A>`  
> Prototype 视觉参考：`<分支、文件或 N/A>`

## 1. 目标、范围与依赖

- 用户成果：
- 包含：
- 不包含：
- 路由与输入/输出：
- 依赖的 Feature / shared module / 产品事实源：

## 2. MVVM 责任

| 层 | 类型/文件 | 职责 | 不负责 |
| --- | --- | --- | --- |
| Presentation | | | |
| Application | | | |
| Domain | | | |
| Data | | | |

## 3. UI 与状态

说明页面、组件、用户操作、可访问性和文案边界。列出每个 ViewModel 的不可变 UI
state、公开 command、初始加载条件和释放时机。

| 状态 | 触发条件 | UI 表现 | 可用操作 |
| --- | --- | --- | --- |
| Initial | | | |
| Loading | | | |
| Data | | | |
| Empty | | | |
| Failure | | | |
| Permission denied / Offline cache | N/A 或具体规则 | | |

## 4. Interfaces

### 对外提供

| ID | 名称与 Dart 风格签名 | 调用者 | 返回与失败语义 | 权限/副作用 |
| --- | --- | --- | --- |
| `<OWNER>-001` | | | | |

### 消费

| ID | Owner | 名称与调用签名 | 调用时机 | 如何处理 `AsyncResult` |
| --- | --- | --- | --- |
| | | | | |

为本 Feature 拥有的每个 Interface 补充完整契约：参数类型与约束、返回类型、
`Success` / `Empty` / `Failure` 条件、失败码、异步语义、幂等性、授权和所有
可观察副作用。仅使用领域类型、输入对象和值对象；不暴露 DTO 或数据库行。

## 5. Data Access Matrix

完整对象定义链接至 `../data/schema-catalog.md`；此处只写本 Feature 的实际访问。

| 业务目的 | 对象与状态 | 操作 | 字段 | 筛选/排序 | 权限与账户边界 | 缓存、队列或写入影响 |
| --- | --- | --- | --- | --- | --- | --- |
| | | `select/insert/update/delete/RPC/storage` | | | | |

## 6. 业务规则与计算

每条规则都给出输入、来源、单位、处理步骤、边界条件和权威产品事实链接。计算还
必须给出公式或伪代码、归一化、缺失规则、版本和一个可手工验算的例子。

## 7. 调用流

涉及超过两个外部 Interface、写操作或跨 Feature 导航时，使用编号流程或简短
Mermaid sequence，逐步写明 payload、成功、空、失败和重试去向。

## 8. File Manifest

| 路径 | `create/modify/reuse/prohibited` | Owner | 责任/公开 Interface |
| --- | --- | --- | --- |
| | | | |

## 9. 验收与测试

- Interface 契约矩阵：成功、空、可重试失败、不可重试失败；适用时加入无权限、离线缓存。
- ViewModel 状态测试：
- 跨 Feature 验收流（前置条件 → 操作 → 预期结果）：
- 可执行命令：仅在仓库已有时记录；否则写 `尚未建立`。

## 10. Change Log

| 日期 | 状态 | 变更 | 影响的 Interface / 数据对象 / Feature |
| --- | --- | --- | --- |
| | | | |
