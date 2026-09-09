import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:locate_my/core/supabase/supabase_client_manager.dart';
import 'package:locate_my/core/supabase/district_resolver.dart';
import 'package:locate_my/core/cache/local_cache_service.dart';

/// 社会经济数据仓库：以真实 Supabase 数据为准计算 B40/M40/T20 占比与基尼系数。
///
/// 数据优先级（全部来自真实表，口径为家庭月收入 RM）：
/// - 县级收入：`hh_income_district`（income_mean / income_median）；
/// - 县级真实基尼：`hh_inequality_district.gini`（缺省降级州级
///   `hies_state.gini` → 全国 `hh_inequality.gini`，再无则退回分布拟合）；
/// - 官方阶层门槛：`hies_malaysia_percentile` 中第 40 / 80 百分位的
///   “median”收入（2024 年全国口径：B40 ≤ ~RM5,810；T20 ≥ ~RM12,567），
///   该表不可用时退回参考常量；
/// - 收入分布：对数正态近似，其中 σ 优先由真实基尼系数反推校准，
///   使展示占比与展示的基尼系数自洽；均/中位数比值仅作兜底。
class SocioEconomicRepository {
  final SupabaseClientManager _supabase = SupabaseClientManager();
  final LocalCacheService _cache = LocalCacheService();
  final DistrictResolver _resolver = DistrictResolver();

  // 兜底参考门槛（仅当 hies_malaysia_percentile 不可用时使用）。
  static const double _fallbackB40Ceiling = 4850.0;
  static const double _fallbackT20Floor = 10959.0;

