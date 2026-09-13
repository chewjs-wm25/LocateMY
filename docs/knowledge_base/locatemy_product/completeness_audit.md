---
kb_id: locatemy-knowledge-completeness-audit
kind: audit-reference
language: zh-CN
canonical: true
status: audited
audited_at: 2026-09-12
---

# 当前 UI 原型知识库完整性审计

## 审计口径

本审计只回答：当前 Flutter UI 原型展示的页面、功能意图、数值读数和研究模型，是否已经在知识库中被讨论并记录。项目仍处于前期研究与 UI 原型阶段；本矩阵不做生产可用性验收，也不把代码中的回调、fixture、硬编码或内存状态写成生产功能事实。

## 2026-09-13 工作树复核

本文件原有矩阵引用的 `lib/features/...` 页面文件不在当前 `Rework` 工作树；当前 `lib/` 仅包含最小启动页 `main.dart` 与 Supabase 配置。经 Git 核实，历史原型代码位于 `Prototype` 分支（远端对应 `origin/Prototype`）。因此，以下矩阵保留为该分支 UI 原型的审计与重开发参考，不能作为当前分支代码已存在的证明；设计文档若引用正常态视觉，应明确引用 `Prototype` 分支，并在 Change Log 记录分支差异。

本次接续审查的范围是：地图单点摘要、个人化地点适配度、地点 A/B 比较总览、六类单点分析和六类比较详情。首页、认证、账户、隐患和房产页面的审计结论沿用本文件的既有矩阵。

状态含义：

- `已记录`：展示意图和研究口径已有合理 canonical 事实源。
- `已记录／原型缺口`：意图和口径已记录，但当前 UI 仍是 fixture、缺少数据服务或存在展示限制。
- `代码—口径不一致`：代码展示与已确认的产品口径不一致，必须在重开发或后续原型修订时处理。
- `需产品确认`：知识库不能替产品决定尚未确认的范围；本次地点分析审计未新增此类决定。

## 页面—能力—事实源矩阵

