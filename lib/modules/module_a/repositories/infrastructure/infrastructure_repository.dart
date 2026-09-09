import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:locate_my/core/supabase/supabase_client_manager.dart';
import 'package:locate_my/core/supabase/district_resolver.dart';
import 'package:locate_my/core/cache/local_cache_service.dart';
import 'package:locate_my/core/district_matcher.dart';
import 'package:locate_my/core/ici_score.dart';
import 'package:locate_my/core/normalized_score.dart';
import 'package:locate_my/modules/module_a/repositories/transport/transit_repository.dart';

/// 综合基础设施普及率 (ICI) 数据仓库。
///
/// 数据源（全部为真实 Supabase 表）：
/// - `hh_access_amenities`：piped_water / sanitation / electricity（0-100%）
/// - `hospital_beds`：各县公立床位（type='all'，取最新年份）
/// - `district_population`：县常住人口（人，见 scripts/seed_district_population.sql）
/// - `teachers_district` / `enrolment_school_district`：师生比
/// - `transit_stops`：周边站点密度
///
/// 归一化说明：
/// - 医疗 = 每千人口床位（beds / population × 1000），在全国同年横截面上 min-max
///   归一；`district_population` 表缺失或目标县无人口时回退为绝对床位数口径。
/// - 教育 = 师生比，在全国“与目标县同一报告年”的横截面上 min-max 归一。
/// 数据缺失的子项返回 null，由视图显示空态并提示“数据不完整”。
class InfrastructureRepository {
  final SupabaseClientManager _supabase = SupabaseClientManager();
  final LocalCacheService _cache = LocalCacheService();
  final DistrictResolver _resolver = DistrictResolver();
  final TransitRepository _transit = TransitRepository();

  Future<Map<String, dynamic>> getInfrastructureData({
    required String districtHint,
    double? lat,
    double? lng,
  }) async {
    final cacheKey =
        '${districtHint}_${lat?.toStringAsFixed(3) ?? 'na'}_${lng?.toStringAsFixed(3) ?? 'na'}';
    final cached = await _cache.getCachedData(
      'infrastructure_v4',
      cacheKey,
      expiry: const Duration(days: 3),
    );
    if (cached != null) return (cached as Map).cast<String, dynamic>();

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
    final state = resolved?['state'];

    // ---- 1) 水 / 电 / 卫生覆盖率（行政区精确匹配，取最新年份）----
    // 上游表县名与解析器县名存在写法差异（S.P. Selatan 等），
    // 精确查询失败时降级为“全量拉取 + 宽松县名匹配”。
    double? water;
    double? power;
    try {
      final exact = await _supabase
          .from('hh_access_amenities')
          .select('state, district, date, piped_water, sanitation, electricity')
          .eq('district', districtName)
          .order('date', ascending: false)
          .limit(1);
      var rows = exact;
      if (exact.isEmpty) {
        rows = await _supabase
            .from('hh_access_amenities')
            .select(
              'state, district, date, piped_water, sanitation, electricity',
            )
            .order('date', ascending: false)
            .limit(1000);
      }
      final row = _latestAmenityFor(rows, districtName);
      if (row != null) {
        water = _toDouble(row['piped_water']);
        final elec = _toDouble(row['electricity']);
        final san = _toDouble(row['sanitation']);
        if (elec != null && san != null) {
          power = (elec + san) / 2;
        } else {
          power = elec ?? san;
        }
      }
    } catch (e) {
      debugPrint('Infra amenities error: $e');
    }

    // ---- 2) 医疗密度：医院床位（全国同年 min-max 归一）----
    final healthScore = await _districtBedsScore(districtName);

    // ---- 3) 教育资源：师生比（全国同年 min-max 归一）----
    final eduScore = await _educationScore(districtName);

    // ---- 4) 交通密度：以选中坐标为中心、2km 半径内站点密度 ----
    double? transitScore;
    if (lat != null && lng != null) {
      try {
        final stops = await _transit.fetchNearbyStops(
          lat: lat,
          lng: lng,
          radiusMeters: 2000,
          maxStops: 500,
        );
        if (stops.isNotEmpty) {
          // 同一密度口径也用于交通运输页：2km 内 60 个站点视为满分。
          transitScore = math.min(100, stops.length * (100 / 60)).toDouble();
        }
      } catch (e) {
        debugPrint('Infra transit error: $e');
      }
    }

    final scores = <String, dynamic>{
      'water': water,
      'power': power,
      'healthcare': healthScore,
      'education': eduScore,
      'transit': transitScore,
    };

    // ICI：公平口径（与 Provider 滑块重算完全一致）。
    //  - 源数据缺失的子项按 0 计入、权重保留在分母（缺数据 ≠ 满分）；
    //  - 未提供坐标时 transit 不可评估，该项权重与分数一并剔除。
    final transitApplicable = lat != null && lng != null;
    final ici = computeIciScore(
      scores,
      transitApplicable: transitApplicable,
      wWater: 0.2,
      wPower: 0.2,
      wHealth: 0.2,
      wEdu: 0.2,
      wTransit: 0.2,
    );

    final data = <String, dynamic>{
      'district': districtName,
      'state': state,
      'ici_score': ici,
      'scores': scores,
      // transit 是否可评估(取决于是否提供坐标);供视图/Provider 复算同一口径。
      'transit_applicable': lat != null && lng != null,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await _cache.cacheData('infrastructure_v4', cacheKey, data);
    } catch (e) {
      debugPrint('InfrastructureRepository cache write failed: $e');
    }
    return data;
  }

