import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('real DOSM boundary, durable favorites, two clients, tombstone and RLS', () async {
    HttpOverrides.global = null;
    sqfliteFfiInit();
    final Map<String, String> env = Platform.environment;
    SupabaseClient make() {
      return SupabaseClient(
        env['SUPABASE_URL']!,
        env['SUPABASE_PUBLISHABLE_KEY']!,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
    }

    final SupabaseClient a = make(),
        second = make(),
        other = make(),
        anon = make();
    final Database db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    final Database db2 = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      await a.auth.signInWithPassword(
        email: env['LOCATEMY_EMAIL']!,
        password: env['LOCATEMY_PASSWORD']!,
      );
      await second.auth.signInWithPassword(
        email: env['LOCATEMY_EMAIL']!,
        password: env['LOCATEMY_PASSWORD']!,
      );
      await other.auth.signInWithPassword(
        email: env['LOCATEMY_OTHER_EMAIL']!,
        password: env['LOCATEMY_OTHER_PASSWORD']!,
      );

      final AccountScope otherScope = AccountScope(other.auth.currentUser!.id);
      final Database otherDb = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        final LocationCoordinator otherMap = createLocationCoordinator(
          scope: otherScope,
          readScope: () => AccountScopeOpened(otherScope),
          validatePoint: (p) => validateLocationInMalaysia(other, p),
          storage: createLocationStorage(
            client: other,
            database: otherDb,
            accountId: otherScope.accountId,
          ),
        );
        final LocationSelected chosen = await otherMap.select(
          const LocationSelectionRequest(
            role: LocationRole.single,
            point: GeographicPoint(latitude: 3.0738, longitude: 101.5183),
          ),
        ) as LocationSelected;
        final SavedLocationOutcome created = await otherMap.save(
          SaveLocationRequest(
            location: chosen.location,
            name: '${env['LOCATEMY_MAP_FIXTURE']}-other',
          ),
        );
        expect(
          created,
          isA<SavedLocationSaved>(),
          reason:
              'optional profile absence cannot prevent authenticated favorites',
        );
      } finally {
        await otherDb.close();
      }
      final AccountScope scope = AccountScope(a.auth.currentUser!.id);
      AccountScopeSnapshot current = AccountScopeOpened(scope);
      final LocationCoordinator map = createLocationCoordinator(
        scope: scope,
        readScope: () => current,
        validatePoint: (p) => validateLocationInMalaysia(a, p),
        storage: createLocationStorage(
          client: a,
          database: db,
          accountId: scope.accountId,
        ),
      );
      final LocationCoordinator map2 = createLocationCoordinator(
        scope: scope,
        readScope: () => current,
        validatePoint: (p) => validateLocationInMalaysia(second, p),
        storage: createLocationStorage(
          client: second,
          database: db2,
          accountId: scope.accountId,
        ),
      );
      for (final p in [
        const GeographicPoint(
          latitude: 2.18072,
          longitude: 102.99359,
        ), // exact audited polygon vertex, ST_Covers
        const GeographicPoint(latitude: 3.0738, longitude: 101.5183),
        const GeographicPoint(latitude: 5.4141, longitude: 100.3288),
        const GeographicPoint(latitude: 6.1248, longitude: 100.3682),
        const GeographicPoint(latitude: 6.3529, longitude: 99.7620),
        const GeographicPoint(latitude: 5.9804, longitude: 116.0735),
      ]) {
        expect(
          await map.select(
            LocationSelectionRequest(role: LocationRole.single, point: p),
          ),
          isA<LocationSelected>(),
        );
      }
      expect(
        (await map.select(
          const LocationSelectionRequest(
            role: LocationRole.single,
            point: GeographicPoint(latitude: 3, longitude: 104),
          ),
        ) as LocationSelectionRejected).failure,
        LocationSelectionFailure.outsideMalaysia,
      );
      expect(
        (await map.select(
          const LocationSelectionRequest(
            role: LocationRole.single,
            point: GeographicPoint(latitude: 1.3, longitude: 103.8),
          ),
        ) as LocationSelectionRejected).failure,
        LocationSelectionFailure.outsideMalaysia,
      );
      final LocationSelected selected = await map.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 3.0738, longitude: 101.5183),
        ),
      ) as LocationSelected;
      final String name = env['LOCATEMY_MAP_FIXTURE']!;
      final SavedLocationOutcome result = await map.save(
        SaveLocationRequest(location: selected.location, name: name),
      );
      expect(
        result,
        isA<SavedLocationSaved>(),
        reason: result is SavedLocationRejected
            ? result.failure.name
            : result.runtimeType.toString(),
      );
      final SavedLocation saved = (result as SavedLocationSaved).savedLocation;
      expect(
        (await map2.synchronizeSavedLocations() as SavedLocationsAvailable)
            .locations
            .any((r) => r.id == saved.id),
        true,
      );
      expect(
        (await other.rpc('read_saved_locations') as List).where(
          (r) => r['id'] == saved.id,
        ),
        isEmpty,
      );
      await expectLater(
        anon.rpc('read_saved_locations'),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        other.from('user_saved_locations').insert({
          'user_id': scope.accountId,
          'name': 'denied',
          'client_key': 'denied',
          'location': 'SRID=4326;POINT(101 3)',
        }),
        throwsA(isA<PostgrestException>()),
      );
      expect(
        await other
            .from('user_saved_locations')
            .update({'name': 'denied'})
            .eq('id', saved.id)
            .select('id'),
        isEmpty,
      );
      await expectLater(
        anon.from('user_saved_locations').insert({
          'user_id': scope.accountId,
          'name': 'denied',
          'client_key': 'anonymous',
          'location': 'SRID=4326;POINT(101 3)',
        }),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        a.from('user_saved_locations').delete().eq('id', saved.id),
        throwsA(isA<PostgrestException>()),
      );
      // Second client retains the previous revision; deletion must conflict.
      expect(
        await map.deleteSavedLocation(saved.id),
        isA<SavedLocationSaved>(),
      );
      expect(
        (await map2.deleteSavedLocation(
          saved.id,
        ) as SavedLocationRejected).failure,
        SavedLocationFailure.conflict,
      );
      expect(
        (await map2.synchronizeSavedLocations() as SavedLocationsAvailable)
            .locations
            .any((r) => r.id == saved.id),
        false,
      );
      expect(
        (await map2.deleteSavedLocation(
          saved.id,
        ) as SavedLocationRejected).failure,
        SavedLocationFailure.notFound,
      );

      final SwitchNetwork network = SwitchNetwork();
      final SupabaseClient offlineClient = SupabaseClient(
        env['SUPABASE_URL']!,
        env['SUPABASE_PUBLISHABLE_KEY']!,
        httpClient: network,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      await offlineClient.auth.signInWithPassword(
        email: env['LOCATEMY_EMAIL']!,
        password: env['LOCATEMY_PASSWORD']!,
      );
      final Directory disk = await Directory.systemTemp.createTemp(
        'map-replay-',
      );
      Database diskDb = await databaseFactoryFfi.openDatabase(
        '${disk.path}/map.db',
      );
      try {
        LocationCoordinator makeOffline() {
          return createLocationCoordinator(
            scope: scope,
            readScope: () => current,
            validatePoint: (p) => validateLocationInMalaysia(offlineClient, p),
            storage: createLocationStorage(
              client: offlineClient,
              database: diskDb,
              accountId: scope.accountId,
            ),
          );
        }

        LocationCoordinator offlineMap = makeOffline();
        final LocationSelected chosen = await offlineMap.select(
          const LocationSelectionRequest(
            role: LocationRole.single,
            point: GeographicPoint(latitude: 3.0738, longitude: 101.5183),
          ),
        ) as LocationSelected;
        network.offline = true;
        expect(
          await offlineMap.save(
            SaveLocationRequest(
              location: chosen.location,
              name: '$name-queued',
            ),
          ),
          isA<SavedLocationQueued>(),
        );
        await diskDb.close();
        diskDb = await databaseFactoryFfi.openDatabase('${disk.path}/map.db');
        offlineMap = makeOffline();
        expect(
          await offlineMap.synchronizeSavedLocations(),
          isA<SavedLocationsUnavailable>(),
        );
        network.offline = false;
        final SavedLocationsSnapshot replay = await offlineMap
            .synchronizeSavedLocations();
        expect(replay, isA<SavedLocationsAvailable>());
        expect(
          (replay as SavedLocationsAvailable).locations.any(
            (r) =>
                r.name == '$name-queued' &&
                r.syncState == SavedLocationSyncState.synchronized,
          ),
          true,
        );
        for (final r in replay.locations.where(
          (r) => r.name == '$name-queued',
        )) {
          await offlineMap.deleteSavedLocation(r.id);
        }
      } finally {
        await diskDb.close();
        await disk.delete(recursive: true);
        await offlineClient.dispose();
      }
      current = AccountScopeClosing(scope);
      expect(map.read(LocationRole.single), isA<LocationAbsent>());
      expect(
        await locationPrivacyParticipant(map).clearPrivateState(scope),
        isA<PrivateStateCleared>(),
      );
      expect(
        (await map.synchronizeSavedLocations() as SavedLocationsUnavailable)
            .failure,
        SavedLocationFailure.scopeUnavailable,
      );
      if (env['GEOAPIFY_API_KEY']?.isNotEmpty == true) {
        final LocationSearchAvailable candidates = await createLocationSearch(
          apiKey: env['GEOAPIFY_API_KEY']!,
        ).search('Shah Alam') as LocationSearchAvailable;
        expect(candidates.candidates, isNotEmpty);
        expect(
          await validateLocationInMalaysia(
            a,
            candidates.candidates.first.point,
          ),
          isTrue,
        );
      }
    } finally {
      await db.close();
      await db2.close();
      await Future.wait([
        a.dispose(),
        second.dispose(),
        other.dispose(),
        anon.dispose(),
      ]);
    }
  }, skip: Platform.environment['LOCATEMY_MAP_LIVE'] != '1');
}

class SwitchNetwork extends http.BaseClient {
  final http.Client inner = http.Client();
  bool offline = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (offline && request.url.path.contains('user_saved_locations')) {
      throw http.ClientException('QA unavailable');
    }
    return inner.send(request);
  }

  @override
  void close() {
    inner.close();
  }
}
