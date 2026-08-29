# 综合基础设施普及率指数（ICI）评估器

## 1. 模块简介与定位
- **模块名称**：综合基础设施普及率指数（ICI）评估器 (Infrastructure Coverage Index Evaluator)
- **功能描述**：动态整合目标县的水覆盖率、电覆盖率、排污覆盖率、每千人医疗床位数及每万学龄人口学校数。Flutter 移动端提供直观的交互滑块与 `fl_chart` 雷达图，供用户根据亲子、养老或单身等画像自由调整各子项权重，并将个性化偏好同步至 Supabase 云端数据库。

## 2. 决策维度剖析与用户价值
- **公共服务与基础设施可及性维度**：
  - 自来水管网接驳率、供电稳定性与卫生排污设施覆盖率构成了居住环境的基础底线。
  - 对于育儿家庭或老年群体，区域内医疗资源（如卫生部 MoH 医院、非 MoH 公立医院及专科中心床位数）和教育资源（公立小学及中学的每万学龄人口学校数、师生比及毕业率）的配比，直接影响长期居住质量。

## 3. 核心数据源与 API 规范 (100% 免费开放数据)

### 3.1 基础公用设施普及率 (`hh_access_amenities`)
- **数据机构**：马来西亚统计局 (Data.gov.my)
- **数据内容**：全国 16 个州属及 160 个行政县的管道自来水覆盖率（`piped_water`）、卫生设施覆盖率（`sanitation`）及供电覆盖率（`electricity`）。
- **API 端点**：`GET https://api.data.gov.my/data-catalogue?id=hh_access_amenities`
- **关键提取字段**：`state`, `district`, `piped_water`, `sanitation`, `electricity`
- **更新机制**：高稳定性基线数据（HIES 周期更新）。

### 3.2 医疗基础设施数据 (`hospital_beds`)
- **数据机构**：马来西亚卫生部 (MoH) / Data.gov.my
- **数据内容**：统计全国、州及县级的公立医疗床位数（卫生部医院 `hospital_moh`、专科机构 `special_medical_institution`、非卫生部公立医院 `hospital_non_moh`）。
- **API 端点**：`GET https://api.data.gov.my/data-catalogue?id=hospital_beds`
- **关键提取字段**：`state`, `district`, `hospital_type`, `beds`
- **更新机制**：按年度更新。

### 3.3 教育基础设施数据 (`enrolment_school_district` 与 `teachers_district`)
- **数据机构**：马来西亚教育部 (MOE) / Data.gov.my
- **数据内容**：县级公立中小学注册学生人数与教师总数。
- **API 端点**：
  - `GET https://api.data.gov.my/data-catalogue?id=enrolment_school_district`
  - `GET https://api.data.gov.my/data-catalogue?id=teachers_district`
- **关键提取字段**：`district`, `stage`, `students`, `teachers`
- **更新机制**：按年度更新。

---

## 4. 数据合成算法与指数建模 ($ICI$)

定义任意行政县 $d$ 的综合基础设施普及率指数 $ICI_d \in [0, 100]$ 为五项归一化指标的加权组合：

$$ICI_d = \sum_{k=1}^{5} w_k \cdot S_{k, d}$$

其中，$w_k$ 为用户在 Flutter 前端界面根据个人偏好（亲子、养老、单身等画像）设定的权重，满足约束条件：

$$\sum_{k=1}^{5} w_k = 1, \quad w_k \ge 0$$

五项分级得分 $S_{k, d}$ 的数学定义如下：

1. **水资源接驳得分 ($S_{1, d}$)**：直接取自 `hh_access_amenities` 中的 `piped_water` 覆盖率百分比 $P_{\text{water}, d} \in [0, 100]$：
   $$S_{1, d} = P_{\text{water}, d}$$

2. **供电与卫生设施得分 ($S_{2, d}$)**：取供电率 $P_{\text{elec}, d}$ 与卫生排污覆盖率 $P_{\text{san}, d}$ 的均值：
   $$S_{2, d} = \frac{P_{\text{elec}, d} + P_{\text{san}, d}}{2}$$

3. **医疗床位密度得分 ($S_{3, d}$)**：计算县 $d$ 每千人平均拥有的公立医疗床位数 $B_{1k, d}$：
   $$B_{1k, d} = \frac{\text{Hospital Beds}_d}{\text{Total Population}_d} \times 1000$$
   采用极差标准化（Min-Max Normalization）转化为 0-100 标度（以全国各县极值为基准）：
   $$S_{3, d} = \min\left(100, \frac{B_{1k, d} - B_{\min}}{B_{\max} - B_{\min}} \times 100\right)$$

4. **教育资源充足度得分 ($S_{4, d}$)**：结合学龄人口学校密度 $E_{10k, d}$ 与师生比 $R_{TS, d}$：
   $$E_{10k, d} = \frac{\text{Schools}_d}{\text{School-Age Population}_d} \times 10,000$$
   $$R_{TS, d} = \frac{\text{Teachers}_d}{\text{Students}_d}$$
   综合得分为：
   $$S_{4, d} = 0.6 \cdot \text{MinMax}(E_{10k, d}) + 0.4 \cdot \text{MinMax}(R_{TS, d})$$

5. **公共交通可达性得分 ($S_{5, d}$)**：基于 GTFS 数据计算县域内地理网格中 500 米步径可达至少一个公共交通站点的覆盖比例 $T_{\text{cov}, d}$：
   $$S_{5, d} = T_{\text{cov}, d} \times 100$$

---

## 5. Flutter 客户端交互与 Supabase 偏好同步架构

### 5.1 架构设计与 0 成本保证
- **客户端渲染**：Flutter 通过 `Slider` 控件实时动态响应权重变动，利用 `fl_chart` 的 `RadarChart` 进行毫秒级重绘展示各维度得分。
- **云端持久化 (Supabase Free Tier)**：用户的个性化权重偏好与地区对比心愿单保存在 Supabase 的 `user_ici_preferences` 表中，**无需信用卡绑定，完全免费**。

### 5.2 数据库 Schema 与 RLS 安全策略

```sql
CREATE TABLE user_ici_preferences (
  pref_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  water_weight DOUBLE PRECISION NOT NULL DEFAULT 0.20,
  power_sanitation_weight DOUBLE PRECISION NOT NULL DEFAULT 0.20,
  healthcare_weight DOUBLE PRECISION NOT NULL DEFAULT 0.20,
  education_weight DOUBLE PRECISION NOT NULL DEFAULT 0.20,
  transit_weight DOUBLE PRECISION NOT NULL DEFAULT 0.20,
  favorite_districts TEXT[] DEFAULT ARRAY[]::TEXT[], -- 关注的对比心愿单县区
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE user_ici_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User ICI Preferences Self Access"
  ON user_ici_preferences
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

### 5.3 Flutter Dart 集成实现示例

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class IciCalculatorService {
  final _supabase = Supabase.instance.client;

  // 1. 同步保存用户的权重偏好
  Future<void> saveUserPreferences({
    required double wWater,
    required double wPower,
    required double wHealth,
    required double wEdu,
    required double wTransit,
    required List<String> favorites,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('user_ici_preferences').upsert({
      'user_id': user.id,
      'water_weight': wWater,
      'power_sanitation_weight': wPower,
      'healthcare_weight': wHealth,
      'education_weight': wEdu,
      'transit_weight': wTransit,
      'favorite_districts': favorites,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // 2. 获取用户已保存的权重
  Future<Map<String, dynamic>?> fetchUserPreferences() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('user_ici_preferences')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    return response;
  }
}
```