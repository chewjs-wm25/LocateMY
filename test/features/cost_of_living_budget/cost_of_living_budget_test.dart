// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart';
import 'package:locatemy/features/map_location/map_location.dart';

void main() {
  group('Legacy test fixture only (not production evidence)', () {
    late CostOfLivingBudget costOfLiving;

    setUp(() {
      costOfLiving = createFakeCostOfLivingBudget();
    });

    test('analyse returns Available for standard location', () async {
      final ValidLocationReference location = const ValidLocationReference(
        locationId: 'loc-1',
        point: GeographicPoint(latitude: 3.1390, longitude: 101.6869),
        displayName: 'Kuala Lumpur',
      );

      final CostAnalysisOutcome outcome = await costOfLiving.analyse(
        CostAnalysisRequest(
          location: location,
          refreshPolicy: CostRefreshPolicy.cacheAllowed,
        ),
      );

      expect(outcome, isA<CostAnalysisAvailable>());
      final CostAnalysis analysis = (outcome as CostAnalysisAvailable).analysis;
      expect(analysis.location.locationId, 'loc-1');
      expect(analysis.basketVersion, 'cost-basket-v1');
    });

    test('analyse returns Unavailable for specific failure ID', () async {
      final ValidLocationReference location = const ValidLocationReference(
        locationId: 'unavailable',
        point: GeographicPoint(latitude: 0, longitude: 0),
      );

      final CostAnalysisOutcome outcome = await costOfLiving.analyse(
        CostAnalysisRequest(
          location: location,
          refreshPolicy: CostRefreshPolicy.cacheAllowed,
        ),
      );

      expect(outcome, isA<CostAnalysisUnavailable>());
    });
  });

  group('Legacy budget fixture only (not production evidence)', () {
    late BudgetScenarioStore budgetStore;

    setUp(() {
      budgetStore = createFakeBudgetScenarioStore();
    });

    test('read returns initial default scenario', () async {
      final BudgetScenariosOutcome outcome = await budgetStore.read();
      expect(outcome, isA<BudgetScenariosAvailable>());
      final BudgetScenariosAvailable available =
          outcome as BudgetScenariosAvailable;
      expect(available.scenarios, isNotEmpty);
      expect(available.current, isA<CurrentBudgetScenarioAvailable>());
    });

    test('create adds new scenario', () async {
      final BudgetScenarioMutationOutcome mutation = await budgetStore.create(
        const BudgetScenarioDraft(name: 'New Scenario', housingExpenseRm: 500),
      );

      expect(mutation, isA<BudgetScenarioMutationSaved>());

      final BudgetScenariosOutcome outcome = await budgetStore.read();
      final BudgetScenariosAvailable available =
          outcome as BudgetScenariosAvailable;
      expect(available.scenarios.any((s) => s.name == 'New Scenario'), isTrue);
    });

    test('selectCurrent updates current scenario', () async {
      final BudgetScenarioMutationOutcome mutation = await budgetStore.create(
        const BudgetScenarioDraft(name: 'Target'),
      );
      final String newId =
          (mutation as BudgetScenarioMutationSaved).scenario.id;

      final BudgetScenarioMutationOutcome selectOutcome = await budgetStore
          .selectCurrent(newId);
      expect(selectOutcome, isA<BudgetScenarioMutationSaved>());

      final BudgetScenariosOutcome readOutcome = await budgetStore.read();
      final CurrentBudgetScenarioSnapshot current =
          (readOutcome as BudgetScenariosAvailable).current;
      expect(current, isA<CurrentBudgetScenarioAvailable>());
      expect((current as CurrentBudgetScenarioAvailable).scenario.id, newId);
    });

    test('create rejects invalid names and negative amounts', () async {
      final BudgetScenarioMutationOutcome blankResult = await budgetStore
          .create(
            const BudgetScenarioDraft(name: '   ', housingExpenseRm: 400),
          );
      expect(blankResult, isA<BudgetScenarioMutationRejected>());
      expect(
        (blankResult as BudgetScenarioMutationRejected).failure,
        BudgetScenarioFailure.invalidName,
      );

      final BudgetScenarioMutationOutcome invalidAmountResult =
          await budgetStore.create(
            const BudgetScenarioDraft(
              name: 'Bad numbers',
              housingExpenseRm: -10,
            ),
          );
      expect(invalidAmountResult, isA<BudgetScenarioMutationRejected>());
      expect(
        (invalidAmountResult as BudgetScenarioMutationRejected).failure,
        BudgetScenarioFailure.invalidAmount,
      );
    });
  });
}
