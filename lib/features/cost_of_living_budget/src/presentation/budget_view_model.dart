

import 'package:flutter/foundation.dart';

import '../../cost_of_living_budget.dart';

final class BudgetViewModel extends ChangeNotifier {
  final BudgetScenarioStore _store;
  bool _disposed = false;
  int _version = 0;
  bool loading = true;
  bool busy = false;
  BudgetScenariosOutcome? outcome;
  BudgetScenarioFailure? failure;
  bool saved = false;
  BudgetViewModel(BudgetScenarioStore store) : _store = store;
  Future<void> load() async {
    final int version = ++_version;
    loading = true;
    notifyListeners();
    final BudgetScenariosOutcome result = await _store.read();
    if (_disposed || version != _version) {
      return;
    }
    outcome = result;
    loading = false;
    notifyListeners();
  }

  Future<bool> mutate(
    Future<BudgetScenarioMutationOutcome> Function() operation,
  ) async {
    if (busy) {
      return false;
    }
    busy = true;
    saved = false;
    failure = null;
    notifyListeners();
    final BudgetScenarioMutationOutcome result = await operation();
    if (_disposed) {
      return false;
    }
    busy = false;
    if (result is BudgetScenarioMutationRejected) {
      failure = result.failure;
      notifyListeners();
      return false;
    }
    saved = true;
    await load();
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    super.dispose();
  }
}
