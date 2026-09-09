import 'package:flutter/material.dart';
import 'package:locate_my/modules/module_b/models/cost_of_living/budget_scenario.dart';
import 'package:locate_my/modules/module_b/repositories/cost_of_living/cost_of_living_repository.dart';
import 'package:locate_my/core/supabase/supabase_client_manager.dart';

class BudgetViewModel extends ChangeNotifier {
  final CostOfLivingRepository _repository = CostOfLivingRepository();
  final SupabaseClientManager _supabase = SupabaseClientManager();

  List<BudgetScenario> _scenarios = [];

  String? _currentScenarioId;
  Map<String, dynamic>? _comparisonData;
  bool _isLoading = false;
  String? _error;
  String? _requestKey;

  List<BudgetScenario> get scenarios => List.unmodifiable(_scenarios);

  BudgetScenario? get currentScenario {
    if (_scenarios.isEmpty) return null;
    return _scenarios.firstWhere(
      (s) => s.id == _currentScenarioId,
      orElse: () => _scenarios.first,
    );
  }

  Map<String, dynamic>? get comparisonData => _comparisonData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get requestKey => _requestKey;

  BudgetViewModel() {
    _loadUserScenarios();
  }

  Future<void> _loadUserScenarios() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('user_budget_scenarios')
          .select()
          .eq('user_id', user.id);

      _scenarios = (data as List)
          .map(
            (item) => BudgetScenario(
              id: item['id'].toString(),
              name: item['scenario_name'],
              housingWeight: (item['max_rent'] as num?)?.toDouble() ?? 0.0,
              foodWeight: (item['living_expenses'] as num?)?.toDouble() ?? 0.0,
              transportWeight:
                  (item['transport_allowance'] as num?)?.toDouble() ?? 0.0,
              updatedAt: DateTime.parse(item['updated_at']),
            ),
          )
          .toList();

      if (_scenarios.isNotEmpty && _currentScenarioId == null) {
        _currentScenarioId = _scenarios.first.id;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading scenarios: $e');
    }
  }

  Future<void> fetchComparison(
    String origin,
    String target, {
    bool force = false,
  }) async {
    final key = '$origin|$target';
    if (_isLoading && _requestKey == key) return;
    if (!force &&
        _requestKey == key &&
        (_comparisonData != null || _error != null))
      return;
    if (_requestKey != key) {
      _comparisonData = null;
      _error = null;
    }
    _requestKey = key;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // 基础预算取自云端情景预案（max_rent + living_expenses + transport_allowance），
      // 无预案时 baseBudget=null（界面不显示金额换算，只展示 CPI 比值）。
      final scenario = currentScenario;
      final double? baseBudget = scenario == null
          ? null
          : (scenario.housingWeight +
                    scenario.foodWeight +
                    scenario.transportWeight) >
                0
          ? scenario.housingWeight +
                scenario.foodWeight +
                scenario.transportWeight
          : null;
      _comparisonData = await _repository.getComparisonData(
        origin,
        target,
        baseBudget: baseBudget,
      );
    } catch (e) {
      _error = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : '$e';
      debugPrint('Error fetching comparison: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentScenario(String id) {
    _currentScenarioId = id;
    notifyListeners();
  }

  Future<void> addScenario(String name) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final insertData = {'scenario_name': name, 'user_id': user.id};

    try {
      final response = await _supabase
          .from('user_budget_scenarios')
          .insert(insertData)
          .select();

      if (response.isNotEmpty) {
        final item = response.first;
        final newScenario = BudgetScenario(
          id: item['id'].toString(),
          name: item['scenario_name'],
          updatedAt: DateTime.parse(item['updated_at']),
        );
        _scenarios.add(newScenario);
        _currentScenarioId = newScenario.id;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding scenario: $e');
    }
  }

  Future<void> renameScenario(String id, String newName) async {
    try {
      await _supabase
          .from('user_budget_scenarios')
          .update({'scenario_name': newName})
          .eq('id', id);

      final index = _scenarios.indexWhere((s) => s.id == id);
      if (index != -1) {
        _scenarios[index] = _scenarios[index].copyWith(name: newName);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error renaming scenario: $e');
    }
  }

  Future<void> updateCurrentScenario({
    double? housingWeight,
    double? foodWeight,
    double? transportWeight,
    double? entertainmentWeight,
  }) async {
    final scenario = currentScenario;
    if (scenario == null) return;

    final updateData = <String, dynamic>{};
    if (housingWeight != null) updateData['max_rent'] = housingWeight;
    if (foodWeight != null) updateData['living_expenses'] = foodWeight;
    if (transportWeight != null)
      updateData['transport_allowance'] = transportWeight;

    try {
      await _supabase
          .from('user_budget_scenarios')
          .update(updateData)
          .eq('id', scenario.id);

      final index = _scenarios.indexWhere((s) => s.id == scenario.id);
      if (index != -1) {
        _scenarios[index] = _scenarios[index].copyWith(
          housingWeight: housingWeight,
          foodWeight: foodWeight,
          transportWeight: transportWeight,
          entertainmentWeight: entertainmentWeight,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating scenario: $e');
    }
  }

  Future<void> deleteScenario(String id) async {
    try {
      await _supabase.from('user_budget_scenarios').delete().eq('id', id);

      _scenarios.removeWhere((s) => s.id == id);
      if (_currentScenarioId == id) {
        _currentScenarioId = _scenarios.isNotEmpty ? _scenarios.first.id : null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting scenario: $e');
    }
  }
}
