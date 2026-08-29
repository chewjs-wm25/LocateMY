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
| **Info / Mobility (通勤设施)** | `#06B6D4` (Cyan 500) | `#ECFEFF` (Cyan 50) | 轻轨/地铁站点、ICI 基础设施雷达图指标 |
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

**定位**：App 的首页 (Home)，解答“大环境如何？现在是不是搬家的好时机？”

*   **Flutter 组件体系 (Component Detail)**：
    *   `MacroDashboardScreen`: 页面主容器，使用 `Scaffold` 与 `SingleChildScrollView` 构建。
    *   `Hero Banner Card`: 宏观时机综述卡片，包含 `StatusBadge` (Favorable Period) 与 `OutlinedButton` (导航至地图)。
    *   `National Inflation Banner Card`: 消费者物价趋势卡片，使用 `_buildMiniMetricItem` 渲染 Core CPI、Food、Housing、Transport 四大维度指标。
    *   `World Bank GDP Growth & Gini Chart Card`: 经济增长与基尼系数趋势卡片，集成 `fl_chart` 的 `LineChart` 展示 2018-2024 趋势，下方包含 `National Gini Index` 状态条。
    *   `KPI Stats Row`: 包含 `Unemployment Rate` (失业率) 与 `Median Monthly Income` (家庭收入中位数) 的双列 Bento KPI 卡片。
*   **数据流与 Supabase 协同**：
    *   纯公共数据读取，客户端通过 `http` / `dio` 包异步拉取并做内存/本地轻量缓存（`shared_preferences` / `sqflite`），不消耗 Supabase 额度。

---

## 页面 2：空间选址与速览比对页 (Spatial Selection & Quick Compare Map)

**定位**：核心交互入口，解答“从A搬到B，大体上差别有多大？”

*   **Flutter 组件体系 (Component Detail)**：
    *   `SpatialMapScreen`: 地图主页面，采用 `Stack` 布局叠加交互组件。
    *   `Interactive OpenStreetMap`: 使用 `flutter_map` (CartoDB 瓦片) 渲染，包含 `PolylineLayer` (A-B 连线) 与 `MarkerLayer` (Pin A 起点/Pin B 终点)。
    *   `Location Selector Bar`: 顶部浮动位置选择器，包含两个 `DropdownButton` 分别选择 Origin A 与 Target B。
    *   `Floating Map Controls`: 右侧浮动按钮组，包含 `Toggle Hazard Layer` (切换排雷图层) 与 `Recenter Map` (重置视角)。
    *   `Quick Glance Draggable Bottom Sheet`: 底部滑动抽屉，包含：
        *   `Metric Grid`: 渲染 ΔCoL (月度开销差额) 与目标地中位数收入。
        *   `Risk & ICI Lights`: 使用 `StatusBadge` 渲染治安、水灾风险与基础设施综合评分。
        *   `Drill-down Button`: 引导进入深度评估维度的入口。
    *   `Report Hazard Modal (UGC)`: 长按地图触发的 `showModalBottomSheet`，包含 `DropdownButtonFormField` (类别)、`TextField` (标题/描述) 与模拟照片上传。
    *   `Hazard Detail Modal`: 点击排雷 Pin 弹出，包含 `Upvote/Downvote` 验证系统与 `Withdraw` 撤回功能。
*   **交互式扩展功能：社区微观排雷众包图层 (Crowdsourced Hazard Layer)**：
    *   **技术实现 (Flutter + Supabase Free Realtime & Storage)**：
        *   **Create (新增标记)**：用户在 `FlutterMap` 上长按 (`onLongPress`) 触发表单，数据写入 Supabase `crowdsourced_hazards` 表。
        *   **Read (实时渲染)**：通过 Supabase Realtime Stream 监听数据变动，地图 Marker 自动同步。
        *   **Update (协同验证)**：通过 RPC 事务函数 `vote_hazard` 实现点赞确认/质疑。

---

## *(用户在页面 2 选定地点并点击“查看详细评估”后，将进入以下深度解析页面)*

---

## 页面 3：财务与阶层深度演算页 (Financial & Socioeconomic Drill-down)

**定位**：详细的财务测算与预算持久化管理工具。

