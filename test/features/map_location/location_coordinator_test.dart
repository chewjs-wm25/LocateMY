import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';

void main() {
  test(
    'older outside result cannot replace a newer valid selection outcome',
    () async {
      final Completer<bool> pending = Completer<bool>();
      final LocationCoordinator map = createLocationCoordinator(
        accountId: 'a',
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
  test(
    'failed online save is never replayed when connectivity returns',
    () async {
      final MemoryStorage storage = MemoryStorage()..offline = true;
      final LocationCoordinator map = createLocationCoordinator(
        accountId: 'a',
        validatePoint: (GeographicPoint point) async {
          return true;
        },
        storage: storage,
      );
      final LocationSelected selected = await map.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
      ) as LocationSelected;
      expect(
        await map.save(
          SaveLocationRequest(location: selected.location, name: 'Offline'),
        ),
        isA<SavedLocationRejected>(),
      );
      expect(storage.remote, isEmpty);
      storage.offline = false;
      expect(
        (await map.loadSavedLocations() as SavedLocationsAvailable).locations,
        isEmpty,
      );
      expect(storage.remote, isEmpty);
      expect(
        await map.save(
          SaveLocationRequest(location: selected.location, name: 'Online'),
        ),
        isA<SavedLocationSaved>(),
      );
      expect(storage.remote, hasLength(1));
      storage.offline = true;
      expect(await map.loadSavedLocations(), isA<SavedLocationsUnavailable>());
    },
  );
  test('saved name length follows SQL Unicode characters', () async {
    final LocationCoordinator map = createLocationCoordinator(
      accountId: 'a',
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
    final LocationCoordinator map = createLocationCoordinator(
      accountId: 'a',
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
    final LocationCoordinator map = createLocationCoordinator(
      accountId: 'a',
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
      final LocationCoordinator map = createLocationCoordinator(
        accountId: 'a',
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
    'offline delete keeps item and remote tombstone prevents resurrection',
    () async {
      final MemoryStorage store = MemoryStorage();
      final LocationCoordinator map = createLocationCoordinator(
        accountId: 'a',
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
        SavedLocationFailure.retryableUnavailable,
      );
      expect(store.remote.single.deleted, false);
      store.offline = false;
      expect(
        await map.deleteSavedLocation(saved.savedLocation.id),
        isA<SavedLocationSaved>(),
      );
      expect(
        (await map.loadSavedLocations() as SavedLocationsAvailable).locations,
        isEmpty,
      );
    },
  );

  test(
    'concurrent saves retain both records through the public saved snapshot',
    () async {
      final MemoryStorage store = MemoryStorage();
      final LocationCoordinator map = createLocationCoordinator(
        accountId: 'a',
        validatePoint: (_) async => true,
        storage: store,
      );
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
        (await map.loadSavedLocations() as SavedLocationsAvailable).locations
            .map((s) => s.name)
            .toSet(),
        {'One', 'Two'},
      );
    },
  );
  test('an issued immutable reference stays saveable after another point is selected', () async {
    final MemoryStorage store = MemoryStorage();
    final LocationCoordinator map = createLocationCoordinator(
      accountId: 'a',
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
}

class MemoryStorage implements LocationStorage {
  bool offline = false;
  List<SavedRecord> remote = [];
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
      ),
    );
    remote.add(row);
    return row;
  }

  @override
  Future<SavedRecord> deleteRemote(SavedRecord record) async {
    if (offline) {
      throw SavedLocationFailure.retryableUnavailable;
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
