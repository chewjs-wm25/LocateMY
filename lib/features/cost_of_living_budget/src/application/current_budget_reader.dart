import '../domain/budget_models.dart';

abstract interface class CurrentBudgetReader {
  Future<BudgetScenariosOutcome> readCurrent();
  Stream<BudgetScenariosOutcome> watchCurrent();
}
