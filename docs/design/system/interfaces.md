# 系统 Interface 注册表

> 状态：`Draft — Issue #2 tracer scope`
> 最后更新：2026-09-13

本注册表是系统 Interface 摘要的唯一真相。当前条目只覆盖
[TRACER-01](flows.md#tracer-01启动登录选址查看周边设施并退出)；精确成员、领域类型、稳定失败码、
幂等性和 Adapter 规格由第二阶段 owning Feature/shared module 文档定义。表内语义是系统契约，
不是语言声明。

## Tracer Interfaces

| ID | Owner | 消费者 | 用途 | 领域输入 | 领域输出与结果语义 | 权限 | 副作用 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `AUTH-001` | Authentication & Session | Application Shell；Authentication 登录/退出表现层 | 恢复当前设备会话、邮箱密码登录、结束当前设备会话 | 启动恢复无业务输入；登录为规范化邮箱与仅限本次提交的密码值；退出为当前会话引用和 `current-device` 范围 | 恢复：`authenticated`、`unauthenticated`、`retryable failure`、`non-retryable failure`；登录：已认证会话或分类失败；退出：本机会话已结束或分类失败。远端拒绝/失效会话按 `unauthenticated`，不是空数据 | 恢复无需已登录；登录仅匿名入口；退出须匹配当前会话。凭据不得越过此 Interface | 登录/恢复可更新 SDK 本机会话；退出只结束当前设备会话，不影响其他设备，也不删除业务数据 |
| `SHELL-001` | Application Shell | Map / Location；其他产生业务导航意图的 Feature | 在认证门控内处理类型化业务导航意图并保持返回上下文 | 目的地种类、不可变领域输入、发起上下文；本 tracer 为 `nearby facilities` 与合法单点引用 | `accepted` 带已建立路由、`rejected` 带缺失/非法输入原因、`authentication required`。无合法地点不是成功，也不使用默认地点 | 仅已打开账户范围可进入主应用目的地 | 更新导航栈；退出/切换账户时丢弃私有导航栈和待处理意图，不改变 Feature 业务数据 |
| `LOCATION-001` | Map / Location | Application Shell；地点分析 Feature | 提供与可变地点上下文隔离的单点分析目标 | 地点角色 `single`；用户点选时包含候选名称和坐标 | `valid location reference` 或 `absent` / `outside Malaysia` / `invalid coordinate`；成功引用固定名称、坐标、角色与产生时间，供一次分析使用 | 主应用认证门控内可用；不申请 GPS 权限 | 合法点选替换单点状态并刷新 Marker/摘要；查询分析目标本身无副作用，不改变 A/B 状态 |
| `FACILITY-001` | Nearby Facilities | Application Shell；Map / Location 地点摘要 | 取得一个合法地点的 2 公里周边设施结果 | 不可变地点引用；读取策略 `cache-allowed` 或用户刷新 `refresh` | `available fresh`、`available cached`、`complete empty`、`retryable unavailable`、`non-retryable unavailable`。结果保留地点、2,000 米范围、五类数量/最近三项、查询或缓存时间、OSM 来源、完整性与原因；未知不等于零 | 仅认证门控内的用户流程可调用；OSM 资料不是账户私有资料 | 可读写 Nearby Facilities 自有公共缓存；不写账户资料、不改变全局选点 |
| `PRIVACY-001` | Account Privacy | Application Shell（触发者）；Map / Location、Cost of Living、Account、Infrastructure、Hazard Reporting、Property Inspection（关闭参与者） | 为已认证身份打开隔离账户范围；在退出或账户切换时关闭旧范围，并证明本机私有状态已全部处理 | 打开为已认证账户引用与原因 `startup` / `sign-in`；关闭为旧账户不可逆引用、原因 `sign-out` / `account-switch`、已登记 Owner 集合 | 打开：`opened`、`identity mismatch`、分类失败；关闭：`closed` 仅在旧账户内存、SQLite 队列/私有缓存和待传文件均清除后返回，分类失败必须列出未完成 Owner，且旧范围保持不可访问。重复打开/关闭同一范围保持幂等结果语义 | 仅 Application Shell 可发起；只有 `AUTH-001` 已认证的同一账户可打开；参与者只能清除输入账户所属分区 | 打开使匹配分区可读；关闭清除旧账户本机私有状态和未同步队列/文件；不删除 Supabase 权威业务记录，不清除公共分析缓存或设备语言偏好 |
| `FACILITY-002` | Nearby Facilities | Nearby Facilities Application/Domain；Overpass Adapter 满足此 Interface | 隔离真实 OSM 查询与确定性测试 Adapter，使圆形完整性判断留在 owning Feature | 地点坐标、矩形预筛范围、所需 OSM 标签集合、超时/查询策略 | 完整原始元素集，或限流/超时/网络/响应无效等来源失败；部分或无法证明完整的响应不可作为空结果 | 无 LocateMY 账户权限；遵守 OSM/Overpass 使用与归因要求 | 生产 Adapter 发出网络读取，测试 Adapter 无外部副作用；成功结果只有经 Feature 归类、去重和圆形过滤后才可缓存 |

## 使用约束

- `AUTH-001` 的 `authenticated` 只能由 Authentication & Session 产生；页面跳转不是会话证据。
- `SHELL-001` 只接受 `LOCATION-001` 的成功快照作为本 tracer 的分析输入。Nearby Facilities 不回读
  当前全局选点，因此离开地图后的地点变化不改写正在展示的结果。
- `FACILITY-001` 将“完整查询且计数为零”与“查询失败或完整性未知”分开；消费者保留该分支，
  不压缩成可空列表。
- `PRIVACY-001` 是账户隔离和退出完成的 privacy barrier。Application Shell 只有在 `AUTH-001`
  的账户引用与 `opened` 范围相同后才开放主应用；退出时可以先隐藏私有内容，但只有本地会话结束
  且返回 `closed` 后才显示普通登录入口。
- Interface 的提供方验证结果语义；Application Shell 验证跨 Interface 的顺序、门控和账户切换。
- `PRIVACY-001` 表内 Feature 当前只登记为退出清理参与者；除 Map / Location 外，它们的完整
  Capability 边界和其他 Interface 仍待后续系统设计，不由本条目推断。

## 后续 owning document

| Interface | 计划 owning document | 进入 `Ready for Development` 前必须补全 |
| --- | --- | --- |
| `AUTH-001` | Authentication & Session Feature design | 成员、会话有效性规则、Supabase Auth Adapter、稳定失败码、当前设备退出验收 |
| `SHELL-001` | Application Shell module design | 导航意图种类、路由输入生命周期、重入/返回规则、认证门控测试 |
| `LOCATION-001` | Map / Location Feature design | Location Reference 字段约束、马来西亚范围验证来源、精度与等价规则 |
| `FACILITY-001`、`FACILITY-002` | Nearby Facilities Feature design | 查询/刷新时序、分类映射版本、缓存键、失败码、OSM Adapter 契约 |
| `PRIVACY-001` | Account Privacy module design | Owner 登记清单、身份匹配、开启/清理次序、失败恢复、幂等性和全部账户切换测试 |
