import '../core/supabase/supabase_client_manager.dart';
import '../core/cache/local_cache_service.dart';

class CostOfLivingRepository {
  final SupabaseClientManager _supabase = SupabaseClientManager();
  final LocalCacheService _cache = LocalCacheService();

  Future<Map<String, dynamic>> getComparisonData(String originDistrict, String targetDistrict) async {
    final cacheKey = '${originDistrict}_to_$targetDistrict';
    final cached = await _cache.getCachedData('cost_of_living', cacheKey, expiry: const Duration(days: 7));
    
    if (cached != null) return cached;

    // 对接到真实表: cpi_state (按 district/state 匹配)
    // 注意：真实表中字段名为 'state'，但此处根据业务需求可能需要按区匹配或状态匹配
    // 根据 real_supabase_tables.md，cpi_state 有 'state' 字段
    final cpiOrigin = await _supabase.from('cpi_state').select().eq('state', originDistrict);
    final cpiTarget = await _supabase.from('cpi_state').select().eq('state', targetDistrict);

    final originIdx = (cpiOrigin.firstOrNull?['index'] ?? 100.0) as double;
    final targetIdx = (cpiTarget.firstOrNull?['index'] ?? 100.0) as double;
    final change = ((targetIdx / originIdx) - 1) * 100;

    // 从 price_catcher 获取微观物价 (根据 premises 所在的 district)
    // 这是一个复杂的查询，通常需要连接 premise 表
    final prices = await _supabase.rpc('get_district_prices', params: {'district_name': targetDistrict});

    final data = {
      'purchasing_power_change': change.abs(),
      'is_improvement': change < 0,
      'equivalent_budget': 5000.0 * (targetIdx / originIdx),
      'base_budget': 5000.0,
      'categories': [
        {'name': 'Housing', 'origin': 1500.0, 'target': 1500.0 * (targetIdx / originIdx)},
        {'name': 'Food', 'origin': 1200.0, 'target': 1200.0 * (targetIdx / originIdx)},
        {'name': 'Transport', 'origin': 800.0, 'target': 800.0 * (targetIdx / originIdx)},
      ],
      'micro_prices': prices ?? [],
      'timestamp': DateTime.now().toIso8601String(),
      'origin_name': originDistrict,
      'target_name': targetDistrict,
    };

    await _cache.cacheData('cost_of_living', cacheKey, data);
    return data;
  }
}