*   **Flutter 组件体系 (Component Detail)**：
    *   `FinancialDrilldownScreen`: 财务深度分析主页面。
    *   `Scenario Management Header Bar`: 预案管理栏，包含 `DropdownButton` (预案切换)、`Add Button` (新建预案) 与 `Toggle Chart Button` (切换图表)。
    *   `Multi-Scenario Expenditure Comparison Chart`: 交互式 `BarChart`，横向对比不同预案的五大项支出。
    *   `Differential Cost of Living (ΔCoL) Calculator`: 交互式计算器，包含 `Slider` 组（住房、食品、水电、交通、自定义）与 ΔCoL 实时差额看板。
    *   `PriceCatcher 5km Grocery Basket`: 物价追踪列表，表格展示鸡蛋、鸡肉、大米、食油、牛奶在两地的实时价格差。
    *   `Socioeconomic Ladder Card`: 收入阶层梯子，包含 `Slider` (调整个人收入) 与 B40/M40/T20 视觉分布条。
*   **交互式扩展功能：多情景搬家生活开销预案中心 (Multi-Scenario Budget Planner)**：
    *   **技术实现 (Flutter + Supabase Free Postgres & Auth)**：
        *   **Persistence**: 预案数据持久化至 Supabase PostgreSQL，受 RLS 保护。
        *   **CRUD**: 支持新建预案 (`insert`)、修改参数 (`update`)、切换方案与删除方案。

---

## 页面 4：设施与通勤定制评测页 (Infrastructure & Mobility Drill-down)

**定位**：聚焦于目标 B 地点的便利度深度定制。

*   **Flutter 组件体系 (Component Detail)**：
    *   `InfrastructureDrilldownScreen`: 基础设施与通勤评估页面。
    *   `ICI Radar Score View`: 核心看板，集成 `fl_chart` 的 `RadarChart` 渲染五维覆盖率（水、电、医、教、行）。
    *   `IciWeightCustomizer`: 权重动态配置器，包含 `ActionChip` (预设配置文件：家庭/老人/单身) 与 5 个百分比联动 `Slider`。
    *   `TransitCoverageCard`: 公共交通覆盖卡片，展示 500m 步径内 MRT/Bus/KTM 的可达性与具体步行距离。
*   **Supabase 协同**：
    *   用户的个性化 ICI 权重偏好可作为用户元数据（User Metadata）保存在 Supabase Auth 中。

---

## 页面 5：治安与气候避险排雷页 (Safety & Climate Risk Drill-down)

**定位**：最终的“避坑/防灾”确认清单与个人验房资产库。

*   **Flutter 组件体系 (Component Detail)**：
    *   `SafetyClimateScreen`: 治安与气候风险主页面。
    *   `Golden Monsoon Inspection Window Banner`: 季风看房窗口期提醒卡片。
    *   `Police District Safety & Crime Structure Card`: 使用 `fl_chart` 的 `PieChart` 渲染目标警区的犯罪结构（盗窃、破门、抢劫等）。
    *   `Flood History Card`: 区域水灾历史看板，包含 5 年频次、水深、排涝速度等 KPI。
    *   `Property Inspection Portfolio`: 个人房源档案列表，包含 `Dismissible` 房源卡片、`Checkbox` (选中比对) 与 `StatusBadge` (价格比对)。
    *   `NewInspectionForm`: 房源录入表单，包含 **雨季验房 Checklist**（5 星打分制：排水、防水、防潮、交通）。
*   **交互式扩展功能：个人专属“实地验房与房源档案库” (Property Inspection Portfolio)**：
    *   **技术实现 (Flutter + Supabase Free Storage & Postgres)**：
        *   **Photo Storage**: 验房实拍照片上传至 Supabase Storage `inspection_photos` 桶。
        *   **Comparison**: 支持选中多个房源进入 `InspectionComparisonScreen` 并排比对。

---

## 页面 6：多房源横向对比页 (Inspection Comparison Screen)

**定位**：决策最后一步，并排对比不同房源的软硬指标。

*   **Flutter 组件体系 (Component Detail)**：
    *   `InspectionComparisonScreen`: 对比详情页。
    *   `Core Parameters DataTable`: 对比表格，横向呈现各房源的价格、NAPIC 差额、综合验房得分及四大雨季防汛指标。
    *   `Inspection Notes Gallery`: 详细备注列表，展示各房源的实拍环境描述与验房现场记录。
