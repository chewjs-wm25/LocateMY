# Module B：开销预算与房产评估（Cost of Living, Budget & Property）作业回顾

> 本模块由原"生活开销与预算""房产检查"两块融合而成：它们共同回答"搬过去之后，
> 开销划不划算、房子靠不靠谱"，预案金额是等效预算换算的基础，房产档案又复用同一套
> 警区/风险解析基础设施，是一组围绕"搬迁经济与居住决策"的用户评估数据。
>
> 涉及文件：`lib/views/cost_of_living/cost_of_living_view.dart`、
> `lib/views/property/`（5 个页面）、`lib/providers/budget_provider.dart`、
> `lib/providers/property_provider.dart`、`lib/repositories/cost_of_living_repository.dart`、
> `lib/repositories/security_risk_repository.dart`、`lib/models/budget_scenario.dart`、
> `lib/models/property_inspection.dart`、`lib/core/supabase/district_resolver.dart`、
> `lib/core/cache/local_cache_service.dart`、`lib/widgets/star_rating_selector.dart`、
> `lib/widgets/mini_map.dart`
>
> 对应数据实体：云端 `user_budget_scenarios`（预算预案，RLS 限定本人）；
> 数据库已建 `user_property_inspections` 表但档案当前为内存态（见 Q3）。

---

## Q1. Please briefly describe the module(s)/function(s) you engaged in the assignment. Indicate clearly the APIs and external libraries used.

本模块帮助用户在搬迁前把两件事算清楚：**搬去新地点的开销**，以及**候选房子的
实地情况**。两者共享同一个起点——用户在地图上选定的收藏位置，并经同一套地点归一
与警区解析服务把坐标、县名、别名统一成真实行政区。

**开销对比与等效预算**部分负责"两地生活成本差异"的计算展示。`getComparisonData`
对起点/终点（可以是县名、州名或城市别名）先经 `DistrictResolver` 归一为真实行政区
与州，再取两州最新月份的整体 CPI（`cpi_state`，`division='overall'`），计算购买力
变化百分比、开销差异百分比与"是否更划算"，同时经 RPC `get_district_prices` 拉取
PriceCatcher 的县域民生品均价用于微观物价对比，结果带 3 天本地缓存（过期即删除）。
若当前预案的金额合计大于 0，则以 `equivalent_budget = baseBudget × targetCpi /
originCpi` 返回"在新地点维持同等生活所需的预算"，界面直接展示换算前后的金额；
没有预案金额时，界面改用一次性输入框按同一 CPI 比值做本地实时换算，不保存。

**预算预案（Budget Scenario）的 CRUD**把上述换算与"我的预算计划"持久化到云端表
`user_budget_scenarios`（`user_id` 外键关联 `profiles`，RLS 限定只能操作自己的预案）：
新增预案 `addScenario(name)` 用 `insert(...).select()` 把服务端生成的 uuid 与默认
时间戳回填成本地模型并设为当前预案；读取在 Provider 构造时按当前用户拉取预案列表；
更新分两类——`renameScenario` 改预案名（界面有编辑对话框），`updateCurrentScenario`
已实现更新住房/生活/交通三类金额（`max_rent` / `living_expenses` /
`transport_allowance`）并落库，供预算编辑界面调用；删除 `deleteScenario` 删掉预案并
自动把当前预案切换到剩余的第一条。生活开销页围绕这些能力提供预案下拉切换、新增、
重命名、删除按钮，以及 CPI 对比图表、价格对比表与预算换算器。

**房产检查档案（Property Inspection）的 CRUD**面向"实地看房"：看房时记录目标房产
的名称、地址、价格、雨季隐患检查清单（排水、防水、湿度、照明各 1–5 分，总体评分
取平均）、照片占位、淹水线索与备注。新增 `addInspection` 若带坐标，会先经
`SecurityRiskRepository.getRiskContext` 并行查询 `crime_stats` 与
`crowdsourced_hazards`，自动补齐警区名、10 分制安全分与附近隐患数（期间置
`isLoadingRiskData`），再构造不可变 `PropertyInspection` 加入列表；读取经档案库列表、
详情页与对比页共用同一 Provider；更新 `updateInspection` 用 `copyWith` 生成新对象
替换原项，仅当坐标真正变化时才重算风险上下文；删除是软删除——`deleteInspection`
先把记录移入回收站再从档案列表移除，`restoreInspection` 可单条恢复，
`clearRecycleBin` 整批清空，配合详情页删除前的确认对话框。看房录入表单由
`AddPropertyScreen` 同时承担新增与编辑两职：从收藏位置选择地址（带迷你地图预览）、
填写价格与备注、逐项打分、管理照片占位（点按追加、可标记主图、可移除）、开关
"本地淹水线索"并填写备注；中途输入的名称、价格、所选位置与清单分值实时同步到
Provider 的草稿字段，离开再进入可续填。档案库支持长按进入多选模式、勾选多套房产
进入并排对比页；详情页分卡展示照片/价格、位置与迷你地图、治安、水灾风险、检查
清单、图库与备注，并支持编辑与删除；回收站页可恢复或清空。为演示 UI，列表内置了
5 条示例房产作为首启数据。房产档案入口同时存在于治安页（"添加房产"悬浮按钮与档案
卡片）和账户页（Property Inspection Portfolio）。