| 当前路由/页面 | UI 原型展示的功能/意图 | 能力 ID | canonical 事实源 | 当前审计结果 | 代码证据 |
| --- | --- | --- | --- | --- | --- |
| `ExplorePage` 单点地图与地点详情卡 | 预设地点、单点/两地切换、可折叠摘要、收藏、完整分析、发起比较、上报隐患 | MAP-01/02/03/04/05/06 | `features/map_location.md`、`domain_objects.md` | 已记录／原型缺口；地图和地点只存在内存，摘要五项读数来自本地 fixture | `lib/features/explore/presentation/explore_page.dart` |
| `ExplorePage` 地点摘要展开态 | 地点名称/地区、安全、成本、周边设施、交通、ICI 摘要；社会经济不放入摘要 | MAP-06、SAFE、COST、INFRA、FAC、TRANSIT | `features/map_location.md`、六类 feature/scoring 文件 | 已记录／原型缺口；安全分始终不可用，其他读数是 fixture 或示例状态；各项口径已写入事实源 | `explore_page.dart` `_summaries()` |
| `ExplorePage` 个人化地点适配度 | 账户五项偏好加权的 0–100 读数，或显示缺失原因 | MAP-06 | `features/map_location.md`、`domain_objects.md` | 已记录／原型缺口；当前代码把安全读数固定为 `null`，因此默认无法生成总分；低优先级缺失和“无可用维度”状态已展示 | `locate_my_state.dart` `locationSuitability`；`location_suitability.dart` |
| `AnalysisPage` 单点分析入口 | 生活成本、治安与犯罪、社会经济、基础设施、周边设施、公共交通六类入口 | MAP-06、COST-01、SAFE-01、SOCIO-01、INFRA-01、FAC-01、TRANSIT-01 | `features/map_location.md`、各六类 feature 文件 | 已记录／原型缺口；单点目标使用 `selected`，页面明确为演示数据 | `analysis_page.dart` `categories`、单点分支 |
| `AnalysisPage` 地点比较总览 | A/B 并列六类主读数并进入对应详情；阻止相同地点 | MAP-04/06、COST-01、SOCIO-03、INFRA-01、FAC-01、TRANSIT-01 | `features/map_location.md`、`domain_objects.md`、各 feature 文件 | 已记录／代码—口径不一致：入口和六类结构存在，但除生活成本外总览读数是硬编码，未逐类读取 A/B 分析结果，且只有一条通用来源/日期说明 | `analysis_page.dart` `_comparisonOverview()` |
| 六类比较详情 | A/B 读数、差异或资料缺失/不可比原因 | 各六类能力 | 各六类 feature/scoring 文件 | 已记录／代码—口径不一致：比较页面结构存在；治安、社会经济、ICI、周边设施、交通详情使用硬编码示例，未按 A/B 结果、状态、来源和日期计算 | `analysis_page.dart` `AnalysisDetailPage.build()` |
| `CostPage` 单点 | 本地价格、统一生活篮子月支出、生活成本指数、预算压力和输入状态 | COST-01/02/03 | `features/cost_of_living.md` | 已记录／原型缺口：读数模型和缺失状态已记录，但代码仍用本地 fixture；单项价格展示把“单位价格”标成 `/月` | `analysis_page.dart` `CostPage`；`cost_of_living.dart` |
| `CostPage` A/B | 同口径生活成本指数、月支出和同名商品价格对照 | COST-01 | `features/cost_of_living.md` | 已记录／原型缺口：指数和月支出读取同一预算场景的 fixture；比较可比性提示已展示；商品价格仍有单位标注问题 | `analysis_page.dart` `_comparisonMetrics()`、`_comparisonPrices()` |
| 治安与犯罪单点 | 警区示意、0–100 安全指数状态、最近五年案件趋势、类别筛选 | SAFE-01/02/03 | `features/crime_security.md` | 已记录／原型缺口：责任边界、公式、警区口径和缺失规则齐全；当前安全卡和趋势全为硬编码示例，不依赖 selected 地点 | `analysis_page.dart` `_safetyPage()`、`_crimeSeries` |
| 社会经济单点 | 行政区收入/基尼、州级 B40/M40/T20 与分布参考、用户家庭收入位置 | SOCIO-01/02 | `features/socio_economic.md` | 已记录／原型缺口：页面主要显示缺失状态；用户百分位函数使用州级 fixture 线性插值，页面仍注明未接入 DOSM | `analysis_page.dart` `_social*()`；`socio_economic.dart` |
| 基础设施单点 | 供水、供电、医疗、教育、公共交通分项，ICI、优先级滑块和缺失状态 | INFRA-01/02 | `features/infrastructure.md`、`infrastructure_index_scoring.md` | 已记录／原型缺口：fixture 已覆盖完整、缺失、明确零值和行政区无法映射场景；公式、数据集、年度错配和 ICI 权重均有事实源 | `analysis_page.dart` `_infra*()`；`infrastructure_index.dart` |
| 周边设施单点 | 2 km 五类设施、数量、最近三项、覆盖/未知状态、OSM 来源和缓存状态 | FAC-01/02 | `features/nearby_facilities.md`、`nearby_facilities_scoring.md` | 已记录／原型缺口：fixture 已覆盖五类、未覆盖、未知和缓存状态；没有综合指数，代码保持这一边界 | `analysis_page.dart` `_nearby*()`；`nearby_facilities.dart` |
| 公共交通单点 | 1.5 km 站点、最近距离、有效路线、交通连通性分、分布图、选中联动和状态场景 | TRANSIT-01/02/03 | `features/transportation.md`、`infrastructure_index_scoring.md` | 已记录／原型缺口：fixture 已覆盖正常、无站点、无有效路线、资料不完整和可能过期；真实 GTFS 未接入 | `analysis_page.dart` `_transport*()`；`transportation.dart` |
| 其他页面 | 首页、全局导航、登录/注册、账户、隐患、房产及既有展示读数 | HOME、NAV、AUTH、ACCOUNT、HAZ、PROP | `features/home.md`、`features/global_navigation.md`、相应 feature 文件 | 已记录；本次不重新审查 | 既有审计结论 |

## 地点摘要与个人化适配度读数矩阵

