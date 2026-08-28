# UI 设计规范与 Flutter + Supabase 技术架构逻辑

## 全局 UI/UX 设计规范 (Bento Design System)

本系统采用现代 **Bento Grid（便当盒网格）** 设计语言，以**深邃理性的科技蓝（Tech Blue）**作为核心主色调。通过模块化容器、高信息密度排版、层次分明的视觉权重与精致的微交互，为用户提供清晰、专业、数据驱动的搬迁决策与空间分析体验。

---

### 1. 核心设计理念 (Design Philosophy)

* **Bento 模块化容器 (Modular Bento Grid)**：将复杂的宏观数据、微观排雷、财务演算与交通指标分解为大小各异、功能明确的独立“便当盒”卡片，降低认知负荷。
* **数据即界面 (Data-as-Interface)**：突出数据指标与微观对比，图表、数字、标签与状态灯具备自解释性。
* **层次与呼吸感 (Hierarchy & Whitespace)**：依靠统一的大圆角（$16\text{dp}\sim 24\text{dp}$）、微描边（$1\text{px}$）与柔和环境光阴影营造悬浮立体感，避免杂乱。
* **理性科技感 (Rational & Trustworthy)**：以沉稳克制的蓝色系为基底，辅以高辨识度的语义功能色，传递严谨、权威的政经与生活数据洞察。

---

### 2. 色彩系统 (Color System)

系统定义了基于 Flutter Material 3 的全局色彩 Token，保证全平台视觉一致性：

#### 2.1 主色调 (Primary Palette - Tech Blue)
| 角色 / Token | 色值 (Hex) | 用途说明 | Flutter 映射 |
| :--- | :--- | :--- | :--- |
| **Primary Base (主色)** | `#1E40AF` (Blue 800) / `#2563EB` (Blue 600) | 核心品牌色、重要操作按钮、当前定位 Pin、关键高亮 | `ColorScheme.primary` |
| **Primary Hover/Dark** | `#1D4ED8` (Blue 700) | 按钮按下态、导航激活态底色 | `ColorScheme.onPrimaryContainer` |
| **Primary Light / Container** | `#EFF6FF` (Blue 50) | Bento 卡片激活背景、选中高亮底色、轻量 Badge 底色 | `ColorScheme.primaryContainer` |
| **Primary Tint / Accent** | `#38BDF8` (Sky Blue 400) | 趋势折线图主轴、高亮环形进度条、数据指针 | `ColorScheme.tertiary` |

#### 2.2 辅助与语义功能色 (Semantic & Functional Colors)
| 语义分类 | 色值 (Hex) | 搭配浅底色 (Hex) | 业务应用场景 |
| :--- | :--- | :--- | :--- |
| **Success (安全 / 优势)** | `#10B981` (Emerald 500) | `#ECFDF5` (Emerald 50) | 治安良好评级、预算结余、公共交通 500m 极佳覆盖 |
| **Warning (警示 / 中度风险)** | `#F59E0B` (Amber 500) | `#FFFBEB` (Amber 50) | 季风雨季预警、中度物价波动、目标地 B40 临界线 |
| **Danger (危险 / 严重隐患)** | `#EF4444` (Red 500) | `#FEF2F2` (Red 50) | 积水黑点、治安死角 Pin、预算严重超支、犯罪率偏高 |
| **Info / Mobility (通勤设施)** | `#06B6D4` (Cyan 500) | `#ECFEFF` (Cyan 50) | 轻轨/地铁站点、ICI 基础设施雷达图指标、GTFS 实时到站 |
| **Secondary Target (对比目标)**| `#F97316` (Orange 500) | `#FFF7ED` (Orange 50) | 选址比对中的“目标住址 (Pin B)”专属区分色 |

