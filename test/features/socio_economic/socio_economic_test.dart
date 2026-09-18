import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart';
import 'package:locatemy/features/socio_economic/socio_economic.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';

const ValidLocationReference location = ValidLocationReference(
  locationId: 'sunway',
  point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
);

final class GeoFixture implements GeographicContext {
  GeographicLevelOutcome? district;
  bool offline = false;
  @override
  Future<GeographicContextOutcome> resolve(
    GeographicContextRequest request,
  ) async {
    if (offline) {
      return const GeographicContextUnavailable(
        GeographicContextFailure.sourceUnavailable,
      );
    }
    final BoundaryProvenance source = BoundaryProvenance(
      datasetId: 'admin',
      sourceUri: Uri.parse('https://example.com/admin'),
      sourceVersion: 'v1',
      sourceSha256: 'hash',
      derivedGeometrySha256: 'hash',
      importedAt: DateTime.utc(2026),
    );
    return GeographicContextAvailable(<GeographicLevel, GeographicLevelOutcome>{
      GeographicLevel.reportingState: GeographicLevelResolved(
        const AdministrativeArea(
          level: GeographicLevel.reportingState,
          stableId: 'Selangor',
          name: 'Selangor',
          reportingStateId: 'Selangor',
          reportingStateName: 'Selangor',
        ),
        source,
      ),
      GeographicLevel.district:
          district ??
          GeographicLevelResolved(
            const AdministrativeArea(
              level: GeographicLevel.district,
              stableId: 'petaling',
              name: 'Petaling',
              reportingStateId: 'Selangor',
              reportingStateName: 'Selangor',
            ),
            source,
          ),
    });
  }
}

final class ReaderFixture implements SocioInputsReader {
  Map<String, Object?> payload = <String, Object?>{
    'version': 1,
    'income_district': <Object?>[
      <String, Object?>{'date': '2024-01-01', 'income_median': 8210},
    ],
    'income_state': <Object?>[
      <String, Object?>{'date': '2024-01-01', 'income_median': 10100},
    ],
    'gini_district': <Object?>[
      <String, Object?>{'date': '2024-01-01', 'gini': 0.39},
      <String, Object?>{'date': '2023-01-01', 'gini': 0.41},
    ],
    'gini_state': <Object?>[],
    'percentiles': <Object?>[],
  };
  bool offline = false;
  @override
  Future<Map<String, Object?>> read(String state, String? district) async {
    if (offline) {
      throw Exception('offline');
    }
    return payload;
  }
}

final class BudgetFixture implements CurrentBudgetReader {
  double? household = 5050;
  bool unavailable = false;
  bool alternate = false;
  bool _next = false;
  @override
  Future<BudgetScenariosOutcome> readCurrent() async {
    if (unavailable) {
      return const BudgetScenariosUnavailable(
        BudgetScenarioFailure.retryableUnavailable,
      );
    }
    if (alternate) {
      _next = !_next;
      household = _next ? 5000 : 9000;
    }
    final BudgetScenario scenario = BudgetScenario(
      id: 'current',
      name: 'Saved',
      monthlyNetIncomeRm: 99999,
      householdMonthlyIncomeRm: household,
      isCurrent: true,
      updatedAt: DateTime.utc(2026),
      version: 1,
    );
    return BudgetScenariosAvailable(
      scenarios: <BudgetScenario>[scenario],
      current: CurrentBudgetScenarioAvailable(scenario: scenario, version: 1),
    );
  }

  @override
  Stream<BudgetScenariosOutcome> watchCurrent() {
    return const Stream<BudgetScenariosOutcome>.empty();
  }
}

final class RaceReader implements SocioInputsReader {
  final List<Completer<Map<String, Object?>>> pending =
      <Completer<Map<String, Object?>>>[];
  @override
  Future<Map<String, Object?>> read(String state, String? district) {
    final Completer<Map<String, Object?>> request =
        Completer<Map<String, Object?>>();
    pending.add(request);
    return request.future;
  }
}