  /// 查询某位置的收入数据。位置可为行政县名（districtHint）或坐标。
  Future<Map<String, dynamic>> getSocioEconomicData({
    required String districtHint,
    double? lat,
    double? lng,
  }) async {
    final cacheKey =
        '${districtHint}_${lat?.toStringAsFixed(3) ?? 'na'}_${lng?.toStringAsFixed(3) ?? 'na'}';
    final cached = await _cache.getCachedData(
      'socio_economic_v3',
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
        resolved?['district'] ??
        (districtHint.isNotEmpty ? districtHint : null);
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
    final incomeYear = latest['date']?.toString() ?? '';
    final stateName = latest['state']?.toString() ?? '';
    final median = ((latest['income_median'] as num?) ?? 0).toDouble();
    final mean = ((latest['income_mean'] as num?) ?? 0).toDouble();
    final prevMedian = previous != null
        ? ((previous['income_median'] as num?) ?? 0).toDouble()
        : 0.0;

    // 2) 全国排名：按“各县最新年份”的 income_median 排序（等效最新横截面）。
    final allRows = await _supabase
        .from('hh_income_district')
        .select('district, income_median');
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

    // 3) 并行拉取：县级基尼 / 州级 HIES / 全国基尼与收入 / 官方阶层门槛。
    // 真实附表查询失败时降级（空结果），不阻断主流程。
    final giniDistrictRows = await _safeRows(
      () => _supabase
          .from('hh_inequality_district')
          .select('state, district, date, gini')
          .eq('district', districtName)
          .order('date', ascending: false),
    );

    final stateHies = await _safeRows(
      () => _supabase
          .from('hies_state')
          .select('date, income_mean, income_median, gini, poverty')
          .eq('state', stateName)
          .order('date', ascending: false),
    );

    final nationalGiniRows = await _safeRows(
      () => _supabase
          .from('hh_inequality')
          .select('date, gini')
          .order('date', ascending: false),
    );

    final nationalIncomeRows = await _safeRows(
      () => _supabase
          .from('hh_income')
          .select('date, income_mean, income_median')
          .order('date', ascending: false),
    );

    final percentileRows = await _safeRows(
      () => _supabase
          .from('hies_malaysia_percentile')
          .select('date, percentile, variable, income')
          .eq('variable', 'median')
          .inFilter('percentile', [40, 80])
          .order('date', ascending: false),
    );

    // ---- 基尼系数：县 → 州 → 全国（尽量与收入年份一致）----
    Map<String, dynamic>? districtGiniRow;
    for (final row in giniDistrictRows) {
      final date = row['date']?.toString() ?? '';
      if (date == incomeYear || districtGiniRow == null) {
        districtGiniRow = (row as Map).cast<String, dynamic>();
        if (date == incomeYear) break;
      }
    }
    final Map<String, dynamic>? stateHiesRow = stateHies.isNotEmpty
        ? (stateHies.first as Map).cast<String, dynamic>()
        : null;
    final Map<String, dynamic>? nationalGiniRow = nationalGiniRows.isNotEmpty
        ? (nationalGiniRows.first as Map).cast<String, dynamic>()
        : null;
    final Map<String, dynamic>? nationalIncomeRow =
        nationalIncomeRows.isNotEmpty
        ? (nationalIncomeRows.first as Map).cast<String, dynamic>()
        : null;

    final double? giniDistrict = (districtGiniRow?['gini'] as num?)?.toDouble();
    final double? giniState = (stateHiesRow?['gini'] as num?)?.toDouble();
    final double? giniNational = (nationalGiniRow?['gini'] as num?)?.toDouble();
    final double? giniReal = giniDistrict ?? giniState ?? giniNational;
    final String giniSource = giniDistrict != null
        ? 'district'
        : (giniState != null
              ? 'state'
              : (giniNational != null ? 'national' : 'estimated'));

    // ---- 官方 B40/T20 门槛（全国第 40 / 80 百分位收入）----
    double? p40, p80;
    for (final row in percentileRows) {
      final p = (row['percentile'] as num?)?.toInt();
      final v = (row['income'] as num?)?.toDouble();
      if (p == 40 && v != null) p40 = v;
      if (p == 80 && v != null) p80 = v;
    }
    final b40Ceiling = p40 ?? _fallbackB40Ceiling;
    final t20Floor = p80 ?? _fallbackT20Floor;

    // ---- 分布参数：σ 优先由真实基尼校准，否则用均/中位数比值拟合 ----
    final sigmaFit = _fitSigma(mean, median);
    double? sigma;
    if (giniReal != null && giniReal > 0 && giniReal < 1) {
      sigma = _sigmaFromGini(giniReal);
    } else {
      sigma = sigmaFit;
    }
    final lnMedian = median > 0 ? math.log(median) : 0.0;

    final pB40 = sigma == null
        ? null
        : _lognormalCdf(b40Ceiling, lnMedian, sigma);
    final pT20 = sigma == null
        ? null
        : 1 - _lognormalCdf(t20Floor, lnMedian, sigma);
    final pM40 = (pB40 != null && pT20 != null)
        ? (1 - pB40 - pT20).clamp(0.0, 1.0).toDouble()
        : null;

    final data = <String, dynamic>{
      'district': districtName,
      'state': stateName,
      'year': incomeYear,
      'median_income': median,
      'mean_income': mean,
      'income_growth_pct': (previous != null && prevMedian > 0)
          ? (median - prevMedian) / prevMedian * 100
          : null,
      'rank': rank,
      'total_districts': total,
      'ln_median': lnMedian,
      'sigma': sigma,
      // 真实基尼优先，字段说明数值是否官方直读。
      'gini_index': giniReal ?? (sigma == null ? null : _giniFromSigma(sigma)),
      'gini_source': giniSource,
      'gini_is_estimated': giniReal == null,
      'b40_ceiling': b40Ceiling,
      't20_floor': t20Floor,
      // 州级背景（hies_state）
      'state_median_income': (stateHiesRow?['income_median'] as num?)
          ?.toDouble(),
      'state_poverty_rate': (stateHiesRow?['poverty'] as num?)?.toDouble(),
      // 全国背景（hh_income / hh_inequality）
      'national_median_income': (nationalIncomeRow?['income_median'] as num?)
          ?.toDouble(),
      'national_mean_income': (nationalIncomeRow?['income_mean'] as num?)
          ?.toDouble(),
      'national_gini': giniNational,
      'class_share_b40': pB40,
      'class_share_m40': pM40,
      'class_share_t20': pT20,
    };

    try {
      await _cache.cacheData('socio_economic_v3', cacheKey, data);
    } catch (e) {
      debugPrint('SocioEconomicRepository cache write failed: $e');
    }
    return data;
  }

  /// 真实附表查询守卫：失败只返回空列表（调用方降级），避免整页报错。
  Future<List<Map<String, dynamic>>> _safeRows(
    Future<List<Map<String, dynamic>>> Function() query,
  ) async {
    try {
      return await query();
    } catch (e) {
      debugPrint('SocioEconomicRepository real-table query failed: $e');
      return [];
    }
  }

  /// 由均值/中位数反推对数正态 σ（无真实基尼时的兜底）。
  double? _fitSigma(double mean, double median) {
    if (mean <= 0 || median <= 0 || mean < median) return null;
    final v = 2 * math.log(mean / median);
    if (v < 0) return null;
    return math.sqrt(v);
  }

  /// 某收入在该县收入分布中的百分位（0-100）。
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

  /// 由真实基尼系数校准对数正态 σ：gini = 2Φ(σ/√2) − 1。
  double _sigmaFromGini(double gini) =>
      math.sqrt(2) * _invNormalCdf((1 + gini) / 2);

  double _giniFromSigma(double sigma) =>
      2 * _normalCdf(sigma / math.sqrt(2)) - 1;

  double _invNormalCdf(double p) => math.sqrt(2) * _erfInv(2 * p - 1);

  /// erfinv（Winitzki 近似，精度足够展示用途）。
  double _erfInv(double x) {
    const a = 0.147;
    final ln1mx2 = math.log(1 - x * x);
    final t1 = 2 / (math.pi * a) + ln1mx2 / 2;
    final t2 = ln1mx2 / a;
    final s = (x >= 0 ? 1.0 : -1.0) * math.sqrt(math.sqrt(t1 * t1 - t2) - t1);
    return s;
  }

  double _erf(double x) {
    final sign = x < 0 ? -1.0 : 1.0;
    final ax = x.abs();
    final t = 1.0 / (1.0 + 0.3275911 * ax);
    final y =
        1 -
        (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t -
                        0.284496736) *
                    t +
                0.254829592) *
            t *
            math.exp(-ax * ax);
    return sign * y;
  }
}
