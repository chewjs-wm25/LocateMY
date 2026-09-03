import 'package:flutter/material.dart';
import '../models/budget_scenario.dart';

class BudgetProvider extends ChangeNotifier {
  final List<BudgetScenario> _scenarios = [
    BudgetScenario(
      id: 'default',
      name: 'Default Scenario',
      updatedAt: DateTime.now(),
    ),
  ];
  
  String _currentScenarioId = 'default';

  List<BudgetScenario> get scenarios => List.unmodifiable(_scenarios);
  
  BudgetScenario get currentScenario => 
      _scenarios.firstWhere((s) => s.id == _currentScenarioId);

  void setCurrentScenario(String id) {
    _currentScenarioId = id;
    notifyListeners();
  }

  void addScenario(String name) {
    final newScenario = BudgetScenario(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      updatedAt: DateTime.now(),
    );
    _scenarios.add(newScenario);
    _currentScenarioId = newScenario.id;
    notifyListeners();
  }

  void updateCurrentScenario({
    double? housingWeight,
    double? foodWeight,
    double? transportWeight,
    double? entertainmentWeight,
  }) {
    final index = _scenarios.indexWhere((s) => s.id == _currentScenarioId);
    if (index != -1) {
      _scenarios[index] = _scenarios[index].copyWith(
        housingWeight: housingWeight,
        foodWeight: foodWeight,
        transportWeight: transportWeight,
        entertainmentWeight: entertainmentWeight,
      );
      notifyListeners();
    }
  }

  void deleteScenario(String id) {
    if (_scenarios.length > 1) {
      _scenarios.removeWhere((s) => s.id == id);
      if (_currentScenarioId == id) {
        _currentScenarioId = _scenarios.first.id;
      }
      notifyListeners();
    }
  }
}