使用的 API 与外部库：

- **Supabase / PostgREST**（`supabase_flutter: ^2.6.0`）：`user_budget_scenarios` 的
  `insert().select()` / `select().eq('user_id', ...)` / `update(...).eq('id', ...)` /
  `delete().eq('id', ...)`；`cpi_state` 查询；RPC `get_district_prices` 与
  `match_police_district`；`crime_stats` / `crowdsourced_hazards` 查询；Auth 定位归属；
- **本地缓存**：`sqflite` + `path`（`LocalCacheService`，`cached_reports` 表）；
- **Flutter 生态**：`provider`（`ChangeNotifier` 状态管理）、`fl_chart: ^1.2.0`
  （对比图表）、`flutter_map` + `latlong2`（位置预览与迷你地图）、`intl: ^0.20.2`
  （RM 货币/百分比格式化）、`flutter_localizations` 中英文本地化、Material 组件；
- 数据对象为普通不可变 Dart 类（`BudgetScenario` / `PropertyInspection` +
  `copyWith` + `toJson`），无代码生成；照片为占位实现，未引入 image_picker。

---

## Q2. What are the strengths of the modules/functions created by you?

- **围绕"预案 + 档案"形成可落地的 CRUD 结构**：预算预案的增删改查全部对接云端并在
  插入时用 `.select()` 让服务端把生成的 uuid 与默认时间戳回填到本地模型，本地与
  服务端状态一致；房产档案则用"软删除 → 回收站 → 恢复/清空"的完整链路配合删除
  确认，误删成本低。
- **与选址和风险数据天然联动**：房产新增或移动坐标时自动命中警区、计算安全分与
  附近隐患数；开销对比与治安/社会经济等模块共用 `DistrictResolver` 与 RPC 查询设施，
  看房记录不是孤立表单，而是带区位风险评估的复合档案。
- **计算口径来自真实数据而非写死**：CPI、购买力、等效预算全部由 `cpi_state` 最新
  数据推导，物价来自 PriceCatcher 真实均价，代码中没有伪造的示例数字；输入地点
  统一归一，容忍"KL / 吉隆坡 / Kuala Lumpur / Petaling Jaya"这类异名。
- **缓存与请求策略分层合理**：静态参考数据（CPI 比值、物价）三天一换走本地缓存，
  用户自己的预案/档案每次变更实时生效；`fetchComparison` 以 `origin|target` 为请求
  键并支持 `force` 刷新，重复触发不会重复请求。
- **表单与状态设计复用度高**：新增/编辑共用一套表单（靠 `existingInspection` 区分），
  校验、布局与提交逻辑不重复；多个页面共享单一 Provider，任何页面增删改后其余页面
  自动同步；表单草稿跨页保留，中途离开不丢已填内容；不可变模型 + `copyWith` 避免
  就地修改的脏状态，`toJson` 也为将来落库预留出口。
- **优雅降级**：无预案金额时只展示 CPI 比值、不做金额换算，缓存旧版本（无金额字段）
  命中后自动补算；缺 CPI 数据或请求失败时有明确错误与重试入口。

---

## Q3. What are the weaknesses of the modules/functions created by you?

- **房产档案没有持久化**：档案与回收站只存在于内存，重启即丢失；数据库端
  `user_property_inspections`（含 `inspection_data jsonb`、`image_urls text[]`）已建好
  且 RLS 就绪，但代码尚未接入，属于"有表无实现"，是模块最需要补齐的一环；内置的
  5 条示例房产是硬编码种子，会与真实用户档案混在一起，容易误导。
- **预案的"金额编辑"闭环未完成**：`updateCurrentScenario` 已实现并可写库，但界面
  没有入口调用它，预案创建时只保存名称（金额为默认 0），因此无预案金额时界面退回
  "一次性输入月支出"的本地换算且无法保存回预案——预案更像"命名收藏"。
