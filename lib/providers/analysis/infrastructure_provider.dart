import 'package:flutter/material.dart';
import '../../repositories/infrastructure_repository.dart';

class InfrastructureProvider extends ChangeNotifier {
  final InfrastructureRepository _repository = InfrastructureRepository();
  
  Map<String, dynamic>? _infraData;
  bool _isLoading = false;
  
  // Custom weights for ICI
  double wWater = 0.2;
  double wPower = 0.2;
  double wHealth = 0.2;
  double wEdu = 0.2;
  double wTransit = 0.2;

  Map<String, dynamic>? get infraData => _infraData;
  bool get isLoading => _isLoading;

  Future<void> loadInfraData(String district) async {
    if (_infraData != null && _infraData!['district'] == district) return;

    _isLoading = true;
    notifyListeners();
    try {
      _infraData = await _repository.getInfrastructureData(district);
    } catch (e) {
      debugPrint('Error loading infra data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateWeights({double? water, double? power, double? health, double? edu, double? transit}) {
    if (water != null) wWater = water;
    if (power != null) wPower = power;
    if (health != null) wHealth = health;
    if (edu != null) wEdu = edu;
    if (transit != null) wTransit = transit;
    
    // Recalculate score locally if data exists
    if (_infraData != null) {
      final scores = _infraData!['scores'];
      final newScore = (scores['water'] * wWater + 
                        scores['power'] * wPower + 
                        scores['healthcare'] * wHealth + 
                        scores['education'] * wEdu + 
                        scores['transit'] * wTransit) / (wWater + wPower + wHealth + wEdu + wTransit);
      _infraData!['ici_score'] = newScore;
    }
    notifyListeners();
  }
}
