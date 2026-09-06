import 'package:flutter/material.dart';
import '../../repositories/infrastructure_repository.dart';

class InfrastructureProvider extends ChangeNotifier {
  final InfrastructureRepository _repository = InfrastructureRepository();

  Map<String, dynamic>? _infraData;
  bool _isLoading = false;
  String? _error;
  String? _requestKey;

  // Custom weights for ICI（默认等权，和视图滑块对应）
  double wWater = 0.2;
  double wPower = 0.2;
  double wHealth = 0.2;
  double wEdu = 0.2;
  double wTransit = 0.2;

  Map<String, dynamic>? get infraData => _infraData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get requestKey => _requestKey;

  /// 幂等加载：同一位置键只尝试一次，失败暴露 [error]，由视图提供重试。
  Future<void> loadInfraData({
    required String district,
    double? lat,
    double? lng,
    bool force = false,
  }) async {
    final key = '${district}|${lat?.toStringAsFixed(3) ?? 'na'}|${lng?.toStringAsFixed(3) ?? 'na'}';
    if (_isLoading && _requestKey == key) return;
    if (!force && _requestKey == key && (_infraData != null || _error != null)) {
      return;
    }
    if (_requestKey != key) {
      _infraData = null;
      _error = null;
    }
    _requestKey = key;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _infraData = await _repository.getInfrastructureData(
        districtHint: district,
        lat: lat,
        lng: lng,
      );
    } catch (e) {
      _error = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
      debugPrint('Error loading infra data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 按权重重算 ICI 分数（仅使用真实存在的子项）。
  double? get weightedIciScore {
    final scores = _infraData?['scores'];
    if (scores is! Map) return null;
    double total = 0;
    double weightSum = 0;
    void add(String key, double w) {
      final v = scores[key];
      if (v is num) {
        total += v.toDouble() * w;
        weightSum += w;
      }
    }

    add('water', wWater);
    add('power', wPower);
    add('healthcare', wHealth);
    add('education', wEdu);
    add('transit', wTransit);
    if (weightSum <= 0) return null;
    return total / weightSum;
  }

  void updateWeights({
    double? water,
    double? power,
    double? health,
    double? edu,
    double? transit,
  }) {
    if (water != null) wWater = water;
    if (power != null) wPower = power;
    if (health != null) wHealth = health;
    if (edu != null) wEdu = edu;
    if (transit != null) wTransit = transit;
    notifyListeners();
  }
}
