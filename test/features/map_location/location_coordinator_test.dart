import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';

void main() {
  test(
    'older outside result cannot replace a newer valid selection outcome',
    () async {
      final AccountScope scope = AccountScope('a');
      final Completer<bool> pending = Completer<bool>();
      final LocationCoordinator map = createLocationCoordinator(
        scope: scope,
        readScope: () => AccountScopeOpened(scope),
        validatePoint: (point) =>
            point.latitude == 3 ? pending.future : Future.value(true),
      );
      final Future<LocationSelectionOutcome> older = map.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
      );
      await map.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 4, longitude: 102),
        ),
      );
      pending.complete(false);
      expect(
        (await older as LocationSelectionRejected).failure,
        LocationSelectionFailure.scopeUnavailable,
      );
      expect(
        (map.read(
          LocationRole.single,
        ) as LocationPresent).location.point.latitude,
        4,
      );
    },
  );
  test('saved name length follows SQL Unicode characters', () async {
    final AccountScope scope = AccountScope('a');
    final LocationCoordinator map = createLocationCoordinator(
      scope: scope,
      readScope: () => AccountScopeOpened(scope),
      validatePoint: (_) async => true,
      storage: MemoryStorage(),
    );
    final LocationSelected selected = await map.select(
      const LocationSelectionRequest(
        role: LocationRole.single,
        point: GeographicPoint(latitude: 3, longitude: 101),
      ),
    ) as LocationSelected;
    expect(
      await map.save(
        SaveLocationRequest(location: selected.location, name: '😀' * 120),
      ),
      isA<SavedLocationSaved>(),
    );
    expect(
      (await map.save(
        SaveLocationRequest(location: selected.location, name: '😀' * 121),
      ) as SavedLocationRejected).failure,
      SavedLocationFailure.invalidName,
    );
  });
  test('validated selection updates only the requested role', () async {
    final AccountScope scope = AccountScope('a');
    final LocationCoordinator map = createLocationCoordinator(
      scope: scope,
      readScope: () => AccountScopeOpened(scope),
      validatePoint: (_) async => true,
    );
    final LocationSelectionOutcome result = await map.select(
      const LocationSelectionRequest(
        role: LocationRole.single,
        point: GeographicPoint(latitude: 3.1, longitude: 101.6),
      ),
    );
    expect(result, isA<LocationSelected>());
    expect(map.read(LocationRole.single), isA<LocationPresent>());
    expect(map.read(LocationRole.locationA), isA<LocationAbsent>());
  });
  test('invalid coordinates preserve the previous validated point', () async {
    final AccountScope scope = AccountScope('a');
    final LocationCoordinator map = createLocationCoordinator(
      scope: scope,
      readScope: () => AccountScopeOpened(scope),
      validatePoint: (_) async => true,
    );
    await map.select(
      const LocationSelectionRequest(
        role: LocationRole.single,
        point: GeographicPoint(latitude: 3, longitude: 101),
      ),
    );
    final LocationSelectionOutcome rejected = await map.select(
      const LocationSelectionRequest(
        role: LocationRole.single,
        point: GeographicPoint(latitude: double.nan, longitude: 101),
      ),
    );
    expect(
      (rejected as LocationSelectionRejected).failure,
      LocationSelectionFailure.invalidCoordinate,
    );
    expect(
      (map.read(
        LocationRole.single,
      ) as LocationPresent).location.point.latitude,
      3,
    );
  });

  test(
    'comparison rejects identical points and swaps immutable references only',
    () async {
      final AccountScope scope = AccountScope('a');
      final LocationCoordinator map = createLocationCoordinator(
        scope: scope,
        readScope: () => AccountScopeOpened(scope),
        validatePoint: (_) async => true,
      );
      const GeographicPoint a = GeographicPoint(latitude: 3, longitude: 101);
      const GeographicPoint b = GeographicPoint(latitude: 5, longitude: 100);
      final LocationSelected selected = await map.select(
        const LocationSelectionRequest(role: LocationRole.locationA, point: a),
      ) as LocationSelected;
      final LocationSelectionOutcome same = await map.select(
        const LocationSelectionRequest(role: LocationRole.locationB, point: a),
      );
      expect(
        (same as LocationSelectionRejected).failure,
        LocationSelectionFailure.sameComparisonPoint,
      );
      await map.select(
        const LocationSelectionRequest(role: LocationRole.locationB, point: b),
      );
      await map.swapComparisonLocations();
      expect(
        identical(
          (map.read(LocationRole.locationB) as LocationPresent).location,
          selected.location,
        ),
        true,
      );
      expect(map.read(LocationRole.single), isA<LocationAbsent>());
    },
  );

  test(
    'late selection cannot overwrite newer selection or reopen closed scope',
    () async {
      final AccountScope scope = AccountScope('a');
      AccountScopeSnapshot current = AccountScopeOpened(scope);
      final Completer<bool> slow = Completer<bool>();
      final LocationCoordinator map = createLocationCoordinator(
        scope: scope,
        readScope: () => current,
        validatePoint: (p) =>
            p.latitude == 3 ? slow.future : Future.value(true),
      );
      final Future<LocationSelectionOutcome> old = map.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
      );
      await map.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 5, longitude: 100),
        ),
      );
      slow.complete(true);
      expect(await old, isA<LocationSelectionRejected>());
      expect(
        (map.read(
          LocationRole.single,
        ) as LocationPresent).location.point.latitude,
        5,
      );
      current = AccountScopeClosing(scope);
      expect(map.read(LocationRole.single), isA<LocationAbsent>());
      expect(
        await map.select(
          const LocationSelectionRequest(
            role: LocationRole.single,
            point: GeographicPoint(latitude: 5, longitude: 100),
          ),
        ),
        isA<LocationSelectionRejected>(),
      );
    },
  );

  test(
    'offline create is durable queued and replay becomes synchronized',
    () async {
      final AccountScope scope = AccountScope('a');
      final MemoryStorage store = MemoryStorage()..offline = true;
      final LocationCoordinator map = createLocationCoordinator(
        scope: scope,
        readScope: () => AccountScopeOpened(scope),
        validatePoint: (_) async => true,
        storage: store,
      );
      final LocationSelected selected = await map.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
      ) as LocationSelected;
      expect(
        await map.save(
          SaveLocationRequest(location: selected.location, name: ' Home '),
        ),
        isA<SavedLocationQueued>(),
      );
      expect(store.local.single.attempts, 1);
      expect(
        store.local.single.lastFailure,
        SavedLocationFailure.retryableUnavailable,
      );
      store.offline = false;
      final LocationCoordinator restarted = createLocationCoordinator(
        scope: scope,
        readScope: () => AccountScopeOpened(scope),
        validatePoint: (_) async => true,
        storage: store,
      );
      final SavedLocationsAvailable synced =
          await restarted.synchronizeSavedLocations()
              as SavedLocationsAvailable;
      expect(synced.locations.single.name, 'Home');
      expect(
        synced.locations.single.syncState,
        SavedLocationSyncState.synchronized,
      );
      expect(
        (await restarted.synchronizeSavedLocations() as SavedLocationsAvailable)
            .locations
            .length,
        1,
      );
    },
  );

  test(
    'offline delete keeps item and remote tombstone prevents resurrection',
    () async {
      final AccountScope scope = AccountScope('a');
      final MemoryStorage store = MemoryStorage();
      final LocationCoordinator map = createLocationCoordinator(
        scope: scope,
        readScope: () => AccountScopeOpened(scope),
        validatePoint: (_) async => true,
        storage: store,
      );
      final LocationSelected selected = await map.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
      ) as LocationSelected;
      final SavedLocationSaved saved = await map.save(
        SaveLocationRequest(location: selected.location, name: 'Home'),
      ) as SavedLocationSaved;
      store.offline = true;
      expect(
        (await map.deleteSavedLocation(
          saved.savedLocation.id,
        ) as SavedLocationRejected).failure,
        SavedLocationFailure.offlineDeleteUnsupported,
      );
      expect(store.local.single.deleted, false);
      store.offline = false;
      expect(
        await map.deleteSavedLocation(saved.savedLocation.id),
        isA<SavedLocationSaved>(),
      );
      expect(
        (await map.synchronizeSavedLocations() as SavedLocationsAvailable)
            .locations,
        isEmpty,
      );
    },
  );

  test(
    'privacy participant clears queue and roles without deleting remote',
    () async {
      final AccountScope scope = AccountScope('a');
      final MemoryStorage store = MemoryStorage();
      final LocationCoordinator map = createLocationCoordinator(
        scope: scope,
        readScope: () => AccountScopeOpened(scope),
        validatePoint: (_) async => true,
        storage: store,
      );
      final LocationSelected selected = await map.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
      ) as LocationSelected;
      await map.save(
        SaveLocationRequest(location: selected.location, name: 'Home'),
      );
      expect(
        await locationPrivacyParticipant(map).clearPrivateState(scope),
        isA<PrivateStateCleared>(),
      );
      expect(map.read(LocationRole.single), isA<LocationAbsent>());
      expect(store.local, isEmpty);
      expect(store.remote.length, 1);
    },
  );
  test(
    'concurrent saves retain both records through the public saved snapshot',
    () async {
      final AccountScope scope = AccountScope('a');
      final MemoryStorage store = MemoryStorage();
      final LocationCoordinator map = createLocationCoordinator(
        scope: scope,
        readScope: () => AccountScopeOpened(scope),
        validatePoint: (_) async => true,
        storage: store,
      );
      store.offline = true;
      final LocationSelected selected = await map.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
      ) as LocationSelected;
      await Future.wait([
        map.save(SaveLocationRequest(location: selected.location, name: 'One')),
        map.save(SaveLocationRequest(location: selected.location, name: 'Two')),
      ]);
      store.offline = false;
      expect(
        (await map.synchronizeSavedLocations() as SavedLocationsAvailable)
            .locations
            .map((s) => s.name)
            .toSet(),
        {'One', 'Two'},
      );
    },
  );
  test('an issued immutable reference stays saveable after another point is selected', () async {
    final AccountScope scope = AccountScope('a');
    final MemoryStorage store = MemoryStorage();
    final LocationCoordinator map = createLocationCoordinator(
      scope: scope,
      readScope: () => AccountScopeOpened(scope),
      validatePoint: (_) async => true,
      storage: store,
    );
    final LocationSelected first = await map.select(
      const LocationSelectionRequest(
        role: LocationRole.single,
        point: GeographicPoint(latitude: 3, longitude: 101),
      ),
    ) as LocationSelected;
    await map.select(
      const LocationSelectionRequest(
        role: LocationRole.single,
        point: GeographicPoint(latitude: 5, longitude: 100),
      ),
    );
    expect(
      await map.save(
        SaveLocationRequest(location: first.location, name: 'First'),
      ),
      isA<SavedLocationSaved>(),
    );
  });

  test('offline restart exposes queued records while reporting synchronization failure', () async {
    final AccountScope scope = AccountScope('a');
    final MemoryStorage store = MemoryStorage()..offline = true;
    final LocationCoordinator map = createLocationCoordinator(
      scope: scope,
      readScope: () => AccountScopeOpened(scope),
      validatePoint: (_) async => true,
      storage: store,
    );
    final LocationSelected selected = await map.select(
      const LocationSelectionRequest(
        role: LocationRole.single,
        point: GeographicPoint(latitude: 3, longitude: 101),
      ),
    ) as LocationSelected;
    await map.save(
      SaveLocationRequest(location: selected.location, name: 'Queued'),
    );
    final LocationCoordinator restarted = createLocationCoordinator(
      scope: scope,
      readScope: () => AccountScopeOpened(scope),
      validatePoint: (_) async => true,
      storage: store,
    );
    final List<SavedLocationsSnapshot> states = await restarted
        .watchSavedLocations()
        .take(2)
        .toList()
        .timeout(const Duration(seconds: 2));
    expect(
      (states.first as SavedLocationsAvailable).locations.single.syncState,
      SavedLocationSyncState.queued,
    );
    expect(states.last, isA<SavedLocationsUnavailable>());
  });
  test('privacy recovery clears the immutable account id even with a restored scope token', () async {
    final AccountScope scope = AccountScope('a');
    final MemoryStorage store = MemoryStorage();
    final LocationCoordinator map = createLocationCoordinator(
      scope: scope,
      readScope: () => AccountScopeOpened(scope),
      validatePoint: (_) async => true,
      storage: store,
    );
    await map.select(
      const LocationSelectionRequest(
        role: LocationRole.single,
        point: GeographicPoint(latitude: 3, longitude: 101),
      ),
    );
    expect(
      await locationPrivacyParticipant(map)
          .clearPrivateState(const AccountScope('a')),
      isA<PrivateStateCleared>(),
    );
    expect(map.read(LocationRole.single), isA<LocationAbsent>());
  });
}

