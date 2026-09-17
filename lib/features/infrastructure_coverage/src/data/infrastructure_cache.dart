// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:convert';

import '../application/infrastructure_service.dart';

import 'package:sqflite/sqflite.dart';

final class InfrastructureCache implements InfrastructurePublicCache {
  final Database _database;
  final DateTime Function() _clock;
  Future<void>? _initialization;
  InfrastructureCache(Database database, DateTime Function() clock)
    : _database = database,
      _clock = clock;
  Future<void> _initialize() async {
    await _database.execute(
      'CREATE TABLE IF NOT EXISTS infrastructure_public_cache (cache_key TEXT PRIMARY KEY, version INTEGER NOT NULL, payload TEXT NOT NULL, fetched_at TEXT NOT NULL, expires_at TEXT NOT NULL)',
    );
  }

  @override
  Future<Map<String, Object?>?> read(String key) async {
    try {
      _initialization ??= _initialize();
      await _initialization;
      final List<Map<String, Object?>> rows = await _database.query(
        'infrastructure_public_cache',
        where: 'cache_key = ? AND version = 1',
        whereArgs: <Object?>[key],
      );
      if (rows.isEmpty) {
        return null;
      }
      final DateTime fetched = DateTime.parse(
        rows.first['fetched_at'] as String,
      );
      final DateTime expires = DateTime.parse(
        rows.first['expires_at'] as String,
      );
      if (fetched.isAfter(_clock()) ||
          !expires.isAfter(_clock()) ||
          expires.difference(fetched) != const Duration(days: 3)) {
        return null;
      }
      return Map<String, Object?>.from(
        jsonDecode(rows.first['payload'] as String) as Map,
      );
    } catch (_) {
      _initialization = null;
      return null;
    }
  }

  @override
  Future<void> write(String key, Map<String, Object?> payload) async {
    _initialization ??= _initialize();
    await _initialization;
    final DateTime now = _clock().toUtc();
    await _database.insert('infrastructure_public_cache', <String, Object?>{
      'cache_key': key,
      'version': 1,
      'payload': jsonEncode(payload),
      'fetched_at': now.toIso8601String(),
      'expires_at': now.add(const Duration(days: 3)).toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
