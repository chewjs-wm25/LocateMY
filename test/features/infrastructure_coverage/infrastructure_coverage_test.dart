import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/infrastructure_coverage/infrastructure_coverage.dart';
import 'package:locatemy/features/map_location/map_location.dart';

void main() {
  final ValidLocationReference location = ValidLocationReference(
    locationId: 'kuala-lumpur',
    point: const GeographicPoint(latitude: 3.139, longitude: 101.686),
    displayName: 'Kuala Lumpur',
  );

  test(
    'service computes a stable infrastructure score with five categories',
    () async {
      final InfrastructureService service = const InfrastructureService();
      final InfrastructureLoadOutcome outcome = await service.fetch(
        location,
        DateTime(2026, 9, 17),
        weights: const InfrastructureWeightSettings(),
      );

      expect(outcome, isA<InfrastructureAvailable>());
      final InfrastructureAvailable available =
          outcome as InfrastructureAvailable;
      expect(available.snapshot.score, inInclusiveRange(0, 100));
      expect(available.snapshot.categories.length, 5);
    },
  );

  testWidgets('page renders coverage and weights UI', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InfrastructureCoveragePage(
          location: location,
          analysisDate: DateTime(2026, 9, 17),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Infrastructure coverage'), findsOneWidget);
    expect(
      find.textContaining('Infrastructure coverage score'),
      findsOneWidget,
    );
    expect(find.text('Infrastructure weights'), findsOneWidget);
  });
}
