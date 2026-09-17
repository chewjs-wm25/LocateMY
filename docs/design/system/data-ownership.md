# 数据与状态归属（Issue #31）

| 内容 | Owner／位置 | 保留／失败边界 |
| --- | --- | --- |
| 认证身份 | SDK；Auth 消费当前用户 | 默认保持登录，退出当前设备 |
| 页面栈、选点／A/B、未提交输入 | owning 页面内存 | 地图返回保留表单；退出／dispose 结束，无重启草稿 |
| 收藏 | Map／Supabase | online-only，owner RLS，无本机缓存／同步 |
| 预算／current | Cost／Supabase | online-only，至少字段缺失与零区分；Account／Socio 仅读服务 |
| 隐患／本人票 | Hazard／Supabase | 公开报告 authenticated 可读，作者状态／删除，本人唯一票 |
| 房产／风险／回收站 | Property／Supabase | 新增／坐标变化风险，失败仍可保存；退出不删 |
| 照片 | Property／Storage 与元数据 | 在线操作，部分失败真实反馈，软删保留，确认永久清空业务删除 |
| 三项 ICI 权重 | Infrastructure／Supabase | 默认 5，单点可调，摘要／A/B 中性 |
| 公共分析缓存 | owning 分析／SQLite | 退出保留，日期／来源／旧缓存可见 |
| 语言与简单设置 | app／KV | 退出、重启保留 |
| 预算 JSON | Cost／应用文件目录 | 导出副本，退出、重启保留，读取不写回云端 |

字段／RLS／migration 唯一见 [Schema Catalog](../data/schema-catalog.md)。
五项评估偏好停用；历史 migration 不删。私有队列／照片待传／草稿／清理屏障不再有 owner 或消费者。