void main() {
  test('resolved location exposes official district income and absolute annual gini change', () async {
    final SocioEconomic service = createSocioEconomic(
      geographicContext: GeoFixture(),
      reader: ReaderFixture(),
    );
    final SocioAnalysis result = await service.analyse(location);
    expect(result.income?.value, 8210);
    expect(result.income?.year, 2024);
    expect(result.income?.district, 'Petaling');
    expect(result.gini?.value, 0.39);
    expect(result.giniChange, closeTo(-0.02, 0.000001));
    expect(result.distribution, isEmpty);
  });
  test('missing district metrics independently fall back to state while ambiguity does not select a district', () async {
    final GeoFixture geo = GeoFixture();
    geo.district = const GeographicLevelUnresolved(
      GeographicContextFailure.noCoverage,
    );
    final ReaderFixture reader = ReaderFixture();
    reader.payload['income_district'] = <Object?>[];
    reader.payload['gini_state'] = <Object?>[
      <String, Object?>{'date': '2022-01-01', 'gini': 0.4},
    ];
    final SocioAnalysis result = await createSocioEconomic(
      geographicContext: geo,
      reader: reader,
    ).analyse(location);
    expect(result.income?.value, 10100);
    expect(result.income?.district, isNull);
    expect(result.gini?.value, 0.4);
    expect(result.gini?.year, 2022);
    expect(result.district, isNull);
  });

  test('complete percentile observations derive group shares means thresholds and preserve P50', () async {
    final ReaderFixture reader = ReaderFixture();
    final List<Object?> rows = <Object?>[];
    for (int p = 1; p <= 100; p++) {
      int mean = 1000;
      if (p > 80) {
        mean = 10000;
      } else if (p > 40) {
        mean = 3000;
      }
      rows.add(<String, Object?>{
        'date': '2024-01-01',
        'percentile': p,
        'variable': 'mean',
        'income': mean,
      });
      rows.add(<String, Object?>{
        'date': '2024-01-01',
        'percentile': p,
        'variable': 'median',
        'income': p * 100,
      });
    }
    rows.add(<String, Object?>{
      'date': '2024-01-01',
      'percentile': 40,
      'variable': 'maximum',
      'income': 2500,
    });
    rows.add(<String, Object?>{
      'date': '2024-01-01',
      'percentile': 80,
      'variable': 'maximum',
      'income': 7500,
    });
    rows.add(<String, Object?>{
      'date': '2024-01-01',
      'percentile': 100,
      'variable': 'maximum',
      'income': null,
    });
    reader.payload['percentiles'] = rows;
    final SocioAnalysis result = await createSocioEconomic(
      geographicContext: GeoFixture(),
      reader: reader,
    ).analyse(location);
    expect(result.structure?.b40.mean, 1000);
    expect(result.structure?.m40.mean, 3000);
    expect(result.structure?.t20.mean, 10000);
    expect(result.structure?.b40.share, closeTo(1 / 9, 0.000001));
    expect(result.structure?.m40.share, closeTo(1 / 3, 0.000001));
    expect(result.structure?.t20.share, closeTo(5 / 9, 0.000001));
    expect(result.structure?.b40Threshold, 2500);
    expect(result.structure?.m40Threshold, 7500);
    expect(result.distribution.length, 100);
    expect(result.distribution[49], 5000);
    expect(result.distributionYear, 2024);
  });

  test('saved household income interpolates exact observations without clamping and never substitutes net income', () async {
    final ReaderFixture reader = ReaderFixture();
    final List<Object?> rows = <Object?>[];
    for (int p = 1; p <= 100; p++) {
      rows.add(<String, Object?>{
        'date': '2024-01-01',
        'percentile': p,
        'variable': 'median',
        'income': p * 100,
      });
    }
    reader.payload['percentiles'] = rows;
    final BudgetFixture budget = BudgetFixture();
    final SocioEconomic service = createSocioEconomic(
      geographicContext: GeoFixture(),
      reader: reader,
      budget: budget,
    );
    expect((await service.analyse(location)).position?.percentile, 50.5);
    budget.household = 5000;
    expect((await service.analyse(location)).position?.percentile, 50);
    budget.household = 0;
    expect(
      (await service.analyse(location)).position?.boundary,
      IncomePositionBoundary.belowP1,
    );
    budget.household = 10001;
    expect(
      (await service.analyse(location)).position?.boundary,
      IncomePositionBoundary.aboveP100,
    );
    budget.household = null;
    expect((await service.analyse(location)).position, isNull);
    budget.unavailable = true;
    expect((await service.analyse(location)).position, isNull);
    rows.removeAt(49);
    budget.unavailable = false;
    budget.household = 5050;
    expect((await service.analyse(location)).position, isNull);
  });

  test('income and gini prefer a common survey year instead of mixing latest years', () async {
    final ReaderFixture reader = ReaderFixture();
    reader.payload['income_district'] = <Object?>[
      <String, Object?>{'date': '2024-01-01', 'income_median': 8210},
      <String, Object?>{'date': '2022-01-01', 'income_median': 7000},
    ];
    reader.payload['gini_district'] = <Object?>[
      <String, Object?>{'date': '2022-01-01', 'gini': 0.4},
    ];
    final SocioAnalysis result = await createSocioEconomic(
      geographicContext: GeoFixture(),
      reader: reader,
    ).analyse(location);
    expect(result.income?.year, 2022);
    expect(result.income?.value, 7000);
    expect(result.gini?.year, 2022);
  });

  test('public cache survives restart for three days but cannot manufacture income position when offline', () async {
    sqfliteFfiInit();
    final Database database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    DateTime now = DateTime.utc(2026, 9, 17);
    final ReaderFixture reader = ReaderFixture();
    final SocioEconomic service = createSocioEconomic(
      geographicContext: GeoFixture(),
      reader: reader,
      database: database,
      clock: () {
        return now;
      },
    );
    expect((await service.analyse(location)).income?.value, 8210);
    reader.offline = true;
    final SocioEconomic restarted = createSocioEconomic(
      geographicContext: GeoFixture(),
      reader: reader,
      database: database,
      clock: () {
        return now;
      },
    );
    expect((await restarted.analyse(location)).income?.value, 8210);
    now = now.add(const Duration(days: 3));
    expect((await restarted.analyse(location)).income, isNull);
    reader.offline = false;
    expect(
      (await restarted.analyse(location, refresh: true)).income?.value,
      8210,
    );
    await database.close();
  });

  test('A/B exposes differences only for matching survey year scope and boundary version', () async {
    final SocioEconomic service = createSocioEconomic(
      geographicContext: GeoFixture(),
      reader: ReaderFixture(),
    );
    final SocioComparison result = await service.compare(location, location);
    expect(result.incomeDifference, 0);
    expect(result.giniDifference, 0);
    final SocioComparison missing = SocioComparison(
      result.a,
      SocioAnalysis(location: location),
    );
    expect(missing.incomeDifference, isNull);
    final SocioComparison yearMismatch = SocioComparison(
      result.a,
      SocioAnalysis(
        location: location,
        boundaryVersion: 'v1',
        income: const SocioReading(6000, 2022, 'Selangor', 'Petaling'),
      ),
    );
    expect(yearMismatch.incomeDifference, isNull);
    final SocioComparison versionMismatch = SocioComparison(
      result.a,
      SocioAnalysis(
        location: location,
        boundaryVersion: 'v2',
        income: const SocioReading(6000, 2024, 'Selangor', 'Petaling'),
      ),
    );
    expect(versionMismatch.incomeDifference, isNull);
  });

  test('invalid observations cannot appear as official readings and geography failures stay unavailable', () async {
    final ReaderFixture reader = ReaderFixture();
    reader.payload['income_district'] = <Object?>[
      <String, Object?>{'date': '2024-01-01', 'income_median': -1},
    ];
    reader.payload['income_state'] = <Object?>[];
    reader.payload['gini_district'] = <Object?>[
      <String, Object?>{'date': '2024-01-01', 'gini': 1.1},
    ];
    final GeoFixture geo = GeoFixture();
    final SocioEconomic service = createSocioEconomic(
      geographicContext: geo,
      reader: reader,
    );
    final SocioAnalysis invalid = await service.analyse(location);
    expect(invalid.income, isNull);
    expect(invalid.gini, isNull);
    geo.offline = true;
    final SocioAnalysis offline = await service.analyse(location);
    expect(offline.income, isNull);
    expect(offline.failure, isNotNull);
  });

  test('failed refresh never extends public cache expiry', () async {
    sqfliteFfiInit();
    final Database database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    DateTime now = DateTime.utc(2026, 9, 17);
    final ReaderFixture reader = ReaderFixture();
    final SocioEconomic service = createSocioEconomic(
      geographicContext: GeoFixture(),
      reader: reader,
      database: database,
      clock: () {
        return now;
      },
    );
    await service.analyse(location);
    now = now.add(const Duration(days: 2));
    reader.offline = true;
    expect(
      (await service.analyse(location, refresh: true)).income?.value,
      8210,
    );
    now = now.add(const Duration(days: 1));
    expect((await service.analyse(location)).income, isNull);
    await database.close();
  });

  test('offline geographic source uses only an unexpired exact-coordinate public snapshot', () async {
    sqfliteFfiInit();
    final Database database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    final GeoFixture geo = GeoFixture();
    final ReaderFixture reader = ReaderFixture();
    final SocioEconomic service = createSocioEconomic(
      geographicContext: geo,
      reader: reader,
      database: database,
    );
    await service.analyse(location);
    geo.offline = true;
    reader.offline = true;
    expect((await service.analyse(location)).income?.value, 8210);
    const ValidLocationReference other = ValidLocationReference(
      locationId: 'other',
      point: GeographicPoint(latitude: 1.5, longitude: 103.7),
    );
    expect((await service.analyse(other)).income, isNull);
    await database.close();
  });

  test('partial newest curve preserves real observations while income position uses latest complete year', () async {
    final ReaderFixture reader = ReaderFixture();
    final List<Object?> rows = <Object?>[];
    for (int p = 1; p <= 100; p++) {
      rows.add(<String, Object?>{
        'date': '2022-01-01',
        'percentile': p,
        'variable': 'median',
        'income': p * 100,
      });
    }
    rows.add(<String, Object?>{
      'date': '2024-01-01',
      'percentile': 1,
      'variable': 'median',
      'income': 150,
    });
    rows.add(<String, Object?>{
      'date': '2024-01-01',
      'percentile': 50,
      'variable': 'median',
      'income': 5500,
    });
    rows.add(<String, Object?>{
      'date': '2024-01-01',
      'percentile': 100,
      'variable': 'median',
      'income': null,
    });
    reader.payload['percentiles'] = rows;
    final SocioAnalysis result = await createSocioEconomic(
      geographicContext: GeoFixture(),
      reader: reader,
      budget: BudgetFixture(),
    ).analyse(location);
    expect(result.distributionPoints, <int, double>{1: 150, 50: 5500});
    expect(result.distributionYear, 2024);
    expect(result.position?.year, 2022);
    expect(result.position?.percentile, 50.5);
  });

  test('A/B income positions share one saved current snapshot even during a concurrent budget switch', () async {
    final ReaderFixture reader = ReaderFixture();
    final List<Object?> rows = <Object?>[];
    for (int p = 1; p <= 100; p++) {
      rows.add(<String, Object?>{
        'date': '2024-01-01',
        'percentile': p,
        'variable': 'median',
        'income': p * 100,
      });
    }
    reader.payload['percentiles'] = rows;
    final BudgetFixture budget = BudgetFixture();
    budget.alternate = true;
    final SocioComparison result = await createSocioEconomic(
      geographicContext: GeoFixture(),
      reader: reader,
      budget: budget,
    ).compare(location, location);
    expect(result.a.position?.householdIncome, 5000);
    expect(result.b.position?.householdIncome, 5000);
  });

  test('nonmonotonic percentile incomes cannot produce a personal percentile estimate', () async {
    final ReaderFixture reader = ReaderFixture();
    final List<Object?> rows = <Object?>[];
    for (int p = 1; p <= 100; p++) {
      int income = p * 100;
      if (p == 70) {
        income = 10;
      }
      rows.add(<String, Object?>{
        'date': '2024-01-01',
        'percentile': p,
        'variable': 'median',
        'income': income,
      });
    }
    reader.payload['percentiles'] = rows;
    final SocioAnalysis result = await createSocioEconomic(
      geographicContext: GeoFixture(),
      reader: reader,
      budget: BudgetFixture(),
    ).analyse(location);
    expect(result.position, isNull);
  });
  test('late older refresh cannot replace the newer exact-location offline snapshot', () async {
    sqfliteFfiInit();
    final Database database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    final GeoFixture geo = GeoFixture();
    final RaceReader reader = RaceReader();
    final SocioEconomic service = createSocioEconomic(
      geographicContext: geo,
      reader: reader,
      database: database,
    );
    final Future<SocioAnalysis> first = service.analyse(
      location,
      refresh: true,
    );
    while (reader.pending.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    final Future<SocioAnalysis> second = service.analyse(
      location,
      refresh: true,
    );
    while (reader.pending.length < 2) {
      await Future<void>.delayed(Duration.zero);
    }
    final Map<String, Object?> newer = ReaderFixture().payload;
    newer['income_district'] = <Object?>[
      <String, Object?>{'date': '2024-01-01', 'income_median': 9000},
    ];
    reader.pending[1].complete(newer);
    expect((await second).income?.value, 9000);
    reader.pending[0].complete(ReaderFixture().payload);
    await first;
    geo.offline = true;
    expect((await service.analyse(location)).income?.value, 9000);
    await database.close();
  });
  test('official readings prefer a survey year shared with the state distribution when one exists', () async {
    final ReaderFixture reader = ReaderFixture();
    reader.payload['income_district'] = <Object?>[
      <String, Object?>{'date': '2024-01-01', 'income_median': 8210},
      <String, Object?>{'date': '2022-01-01', 'income_median': 7000},
    ];
    reader.payload['gini_district'] = <Object?>[
      <String, Object?>{'date': '2024-01-01', 'gini': 0.39},
      <String, Object?>{'date': '2022-01-01', 'gini': 0.4},
    ];
    final List<Object?> rows = <Object?>[];
    for (int p = 1; p <= 100; p++) {
      rows.add(<String, Object?>{
        'date': '2022-01-01',
        'percentile': p,
        'variable': 'median',
        'income': p * 100,
      });
    }
    reader.payload['percentiles'] = rows;
    final SocioAnalysis result = await createSocioEconomic(
      geographicContext: GeoFixture(),
      reader: reader,
    ).analyse(location);
    expect(result.income?.year, 2022);
    expect(result.gini?.year, 2022);
    expect(result.distributionYear, 2022);
  });
}
