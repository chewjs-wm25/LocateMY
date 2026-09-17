// Explicit parameter types and initialization follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/location_models.dart';
import '../application/location_storage.dart';

class LocationStore implements LocationStorage {
  LocationStore(SupabaseClient client, Database database, String accountId)
    : client = client,
      database = database,
      accountId = accountId;
  final SupabaseClient client;
  final Database database;
  final String accountId;
  Future<void> _schema() {
    return database.execute(
      'CREATE TABLE IF NOT EXISTS map_saved_records (account_id TEXT NOT NULL, client_key TEXT NOT NULL, payload TEXT NOT NULL, PRIMARY KEY(account_id,client_key))',
    );
  }

  void _authorize() {
    if (client.auth.currentUser?.id != accountId) {
      throw SavedLocationFailure.scopeUnavailable;
    }
  }

  SavedRecord _decode(Map<String, dynamic> record) {
    final GeographicPoint point = GeographicPoint(
      latitude: (record['latitude'] as num).toDouble(),
      longitude: (record['longitude'] as num).toDouble(),
    );
    final Object? failureValue = record['last_failure'];
    SavedLocationFailure? lastFailure;
    if (failureValue != null) {
      lastFailure = SavedLocationFailure.values.byName(failureValue as String);
    }
    final Object? syncStateValue = record['sync_state'];
    SavedLocationSyncState syncState = SavedLocationSyncState.synchronized;
    if (syncStateValue != null) {
      syncState = SavedLocationSyncState.values.byName(
        syncStateValue as String,
      );
    }
    return SavedRecord(
      clientKey: record['client_key'] as String,
      attempts: (record['attempts'] as num?)?.toInt() ?? 0,
      lastFailure: lastFailure,
      deleted: record['deleted_at'] != null,
      version: (record['version'] as num).toInt(),
      saved: SavedLocation(
        id: record['id'] as String,
        name: record['name'] as String,
        location: ValidLocationReference(
          locationId: '${point.latitude},${point.longitude}',
          point: point,
        ),
        createdAt: DateTime.parse(record['created_at'] as String),
        syncState: syncState,
      ),
    );
  }

  Map<String, dynamic> _encode(SavedRecord record) {
    String? deletedAt;
    if (record.deleted) {
      deletedAt = 'deleted';
    }
    return {
      'id': record.saved.id,
      'client_key': record.clientKey,
      'name': record.saved.name,
      'latitude': record.saved.location.point.latitude,
      'longitude': record.saved.location.point.longitude,
      'created_at': record.saved.createdAt.toIso8601String(),
      'deleted_at': deletedAt,
      'version': record.version,
      'sync_state': record.saved.syncState.name,
      'attempts': record.attempts,
      'last_failure': record.lastFailure?.name,
    };
  }

