import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'durable local store isolates accounts and survives reopening',
    () async {
      sqfliteFfiInit();
      final Database db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
      );
      final SupabaseClient client = SupabaseClient(
        'https://example.test',
        'public',
      );
      final LocationStorage a = createLocationStorage(
        client: client,
        database: db,
        accountId: 'a',
      );
      final LocationStorage b = createLocationStorage(
        client: client,
        database: db,
        accountId: 'b',
      );
      final SavedRecord record = SavedRecord(
        clientKey: 'key',
        attempts: 2,
        lastFailure: SavedLocationFailure.retryableUnavailable,
        saved: SavedLocation(
          id: 'key',
          name: 'Home',
          location: const ValidLocationReference(
            locationId: 'p',
            point: GeographicPoint(latitude: 3, longitude: 101),
          ),
          createdAt: DateTime.utc(2026),
          syncState: SavedLocationSyncState.queued,
        ),
      );
      await a.writeLocal([record]);
      expect(
        (await createLocationStorage(
          client: client,
          database: db,
          accountId: 'a',
        ).readLocal()).single.saved.name,
        'Home',
      );
      expect((await a.readLocal()).single.attempts, 2);
      expect(
        (await a.readLocal()).single.lastFailure,
        SavedLocationFailure.retryableUnavailable,
      );
      expect(await b.readLocal(), isEmpty);
      await a.clearLocal();
      expect(await a.readLocal(), isEmpty);
      await client.dispose();
      await db.close();
    },
  );
}