- **写操作缺少面向用户的错误反馈与回滚**：新增、改名、删除预案与档案写失败大多只
  `debugPrint`；删除预案时内存先改、云端失败则界面与数据库不一致，UI 无提示。
- **字段映射与结构弹性有限**：预案金额是三类固定列（`max_rent` /
  `living_expenses` / `transport_allowance`）且模型与表列之间是手写映射，无统一序列化
  层，增加类别或改表结构容易漏改。
- **照片功能是占位实现**：没有接入相机/相册，"添加照片"只追加 `mock_photo_N`
  字符串，图库与主图标记的 UI 逻辑完整但无真实图片。
- **风险上下文时效性与口径不一致**：房产安全分只在新增或坐标变更时计算一次，编辑
  其他字段不刷新；且其公式是简化启发式（`9.8 − 罪案数/500` 截断），与治安页的精细
  评分口径不同，两处数字可能对不上。
- **其余细节**：对比缓存以"起点 _to_ 终点"为键且无版本协商，月中更新 CPI 时会偏旧；
  匿名/未登录时预算功能整体静默失效且无登录引导；多选对比藏在长按手势里，可发现性
  偏低；表单提交与风险数据加载存在竞态的可能。

---

## Q4. What have you learned in doing this assignment?

- **用 `.select()` 拿回服务端生成列**：Supabase 的 `insert()` 默认不返回行，配合
  `.select()` 才能拿到 `gen_random_uuid()` 的主键与 `now()` 默认时间戳，客户端据此
  建立与云端一致的对象引用，是"写后读一致"的实用技巧，预案与灾害上报都因此受益。
- **软删除是低成本高价值的 UX 设计**：把"删除 = 移入回收站"作为中间态，用恢复与
  清空两个方向补全误删链路，比直接物理删除更贴近真实产品。
- **集中状态 + 不可变数据让多页同步变简单**：多个页面共享一个 Provider 时，只要所有
  修改都走公开方法并以 `copyWith` 生成新对象，页面间的自动同步几乎零成本；草稿状态
  提升到 Provider 后，页面销毁重建仍可续填。
- **归一化层解决"叫法不统一"**：开销对比面对的 CPI 只有州级口径，而输入可能是县名
  或别名，把"任意写法 → 真实行政区/州"做成一层共享清洗服务（`DistrictResolver`），
  比在各仓库里各写一套匹配可靠得多。
- **请求幂等与缓存版本要一起设计**：以"请求键 + force + 内存态"控制重复请求比盲目
  节流贴合业务；字段演进（如新增 `base_budget`）时旧缓存要能补算而非直接失效，缓存
  的版本号与数据自洽同样重要。
- **功能与数据库必须同步演进**：界面先做出"看起来完整"的 CRUD、持久化却没有跟上，
  最终形成内存 demo 与真实表结构之间的落差——设计阶段就该把落库方案纳入功能定义。

---

## Q5. What are the challenges, if any, you faced while working on this assignment?

- **州级 CPI 与县/别名输入的落差**：UI 接受"Petaling、JB、吉隆坡"等写法但 CPI 只有
  州级，直接查表会查不到；解决方式是先用 `DistrictResolver` 归一化到州，再在失败时
  回退展示原始输入，保证任何合法输入都有结果。
- **插入后拿不到服务端行**：预算预案最初 insert 后本地乐观渲染，但主键是服务端 uuid，
  本地无法构造稳定引用，导致新预案无法被后续更新/删除命中；改为 `insert(...).select()`
  从响应解析后追加才解决——这与灾害上报模块遇到的"临时 id 换真实 id"是同一个问题的
  两种表现。
- **删除的本地/云端一致性**：删除当前预案或房产后要处理"当前项指针转移"，且云端
  失败而内存已改会造成界面与数据库不一致，目前只靠 try/catch 兜底，缺少 UI 回滚提示。
- **缓存字段演进**：对比结果从无金额字段升级到带 `base_budget` 后，旧缓存命中要能
  自动补算等效预算，否则升级后的界面会显示空金额；这个兼容分支的编写与回归验证
  比较耗时。
- **多入口导航与异步时序**：房产档案同时被治安页（悬浮按钮/档案卡片）与账户页导航，
  还要能回到地图 Tab 选点，理顺"从哪进、提交后回哪"需要反复调整导航栈与 Provider
  状态；同时协调提交标志与风险数据加载标志、避免重复提交或档案缺风险字段，是调试
  较多的部分。
- **口径统一的技术债**：为控制依赖，房产的风险上下文用了与治安页不同的简化评分，
  两套口径并存需要后续收敛；演示房产数据与真实用户档案的边界、以及将来接入
  `user_property_inspections` 表时示例数据的去留，都需要在产品化层面做取舍。
