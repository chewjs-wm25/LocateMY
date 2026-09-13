# Schema Catalog

本文件是 LocateMY 设计中的数据对象目录，不替代学生编写的可执行 schema。Supabase DDL、RLS
和索引最终以 `supabase/migrations/` 为权威；SQLite 以实际 migration 源文件为权威。AI 只定义
对象契约和迁移目标，不生成 migration 或其他可提交代码。

系统设计先确定数据所有权和边界；Feature 设计只有在对象已登记或明确标记 `proposed` 后才能
进入 `Ready for Development`。

## 对象状态

- `proposed`：已批准设计，尚无学生编写的可执行实现。
- `implemented`：存在对应的可执行 migration 或本地 schema 实现。
- `deprecated`：新 Feature 不再使用，并记录替代对象和迁移方向。

## 对象目录

| 对象 | 类型 | 状态 | Owner | 权威来源 | 迁移/实现 | 消费 Feature |
| --- | --- | --- | --- | --- | --- | --- |
| 尚未登记 | N/A | N/A | N/A | N/A | N/A | N/A |

## 对象模板

### `<physical_name>`

- 类型：`Supabase table/view/RPC` / `SQLite table` / `Storage bucket`
- 状态：`proposed`
- Owner：
- 权威性与数据来源：
- 可执行 schema / migration：`尚未由学生建立` 或实际路径
- 消费 Feature：
- 访问规则：政府镜像写只读 View/RPC；项目自有表写 RLS 和账户隔离；SQLite 写账户分区、
  TTL 或队列重试；Storage 写 bucket、对象路径语义和策略。

| 字段 | 类型 | 可空 | 默认值 | 语义/约束 | 索引或关系 |
| --- | --- | --- | --- | --- | --- |
| | | | | | |

- 主键：
- 外键：
- RLS / access policy：
- Index：
- 迁移与兼容方向：描述目标、前置检查和回滚语义，不写 SQL。
- 数据安全：只使用清洗示例；不记录凭据、service-role key、真实用户数据或可识别测试资料。