  @override
  Future<List<SavedRecord>> readLocal() async {
    await _schema();
    final List<Map<String, Object?>> rows = await database.query(
      'map_saved_records',
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
    final List<SavedRecord> records = <SavedRecord>[];
    for (final Map<String, Object?> row in rows) {
      final String payload = row['payload'] as String;
      final Map<String, dynamic> decoded =
          jsonDecode(payload) as Map<String, dynamic>;
      records.add(_decode(decoded));
    }
    return records;
  }

  @override
  Future<void> writeLocal(List<SavedRecord> records) async {
    await _schema();
    await database.transaction((tx) async {
      await tx.delete(
        'map_saved_records',
        where: 'account_id = ?',
        whereArgs: [accountId],
      );
      for (final SavedRecord r in records) {
        await tx.insert('map_saved_records', {
          'account_id': accountId,
          'client_key': r.clientKey,
          'payload': jsonEncode(_encode(r)),
        });
      }
    });
  }

  @override
  Future<void> clearLocal() async {
    await _schema();
    await database.delete(
      'map_saved_records',
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
  }

  SavedLocationFailure _failureForPostgrest(PostgrestException error) {
    switch (error.code) {
      case '42501':
      case '401':
      case '403':
      case 'PGRST301':
      case 'PGRST302':
      case 'PGRST303':
        return SavedLocationFailure.permissionDenied;
      case '23505':
      case '40001':
        return SavedLocationFailure.conflict;
      default:
        return SavedLocationFailure.retryableUnavailable;
    }
  }

  Future<T> _remote<T>(Future<T> Function() run) async {
    _authorize();
    try {
      final T value = await run().timeout(const Duration(seconds: 20));
      _authorize();
      return value;
    } on PostgrestException catch (error) {
      throw _failureForPostgrest(error);
    } on IOException {
      throw SavedLocationFailure.retryableUnavailable;
    } on http.ClientException {
      throw SavedLocationFailure.retryableUnavailable;
    } on TimeoutException {
      throw SavedLocationFailure.retryableUnavailable;
    }
  }

  @override
  Future<List<SavedRecord>> readRemote() {
    return _remote(() async {
      final List<dynamic> rows =
          await client.rpc('read_saved_locations') as List<dynamic>;
      final List<SavedRecord> records = <SavedRecord>[];
      for (final dynamic row in rows) {
        final Map<String, dynamic> values = Map<String, dynamic>.from(
          row as Map<dynamic, dynamic>,
        );
        records.add(_decode(values));
      }
      return records;
    });
  }

  @override
  Future<SavedRecord> createRemote(SavedRecord r) {
    return _remote(() async {
      await client
          .from('user_saved_locations')
          .upsert(
            {
              'user_id': accountId,
              'client_key': r.clientKey,
              'name': r.saved.name,
              'location':
                  'SRID=4326;POINT(${r.saved.location.point.longitude} ${r.saved.location.point.latitude})',
            },
            onConflict: 'user_id,client_key',
            ignoreDuplicates: true,
          );
      final List<SavedRecord> records = await readRemote();
      return records.firstWhere((row) => row.clientKey == r.clientKey);
    });
  }

  @override
  Future<SavedRecord> deleteRemote(SavedRecord r) {
    return _remote(() async {
      final List<Map<String, dynamic>> rows = await client
          .from('user_saved_locations')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', r.saved.id)
          .eq('version', r.version)
          .isFilter('deleted_at', null)
          .select('id');
      if (rows.isEmpty) {
        final Iterable<SavedRecord> current = (await readRemote()).where(
          (row) => row.saved.id == r.saved.id,
        );
        if (current.isEmpty) {
          throw SavedLocationFailure.notFound;
        }
        throw SavedLocationFailure.conflict;
      }
      final List<SavedRecord> records = await readRemote();
      return records.firstWhere((row) => row.saved.id == r.saved.id);
    });
  }
}

Future<bool> validateMalaysiaPoint(
  SupabaseClient client,
  GeographicPoint point,
) async {
  try {
    final rows = await client
        .rpc(
          'read_administrative_boundary_candidates',
          params: {'latitude': point.latitude, 'longitude': point.longitude},
        )
        .timeout(const Duration(seconds: 20));
    if (rows is! List) {
      throw SavedLocationFailure.retryableUnavailable;
    }
    for (final raw in rows) {
      final Map<dynamic, dynamic> r = raw as Map;
      if (r['source_version'] is! String ||
          (r['source_version'] as String).trim().isEmpty ||
          !RegExp(r'^[a-f0-9]{64}$')
              .hasMatch(r['source_sha256'] as String? ?? '') ||
          !RegExp(r'^[a-f0-9]{64}$')
              .hasMatch(r['derived_geometry_sha256'] as String? ?? '')) {
        throw SavedLocationFailure.retryableUnavailable;
      }
    }
    return rows.isNotEmpty;
  } catch (_) {
    throw SavedLocationFailure.retryableUnavailable;
  }
}
