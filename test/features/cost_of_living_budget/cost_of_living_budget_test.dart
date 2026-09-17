import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart';
import 'package:locatemy/features/map_location/map_location.dart';

void main() {
  group('CostOfLivingBudgetFake', () {
    late CostOfLivingBudget costOfLiving;

    setUp(() {
      costOfLiving = createFakeCostOfLivingBudget();
    });

    test('analyse returns Available for standard location', () async {
      final location = const ValidLocationReference(
        locationId: 'loc-1',
        point: GeographicPoint(latitude: 3.1390, longitude: 101.6869),
        displayName: 'Kuala Lumpur',
      );

      final outcome = await costOfLiving.analyse(CostAnalysisRequest(
        location: location,
        refreshPolicy: CostRefreshPolicy.cacheAllowed,
      ));

      expect(outcome, isA<CostAnalysisAvailable>());
      final analysis = (outcome as CostAnalysisAvailable).analysis;
      expect(analysis.location.locationId, 'loc-1');
      expect(analysis.basketVersion, 'cost-basket-v1');
    });

    test('analyse returns Unavailable for specific failure ID', () async {
      final location = const ValidLocationReference(
        locationId: 'unavailable',
        point: GeographicPoint(latitude: 0, longitude: 0),
      );

      final outcome = await costOfLiving.analyse(CostAnalysisRequest(
        location: location,
        refreshPolicy: CostRefreshPolicy.cacheAllowed,
      ));

      expect(outcome, isA<CostAnalysisUnavailable>());
    });

    test('calculateCpiEquivalent returns reading', () async {
      final location = const ValidLocationReference(
        locationId: 'loc-1',
        point: GeographicPoint(latitude: 3.1390, longitude: 101.6869),
      );

      final outcome = await costOfLiving.calculateCpiEquivalent(CpiEquivalentRequest(
        location: location,
        inputMonthlySpendRm: 1000,
        refreshPolicy: CostRefreshPolicy.cacheAllowed,
      ));

      expect(outcome, isA<CpiEquivalentAvailable>());
      expect((outcome as CpiEquivalentAvailable).reading.equivalentRm, greaterThan(1000));
    });
  });

  group('BudgetScenarioStoreFake', () {
    late BudgetScenarioStore budgetStore;

    setUp(() {
      budgetStore = createFakeBudgetScenarioStore();
    });

    test('read returns initial default scenario', () async {
      final outcome = await budgetStore.read();
      expect(outcome, isA<BudgetScenariosAvailable>());
      final available = outcome as BudgetScenariosAvailable;
      expect(available.scenarios, isNotEmpty);
      expect(available.current, isA<CurrentBudgetScenarioAvailable>());
    });

    test('create adds new scenario', () async {
      final mutation = await budgetStore.create(const BudgetScenarioDraft(
        name: 'New Scenario',
        housingExpenseRm: 500,
      ));

      expect(mutation, isA<BudgetScenarioMutationSaved>());
      
      final outcome = await budgetStore.read();
      final available = outcome as BudgetScenariosAvailable;
      expect(available.scenarios.any((s) => s.name == 'New Scenario'), isTrue);
    });

    test('selectCurrent updates current scenario', () async {
      final mutation = await budgetStore.create(const BudgetScenarioDraft(
        name: 'Target',
      ));
      final newId = (mutation as BudgetScenarioMutationSaved).scenario.id;

      final selectOutcome = await budgetStore.selectCurrent(newId);
      expect(selectOutcome, isA<BudgetScenarioMutationSaved>());
      
      final readOutcome = await budgetStore.read();
      final current = (readOutcome as BudgetScenariosAvailable).current;
      expect(current, isA<CurrentBudgetScenarioAvailable>());
      expect((current as CurrentBudgetScenarioAvailable).scenario.id, newId);
    });
  });
}
