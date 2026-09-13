# 系统基线独立审查

> 审查日期：2026-09-13
> 审查对象：`a9bd539` 后的 Issue #5 基线候选
> 结论：`Ready for owner approval`；设计 AI 不批准 `Baselined`

本文件只保存审查维度、发现、影响、处置和开放项。系统规格仍由各 owning document 持有。

## 审查结果

| 维度 | 证据范围 | 结果 |
| --- | --- | --- |
| 范围 | Capability Catalog 与 45 行[追踪表](capability-traceability.md) | 45 项 `required` 各出现一次；7 项 `excluded` 未混入交付范围 |
| 领域语义 | `CONTEXT.md`、产品知识库、两份 Accepted ADR、Feature map | 地点/行政区/警区、设施/交通覆盖、预案/偏好/ICI 权重、风险快照语义一致 |
| 架构 | [architecture.md](architecture.md) | app/core/features、MVVM、composition root、依赖方向及八类 NFR 均有可验证证据要求 |
| 契约 | [interfaces.md](interfaces.md)、[feature-map.md](feature-map.md) | 19 个内部 Interface 与 4 个外部 seam；`D01`–`D46` 每边恰有一个 owning Interface 覆盖 |
| 数据 | [data-ownership.md](data-ownership.md)、[Schema Catalog](../data/schema-catalog.md) | 状态、远端对象、缓存、队列、文件各有唯一 Owner；现有/目标状态没有混写为实现事实 |
| 追踪 | [capability-traceability.md](capability-traceability.md)、[flows.md](flows.md) | 每项 required Capability 均连接 Owner、Interface、数据/状态、验收场景、波次和产品事实 |
| 可实施性 | Interface owning-design Gate、下方迁移计划 | 下游可补精确成员、Adapter 和 migration，不需重新决定系统 Owner、依赖或可观察行为 |
| 人工编码边界 | 全部 `docs/design/` 当前产物 | 未发现完整类、可编译函数体、SQL migration、测试代码或可直接提交实现 |
| 文档结构 | `docs/design/system/README.md` 及专题指针 | 入口只维护流程、状态与指针；契约、对象、流程和审查各有单一权威位置 |

## 发现与处置

| ID | 严重度 | 受影响追踪项 | 发现 | 处置 | 状态 |
| --- | --- | --- | --- | --- | --- |
| `BR-01` | Blocking | 全部 45 项 | 追踪表只有 Issue #2 的 8 行，37 项缺完整链 | 以同一列结构补齐 45 行并加入波次；逐 ID 核对目录、Interface、对象与 AT 定义 | Closed |
| `BR-02` | Blocking | `ACCOUNT-07`、所有私有 Capability | privacy barrier 是否覆盖全部私有 Owner 尚未完成 Gate 审计 | 对照 Feature map、远端私有对象、本机表、文件和内存状态；8 个参与者覆盖全部私有持有者，无通用 payload Owner | Closed |
| `BR-03` | Blocking | `FAC-01`、全部公共分析 | 公共缓存可能混入账户资料 | Schema Catalog 的 4 个具名公共缓存逐项限制为公共输入/结果/版本/日期/完整性；可选缓存继承同一约束，用户命名与账户 ID 只存在私有对象 | Closed |
| `BR-04` | Blocking | Home、Crime、Socio、Infrastructure、Transit | canonical 镜像和读取对象尚有 `proposed` 项，缺 Baseline 所需迁移计划 | 采用下方按 Owner 分组的 add–migrate–remove 计划；实现仍由相应 Feature Ready Gate 和学生 migration 完成 | Closed for Baseline；Feature Ready open |
| `BR-05` | Major | `ACCOUNT-09` | 领域对象同时写“当前选择只在内存”和“账户保存当前预案” | 删除旧原型语义，保留 Supabase 权威、账户唯一 current 的已批准语义 | Closed |
| `BR-06` | Major | `NAV-01`、`ACCOUNT-07` | 协作文档把会话变化发布者写成 Shell，与 `AUTH-001` Owner 冲突 | 明确 Authentication 发布会话事实，Shell 只协调门控/清理流程 | Closed |

