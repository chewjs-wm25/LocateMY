import 'package:latlong2/latlong.dart';
import '../core/supabase/supabase_client_manager.dart';
import '../core/cache/local_cache_service.dart';
import '../models/hazard_marker.dart';
import '../models/saved_location.dart';
import 'package:sqflite/sqflite.dart';

class MapRepository {
  final SupabaseClientManager _supabase = SupabaseClientManager();
  final LocalCacheService _cacheService = LocalCacheService();

  // --- Hazards (Supabase) ---

  Future<List<HazardMarker>> fetchHazards() async {
    try {
      final response = await _supabase.from('crowdsourced_hazards').select();
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => parseHazardMarker(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching hazards: $e');
      return [];
    }
  }

  Future<bool> saveHazard(HazardMarker hazard) async {
    try {
      final user = _supabase.auth.currentUser;
      await _supabase.from('crowdsourced_hazards').insert({
        'user_id': user?.id,
        'hazard_type': hazard.type.name,
        'title': hazard.title,
        'description': hazard.description,
        'location': 'POINT(${hazard.location.longitude} ${hazard.location.latitude})',
        'report_time': hazard.createdAt.toIso8601String(),
      }).select(); // 关键：添加 .select() 以确保数据已被处理
      return true;
    } catch (e) {
      print('Error saving hazard: $e');
      return false;
    }
  }

  static HazardType _parseHazardType(String? type) {
    return HazardType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => HazardType.other,
    );
  }

  // --- User Specific Hazards ---

  Future<List<HazardMarker>> fetchUserHazards() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('crowdsourced_hazards')
          .select()
          .eq('user_id', user.id)
          .order('report_time', ascending: false);
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => parseHazardMarker(json)).toList();
    } catch (e) {
      print('Error fetching user hazards: $e');
      return [];
    }
  }

  Future<bool> deleteHazard(String id) async {
    try {
      await _supabase.from('crowdsourced_hazards').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting hazard: $e');
      return false;
    }
  }

  /// 将 Supabase `crowdsourced_hazards` 的一行记录解析为 [HazardMarker]。
  ///
  /// PostGIS `geometry` 列经 Supabase REST 返回的是 GeoJSON，例如：
  ///   {"type":"Point","crs":{...},"coordinates":[lng, lat]}
  /// 坐标数组始终是 [经度, 纬度]，因此解析为 LatLng 时要交换位置。
  static HazardMarker parseHazardMarker(Map<String, dynamic> json) {
    final dynamic locationData = json['location'];
    LatLng pos = const LatLng(0, 0);

    if (locationData is String && locationData.contains('POINT')) {
      // Handle "SRID=4326;POINT(lng lat)" / "POINT(lng lat)" text format
      final content = locationData
          .replaceFirst(RegExp(r'^SRID=\d+;'), '')
          .replaceAll('POINT(', '')
          .replaceAll(')', '')
          .trim();
      final coords = content.split(RegExp(r'\s+'));
      if (coords.length >= 2) {
        pos = LatLng(double.parse(coords[1]), double.parse(coords[0]));
      }
    } else if (locationData is Map<String, dynamic>) {
      final rawCoordinates = locationData['coordinates'];
      if (rawCoordinates is List && rawCoordinates.length >= 2) {
        // GeoJSON: coordinates = [longitude, latitude]
        pos = LatLng(
          (rawCoordinates[1] as num).toDouble(),
          (rawCoordinates[0] as num).toDouble(),
        );
      } else {
        // 普通对象: 直接提供 lat / lng 键
        final lat = locationData['lat'] ?? locationData['latitude'] ?? 0.0;
        final lng = locationData['lng'] ?? locationData['longitude'] ?? 0.0;
        pos = LatLng((lat as num).toDouble(), (lng as num).toDouble());
      }
    } else if (json['latitude'] != null && json['longitude'] != null) {
      pos = LatLng((json['latitude'] as num).toDouble(), (json['longitude'] as num).toDouble());
    }

    return HazardMarker(
      id: json['id'].toString(),
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? '',
      location: pos,
      type: _parseHazardType(json['hazard_type']),
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      createdBy: json['user_id'] ?? 'Anonymous',
      createdAt: DateTime.tryParse(json['report_time'] ?? '') ?? DateTime.now(),
    );
  }

  // --- Saved Locations (Local SQLite + Sync to Supabase) ---

  Future<List<SavedLocation>> getLocalSavedLocations() async {
    final db = await _cacheService.database;
    final List<Map<String, dynamic>> maps = await db.query('saved_locations', orderBy: 'created_at DESC');
    return maps.map((m) => SavedLocation.fromMap(m)).toList();
  }

  Future<void> addLocalSavedLocation(SavedLocation location) async {
    final db = await _cacheService.database;
    await db.insert(
      'saved_locations',
      location.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Try to sync immediately
    syncToSupabase();
  }

  Future<void> removeLocalSavedLocation(String id) async {
    final db = await _cacheService.database;
    // 先取该收藏的坐标：云端 user_saved_regions 的 (user_id, district_id) 唯一键
    // 中 district_id 保存的是 “lat,lng” 坐标串，删除需按它精确匹配。
    final List<Map<String, dynamic>> rows = await db.query(
      'saved_locations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    await db.delete('saved_locations', where: 'id = ?', whereArgs: [id]);

    // Also try to delete from Supabase if authenticated
    final user = _supabase.auth.currentUser;
    if (user != null && rows.isNotEmpty) {
      final lat = (rows.first['latitude'] as num?)?.toDouble();
      final lng = (rows.first['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        try {
          // district_id 与该收藏同步时写入的坐标串完全一致，且 (user_id,
          // district_id) 唯一，删除必然精确命中该云端行（旧实现按 alias=本地
          // UUID 匹配是无效的——云端 alias 存的是收藏名称）。
          await _supabase
              .from('user_saved_regions')
              .delete()
              .eq('user_id', user.id)
              .eq('district_id', '${lat.toString()},${lng.toString()}');
        } catch (e) {
          print('Error deleting from Supabase: $e');
        }
      }
    }
  }

  Future<void> syncToSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final db = await _cacheService.database;
    final List<Map<String, dynamic>> unsynced = await db.query(
      'saved_locations',
      where: 'synced = 0',
    );

    for (var map in unsynced) {
      final location = SavedLocation.fromMap(map);
      final districtId = '${location.location.latitude},${location.location.longitude}';
      try {
        // user_saved_regions 对 (user_id, district_id) 有唯一约束；本地每条收藏
        // 都有独立 id（毫秒时间戳），而云端行主键是云端生成的 uuid。若这里不
        // 显式指定 onConflict，PostgREST 会按主键 id 判断冲突（永不冲突）→ 等价
        // 于 INSERT，同一坐标再次同步就会触发 duplicate key
        // (user_saved_regions_user_id_district_id_key)。
        // 显式 onConflict='user_id,district_id' 后，同一坐标重复同步会更新已
        // 有行而不是重复插入，天然幂等，可安全重试。
        await _supabase.from('user_saved_regions').upsert({
          'user_id': user.id,
          'district_id': districtId,
          'alias': location.name,
        }, onConflict: 'user_id,district_id');

        // Mark as synced locally
        await db.update(
          'saved_locations',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [location.id],
        );
      } catch (e) {
        print('Sync error for ${location.name}: $e');
      }
    }
  }
}