#### 2.3 中性色阶与表面层级 (Neutral & Surface Colors)
| 层级 / Token | Light Mode (浅色) | Dark Mode (暗色) | 界面用途 |
| :--- | :--- | :--- | :--- |
| **Background (全局底色)** | `#F8FAFC` (Slate 50) | `#0B0F19` (Deep Navy) | 页面最底层背景画布 |
| **Surface Base (Bento 卡片底色)**| `#FFFFFF` (Pure White) | `#131B2E` (Navy Slate) | 标准 Bento 便当盒卡片容器 |
| **Surface Sub (次级嵌入容器)** | `#F1F5F9` (Slate 100) | `#1E293B` (Slate 800) | 卡片内部的小指标格、搜索框、输入框底色 |
| **Border / Stroke (微描边)** | `#E2E8F0` (Slate 200) | `#2E3A52` (Slate 700) | 卡片 1px 极细边框，提供明确边界 |
| **Text Primary (主要文字)** | `#0F172A` (Slate 900) | `#F8FAFC` (Slate 50) | 标题、核心数值、关键指标文字 |
| **Text Secondary (次要文字)** | `#475569` (Slate 600) | `#94A3B8` (Slate 400) | 描述段落、图表轴标、副标题 |
| **Text Muted (弱化辅助)** | `#94A3B8` (Slate 400) | `#64748B` (Slate 500) | 时间戳、免责声明、禁用态文字 |

---

### 3. 排版与字体系统 (Typography System)

* **推荐字体栈 (Font Family)**：`Plus Jakarta Sans` / `Inter` / `SF Pro Display`，中文及回退字体采用 `PingFang SC` / `Noto Sans SC`。
* **数字与数值呈现**：涉及金额、GDP 比率、百分比、经纬度等关键度量，强制开启等宽数字特性（`fontFeatures: [FontFeature.tabularFigures()]`），确保在 Bento 统计卡片中对齐严谨。

#### 3.1 字阶规范表 (Type Scale)
| 样式级别 | 字号 (FontSize) | 字重 (FontWeight) | 行高 (LineHeight) | 适用场景 |
| :--- | :--- | :--- | :--- | :--- |
| **Display (超级大字)** | $28\text{sp}\sim 32\text{sp}$ | `Bold (700)` | $36\text{sp}$ | Bento Hero 主卡片核心金额与综合得分 |
| **Title Large (一级标题)** | $20\text{sp}\sim 22\text{sp}$ | `SemiBold (600)` | $28\text{sp}$ | 页面顶栏 AppBar、大模块主标题 |
| **Title Medium (卡片标题)** | $16\text{sp}\sim 17\text{sp}$ | `SemiBold (600)` | $22\text{sp}$ | 每个 Bento 便当盒卡片的 Header 标题 |
| **Body Regular (正文内容)** | $14\text{sp}$ | `Regular (400)` | $20\text{sp}$ | 指标详情说明、验房 Checklist 条目、排雷详情 |
| **Label / Sub (次级标签)** | $12\text{sp}$ | `Medium (500)` | $16\text{sp}$ | 状态 Badge、图表 Legend、表单辅助说明 |
| **Caption (弱化注释)** | $11\text{sp}\sim 10\text{sp}$ | `Regular (400)` | $14\text{sp}$ | 数据来源标注 (DOSM/NAPIC)、最后同步时间戳 |

---

### 4. Bento 便当盒网格与布局体系 (Bento Layout & Grid System)

Bento 布局通过非对称但高度规整的网格，实现信息“一目了然、错落有致”的视觉享受：

#### 4.1 栅格参数基准
* **屏幕边距 (Screen Padding)**：水平 $16\text{dp}$，垂直 $16\text{dp}$（在大屏/平板上为 $24\text{dp}$）。
* **卡片间距 (Grid Gaps / Spacing)**：卡片与卡片之间统一为 $12\text{dp}$ 或 $16\text{dp}$。
* **列基准 (Column System)**：移动端采用 **2 列基础网格 (2-Column Grid)**，支持多种跨度组合。

#### 4.2 Bento 卡片规格与跨度模式 (Card Spans)
```
┌─────────────────────────────────────────────────────────┐
│              Hero Banner Card (Span 2x1)                │  <- 跨 2 列大卡：核心时机/综合评级
├────────────────────────────┬────────────────────────────┤
│   Metric Square (Span 1x1) │   Metric Square (Span 1x1) │  <- 1x1 方块：单一数据 KPI
├────────────────────────────┴────────────────────────────┤
│              Drill-down Chart Card (Span 2x2)           │  <- 跨 2 列高卡：折线/雷达图表
├────────────────────────────┬────────────────────────────┤
│   Tall Action (Span 1x2)   │   Micro Info A (Span 1x1)  │
│   (如快捷排雷入口)         ├────────────────────────────┤  <- 错落组合：增强界面节奏感
│                            │   Micro Info B (Span 1x1)  │
└────────────────────────────┴────────────────────────────┘
```

