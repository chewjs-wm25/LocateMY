# Schema Catalog

本文件是 LocateMY 数据对象的可读目录，不替代可执行 schema。Supabase DDL、RLS
和索引以 `supabase/migrations/` 为权威；SQLite 则以实际 migration 源文件为
权威。本目录只登记已实现或已经设计文档明确提出的对象。

## 对象状态

- `proposed`：设计已定义，尚无可执行 migration。
- `implemented`：有对应可执行 migration。
- `deprecated`：不可由新 Feature 使用；说明替代对象与迁移路径。

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
- 可执行 schema / migration：
- 消费 Feature：
- 访问规则：政府镜像写明只读 View/RPC；项目自有表写明 RLS 和账户隔离；SQLite
  写明账户分区、TTL 或队列重试；Storage 写明 bucket、对象路径和策略。

| 字段 | 类型 | 可空 | 默认值 | 语义/约束 | 索引或关系 |
| --- | --- | --- | --- | --- |
| | | | | | |

- 主键：
- 外键：
- RLS / access policy：
- Index：
- 迁移与兼容策略：
