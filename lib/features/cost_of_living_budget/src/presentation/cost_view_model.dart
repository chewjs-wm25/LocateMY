// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../../cost_of_living_budget.dart';

final class CostViewModel extends ChangeNotifier {
  final CostOfLivingBudget _service;
  final ValidLocationReference _location;
  final ValidLocationReference? _second;
  StreamSubscription<BudgetScenariosOutcome>? _subscription;
  bool _disposed = false;
  int _version = 0;
  int _cpiVersion = 0;
  String? _budgetSignature;
  bool loading = true;
  bool cpiLoading = false;
  CostAnalysisOutcome? outcome;
  CostComparisonOutcome? comparison;
  CpiEquivalentOutcome? cpi;
  CostViewModel({
    required CostOfLivingBudget service,
    required ValidLocationReference location,
    ValidLocationReference? locationB,
    CurrentBudgetReader? budget,
  }) : _service = service,
       _location = location,
       _second = locationB {
    _subscription = budget?.watchCurrent().listen((
      BudgetScenariosOutcome event,
    ) {
      if (event is BudgetScenariosAvailable) {
        String signature = 'none';
        final CurrentBudgetScenarioSnapshot current = event.current;
        if (current is CurrentBudgetScenarioAvailable) {
          signature = '${current.scenario.id}:${current.version}';
        }
        if (signature != _budgetSignature) {
          _budgetSignature = signature;
          load();
        }
      }
    });
  }
  Future<void> load({bool refresh = false}) async {
    final int version = ++_version;
    loading = true;
    notifyListeners();
    final CostRefreshPolicy policy = refresh
        ? CostRefreshPolicy.refresh
        : CostRefreshPolicy.cacheAllowed;
    if (_second == null) {
      final CostAnalysisOutcome result = await _service.analyse(
        CostAnalysisRequest(location: _location, refreshPolicy: policy),
      );
      if (_disposed || version != _version) {
        return;
      }
      outcome = result;
    } else {
      final CostComparisonOutcome result = await _service.compare(
        CostComparisonRequest(
          locationA: _location,
          locationB: _second,
          refreshPolicy: policy,
        ),
      );
      if (_disposed || version != _version) {
        return;
      }
      comparison = result;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> convert(String input) async {
    final int version = ++_cpiVersion;
    final double? amount = double.tryParse(input.trim());
    if (amount == null || !amount.isFinite || amount < 0) {
      cpiLoading = false;
      cpi = const CpiEquivalentUnavailable(CpiEquivalentFailure.invalidInput);
      notifyListeners();
      return;
    }
    cpiLoading = true;
    notifyListeners();
    final CpiEquivalentOutcome result = await _service.calculateCpiEquivalent(
      CpiEquivalentRequest(
        location: _location,
        inputMonthlySpendRm: amount,
        refreshPolicy: CostRefreshPolicy.refresh,
      ),
    );
    if (_disposed || version != _cpiVersion) {
      return;
    }
    cpi = result;
    cpiLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    _cpiVersion++;
    _subscription?.cancel();
    _service.clearTemporaryCpiInput();
    super.dispose();
  }
}