#### 4.3 卡片容器形态标准 (Card Container Specs)
* **圆角半径 (Corner Radius)**：
  - 标准 Bento 卡片：`BorderRadius.circular(20.0)`（极简大圆角）。
  - 内部嵌套子容器/Badge：`BorderRadius.circular(10.0)`。
  - 药丸型标签/FAB：`BorderRadius.circular(999.0)` (Full Capsule)。
* **描边与投影 (Stroke & Elevation)**：
  - 采用 **轻量描边 + 柔和环境光 (Subtle Border + Soft Ambient Shadow)** 组合，坚决摒弃生硬的纯黑浓重投影。
  - 描边：`border: Border.all(color: AppColors.cardBorder, width: 1.0)`
  - 投影参数：
    ```dart
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.04),
        blurRadius: 16.0,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
    ]
    ```

---

### 5. 图标、徽章与视觉元素规范 (Iconography & Badges)

* **图标选型 (Icons)**：统一采用 **Rounded / Flat 风格**（推荐 `Lucide Icons` 或 Flutter 原生 `Icons.*_rounded`），线宽保持一致的 $1.75\text{px}\sim 2.0\text{px}$ 视觉重力。
* **状态指示药丸 (Status Pills / Badges)**：
  - 结构：`[状态图标 14dp] + [文字 12dp SemiBold]`。
  - 样式：采用对应语义色的浅色底 + 深色字（例如安全态：`#ECFDF5` 底 + `#059669` 字）。
* **地图 Pin 设计**：
  - Pin A (当前起点)：高亮科技蓝 `#1E40AF` 渐变气泡 + 白色 Home 图标。
  - Pin B (目标新居)：活力活力橙 `#F97316` 渐变气泡 + 白色 Flag 图标。
  - Hazard Pin (排雷点)：告警红 `#EF4444` 六边形/圆角菱形警示框。

---

### 6. 数据可视化设计规范 (Data Visualization Standards)

基于 `fl_chart` 制定统一的图表视觉规则：

* **配色映射**：
  - 主趋势线（如目标地 GDP / 目标地开销）：主色科技蓝 `#2563EB`，带平滑渐变面积阴影（`LinearGradient(colors: [primary.withOpacity(0.25), primary.withOpacity(0.0)])`）。
  - 对比基准线（如全国平均 / 原住址 A）：中性浅灰蓝 `#94A3B8` 虚线或次主色 `#F97316`。
  - 雷达图区域（ICI 指数）：半透明天蓝色填充 `#38BDF8`（Alpha 30%）搭配高饱和度边界。
* **交互细节**：
  - 点击/长按图表点弹出 Bento 风格悬浮 Tooltip（深色底 `#0F172A`，白色等宽数值，带 $8\text{dp}$ 圆角）。
  - 图表网格线采用极细虚线 `#E2E8F0`（暗色模式下为 `#1E293B`），减少视觉噪音。

---

### 7. 交互动效与触觉反馈规范 (Motion & Haptics)

* **微动效曲线 (Animation Curve)**：卡片展开、抽屉上拉均采用自然回弹或平滑减速曲线 `Curves.easeOutCubic` 或 `Curves.fastOutSlowIn`。
* **时长标准 (Duration Tokens)**：
  - 微交互（按钮点击、Badge 切换）：$150\text{ms}$。
  - 卡片下钻/页面路由过渡：$250\text{ms}\sim 300\text{ms}$。
  - 复杂图表加载/雷达图重绘动效：$600\text{ms}\sim 800\text{ms}$。
* **触摸反馈 (Tactile / Haptic Feedback)**：
  - 地图长按触发排雷标记：触发 `HapticFeedback.mediumImpact()`。
  - 预案滑块微调 / 切换 Tag：触发轻微的 `HapticFeedback.selectionClick()`。

---

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