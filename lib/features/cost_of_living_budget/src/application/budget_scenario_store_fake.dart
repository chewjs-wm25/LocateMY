import 'dart:async';

import '../../cost_of_living_budget.dart';

class BudgetScenarioStoreFake implements BudgetScenarioStore {
  final List<BudgetScenario> _scenarios = [
    BudgetScenario(
      id: 'default-1',
      name: 'Standard Living',
      additionalLivingExpenseRm: 200,
      housingExpenseRm: 800,
      transportExpenseRm: 300,
      monthlyNetIncomeRm: 3500,
      householdMonthlyIncomeRm: 5000,
      isCurrent: true,
      updatedAt: DateTime.now(),
      version: 1,
    ),
  ];

  final _controller = StreamController<BudgetScenariosOutcome>.broadcast();

  BudgetScenarioStoreFake() {
    _emit();
  }

  void _emit() {
    final current = _scenarios.cast<BudgetScenario?>().firstWhere(
      (s) => s?.isCurrent ?? false,
      orElse: () => null,
    );

    final currentSnapshot = current != null
        ? CurrentBudgetScenarioAvailable(
            scenario: current,
            version: current.version,
          )
        : NoCurrentBudgetScenario(version: 0);

    _controller.add(
      BudgetScenariosAvailable(
        scenarios: List.unmodifiable(_scenarios),
        current: currentSnapshot,
      ),
    );
  }

  @override
  Future<BudgetScenariosOutcome> read() async {
    final current = _scenarios.cast<BudgetScenario?>().firstWhere(
      (s) => s?.isCurrent ?? false,
      orElse: () => null,
    );

    final currentSnapshot = current != null
        ? CurrentBudgetScenarioAvailable(
            scenario: current,
            version: current.version,
          )
        : NoCurrentBudgetScenario(version: 0);

    return BudgetScenariosAvailable(
      scenarios: List.unmodifiable(_scenarios),
      current: currentSnapshot,
    );
  }

  @override
  Stream<BudgetScenariosOutcome> watch() => _controller.stream;

  @override
  Future<BudgetScenarioMutationOutcome> create(
    BudgetScenarioDraft draft,
  ) async {
    if (draft.name.trim().isEmpty) {
      return const BudgetScenarioMutationRejected(
        BudgetScenarioFailure.invalidName,
      );
    }

    final newScenario = BudgetScenario(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: draft.name,
      additionalLivingExpenseRm: draft.additionalLivingExpenseRm,
      housingExpenseRm: draft.housingExpenseRm,
      transportExpenseRm: draft.transportExpenseRm,
      monthlyNetIncomeRm: draft.monthlyNetIncomeRm,
      householdMonthlyIncomeRm: draft.householdMonthlyIncomeRm,
      isCurrent: false,
      updatedAt: DateTime.now(),
      version: 1,
    );

    _scenarios.add(newScenario);
    _emit();

    return BudgetScenarioMutationSaved(
      scenario: newScenario,
      current: (await read() as BudgetScenariosAvailable).current,
    );
  }

  @override
  Future<BudgetScenarioMutationOutcome> update(
    BudgetScenarioUpdate update,
  ) async {
    final index = _scenarios.indexWhere((s) => s.id == update.scenarioId);
    if (index == -1) {
      return const BudgetScenarioMutationRejected(
        BudgetScenarioFailure.notFound,
      );
    }

    final old = _scenarios[index];
    final updated = BudgetScenario(
      id: old.id,
      name: update.values.name,
      additionalLivingExpenseRm: update.values.additionalLivingExpenseRm,
      housingExpenseRm: update.values.housingExpenseRm,
      transportExpenseRm: update.values.transportExpenseRm,
      monthlyNetIncomeRm: update.values.monthlyNetIncomeRm,
      householdMonthlyIncomeRm: update.values.householdMonthlyIncomeRm,
      isCurrent: old.isCurrent,
      updatedAt: DateTime.now(),
      version: old.version + 1,
    );

    _scenarios[index] = updated;
    _emit();

    return BudgetScenarioMutationSaved(
      scenario: updated,
      current: (await read() as BudgetScenariosAvailable).current,
    );
  }

  @override
  Future<BudgetScenarioMutationOutcome> selectCurrent(String scenarioId) async {
    final index = _scenarios.indexWhere((s) => s.id == scenarioId);
    if (index == -1) {
      return const BudgetScenarioMutationRejected(
        BudgetScenarioFailure.notFound,
      );
    }

    for (int i = 0; i < _scenarios.length; i++) {
      final s = _scenarios[i];
      _scenarios[i] = BudgetScenario(
        id: s.id,
        name: s.name,
        additionalLivingExpenseRm: s.additionalLivingExpenseRm,
        housingExpenseRm: s.housingExpenseRm,
        transportExpenseRm: s.transportExpenseRm,
        monthlyNetIncomeRm: s.monthlyNetIncomeRm,
        householdMonthlyIncomeRm: s.householdMonthlyIncomeRm,
        isCurrent: s.id == scenarioId,
        updatedAt: s.id == scenarioId ? DateTime.now() : s.updatedAt,
        version: s.id == scenarioId ? s.version + 1 : s.version,
      );
    }

    _emit();

    final updated = _scenarios[index];
    return BudgetScenarioMutationSaved(
      scenario: updated,
      current: CurrentBudgetScenarioAvailable(
        scenario: updated,
        version: updated.version,
      ),
    );
  }

  @override
  Future<BudgetScenarioMutationOutcome> delete(String scenarioId) async {
    final index = _scenarios.indexWhere((s) => s.id == scenarioId);
    if (index == -1) {
      return const BudgetScenarioMutationRejected(
        BudgetScenarioFailure.notFound,
      );
    }

    _scenarios.removeAt(index);
    _emit();

    final outcome = await read() as BudgetScenariosAvailable;
    return BudgetScenarioMutationDeleted(
      scenarioId: scenarioId,
      current: outcome.current,
    );
  }
}
