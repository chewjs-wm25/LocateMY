import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/nearby_facilities/nearby_facilities.dart';

void main() {
  testWidgets(
    'available page presents Penpot facility summary, categories and disclosure',
    (WidgetTester tester) async {
      final FacilityAnalysis analysis = FacilityAnalysis(
        location: const ValidLocationReference(
          locationId: 'sunway',
          point: GeographicPoint(latitude: 3, longitude: 101),
          displayName: 'Sunway Mentari',
        ),
        radiusMetres: 2000,
        mappingVersion: 'osm-facility-v1',
        dataState: FacilityDataState.fresh,
        observedAt: DateTime.utc(2026, 9, 17),
        attribution: FacilityAttribution(
          source: '© OpenStreetMap contributors',
          copyrightUrl: Uri.parse('https://www.openstreetmap.org/copyright'),
        ),
        categories: List<FacilityCategoryResult>.generate(5, (int index) {
          return FacilityCategoryResult(
            category: FacilityCategory.values[index],
            state: FacilityCategoryState.completeEmpty,
            nearest: const <NearbyFacility>[],
          );
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: NearbyFacilitiesPage(
            facilities: FakeNearbyFacilities(
              analysisOutcome: FacilityAnalysisAvailable(analysis: analysis),
              comparisonOutcome: const FacilityComparisonUnavailable(
                failure: FacilityFailure.sourceUnavailable,
              ),
              layerOutcome: const FacilityLayerNotPublished(
                failure: FacilityLayerFailure.analysisUnavailable,
              ),
            ),
            location: analysis.location,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('范围内覆盖'), findsOneWidget);
      expect(find.text('0 / 5 类'), findsOneWidget);
      expect(find.text('医疗健康'), findsOneWidget);
      expect(
        find.text('仅显示已收录设施；未收录不代表不存在。', skipOffstage: false),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'changing the public location reloads and ignores a late old response',
    (WidgetTester tester) async {
      final _PageSource source = _PageSource();
      final NearbyFacilities facilities = createNearbyFacilities(
        source: source,
      );
      const ValidLocationReference first = ValidLocationReference(
        locationId: 'a',
        point: GeographicPoint(latitude: 3, longitude: 101),
        displayName: 'Old location',
      );
      const ValidLocationReference second = ValidLocationReference(
        locationId: 'b',
        point: GeographicPoint(latitude: 4, longitude: 101),
        displayName: 'New location',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: NearbyFacilitiesPage(facilities: facilities, location: first),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          home: NearbyFacilitiesPage(facilities: facilities, location: second),
        ),
      );
      await tester.pump();
      expect(source.responses.length, 2);
      source.responses[1].complete(
        OverpassFacilityComplete(
          elements: const <OverpassElement>[],
          queriedAt: DateTime.now(),
        ),
      );
      await tester.pumpAndSettle();
      source.responses[0].complete(
        OverpassFacilityComplete(
          elements: const <OverpassElement>[],
          queriedAt: DateTime.now(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('New location'), findsOneWidget);
      expect(find.text('Old location'), findsNothing);
    },
  );

  testWidgets(
    'failed query keeps attribution, its reason and an actionable copyright link',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NearbyFacilitiesPage(
            facilities: FakeNearbyFacilities(
              analysisOutcome: const FacilityAnalysisUnavailable(
                failure: FacilityFailure.rateLimited,
              ),
              comparisonOutcome: const FacilityComparisonUnavailable(
                failure: FacilityFailure.sourceUnavailable,
              ),
              layerOutcome: const FacilityLayerNotPublished(
                failure: FacilityLayerFailure.analysisUnavailable,
              ),
            ),
            location: const ValidLocationReference(
              locationId: 'a',
              point: GeographicPoint(latitude: 3, longitude: 101),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Too many requests. Try again later.'), findsOneWidget);
      expect(find.text('Data source: OpenStreetMap'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, '© OpenStreetMap contributors'),
        findsOneWidget,
      );
    },
  );

  testWidgets('A/B shares one attribution and disclaimer and permits retry', (
    WidgetTester tester,
  ) async {
    const ValidLocationReference a = ValidLocationReference(
      locationId: 'a',
      point: GeographicPoint(latitude: 3, longitude: 101),
    );
    const ValidLocationReference b = ValidLocationReference(
      locationId: 'b',
      point: GeographicPoint(latitude: 4, longitude: 101),
    );
    final FakeNearbyFacilities facilities = FakeNearbyFacilities(
      analysisOutcome: const FacilityAnalysisUnavailable(
        failure: FacilityFailure.invalidPayload,
      ),
      comparisonOutcome: const FacilityComparisonNotComparable(
        locationA: FacilityAnalysisUnavailable(
          failure: FacilityFailure.invalidPayload,
        ),
        locationB: FacilityAnalysisUnavailable(
          failure: FacilityFailure.invalidPayload,
        ),
        failure: FacilityComparisonFailure.incompleteResult,
      ),
      layerOutcome: const FacilityLayerNotPublished(
        failure: FacilityLayerFailure.analysisUnavailable,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyFacilitiesPage(
          facilities: facilities,
          location: a,
          locationB: b,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('© OpenStreetMap contributors'),
      200,
    );
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Only recorded facilities'),
      100,
    );
    expect(find.textContaining('Only recorded facilities'), findsOneWidget);
    expect(find.text('Data source: OpenStreetMap'), findsNothing);
    facilities.comparisonOutcome = const FacilityComparisonUnavailable(
      failure: FacilityFailure.rateLimited,
    );
    await tester.scrollUntilVisible(find.text('Retry').first, -200);
    await tester.tap(find.text('Retry').first);
    await tester.pumpAndSettle();
    expect(find.text('Too many requests. Try again later.'), findsOneWidget);
  });

  testWidgets(
    'unknown categories suppress definitive coverage and total at 360dp with 200 percent text',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const ValidLocationReference location = ValidLocationReference(
        locationId: 'a',
        point: GeographicPoint(latitude: 3, longitude: 101),
      );
      final FacilityAnalysis analysis = FacilityAnalysis(
        location: location,
        radiusMetres: 2000,
        mappingVersion: 'osm-facility-v1',
        dataState: FacilityDataState.cached,
        observedAt: DateTime.now(),
        attribution: FacilityAttribution(
          source: '© OpenStreetMap contributors',
          copyrightUrl: Uri.parse('https://www.openstreetmap.org/copyright'),
        ),
        categories: List<FacilityCategoryResult>.generate(5, (int index) {
          return FacilityCategoryResult(
            category: FacilityCategory.values[index],
            state: index == 0
                ? FacilityCategoryState.unknown
                : FacilityCategoryState.completeEmpty,
            nearest: const <NearbyFacility>[],
          );
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: NearbyFacilitiesPage(
              location: location,
              facilities: FakeNearbyFacilities(
                analysisOutcome: FacilityAnalysisAvailable(analysis: analysis),
                comparisonOutcome: const FacilityComparisonUnavailable(
                  failure: FacilityFailure.sourceUnavailable,
                ),
                layerOutcome: const FacilityLayerNotPublished(
                  failure: FacilityLayerFailure.analysisIncomplete,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Coverage unknown'), findsOneWidget);
      expect(find.textContaining('/ 5 categories'), findsNothing);
      expect(find.text('0 recorded facilities'), findsNothing);
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}

final class _PageSource implements OverpassFacilitySource {
  final List<Completer<OverpassFacilityOutcome>> responses =
      <Completer<OverpassFacilityOutcome>>[];
  @override
  Future<OverpassFacilityOutcome> query(OverpassFacilityQuery query) {
    final Completer<OverpassFacilityOutcome> response =
        Completer<OverpassFacilityOutcome>();
    responses.add(response);
    return response.future;
  }
}
