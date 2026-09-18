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

  final StreamController<BudgetScenariosOutcome> _controller =
      StreamController<BudgetScenariosOutcome>.broadcast();

  BudgetScenarioStoreFake() {
    _emit();
  }

  bool _hasValidName(String value) {
    final String trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed.length <= 120;
  }

  bool _hasValidAmount(double? value) {
    if (value == null) {
      return true;
    }
    return value.isFinite && value >= 0;
  }

  bool _hasValidDraft(BudgetScenarioDraft draft) {
    if (!_hasValidName(draft.name)) {
      return false;
    }
    return _hasValidAmount(draft.additionalLivingExpenseRm) &&
        _hasValidAmount(draft.housingExpenseRm) &&
        _hasValidAmount(draft.transportExpenseRm) &&
        _hasValidAmount(draft.monthlyNetIncomeRm) &&
        _hasValidAmount(draft.householdMonthlyIncomeRm);
  }

  void _emit() {
    final BudgetScenario? current = _scenarios
        .cast<BudgetScenario?>()
        .firstWhere(
          (BudgetScenario? scenario) => scenario?.isCurrent ?? false,
          orElse: () => null,
        );

    final CurrentBudgetScenarioSnapshot currentSnapshot = current != null
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
    final BudgetScenario? current = _scenarios
        .cast<BudgetScenario?>()
        .firstWhere(
          (BudgetScenario? scenario) => scenario?.isCurrent ?? false,
          orElse: () => null,
        );

    final CurrentBudgetScenarioSnapshot currentSnapshot = current != null
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
    if (!_hasValidName(draft.name)) {
      return const BudgetScenarioMutationRejected(
        BudgetScenarioFailure.invalidName,
      );
    }
    if (!_hasValidDraft(draft)) {
      return const BudgetScenarioMutationRejected(
        BudgetScenarioFailure.invalidAmount,
      );
    }

    final BudgetScenario newScenario = BudgetScenario(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: draft.name.trim(),
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
    final int index = _scenarios.indexWhere((BudgetScenario scenario) {
      return scenario.id == update.scenarioId;
    });
    if (index == -1) {
      return const BudgetScenarioMutationRejected(
        BudgetScenarioFailure.notFound,
      );
    }

    if (!_hasValidName(update.values.name)) {
      return const BudgetScenarioMutationRejected(
        BudgetScenarioFailure.invalidName,
      );
    }
    if (!_hasValidDraft(update.values)) {
      return const BudgetScenarioMutationRejected(
        BudgetScenarioFailure.invalidAmount,
      );
    }

    final BudgetScenario old = _scenarios[index];
    final BudgetScenario updated = BudgetScenario(
      id: old.id,
      name: update.values.name.trim(),
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
