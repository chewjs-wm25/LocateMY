/// min-max 归一到 0-100 的统一实现。
///
/// 供医疗(每千人床位)/教育(师生比)等子项在“同年全国横截面”上打分使用,
/// 避免各处重复实现出现口径漂移。
library;

/// [value] 目标县在该年份横截面上的原始值(如 每千人床位 2.1、师生比 0.05);
/// [pool] 同一年份全国所有县的同类原始值。
///
/// 返回:
///  - pool 为空 → null(该年横截面无参照,无法归一);
///  - pool 极差为 0(max <= min) → 100.0(全国各县相同,目标县即为最优);
///  - 否则 (value-min)/(max-min)*100,收敛在 0-100。
double? minMaxNormalized(double value, List<double> pool) {
  if (pool.isEmpty) return null;
  var min = pool.first;
  var max = pool.first;
  for (final v in pool.skip(1)) {
    if (v < min) min = v;
    if (v > max) max = v;
  }
  if (max <= min) return 100.0;
  return ((value - min) / (max - min) * 100).clamp(0.0, 100.0);
}
