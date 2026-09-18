import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrimeRepository {
  final SupabaseClient supabaseClient;
  final Database database;

  const CrimeRepository({required this.supabaseClient, required this.database});

  Future<void> ensureCacheTableExists() async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS crime_public_cache (
        reporting_state TEXT,
        model_version TEXT,
        boundary_version TEXT,
        result TEXT,
        source_year INTEGER,
        fetched_at INTEGER,
        expires_at INTEGER,
        PRIMARY KEY (reporting_state, model_version, boundary_version)
      )
    ''');
  }

  Future<CachedSafetyData?> getCachedSafety(
    String stateId,
    String modelVersion,
    String boundaryVersion,
  ) async {
    await ensureCacheTableExists();
    final List<Map<String, dynamic>> maps = await database.query(
      'crime_public_cache',
      where:
          'reporting_state = ? AND model_version = ? AND boundary_version = ?',
      whereArgs: [stateId, modelVersion, boundaryVersion],
    );

    if (maps.isEmpty) return null;

    final row = maps.first;
    final int expiresAt = row['expires_at'] as int;
    final bool isExpired = DateTime.now().millisecondsSinceEpoch > expiresAt;

    return CachedSafetyData(
      snapshotJson: row['result'] as String,
      sourceYear: row['source_year'] as int,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(row['fetched_at'] as int),
      isExpired: isExpired,
    );
  }

  Future<void> cacheSafety({
    required String stateId,
    required String modelVersion,
    required String boundaryVersion,
    required String snapshotJson,
    required int sourceYear,
    required Duration ttl,
  }) async {
    await ensureCacheTableExists();
    final now = DateTime.now();
    await database.insert('crime_public_cache', {
      'reporting_state': stateId,
      'model_version': modelVersion,
      'boundary_version': boundaryVersion,
      'result': snapshotJson,
      'source_year': sourceYear,
      'fetched_at': now.millisecondsSinceEpoch,
      'expires_at': now.add(ttl).millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<RawCrimeData>> fetchCrimeData(String stateName) async {
    
    
    
    
    try {
      final response = await supabaseClient
          .from('crime_district')
          .select('date, state, category, type, crimes')
          .eq('state', stateName);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => RawCrimeData.fromJson(json)).toList();
    } catch (e) {
      
      return [];
    }
  }

  Future<List<String>> fetchOtherStatesData(int year) async {
    
    
    try {
      final response = await supabaseClient
          .from('crime_district')
          .select('state, category, crimes')
          .filter('date', 'like', '$year%')
          .neq('state', 'Malaysia');

      
      
      
      return (response as List<dynamic>).map((e) => jsonEncode(e)).toList();
    } catch (e) {
      return [];
    }
  }
}

final class CachedSafetyData {
  final String snapshotJson;
  final int sourceYear;
  final DateTime fetchedAt;
  final bool isExpired;

  const CachedSafetyData({
    required this.snapshotJson,
    required this.sourceYear,
    required this.fetchedAt,
    required this.isExpired,
  });
}

final class RawCrimeData {
  final String date;
  final String state;
  final String category;
  final String type;
  final int crimes;

  const RawCrimeData({
    required this.date,
    required this.state,
    required this.category,
    required this.type,
    required this.crimes,
  });

  factory RawCrimeData.fromJson(Map<String, dynamic> json) {
    return RawCrimeData(
      date: json['date'] as String,
      state: json['state'] as String,
      category: json['category'] as String,
      type: json['type'] as String,
      crimes: json['crimes'] as int,
    );
  }
}
