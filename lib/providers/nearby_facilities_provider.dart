import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/nearby_facility.dart';
import '../repositories/facility_repository.dart';

/// 周边设施 (POI) 数据 Provider。
/// 依据当前选中地点通过 OSM Overpass API 拉取周边设施。
class NearbyFacilitiesProvider extends ChangeNotifier {
  final FacilityRepository _repository = FacilityRepository();

  List<NearbyFacility> _facilities = [];
  bool _isLoading = false;
  String? _error;
  LatLng? _lastLoadedLocation;

  List<NearbyFacility> get facilities => _facilities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNearbyFacilities(LatLng location) async {
    // 同一地点已加载成功则跳过，避免重复请求
    if (_isLoading) return;
    if (location == _lastLoadedLocation && _facilities.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _facilities = await _repository.getNearbyFacilities(location);
      _lastLoadedLocation = location;
    } catch (e) {
      _error = '加载周边设施失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _facilities = [];
    _error = null;
    _lastLoadedLocation = null;
    notifyListeners();
  }
}
