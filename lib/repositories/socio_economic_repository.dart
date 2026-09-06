import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../core/supabase/supabase_client_manager.dart';
import '../core/supabase/district_resolver.dart';
import '../core/cache/local_cache_service.dart';

/// 社会经济数据仓库：对接真实表 `hh_income_district`。
///
/// 真实表结构：state, district, date, income_mean, income_median。
/// 该表不含 gini / poverty_rate 字段，因此基尼系数与收入百分位
/// 由“收入均值 + 收入中位数”拟合的对数正态分布推导（估计值），
/// 而不是写死的示例数字。
class SocioEconomicRepository {
  final SupabaseClientManager _supabase = SupabaseClientManager();
  final LocalCacheService _cache = LocalCacheService();
  final DistrictResolver _resolver = DistrictResolver();

  /// 查询某位置的收入数据。位置可为行政县名（districtHint）或坐标。
  Future<Map<String, dynamic>> getSocioEconomicData({
    required String districtHint,
    double? lat,
    double? lng,
  }) async {
    final cacheKey = '${districtHint}_${lat?.toStringAsFixed(3) ?? 'na'}_${lng?.toStringAsFixed(3) ?? 'na'}';
    final cached = await _cache.getCachedData(
      'socio_economic_v2',
      cacheKey,
      expiry: const Duration(days: 3),
    );
    if (cached != null) {
      return (cached as Map).cast<String, dynamic>();
    }

    final resolved = await _resolver.resolve(
      name: districtHint.isEmpty ? null : districtHint,
      latLng: lat != null && lng != null ? LatLng(lat, lng) : null,
    );
    final districtName =
        resolved?['district'] ?? (districtHint.isNotEmpty ? districtHint : null);
    if (districtName == null) {
      throw Exception('无法确定该位置的行政区');
    }

    // 1) 该县全部年份 → 最新年份为当前口径，取前一年算增长。
    final rows = await _supabase
        .from('hh_income_district')
        .select('state, district, date, income_mean, income_median')
        .eq('district', districtName)
        .order('date', ascending: false);

    if (rows.isEmpty) {
      throw Exception('未找到该地区的收入数据（$districtName）');
    }
    final latest = rows.first;
    final previous = rows.length > 1 ? rows[1] : null;
    final median = ((latest['income_median'] as num?) ?? 0).toDouble();
    final mean = ((latest['income_mean'] as num?) ?? 0).toDouble();
    final prevMedian = previous != null
        ? ((previous['income_median'] as num?) ?? 0).toDouble()
        : 0.0;

    // 2) 全国排名：按“各县最新年份”的 income_median 排序（等效最新横截面）。
    final allRows =
        await _supabase.from('hh_income_district').select('district, income_median');
    final byDistrict = <String, double>{};
    for (final row in allRows) {
      final d = row['district']?.toString();
      final v = (row['income_median'] as num?)?.toDouble() ?? 0;
      if (d == null || d.isEmpty) continue;
      byDistrict[d] = math.max(byDistrict[d] ?? 0, v);
    }
    final sorted = byDistrict.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final rankIndex = sorted.indexWhere((e) => e.key == districtName);
    final rank = rankIndex >= 0 ? rankIndex + 1 : null;
    final total = sorted.length;

    // 3) 拟合对数正态分布（σ² = 2 ln(mean/median)）。
    final sigma = _fitSigma(mean, median);
    final lnMedian = median > 0 ? math.log(median) : 0.0;

    const b40Ceiling = 4850.0; // RM/月，国家统计局阶层切分参考
    const t20Floor = 10959.0;
    final pB40 =
        sigma == null ? null : _lognormalCdf(b40Ceiling, lnMedian, sigma);
    final pT20 =
        sigma == null ? null : 1 - _lognormalCdf(t20Floor, lnMedian, sigma);
    final pM40 = (pB40 != null && pT20 != null)
        ? (1 - pB40 - pT20).clamp(0.0, 1.0).toDouble()
        : null;

    final data = <String, dynamic>{
      'district': districtName,
      'state': latest['state'],
      'year': latest['date'],
      'median_income': median,
      'mean_income': mean,
      'income_growth_pct': (previous != null && prevMedian > 0)
          ? (median - prevMedian) / prevMedian * 100
          : null,
      'rank': rank,
      'total_districts': total,
      'ln_median': lnMedian,
      'sigma': sigma,
      'gini_index': sigma == null ? null : _giniFromSigma(sigma),
      'class_share_b40': pB40,
      'class_share_m40': pM40,
      'class_share_t20': pT20,
    };

    try {
      await _cache.cacheData('socio_economic_v2', cacheKey, data);
    } catch (e) {
      debugPrint('SocioEconomicRepository cache write failed: $e');
    }
    return data;
  }

  /// 由均值/中位数反推对数正态 σ。
  double? _fitSigma(double mean, double median) {
    if (mean <= 0 || median <= 0 || mean < median) return null;
    final v = 2 * math.log(mean / median);
    if (v < 0) return null;
    return math.sqrt(v);
  }

  /// 某收入在该县拟合分布中的百分位（0-100）。
  double? incomePercentile(Map<String, dynamic> data, double income) {
    final sigma = (data['sigma'] as num?)?.toDouble();
    final lnMedian = (data['ln_median'] as num?)?.toDouble();
    if (sigma == null || lnMedian == null || sigma <= 0 || income <= 0) {
      return null;
    }
    return _normalCdf((math.log(income) - lnMedian) / sigma) * 100;
  }

  double _lognormalCdf(double x, double lnMedian, double sigma) {
    if (x <= 0) return 0;
    return _normalCdf((math.log(x) - lnMedian) / sigma);
  }

  double _normalCdf(double z) => 0.5 * (1 + _erf(z / math.sqrt(2)));

  double _erf(double x) {
    final sign = x < 0 ? -1.0 : 1.0;
    final ax = x.abs();
    final t = 1.0 / (1.0 + 0.3275911 * ax);
    final y = 1 -
        (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t -
                    0.284496736) *
                t +
            0.254829592) *
            t *
            math.exp(-ax * ax);
    return sign * y;
  }

  double _giniFromSigma(double sigma) =>
      2 * _normalCdf(sigma / math.sqrt(2)) - 1;
}
