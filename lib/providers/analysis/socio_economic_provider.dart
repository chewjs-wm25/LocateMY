import 'package:flutter/material.dart';
import '../../repositories/socio_economic_repository.dart';

class SocioEconomicProvider extends ChangeNotifier {
  final SocioEconomicRepository _repository = SocioEconomicRepository();
  
  Map<String, dynamic>? _socioData;
  bool _isLoading = false;

  Map<String, dynamic>? get socioData => _socioData;
  bool get isLoading => _isLoading;

  Future<void> loadSocioData(String district) async {
    if (_socioData != null && _socioData!['district'] == district) return;

    _isLoading = true;
    notifyListeners();
    try {
      _socioData = await _repository.getSocioEconomicData(district);
    } catch (e) {
      debugPrint('Error loading socio data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
