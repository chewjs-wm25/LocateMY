final class BudgetScenario {
  final String id;
  final String name;
  final double? additionalLivingExpenseRm;
  final double? housingExpenseRm;
  final double? transportExpenseRm;
  final double? monthlyNetIncomeRm;
  final double? householdMonthlyIncomeRm;
  final bool isCurrent;
  final DateTime updatedAt;
  final int version;

  const BudgetScenario({
    required String id,
    required String name,
    double? additionalLivingExpenseRm,
    double? housingExpenseRm,
    double? transportExpenseRm,
    double? monthlyNetIncomeRm,
    double? householdMonthlyIncomeRm,
    required bool isCurrent,
    required DateTime updatedAt,
    required int version,
  }) : id = id,
       name = name,
       additionalLivingExpenseRm = additionalLivingExpenseRm,
       housingExpenseRm = housingExpenseRm,
       transportExpenseRm = transportExpenseRm,
       monthlyNetIncomeRm = monthlyNetIncomeRm,
       householdMonthlyIncomeRm = householdMonthlyIncomeRm,
       isCurrent = isCurrent,
       updatedAt = updatedAt,
       version = version;
}

final class BudgetScenarioDraft {
  final String name;
  final double? additionalLivingExpenseRm;
  final double? housingExpenseRm;
  final double? transportExpenseRm;
  final double? monthlyNetIncomeRm;
  final double? householdMonthlyIncomeRm;

  const BudgetScenarioDraft({
    required String name,
    double? additionalLivingExpenseRm,
    double? housingExpenseRm,
    double? transportExpenseRm,
    double? monthlyNetIncomeRm,
    double? householdMonthlyIncomeRm,
  }) : name = name,
       additionalLivingExpenseRm = additionalLivingExpenseRm,
       housingExpenseRm = housingExpenseRm,
       transportExpenseRm = transportExpenseRm,
       monthlyNetIncomeRm = monthlyNetIncomeRm,
       householdMonthlyIncomeRm = householdMonthlyIncomeRm;
}

final class BudgetScenarioUpdate {
  final String scenarioId;
  final BudgetScenarioDraft values;

  const BudgetScenarioUpdate({
    required String scenarioId,
    required BudgetScenarioDraft values,
  }) : scenarioId = scenarioId,
       values = values;
}

sealed class BudgetScenariosOutcome {
  const BudgetScenariosOutcome();
}

final class BudgetScenariosAvailable extends BudgetScenariosOutcome {
  final List<BudgetScenario> scenarios;
  final CurrentBudgetScenarioSnapshot current;
  BudgetScenariosAvailable({
    required List<BudgetScenario> scenarios,
    required CurrentBudgetScenarioSnapshot current,
  }) : scenarios = List<BudgetScenario>.unmodifiable(scenarios),
       current = current;
}

final class BudgetScenariosUnavailable extends BudgetScenariosOutcome {
  final BudgetScenarioFailure failure;
  const BudgetScenariosUnavailable(BudgetScenarioFailure failure)
    : failure = failure;
}

sealed class CurrentBudgetScenarioSnapshot {
  const CurrentBudgetScenarioSnapshot();
}

final class CurrentBudgetScenarioAvailable
    extends CurrentBudgetScenarioSnapshot {
  final BudgetScenario scenario;
  final int version;
  const CurrentBudgetScenarioAvailable({
    required BudgetScenario scenario,
    required int version,
  }) : scenario = scenario,
       version = version;
}

final class NoCurrentBudgetScenario extends CurrentBudgetScenarioSnapshot {
  final int version;
  const NoCurrentBudgetScenario({required int version}) : version = version;
}

sealed class BudgetScenarioMutationOutcome {
  const BudgetScenarioMutationOutcome();
}

final class BudgetScenarioMutationSaved extends BudgetScenarioMutationOutcome {
  final BudgetScenario scenario;
  final CurrentBudgetScenarioSnapshot current;
  const BudgetScenarioMutationSaved({
    required BudgetScenario scenario,
    required CurrentBudgetScenarioSnapshot current,
  }) : scenario = scenario,
       current = current;
}

final class BudgetScenarioMutationDeleted
    extends BudgetScenarioMutationOutcome {
  final String scenarioId;
  final CurrentBudgetScenarioSnapshot current;
  const BudgetScenarioMutationDeleted({
    required String scenarioId,
    required CurrentBudgetScenarioSnapshot current,
  }) : scenarioId = scenarioId,
       current = current;
}

final class BudgetScenarioMutationRejected
    extends BudgetScenarioMutationOutcome {
  final BudgetScenarioFailure failure;
  const BudgetScenarioMutationRejected(BudgetScenarioFailure failure)
    : failure = failure;
}

enum BudgetScenarioFailure {
  invalidName,
  invalidAmount,
  notFound,
  conflict,
  permissionDenied,
  retryableUnavailable,
  scopeUnavailable,
}
