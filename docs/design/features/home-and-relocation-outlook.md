# Home & Relocation Outlook

> 状态：`Ready for Development`
> Owner：`A`
> 系统基线：`5d11769`
> 依赖波次：`4`
> 最后更新：`2026-09-14`
> Prototype 视觉参考：`origin/Prototype`（首页布局意图；固定示例数值和无效刷新入口不继承）

本文件固定首页与 Application Shell 间的可观察协调契约。Home 拥有全国宏观资料的读取、指数结果、公共缓存和刷新状态；指数公式、数据字段及存储结构仍分别由产品知识库和 Schema Catalog 唯一规定。

## 1. 用户成果与范围

- 用户成果：在已打开的主应用首页看到全国 `0–100` 搬家时机、状态、最多三条原因和各自数据日期；看到成本压力、就业稳定度、经济动能及家庭收入中位数卡，并能一致地通过按钮或下拉刷新，或进入地图探索。
- 包含的 Capability ID：`HOME-01`、`HOME-02`、`HOME-03`。
- 不包含及原因：不选择或分析具体地点、不计算个人化地点适配度、不拥有地图 Tab 或语言偏好；这些分别属于 Map / Location、Personalized Location Suitability 与 Application Shell。Home 也不自动同步政府数据：本项目只读取 Flutter 开发前一次性手动导入的资料。
- 产品事实源：[首页](../../knowledge_base/locatemy_product/features/home.md)、[首页宏观指数](../../knowledge_base/locatemy_product/home_index_scoring.md)、[Capability Catalog](../../knowledge_base/locatemy_product/capability_catalog.md)。
- 原型差异：保留宏观卡、趋势/建议呈现和地图入口；移除将固定样例当实时统计的含义，补上真实数据日期、可用性、按钮及下拉刷新和相同的冷却反馈。

## 2. 依赖、责任与文件边界

