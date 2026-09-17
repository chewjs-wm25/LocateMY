// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';

import 'src/application/cost_service.dart';
export 'src/application/cost_service.dart'
    show CostPublicReader, CostPublicFailure;
export 'src/data/supabase_cost_reader.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/application/current_budget_reader.dart';
import 'src/data/supabase_budget_store.dart';

import 'src/domain/cost_models.dart';
import 'src/domain/budget_models.dart';
import 'src/application/cost_of_living_budget_fake.dart';
import 'src/application/budget_scenario_store_fake.dart';

export 'src/domain/cost_models.dart';
export 'src/application/budget_json.dart';
export 'src/application/current_budget_reader.dart';
export 'src/domain/budget_models.dart';
export 'src/presentation/cost_budget_page.dart';
export 'src/presentation/budget_scenarios_page.dart';
export 'src/presentation/budget_account_panel.dart';

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

CostOfLivingBudget createCostOfLivingBudget({
  required GeographicContext geographicContext,
  required CostPublicReader reader,
  CurrentBudgetReader? budget,
  Database? database,
  DateTime Function()? clock,
}) {
  return CostService(
    geographicContext: geographicContext,
    reader: reader,
    budget: budget,
    database: database,
    clock: clock,
  );
}

final Expando<SupabaseBudgetScenarioStore> _onlineStores =
    Expando<SupabaseBudgetScenarioStore>();
SupabaseBudgetScenarioStore _onlineStore(SupabaseClient client) {
  return _onlineStores[client] ??= SupabaseBudgetScenarioStore(client);
}

BudgetScenarioStore createBudgetScenarioStore({SupabaseClient? client}) {
  return _onlineStore(client ?? Supabase.instance.client);
}

@Deprecated('Test fixture only; production requires real dependencies.')
CostOfLivingBudget createFakeCostOfLivingBudget() {
  return CostOfLivingBudgetFake();
}

@Deprecated('Test fixture only; production uses Supabase.')
BudgetScenarioStore createFakeBudgetScenarioStore() {
  return BudgetScenarioStoreFake();
}

CurrentBudgetReader createSupabaseCurrentBudgetReader(SupabaseClient client) {
  return _onlineStore(client);
}
