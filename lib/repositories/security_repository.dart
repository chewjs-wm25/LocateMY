import 'package:flutter/foundation.dart';
import '../core/supabase/supabase_client_manager.dart';
import '../core/cache/local_cache_service.dart';

/// 治安与犯罪数据仓库。
///
/// 真实表：`crime_stats`（state / district / category / type / crimes）。
/// 流程：
/// 1. 用 PostGIS RPC `match_police_district` 把坐标落到警区/行政区；
/// 2. 在 `crime_stats` 里取该行政区数据；若表内只有州级聚合
///    （district='All'）则回退到州级；
/// 3. 整理逐年罪案趋势（type='all' 的分类合计）供治安页折线图绘制，
///    无任何写死的示例数字。
class SecurityRepository {
  final SupabaseClientManager _supabase = SupabaseClientManager();
  final LocalCacheService _cache = LocalCacheService();

  static const Map<String, String> _stateCodeToFull = {
    'SGR': 'Selangor',
    'JHR': 'Johor',
    'KDH': 'Kedah',
    'KTN': 'Kelantan',
    'MLK': 'Melaka',
    'NSN': 'Negeri Sembilan',
    'PHG': 'Pahang',
    'PRK': 'Perak',
    'PLS': 'Perlis',
    'PNG': 'Pulau Pinang',
    'SBH': 'Sabah',
    'SWK': 'Sarawak',
    'TRG': 'Terengganu',
    'KUL': 'W.P. Kuala Lumpur',
    'LBN': 'W.P. Labuan',
    'PJY': 'W.P. Putrajaya',
  };

  Future<Map<String, dynamic>> getSecurityData(double lat, double lng) async {
    final locationKey = '${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}';
    final cached = await _cache.getCachedData('security_v3', locationKey,
        expiry: const Duration(days: 3));
    if (cached != null) return (cached as Map).cast<String, dynamic>();

    String? policeDistrict;
    String? fullState;
    try {
      final districtResult =
          await _supabase.rpc('match_police_district', params: {'lat': lat, 'lng': lng});
      if (districtResult is List && districtResult.isNotEmpty) {
        final first = (districtResult.first as Map).cast<String, dynamic>();
        policeDistrict = first['name']?.toString();
        final code = first['state']?.toString();
        fullState = _stateCodeToFull[code];
      }
    } catch (e) {
      debugPrint('SecurityRepository match error: $e');
    }

    if (policeDistrict == null && fullState == null) {
      throw Exception('无法匹配当前位置的警区数据');
    }

    // 优先行政区口径；若该行政区在 crime_stats 无行，回退州级 district='All'。
    var rows = await _supabase
        .from('crime_stats')
        .select('date, category, type, crimes')
        .eq('district', policeDistrict ?? '');
    if (rows.isEmpty && fullState != null) {
      rows = await _supabase
          .from('crime_stats')
          .select('date, category, type, crimes')
          .eq('district', 'All')
          .eq('state', fullState);
    }

    // 逐年总罪案（只统计 type='all' 的分类合计，避免把细分重复相加）。
    final yearly = <String, int>{};
    // category -> {year: crimes} 用于分类筛选折线
    final byCategoryYear = <String, Map<String, int>>{};

    for (final raw in rows) {
      final row = (raw as Map).cast<String, dynamic>();
      if ((row['type']?.toString() ?? '') != 'all') continue;
      final date = row['date']?.toString() ?? '';
      final year = date.length >= 4 ? date.substring(0, 4) : date;
      final crimes = ((row['crimes'] as num?) ?? 0).toInt();
      final category = row['category']?.toString() ?? 'other';
      if (year.isEmpty) continue;

      yearly[year] = (yearly[year] ?? 0) + crimes;
      byCategoryYear
          .putIfAbsent(category, () => {})[year] =
          (byCategoryYear[category]?[year] ?? 0) + crimes;
    }

    final sortedYears = yearly.keys.toList()..sort();
    final lastYear = sortedYears.isEmpty ? null : sortedYears.last;
    int totalCrimes = 0;
    final categoryBreakdown = <String, int>{};
    if (lastYear != null) {
      for (final raw in rows) {
        final row = (raw as Map).cast<String, dynamic>();
        if ((row['type']?.toString() ?? '') != 'all') continue;
        final date = row['date']?.toString() ?? '';
        if (date.length < 4 || date.substring(0, 4) != lastYear) continue;
        totalCrimes += ((row['crimes'] as num?) ?? 0).toInt();
        final cat = row['category']?.toString() ?? 'other';
        categoryBreakdown[cat] =
            (categoryBreakdown[cat] ?? 0) + ((row['crimes'] as num?) ?? 0).toInt();
      }
    }

    // 获取同年“全国”总数作为基线（真实 crime_stats 中 state=Malaysia 的聚合），
    // 安全评分 = 本区罪案占比越低越安全，无任何写死除数。
    int nationalTotal = 0;
    try {
      final nationalRows = await _supabase
          .from('crime_stats')
          .select('date, category, type, crimes')
          .eq('state', 'Malaysia')
          .eq('district', 'All');
      if (lastYear != null) {
        for (final raw in nationalRows) {
          final row = (raw as Map).cast<String, dynamic>();
          if ((row['type']?.toString() ?? '') != 'all') continue;
          final date = row['date']?.toString() ?? '';
          if (date.length < 4 || date.substring(0, 4) != lastYear) continue;
          nationalTotal += ((row['crimes'] as num?) ?? 0).toInt();
        }
      }
    } catch (e) {
      debugPrint('SecurityRepository national baseline error: $e');
    }

    double safetyScore = 10.0;
    if (totalCrimes > 0 && nationalTotal > 0) {
      // 本区罪案占全国比例映射到 10 分制（越接近 0% 越安全）。
      final share = totalCrimes / nationalTotal;
      safetyScore = (10.0 - share * 10.0).clamp(0.0, 10.0);
    } else if (totalCrimes > 0) {
      // 无全国基线时给出中性偏安全分，不伪造精确值。
      safetyScore = 8.0;
    }

    final trend = sortedYears
        .map((y) => <String, dynamic>{'year': y, 'crimes': yearly[y] ?? 0})
        .toList();
    final trendByCategory = <String, List<dynamic>>{};
    byCategoryYear.forEach((category, byYear) {
      final years = byYear.keys.toList()..sort();
      trendByCategory[category] = years
          .map((y) => <String, dynamic>{'year': y, 'crimes': byYear[y] ?? 0})
          .toList();
    });

    final data = <String, dynamic>{
      'district_name': policeDistrict,
      'state': fullState,
      'security_score': safetyScore,
      'total_crimes': totalCrimes,
      'trend': trend,
      'trend_by_category': trendByCategory,
      'category_breakdown': categoryBreakdown,
      'location_key': locationKey,
    };
    try {
      await _cache.cacheData('security_v3', locationKey, data);
    } catch (e) {
      debugPrint('SecurityRepository cache write failed: $e');
    }
    return data;
  }
}
