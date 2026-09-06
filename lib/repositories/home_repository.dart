import 'package:flutter/foundation.dart';
import '../core/supabase/supabase_client_manager.dart';
import '../core/cache/local_cache_service.dart';
import '../models/home_stats.dart';

class HomeRepository {
  final SupabaseClientManager _supabase = SupabaseClientManager();
  final LocalCacheService _cache = LocalCacheService();

  static const String _cacheKey = 'home_macro_stats_v2';
  static const String _cacheType = 'macro_data';

  Future<HomeStats> getHomeStats({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _cache.getCachedData(_cacheType, _cacheKey, expiry: const Duration(hours: 24));
      if (cached != null) {
        return HomeStats.fromJson(cached);
      }
    }

    // 1. 获取收入数据与增长率 (hh_income_district)
    final incomeResult = await _getIncomeStats();
    
    // 2. 获取通胀率 (cpi_state)
    final inflationResult = await _getInflationRate();
    
    // 3. 获取基础设施评分 (ICI) - 全国平均
    final iciScore = await _getNationalAverageICI();

    // 4. 获取治安趋势 (crime_stats)
    final crimeTrend = await _getNationalCrimeTrend();

    // 5. 尝试获取 GDP 数据 (可能缺失，不设兜底)
    final gdpStats = await _getGDPStats();

    // 6. 尝试获取失业率 (可能缺失，不设兜底)
    final unemploymentStats = await _getUnemploymentStats();

    // 计算搬迁时机指数 (Relocation Index)
    // 逻辑：放宽依赖，如果 ICI 缺失则使用基准值 85.0 (马来西亚平均水平)
    double? relocationIndex;
    if (incomeResult['trend'] != null && inflationResult != null) {
      double score = 5.0;
      score += (incomeResult['trend'] as double) * 0.2;
      score -= (inflationResult as double) * 0.2;
      
      double effectiveICI = iciScore ?? 85.0;
      score += (effectiveICI / 20.0);

      if (crimeTrend != null) {
        score -= (crimeTrend * 0.1);
      }
      relocationIndex = double.parse(score.clamp(0.0, 10.0).toStringAsFixed(1));
    }

    final stats = HomeStats(
      medianIncome: incomeResult['median'],
      incomeTrend: incomeResult['trend'],
      inflationRate: inflationResult,
      gdpGrowth: gdpStats['growth'],
      gdpTrend: gdpStats['trend'],
      unemploymentRate: unemploymentStats['rate'],
      unemploymentTrend: unemploymentStats['trend'],
      relocationIndex: relocationIndex,
      isIciFallback: iciScore == null,
      oprRate: 3.00, // 固定或从配置表取
      lastUpdated: DateTime.now(),
    );

    await _cache.cacheData(_cacheType, _cacheKey, stats.toJson());
    return stats;
  }

  Future<Map<String, dynamic>> _getIncomeStats() async {
    try {
      final latestDateResp = await _supabase.from('hh_income_district').select('date').order('date', ascending: false).limit(1);
      if (latestDateResp.isEmpty) {
        debugPrint('HomeRepository: No income data found in hh_income_district');
        return {'median': null, 'trend': null};
      }
      
      final latestDate = latestDateResp.first['date'];
      final latestData = await _supabase.from('hh_income_district').select('income_median').eq('date', latestDate);
      if (latestData.isEmpty) return {'median': null, 'trend': null};
      
      final latestAvg = latestData.fold<num>(0, (p, e) => p + (e['income_median'] as num)) / latestData.length;

      final prevDateResp = await _supabase.from('hh_income_district').select('date').lt('date', latestDate).order('date', ascending: false).limit(1);
      if (prevDateResp.isEmpty) return {'median': latestAvg.toInt(), 'trend': null};

      final prevDate = prevDateResp.first['date'];
      final prevData = await _supabase.from('hh_income_district').select('income_median').eq('date', prevDate);
      if (prevData.isEmpty) return {'median': latestAvg.toInt(), 'trend': null};

      final prevAvg = prevData.fold<num>(0, (p, e) => p + (e['income_median'] as num)) / prevData.length;
      final trend = ((latestAvg / prevAvg) - 1) * 100;
      
      return {'median': latestAvg.toInt(), 'trend': trend};
    } catch (e) {
      debugPrint('HomeRepository Error (_getIncomeStats): $e');
      return {'median': null, 'trend': null};
    }
  }