没有接受未分配 Owner 或没有最迟解决点的非阻塞假设。仍开放的实现风险继续以
[风险登记](risks-and-decisions.md#风险与关闭条件)为唯一清单；它们均有影响、验证方式、Owner 和最迟关闭点，
且不授权下游改变系统决定。

## Schema 迁移计划

计划只规定责任、顺序和完成证据，不包含 migration 实现。

| Owner / 波次 | add | migrate / validate | remove 条件 | 最迟完成 |
| --- | --- | --- | --- | --- |
| Authentication / 1 | 保留 `profiles`，加固与 Auth identity 的一致性约束 | 两账户 CRUD 与真实邮箱/确认状态不复制验证 | 无替代消费者后移除任何旧认证资料副本 | Authentication Ready |
| Geographic Context / 1 | `administrative_district_boundaries`；补 `police_districts_boundary.source version` | 边界点、离岛、重叠、零匹配、多版本样本 | `match_police_district` 无消费者后移除 | Geographic Context Ready |
| Home / 4 | 四个缺失 canonical 镜像与 `read_home_metrics` | 官方 schema、键、行数、最大日期、完整/部分/空导入 | 稳定读取切换后移除不适配 Home 旧对象 | Home Ready |
| Map / 4 | 本机收藏缓存/创建队列 | 双设备、幂等 create、在线删除传播、换号清理 | 有可证明坐标才迁移 `user_saved_regions`，否则 deny 后移除 | Map Ready |
| Cost / 5 | `cpi_state_inflation` 与 `read_cost_inputs` | 官方键、覆盖率、日期和同口径 A/B | 稳定读取切换后移除旧 RPC | Cost Ready |
| Crime / 5 | canonical `crime_district`、`read_safety_inputs` | 官方 schema/键、最新完整年度、五年趋势、警区绑定 | 消费者切换后移除/改名旧 `crime_stats` | Crime Ready |
| Transit / 5 | feed snapshots、标准化 stops/routes/services、reference grid 与读取对象 | feed 解析、有效服务日、缺 feed、失败/过期、唯一站点/路线 | 切换后移除不带 feed identity 的 `transit_stops`/旧 RPC | Transit Ready |
| Hazard / 5 | 安全聚合 `hazard_vote_counts` seam | 两账户读同一计数且不能枚举他人票；匿名拒绝 | 新聚合通过后移除不安全 View | Hazard Ready |
| Socio / 6 | 州收入/基尼/百分位与 `read_socio_inputs` | 层级、年份、P1/P100 边界和 A/B 可比性 | 切换后移除全国/错误粒度替代物与旧 RPC | Socio Ready |
| Infrastructure / 6 | population/schools、读取对象及三项 `1–10` ICI 权重 | 官方维度/键、缺失重归一化、两账户默认/迁移样本 | 切换后移除旧五项 `0–1` 权重和错误粒度对象 | Infrastructure Ready |
| Property / 6 | 实勘、照片、Storage policy 的目标约束 | 必需地点、父实勘 owner、20 张、风险快照原子字段组、部分失败清空 | 显式数据审计与消费者切换后移除旧 JSON 对象 | Property Ready |

每组依 [Schema Catalog 通用规则](../data/schema-catalog.md#通用访问与迁移规则)执行：先添加并验证，
再迁移/切换消费者，最后由项目负责人批准移除。任何数据无法证明时保留 unavailable，不制造 fixture 值。

## Baseline Gate disposition

- [x] 所有 Capability 已分类，required 无遗漏。
- [x] Feature/shared module、状态和数据均有唯一 Owner。
- [x] Interface、关键流程与直接阻塞边完整且 DAG 无循环。
- [x] 技术架构与 NFR 足以约束 owning design。
- [x] 45 条 required 追踪链无断点。
- [x] Baseline 阻塞发现为零；后续风险均有 Owner、验证和最迟关闭点。
- [x] 独立审查发现已关闭；无待负责人接受的偏差。
- [ ] 项目负责人记录基线版本并明确批准 `Baselined`。

候选版本在负责人批准时记录为批准 commit SHA；批准前系统状态保持 `Under Review`。
