# Geographic Context

> 状态：`Ready for Development`
> Owner：`B`
> 系统基线：`5d11769`
> 消费 Feature：Cost of Living & Budget；Crime & Security；Socio-economic；Infrastructure Coverage
> 最后更新：2026-09-14

本文件协调行政统计地理语境与其消费者。地点仍由 Map / Location 以不可变合法地点引用提供；本模块只把其中坐标解释为州或行政区，并使结果、资料来源和边界版本可被下游保留和解释。Crime 使用州结果聚合犯罪资料，不解析警区。

## 1. 建立理由、责任与文件边界

- **共享必要性**：四个消费者都需要从同一坐标得到可解释的统计地理语境。删除本模块后，边界版本、零/多匹配和“不得以附近地区替代”的规则会重现于 Cost、Crime、Socio-economic 与 Infrastructure，失去跨页面的一致性和确定性测试的共同 seam。此模块以一个小 Interface 隐藏边界读取、空间匹配与公共缓存的实现复杂度。
- **拥有**：按行政统计口径解析州、行政区；返回每项的 resolved、unresolved 或 ambiguous 结果；随结果保留边界来源与版本；维护生产边界读取和确定性测试所共同使用的外部 seam。
- **不拥有**：马来西亚范围校验、地点搜索或可变选点（Map / Location）；地图图层；犯罪、成本、社会经济或基础设施读数；任何分析 Feature 的资料层级回退；边界资料的导入、迁移实现和下游政府数据查询策略。
- **删除测试**：若删除该 Module，四个消费者须各自处理行政区多边形版本、边界点和重叠、零匹配及其测试资料。复杂性会回到所有调用方，故这是有 Leverage 和 Locality 的 shared module，而非转发层。
- **关联基线**：[FM-GEO](../system/feature-map.md#fm-geo)、`D09`、`D13`、`D23`、`D27`；系统 Interface 注册表中的 `GEO-001` 与 `GEO-002`；[数据所有权](../system/data-ownership.md#公共资料镜像与缓存)和[风险 `RISK-GEO-02`](../system/risks-and-decisions.md#风险与关闭条件)。

| 模块 / 文件边界 | Owner | 负责 | 不负责 | 与消费者的沟通 |
| --- | --- | --- | --- | --- |
| Geographic Context 的公开 Interface（`GEO-001`）及其 Owner 内部实现 | Geographic Context Owner | 统计地理语境结果及版本/来源事实 | 地点生命周期、分析和回退 | 消费者只请求所需口径并消费结果；不得读取边界实现或可变地点状态 |
| 版本化边界读取 seam（`GEO-002`） | Geographic Context Owner | 零/一/多空间匹配和边界资料事实 | 指标资料、范围校验或附近替代 | 只由本 Module 使用；生产与确定性测试 Adapter 满足同一 seam |
| `docs/design/modules/geographic-context.md` | Geographic Context Owner（设计） | 本 Module 的协调契约与 Gate | 系统注册表、Schema Catalog、ADR、迁移和 composition root | 共享文件改动由项目负责人整合 |

实现者可在该 Module 的私有范围内选择文件、语言符号、缓存、空间库、Adapter、时序和测试组织；跨 Owner 可见的 Interface 仅为本文件所列语义。

## 2. 消费者、依赖与协调契约

| 消费 Feature | 使用目的 | 依赖的 Interface / 事实源 | 所需结果与安全边界 |
| --- | --- | --- | --- |
| Cost of Living & Budget | 将地点置于 PriceCatcher 与行政区收入语境 | `GEO-001`；[生活成本事实源](../../knowledge_base/locatemy_product/features/cost_of_living.md) | 行政区与州及边界版本，或明确未解析/歧义；不由 Geo 以州或附近行政区伪造行政区 |
| Crime & Security | 取得州级犯罪统计所用统计州 | `GEO-001`；[治安事实源](../../knowledge_base/locatemy_product/features/crime_security.md) | 州与版本，或明确未解析/歧义；Crime 按其事实源聚合原始警区记录，不请求或推测警区 |
| Socio-economic | 取得行政区读数和已定义的州级回退所需语境 | `GEO-001`；[社会经济事实源](../../knowledge_base/locatemy_product/features/socio_economic.md) | 每个已解析层级及其版本；是否采用州级回退仍由 Socio-economic 的事实源决定 |
| Infrastructure Coverage | 查询四项行政区资料 | `GEO-001`；[基础设施事实源](../../knowledge_base/locatemy_product/features/infrastructure.md) | 行政区与州及版本，或明确未解析/歧义；缺失不变成零或其他地区 |

### 提供

| ID | 消费者 | 动作与可观察事实 | 输入、结果与失败语义 | 权限与副作用边界 |
| --- | --- | --- | --- | --- |
| `GEO-001` | Cost；Crime；Socio-economic；Infrastructure | 对一个不可变、已通过 `LOCATION-001` 校验的地点引用，取得所请求的行政统计语境（州及行政区）。同一坐标、请求口径和边界资料版本必须产生一致结果。 | 输入是合法地点坐标和所请求口径，而非 Map 的可变状态。每个请求口径分别返回：`resolved`（名称/稳定边界标识、适用州、资料来源与版本）、`unresolved`（可解释原因及已知资料版本）或 `ambiguous`（所有候选及资料来源与版本）。若州可解析而行政区不能解析，已解析州可供结果使用，但未解析层级仍必须如实标记；不把它包装为完整的地区解析。`ambiguous` 不选择任一候选；`unresolved` 不以最近、相邻、默认或名称猜测地区替代。 | 只供 opened 主应用流程的公共只读请求；不读取或写入账户资料。可读取/维护无账户的公共边界缓存，但不得改写 Map 地点、消费者分析结果或任何边界资料。缓存失效和请求时序是 Owner 内部策略，结果版本改变时旧结果不可伪装为当前版本。 |
| `GEO-002` | `GEO-001` 的生产与确定性测试 Adapter | 对给定坐标读取版本化行政边界对象，公开零、一或多匹配以及该批边界资料的来源、版本与可读状态。 | 输入是坐标。零匹配返回可区分的未覆盖/资料不可读等原因；一匹配返回对应边界事实；多匹配返回完整候选集，均附同一读取批次的资料来源与版本。资料版本不存在、来源无法验证或读取不可用时，不能宣称已解析。空间匹配细则在 `RISK-GEO-02` 关闭前仍待验证，但其结果必须可重复验证。 | 只读外部/镜像边界资料与无账户公共缓存；不作网络或数据写入承诺、不修改地点或下游结果。生产 Adapter 与固定样本测试 Adapter 的替换不得改变上述可观察结果语义。 |

## 3. 数据、确定性规则与用户结果

| 目的 | 权威对象或事实源 | 访问 / 应用边界 | 必须保持的语义 |
| --- | --- | --- | --- |
| 行政统计地理解析 | [Schema Catalog：`administrative_district_boundaries`](../data/schema-catalog.md#公共政府镜像与边界对象)；[`GEO-002`](../system/interfaces.md#外部来源-seam) | Geographic Context 经版本化只读边界对象读取；Flutter 不直接查询镜像表 | 返回州和行政区的边界事实、来源与版本；已导入、审计并通过固定空间样本验证 |
| 州级治安语境 | [治安事实源](../../knowledge_base/locatemy_product/features/crime_security.md#计算范围) | Crime 只消费 `GEO-001` 的州结果；其后按 `crime_district.state` 聚合 | 不读取或解析警区边界；统计州归并规则由治安事实源定义 |
| 下游行政区、州级资料与回退 | [生活成本](../../knowledge_base/locatemy_product/features/cost_of_living.md)、[社会经济](../../knowledge_base/locatemy_product/features/socio_economic.md#已确认的产品口径)、[基础设施](../../knowledge_base/locatemy_product/features/infrastructure.md) | Geo 仅提供地理事实；各 Feature 按自己的事实源读取统计资料并决定是否允许州级回退 | Geo 不把行政区缺失改为州级成功，也不决定指标缺失、可比性或回退文案 |
| 公共缓存与退出边界 | [数据所有权](../system/data-ownership.md#公共资料镜像与缓存) | 可替换公共缓存不含账户字段；退出可保留 | 版本属于结果；零/多匹配不以附近地区替代 |

本 Module 固定以下确定性应用口径，完整产品规则仍保留在上述唯一事实源：

- **口径分离**：行政区用于收入、供水、供电、医疗、教育等地区统计；州结果用于州级犯罪统计。任何消费者均不得将一种结果当成另一种。
- **逐层诚实**：请求的每个层级各自报告结果。州已解析不证明行政区已解析；反之亦然。
- **候选集完整**：坐标在边界上或落入重叠区时，所有覆盖它的行政区均为候选并返回 `ambiguous`；只有恰有一个候选时才返回 `resolved`。这同样适用于统计州，故州级治安可能不可用而非猜选州。
- **版本可见**：resolved、unresolved 与 ambiguous 都携带足以识别所用边界资料的来源/版本事实；消费者在展示、缓存或比较时保留它，而不以读取时间替代资料版本。
- **无推测回退**：零匹配、多匹配、资料不可读、版本不可验证均不产生任一地区的伪解析。下游仅可应用其事实源已明确授权的统计层级回退。

| 用户或消费者动作 | 成功结果 | 空、不可用或失败结果 | 必须保持的安全 / 可访问性语义 |
| --- | --- | --- | --- |
| 请求行政统计语境 | 返回州及行政区，附来源/版本，供行政区资料查询使用 | 返回行政区的 unresolved 或 ambiguous；若只有州已知，明确只提供州 | 不以附近行政区、默认城市或名称猜测补全；不改变地点 |
| 请求州级治安语境 | 返回州，附来源/版本，供州级安全读数使用 | 返回州的 unresolved 或 ambiguous | Crime 据此显示其既有的“暂不可用”语义；不请求或推测警区 |
| 同地点由多个消费者请求 | 在相同口径和版本下返回相同地理事实 | 版本不同或资料不可读时显式显示各自事实，不能声称可比 | 公共读取不暴露账户或收藏名称；调用不产生对地点、指标或远端资料的写入 |

## 4. 验收与 Ready Gate

| Capability / 消费者 | 验收情景 | 操作 | 可观察结果 |
| --- | --- | --- | --- |
| Cost（`D09`） | 已明确位于一个行政区的合法地点 | 请求行政统计语境并交给 Cost | 得到相同州/行政区和边界来源/版本；Cost 可按其事实源查询，Geo 未决定成本或回退 |
| Crime（`D13`；`SAFE-01`、`SAFE-03`） | 合法地点 | 请求州级语境 | 州结果供安全分析聚合 `crime_district`；不产生警区结果或安全图层 |
| Socio-economic（`D23`；`SOCIO-01`–`03`） | 州可解析但行政区零匹配的合法地点 | 请求行政统计语境并发起社会经济读取 | 返回已解析州和明确行政区 unresolved；仅由 Socio 的事实源决定可否显示州级参考，且保留统计层级 |
| Infrastructure（`D27`；`INFRA-01`） | 行政区 unresolved 或 ambiguous | 请求行政统计语境并发起分项读取 | 各相关分项保持缺失/原因，不以零、邻近行政区或交通结果补齐 |
| `GEO-002` / `RISK-GEO-02` | 边界点、离岛、重叠、多边形外坐标和行政边界版本样本 | 用同一固定样本重复请求 | 每例稳定地产生零、一或多匹配；多匹配完整列候选；每个结果附正确来源/版本；无附近替代 |
| 跨消费者一致性 | 两个消费者以同一地点、口径和版本并行/重复请求 | 比较结果 | 地理标识、名称、州、来源与版本一致；不共享账户资料或改写彼此分析 |

### 未关闭 Ready Gates

- [x] **`RISK-GEO-02`**：批准的行政区边界已按固定版本导入并记录来源、原始/派生 hash 和修复标识；离岛、边界点、重叠、零覆盖和版本事实的证据见风险记录。
- [x] **Schema 可用性（`RISK-SCHEMA-01` 的本 Module 部分）**：`administrative_district_boundaries` 已按 Catalog 导入；稳定 RPC、authenticated-only 权限和实际导入审计均已验证。
- [x] **实现前独立审查**：已审查 Capability、Interface、数据、流程、风险、无可提交代码边界和本文件链接；固定资料验证、远端导入/权限验收与安全顾问发现均已记录，受控 RPC 例外由项目负责人接受。
- [x] **项目负责人批准**：项目负责人于 2026-09-14 批准本 Module 为 `Ready for Development`；实现学生仍待另行分配，不阻碍设计状态。

Ready Gate 完成判据：下列复选项全部成立，且上述未关闭 Gate 已由项目负责人记录处置。

- [x] 共享必要性、消费者、Owner（待分配）和受控文件边界明确。
- [x] `GEO-001` / `GEO-002` 的协调契约、数据/事实源与可观察副作用有单一来源。
- [x] 行政区与州的口径分离、版本保留和无推测回退已链接唯一事实源并写明应用语义。
- [x] 阻塞问题归零；独立审查完成；项目负责人已批准 `Ready for Development`。

## 5. Change Log

| 日期 | 状态 | 变更原因 | 影响的 Feature / Interface / 数据对象 | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Draft` | Issue #7 建立 Wave 1 Geographic Context owning design | Cost、Crime、Socio-economic、Infrastructure；`GEO-001`、`GEO-002`；两类边界对象 | 待项目负责人审查 |
| 2026-09-14 | `Draft` | 项目负责人选定行政区运行资料；详见 [`RISK-GEO-02`](../system/risks-and-decisions.md#risk-geo-02-资料决定与未关闭证据) | Cost、Crime、Socio-economic、Infrastructure；`GEO-001`、`GEO-002`；行政区边界对象 | 项目负责人 |
| 2026-09-14 | `Draft` | 项目负责人确认警区多边形边界不可获取，移除警区解析和 `SAFE-02`；Crime 改消费州结果并聚合原始警区记录 | Crime；`GEO-001`、`GEO-002`；`police_districts_boundary` 退役 | 项目负责人 |
| 2026-09-14 | `Draft` | 项目负责人确认边界点与重叠返回完整 `ambiguous` 候选集；导入可修复源内退化环，但不裁剪或消除资料重叠 | `GEO-001`、`GEO-002`；行政区边界导入审计 | 项目负责人 |
| 2026-09-14 | `Ready for Development` | 项目负责人接受 authenticated-only 受控 RPC 例外并批准完成资料导入、空间验证和独立审查；实现学生暂未分配 | Geographic Context；`GEO-001`、`GEO-002`；行政区边界与导入审计 | 项目负责人 |
