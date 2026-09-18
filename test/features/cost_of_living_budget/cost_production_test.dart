import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart';

import '../infrastructure_coverage/infrastructure_behavior_test.dart'
    show GeoFixture, location;

final class Prices implements CostPublicReader {
  Duration delay = Duration.zero;
  int monthCount = 12;
  bool baselineMissing = false;
  bool offline = false;
  bool narrow = false;
  bool dateMismatch = false;
  bool cpiMissing = false;
  @override
  Future<Map<String, Object?>> read(String state, String district) async {
    await Future<void>.delayed(delay);
    if (offline) {
      throw StateError('Offline');
    }
    final List<Map<String, Object?>> baseline = <Map<String, Object?>>[];
    final List<Map<String, Object?>> months = <Map<String, Object?>>[];
    final Map<int, double> quantities = <int, double>{
      1: 2,
      16: 2,
      118: 3,
      224: 4,
      272: 4,
      904: 0.5,
      918: 2,
      1589: 1,
      1605: 1,
      1645: 1,
      1541: 1,
    };
    for (final int item in quantities.keys) {
      baseline.add(<String, Object?>{
        'item_code': item,
        'name': 'Item $item',
        'unit': 'unit',
        'expected_unit': 'unit',
        'quantity': quantities[item],
        'national_price': baselineMissing && item == 272 ? null : 10,
      });
      for (int month = 1; month <= monthCount; month++) {
        if (narrow && item != 1) {
          continue;
        }
        months.add(<String, Object?>{
          'item_code': item,
          'month': '2026-${month.toString().padLeft(2, '0')}-01',
          'price': 20,
          'premises': 2,
          'records': 3,
        });
      }
    }
    return <String, Object?>{
      'basket_version': 'cost-basket-v1',
      'source_date': dateMismatch && district == 'Other'
          ? '2026-11-30'
          : '2026-12-31',
      'baseline': baseline,
      'months': months,
      'district_income': 1000,
      'cpi': cpiMissing
          ? null
          : <String, Object?>{
              'date': '2026-12-01',
              'state_index': 120,
              'national_index': 100,
            },
    };
  }
}

final class BudgetReader implements CurrentBudgetReader {
  BudgetScenario? scenario;
  @override
  Future<BudgetScenariosOutcome> readCurrent() async {
    final BudgetScenario? s = scenario;
    if (s == null) {
      return BudgetScenariosAvailable(
        scenarios: <BudgetScenario>[],
        current: const NoCurrentBudgetScenario(version: 0),
      );
    }
    return BudgetScenariosAvailable(
      scenarios: <BudgetScenario>[s],
      current: CurrentBudgetScenarioAvailable(scenario: s, version: s.version),
    );
  }

  @override
  Stream<BudgetScenariosOutcome> watchCurrent() {
    return const Stream<BudgetScenariosOutcome>.empty();
  }
}

