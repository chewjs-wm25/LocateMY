


import 'dart:convert';

import 'package:locatemy/features/map_location/map_location.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/facility_models.dart';
import '../application/facility_cache.dart';


final class PublicFacilityCache implements FacilityCache {
  final Database? database;
  final Map<String, OverpassFacilityComplete> _memory =
      <String, OverpassFacilityComplete>{};
  Future<void>? _ready;

  PublicFacilityCache(Database? database) : database = database;

  Future<void> _prepare() async {
    final Database? connection = database;
    if (connection != null) {
      final List<Map<String, Object?>> columns = await connection.rawQuery(
        'PRAGMA table_info(facility_public_cache)',
      );
      if (columns.isNotEmpty &&
          !columns.any((Map<String, Object?> column) {
            return column['name'] == 'expires_at';
          })) {
        
        
        await connection.execute('DROP TABLE facility_public_cache');
      }
      await connection.execute(
        'CREATE TABLE IF NOT EXISTS facility_public_cache '
        '(coordinate_key TEXT PRIMARY KEY, payload TEXT NOT NULL, '
        'radius_metres INTEGER NOT NULL, mapping_version TEXT NOT NULL, '
        'source TEXT NOT NULL, copyright_url TEXT NOT NULL, '
        'queried_at TEXT NOT NULL, expires_at TEXT NOT NULL, complete INTEGER NOT NULL)',
      );
    }
  }

  @override
  Future<OverpassFacilityComplete?> read(String key) async {
    final Database? connection = database;
    if (connection == null) {
      return _memory[key];
    }
    try {
      await (_ready ??= _prepare());
      final List<Map<String, Object?>> rows = await connection.query(
        'facility_public_cache',
        where: 'coordinate_key = ?',
        whereArgs: <Object>[key],
      );
      if (rows.isEmpty) {
        return null;
      }
      final Map<String, Object?> row = rows.first;
      if (row['radius_metres'] != 2000 ||
          row['mapping_version'] != 'osm-facility-v1' ||
          row['complete'] != 1 ||
          row['source'] != '© OpenStreetMap contributors' ||
          row['copyright_url'] != 'https://www.openstreetmap.org/copyright') {
        return null;
      }
      final DateTime queriedAt = DateTime.parse(row['queried_at'] as String);
      final DateTime expiresAt = DateTime.parse(row['expires_at'] as String);
      if (expiresAt.difference(queriedAt) != const Duration(hours: 24)) {
        return null;
      }
      final Map<String, dynamic> payload =
          jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
      final List<OverpassElement> elements = <OverpassElement>[];
      for (final dynamic raw in payload['elements'] as List<dynamic>) {
        final Map<String, dynamic> item = raw as Map<String, dynamic>;
        elements.add(
          OverpassElement(
            elementType: item['type'] as String,
            osmId: item['id'] as String,
            representativePoint: GeographicPoint(
              latitude: (item['lat'] as num).toDouble(),
              longitude: (item['lon'] as num).toDouble(),
            ),
            tags: Map<String, String>.from(item['tags'] as Map),
          ),
        );
      }
      return OverpassFacilityComplete(
        elements: List<OverpassElement>.unmodifiable(elements),
        queriedAt: queriedAt,
      );
    } catch (_) {
      
      return null;
    }
  }

  @override
  Future<void> write(String key, OverpassFacilityComplete result) async {
    final Database? connection = database;
    if (connection == null) {
      _memory[key] = result;
      return;
    }
    final List<Map<String, Object>> elements = <Map<String, Object>>[];
    for (final OverpassElement element in result.elements) {
      elements.add(<String, Object>{
        'type': element.elementType,
        'id': element.osmId,
        'lat': element.representativePoint.latitude,
        'lon': element.representativePoint.longitude,
        'tags': element.tags,
      });
    }
    try {
      await (_ready ??= _prepare());
      await connection.insert('facility_public_cache', <String, Object>{
        'coordinate_key': key,
        'radius_metres': 2000,
        'mapping_version': 'osm-facility-v1',
        'source': '© OpenStreetMap contributors',
        'copyright_url': 'https://www.openstreetmap.org/copyright',
        'queried_at': result.queriedAt.toUtc().toIso8601String(),
        'expires_at': result.queriedAt
            .toUtc()
            .add(const Duration(hours: 24))
            .toIso8601String(),
        'complete': 1,
        'payload': jsonEncode(<String, Object>{
          'queriedAt': result.queriedAt.toUtc().toIso8601String(),
          'elements': elements,
        }),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      
    }
  }
}
