import '../core/supabase/supabase_client_manager.dart';
import '../core/cache/local_cache_service.dart';

class SecurityRepository {
  final SupabaseClientManager _supabase = SupabaseClientManager();
  final LocalCacheService _cache = LocalCacheService();

  Future<Map<String, dynamic>> getSecurityData(double lat, double lng) async {
    final locationKey = '${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}';
    final cached = await _cache.getCachedData('security', locationKey, expiry: const Duration(days: 7));

    if (cached != null) return cached;

    // 1. 使用 PostGIS RPC 匹配警区
    final districtResult = await _supabase.rpc('match_police_district', params: {'lat': lat, 'lng': lng});
    
    if (districtResult == null || (districtResult as List).isEmpty) {
      throw Exception('无法匹配当前位置的警区数据');
    }

    final districtName = districtResult[0]['name'];
    final stateName = districtResult[0]['state'];

    // 2. 获取真实犯罪统计数据 (对应 crime_stats 表中的 district 字段)
    final crimeStats = await _supabase.from('crime_stats').select().eq('district', districtName);

    // 3. 获取附近众包隐患 (crowdsourced_hazards 表)
    final hazards = await _supabase.from('crowdsourced_hazards').select().eq('district', districtName);
    
    // 根据犯罪统计计算安全分数
    int totalCrimes = 0;
    for (var crime in crimeStats) {
      totalCrimes += (crime['crimes'] as int);
    }
    
    // 这里使用一个基于犯罪总数的启发式评分逻辑
    double baseScore = 10.0;
    double safetyScore = (baseScore - (totalCrimes / 500.0)).clamp(0.0, 10.0);

    final data = {
      'district_name': districtName,
      'state': stateName,
      'security_score': safetyScore,
      'crime_stats': crimeStats,
      'hazards': hazards,
      'location_key': locationKey,
    };

    await _cache.cacheData('security', locationKey, data);
    return data;
  }
}
