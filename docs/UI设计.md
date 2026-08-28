# UI 设计规范与 Flutter + Supabase 技术架构逻辑

## 整体技术栈规范与选型原则

* **前端框架**：Flutter (Dart 3.x) — 跨平台原生渲染（iOS / Android），采用响应式架构与 Material 3 设计系统。
* **地图底图与渲染**：`flutter_map` + OpenStreetMap (OSM) / CartoDB 开放瓦片源（**100% 免费开源，无需绑定信用卡或获取计费 API Key**）。
* **图表库**：`fl_chart` — 高性能矢量图表绘制（雷达图、折线图、柱状图、条形堆叠图）。
* **后端与数据库**：Supabase Free Tier（**永久免费版，注册无需绑定信用卡**）：
  - **Database**：PostgreSQL 15+（免费启用 `postgis` 空间拓扑插件）。
  - **Auth**：Supabase 认证（Email/Password、匿名登录，内置 RLS 行级安全策略）。
  - **Storage**：Supabase Storage（免费 1GB 存储，存放实地验房照片与排雷现场图片）。
  - **Realtime**：Supabase Realtime（基于 Postgres CDC 实现众包排雷数据毫秒级同步推送）。
  - **Client SDK**：`supabase_flutter` 官方 SDK。
* **开放数据中台**：直接集成马来西亚官方 Open Data API（Data.gov.my, OpenDOSM, MET Malaysia, JPS, World Bank API，均为 0 成本开放接口）。

---

## 页面 1：马来西亚宏观时机仪表盘 (Macro Timing Dashboard)

**定位**：App 的首页（Home），解答“大环境如何？现在是不是搬家的好时机？”

* **Flutter 组件体系**：
  - `MacroDashboardScreen`：使用 `CustomScrollView` + `SliverAppBar` 构筑沉浸式 Bento Grid 布局。
  - `MacroGdpTrendCard`：嵌入 `fl_chart` 的 `LineChart`，调用世界银行 (World Bank Open Data API) 渲染马来西亚历年 GDP 增长率与基尼系数变动。
  - `NationalInflationBanner`：调用 OpenDOSM 总体 CPI 接口，展示全国通胀趋势与宏观建议 Tag（如“当前租金上行期”、“物价平稳期”）。
* **数据流与 Supabase 协同**：
  - 纯公共数据读取，客户端通过 `http` / `dio` 包异步拉取并做内存/本地轻量缓存（`shared_preferences` / `sqflite`），不消耗 Supabase 额度。

---

## 页面 2：空间选址与速览比对页 (Spatial Selection & Quick Compare Map)

**定位**：核心交互入口，解答“从A搬到B，大体上差别有多大？”

* **Flutter 组件体系**：
  - `DualLocationMapScreen`：全屏 `FlutterMap`，支持双图钉（Pin A: 蓝色当前住址，Pin B: 橙色目标住址）自由拖拽与地址自动检索（Nominatim 开放反向地理编码）。
  - `QuickGlanceCard`：位于地图底部的滑动抽屉 `DraggableScrollableSheet`，动态呈现两地核心指标对照：
    - **开销预估差额**：$\Delta \text{CoL}_{A \to B}$ 粗略月度变动。
    - **家庭中位数收入对比**：双柱状图对比两地 Household Income Median。
    - **综合风险指示灯**：红/黄/绿 Badge 展示治安评级与水灾风险评级。

### 交互式扩展功能：社区微观排雷众包图层 (Crowdsourced Hazard Layer)
* **技术实现 (Flutter + Supabase Free Realtime & Storage)**：
  - **图层开关控制**：地图右上角 `FloatingActionButton` 切换排雷图层（Toggle `MarkerLayer`）。
  - **Create (新增标记)**：
    1. 用户在 `FlutterMap` 上长按 (`onLongPress`) 触发 `showModalBottomSheet` 弹出排雷表单。
    2. 类别选择：`DropdownButtonFormField`（治安死角、积水点、照明故障、物价异常）。
    3. 照片上传：调用 `image_picker` 拍摄/选图，通过 `supabase.storage.from('hazard_photos').upload()` 上传至 Supabase 免费对象存储，返回公开 URL。
    4. 数据写入：`supabase.from('crowdsourced_hazards').insert({...})` 写入 PostGIS 坐标。
  - **Read (查看微观卡片与实时渲染)**：
    - 地图视窗平移触发 Supabase PostGIS RPC 函数 `get_hazards_in_bounds`，毫秒级读取矩形视窗内的 Warning Pins。
    - 点击 Pin 弹出详情卡片，展示实拍图片（`CachedNetworkImage`）、发生时间与“证实/质疑”统计。
  - **Update (协同验证/状态更新)**：
    - 交互按钮：`IconButton` 👍 (Upvote) 与 👎 (Downvote)，调用 Supabase RPC 事务函数 `vote_hazard` 安全原子递增。
    - 原作者权限：通过 Supabase RLS 策略校验 `auth.uid() = user_id`，原作者可点击“标记为已解决”。
    - **Realtime 监听**：通过 `supabase.from('crowdsourced_hazards').stream(primaryKey: ['hazard_id'])` 实现多端协同，无需手动刷新地图。
  - **Delete (撤回标记)**：
    - 原作者在详情弹窗点击“撤回”，调用 `supabase.from('crowdsourced_hazards').delete().eq('hazard_id', id)`，地图即时抹除 Pin。

---

## *(用户在页面 2 选定地点并点击“查看详细评估”后，将进入以下 3 个深度解析页面，数据均基于页面 2 选定的 A 和 B 地点动态生成)*

