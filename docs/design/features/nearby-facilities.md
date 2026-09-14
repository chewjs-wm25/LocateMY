# 周边设施

> 状态：`Ready for Development`
> Owner：待项目负责人分配
> 系统基线：`5d11769`
> 依赖波次：5
> 最后更新：2026-09-14
> Prototype 视觉参考：N/A

本文件是周边设施 Feature 与其消费者的高层协调设计。它固定可观察成果、模块责任、跨
Owner 契约、受控文件边界和验收情景；Feature 内部的类型、文件拆分、运行时策略与测试
组织归实现 Owner。

## 1. 用户成果与范围

- 用户成果：对一个已选地点，用户能理解其中心 2 公里圆形范围内五类**已收录** OSM
  设施的类别覆盖、数量和每类最近三项；结果清楚说明来源、时间、缓存或资料不确定性。
  在地点 A/B 比较中，用户看到两端各自结果及可比性，而不会把单点读数伪装成比较结果。
- 包含的 Capability ID：`FAC-01`。
- 不包含及原因：`FAC-02`（设施详情、展开和路线）已排除；不产生 0–100 综合指数，
  也不评价设施质量、营业状态或政府服务水平。地点选择、地图底图和相机不属于本
  Feature；账户资料及其私有队列亦不属于本 Feature。
- 产品事实源：[周边设施](../../knowledge_base/locatemy_product/features/nearby_facilities.md)、
  [单个地点周边设施覆盖](../../knowledge_base/locatemy_product/nearby_facilities_scoring.md)、
  [核心业务对象](../../knowledge_base/locatemy_product/domain_objects.md)。
- 原型差异：正式实现只展示五类、真实查询目标的单点或 A/B 结果，删除固定数量、装饰性
  箭头和“查看更多”；“日常便利”仅是评估偏好维度，面向分析页面和摘要统一称“周边设施”。

## 2. 依赖、责任与文件边界

| 模块 / 文件边界 | Owner | 负责 | 不负责 | 与其他模块的沟通 |
| --- | --- | --- | --- | --- |
| `docs/design/features/nearby-facilities.md` 所定义的 Feature 内部目录 | Nearby Facilities | Overpass 外部 seam、五类归类、同一 OSM 对象去重、圆形过滤、最近项、结果完整性、24 小时公共缓存和设施声明式呈现贡献 | 可变地点、导航/组合、OSM 底图、账户私有资料、设施详情/路线 | 消费 `LOCATION-001`；提供 `FACILITY-001`；通过 `LOCATION-002` 提交图层贡献 |
| Application Shell 组合槽位 | Application Shell | 分析页/比较总览/地点摘要的导航、返回上下文和组合呈现 | 解读设施标签、计算或缓存设施结果 | 消费 `FACILITY-001` 的带地点、范围、来源、时间和完整性结果 |
| Map / Location | Map / Location | 合法不可变地点引用、底图、相机、图层宿主及点击意图转交 | OSM 查询、类别解释、缓存和结果语义 | `LOCATION-001` 向本 Feature 给出地点；`LOCATION-002` 接收声明式设施贡献 |
| Overpass / OpenStreetMap | 外部 | 返回供本 Feature 处理的 OSM 原始元素或可分类失败 | 产品类别、距离过滤、缓存、账户数据或页面结论 | `FACILITY-002`；其适配、请求、超时、重试和限流策略封装在 Feature 内 |

### 依赖与未决项

| 依赖或问题 | 影响 | 验证方式 / 最迟解决点 |
| --- | --- | --- |
| `D14` / `SHELL-001` 已 Ready | 分析导航、摘要和 A/B 组合只能由 Shell 呈现 | 实现前读取 [Application Shell 设计](../modules/application-shell.md)；集成时验证返回原任务上下文 |
| `D15` / `LOCATION-001` 已 Ready | 每次查询、缓存结果和贡献均绑定合法不可变地点，不能读可变选点或默认地点 | 以不同请求先后完成及无/非法/A=B 地点情景验证绑定与拒绝语义 |
| `LOCATION-002` 已 Ready | 设施图层只以声明式贡献进入地图，点击不泄漏地图内部对象 | 以 accepted/hidden/rejected 和点击意图情景验证 |
| `RISK-OSM-01` | 不完整、超时或限流外部响应若被当作空集，会产生误导性未覆盖 | Ready Gate：用完整、截断、超时、限流和无效 payload 的代表响应证明只有完整响应可产出空结果 |
| `RISK-CACHE-01` | 坐标、半径或类别映射版本错配会展示另一地点/口径的结果 | Ready Gate：手工核验邻近坐标、类别版本升级和 24 小时边界，证明 key 与回带结果一致 |

