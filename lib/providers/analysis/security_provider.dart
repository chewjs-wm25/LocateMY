import 'package:flutter/material.dart';
import '../../repositories/security_repository.dart';

class SecurityProvider extends ChangeNotifier {
  final SecurityRepository _repository = SecurityRepository();

  Map<String, dynamic>? _securityData;
  bool _isLoading = false;
  String? _error;
  String? _requestKey;

  Map<String, dynamic>? get securityData => _securityData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get requestKey => _requestKey;

  /// 幂等加载：同一坐标只尝试一次；失败暴露 [error]，不会无限重试。
  Future<void> loadSecurityData(
    double lat,
    double lng, {
    bool force = false,
  }) async {
    final key = '${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}';
    if (_isLoading && _requestKey == key) return;
    if (!force && _requestKey == key && (_securityData != null || _error != null)) {
      return;
    }
    if (_requestKey != key) {
      _securityData = null;
      _error = null;
    }
    _requestKey = key;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _securityData = await _repository.getSecurityData(lat, lng);
    } catch (e) {
      _error = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
      debugPrint('Error loading security data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
