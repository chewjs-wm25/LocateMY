import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import 'location_coordinator_test.dart' show MemoryStorage;

void main() {
  test(
    'diagnostics classify outcomes and never include private inputs',
    () async {
      final List<String> lines = <String>[];
      await runZoned(
        () async {
          final DiagnosticStorage store = DiagnosticStorage();
          final LocationCoordinator map = createLocationCoordinator(
            accountId: 'a',
            validatePoint: (_) async => true,
            storage: store,
          );
          final LocationSelected selected = await map.select(
            const LocationSelectionRequest(
              role: LocationRole.single,
              point: GeographicPoint(latitude: 3.0738, longitude: 101.5183),
              displayName: 'private-name',
            ),
          ) as LocationSelected;
          await map.save(
            SaveLocationRequest(location: selected.location, name: ''),
          );
          store.offline = true;
          await map.save(
            SaveLocationRequest(
              location: selected.location,
              name: 'private-name',
            ),
          );
          await map.loadSavedLocations();
          store.offline = false;
          await map.save(
            SaveLocationRequest(
              location: selected.location,
              name: 'private-name',
            ),
          );
          final SavedLocationsAvailable synced =
              await map.loadSavedLocations() as SavedLocationsAvailable;
          store.conflict = true;
          await map.deleteSavedLocation(synced.locations.single.id);
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => lines.add(line),
        ),
      );
      final List<Map<String, dynamic>> events = lines
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      expect(
        events.map((e) => e['result']),
        containsAll([
          'success',
          'invalidName',
          'retryableUnavailable',
          'conflict',
        ]),
      );
      for (final Map<String, dynamic> e in events) {
        expect(e.keys.toSet(), {
          'event',
          'feature',
          'result',
          'duration_bucket',
          'correlation_id',
        });
        expect(e['feature'], 'map_location');
        expect(e['correlation_id'], matches(r'^map-\d+$'));
      }
      for (final String private in [
        'private-account',
        'private-name',
        '3.0738',
        '101.5183',
        'password',
        'token',
        '@',
      ]) {
        expect(lines.join(), isNot(contains(private)));
      }
    },
  );
}

class DiagnosticStorage extends MemoryStorage {
  bool conflict = false, clearFailure = false;
  @override
  Future<SavedRecord> deleteRemote(SavedRecord record) {
    if (conflict) {
      throw SavedLocationFailure.conflict;
    }
    return super.deleteRemote(record);
  }
}
