# 状态与数据所有权

> 状态：`Draft — Issue #4 complete ownership`
> 最后更新：2026-09-13

本文件确定系统状态与数据族的唯一语义 Owner、权威来源、寿命和账户切换行为。物理对象与字段只在
[Schema Catalog](../data/schema-catalog.md)定义。Account Privacy 拥有关闭协议，不拥有参与者的业务数据或队列 payload。

## 运行时状态与派生结果

| ID | 内容 | 唯一 Owner | 保存位置/寿命 | 权威与失效 | 退出/换号 |
| --- | --- | --- | --- | --- | --- |
| `STATE-SESSION` | 当前设备认证会话与真实确认状态 | Authentication & Session | Supabase Auth SDK 本机状态；跨重启 | Supabase Auth 权威；远端拒绝后失效 | 结束当前设备会话；其他设备不受影响 |
| `STATE-AUTH-FORM` | 邮箱、密码、提交与错误 | Authentication & Session | 页面内存 | 仅当前表单；密码不离开 Interface | 清空 |
| `STATE-ACCOUNT-SCOPE` | 当前可访问账户与 privacy barrier | Account Privacy | 内存；账户生命周期 | 仅 `AUTH-001` 同账户可打开 | 先阻断读取，全部参与者完成后关闭 |
| `STATE-NAVIGATION` | 门控、双 Tab、导航栈、待处理意图、组合请求版本 | Application Shell | 内存；进程寿命 | 当前 scope/请求版本决定有效性 | 重置登录门控并丢弃私有路由与晚到响应 |
| `PREF-LANGUAGE` | 中文/English 设备偏好 | Application Shell | 键值存储；跨重启 | 本机最后一次明确选择 | 保留，不绑定账户 |
| `STATE-HOME-REFRESH` | 加载、刷新和 60 秒成功冷却 | Home & Relocation Outlook | 页面/进程内存 | 成功强刷开始冷却；重启不恢复倒计时 | 释放 |
| `STATE-LOCATION` | single、A、B、Marker、摘要与地图 viewport | Map / Location | 内存；进程寿命 | 最近一次合法明确动作；角色相互隔离 | 全部清空，避免泄漏旧任务 |
| `STATE-TRANSIT-SELECTION` | 局部站点高亮 | Public Transportation | 页面内存 | 绑定当前交通结果 | 释放；从不写全局地点 |
| `STATE-COST-TEMP` | 不保存的当前月支出 CPI 换算输入 | Cost of Living & Budget | 页面内存 | 只服务当前换算 | 释放，不进入预案或适配度 |
| `RESULT-*` | Home、Cost、Safety、Facilities、Transit、Socio、Infrastructure、Suitability 当前结果 | 各分析 Feature | 页面/ViewModel 内存 | 必须绑定不可变地点/输入版本、日期、来源、口径和可用性 | 释放；公共缓存可重新生成 |
| `STATE-PROPERTY-COMPARE` | 当前选中的 2–3 份实勘 | Property Inspection | 页面内存 | 只引用当前账户可见记录 | 清空 |

## 远端权威业务数据

| 数据族 | 唯一 Owner | Supabase 权威对象 | 本机副本/队列 | 访问与生命周期 |
| --- | --- | --- | --- | --- |
| 注册资料 | Authentication & Session | `profiles` | 仅页面内存 | owner-only；认证邮箱/确认状态仍来自 Auth，不复制进 profile；Account Center 只经 `AUTH-001` 消费真实认证资料 |
| 收藏地点 | Map / Location | `user_saved_locations` | `saved_location_cache`、`saved_location_create_queue` | owner-only；前台双向同步；删除只在线并向本机传播 |
| 预算预案与当前评估预案 | Cost of Living & Budget | `user_budget_scenarios` | 系统基线不建立本机副本 | owner-only；每账户至多一份 current；后续若需副本须先登记 Schema Catalog |
| 评估偏好 | Account Center | `user_assessment_preferences` | 系统基线不建立本机副本 | owner-only；只有 `configured_at` 非空的完整五项 `1–10` 快照可供 Suitability 使用；未配置的预填 `5` 不作为输入；后续若需副本须先登记 Schema Catalog |
| ICI 权重 | Infrastructure Coverage | `user_ici_preferences` | 系统基线不建立本机副本 | owner-only；医疗/教育/交通，缺省语义为 5；与评估偏好不同 |
| 隐患报告 | Hazard Reporting | `crowdsourced_hazards` | 页面/去身份公共读缓存（若建立） | authenticated 可读；author-only insert/delete 与自身状态更新；发布后内容/位置/上报时间不可变；`pending/resolved`；无审核者例外 |
| 隐患投票 | Hazard Reporting | `crowdsourced_hazard_votes`；计数来自 `hazard_vote_counts` | 当前账户投票页面状态 | 每账户每报告至多一条；本人可改/撤回；客户端不直写计数 |
| 房产实勘与风险快照 | Property Inspection | `property_inspections` | `property_drafts` 与可选私有读缓存 | owner-only；软删除/恢复；风险快照按 Schema Catalog 的原子字段组显式采集且不静默覆盖；仅两项完整风险输入可整体 create/replace |
| 房产草稿照片 | Property Inspection | 无远端权威对象 | `property_draft_photos` 与应用数据目录本机副本 | account/draft 绑定、跨重启可续填；远端 inspection 成功后才转换为正式待传照片，全部转换前保留草稿照片；退出清除 |
| 房产照片元数据 | Property Inspection | `property_inspection_photos` | `property_photo_upload_queue` | owner-only；最多 20 张；封面/说明与 Storage 文件分开；只在已有同账户远端 inspection 后进入待传队列 |
| 房产照片文件 | Property Inspection | `inspection-photos` Storage bucket | 应用数据目录中的草稿/待传副本 | owner-only；上传成功后可删本机副本；清空回收站永久删除 |

