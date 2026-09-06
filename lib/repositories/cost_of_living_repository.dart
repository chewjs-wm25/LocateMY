import 'package:flutter/foundation.dart';
import '../core/supabase/supabase_client_manager.dart';
import '../core/supabase/district_resolver.dart';
import '../core/cache/local_cache_service.dart';

/// 生活开销对比数据仓库。
///
/// 真实数据源：
/// - `cpi_state`：州级消费物价指数（CPI，division='overall'，取最新月份）
/// - `get_district_prices` RPC：PriceCatcher 县域均价（已部署于 Supabase）
///
/// 对比按“州”执行（CPI 只有州级口径）：起点/终点传入的可以是行政县
/// （例如 'Petaling'、'Johor Bahru'），由 [DistrictResolver] 先归一到州。
class CostOfLivingRepository {
  final SupabaseClientManager _supabase = SupabaseClientManager();
  final LocalCacheService _cache = LocalCacheService();
  final DistrictResolver _resolver = DistrictResolver();

  /// [baseBudget]：用户当前月度预算（来自云端情景预案 user_budget_scenarios），
  /// 用于计算“在新地点维持同生活方式的等效预算”。null 时不做金额换算。
  Future<Map<String, dynamic>> getComparisonData(
    String originDistrict,
    String targetDistrict, {
    double? baseBudget,
  }) async {
    final cacheKey = '${originDistrict}_to_$targetDistrict';
    final cached = await _cache.getCachedData('cost_of_living_v3', cacheKey,
        expiry: const Duration(days: 3));
    if (cached != null) {
      final m = (cached as Map).cast<String, dynamic>();
      if (baseBudget == null || m.containsKey('base_budget')) {
        return m;
      }
      // 缓存里只有旧的无金额版本时重算等效预算。
      m['base_budget'] = baseBudget;
      final targetIdx = (m['target_cpi'] as num?)?.toDouble();
      final originIdx = (m['origin_cpi'] as num?)?.toDouble();
      if (targetIdx != null && originIdx != null && originIdx > 0) {
        m['equivalent_budget'] = baseBudget * targetIdx / originIdx;
      }
      return m;
    }

    // 起点/终点名称可能是县名也可能是州名；先归一，拿到州名再查 CPI。
    final originResolved = await _resolver.resolve(name: originDistrict, latLng: null);
    final targetResolved = await _resolver.resolve(name: targetDistrict, latLng: null);

    final originState = originResolved?['state'] ?? originDistrict;
    final targetState = targetResolved?['state'] ?? targetDistrict;
    final originDistrictName = originResolved?['district'] ?? originDistrict;
    final targetDistrictName = targetResolved?['district'] ?? targetDistrict;

    // 州级 CPI：division='overall'，每个州取最新月份。
    final originIdx = await _latestStateCpi(originState);
    final targetIdx = await _latestStateCpi(targetState);

    if (originIdx == null || targetIdx == null) {
      throw Exception('CPI 数据缺失，无法计算生活开销对比');
    }
    final ratio = targetIdx / originIdx; // >1 → 目标州更贵
    final equivalentBudget =
        (baseBudget != null && baseBudget > 0) ? baseBudget * ratio : null;
    final isImprovement = ratio < 1.0; // 目标更便宜 → 同样预算买到更多
    final budgetDiffPct = ((ratio - 1.0).abs()) * 100;

    // 微观物价（PriceCatcher，按目标县 / 源县真实均价）。
    final originPrices = await _districtPrices(originDistrictName);
    final targetPrices = await _districtPrices(targetDistrictName);

    final data = <String, dynamic>{
      'origin_cpi': originIdx,
      'target_cpi': targetIdx,
      'origin_state': originState,
      'target_state': targetState,
      'purchasing_power_change': (1 / ratio - 1) * 100, // 正数 = 购买力提升
      'budget_diff_pct': budgetDiffPct,
      'is_improvement': isImprovement,
      'base_budget': baseBudget,
      'equivalent_budget': equivalentBudget,
      'origin_district': originDistrictName,
      'target_district': targetDistrictName,
      'origin_prices': originPrices,
      'micro_prices': targetPrices,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await _cache.cacheData('cost_of_living_v3', cacheKey, data);
    } catch (e) {
      debugPrint('CostOfLivingRepository cache write failed: $e');
    }
    return data;
  }

  Future<double?> _latestStateCpi(String state) async {
    try {
      final rows = await _supabase
          .from('cpi_state')
          .select('index')
          .eq('state', state)
          .eq('division', 'overall')
          .order('date', ascending: false)
          .limit(1);
      if (rows.isEmpty) return null;
      return ((rows.first['index'] as num?) ?? 0).toDouble();
    } catch (e) {
      debugPrint('Cost CPI query error: $e');
      return null;
    }
  }

  Future<List<dynamic>> _districtPrices(String district) async {
    try {
      final res =
          await _supabase.rpc('get_district_prices', params: {'district_name': district});
      if (res is List) return res;
      return [];
    } catch (e) {
      debugPrint('Cost price query error: $e');
      return [];
    }
  }
}
