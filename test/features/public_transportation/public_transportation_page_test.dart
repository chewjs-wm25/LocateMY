import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/l10n/app_localizations.dart';

import 'public_transportation_test.dart' show usableFeeds, partialFeeds;

import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/public_transportation/public_transportation.dart';

void main() {
  for (final bool distanceOnly in <bool>[false, true]) {
    testWidgets('partial score is visible with distance-only=$distanceOnly', (
      WidgetTester tester,
    ) async {
      final PendingReader reader = PendingReader();
      await tester.pumpWidget(
        MaterialApp(
          home: PublicTransportationPage(
            transportation: createPublicTransportation(reader),
            location: const ValidLocationReference(
              locationId: 'partial-score',
              point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
            ),
            analysisDate: DateTime(2026, 9, 17),
          ),
        ),
      );
      final Map<String, Object?> payload = stationPayload('Mentari BRT');
      payload['availability_status'] = 'incomplete';
      payload['feeds'] = partialFeeds();
      if (distanceOnly) {
        // All sources can be usable while the date-specific reference grid is missing.
        payload['feeds'] = usableFeeds();
        payload['score_basis'] = 'distance_only';
      }
      reader.pending['partial-score']!.complete(payload);
      await tester.pumpAndSettle();
      expect(
        find.text('Partial transportation score 68 / 100'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Data is incomplete; available scores use successfully read data.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Distance only; density and route reference data are missing.',
        ),
        distanceOnly ? findsOneWidget : findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final bool hasStops in <bool>[false, true]) {
    testWidgets(
      'known ${hasStops ? 'no active routes' : 'no stops'} renders unscored facts and a centre circle',
      (WidgetTester tester) async {
        final PendingReader reader = PendingReader();
        await tester.pumpWidget(
          MaterialApp(
            home: PublicTransportationPage(
              transportation: createPublicTransportation(reader),
              location: const ValidLocationReference(
                locationId: 'unscored',
                point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
              ),
              analysisDate: DateTime(2026, 9, 17),
            ),
          ),
        );
        final Map<String, Object?> payload = stationPayload('Mentari BRT');
        payload['service_outcome'] = hasStops ? 'no_active_routes' : 'no_stops';
        payload['transit_score'] = null;
        payload['unique_route_count'] = 0;
        if (!hasStops) {
          payload['stations'] = <Object?>[];
          payload['unique_stop_count'] = 0;
          payload['nearest_distance_m'] = null;
        }
        reader.pending['unscored']!.complete(payload);
        await tester.pumpAndSettle();
        expect(
          find.text(
            hasStops
                ? 'Stops present, no active routes on analysis date · score unavailable'
                : 'No stops in radius · score unavailable',
          ),
          findsOneWidget,
        );
        expect(find.text('0'), findsNothing);
        expect(find.text('68'), findsNothing);
        expect(find.text('1.5 km radius'), findsOneWidget);
        expect(
          find.byKey(
            const ValueKey<String>('transit-marker-gtfs_static_ktmb:station'),
          ),
          hasStops ? findsOneWidget : findsNothing,
        );
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'rejected local layer keeps station facts and exposes a retry without drawing rejected markers',
    (WidgetTester tester) async {
      final PendingReader reader = PendingReader();
      await tester.pumpWidget(
        MaterialApp(
          home: PublicTransportationPage(
            transportation: createPublicTransportation(reader),
            location: ValidLocationReference(
              locationId: 'sunway',
              point: const GeographicPoint(
                latitude: 3.0738,
                longitude: 101.6077,
              ),
            ),
            analysisDate: DateTime(2026, 9, 17),
            mapLayerHost: RejectedTransitLayer(),
          ),
        ),
      );
      reader.pending['sunway']!.complete(stationPayload('Mentari BRT'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('The station layer could not be shown. Refresh to retry.'),
        100,
      );
      expect(
        find.text('The station layer could not be shown. Refresh to retry.'),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('transit-marker-gtfs_static_ktmb:station'),
        ),
        findsNothing,
      );
      await tester.scrollUntilVisible(find.text('Mentari BRT'), 100);
      expect(find.text('Mentari BRT'), findsOneWidget);
    },
  );

  testWidgets(
    'real local Map host receives all stations and is cleared after scope closes without changing the global selection',
    (WidgetTester tester) async {
      LocationCoordinator map() {
        return createLocationCoordinator(
          accountId: 'a',
          validatePoint: (GeographicPoint point) async {
            return true;
          },
        );
      }

      final LocationCoordinator global = map();
      final LocationSelected selected = (await global.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
        ),
      )) as LocationSelected;
      final LocationCoordinator local = map();
      final PendingReader reader = PendingReader();
      await tester.pumpWidget(
        MaterialApp(
          home: PublicTransportationPage(
            transportation: createPublicTransportation(reader),
            location: selected.location,
            analysisDate: DateTime(2026, 9, 17),
            mapLayerHost: locationLayerHost(local),
            mapWorkspace: locationWorkspace(local),
          ),
        ),
      );
      reader.pending.values.single.complete(stationPayload('Mentari BRT'));
      await tester.pumpAndSettle();
      final List<MapLayerItem> markers = locationWorkspace(local)
          .visibleLayerItems;
      expect(markers.length, 2);
      expect(
        markers.map((MapLayerItem item) {
          return item.stableItemId;
        }),
        contains('gtfs_static_ktmb:station'),
      );
      expect(
        (global.read(LocationRole.single) as LocationPresent).location,
        same(selected.location),
      );
      expect(locationWorkspace(global).visibleLayerItems, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(locationWorkspace(local).visibleLayerItems, isEmpty);
    },
  );

  testWidgets('failed refresh identifies the retained previous result', (
    WidgetTester tester,
  ) async {
    final PendingReader reader = PendingReader();
    await tester.pumpWidget(
      MaterialApp(
        home: PublicTransportationPage(
          transportation: createPublicTransportation(reader),
          location: ValidLocationReference(
            locationId: 'sunway',
            point: const GeographicPoint(latitude: 3.0738, longitude: 101.6077),
          ),
          analysisDate: DateTime(2026, 9, 17),
        ),
      ),
    );
    reader.pending['sunway']!.complete(stationPayload('Mentari BRT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refresh'));
    await tester.pump();
    reader.pending['sunway']!.complete(<String, Object?>{});
    await tester.pumpAndSettle();
    expect(
      find.text('Refresh failed. Showing the previous successful result.'),
      findsOneWidget,
    );
    expect(find.text('68'), findsOneWidget);
  });

  testWidgets(
    'Chinese page exposes the fixed radius and all coordinate markers without technical metadata',
    (WidgetTester tester) async {
      final PendingReader reader = PendingReader();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PublicTransportationPage(
            transportation: createPublicTransportation(reader),
            location: ValidLocationReference(
              locationId: 'sunway',
              point: const GeographicPoint(
                latitude: 3.0738,
                longitude: 101.6077,
              ),
            ),
            analysisDate: DateTime(2026, 9, 17),
          ),
        ),
      );
      reader.pending['sunway']!.complete(stationPayload('Mentari BRT'));
      await tester.pumpAndSettle();
      expect(find.text('公共交通'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('transit-marker-gtfs_static_ktmb:station'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('test-snapshot'), findsNothing);
      expect(find.textContaining('test-grid'), findsNothing);
      expect(find.textContaining('https://'), findsNothing);
    },
  );

  testWidgets('marker and list selection share a visible station description', (
    WidgetTester tester,
  ) async {
    final PendingReader reader = PendingReader();
    await tester.pumpWidget(
      MaterialApp(
        home: PublicTransportationPage(
          transportation: createPublicTransportation(reader),
          location: ValidLocationReference(
            locationId: 'sunway',
            point: const GeographicPoint(latitude: 3.0738, longitude: 101.6077),
          ),
          analysisDate: DateTime(2026, 9, 17),
        ),
      ),
    );
    reader.pending['sunway']!.complete(stationPayload('Mentari BRT'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('transit-marker-gtfs_static_ktmb:station'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Selected: Mentari BRT'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(
        const ValueKey<String>('transit-station-gtfs_static_ktmb:station'),
      ),
      100,
    );
    await tester.ensureVisible(
      find.byKey(
        const ValueKey<String>('transit-station-gtfs_static_ktmb:station'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('transit-station-gtfs_static_ktmb:station'),
      ),
    );
    await tester.pumpAndSettle();
    final ListTile row = tester.widget<ListTile>(
      find.byKey(
        const ValueKey<String>('transit-station-gtfs_static_ktmb:station'),
      ),
    );
    expect(row.selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'changing location discards an old request and displays the new station',
    (WidgetTester tester) async {
      final PendingReader reader = PendingReader();
      final PublicTransportation transportation = createPublicTransportation(
        reader,
      );
      final DateTime date = DateTime(2026, 9, 17);
      Future<void> open(String id) async {
        await tester.pumpWidget(
          MaterialApp(
            home: PublicTransportationPage(
              transportation: transportation,
              location: ValidLocationReference(
                locationId: id,
                point: const GeographicPoint(
                  latitude: 3.0738,
                  longitude: 101.6077,
                ),
                displayName: id,
              ),
              analysisDate: date,
            ),
          ),
        );
        await tester.pump();
      }

      await open('old');
      await open('new');
      expect(reader.pending.containsKey('new'), isTrue);
      reader.pending['new']!.complete(stationPayload('New station'));
      await tester.pumpAndSettle();
      reader.pending['old']!.complete(stationPayload('Old station'));
      await tester.pumpAndSettle();
      expect(find.text('New station'), findsWidgets);
      expect(find.text('Old station'), findsNothing);
    },
  );
}

final class PendingReader implements TransitAnalysisReader {
  final Map<String, Completer<Map<String, Object?>>> pending =
      <String, Completer<Map<String, Object?>>>{};
  @override
  Future<Map<String, Object?>> readTransitAnalysis(TransitRequest request) {
    final Completer<Map<String, Object?>> response =
        Completer<Map<String, Object?>>();
    pending[request.location.locationId] = response;
    return response.future;
  }
}

Map<String, Object?> stationPayload(String name) {
  return <String, Object?>{
    'availability_status': 'available',
    'service_outcome': 'served',
    'radius_m': 1500,
    'snapshot_id': 'test-snapshot',
    'reference_grid_version': 'test-grid',
    'generated_at': '2026-09-17T00:00:00Z',
    'unique_stop_count': 1,
    'nearest_distance_m': 180,
    'unique_route_count': 1,
    'transit_score': 68,
    'feeds': usableFeeds(),
    'analysis_date': '2026-09-17',
    'latitude': 3.0738,
    'longitude': 101.6077,
    'stations': <Object?>[
      <String, Object?>{
        'feed_id': 'gtfs_static_ktmb',
        'stop_id': 'station',
        'name': name,
        'latitude': 3.0738 + 180 / 111195,
        'longitude': 101.6077,
        'station_type': 'bus',
        'distance_m': 180,
      },
    ],
  };
}

final class RejectedTransitLayer implements MapLayerHost {
  @override
  Future<MapLayerContributionOutcome> contribute(
    MapLayerContribution contribution,
  ) async {
    return const MapLayerRejected(failure: MapLayerFailure.staleViewport);
  }

  @override
  Future<MapLayerIntentOutcome> requestLongPress(GeographicPoint point) async {
    return const MapLayerIntentRejected(
      failure: MapLayerFailure.invalidContribution,
    );
  }
}
