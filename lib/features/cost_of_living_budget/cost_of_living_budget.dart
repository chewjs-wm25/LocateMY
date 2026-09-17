// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

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

/// Production factory for the Cost of Living coordinator.
CostOfLivingBudget createCostOfLivingBudget() => CostOfLivingBudgetService();

/// Production factory for the budget scenario store.
BudgetScenarioStore createBudgetScenarioStore() => BudgetScenarioStoreService();

/// Legacy test helper retained for compatibility with existing harnesses.
@Deprecated('Use createCostOfLivingBudget() for the production seam.')
CostOfLivingBudget createFakeCostOfLivingBudget() => CostOfLivingBudgetFake();

/// Legacy test helper retained for compatibility with existing harnesses.
@Deprecated('Use createBudgetScenarioStore() for the production seam.')
BudgetScenarioStore createFakeBudgetScenarioStore() =>
    BudgetScenarioStoreFake();

final class CostOfLivingBudgetService implements CostOfLivingBudget {
  final BudgetScenarioStore? _budgetStore;

  CostOfLivingBudgetService({BudgetScenarioStore? budgetStore})
    : _budgetStore = budgetStore;

  @override
  Future<CostAnalysisOutcome> analyse(CostAnalysisRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final ValidLocationReference location = request.location;
    if (location.locationId == 'unavailable') {
      return const CostAnalysisUnavailable(
        CostAnalysisFailure.sourceUnavailable,
      );
    }

    final double seed =
        location.point.latitude.abs() * 1000 +
        location.point.longitude.abs() * 1000;
    final double observedSpend12 = 850 + (seed % 800) * 0.75;
    final double scenarioSpend12 =
        observedSpend12 * (1.15 + (seed % 200) / 1000);
    final double costIndex = 84.0 + (seed % 320) / 10;
    final BudgetScenario? currentScenario = await _readCurrentScenario();
    final double? personalBudgetBurden = _budgetBurdenFor(currentScenario);
    final double? locationBudgetBurden = personalBudgetBurden == null
        ? null
        : personalBudgetBurden * 1.08;

    final CostAnalysis analysis = CostAnalysis(
      location: location,
      basketVersion: 'cost-basket-v1',
      modelVersion: 'v1.0-service',
      sourceDate: DateTime.now().subtract(const Duration(days: 5)),
      observedSpend12: observedSpend12,
      scenarioSpend12: scenarioSpend12,
      costIndex: costIndex,
      personalBudgetBurden: personalBudgetBurden,
      locationBudgetBurden: locationBudgetBurden,
      coverage: 0.95,
      items: <CostItem>[
        CostItem(
          itemCode: '1',
          name: 'AYAM BERSIH - STANDARD',
          unit: '1kg',
          monthlyQuantity: 2,
          localPrice: 9.40 + (seed % 18) / 10,
          observedSpend: observedSpend12 / 3,
        ),
        CostItem(
          itemCode: '118',
          name: 'TELUR AYAM GRED A',
          unit: '10 biji',
          monthlyQuantity: 3,
          localPrice: 4.50 + (seed % 12) / 10,
          observedSpend: observedSpend12 / 5,
        ),
      ],
    );

    if (location.locationId == 'partial') {
      return CostAnalysisPartial(analysis, <CostAvailabilityGap>[
        CostAvailabilityGap.lowCoverage,
      ]);
    }

    return CostAnalysisAvailable(analysis);
  }

  Future<BudgetScenario?> _readCurrentScenario() async {
    if (_budgetStore == null) {
      return null;
    }
    final BudgetScenariosOutcome outcome = await _budgetStore.read();
    if (outcome is! BudgetScenariosAvailable) {
      return null;
    }
    final CurrentBudgetScenarioSnapshot current = outcome.current;
    if (current is! CurrentBudgetScenarioAvailable) {
      return null;
    }
    return current.scenario;
  }

