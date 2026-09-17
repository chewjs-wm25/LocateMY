import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../application/home_dependencies.dart';
import '../domain/home_models.dart';
import '../domain/home_snapshot_validation.dart';
import 'home_codec.dart';

final class SqliteHomeCache implements PublicHomeCache {
  final Future<Database> Function() open;
  Future<Database>? _database;
  final DateTime Function() clock;
  SqliteHomeCache(this.open, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  Future<Database> _db() =>
      _database ??= _initialize().catchError((Object error, StackTrace stack) {
        _database = null;
        Error.throwWithStackTrace(error, stack);
      });
  Future<Database> _initialize() async {
    final db = await open();
    await db.execute(
      'CREATE TABLE IF NOT EXISTS home_public_cache (cache_key TEXT PRIMARY KEY, payload_version INTEGER NOT NULL, result_payload TEXT NOT NULL, source_dates TEXT NOT NULL, fetched_at TEXT NOT NULL, expires_at TEXT NOT NULL, completeness TEXT NOT NULL)',
    );
    return db;
  }

  @override
  Future<HomeOutlookSnapshot?> read() async {
    try {
      final rows = await (await _db()).query(
        'home_public_cache',
        where: 'cache_key = ? AND payload_version = ?',
        whereArgs: ['national', 1],
      );
      if (rows.isEmpty) return null;
      final snapshot = decodeHomeOutlookSnapshot(
        Map<String, dynamic>.from(
          jsonDecode(rows.single['result_payload'] as String) as Map,
        ),
      );
      return validCachedHome(snapshot, clock()) ? snapshot : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(HomeOutlookSnapshot snapshot) async {
    final db = await _db();
    await db.transaction((transaction) async {
      final rows = await transaction.query(
        'home_public_cache',
        where: 'cache_key = ? AND payload_version = ?',
        whereArgs: ['national', 1],
      );
      if (rows.isNotEmpty) {
        HomeOutlookSnapshot? current;
        try {
          current = decodeHomeOutlookSnapshot(
            Map<String, dynamic>.from(
              jsonDecode(rows.single['result_payload'] as String) as Map,
            ),
          );
        } catch (_) {}
        if (current != null && validCachedHome(current, clock())) {
          final previous = {
            for (final source in [
              ...current.relocationTiming.sources,
              current.householdMedianIncome.source,
            ])
              source.datasetId: source.observedAt,
          };
          final candidate = {
            for (final source in [
              ...snapshot.relocationTiming.sources,
              snapshot.householdMedianIncome.source,
            ])
              source.datasetId: source.observedAt,
          };
          if (previous.entries.any(
            (e) =>
                candidate[e.key] == null || candidate[e.key]!.isBefore(e.value),
          )) {
            return;
          }
          if (!candidate.entries.any(
            (e) => previous[e.key] == null || e.value.isAfter(previous[e.key]!),
          )) {
            return;
          }
        }
      }
      await transaction.insert('home_public_cache', {
        'cache_key': 'national',
        'payload_version': 1,
        'result_payload': jsonEncode(encodeHomeOutlookSnapshot(snapshot)),
        'source_dates': jsonEncode({
          for (final source in [
            ...snapshot.relocationTiming.sources,
            snapshot.householdMedianIncome.source,
          ])
            source.datasetId: source.observedAt.toIso8601String(),
        }),
        'fetched_at': snapshot.fetchedAt.toIso8601String(),
        'expires_at': snapshot.fetchedAt
            .add(const Duration(days: 1))
            .toIso8601String(),
        'completeness': snapshot.completeness.name,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }
}
