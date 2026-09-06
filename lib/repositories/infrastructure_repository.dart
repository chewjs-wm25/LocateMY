import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../core/supabase/supabase_client_manager.dart';
import '../core/supabase/district_resolver.dart';
import '../core/cache/local_cache_service.dart';
import 'transit_repository.dart';

/// 综合基础设施普及率 (ICI) 数据仓库。
///
/// 数据源（全部为真实 Supabase 表）：
/// - `hh_access_amenities`：piped_water / sanitation / electricity（0-100%）
/// - `hospital_beds`：各县公立床位（type='all'，取最新年份）
/// - `teachers_district` / `enrolment_school_district`：师生比
/// - `transit_stops`：周边站点密度
///
/// 归一化说明：医疗 / 教育子项在“全国同年横截面”上做 min-max 归一到 0-100，
/// 不写死评分常数；数据缺失的子项返回 null，由视图显示空态。
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
      'infrastructure_v2',
      cacheKey,
      expiry: const Duration(days: 3),
    );
    if (cached != null) return (cached as Map).cast<String, dynamic>();

    final resolved = await _resolver.resolve(
      name: districtHint.isEmpty ? null : districtHint,
      latLng: lat != null && lng != null ? LatLng(lat, lng) : null,
    );
    final districtName =
        resolved?['district'] ?? (districtHint.isNotEmpty ? districtHint : null);
    if (districtName == null) {
      throw Exception('无法确定该位置的行政区');
    }
    final state = resolved?['state'];

    // ---- 1) 水 / 电 / 卫生覆盖率（行政区精确匹配，取最新年份）----
    double? water;
    double? power;
    try {
      final amenities = await _supabase
          .from('hh_access_amenities')
          .select('state, district, date, piped_water, sanitation, electricity')
          .eq('district', districtName)
          .order('date', ascending: false)
          .limit(1);
      if (amenities.isNotEmpty) {
        final row = amenities.first;
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

    // ICI = 可用子项均值（默认等权；视图层滑块会按权重重算）。
    double? ici;
    final present = scores.values.whereType<double>().toList();
    if (present.isNotEmpty) {
      ici = present.reduce((a, b) => a + b) / present.length;
    }

    final data = <String, dynamic>{
      'district': districtName,
      'state': state,
      'ici_score': ici,
      'scores': scores,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await _cache.cacheData('infrastructure_v2', cacheKey, data);
    } catch (e) {
      debugPrint('InfrastructureRepository cache write failed: $e');
    }
    return data;
  }

  /// 全国（type='all'）每县最新年份床位数，min-max 归一；医院口径县名
  /// 常含括号后缀（如 'Petaling (Subang Jaya)'），故对目标县做前缀匹配。
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

      final normalized = district.toLowerCase();
      double? match;
      for (final e in latestByDistrict.entries) {
        if (e.key.toLowerCase().startsWith(normalized) ||
            e.key.toLowerCase().contains(normalized)) {
          match = math.max(match ?? 0, e.value);
        }
      }
      if (match == null) return null;

      final pool = latestByDistrict.values;
      final min = pool.reduce(math.min);
      final max = pool.reduce(math.max);
      if (max <= min) return 100.0;
      return ((match - min) / (max - min) * 100).clamp(0.0, 100.0);
    } catch (e) {
      debugPrint('Infra beds error: $e');
      return null;
    }
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

      final normalized = district.toLowerCase();
      final tRows = teachers.where((e) =>
          (e['district']?.toString() ?? '').toLowerCase().startsWith(normalized));
      final sRows = students.where((e) =>
          (e['district']?.toString() ?? '').toLowerCase().startsWith(normalized));

      double? districtRatio;
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
        final s = sByDate[latest] ?? 0;
        if (s > 0) districtRatio = (tByDate[latest] ?? 0) / s;
      }
      if (districtRatio == null) return null;

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
      final min = ratios.reduce(math.min);
      final max = ratios.reduce(math.max);
      if (max <= min) return 100.0;
      return ((districtRatio - min) / (max - min) * 100).clamp(0.0, 100.0);
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
}
