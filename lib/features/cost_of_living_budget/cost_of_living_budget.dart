import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/application/current_budget_reader.dart';
import 'src/data/supabase_current_budget_reader.dart';

import 'package:locatemy/features/map_location/map_location.dart';

import 'src/domain/cost_models.dart';
import 'src/domain/budget_models.dart';
import 'src/application/cost_of_living_budget_fake.dart';
import 'src/application/budget_scenario_store_fake.dart';

export 'src/domain/cost_models.dart';
export 'src/application/current_budget_reader.dart';
export 'src/domain/budget_models.dart';
export 'src/presentation/cost_budget_page.dart';

/// COST-001: The primary interface for Cost of Living analysis.
abstract interface class CostOfLivingBudget {
  Future<CostAnalysisOutcome> analyse(CostAnalysisRequest request);
  Future<CostComparisonOutcome> compare(CostComparisonRequest request);
  Future<CpiEquivalentOutcome> calculateCpiEquivalent(
    CpiEquivalentRequest request,
  );
  void clearTemporaryCpiInput();
}

/// COST-002: The store for managing user budget scenarios.
abstract interface class BudgetScenarioStore {
  Future<BudgetScenariosOutcome> read();
  Stream<BudgetScenariosOutcome> watch();
  Future<BudgetScenarioMutationOutcome> create(BudgetScenarioDraft draft);
  Future<BudgetScenarioMutationOutcome> update(BudgetScenarioUpdate update);
  Future<BudgetScenarioMutationOutcome> selectCurrent(String scenarioId);
  Future<BudgetScenarioMutationOutcome> delete(String scenarioId);
}

/// Factory for creating fake Cost of Living coordinator.
CostOfLivingBudget createFakeCostOfLivingBudget() => CostOfLivingBudgetFake();

/// Factory for creating fake Budget Scenario store.
BudgetScenarioStore createFakeBudgetScenarioStore() =>
    BudgetScenarioStoreFake();

/// Navigation intents consumed by Application Shell.
final class OpenCostIntent {
  final ValidLocationReference location;
  OpenCostIntent({required this.location});
}

final class OpenCostComparisonIntent {
  final ValidLocationReference locationA;
  final ValidLocationReference locationB;
  OpenCostComparisonIntent({required this.locationA, required this.locationB});
}

final class OpenBudgetScenarioIntent {
  OpenBudgetScenarioIntent();
}

CurrentBudgetReader createSupabaseCurrentBudgetReader(SupabaseClient client) {
  return SupabaseCurrentBudgetReader(client);
}