  Future<double?> _getInflationRate() async {
    try {
      final latestDateResp = await _supabase.from('cpi_state').select('date').order('date', ascending: false).limit(1);
      if (latestDateResp.isEmpty) {
        debugPrint('HomeRepository: No CPI data found in cpi_state');
        return null;
      }

      final latestDate = latestDateResp.first['date'];
      
      // 根据日志，division 使用的是数字代码 (01, 02...)
      // 优先匹配可能代表综合指标的 '00'，如果不存在则自动回退到第一个可用分类
      var latestData = await _supabase.from('cpi_state')
          .select('index')
          .eq('date', latestDate)
          .ilike('division', '00%');
          
      if (latestData == null || (latestData as List).isEmpty) {
        latestData = await _supabase.from('cpi_state')
            .select('index')
            .eq('date', latestDate)
            .limit(1);
      }
          
      if (latestData == null || (latestData as List).isEmpty) return null;
      final latestList = latestData as List;
      final latestAvg = latestList.fold<num>(0, (p, e) => p + (e['index'] as num)) / latestList.length;

      final oneYearAgo = DateTime.parse(latestDate).subtract(const Duration(days: 365));
      final formattedOneYearAgo = "${oneYearAgo.year}-${oneYearAgo.month.toString().padLeft(2, '0')}-01";
      
      var prevData = await _supabase.from('cpi_state')
          .select('index')
          .lte('date', formattedOneYearAgo)
          .ilike('division', '00%')
          .order('date', ascending: false)
          .limit(16);

      if (prevData == null || (prevData as List).isEmpty) {
        debugPrint('HomeRepository: No historical CPI data found, attempting to get any previous data');
        prevData = await _supabase.from('cpi_state')
            .select('index')
            .lt('date', latestDate)
            .order('date', ascending: false)
            .limit(16);
      }

      if (prevData == null || (prevData as List).isEmpty) {
        debugPrint('HomeRepository: No historical CPI data found to calculate inflation');
        return null;
      }
      final prevList = prevData as List;
      final prevAvg = prevList.fold<num>(0, (p, e) => p + (e['index'] as num)) / prevList.length;
      return ((latestAvg / prevAvg) - 1) * 100;
    } catch (e) {
      debugPrint('HomeRepository Error (_getInflationRate): $e');
      return null;
    }
  }

  Future<double?> _getNationalAverageICI() async {
    try {
      final data = await _supabase.from('hh_access_amenities').select('piped_water, electricity, sanitation').order('date', ascending: false).limit(16);
      if (data.isEmpty) {
        debugPrint('HomeRepository: No amenities data found in hh_access_amenities');
        return null;
      }

      double total = 0;
      for (var row in data) {
        total += (row['piped_water'] as num).toDouble();
        total += (row['electricity'] as num).toDouble();
        total += (row['sanitation'] as num).toDouble();
      }
      return total / (data.length * 3);
    } catch (e) {
      debugPrint('HomeRepository Error (_getNationalAverageICI): $e');
      return null;
    }
  }

  Future<double?> _getNationalCrimeTrend() async {
    try {
      final latestDateResp = await _supabase.from('crime_stats').select('date').order('date', ascending: false).limit(1);
      if (latestDateResp.isEmpty) {
        debugPrint('HomeRepository: No crime data found in crime_stats');
        return null;
      }
      final latestDate = latestDateResp.first['date'];

      final latestCount = await _supabase.from('crime_stats').select('crimes').eq('date', latestDate);
      final latestTotal = latestCount.fold<num>(0, (p, e) => p + (e['crimes'] as num));

      final prevDateResp = await _supabase.from('crime_stats').select('date').lt('date', latestDate).order('date', ascending: false).limit(1);
      if (prevDateResp.isEmpty) return null;
      final prevDate = prevDateResp.first['date'];

      final prevCount = await _supabase.from('crime_stats').select('crimes').eq('date', prevDate);
      final prevTotal = prevCount.fold<num>(0, (p, e) => p + (e['crimes'] as num));

      return prevTotal == 0 ? 0 : ((latestTotal / prevTotal) - 1) * 100;
    } catch (e) {
      debugPrint('HomeRepository Error (_getNationalCrimeTrend): $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _getGDPStats() async {
    try {
      // 使用 gdp_gni_annual_real 表，筛选年增长率 (growth_yoy)
      final data = await _supabase
          .from('gdp_gni_annual_real')
          .select('date, gdp')
          .eq('series', 'growth_yoy')
          .order('date', ascending: true);
          
      if (data == null || (data as List).isEmpty) {
        debugPrint('HomeRepository: No GDP data found in gdp_gni_annual_real');
        return {'growth': null, 'trend': null};
      }
      
      final list = data as List;
      final trend = list.map<GDPDataPoint>((e) {
        final date = DateTime.parse(e['date']);
        return GDPDataPoint(
          year: date.year.toString(),
          value: (e['gdp'] as num).toDouble(),
        );
      }).toList();
      
      return {'growth': trend.last.value, 'trend': trend};
    } catch (e) {
      debugPrint('HomeRepository Error (_getGDPStats): $e');
      return {'growth': null, 'trend': null};
    }
  }

  Future<Map<String, dynamic>> _getUnemploymentStats() async {
    try {
      // 使用 lfs_month 表，获取 u_rate (失业率)
      final data = await _supabase
          .from('lfs_month')
          .select('u_rate, date')
          .order('date', ascending: false);
          
      if (data == null || (data as List).isEmpty) {
        debugPrint('HomeRepository: No unemployment data found in lfs_month');
        return {'rate': null, 'trend': null};
      }
      
      final list = data as List;
      final latest = (list.first['u_rate'] as num).toDouble();
      double? trend;
      if (list.length > 1) {
        trend = latest - (list[1]['u_rate'] as num).toDouble();
      }
      return {'rate': latest, 'trend': trend};
    } catch (e) {
      debugPrint('HomeRepository Error (_getUnemploymentStats): $e');
      return {'rate': null, 'trend': null};
    }
  }
}