class MemoryStorage implements LocationStorage {
  bool offline = false;
  List<SavedRecord> local = [], remote = [];
  @override
  Future<List<SavedRecord>> readLocal() async {
    return List.of(local);
  }

  @override
  Future<void> writeLocal(List<SavedRecord> records) async {
    local = List.of(records);
  }

  @override
  Future<void> clearLocal() async {
    local.clear();
  }

  @override
  Future<List<SavedRecord>> readRemote() async {
    if (offline) {
      throw SavedLocationFailure.retryableUnavailable;
    }
    return List.of(remote);
  }

  @override
  Future<SavedRecord> createRemote(SavedRecord record) async {
    if (offline) {
      throw SavedLocationFailure.retryableUnavailable;
    }
    final Iterable<SavedRecord> existing = remote.where(
      (r) => r.clientKey == record.clientKey,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }
    final SavedRecord row = SavedRecord(
      clientKey: record.clientKey,
      version: 1,
      saved: SavedLocation(
        id: record.saved.id,
        name: record.saved.name,
        location: record.saved.location,
        createdAt: record.saved.createdAt,
        syncState: SavedLocationSyncState.synchronized,
      ),
    );
    remote.add(row);
    return row;
  }

  @override
  Future<SavedRecord> deleteRemote(SavedRecord record) async {
    if (offline) {
      throw SavedLocationFailure.offlineDeleteUnsupported;
    }
    final SavedRecord row = SavedRecord(
      saved: record.saved,
      clientKey: record.clientKey,
      version: record.version + 1,
      deleted: true,
    );
    remote.removeWhere((r) => r.clientKey == row.clientKey);
    remote.add(row);
    return row;
  }
}