void main() {
  test('fixed national basket index uses observed monthly amount and no default scenario', () async {
    final CostOfLivingBudget service = createCostOfLivingBudget(
      geographicContext: GeoFixture(),
      reader: Prices(),
    );
    final CostAnalysisAvailable outcome = await service.analyse(
      const CostAnalysisRequest(
        location: location,
        refreshPolicy: CostRefreshPolicy.refresh,
      ),
    ) as CostAnalysisAvailable;
    expect(outcome.analysis.observedSpend12, 430);
    expect(outcome.analysis.costIndex, 200);
    expect(outcome.analysis.scenarioSpend12, isNull);
    final CpiEquivalentAvailable cpi = await service.calculateCpiEquivalent(
      const CpiEquivalentRequest(
        location: location,
        inputMonthlySpendRm: 1000,
        refreshPolicy: CostRefreshPolicy.cacheAllowed,
      ),
    ) as CpiEquivalentAvailable;
    expect(cpi.reading.equivalentRm, 1200);
  });
  test('zero housing and transport permit pressure; household gross never replaces net income', () async {
    final BudgetReader budget = BudgetReader();
    budget.scenario = BudgetScenario(
      id: 'saved',
      name: 'Current',
      housingExpenseRm: 100,
      transportExpenseRm: 0,
      monthlyNetIncomeRm: 1000,
      householdMonthlyIncomeRm: 99999,
      isCurrent: true,
      updatedAt: DateTime.utc(2026),
      version: 1,
    );
    final CostOfLivingBudget service = createCostOfLivingBudget(
      geographicContext: GeoFixture(),
      reader: Prices(),
      budget: budget,
    );
    final CostAnalysisAvailable result = await service.analyse(
      const CostAnalysisRequest(
        location: location,
        refreshPolicy: CostRefreshPolicy.refresh,
      ),
    ) as CostAnalysisAvailable;
    expect(result.analysis.scenarioSpend12, 530);
    expect(result.analysis.personalBudgetBurden, 53);
    expect(result.analysis.locationBudgetBurden, 53);
    budget.scenario = BudgetScenario(
      id: 'saved',
      name: 'Missing net',
      housingExpenseRm: 0,
      transportExpenseRm: 0,
      householdMonthlyIncomeRm: 99999,
      isCurrent: true,
      updatedAt: DateTime.utc(2026),
      version: 2,
    );
    final CostAnalysisAvailable missing = await service.analyse(
      const CostAnalysisRequest(
        location: location,
        refreshPolicy: CostRefreshPolicy.refresh,
      ),
    ) as CostAnalysisAvailable;
    expect(missing.analysis.scenarioSpend12, 430);
    expect(missing.analysis.personalBudgetBurden, isNull);
  });
  test('incomplete market observations generate labelled partial index and pressure', () async {
    final Prices prices = Prices();
    prices.monthCount = 5;
    final CostOfLivingBudget service = createCostOfLivingBudget(
      geographicContext: GeoFixture(),
      reader: prices,
    );
    final CostAnalysisPartial five = await service.analyse(
      const CostAnalysisRequest(
        location: location,
        refreshPolicy: CostRefreshPolicy.refresh,
      ),
    ) as CostAnalysisPartial;
    expect(five.analysis.observedSpend12, 430);
    expect(five.analysis.costIndex, 200);
    prices.monthCount = 6;
    expect(
      await service.analyse(
        const CostAnalysisRequest(
          location: location,
          refreshPolicy: CostRefreshPolicy.refresh,
        ),
      ),
      isA<CostAnalysisAvailable>(),
    );
    prices.narrow = true;
    prices.monthCount = 12;
    final CostAnalysisPartial narrow = await service.analyse(
      const CostAnalysisRequest(
        location: location,
        refreshPolicy: CostRefreshPolicy.refresh,
      ),
    ) as CostAnalysisPartial;
    expect(narrow.analysis.observedSpend12, 40);
    expect(narrow.analysis.costIndex, 200);
    expect(narrow.analysis.coverage, lessThan(0.8));
    prices.narrow = false;
    prices.baselineMissing = true;
    final CostAnalysisPartial incomplete = await service.analyse(
      const CostAnalysisRequest(
        location: location,
        refreshPolicy: CostRefreshPolicy.refresh,
      ),
    ) as CostAnalysisPartial;
    expect(incomplete.analysis.coverage, 1);
    expect(incomplete.analysis.costIndex, 200);
    expect(incomplete.analysis.isPartialBasket, isTrue);
    expect(incomplete.analysis.indexedItemCount, 10);
  });
  test(
    'partial basket allows labelled budget pressure with complete inputs',
    () async {
      final Prices prices = Prices();
      prices.baselineMissing = true;
      final BudgetReader budget = BudgetReader();
      budget.scenario = BudgetScenario(
        id: 'partial',
        name: 'Partial basket',
        housingExpenseRm: 100,
        transportExpenseRm: 0,
        monthlyNetIncomeRm: 1000,
        isCurrent: true,
        updatedAt: DateTime.utc(2026),
        version: 1,
      );
      final CostOfLivingBudget service = createCostOfLivingBudget(
        geographicContext: GeoFixture(),
        reader: prices,
        budget: budget,
      );
      final CostAnalysisPartial result = await service.analyse(
        const CostAnalysisRequest(
          location: location,
          refreshPolicy: CostRefreshPolicy.refresh,
        ),
      ) as CostAnalysisPartial;
      expect(result.analysis.scenarioSpend12, 450);
      expect(result.analysis.personalBudgetBurden, 45);
      expect(result.analysis.locationBudgetBurden, 45);
    },
  );
  test('cached public inputs recover offline without persisting a personal scenario', () async {
    sqfliteFfiInit();
    final Database db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    DateTime now = DateTime.utc(2026, 9, 18);
    final Prices prices = Prices();
    final BudgetReader budget = BudgetReader();
    final CostOfLivingBudget service = createCostOfLivingBudget(
      geographicContext: GeoFixture(),
      reader: prices,
      budget: budget,
      database: db,
      clock: () {
        return now;
      },
    );
    await service.analyse(
      const CostAnalysisRequest(
        location: location,
        refreshPolicy: CostRefreshPolicy.refresh,
      ),
    );
    prices.offline = true;
    expect(
      await service.analyse(
        const CostAnalysisRequest(
          location: location,
          refreshPolicy: CostRefreshPolicy.refresh,
        ),
      ),
      isA<CostAnalysisAvailable>(),
    );
    now = now.add(const Duration(days: 3));
    expect(
      await service.analyse(
        const CostAnalysisRequest(
          location: location,
          refreshPolicy: CostRefreshPolicy.cacheAllowed,
        ),
      ),
      isA<CostAnalysisUnavailable>(),
    );
    await db.close();
  });

  test(
    'overflowing temporary conversion never exposes a nonfinite RM amount',
    () async {
      final CostOfLivingBudget service = createCostOfLivingBudget(
        geographicContext: GeoFixture(),
        reader: Prices(),
      );
      expect(
        await service.calculateCpiEquivalent(
          const CpiEquivalentRequest(
            location: location,
            inputMonthlySpendRm: 1.7e308,
            refreshPolicy: CostRefreshPolicy.refresh,
          ),
        ),
        isA<CpiEquivalentUnavailable>(),
      );
    },
  );
}