## 3. 对外协调契约

### 提供

| ID | 消费者 | 动作与可观察事实 | 输入、结果与失败语义 | 权限与副作用边界 |
| --- | --- | --- | --- | --- |
| `FACILITY-001` | Application Shell；Map / Location 摘要；Personalized Location Suitability | 为一个合法不可变地点提供固定 2,000 米范围的五类设施结果和声明式设施呈现贡献；单点与 A/B 的每一端分别取得自己的结果。每项结果回带地点、半径、类别映射版本、来源、查询/缓存时间及完整性。 | 输入是地点引用与 `cache-allowed` 或 `refresh`。输出为 fresh、cached、complete-empty、retryable unavailable 或 non-retryable unavailable；类别层面完整且 `N_c=0` 才是“范围内暂无已收录设施”，查询失败、超时、限流、无效或部分外部响应为 unknown/unavailable，绝不以零替代。A/B 只有两端各自为完整且同一半径/类别映射版本时才可比较；否则输出带原因的不可比性。`refresh` 绕过缓存；失败可降级为仍在 24 小时内的缓存，并标为 cached。 | 只在 opened 主应用中读取；OSM 资料和缓存不含账户标识。Feature 只读外部资料、读写公共设施缓存并提交其图层贡献；不写账户资料、全局地点或其他 Feature 结果。 |
| `FACILITY-002` | Overpass（外部 seam） | 接受完整 OSM 原始元素集，或把限流、超时、网络、无效及部分响应清楚传回 Feature。 | 只有可证明完整的 Node、Way、Relation 响应可以进行归类并得出覆盖或 complete-empty；外部 seam 的网络请求、取消、重试、超时、限流与 Adapter 细节归 Feature 内部，不构成跨 Owner 契约。 | 无账户权限或用户业务副作用；原始外部资料不得越过 Feature 被消费者当作产品结果使用。 |

### 消费

| ID | Owner | 使用目的 | 调用方依赖的结果与失败语义 |
| --- | --- | --- | --- |
| `SHELL-001` | Application Shell | 接收单点/A-B 分析导航、返回上下文，并向地点摘要/比较组合提供结果 | 只有 opened 主应用 scope 可接受目的地；Shell 保留地点、来源、日期、范围和不可用原因，且不把分项失败隐藏为成功 |
| `LOCATION-001` | Map / Location | 读取单点或 A/B 的合法不可变地点引用 | 使用 `valid location reference`；`absent`、`outside Malaysia`、`invalid coordinate` 或 `same comparison point` 不能触发查询、缓存写入或图层贡献 |
| `LOCATION-002` | Map / Location | 提交已加载结果的声明式设施图层，并接收点击意图 | 接受/隐藏/拒绝按 Map 契约；贡献包括显示条件、稳定 OSM 条目标识、类别/名称/距离等由本 Feature 定义的内容及类型化点击意图。Map 只呈现和转交，不解释设施业务内容；图层更新不得改变分析地点。 |

## 4. 用户可观察行为与跨模块流程

