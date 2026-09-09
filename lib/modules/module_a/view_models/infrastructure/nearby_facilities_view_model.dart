import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:locate_my/modules/module_a/models/infrastructure/nearby_facility.dart';
import 'package:locate_my/modules/module_a/repositories/infrastructure/facility_repository.dart';

/// 周边设施 (POI) 数据 Provider。
/// 依据当前选中地点通过 OSM Overpass API 拉取周边设施。
///
/// 状态机与 [TransitViewModel] 对齐：
/// - 同一坐标只成功拉取一次（[_requestKey] + [_loaded]），重复进入页面复用缓存；
/// - 失败暴露 [_error] 且不缓存结果，由界面提供"重试"按钮以 [force] 重拉；
/// - 切换坐标时自动清空旧数据。
class NearbyFacilitiesViewModel extends ChangeNotifier {
  /// [repository] 可注入（测试用 mock），默认使用真实 Overpass 仓库。
  NearbyFacilitiesViewModel({FacilityRepository? repository})
    : _repository = repository ?? FacilityRepository();

  final FacilityRepository _repository;

  List<NearbyFacility> _facilities = [];
  bool _isLoading = false;
  String? _error;
  String? _requestKey;
  bool _loaded = false;

  List<NearbyFacility> get facilities => _facilities;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLoaded => _loaded;
  String? get requestKey => _requestKey;

  /// 幂等加载：同一坐标只拉一次；失败暴露 [error]，视图提供重试。
  Future<void> loadNearbyFacilities(
    LatLng location, {
    bool force = false,
  }) async {
    final key =
        '${location.latitude.toStringAsFixed(3)}|${location.longitude.toStringAsFixed(3)}';
    // 正在加载同一坐标 / 已成功（或已失败展示中）且非强制 → 不重复请求。
    if (_isLoading && _requestKey == key) return;
    if (!force && _requestKey == key && (_loaded || _error != null)) return;
    if (_requestKey != key) {
      _facilities = [];
      _loaded = false;
      _error = null;
    }
    _requestKey = key;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _facilities = await _repository.getNearbyFacilities(location);
      _loaded = true;
    } catch (e) {
      _facilities = [];
      _loaded = false;
      _error = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : '$e';
      debugPrint('Error loading nearby facilities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _facilities = [];
    _error = null;
    _requestKey = null;
    _loaded = false;
    _isLoading = false;
    notifyListeners();
  }
}