| UI 读数 | 综合性质/单位 | canonical 公式或规则 | 数据源、地理范围、时间 | 缺失与不可误判边界 | 原型实际状态与审计结果 |
| --- | --- | --- | --- | --- | --- |
| 地点名称与地区 | 身份读数；无分数 | 地点由用户选择的坐标确定 | 当前代码只有吉隆坡、乔治市两个预设；地区文字为联邦直辖区或东北县/槟城 | 地点角色、坐标和行政区不能互相冒充；预设值不等于地点搜索服务 | 已记录／原型缺口；`selected` 用于单点，A/B 只用于比较入口 |
| 地点摘要安全 | 0–100 安全指数；缺失显示 `—` | `crime_security.md`：案件量 `log(1+x)`，同年度警区百分位，assault/property 按 60%/40%反向转换 | `crime_district`；地点所属警区；年度，使用最新完整年度 | 警区无法匹配或两个类别均无数据时不可用；不是人口标准化犯罪率、官方评级或隐患分 | 已记录／原型缺口；摘要固定显示“安全指数暂不可用”，尚未接入警区和年度服务 |
| 地点摘要生活成本 | 以 100 为基准的相对读数；主金额为 RM/月 | `CostIndex = 100 × ScenarioSpend12 / BaseSpend12`；预算压力另按个人预案计算 | `pricecatcher`、`lookup_item`、`lookup_premise`；商品按地点行政区，最近 12 个月；住房/交通/收入是用户预案 | 住房或交通未填写、月份少于 6/12 或覆盖率低于 80%时不显示完整指数/压力；指数不是 CPI 或评级 | 已记录／原型缺口；代码用单次 fixture 价格和固定 `baseSpend12`，摘要会显示部分篮子金额但明确不纳入适配度 |
| 地点摘要周边设施 | 覆盖类别数/文字摘要；不是综合指数 | 每类 `N_c`，覆盖为 `N_c > 0`；未知不计入未覆盖 | OSM Overpass；坐标周围 2 km 直线半径；查询时间或缓存时间 | 查询失败/未知不算未覆盖；未收录不代表现实不存在；不评价质量、营业状态或政府服务 | 已记录／原型缺口；代码有五类 example/cached/unavailable 状态，使用类别覆盖数转换适配度 |
| 地点摘要公共交通 | 交通连通性 0–100 覆盖分；站点为个数 | 距离分 50% + 站点密度百分位 25% + 有效路线百分位 25% | 官方 16 个 GTFS Static feed；坐标周围 1.5 km；以分析日期和 feed 快照为准 | 无站点、无当前有效路线或 feed 不完整时分数不可用；不表示通勤时间、票价、班次或质量 | 已记录／原型缺口；代码 fixture 分数为 72，站点和状态可切换；真实 feed 未接入 |
| 地点摘要 ICI | 0–100 综合覆盖指数 | 五分项基础权重各 0.20；医疗/教育/交通乘以 `priority ÷ 5`，按可用分项归一化；摘要使用中性优先级 5 | 供水/供电/医疗/教育为地点所属行政区；交通为 1.5 km；各分项保留自身日期 | 少于 3/5 分项不可用；缺失不补 0，明确观测 0 保留；不是质量、评级或推荐 | 已记录／原型缺口；单点详情页使用可调 ICI，摘要使用中性 ICI；代码 fixture 已覆盖缺失、零值和无法映射 |
| 个人化地点适配度 | 0–100 个性化读数 | 五维：安全、个人预算压力转换分、五类设施覆盖转换分、交通分、中性 ICI；按 `preference ÷ 5`加权，按可用维度归一化 | 各维度沿用上表事实源；偏好与当前评估预案是账户输入 | 中/高优先级缺失时不可用；低优先级可排除并说明；全部不可用不显示 0；不是客观宜居评分或自动推荐 | 已记录／代码—口径限制；代码把安全分固定为 `null`，因此默认总分不可用；“无可用维度”显示状态已补齐 |

## 六类分析读数与比较矩阵

