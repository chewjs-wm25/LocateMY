// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/app/location_summary.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/nearby_facilities/nearby_facilities.dart';
import 'package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart';
import 'package:locatemy/features/infrastructure_coverage/infrastructure_coverage.dart';
import 'package:locatemy/l10n/app_localizations.dart';

import '../features/cost_of_living_budget/cost_production_test.dart'
    show Prices;
import '../features/infrastructure_coverage/infrastructure_behavior_test.dart'
    show GeoFixture, Inputs, Transit, Weights, location;
import 'analysis_routes_test.dart'
    show RecordingFacilities, RecordingTransportation;

void main() {
  test('summary consumes real Cost and Infrastructure services, neutral priorities and isolates unavailable providers', () async {
    final Weights weights = Weights();
    final Transit transit = Transit();
    final InfrastructureService infrastructure = createInfrastructureCoverage(
      geographicContext: GeoFixture(),
      reader: Inputs(),
      transportation: transit,
      weightsStore: weights,
    );
    final BusinessLocationSummaryReader summary = BusinessLocationSummaryReader(
      cost: createCostOfLivingBudget(
        geographicContext: GeoFixture(),
        reader: Prices(),
      ),
      facilities: ThrowingFacilities(),
      transportation: RecordingTransportation(),
      infrastructure: infrastructure,
    );
    final DateTime date = DateTime(2026, 9, 18);
    final List<LocationSummaryReading> readings = await summary.read(
      location,
      date,
    );
    expect(readings.length, 5);
    expect(readings[0].english, isNull);
    expect(readings[1].english, contains('200.0 (national reference 100)'));
    expect(readings[2].english, isNull);
    expect(readings[3].english, isNull);
    expect(readings[4].english, contains('ICI'));
    expect(readings[4].english, contains('Missing:'));
    expect(transit.last!.location, location);
    expect(transit.last!.analysisDate, date);
  });

  testWidgets(
    'expanded map reloads summary on coordinates, ignores old completion and supports retry',
    (WidgetTester tester) async {
      final LocationCoordinator map = createLocationCoordinator(
        accountId: 'a',
        validatePoint: (GeographicPoint point) async {
          return true;
        },
      );
      await map.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
      );
      final PendingSummary reader = PendingSummary();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MapLocationPage(
            locations: map,
            layerHost: locationLayerHost(map),
            workspace: locationWorkspace(map),
            onAnalysis: (ValidLocationReference location) {},
            onComparison: (
              ValidLocationReference a,
              ValidLocationReference b,
            ) {},
            onLayerSelected: (MapLayerIntent intent) {},
            search: createLocationSearch(apiKey: ''),
            showTiles: false,
            summaryReader: reader,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Show summary'));
      await tester.tap(find.text('Show summary'));
      await tester.pump();
      expect(reader.requests.length, 1);
      await map.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 4, longitude: 102),
        ),
      );
      await tester.pump();
      expect(reader.requests.length, 2);
      reader.requests[0].complete(<LocationSummaryReading>[
        const LocationSummaryReading(
          LocationSummaryMetric.safety,
          english: 'Old location',
        ),
      ]);
      reader.requests[1].complete(<LocationSummaryReading>[
        const LocationSummaryReading(
          LocationSummaryMetric.safety,
          english: 'New location',
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Old location'), findsNothing);
      expect(find.text('New location'), findsOneWidget);
      await tester.ensureVisible(find.text('Retry summary'));
      await tester.tap(find.text('Retry summary'));
      await tester.pump();
      expect(reader.requests.length, 3);
      await tester.pumpWidget(const SizedBox());
      reader.requests[2].completeError(StateError('late provider failure'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}

final class PendingSummary implements LocationSummaryReader {
  final List<Completer<List<LocationSummaryReading>>> requests =
      <Completer<List<LocationSummaryReading>>>[];
  @override
  Future<List<LocationSummaryReading>> read(
    ValidLocationReference location,
    DateTime date,
  ) {
    final Completer<List<LocationSummaryReading>> result =
        Completer<List<LocationSummaryReading>>();
    requests.add(result);
    return result.future;
  }
}

final class ThrowingFacilities implements NearbyFacilities {
  @override
  Future<FacilityComparisonOutcome> compare(FacilityComparisonRequest request) {
    return RecordingFacilities().compare(request);
  }

  @override
  Future<FacilityLayerOutcome> contributeLayer(FacilityLayerRequest request) {
    return RecordingFacilities().contributeLayer(request);
  }

  @override
  Future<FacilityAnalysisOutcome> analyse(
    FacilityAnalysisRequest request,
  ) async {
    throw StateError('Provider unavailable');
  }
}
