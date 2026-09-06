import 'package:flutter/material.dart';
import '../../repositories/security_repository.dart';

class SecurityProvider extends ChangeNotifier {
  final SecurityRepository _repository = SecurityRepository();
  
  Map<String, dynamic>? _securityData;
  bool _isLoading = false;

  Map<String, dynamic>? get securityData => _securityData;
  bool get isLoading => _isLoading;

  Future<void> loadSecurityData(double lat, double lng) async {
    final locationKey = '${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}';
    if (_securityData != null && _securityData!['location_key'] == locationKey) return;

    _isLoading = true;
    notifyListeners();
    try {
      _securityData = await _repository.getSecurityData(lat, lng);
    } catch (e) {
      debugPrint('Error loading security data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