  /// 医疗密度评分：优先按“每千人口公立床位”在全国同年横截面上 min-max 归一；
  /// 若县人口表（district_population）不存在 / 目标县无人口，回退为绝对床位数口径。
  ///
  /// 医院口径县名常含括号后缀（如 'Petaling (Subang Jaya)'），由 DistrictMatcher 统一匹配。
  Future<double?> _districtBedsScore(String district) async {
    try {
      final rows = await _supabase
          .from('hospital_beds')
          .select('district, date, beds')
          .eq('type', 'all');
      if (rows.isEmpty) return null;

      final latestByDistrict = <String, double>{};
      final dateByDistrict = <String, String>{};
      for (final row in rows) {
        final d = row['district']?.toString() ?? '';
        if (d.isEmpty || d == 'All' || d.startsWith('All')) continue;
        final beds = _toDouble(row['beds']);
        final date = row['date']?.toString() ?? '';
        if (beds == null) continue;
        final prevDate = dateByDistrict[d];
        if (prevDate == null || date.compareTo(prevDate) >= 0) {
          latestByDistrict[d] = beds;
          dateByDistrict[d] = date;
        }
      }
      if (latestByDistrict.isEmpty) return null;

      // 1) 每千人口口径（人口表可读时优先）。
      final popRows = await _fetchDistrictPopulationRows();
      if (popRows != null) {
        final perCapita = _bedsPerCapitaScore(
          district,
          latestByDistrict,
          dateByDistrict,
          popRows,
        );
        if (perCapita != null) return perCapita;
      }

      // 2) 回退口径：绝对床位数 min-max（人口缺失时不劣化旧行为）。
      double? match;
      for (final e in latestByDistrict.entries) {
        if (DistrictMatcher.matches(district, e.key)) {
          match = math.max(match ?? 0, e.value);
        }
      }
      if (match == null) return null;
      return minMaxNormalized(match, latestByDistrict.values.toList());
    } catch (e) {
      debugPrint('Infra beds error: $e');
      return null;
    }
  }

  /// 拉取县人口行（district_population：date/state/district/population，单位：人）。
  /// 表不存在或查询失败返回 null（由调用方回退到绝对床位数口径）。
  Future<List<dynamic>?> _fetchDistrictPopulationRows() async {
    try {
      return await _supabase
          .from('district_population')
          .select('district, date, population');
    } catch (e) {
      debugPrint('Infra population unavailable, fallback to absolute beds: $e');
      return null;
    }
  }

  /// 每千人口床位口径：
  ///  - 每个县以其“床位数最新年份”对齐人口（优先取 ≤ 该年份的最近人口，否则取该县最新人口）；
  ///  - 全国池 = 所有能对齐的县 beds/pop*1000；
  ///  - 目标县人口缺失返回 null（上层走绝对口径回退）。
  double? _bedsPerCapitaScore(
    String district,
    Map<String, double> latestByDistrict,
    Map<String, String> dateByDistrict,
    List<dynamic> popRows,
  ) {
    // 人口行按县名分组（县名多种写法由 DistrictMatcher 处理）。
    final popByDistrict = <String, List<(String, double)>>{};
    for (final row in popRows) {
      final d = row['district']?.toString() ?? '';
      if (d.isEmpty || d == 'All' || d.startsWith('All')) continue;
      final p = _toDouble(row['population']);
      final dt = row['date']?.toString() ?? '';
      if (p == null || dt.isEmpty) continue;
      (popByDistrict[d] ??= []).add((dt, p));
    }
    if (popByDistrict.isEmpty) return null;

    final pool = <double>[];
    for (final e in latestByDistrict.entries) {
      final pop = _populationFor(
        popByDistrict,
        e.key,
        dateByDistrict[e.key] ?? '',
      );
      if (pop != null && pop > 0) pool.add(e.value / pop * 1000);
    }
    if (pool.isEmpty) return null;

    // 目标县：取匹配行的最大床位数及其年份。
    double? beds;
    String? bedDate;
    for (final e in latestByDistrict.entries) {
      if (DistrictMatcher.matches(district, e.key) &&
          (beds == null || e.value > beds)) {
        beds = e.value;
        bedDate = dateByDistrict[e.key];
      }
    }
    if (beds == null) return null;
    final pop = _populationFor(popByDistrict, district, bedDate ?? '');
    if (pop == null || pop <= 0) return null;
    return minMaxNormalized(beds / pop * 1000, pool);
  }