| 入口或用户动作 | 成功结果 | 空、不可用或失败结果 | 必须保持的可访问性 / 安全语义 |
| --- | --- | --- | --- |
| 从单点分析进入“周边设施” | 展示明确地点、`2 公里`范围、五类的数量、最近三项、直线距离、来源与时间；同一 OSM 对象仅出现一次且只归一类 | 完整空类别显示“范围内暂无已收录设施”；全部完整空显示 `2 公里内暂无已收录周边设施`；未知类别显示资料无法确定而非未覆盖 | 用户不依靠颜色理解覆盖/未知；结果说明“未收录不代表现实中不存在”，并显示 `© OpenStreetMap contributors` 及版权链接 |
| 选择地点 A/B 后进入比较 | 两端分别按各自不可变地点查询；并列五类覆盖类别数、设施总数及类别摘要，标明每端来源/时间/完整性 | 任一端未知/不可用或映射版本、半径不一致时显示不可比原因，不显示差异、赢家或由另一端结果代替 | A/B 名称和顺序来自 Map；不读当前可变选点，不默认回退任何城市 |
| 地点摘要组合 | 完整五类结果可显示覆盖类别数及未覆盖类别；五类都覆盖时显示 `2 公里内覆盖全部 5 类` | 任一类别未知时显示 `周边设施覆盖情况暂不可确定`，不显示确定比例；所有类别完整空时使用完整空文案 | 摘要称“周边设施”而非“日常便利”；Shell 保留结果地点、范围、来源、时间和原因 |
| 用户主动刷新 | 重新读取，不使用已有缓存命中；成功显示新的查询时间 | 新查询失败时仅可回落未过期缓存并清楚标为“缓存数据”；无有效缓存时显示“资料暂不可用” | 刷新不改变地点、A/B 角色、账户或其他 Feature；无需账户私有权限 |
| 地图请求设施呈现 | Map 按 Feature 提供的显示条件渲染稳定设施条目，并把点击以类型化意图回传 | 图层贡献被 hidden/rejected 或结果未知时不伪造设施 Marker；较旧 viewport 结果不能覆盖较新结果 | 底图和相机仍由 Map 拥有；点击/呈现不授予设施详情、路线或编辑能力 |

跨 Owner 完成条件：Map 先按 `LOCATION-001` 产出指定角色的不可变合法地点；Nearby
Facilities 以该地点处理或读取结果并向 Shell 提供 `FACILITY-001`。若需要呈现在主地图，
Feature 另以 `LOCATION-002` 提交声明式贡献。Shell 决定导航、摘要或比较的组合；任何
返回结果均保持原地点引用，晚到结果不得替换另一地点或另一 A/B 端的结果。

## 5. 数据与确定性业务规则

