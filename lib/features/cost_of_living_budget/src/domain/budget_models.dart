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
    required this.id,
    required this.name,
    this.additionalLivingExpenseRm,
    this.housingExpenseRm,
    this.transportExpenseRm,
    this.monthlyNetIncomeRm,
    this.householdMonthlyIncomeRm,
    required this.isCurrent,
    required this.updatedAt,
    required this.version,
  });
}

final class BudgetScenarioDraft {
  final String name;
  final double? additionalLivingExpenseRm;
  final double? housingExpenseRm;
  final double? transportExpenseRm;
  final double? monthlyNetIncomeRm;
  final double? householdMonthlyIncomeRm;

  const BudgetScenarioDraft({
    required this.name,
    this.additionalLivingExpenseRm,
    this.housingExpenseRm,
    this.transportExpenseRm,
    this.monthlyNetIncomeRm,
    this.householdMonthlyIncomeRm,
  });
}

final class BudgetScenarioUpdate {
  final String scenarioId;
  final BudgetScenarioDraft values;

  const BudgetScenarioUpdate({required this.scenarioId, required this.values});
}

sealed class BudgetScenariosOutcome {
  const BudgetScenariosOutcome();
}

final class BudgetScenariosAvailable extends BudgetScenariosOutcome {
  final List<BudgetScenario> scenarios;
  final CurrentBudgetScenarioSnapshot current;
  const BudgetScenariosAvailable({
    required this.scenarios,
    required this.current,
  });
}

final class BudgetScenariosUnavailable extends BudgetScenariosOutcome {
  final BudgetScenarioFailure failure;
  const BudgetScenariosUnavailable(this.failure);
}

sealed class CurrentBudgetScenarioSnapshot {
  const CurrentBudgetScenarioSnapshot();
}

final class CurrentBudgetScenarioAvailable
    extends CurrentBudgetScenarioSnapshot {
  final BudgetScenario scenario;
  final int version;
  const CurrentBudgetScenarioAvailable({
    required this.scenario,
    required this.version,
  });
}

final class NoCurrentBudgetScenario extends CurrentBudgetScenarioSnapshot {
  final int version;
  const NoCurrentBudgetScenario({required this.version});
}

sealed class BudgetScenarioMutationOutcome {
  const BudgetScenarioMutationOutcome();
}

final class BudgetScenarioMutationSaved extends BudgetScenarioMutationOutcome {
  final BudgetScenario scenario;
  final CurrentBudgetScenarioSnapshot current;
  const BudgetScenarioMutationSaved({
    required this.scenario,
    required this.current,
  });
}

final class BudgetScenarioMutationDeleted
    extends BudgetScenarioMutationOutcome {
  final String scenarioId;
  final CurrentBudgetScenarioSnapshot current;
  const BudgetScenarioMutationDeleted({
    required this.scenarioId,
    required this.current,
  });
}

final class BudgetScenarioMutationRejected
    extends BudgetScenarioMutationOutcome {
  final BudgetScenarioFailure failure;
  const BudgetScenarioMutationRejected(this.failure);
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
