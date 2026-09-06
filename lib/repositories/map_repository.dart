import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      return data.map((json) => _parseHazardMarker(json as Map<String, dynamic>)).toList();
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

  HazardType _parseHazardType(String? type) {
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
      return data.map((json) => _parseHazardMarker(json)).toList();
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

  HazardMarker _parseHazardMarker(Map<String, dynamic> json) {
    final dynamic locationData = json['location'];
    LatLng pos = const LatLng(0, 0);
    
    if (locationData is String && locationData.contains('POINT')) {
      // Handle "POINT(lng lat)" format from PostGIS
      final content = locationData.replaceAll('POINT(', '').replaceAll(')', '').trim();
      final coords = content.split(RegExp(r'\s+'));
      if (coords.length >= 2) {
        pos = LatLng(double.parse(coords[1]), double.parse(coords[0]));
      }
    } else if (locationData is Map<String, dynamic>) {
      final lat = locationData['lat'] ?? locationData['latitude'] ?? 0.0;
      final lng = locationData['lng'] ?? locationData['longitude'] ?? 0.0;
      pos = LatLng((lat as num).toDouble(), (lng as num).toDouble());
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
    await db.delete('saved_locations', where: 'id = ?', whereArgs: [id]);
    
    // Also try to delete from Supabase if authenticated
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('user_saved_regions').delete().eq('alias', id); // Using alias to store local ID for mapping
      } catch (e) {
        print('Error deleting from Supabase: $e');
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
      try {
        // According to real_supabase_tables.md, user_saved_regions has:
        // user_id, district_id, alias
        // We'll store our local ID in alias and coordinates in district_id or similar.
        // But district_id is TEXT. Let's store coords as string for now if district lookup isn't available.
        await _supabase.from('user_saved_regions').upsert({
          'user_id': user.id,
          'district_id': '${location.location.latitude},${location.location.longitude}',
          'alias': location.name,
        });

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
