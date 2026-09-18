import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/public_transportation/public_transportation.dart';

void main() {
  testWidgets('page presents an available score as a coverage reading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PublicTransportationPage(
          transportation: _Transit(),
          location: _location,
          analysisDate: DateTime(2026, 9, 17),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Public transportation'), findsOneWidget);
    expect(find.text('68'), findsOneWidget);
    expect(find.text('Mentari BRT'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Transportation coverage reading;'),
      180,
    );
    expect(
      find.textContaining('Transportation coverage reading;'),
      findsOneWidget,
    );
  });
}

final ValidLocationReference _location = ValidLocationReference(
  locationId: 'sunway',
  point: const GeographicPoint(latitude: 3.07, longitude: 101.60),
  displayName: 'Sunway Mentari',
);

final class _Transit implements PublicTransportation {
  @override
  Future<TransitComparisonOutcome> compare(
    TransitComparisonRequest request,
  ) async {
    throw StateError('Comparison is unused by this single-page fixture');
  }

  @override
  Future<TransitLoadOutcome> load(TransitRequest request) async {
    return TransitAvailable(
      TransitSnapshot(
        location: request.location,
        analysisDate: request.analysisDate,
        radiusMeters: 1500,
        stations: <TransitStation>[
          const TransitStation(
            feedId: 'rapid',
            stopId: 'm1',
            name: 'Mentari BRT',
            point: GeographicPoint(latitude: 3.07, longitude: 101.60),
            type: TransitStationType.bus,
            distanceMeters: 180,
          ),
        ],
        uniqueStopCount: 1,
        nearestDistanceMeters: 180,
        uniqueRouteCount: 4,
        serviceOutcome: TransitServiceOutcome.served,
        score: const TransitScore(68),
        feeds: const <FeedStatus>[],
        provenance: TransitProvenance(
          snapshotId: 's1',
          referenceGridVersion: 'g1',
          generatedAt: DateTime(2026, 9, 15),
        ),
      ),
    );
  }
}
