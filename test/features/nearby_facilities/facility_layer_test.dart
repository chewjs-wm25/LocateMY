// Explicit constructor follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/nearby_facilities/nearby_facilities.dart';

void main() {
  test('real Map accepts complete snapshot, rejects stale viewport and closed scope', () async {
    final AccountScope scope = AccountScope('a');
    AccountScopeSnapshot current = AccountScopeOpened(scope);
    final LocationCoordinator map = createLocationCoordinator(
      scope: scope,
      readScope: () {
        return current;
      },
      validatePoint: (GeographicPoint point) async {
        return true;
      },
    );
    final MapWorkspace workspace = locationWorkspace(map);
    const String viewport = 'current';
    workspace.setViewport(viewport);
    final NearbyFacilities facilities = createNearbyFacilities(
      source: _Source(),
      scopeToken: () {
        if (current is AccountScopeOpened) {
          return scope;
        }
        return null;
      },
      mapLayerHost: () {
        return locationLayerHost(map);
      },
    );
    final FacilityAnalysisOutcome result = await facilities.analyse(
      const FacilityAnalysisRequest(
        location: ValidLocationReference(
          locationId: 'a',
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
        refreshPolicy: FacilityRefreshPolicy.refresh,
      ),
    );
    final FacilityAnalysis analysis =
        (result as FacilityAnalysisAvailable).analysis;
    expect(
      await facilities.contributeLayer(
        FacilityLayerRequest(analysis: analysis, viewportVersion: viewport),
      ),
      isA<FacilityLayerPublished>(),
    );
    expect(workspace.visibleLayerItems.length, 1);
    expect(
      (await facilities.contributeLayer(
        FacilityLayerRequest(analysis: analysis, viewportVersion: 'old'),
      ) as FacilityLayerNotPublished).failure,
      FacilityLayerFailure.staleViewport,
    );
    current = AccountScopeClosing(scope);
    expect(
      (await facilities.contributeLayer(
        FacilityLayerRequest(analysis: analysis, viewportVersion: viewport),
      ) as FacilityLayerNotPublished).failure,
      FacilityLayerFailure.scopeUnavailable,
    );
  });
  testWidgets(
    'a selected Map location publishes facilities for its current viewport',
    (WidgetTester tester) async {
      final AccountScope scope = AccountScope('a');
      final LocationCoordinator map = createLocationCoordinator(
        scope: scope,
        readScope: () {
          return AccountScopeOpened(scope);
        },
        validatePoint: (GeographicPoint point) async {
          return true;
        },
      );
      final MapWorkspace workspace = locationWorkspace(map);
      workspace.setViewport('current');
      await map.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
      );
      final ValueNotifier<String?> viewport = ValueNotifier<String?>('current');
      final Completer<OverpassFacilityOutcome> second =
          Completer<OverpassFacilityOutcome>();
      final NearbyFacilities facilities = createNearbyFacilities(
        source: _Source(second: second),
        mapLayerHost: () {
          return locationLayerHost(map);
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: NearbyFacilitiesMapPanel(
            facilities: facilities,
            locations: map,
            workspace: workspace,
            viewport: viewport,
            child: const Text('Map host'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(workspace.visibleLayerItems.single.stableItemId, 'node_1');
      await map.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 4, longitude: 101),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(workspace.visibleLayerItems, isEmpty);
      second.complete(
        OverpassFacilityComplete(
          elements: const <OverpassElement>[
            OverpassElement(
              elementType: 'node',
              osmId: '2',
              representativePoint: GeographicPoint(latitude: 4, longitude: 101),
              tags: <String, String>{'amenity': 'clinic'},
            ),
          ],
          queriedAt: DateTime.now(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(workspace.visibleLayerItems.single.stableItemId, 'node_2');
      await tester.pumpWidget(const SizedBox());
      viewport.dispose();
    },
  );
  test('unknown categories refuse layer publication with an analysis completeness reason', () async {
    final NearbyFacilities facilities = createNearbyFacilities(
      source: _Source(),
    );
    final FacilityAnalysis analysis = FacilityAnalysis(
      location: const ValidLocationReference(
        locationId: 'a',
        point: GeographicPoint(latitude: 3, longitude: 101),
      ),
      radiusMetres: 2000,
      mappingVersion: 'osm-facility-v1',
      dataState: FacilityDataState.fresh,
      observedAt: DateTime.now(),
      attribution: FacilityAttribution(
        source: '© OpenStreetMap contributors',
        copyrightUrl: Uri.parse('https://www.openstreetmap.org/copyright'),
      ),
      categories: const <FacilityCategoryResult>[
        FacilityCategoryResult(
          category: FacilityCategory.health,
          state: FacilityCategoryState.unknown,
          nearest: <NearbyFacility>[],
        ),
      ],
    );
    final FacilityLayerOutcome result = await facilities.contributeLayer(
      FacilityLayerRequest(analysis: analysis, viewportVersion: 'current'),
    );
    expect(
      (result as FacilityLayerNotPublished).failure,
      FacilityLayerFailure.analysisIncomplete,
    );
  });
}

final class _Source implements OverpassFacilitySource {
  final Completer<OverpassFacilityOutcome>? second;
  _Source({Completer<OverpassFacilityOutcome>? second}) : second = second;
  @override
  Future<OverpassFacilityOutcome> query(OverpassFacilityQuery query) async {
    final Completer<OverpassFacilityOutcome>? pending = second;
    if (query.centre.latitude == 4 && pending != null) {
      return pending.future;
    }
    return OverpassFacilityComplete(
      elements: const <OverpassElement>[
        OverpassElement(
          elementType: 'node',
          osmId: '1',
          representativePoint: GeographicPoint(latitude: 3, longitude: 101),
          tags: <String, String>{'amenity': 'clinic'},
        ),
      ],
      queriedAt: DateTime.now(),
    );
  }
}
