# Home Page 真实数据接入与计算逻辑实现计划 (修订版)

根据用户反馈，本计划将严格遵循“无兜底数据”原则，优先使用数据库现有数据计算指标，若数据缺失则显示错误或加载状态。同时接入 `docs/old` 中定义的计算公式。

## 用户评审要求

- **无兜底数据**：移除所有硬编码的 Fallback 数据。如果查询失败或表不存在，UI 相应位置将显示错误图标或正在加载状态。
- **实时计算逻辑**：对于缺失的宏观指标（如搬迁指数），将基于 `hh_income_district`、`cpi_state`、`crime_stats` 和 `hh_access_amenities` 等现有表进行聚合计算。
- **公式来源**：参考 `docs/old` 中的 ICI 指数、CoL 演算器及风险评分模型。

## 提议的更改

### 1. 数据模型增强 (Models)

#### [home_stats.dart](file:///D:/Work/Mobile Application/Assignment/lib/models/home_stats.dart)
- 为每个指标字段改为可选类型 (`double?`)，以便区分“加载中”、“数据缺失”和“正常数值”状态。

---

### 2. 仓库层逻辑优化 (Repository)

#### [home_repository.dart](file:///D:/Work/Mobile Application/Assignment/lib/repositories/home_repository.dart)
- **搬迁时机指数 ($Score$) 计算公式**：
  - 基于 `docs/old` 的多维决策维度合成：
  - $Score = 5.0 + (\text{收入增长率} \times 0.2) - (\text{通胀率} \times 0.2) + (\text{全国平均 ICI} / 20) - (\text{犯罪率增长率} \times 0.1)$
  - 范围限制在 $[0.0, 10.0]$。
- **全国平均 ICI 计算**：
  - 聚合 `hh_access_amenities` (水/电/卫生)、`hospital_beds` (医疗)、`enrolment_school_district` (教育) 等表。
- **拒绝兜底**：移除原本的 `try-catch` 默认值返回。如果 Supabase 返回错误（如表不存在），则向上层抛出异常。

---

### 3. 状态管理与 UI (State Management & UI)

#### [home_provider.dart](file:///D:/Work/Mobile Application/Assignment/lib/providers/home_provider.dart)
- 记录每个细分指标的加载状态和错误信息。
- 提供 `isRefreshLocked` 逻辑（1 分钟冷却）。

#### [home_screen.dart](file:///D:/Work/Mobile Application/Assignment/lib/views/home/home_screen.dart)
- **卡片级状态处理**：
  - 为 `HeroCard`、`MetricCard`、`GDPChartCard` 添加加载骨架屏或错误占位图。
  - 如果 `stats.unemploymentRate` 为 null，显示“暂无数据”。
- **GDP 图表**：根据 `stats.gdpTrend` 动态绘制。如果数据为空，展示“数据获取失败”。
- **刷新按钮**：在 `AppShell` 的 AppBar 中实现，并带有冷却提示。

## 验证计划

### 自动化测试
- 运行 `flutter test`。
- 模拟数据库表缺失的情况，确保 UI 不崩溃且显示错误状态。

### 手动验证
1. **数据计算验证**：手动计算一部分数据库数据（如 CPI 同比），对照应用显示的数值是否正确。
2. **错误状态展示**：通过临时修改数据库表名，验证卡片是否正确显示“错误/暂无数据”状态。
3. **刷新冷却测试**：验证 60 秒内点击刷新按钮是否能正确弹出 SnackBar 提示。
4. **无缓存验证**：清除 App 缓存后启动，检查是否展示了正确的加载动画。
