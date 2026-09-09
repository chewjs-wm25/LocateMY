import 'package:flutter/material.dart';
import 'package:locate_my/modules/module_a/repositories/transport/transit_repository.dart';

class TransitViewModel extends ChangeNotifier {
  final TransitRepository _repository = TransitRepository();

  List<Map<String, dynamic>> _nearbyStops = [];
  bool _isLoading = false;
  String? _error;
  String? _requestKey;
  bool _loaded = false;

  List<Map<String, dynamic>> get nearbyStops => _nearbyStops;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLoaded => _loaded;
  String? get requestKey => _requestKey;

  /// 幂等加载：同一坐标只拉一次；失败暴露 [error]，视图提供重试。
  Future<void> loadNearbyStops(
    double lat,
    double lng, {
    bool force = false,
  }) async {
    final key = '${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}';
    if (_isLoading && _requestKey == key) return;
    if (!force && _requestKey == key && (_loaded || _error != null)) return;
    if (_requestKey != key) {
      _nearbyStops = [];
      _loaded = false;
      _error = null;
    }
    _requestKey = key;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _nearbyStops = await _repository.fetchNearbyStops(
        lat: lat,
        lng: lng,
        radiusMeters: 1500,
        maxStops: 30,
      );
      _loaded = true;
    } catch (e) {
      _error = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : '$e';
      debugPrint('Error loading transit stops: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
