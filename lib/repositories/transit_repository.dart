import 'dart:math' as math;
import '../core/supabase/supabase_client_manager.dart';

/// 公共交通数据仓库：从真实表 `transit_stops` 读取站点，
/// 客户端用 Haversine 公式计算与用户坐标的距离并排序。
///
/// 真实表结构：stop_id, stop_name, transit_type, latitude, longitude, geom
/// （geom 为 null，PostGIS RPC 不可用，因此用经纬度列在客户端计算距离）。
class TransitRepository {
  final SupabaseClientManager _supabase = SupabaseClientManager();

  static const double earthRadiusM = 6371000.0;

  /// 获取距 (lat,lng) 不超过 [radiusMeters] 的站点，按距离升序。
  ///
  /// Supabase REST 无法直接做空间距离排序，因此在经纬度上做粗粒度包围盒过滤，
  /// 再在客户端用 Haversine 精确筛选排序。
  Future<List<Map<String, dynamic>>> fetchNearbyStops({
    required double lat,
    required double lng,
    double radiusMeters = 2000,
    int maxStops = 60,
  }) async {
    // 粗略包围盒（约 1° ≈ 111km），避免拉全表。
    final dLat = radiusMeters / 111320.0;
    final dLng = radiusMeters / (111320.0 * math.cos(lat * math.pi / 180).abs().clamp(0.01, 1.0));
    final results = await _supabase
        .from('transit_stops')
        .select('stop_id, stop_name, transit_type, latitude, longitude')
        .gte('latitude', lat - dLat)
        .lte('latitude', lat + dLat)
        .gte('longitude', lng - dLng)
        .lte('longitude', lng + dLng);

    final stops = <Map<String, dynamic>>[];
    for (final row in results) {
      final stopLat = (row['latitude'] as num?)?.toDouble();
      final stopLng = (row['longitude'] as num?)?.toDouble();
      if (stopLat == null || stopLng == null) continue;
      final distance = haversine(lat, lng, stopLat, stopLng);
      if (distance <= radiusMeters) {
        stops.add({
          'stop_id': row['stop_id'],
          'stop_name': row['stop_name'],
          'transit_type': row['transit_type'],
          'latitude': stopLat,
          'longitude': stopLng,
          'distance_meters': distance,
        });
      }
    }
    stops.sort((a, b) =>
        (a['distance_meters'] as double).compareTo(b['distance_meters'] as double));
    return stops.take(maxStops).toList();
  }

  /// Haversine 大圆距离（米）。
  static double haversine(double lat1, double lng1, double lat2, double lng2) {
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadiusM * math.asin(math.min(1, math.sqrt(a)));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
