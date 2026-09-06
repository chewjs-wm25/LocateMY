import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalCacheService {
  static final LocalCacheService _instance = LocalCacheService._internal();
  factory LocalCacheService() => _instance;
  LocalCacheService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'locate_my_cache.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE cached_reports(report_type TEXT, location_key TEXT, data_json TEXT, timestamp INTEGER, PRIMARY KEY(report_type, location_key))',
        );
        await db.execute(
          'CREATE TABLE saved_locations(id TEXT PRIMARY KEY, name TEXT, latitude REAL, longitude REAL, synced INTEGER DEFAULT 0, created_at INTEGER)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE TABLE saved_locations(id TEXT PRIMARY KEY, name TEXT, latitude REAL, longitude REAL, synced INTEGER DEFAULT 0, created_at INTEGER)',
          );
        }
      },
    );
  }

  Future<void> cacheData(String reportType, String locationKey, dynamic data) async {
    final db = await database;
    await db.insert(
      'cached_reports',
      {
        'report_type': reportType,
        'location_key': locationKey,
        'data_json': jsonEncode(data),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<dynamic> getCachedData(String reportType, String locationKey, {Duration? expiry}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_reports',
      where: 'report_type = ? AND location_key = ?',
      whereArgs: [reportType, locationKey],
    );

    if (maps.isEmpty) return null;

    final timestamp = maps.first['timestamp'] as int;
    if (expiry != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > expiry.inMilliseconds) {
        await deleteCache(reportType, locationKey);
        return null;
      }
    }

    return jsonDecode(maps.first['data_json']);
  }

  Future<void> deleteCache(String reportType, String locationKey) async {
    final db = await database;
    await db.delete(
      'cached_reports',
      where: 'report_type = ? AND location_key = ?',
      whereArgs: [reportType, locationKey],
    );
  }

  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete('cached_reports');
  }
}
