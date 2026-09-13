# 状态与数据所有权

> 状态：`Draft — Issue #2 tracer scope`
> 最后更新：2026-09-13

本文件确定 tracer 涉及状态和数据的唯一语义 Owner；物理对象与字段在
[`../data/schema-catalog.md`](../data/schema-catalog.md) 和后续 Feature 设计登记。拥有清理协议不等于
拥有业务数据：Account Privacy 证明清理完成，各 Feature 仍独占其状态、缓存和队列语义。

## Tracer 状态与数据

| ID | 类别 | 内容与权威来源 | 唯一 Owner | 保存位置/寿命 | 退出或账户切换 |
| --- | --- | --- | --- | --- | --- |
| `STATE-SESSION` | 账户私有会话 | 当前设备认证会话；Supabase Auth 为权威 | Authentication & Session | 认证 SDK 本机存储；可跨重启 | 当前设备会话必须结束；其他设备会话不受影响 |
| `STATE-ACCOUNT-SCOPE` | 可变运行时状态 | 当前允许访问的账户范围与 privacy barrier 状态 | Account Privacy | 内存；只为匹配的已认证会话打开，随会话关闭 | 先阻断旧范围读取，再清理并关闭；失败时保持不可访问 |
| `STATE-NAVIGATION` | 瞬时 UI state | 认证门控、首页/地图 Tab、导航栈、待处理意图 | Application Shell | 内存；应用进程寿命 | 重置为登录门控；不得继承旧账户私有路由或地图 Tab |
| `STATE-AUTH-FORM` | 瞬时 UI state | 邮箱、本次输入的密码、提交/错误状态 | Authentication & Session | 页面内存；页面寿命 | 清空；密码从不进入持久化、日志或其他 Interface |
| `STATE-LOCATION` | 可变地点上下文 | 当前单点、地点 A/B 与 Marker/摘要状态 | Map / Location | 内存；进程寿命 | 全部清空。地点虽不是账户业务记录，本旅程把其视为会话上下文，避免下个账户看到旧任务 |
| `DATA-FACILITY-RESULT` | 公共数据派生结果 | OSM 元素经五类归类、去重、2,000 米圆形过滤后的分析结果 | Nearby Facilities | 当前分析页内存；页面寿命 | 页面与私有导航一起释放；可从公共缓存重新生成 |
| `CACHE-FACILITY` | 公共数据缓存 | 地点、半径、分类版本、结果完整性、OSM 查询/缓存时间与归因；OSM 为来源 | Nearby Facilities | SQLite；成功查询后最多 24 小时可用 | 保留；不得含账户 ID、收藏名称、用户标签或导航历史 |
| `PREF-LANGUAGE` | 设备共享偏好 | 中文/English 选择 | Application Shell | 键值存储；跨重启 | 保留；它不绑定账户 |

## 账户私有数据与队列清理清单

本 tracer 不创建以下记录，但 `ACCOUNT-07` 的验收必须证明旧账户留下的任何已存在项均被清除。
远端 Supabase 记录继续作为权威来源；清理只作用于本机副本和未同步工作。

| 状态/数据族 | 业务 Owner | 本机形态 | 权威远端 | `PRIVACY-001` 完成条件 |
| --- | --- | --- | --- | --- |
| 收藏地点 | Map / Location | 按账户分区的 SQLite 私有缓存 | Supabase `user_saved_locations` 语义记录 | 旧账户缓存已删除 |
| 收藏地点离线创建 | Map / Location | 按账户分区的 SQLite 创建队列 | 排队项尚无远端权威记录 | 旧账户未同步项已删除；不得在新账户范围重放 |
| 预算预案、当前评估预案 | Cost of Living | 内存选择与按账户本机副本（若 owning design 建立） | Supabase 账户记录 | 旧账户内存选择和任何本机私有副本已删除 |
| 评估偏好 | Account | 内存与按账户本机副本（若 owning design 建立） | Supabase 账户记录 | 旧账户值已删除；不得用作新账户默认值 |
| ICI 权重 | Infrastructure | 内存与按账户本机副本（若 owning design 建立） | Supabase 账户记录 | 旧账户值已删除；不得用作新账户默认值 |
| 隐患本人状态和投票待处理状态 | Hazard Reporting | 内存与按账户本机状态（若 owning design 建立） | Supabase 账户关联记录 | 旧账户私有视图状态和未完成本机工作已删除；公共隐患缓存若完全去身份化可保留 |
| 房产实勘、草稿与私有元数据 | Property Inspection | 按账户 SQLite 私有副本/草稿 | Supabase 账户记录 | 旧账户草稿和私有副本已删除 |
| 房产照片待传副本与同步队列 | Property Inspection | 按账户应用数据文件和 SQLite 队列 | 上传成功后由 Supabase Storage/元数据权威 | 旧账户待传文件和队列已删除；不得转交新账户 |

每个离线创建 Feature 独占自己的队列、重试规则和“已排队/已创建”语义。Account Privacy 只按
Owner 清单执行与核实清除，不消费队列 payload，也不把排队项上传或改写为成功。

## 保留与隔离不变量

1. 所有账户私有本机记录和队列都带不可变账户分区；读取必须同时满足当前已打开账户范围。
2. 应用先关闭旧账户读取，再尝试物理清理；物理清理失败时旧内容仍不可展示或同步。
3. 公共缓存不绑定账户，可在退出后保留，但不能混入用户命名、收藏关系或其他可识别资料。
4. Supabase 权威业务记录不会因当前设备退出而删除；换设备重新登录后可按各 Feature 同步规则恢复。
5. 用户编辑/删除是否支持离线由 owning Feature 的产品事实决定；“创建队列”不自动授权离线编辑或删除。