  /// 在按县名分组的人口行里，为 [district] 选一个对齐年份的人口值：
  /// 优先取日期 ≤ [latestDate]（床位年份）的最近年份；没有则取该县最新年份。
  double? _populationFor(
    Map<String, List<(String, double)>> popByDistrict,
    String district,
    String latestDate,
  ) {
    final candidates = <(String, double)>[];
    for (final e in popByDistrict.entries) {
      if (DistrictMatcher.matches(district, e.key)) {
        candidates.addAll(e.value);
      }
    }
    if (candidates.isEmpty) return null;

    double? bestPop;
    String? bestDate;
    // 优先 ≤ 床位年份的最近人口。
    for (final c in candidates) {
      if (latestDate.isNotEmpty && c.$1.compareTo(latestDate) > 0) continue;
      if (bestDate == null || c.$1.compareTo(bestDate) > 0) {
        bestDate = c.$1;
        bestPop = c.$2;
      }
    }
    if (bestPop != null) return bestPop;
    // 该县没有 ≤ 床位年份的人口 → 用其最新年份人口。
    for (final c in candidates) {
      if (bestDate == null || c.$1.compareTo(bestDate) > 0) {
        bestDate = c.$1;
        bestPop = c.$2;
      }
    }
    return bestPop;
  }

  /// 教师数 / 在校生数 比值，全国同年 min-max 归一。
  Future<double?> _educationScore(String district) async {
    try {
      final teachers = await _supabase
          .from('teachers_district')
          .select('district, date, teachers')
          .eq('sex', 'both');
      final students = await _supabase
          .from('enrolment_school_district')
          .select('district, date, students')
          .eq('sex', 'both');
      if (teachers.isEmpty || students.isEmpty) return null;

      // MOE 表县名可能与解析县名不同（拆分/合并/缩写），用宽松匹配聚合。
      final tRows = teachers.where(
        (e) =>
            DistrictMatcher.matches(district, e['district']?.toString() ?? ''),
      );
      final sRows = students.where(
        (e) =>
            DistrictMatcher.matches(district, e['district']?.toString() ?? ''),
      );

      double? districtRatio;
      String? ratioDate;
      {
        final tByDate = <String, double>{};
        for (final r in tRows) {
          final d = r['date']?.toString() ?? '';
          tByDate[d] = (tByDate[d] ?? 0) + (_toDouble(r['teachers']) ?? 0);
        }
        final sByDate = <String, double>{};
        for (final r in sRows) {
          final d = r['date']?.toString() ?? '';
          sByDate[d] = (sByDate[d] ?? 0) + (_toDouble(r['students']) ?? 0);
        }
        final dates = tByDate.keys.toSet()..retainAll(sByDate.keys.toSet());
        if (dates.isEmpty) return null;
        final latest = dates.reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
        ratioDate = latest;
        final s = sByDate[latest] ?? 0;
        if (s > 0) districtRatio = (tByDate[latest] ?? 0) / s;
      }
      if (districtRatio == null) return null;

      // 归一池只取与目标县“同一报告年”的横截面（全国同年 min-max），
      // 避免不同年份数据混入导致基准逐年漂移。
      final ratios = <double>[];
      final keys = <String>{};
      for (final r in teachers) {
        final d = r['district']?.toString() ?? '';
        final dt = r['date']?.toString() ?? '';
        if (d.isEmpty || d == 'All Districts' || d.startsWith('All')) continue;
        keys.add('$d|$dt');
      }
      for (final k in keys) {
        final parts = k.split('|');
        final d = parts[0];
        final dt = parts[1];
        if (dt != ratioDate) continue;
        double tt = 0;
        for (final r in teachers) {
          if ((r['district']?.toString() ?? '') == d &&
              (r['date']?.toString() ?? '') == dt) {
            tt += _toDouble(r['teachers']) ?? 0;
          }
        }
        double ss = 0;
        for (final r in students) {
          if ((r['district']?.toString() ?? '') == d &&
              (r['date']?.toString() ?? '') == dt) {
            ss += _toDouble(r['students']) ?? 0;
          }
        }
        if (tt > 0 && ss > 0) ratios.add(tt / ss);
      }
      if (ratios.isEmpty) return null;
      return minMaxNormalized(districtRatio, ratios);
    } catch (e) {
      debugPrint('Infra edu error: $e');
      return null;
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// 从(可能包含多种写法的)行集合中取目标县最新年份的一行。
  /// 精确县名查不到时的降级路径：按 [DistrictMatcher] 宽松匹配。
  Map<String, dynamic>? _latestAmenityFor(List<dynamic> rows, String district) {
    Map<String, dynamic>? best;
    String? bestDate;
    for (final raw in rows) {
      final row = (raw as Map).cast<String, dynamic>();
      final d = row['district']?.toString() ?? '';
      if (d.isEmpty || d == 'All' || d.startsWith('All')) continue;
      if (!DistrictMatcher.matches(district, d)) continue;
      final date = row['date']?.toString() ?? '';
      if (bestDate == null || date.compareTo(bestDate) >= 0) {
        best = row;
        bestDate = date;
      }
    }
    return best;
  }
}
