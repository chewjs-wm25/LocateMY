import '../core/supabase/supabase_client_manager.dart';
import '../core/cache/local_cache_service.dart';

class InfrastructureRepository {
  final SupabaseClientManager _supabase = SupabaseClientManager();
  final LocalCacheService _cache = LocalCacheService();

  Future<Map<String, dynamic>> getInfrastructureData(String district) async {
    final cached = await _cache.getCachedData('infrastructure', district, expiry: const Duration(days: 7));
    if (cached != null) return cached;

    // 1. 获取基本设施接入率 (hh_access_amenities 表)
    final amenities = await _supabase.from('hh_access_amenities').select().eq('district', district);
    final amenityData = amenities.isNotEmpty ? amenities.first : {'piped_water': 0.0, 'electricity': 0.0, 'sanitation': 0.0};
    
    // 2. 获取医疗床位统计 (hospital_beds 表)
    final bedsData = await _supabase.from('hospital_beds').select().eq('district', district);
    int totalBeds = 0;
    for (var item in bedsData) {
      totalBeds += (item['beds'] as int);
    }
    double healthScore = (totalBeds / 10.0).clamp(0.0, 100.0);

    // 3. 获取教育资源 (teachers_district 表)
    final teachersData = await _supabase.from('teachers_district').select().eq('district', district);
    int totalTeachers = 0;
    for (var item in teachersData) {
      totalTeachers += (int.tryParse(item['teachers'].toString()) ?? 0);
    }
    double eduScore = (totalTeachers / 50.0).clamp(0.0, 100.0);

    // 4. 获取交通密度 (通过 RPC 计算附近站点)
    final transitData = await _supabase.rpc('get_transit_density', params: {'district_name': district});
    double transitScore = (transitData as double? ?? 50.0);

    final data = {
      'ici_score': (amenityData['piped_water'] * 0.2) + 
                   (amenityData['electricity'] * 0.2) + 
                   (healthScore * 0.3) + 
                   (eduScore * 0.3),
      'scores': {
        'water': amenityData['piped_water'],
        'power': amenityData['electricity'],
        'healthcare': healthScore,
        'education': eduScore,
        'transit': transitScore,
      },
      'amenities': amenityData,
      'district': district,
    };

    await _cache.cacheData('infrastructure', district, data);
    return data;
  }
}