| 目的 | 权威对象或事实源 | 访问 / 应用边界 | 必须保持的语义 |
| --- | --- | --- | --- |
| 定义范围、类别和覆盖状态 | [单个地点周边设施覆盖](../../knowledge_base/locatemy_product/nearby_facilities_scoring.md) | 对 `LOCATION-001` 的坐标使用固定 2,000 米；矩形仅可作预筛选，最终按 Haversine 圆形距离过滤 | 页面固定按医疗健康、教育资源、日常生活、交通出行、休闲与绿地呈现。对象归类优先级则固定为医疗健康、教育资源、交通出行、日常生活、休闲与绿地；每个对象只归入第一个匹配类别，药房只计医疗健康；不产生指数或质量判断 |
| 形成可解释的设施结果 | OSM Node、Way、Relation 与相同事实源 | Node 使用自身坐标，Way/Relation 使用返回代表中心点；以 `element_type + osm_id` 去重；每类按直线距离由近到远取前三项 | `N_c>0` 且完整为覆盖；`N_c=0` 且完整才为空类别；未知永不计未覆盖。设施总数与有记录类别数可展示为数量摘要，但未知存在时不显示确定覆盖比例 |
| 保留数据来源与许可披露 | OpenStreetMap / Overpass；[事实源的来源与许可要求](../../knowledge_base/locatemy_product/nearby_facilities_scoring.md#缓存与页面状态) | 每次结果携带 `数据来源：OpenStreetMap`、查询或缓存时间、缓存状态和 OSM 覆盖限制 | 不能用 `schools_district`、`hospital_beds` 或其他行政区汇总推算 2km POI；页面显示 OSM 署名和版权/许可链接 |
| 公共缓存 | `facility_public_cache`（完整定义见 [Schema Catalog](../data/schema-catalog.md)） | 有效期 24 小时；缓存键至少含分析坐标、2,000 米半径及分类映射版本；`refresh` 绕过缓存 | 公共缓存不含账户标识；只有完整响应可缓存为空。失败仅能使用仍有效缓存且必须标示为 cached；缓存结果回带原地点，过期/版本不匹配不可冒充 fresh |
| 供个人化地点适配度复用 | `FACILITY-001` 与 [个人化地点适配度定义](../../knowledge_base/locatemy_product/domain_objects.md#personalized-location-suitability) | 只向适配度消费者公开五类完整性与已确认覆盖类别数，不输出新的设施综合分 | 五类均可确定时，其日常便利转换由消费者按唯一公式计算；任一类别未知时该维度缺失，未知不能当未覆盖 |

## 6. 验收与 Ready Gate

| Capability | 验收情景 | 用户操作 | 可观察结果 |
| --- | --- | --- | --- |
| `FAC-01` | 正常完整覆盖 | 对合法单点打开分析 | 固定 2km 圆形范围内显示五类、数量、每类最近三项、直线距离、来源/时间；不显示 0–100 分、路线、质量或营业状态 |
| `FAC-01` | 完整空结果 | 查询完整且某类或全部类别无匹配设施 | 该类明确为范围内暂无已收录设施；全部为空使用完整空文案，不把它描述为现实不存在 |
| `FAC-01` | 部分外部响应 | 外部返回被截断或完整性不能确认 | 所受影响类别为 unknown/unavailable，不以 0 或未覆盖呈现；不缓存为 complete-empty |
| `FAC-01` | 不可用结果 | 发生超时、限流、网络或无效响应 | 显示分类不可用原因；有未过期缓存则仅展示并标为 cached，无缓存则资料暂不可用 |
| `FAC-01` | 缓存与刷新 | 在 24 小时内重复读取，再主动刷新 | 有效缓存带缓存时间/状态；刷新绕过缓存，成功后带新查询时间，失败遵守缓存降级语义 |
| `FAC-01` | 不可变地点与 A/B | 对单点、A、B 分别发起读取，且让先前请求晚于新请求返回 | 每个结果与其地点/角色相符；晚到结果不能覆盖另一地点；两端不完整或口径不一致时不比较 |
| `FAC-01` | 摘要与地图贡献 | 由 Shell 组合地点摘要，并请求 Map 呈现设施贡献 | 摘要遵守完整/未知规则；Map 只按声明呈现和回传点击，既不改分析地点也不提供排除的设施详情/路线 |
| `FAC-01` | 披露与可访问性 | 阅读正常、空、缓存和不可用状态 | 每种状态有文字而非仅颜色；显示 OpenStreetMap 来源、时间、覆盖限制、署名和版权链接 |

- [x] `FAC-01` 可追踪到 Nearby Facilities Owner、`FACILITY-001`/`FACILITY-002`、
  `facility_public_cache`、唯一产品事实源及上述验收情景。
- [x] `D14`、`D15`、`LOCATION-002` 的责任和副作用与上游 Ready 设计一致；Feature 不拥有
  地点、导航、底图或账户私有资料。
- [x] 2,000 米 Haversine 圆形边界、五类优先级、去重、最近三项、完整空/未知区别、缓存键和
  24 小时新鲜度均链接至唯一事实源并按本设计应用。
- [x] 正常、empty、partial、unavailable、cached、refresh、不可变地点、A/B、摘要、贡献、
  可访问性和来源披露均有可观察验收情景。
- [x] 独立规格/边界审查完成；`RISK-OSM-01` 与 `RISK-CACHE-01` 的契约已冻结，运行时证据留实现/集成验收。
- [x] 设计 AI 已依 ADR 0013 批准 `Ready for Development`。

## 7. Change Log

| 日期 | 状态 | 变更原因 | 受影响的 Capability / Interface / 数据对象 / Feature | 批准者 |
| --- | --- | --- | --- | --- |
| 2026-09-14 | `Draft` | 为 Issue #12 建立 Wave 5 owning design；等待独立审查与 Ready Gate 运行时风险证据 | `FAC-01`、`FACILITY-001`、`FACILITY-002`、`facility_public_cache`、Map / Location、Application Shell、Personalized Location Suitability | — |
| 2026-09-14 | `Ready for Development` | 独立审查确认范围、契约、完整性、缓存、Map/Shell 边界与验收链完整 | `FAC-01`、`FACILITY-001`、`FACILITY-002`、`RISK-OSM-01`、`RISK-CACHE-01` | 设计 AI（项目负责人依 ADR 0013 授权） |