---

## 页面 3：财务与阶层深度演算页 (Financial & Socioeconomic Drill-down)

**定位**：详细的财务测算与预算持久化管理工具。

* **Flutter 组件体系**：
  - `CostOfLivingCalculatorScreen`：分步表单与交互滑块 `Slider`，用户可输入/调整各项月度实际支出（住房、食品、水电公用、交通等）。
  - `PriceCatcherComparisonView`：调用 PriceCatcher API 比对两地周边 5km 内超市/巴刹的菜篮子物价差异。
  - `IncomeClassLadderView`：结合 OpenDOSM 数据以阶梯进度条展示目标县 B40/M40/T20 门槛及用户薪资所处分位。

### 交互式扩展功能：多情景搬家生活开销预案中心 (Multi-Scenario Budget Planner)
* **技术实现 (Flutter + Supabase Free Postgres & Auth)**：
  - **预案管理 Bar**：页面顶部放置 `DropdownButtonHideUnderline` 预案切换器与“新建预案”按钮。
  - **Create (保存为新预案)**：
    - 用户调整参数后点击“保存预案”，弹窗输入方案名称（如“吉隆坡单身极简方案”）。
    - 调用 `supabase.from('user_budget_scenarios').insert({...})` 持久化写入 PostgreSQL，受 RLS 保护仅当前登录用户可写。
  - **Read (预案切换与双方案横向对比)**：
    - 下拉切换方案触发 `setState` 重新加载参数；
    - 点击“预案对比”调用 `fl_chart` 的 `BarChart` 并排渲染双方案各消费大项（住房/食品/交通/自定义）的对比柱状图。
  - **Update (修改参数并覆盖)**：
    - 用户调整滑块后点击“更新预案”，调用 `supabase.from('user_budget_scenarios').update({...}).eq('scenario_id', currentId)`。
  - **Delete (删除废弃预案)**：
    - 列表项支持 `Dismissible` 滑动删除，调用 `supabase.from('user_budget_scenarios').delete().eq('scenario_id', targetId)`。

---

## 页面 4：设施与通勤定制评测页 (Infrastructure & Mobility Drill-down)

**定位**：聚焦于目标 B 地点的便利度深度定制。

* **Flutter 组件体系**：
  - `InfrastructureMobilityScreen`：选项卡切换架构。
  - `IciWeightCustomizer`：动态权重配置器，提供 5 个带有百分比联动的交互式 `Slider`（水覆盖率、电覆盖率、排污覆盖率、医疗床位、学校资源）。
  - `IciRadarScoreView`：使用 `fl_chart` 的 `RadarChart` 实时根据用户微调的权重计算并渲染雷达图得分。
  - `TransitCoverageCard`：基于 GTFS 静态数据展示居所 500 米步径内的公共交通站点覆盖率。
  - `RealtimeTransitBoard`：调用 APAD / Prasarana / KTMB 的 GTFS-Realtime 开放接口，展示最近站点的实时列车动态与预计到站时间。
* **Supabase 协同**：
  - 用户的个性化 ICI 权重偏好可作为用户元数据（User Metadata）保存在 Supabase Auth 中，实现跨设备免密即时同步。

---

## 页面 5：治安与气候避险排雷页 (Safety & Climate Risk Drill-down)

**定位**：最终的“避坑/防灾”确认清单与个人验房资产库。

* **Flutter 组件体系**：
  - `SafetyClimateScreen`：分区数据看板。
  - `CrimeStructurePieChart`：使用 `fl_chart` 的 `PieChart` 渲染目标警区的暴力犯罪与财产犯罪比例。
  - `FloodHistoryCard`：展示过去 5 年该区域的水灾频次、平均水深与退水恢复时间。
  - `GoldenInspectionWindowBanner`：结合 MET Malaysia 降雨与季风数据，突出显示“雨季黄金看房窗口期”。

### 交互式扩展功能：个人专属“实地验房与房源档案库” (Property Inspection Portfolio)
* **技术实现 (Flutter + Supabase Free Storage & Postgres)**：
  - **模块布局**：页面下半部分采用 `ListView.builder` 渲染已保存的房源档案卡片，右下角悬浮 `FloatingActionButton`（“+ 添加看房记录”）。
  - **Create (添加待验房源档案)**：
    1. 点击打开全屏录入页 `NewInspectionForm`。
    2. 输入房源基本信息（名称、门牌、租金/售价）。
    3. “雨季验房 Checklist”：打分组件（排水通畅度、地下车库防水、墙面防潮、周边道路通行能力，1-5 星级打分）。
    4. 实拍照片：调用 `ImagePicker` 拍照，批量上传至 Supabase Storage `inspection_photos` Bucket，获取图片 URL 数组。
    5. 调用 `supabase.from('user_property_inspections').insert({...})` 写入。
  - **Read (房源卡片列表与 NAPIC 比对)**：
    - 列表卡片展示封面图、防汛综合得分、NAPIC 县级均价比对 Tag（如“低于均价 12%”）。
    - 支持多选 2-3 个房源卡片，进入 `InspectionComparisonScreen` 并排比对实拍照片墙与 Checklist 得分。
  - **Update (修改验房打分与价格)**：
    - 点击卡片进入详情编辑页，修改议价后的租金、补充二次看房照片并调用 `.update()` 更新数据库。
  - **Delete (淘汰房源)**：
    - 卡片左滑 `Dismissible`，确认后调用 `.delete()` 物理删除或归档，并同步调用 Supabase Storage API 清理废弃图片。