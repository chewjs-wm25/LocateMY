import 'package:flutter/material.dart';
import 'package:locate_my/modules/module_b/repositories/socio_economic/socio_economic_repository.dart';

class SocioEconomicViewModel extends ChangeNotifier {
  final SocioEconomicRepository _repository = SocioEconomicRepository();

  Map<String, dynamic>? _socioData;
  bool _isLoading = false;
  String? _error;
  String? _requestKey;

  Map<String, dynamic>? get socioData => _socioData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get requestKey => _requestKey;

  /// 幂等加载：同一位置键只尝试一次；成功后数据保留；失败暴露 [error]，
  /// 不会在 build 中被无限重触发。位置变化或 [force]=true 时重新加载。
  Future<void> loadSocioData({
    required String district,
    double? lat,
    double? lng,
    bool force = false,
  }) async {
    final key =
        '${district}|${lat?.toStringAsFixed(3) ?? 'na'}|${lng?.toStringAsFixed(3) ?? 'na'}';
    if (_isLoading && _requestKey == key) return;
    if (!force &&
        _requestKey == key &&
        (_socioData != null || _error != null)) {
      return;
    }
    if (_requestKey != key) {
      _socioData = null;
      _error = null;
    }
    _requestKey = key;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _socioData = await _repository.getSocioEconomicData(
        districtHint: district,
        lat: lat,
        lng: lng,
      );
    } catch (e) {
      _error = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : '$e';
      debugPrint('Error loading socio data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 用户月收入在“该县拟合收入分布”中的百分位（0-100），无数据/无法拟合返回 null。
  double? incomePercentile(double income) {
    final data = _socioData;
    if (data == null) return null;
    return _repository.incomePercentile(data, income);
  }
}
