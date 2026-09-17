// Explicit constructor follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/nearby_facilities/nearby_facilities.dart';

void main() {
  test(
    'fresh and cached complete layers retain all five facility categories',
    () async {
      final LocationCoordinator map = createLocationCoordinator(
        accountId: 'a',
        validatePoint: (GeographicPoint point) async {
          return true;
        },
      );
      final MapWorkspace workspace = locationWorkspace(map);
      workspace.setViewport('categories');
      final NearbyFacilities facilities = createNearbyFacilities(
        source: _CategorySource(),
        mapLayerHost: () {
          return locationLayerHost(map);
        },
      );
      for (final FacilityRefreshPolicy policy in <FacilityRefreshPolicy>[
        FacilityRefreshPolicy.refresh,
        FacilityRefreshPolicy.cacheAllowed,
      ]) {
        final FacilityAnalysisOutcome outcome = await facilities.analyse(
          FacilityAnalysisRequest(
            location: const ValidLocationReference(
              locationId: 'categories',
              point: GeographicPoint(latitude: 3, longitude: 101),
            ),
            refreshPolicy: policy,
          ),
        );
        final FacilityAnalysis analysis =
            (outcome as FacilityAnalysisAvailable).analysis;
        expect(
          await facilities.contributeLayer(
            FacilityLayerRequest(
              analysis: analysis,
              viewportVersion: 'categories',
            ),
          ),
          isA<FacilityLayerPublished>(),
        );
        expect(
          workspace.visibleLayerItems.map((MapLayerItem item) {
            return item.markerKind;
          }).toSet(),
          <MapMarkerKind>{
            MapMarkerKind.facilityHealth,
            MapMarkerKind.facilityEducation,
            MapMarkerKind.facilityDailyLiving,
            MapMarkerKind.facilityTransport,
            MapMarkerKind.facilityLeisureGreen,
          },
        );
        expect(workspace.visibleLayerItems.length, 5);
        if (policy == FacilityRefreshPolicy.cacheAllowed) {
          expect(analysis.dataState, FacilityDataState.cached);
        }
      }
    },
  );

  testWidgets(
    'a selected Map location publishes facilities for its current viewport',
    (WidgetTester tester) async {
      final LocationCoordinator map = createLocationCoordinator(
        accountId: 'a',
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

final class _CategorySource implements OverpassFacilitySource {
  @override
  Future<OverpassFacilityOutcome> query(OverpassFacilityQuery query) async {
    const List<Map<String, String>> tags = <Map<String, String>>[
      <String, String>{'amenity': 'clinic'},
      <String, String>{'amenity': 'school'},
      <String, String>{'shop': 'supermarket'},
      <String, String>{'highway': 'bus_stop'},
      <String, String>{'leisure': 'park'},
    ];
    final List<OverpassElement> elements = <OverpassElement>[];
    for (int index = 0; index < tags.length; index += 1) {
      elements.add(
        OverpassElement(
          elementType: 'node',
          osmId: '$index',
          representativePoint: const GeographicPoint(
            latitude: 3,
            longitude: 101,
          ),
          tags: tags[index],
        ),
      );
    }
    return OverpassFacilityComplete(
      elements: elements,
      queriedAt: DateTime.now(),
    );
  }
}
