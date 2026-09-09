import 'package:flutter/material.dart';
import 'package:locate_my/core/ici_score.dart';
import 'package:locate_my/modules/module_a/repositories/infrastructure/infrastructure_repository.dart';

class InfrastructureViewModel extends ChangeNotifier {
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
    final key =
        '$district|${lat?.toStringAsFixed(3) ?? 'na'}|${lng?.toStringAsFixed(3) ?? 'na'}';
    if (_isLoading && _requestKey == key) return;
    if (!force &&
        _requestKey == key &&
        (_infraData != null || _error != null)) {
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
      _error = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : '$e';
      debugPrint('Error loading infra data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 按权重重算 ICI 分数。
  ///
  /// 公平口径与仓库层一致：源数据缺失的子项按 0 计入（权重保留在分母），
  /// 未提供坐标时 transit 不可评估（权重与分数一并剔除）——
  /// 避免“缺医疗/教育数据的地区”仅凭剩余高分项虚高到接近满分。
  double? get weightedIciScore {
    final scores = _infraData?['scores'];
    if (scores is! Map) return null;
    // 兼容旧缓存：旧载荷没有 transit_applicable 时按 transit 是否有分判断。
    final transitApplicable =
        _infraData?['transit_applicable'] as bool? ?? scores['transit'] is num;
    return computeIciScore(
      scores.cast<String, dynamic>(),
      transitApplicable: transitApplicable,
      wWater: wWater,
      wPower: wPower,
      wHealth: wHealth,
      wEdu: wEdu,
      wTransit: wTransit,
    );
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
