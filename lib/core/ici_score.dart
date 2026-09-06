/// ICI(综合基础设施普及率指数)公平口径计算。
///
/// 背景问题:
/// 旧实现只对"实际存在"的子项求均值(缺失项被静默剔除,分母随之变小),
/// 导致"缺医疗/教育数据的地区"往往拿到接近 100 的虚高指数,
/// 而数据齐全的地区反而因纳入更多(数值较低的)子项只拿到 80 上下。
///
/// 公平口径规则:
///  1. 固定基期:除 [transitApplicable] = false(未在地图上选点,交通无法评估)外,
///     分母始终累加 5 个子项的权重,不因某项缺失而缩小。
///  2. 源数据缺失的已评估子项(如 healthcare / education 查不到该县数据):
///     分数按 0 计入(保守下限),权重保留在分母 —— 缺数据不再等于满分。
///  3. transit 在未选点时不参与评估:该项的权重与分数一并剔除,
///     避免把"用户没选点"误当成"该地无交通"。
///
/// 返回值 0-100;没有任何可评估子项时返回 null(界面显示 '—')。
library;

const List<String> kIciKeys = [
  'water',
  'power',
  'healthcare',
  'education',
  'transit',
];

/// transit 是否处于可评估状态(传入坐标即视为可评估)。
/// [scores] 中 null 表示该子项本次无数据(源缺失或未评估)。
double? computeIciScore(
  Map<String, dynamic> scores, {
  required bool transitApplicable,
  double wWater = 0.2,
  double wPower = 0.2,
  double wHealth = 0.2,
  double wEdu = 0.2,
  double wTransit = 0.2,
}) {
  final weights = <String, double>{
    'water': wWater,
    'power': wPower,
    'healthcare': wHealth,
    'education': wEdu,
    'transit': wTransit,
  };

  double numerator = 0;
  double denominator = 0;
  var hasAnyScore = false;
  for (final key in kIciKeys) {
    if (key == 'transit' && !transitApplicable) continue;
    final w = weights[key] ?? 0;
    if (w <= 0) continue;
    denominator += w;
    final v = scores[key];
    if (v is num) {
      // 数据存在:按实际得分计入;缺失:按 0 计入(权重保留)。
      hasAnyScore = true;
      numerator += v.toDouble().clamp(0.0, 100.0) * w;
    }
  }
  // 没有任何可评估子项存在得分 → 无数据可评,返回 null(界面显示 '—')。
  if (denominator <= 0 || !hasAnyScore) return null;
  return (numerator / denominator).clamp(0.0, 100.0);
}

/// 返回"因源数据缺失而无法评分的子项"清单(用于界面提示与完整性徽章)。
/// [scores] 中 null 且 [transitApplicable](或该项非 transit)即视为缺失;
/// transit 未评估时不计入缺失清单。
List<String> missingSourceItems(
  Map<String, dynamic> scores, {
  required bool transitApplicable,
}) {
  final missing = <String>[];
  for (final key in kIciKeys) {
    if (key == 'transit' && !transitApplicable) continue;
    if (scores[key] is! num) missing.add(key);
  }
  return missing;
}