| 模块 / 文件边界 | Owner | 负责 | 不负责 | 与其他模块的沟通 |
| --- | --- | --- | --- | --- |
| `lib/features/home_relocation_outlook/` | Home & Relocation Outlook | 全国宏观读取、`HOME-001` 结果、指数/原因、公共缓存、`STATE-HOME-REFRESH` 与首页可用性呈现 | 导航执行、语言偏好、账户资料、地图地点与政府资料写入 | 向 Shell 提供 `HOME-001`；以 `SHELL-001` 提交探索地图意图 |
| `lib/app/` | Application Shell | opened 范围门控、首页 Tab/本地化、探索地图导航及 Home 结果呈现槽位 | Home 资料解释、公式、缓存和刷新冷却 | 提供 `SHELL-001`；只呈现 Home 给出的日期、单位、来源、可用性与原因 |
| `read_home_metrics`、`home_public_cache` | Home & Relocation Outlook | 只读全国资料入口与无账户公共缓存 | 字段/RLS/migration 定义，或账户私有内容 | 对象定义以 [Schema Catalog](../data/schema-catalog.md#稳定公共读取对象) 为准 |

只以上述 Feature 目录作为 Home 的实现边界；其内部文件、类型、请求调度、缓存 TTL、取消、重试、去重与测试组织由实现 Owner 决定，前提是不改变本设计的可观察结果。

### 依赖与未决项

| 依赖或问题 | 影响 | 验证方式 / 最迟解决点 |
| --- | --- | --- |
| `SHELL-001` 已冻结的首页槽位、打开范围和地图 Tab 意图 | 未认证或 scope 未 opened 时不能读取或呈现 Home；探索地图只能切换 Tab | 以 `FLOW-01`、`FLOW-08` 和 `AT-HOME-03` 集成验收；Home Ready 前已可消费，无阻塞 |
| `read_home_metrics` 的五个资料集与 `home_public_cache` 仍为 `proposed` | 没有已验证的完整资料时只能给出分类 unavailable，不能制作样例替代 | 依 [Baseline Review](../system/baseline-review.md#schema-迁移计划) 的 Home add–migrate–validate 证据：官方 schema/键/行数、最大日期及完整/部分/空导入；Home 实现前关闭 |
| `RISK-NFR-01` 的运行时依赖、离线和可访问性证据 | 设计已冻结可观察语义，尚无运行时证明 | 实现/集成验收运行两种语言、刷新/缓存/无网络及辅助功能流程；不授权改动已批准契约 |

## 3. 对外协调契约

### 提供：`HOME-001` 全国搬家时机与宏观首页

| 消费者 | 动作与可观察事实 | 输入、结果与失败语义 | 权限与副作用边界 |
| --- | --- | --- | --- |
| Application Shell | 读取全国搬家时机、三项主要分项、家庭收入中位数和刷新状态；每项保留单位、观测日期、来源数据集及可用性，允许分项渐进完成。 | 输入为 `cache-allowed` 或用户 `refresh`。结果是 fresh、cached 或 stale 的完整/partial 首页结果，或分类 unavailable；缺失、字段变化、历史样本不足、无法验证或无缓存网络失败均带原因。`refresh` 成功后在进程内建立 60 秒冷却；冷却期间返回剩余秒数而非再强刷。 | 仅 opened 主应用流程消费。Home 读写自身无账户公共缓存与内存冷却，不读取/写入账户资料、地点、语言或 Shell 导航状态；退出保留公共缓存，重启不恢复冷却倒计时。 |

`HOME-001` 的完整指数语义只在[首页宏观指数](../../knowledge_base/locatemy_product/home_index_scoring.md)定义：三项主分项任一不可用时，搬家时机综合分不可用；家庭收入中位数只是全国背景资料，绝不参与综合分。Home 不以零填补未知，不强迫月度、季度和年度资料成为同一日期，也不将缓存/一次性导入资料描述为官方实时统计。

### 消费

| ID | Owner | 使用目的 | 调用方依赖的结果与失败语义 |
| --- | --- | --- | --- |
| `SHELL-001` | Application Shell | 在 opened 主应用首页呈现 `HOME-001` 结果；响应“探索地图”意图 | Home 仅提交类型化探索地图意图。Shell 接受时切换地图 Tab且不生成默认地点；门控、语境过期或输入不合格时返回可理解的拒绝/认证结果，Home 保持当前页。 |

## 4. 用户可观察行为与跨模块流程

| 入口或用户动作 | 成功结果 | 空、不可用或失败结果 | 必须保持的可访问性 / 安全语义 |
| --- | --- | --- | --- |
| 打开已认证且 scope opened 的首页 | 以 `cache-allowed` 请求，先显示可得分项；完整资料生成搬家时机、状态、最多三条原因和各卡日期 | 单一数据集失败只使相应卡 unavailable；三主分项任一不可用时综合分 unavailable，其余卡仍保留；无缓存且读取失败显示分类原因和重试入口 | 未认证或关闭 scope 不读取/呈现 Home；指数、趋势、状态和可用性有文字，不能只用颜色 |
| 使用顶部按钮或下拉刷新 | 两入口调用同一 `refresh` 语义；成功更新可用资料、重算结果并开始 60 秒冷却 | 刷新中不可重复触发；冷却期显示剩余秒数；失败保留已有结果并标明 cached/stale 或 unavailable，不报告刷新成功 | 按钮加载、禁用、冷却与下拉状态均有文字/可访问名称；不把过期缓存伪装为 fresh |
| 查看各卡及趋势/建议 | 每张卡显示其单位、数据日期和必要方向/背景说明；建议原因按模型定义的影响排序 | 字段、历史或资料不足时明确“暂不可用”及原因；收入资料缺失不阻断三项主分项 | 成本压力的方向说明明确“分数越高表示相对压力越低”；百分比带单位，日期按 Shell 当前语言本地化 |
| 选择“探索地图” | `SHELL-001` 接受意图，切换至地图 Tab并保留首页同进程状态 | Shell 拒绝或要求认证时停留首页并显示其原因 | 不选定默认城市、坐标或分析目标；地图入口是唯一高强调操作，且有可访问名称 |

跨 Owner 的 `FLOW-08` 完成条件如下：Shell 已确认 opened scope 后，Home 独立取得并标注各资料；Shell 可渐进呈现这些贡献。用户通过任一刷新入口时，Home 处理同一刷新/冷却规则。地图探索只由 Shell 执行 Tab 切换，Home 不转移地点或领域资料。范围关闭期间的结果不得进入已关闭或后续账户的私有呈现。

## 5. 数据与确定性业务规则

| 目的 | 权威对象或事实源 | 访问 / 应用边界 | 必须保持的语义 |
| --- | --- | --- | --- |
| 全国宏观读取 | [`read_home_metrics`](../data/schema-catalog.md#稳定公共读取对象) | Flutter 只经该只读对象读取五个 Home 数据集；不直接读政府镜像，且不写入或自动同步 | 结果标明实际使用的官方数据集（`cpi_headline_inflation`、`lfs_month_sa`、`economic_indicators`、`gdp_qtr_real_sa`、`hh_income`）；使用实际最大 `date` 作为各数据集最新观测日期，不以 Supabase 刷新时间或目录年份代替 |
| 搬家时机及三项主分项 | [首页宏观指数](../../knowledge_base/locatemy_product/home_index_scoring.md) | 只对实际可用全国 `NATIONAL` 资料应用该模型；公式正文不复制到本设计 | 严格应用模型的五年/最小历史、百分位、重归一化、分项 60% 可用权重门槛、取整、趋势和综合分条件；结果为全国近期相对读数，不是政府评级、地点判断或保证 |
| 家庭收入中位数 | [首页宏观指数](../../knowledge_base/locatemy_product/home_index_scoring.md#家庭收入中位数) | 读取全国年度调查值并作为背景卡呈现 | 显示调查年份及“按当年价格，未按通胀调整”；可用时的变化也标注年份，不参与综合分 |
| 缓存与刷新 | [`home_public_cache`](../data/schema-catalog.md#稳定公共读取对象)、[首页刷新事实](../../knowledge_base/locatemy_product/features/home.md#数据边界) | 缓存仅含公共结果、版本、各项来源日期、取得时间、过期/完整性；在线只以资料日期更近的结果替换 | 缓存可显示但必须标识 cached/stale 与资料日期/上次成功时间；冷却仅 `STATE-HOME-REFRESH` 进程内状态，成功强刷后 60 秒，退出保留缓存 |

## 6. 验收与 Ready Gate

| Capability | 验收情景 | 用户操作 | 可观察结果 |
| --- | --- | --- | --- |
| `HOME-01` | 全部三项主分项和收入资料可用；月度、季度、年度日期不同 | 打开首页 | 显示全国 `0–100` 搬家时机、状态、最多三条原因和每项真实数据日期；三项主分项及收入卡带单位/方向说明；不将异频日期或一次性导入写成实时统计 |
| `HOME-01`、`HOME-02` | 任一主分项、收入资料、字段或历史样本缺失 | 打开或刷新首页 | 失败项显示带原因的 unavailable；任一主分项不可用则综合分不可用，其他有效卡保留；收入缺失不阻断主分项；未知不显示为零 |
| `HOME-01`、`HOME-02` | 网络失败时有有效缓存、过期缓存或无缓存 | 打开或刷新首页 | 缓存结果分别标为 cached/stale 并显示观测日期/上次成功时间；无缓存显示可重试 unavailable；不得伪造 fresh 或样例值 |
| `HOME-03` | 按钮与下拉的成功刷新、进行中重复触发、60 秒冷却与刷新失败 | 依次用两种入口刷新 | 两入口产生同一刷新结果；成功后显示剩余冷却秒数并拒绝重复强刷；失败不重置为成功且保留既有可用结果 |
| `HOME-01`–`HOME-03` / Application Shell | opened、未认证、scope 关闭和探索地图 | 进入首页、关闭账户范围或选择探索地图 | 仅 opened 主应用读取/呈现 Home；关闭后旧结果不进入后续账户；探索地图只切换地图 Tab、不制造默认地点，Shell 拒绝时仍留在首页 |

- [x] `HOME-01`–`HOME-03` 均可追踪至 `HOME-001`、唯一事实源、数据对象及上述验收情景。
- [x] Home、Application Shell 和 Schema Catalog 的责任、文件边界、公共缓存副作用与 `D04` 没有重叠或冲突。
- [x] 公式、输入口径、单位、日期和缺失语义只链接至产品知识库；对象字段、RLS 和迁移只链接至 Schema Catalog。
- [x] 覆盖 partial、缓存/过期/无缓存、刷新冷却、账户范围关闭、地图导航和可访问性语义。
- [x] 独立规格/边界审查已核对 `FM-HOME`、D04、`HOME-001`、`FLOW-08`、`STATE-HOME-REFRESH`、数据对象、产品事实与验收链；未发现未归属契约、事实源冲突或可提交实现内容。
- [x] 设计 AI 依 ADR 0013 批准 `Ready for Development`。`read_home_metrics` / `home_public_cache` 的资料导入与 `RISK-NFR-01` 运行时证据仍明确留在实现/集成验收，不阻塞本设计的协调契约。

## 7. Change Log

| 日期 | 状态 | 变更原因 | 受影响的 Capability / Interface / 数据对象 / Feature | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Draft` | Issue #10 建立 Wave 4 Home owning design，冻结首页宏观结果、刷新、公共缓存和探索地图的跨 Owner 可观察契约 | `HOME-01`–`HOME-03`、`HOME-001`、`SHELL-001`、`STATE-HOME-REFRESH`、`read_home_metrics`、`home_public_cache`、D04 | 待独立审查与设计 AI 依 ADR 0013 批准 |
| 2026-09-14 | `Ready for Development` | 独立规格/边界审查确认范围、Interface、资料日期/可用性、刷新、Shell 边界、追踪与验收链完整 | `HOME-01`–`HOME-03`、`HOME-001`、`SHELL-001`、`FLOW-08`、`STATE-HOME-REFRESH`、`read_home_metrics`、`home_public_cache`、D04 | 设计 AI（项目负责人依 ADR 0013 授权） |
