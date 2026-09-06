import '../core/supabase/supabase_client_manager.dart';
import '../core/cache/local_cache_service.dart';

class SocioEconomicRepository {
  final SupabaseClientManager _supabase = SupabaseClientManager();
  final LocalCacheService _cache = LocalCacheService();

  Future<Map<String, dynamic>> getSocioEconomicData(String district) async {
    final cached = await _cache.getCachedData('socio_economic', district, expiry: const Duration(days: 7));
    if (cached != null) return cached;

    // 对接到真实表: hh_income_district
    final statsList = await _supabase.from('hh_income_district').select().eq('district', district);
    
    if (statsList.isEmpty) {
      throw Exception('未找到该地区的社会经济数据');
    }
    
    final stats = statsList.first;

    // 使用 RPC 计算排名，以确保是基于全表数据的真实排名
    final rankInfo = await _supabase.rpc('get_district_income_rank', params: {'district_name': district});

    final data = {
      'median_income': stats['income_median'],
      'mean_income': stats['income_mean'],
      'gini_index': stats['gini'] ?? 0.0, // 假设表中可能有 gini
      'poverty_rate': stats['poverty_rate'] ?? 0.0,
      'rank': rankInfo?['rank'] ?? 0,
      'total_districts': rankInfo?['total'] ?? 160,
      'thresholds': {
        'B40': 4850.0, // 这里的阈值通常是国家级的，可以保留或从配置表加载
        'M40': 10960.0,
        'T20': 15040.0,
      },
      'district': district,
    };

    await _cache.cacheData('socio_economic', district, data);
    return data;
  }
}
