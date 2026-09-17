import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/infrastructure_coverage/infrastructure_coverage.dart';
import 'package:locatemy/features/map_location/map_location.dart';

void main() {
  final ValidLocationReference location = ValidLocationReference(
    locationId: 'test',
    point: const GeographicPoint(latitude: 3.139, longitude: 101.686),
  );
  test('public coverage snapshot owns immutable statistical year maps', () {
    final Map<String, int> sourceYears = <String, int>{'schools': 2025};
    final Map<String, int> populationYears = <String, int>{'education': 2024};
    final InfrastructureCoverage snapshot = InfrastructureCoverage(
      score: null,
      location: location,
      analysisDate: DateTime(2026),
      weights: const InfrastructureWeightSettings(),
      categories: const <InfrastructureCategoryScore>[],
      sourceYears: sourceYears,
      populationYears: populationYears,
    );
    sourceYears['schools'] = 2000;
    populationYears.clear();
    expect(snapshot.sourceYears, <String, int>{'schools': 2025});
    expect(snapshot.populationYears, <String, int>{'education': 2024});
    expect(
      () => snapshot.sourceYears['schools'] = 2001,
      throwsUnsupportedError,
    );
    expect(() => snapshot.populationYears.clear(), throwsUnsupportedError);
  });
  test('ICI uses known zeros and full precision before final rounding', () {
    final InfrastructureCoverage result = InfrastructureService.evaluate(
      location,
      DateTime(2026),
      <String, double?>{
        'water': 100,
        'power': 0,
        'health': 60,
        'education': null,
        'transit': null,
      },
      const InfrastructureWeightSettings(),
    );
    expect(result.score, 53);
    expect(result.missingCategories, <String>['education', 'transit']);
  });
  test('60 percent gate counts baseline categories independently of personal priorities', () {
    final InfrastructureCoverage result = InfrastructureService.evaluate(
      location,
      DateTime(2026),
      <String, double?>{'water': 100, 'power': 100},
      const InfrastructureWeightSettings(
        health: 10,
        education: 10,
        transit: 10,
      ),
    );
    expect(result.score, isNull);
    final InfrastructureCoverage three = InfrastructureService.evaluate(
      location,
      DateTime(2026),
      <String, double?>{'water': 100, 'power': 0, 'health': 60},
      const InfrastructureWeightSettings(health: 1),
    );
    expect(three.score, 51);
  });
  test('priority outside 1 to 10 is rejected', () {
    expect(
      () => InfrastructureService.evaluate(
        location,
        DateTime(2026),
        <String, double?>{},
        const InfrastructureWeightSettings(health: 0),
      ),
      throwsArgumentError,
    );
  });
}