## 公共资料、镜像与缓存

| 数据族 | 唯一 Owner | 远端/外部来源 | 本机形态 | 保留与不可用规则 |
| --- | --- | --- | --- | --- |
| 行政区边界 | Geographic Context | 版本化只读边界对象 | 可替换公共缓存 | 版本是结果一部分；零/多匹配不以附近地区替代 |
| 全国宏观资料 | Home & Relocation Outlook | Home 只读 View/RPC | `home_public_cache` | 缓存记录每个数据集最大观测日期；在线只以更近数据替换 |
| 生活成本资料 | Cost of Living & Budget | Cost 只读 View/RPC | `cost_public_cache`，3 天 | 不含账户预案、收藏名称或用户输入 |
| 犯罪资料 | Crime & Security | Crime 只读 View/RPC | `crime_public_cache`，3 天 | 显示官方年份与州级口径；原始警区记录只用于州汇总 |
| 周边设施 | Nearby Facilities | Overpass/OSM | `facility_public_cache`，24 小时 | 只有完整响应可缓存为空；不含账户标识 |
| 交通标准化结果 | Public Transportation | 维护者导入的 GTFS 只读结果 | 可替换公共缓存 | stale 可显示；incomplete/no active routes/no stops 分开 |
| 社会经济资料 | Socio-economic | Socio 只读 View/RPC | 可替换公共缓存（若建立） | 每项保留层级、年份；一项失败不清空其他项 |
| 基础设施资料 | Infrastructure Coverage | Infrastructure 只读 View/RPC + Transit 结果 | 可替换公共缓存（若建立） | 每分项保留日期；缺失不补零 |

所有政府镜像由维护者在 Flutter 开发前一次性导入，镜像表业务列、类型和键跟随官方数据集；Flutter 不直接查询镜像。公开读取对象与本机缓存不包含账户 ID、自由文字或用户命名。

## SQLite、文件与键值存储责任

| 介质 | 允许内容 | 禁止成为 | Owner/清理 |
| --- | --- | --- | --- |
| SQLite 公共分区 | 上表列明的公共分析缓存、资料日期、版本和完整性 | 用户业务记录的权威来源；账户兴趣画像 | 各分析 Feature 独占 namespace/TTL；退出保留 |
| SQLite 私有分区 | 收藏缓存/创建队列、可选预案/偏好副本、房产草稿/草稿照片、照片待传队列 | 跨账户共享缓存；通用队列 Owner | 各业务 Feature 独占 payload；Account Privacy 汇总清理 |
| 应用数据文件目录 | 压缩后的房产草稿照片与待传副本 | 相册原件、永久照片权威、公开文件 | Property Inspection；草稿转换或上传成功后按其生命周期清理，退出所有未同步副本必须清除 |
| 键值存储 | 语言、小型无身份 UI 偏好、公共缓存数据集日期 | token 的自建副本、业务表、队列或自由文字 | Application Shell/相应公共缓存 Owner；语言退出保留 |

首版离线写仅包括收藏地点创建队列、房产草稿照片与房产照片待传。收藏编辑/删除、隐患写、预案/偏好/ICI 权重写、房产记录的远端创建/编辑/删除均需在线；房产草稿及草稿照片可离线保存但不等于远端实勘或照片已发布。

## Privacy barrier 参与者清单

| Owner | 必须清除的旧账户本机内容 | 明确保留 |
| --- | --- | --- |
| Authentication & Session | SDK 当前设备会话由 `AUTH-001` 结束 | 其他设备会话、远端业务记录 |
| Application Shell | 私有导航栈、待处理意图、组合请求与 ViewModel | 语言偏好、无身份 shell 配置 |
| Map / Location | `STATE-LOCATION`、收藏私有缓存与创建队列 | 公共地图/边界缓存 |
| Cost of Living & Budget | 预案内存选择及任何私有副本 | Cost 公共缓存 |
| Infrastructure Coverage | 账户 ICI 权重内存/副本 | 公共分项缓存 |
| Hazard Reporting | 本人/投票私有视图状态与未完成请求 | 完全去身份的公共隐患读缓存 |
| Property Inspection | 草稿、草稿照片、本机副本、比较选择、待传队列与文件 | 无 |
| Account Center | 评估偏好内存/副本、账户页组合状态 | 无 |

每项清理以不可变旧账户 ID 为目标并可重复执行。任何参与者失败时，`STATE-ACCOUNT-SCOPE` 保持关闭，已清理项不恢复，新登录入口保持阻断；用户可重试失败 Owner。Supabase 记录不会因退出而删除。

## 所有权不变量

1. 每项可变状态、远端记录、公共缓存和离线队列只有一个业务 Owner；存储 Adapter 不成为第二 Owner。
2. 所有账户私有本机对象带不可变账户分区，读取还必须满足同账户 `opened` scope。
3. “已排队”“草稿”“已上传元数据”“文件已上传”和“远端记录已创建”是不同状态，界面保留差异。
4. 明确零、完整空结果、未知、权限失败、可重试不可用和不可重试不可用互不替代。
5. 数据字段、键、RLS 和迁移状态只在 Schema Catalog 维护；Feature 文档只链接并说明访问方式。