| 分析域 | 单点页面读数、单位和代码事实 | A/B 比较读数、状态和代码事实 | canonical 公式/数据源/地理时间口径 | 审计结论 |
| --- | --- | --- | --- | --- |
| 生活成本 | 指数、RM/月、篮子覆盖率、可用月份、住房/交通/月净收入输入；代码初始 fixture 为吉隆坡约指数 101、RM 3,741，乔治市约指数 96、RM 3,561；金额随数量和输入变化 | 指数和月支出动态读取 `CostReport`；同名商品对照读取两个地点的 fixture 单价 | `cost_of_living.md`；PriceCatcher 商品价 + 行政区商户映射 + 模型篮子 + 用户输入；最近 12 个月，至少 6 月且覆盖率 80% | 已记录／原型缺口。代码没有实现 canonical 的逐商户中位数和 12 个月平均；单项单位价格被 `_rm()` 错标为 `/月` |
| 治安与犯罪 | 安全指数显示 `—/100`；警区示意；趋势案件数，筛选只影响趋势；代码固定 2020–2024 五年，不随地点变化 | 总览与详情均为不可用/待接入的硬编码状态，不计算差异 | `crime_security.md`；`crime_district`、警区、年度已定罪案件数；不是人口率 | 已记录／原型缺口。2024 示例年份不应被解读为当前官方数据；比较缺少逐地点来源、日期和可比性字段 |
| 社会经济 | 收入中位数、基尼、B40/M40/T20、P1–P100分布；页面主卡为缺失；用户输入家庭月收入后用 fixture 计算州级参考百分位 | 总览/详情硬编码家庭收入 RM 6,420/5,980 与基尼 0.41/0.39，未读取单点结果 | `socio_economic.md`；行政区收入/基尼优先，州级回退；`hies_state_percentile` 的 `median` 做州级参考和相邻点线性插值；年度、名义 RM/月 | 已记录／代码—口径不一致。比较示例与单点缺失状态不同；页面尾注“不使用插值”与实际用户百分位插值函数矛盾，已记录为待修正文案 |
| 基础设施 | 五分项为供水、供电、医疗、教育、公共交通；ICI；1–10医疗/教育/交通滑块；代码默认滑块 7/4/8，页面按 fixture 计算 | 总览硬编码 79/81；详情硬编码 79/81，未读取 A/B `InfrastructureAnalysisResult`，未传递缺失/最低分的真实状态 | `infrastructure_index_scoring.md`；行政区分项 + 1.5 km GTFS；分项各自日期，人口 2022 与资源 2023 错配可见 | 已记录／代码—口径不一致。单点模型已有清晰事实源；比较不能把硬编码值当作实际 A/B ICI |
| 周边设施 | 五类：医疗健康、教育资源、日常生活、交通出行、休闲与绿地；总数、类别覆盖数、最近项和未知状态；不生成综合指数 | 总览硬编码 28/26；详情硬编码 28/26，未按 A/B 查询结果读取 | `nearby_facilities_scoring.md`；OSM Overpass，2 km Haversine 圆形范围；查询/缓存状态 | 已记录／代码—口径不一致。单点 fixture 实际为吉隆坡 29 处/5 类、乔治市 24 处/4 类；比较值不能作为两个地点结果 |
| 公共交通 | 分数、等级、站点总数、最近站、有效路线、站点分布图和选中步行提示；代码正常 fixture 两地点均为 72 分、5站、9条路线 | 总览硬编码 80/3站与72/2站；详情硬编码同样读数，未读取 A/B `TransportReport` | `features/transportation.md`、`infrastructure_index_scoring.md`；官方 GTFS Static，1.5 km，服务日期有效路线；步行分钟不参与评分 | 已记录／代码—口径不一致。单点状态矩阵完整；比较未保留 `availability_status`、feed 日期和逐地点来源 |

## 代码—知识库差异和缺口清单

以下均是原型审计结论，不是生产实现承诺：

1. 比较总览及五类比较详情（治安、社会经济、基础设施、周边设施、公共交通）使用硬编码文本，未从 A/B 的单点结果、来源、日期、缺失状态或可比性计算。生活成本比较是唯一读取 `CostReport` 的比较域，但商品单价的单位文案仍不正确。
2. 单点安全页的趋势和警区名称是全局固定 fixture；其中趋势包含 2024，而 canonical 犯罪数据说明当前官方页面截至 2023。页面已标为示例，不能据此写成官方最新年份。
3. 个人化地点适配度的公式、优先级分层、低优先级重新归一化和无可用维度状态均已记录；当前代码的 `safetyScore` 固定为 `null`，所以摘要不会显示有效总分。安全服务接入前不得把其他四项读数拼成部分总分。
4. 生活成本领域类保留了 `merchantCount`、`recordCount` 和 `months` 字段，但当前 `CostReport` 未实现 canonical 的逐商户中位数、12 个月窗口平均和按实际缺失月份处理；它只能被描述为 UI fixture 计算。
5. 社会经济用户收入位置实际执行相邻百分位线性插值；社会经济页的原型尾注写成“不使用……插值”，与领域函数和 canonical 规则冲突。重开发或继续展示该页时应修正文案，不能删除已确认的插值规则。
6. 地点摘要中的每项已有对应的单位/范围/来源状态事实源，但当前摘要仍有“数据年份待接入”“示例估算”等泛化文案，未逐项呈现完整来源字段；这属于原型信息完整度限制，不新增数据事实。

## 已覆盖与明确边界

- 六类分析均已核对单点入口、主要读数、单位/状态、公式或“无综合公式”、数据源、地理范围、时间范围、缺失规则和不可误判边界。
- 已明确社会经济没有综合指数，周边设施没有 0–100 综合指数；基尼、覆盖类别数、站点数和预算压力不能被误称为指数。
- 已明确地点 A/B 只表示呈现顺序，不表示搬迁方向；比较只有在资料和统计口径可比时才计算差异。
- 已明确 `working`、`partial`、`prototype`、`placeholder` 描述的是原型行为，不代表生产功能；fixture、未知、明确零值和未接入服务不可互换。
- 未发现需要新增到 `CONTEXT.md` 的领域术语结论；本次差异属于原型实现与既有口径的核对结果。
