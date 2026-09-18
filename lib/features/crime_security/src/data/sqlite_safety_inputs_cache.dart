

import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../application/safety_inputs_cache.dart';

import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/safety_input_rules.dart';

final class SqliteSafetyInputsCache implements SafetyInputsCache {
  final Database _database;
  final DateTime Function() _clock;
  SqliteSafetyInputsCache(Database database, DateTime Function() clock)
    : _database = database,
      _clock = clock;
  Future<void>? _initialization;
  Future<void> _initialize() async {
    await _database.execute(
      'CREATE TABLE IF NOT EXISTS crime_public_cache (cache_key TEXT PRIMARY KEY, model_version TEXT NOT NULL, payload TEXT NOT NULL, source_year INTEGER NOT NULL, fetched_at TEXT NOT NULL, expires_at TEXT NOT NULL)',
    );
  }

  @override
  Future<Map<String, Object?>?> read() async {
    try {
      _initialization ??= _initialize();
      await _initialization;
      final List<Map<String, Object?>> rows = await _database.query(
        'crime_public_cache',
        where: 'cache_key = ? AND model_version = ?',
        whereArgs: <Object?>['all-reporting-states', 'safety-state-v1'],
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
      final DateTime now = _clock().toUtc();
      if (fetched.isAfter(now) ||
          !expires.isAfter(now) ||
          expires.difference(fetched) != const Duration(days: 3)) {
        return null;
      }
      final Map<String, Object?> payload = Map<String, Object?>.from(
        jsonDecode(rows.first['payload'] as String) as Map,
      );
      validateSafetyInputs(payload, _clock());
      if (rows.first['source_year'] != payload['latest_complete_year']) {
        return null;
      }
      payload['_input_fetched_at'] = fetched.toUtc().toIso8601String();
      return payload;
    } catch (_) {
      _initialization = null;
      return null;
    }
  }

  @override
  Future<void> write(Map<String, Object?> data, DateTime fetched) async {
    _initialization ??= _initialize();
    await _initialization;
    await _database.insert('crime_public_cache', <String, Object?>{
      'cache_key': 'all-reporting-states',
      'model_version': 'safety-state-v1',
      'payload': jsonEncode(data),
      'source_year': data['latest_complete_year'],
      'fetched_at': fetched.toIso8601String(),
      'expires_at': fetched.add(const Duration(days: 3)).toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  String _scopeKey(ValidLocationReference location) {
    return 'location:${location.point.latitude}:${location.point.longitude}';
  }

  @override
  Future<SafetyCachedScope?> readScope(ValidLocationReference location) async {
    try {
      _initialization ??= _initialize();
      await _initialization;
      final List<Map<String, Object?>> rows = await _database.query(
        'crime_public_cache',
        where: 'cache_key = ? AND model_version = ?',
        whereArgs: <Object?>[_scopeKey(location), 'safety-state-v1'],
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
      final Map<String, Object?> payload = Map<String, Object?>.from(
        jsonDecode(rows.first['payload'] as String) as Map,
      );
      if (payload['latitude'] != location.point.latitude ||
          payload['longitude'] != location.point.longitude ||
          payload['state'] is! String ||
          (payload['state'] as String).isEmpty ||
          payload['boundary_version'] is! String ||
          (payload['boundary_version'] as String).isEmpty) {
        return null;
      }
      final Map<String, Object?> inputs = Map<String, Object?>.from(
        payload['inputs'] as Map,
      );
      validateSafetyInputs(inputs, _clock());
      if (rows.first['source_year'] != inputs['latest_complete_year']) {
        return null;
      }
      return SafetyCachedScope(
        payload['state'] as String,
        payload['boundary_version'] as String,
        inputs,
        fetched,
      );
    } catch (_) {
      _initialization = null;
      return null;
    }
  }

  @override
  Future<void> writeScope(
    ValidLocationReference location,
    SafetyCachedScope scope,
  ) async {
    _initialization ??= _initialize();
    await _initialization;
    await _database.insert('crime_public_cache', <String, Object?>{
      'cache_key': _scopeKey(location),
      'model_version': 'safety-state-v1',
      'payload': jsonEncode(<String, Object?>{
        'latitude': location.point.latitude,
        'longitude': location.point.longitude,
        'state': scope.state,
        'boundary_version': scope.boundaryVersion,
        'inputs': scope.inputs,
      }),
      'source_year': scope.inputs['latest_complete_year'],
      'fetched_at': scope.capturedAt.toUtc().toIso8601String(),
      'expires_at': scope.capturedAt
          .toUtc()
          .add(const Duration(days: 3))
          .toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
