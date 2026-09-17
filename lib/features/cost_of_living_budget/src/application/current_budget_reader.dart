import '../domain/budget_models.dart';

/// Read-only current scenario consumed by Account and Socio-economic.
/// The budget writer must publish successful mutations through this boundary.
abstract interface class CurrentBudgetReader {
  Future<BudgetScenariosOutcome> readCurrent();
  Stream<BudgetScenariosOutcome> watchCurrent();
}