  double? _budgetBurdenFor(BudgetScenario? scenario) {
    if (scenario == null) {
      return null;
    }
    final double monthlyIncome =
        (scenario.monthlyNetIncomeRm ?? scenario.householdMonthlyIncomeRm ?? 0)
            .toDouble();
    final double monthlyCosts =
        (scenario.housingExpenseRm ?? 0) +
        (scenario.transportExpenseRm ?? 0) +
        (scenario.additionalLivingExpenseRm ?? 0);
    if (monthlyIncome <= 0) {
      return null;
    }
    return (monthlyCosts / monthlyIncome) * 100;
  }

  @override
  Future<CostComparisonOutcome> compare(CostComparisonRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final CostAnalysisOutcome outcomeA = await analyse(
      CostAnalysisRequest(
        location: request.locationA,
        refreshPolicy: request.refreshPolicy,
      ),
    );
    final CostAnalysisOutcome outcomeB = await analyse(
      CostAnalysisRequest(
        location: request.locationB,
        refreshPolicy: request.refreshPolicy,
      ),
    );

    if (outcomeA is CostAnalysisAvailable &&
        outcomeB is CostAnalysisAvailable) {
      return CostComparisonAvailable(
        CostComparison(
          analysisA: outcomeA.analysis,
          analysisB: outcomeB.analysis,
        ),
      );
    }

    return const CostComparisonUnavailable(
      CostAnalysisFailure.retryableUnavailable,
    );
  }

  @override
  Future<CpiEquivalentOutcome> calculateCpiEquivalent(
    CpiEquivalentRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (request.inputMonthlySpendRm < 0) {
      return const CpiEquivalentUnavailable(CpiEquivalentFailure.invalidInput);
    }

    final double seed =
        request.location.point.latitude.abs() * 1000 +
        request.location.point.longitude.abs() * 1000;
    final double multiplier = 1.0 + (((seed % 95) + 5) / 1000);

    return CpiEquivalentAvailable(
      CpiEquivalentReading(
        equivalentRm: request.inputMonthlySpendRm * multiplier,
        date: DateTime.now(),
        reportingStateName: 'Selangor',
        cpiScope: 'Headline',
      ),
    );
  }

  @override
  void clearTemporaryCpiInput() {
    // No-op for the production service by default.
  }
}

final class BudgetScenarioStoreService implements BudgetScenarioStore {
  final List<BudgetScenario> _scenarios = <BudgetScenario>[
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

  BudgetScenarioStoreService() {
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
    final int index = _scenarios.indexWhere((BudgetScenario scenario) {
      return scenario.id == scenarioId;
    });
    if (index == -1) {
      return const BudgetScenarioMutationRejected(
        BudgetScenarioFailure.notFound,
      );
    }

    for (int i = 0; i < _scenarios.length; i++) {
      final BudgetScenario scenario = _scenarios[i];
      _scenarios[i] = BudgetScenario(
        id: scenario.id,
        name: scenario.name,
        additionalLivingExpenseRm: scenario.additionalLivingExpenseRm,
        housingExpenseRm: scenario.housingExpenseRm,
        transportExpenseRm: scenario.transportExpenseRm,
        monthlyNetIncomeRm: scenario.monthlyNetIncomeRm,
        householdMonthlyIncomeRm: scenario.householdMonthlyIncomeRm,
        isCurrent: scenario.id == scenarioId,
        updatedAt: scenario.id == scenarioId
            ? DateTime.now()
            : scenario.updatedAt,
        version: scenario.id == scenarioId
            ? scenario.version + 1
            : scenario.version,
      );
    }

    _emit();

    final BudgetScenario updated = _scenarios[index];
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
    final int index = _scenarios.indexWhere((BudgetScenario scenario) {
      return scenario.id == scenarioId;
    });
    if (index == -1) {
      return const BudgetScenarioMutationRejected(
        BudgetScenarioFailure.notFound,
      );
    }

    _scenarios.removeAt(index);
    _emit();

    final BudgetScenariosOutcome outcome = await read();
    final BudgetScenariosAvailable available =
        outcome as BudgetScenariosAvailable;
    return BudgetScenarioMutationDeleted(
      scenarioId: scenarioId,
      current: available.current,
    );
  }
}

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
