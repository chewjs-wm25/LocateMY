# LocateMY 文档索引

本文档目录以当前代码（2026-09-08）为事实来源。旧的 `view/`、`viewmodel/`、
`model/`、`repository/` 文档保留为早期分层设计稿；其中出现但尚未落地的能力，
统一在 `pages/` 的对应页面中标记为“未完成”，不再把设计目标当作现状。

## 推荐阅读顺序

1. [页面功能状态](./pages/README.md)：逐页查看已完成、部分完成和未完成功能。
2. [架构与模块边界](./architecture/mvvm_structure.md)：查看 feature-first MVVM 目录、职责和依赖规则。
3. [Data Flow](./data-flow/README.md)：追踪数据源、Repository、ViewModel、页面和持久化方向。
4. [数据库真实结构](./real_supabase_tables.md) 与 [RPC 配置](./supabase_rpc_setup.md)。
5. [运行依赖](./requirement.md)。

## 文档目录说明

| 目录/文件 | 定位 | 维护规则 |
| --- | --- | --- |
| `pages/` | 当前页面级功能状态（主文档） | 页面功能变更时同步更新 |
| `data-flow/` | 当前数据流向（主文档） | 数据源、表、RPC、缓存或 Provider 变更时更新 |
| `human/` | 作业回顾与模块说明 | 保留叙述性内容 |
| `view/`、`viewmodel/`、`model/`、`repository/` | 早期设计/分层草案 | 仅作需求来源和历史参考 |
| `old/` | 原始研究与旧设计 | 不代表当前实现 |
| `real_supabase_tables.md` | Supabase 实际表结构 | 后端结构变更时更新 |

## 状态定义

- **已完成**：页面存在可操作 UI，且对应 ViewModel/Repository 数据链路已接通。
- **部分完成**：UI 或内存状态已存在，但持久化、远端写入、细节交互等不完整。
- **未完成**：旧文档描述过，但当前页面代码没有实现，或只有空回调/静态占位数据。
