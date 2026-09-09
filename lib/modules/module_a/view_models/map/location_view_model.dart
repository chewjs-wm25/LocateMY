import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:locate_my/modules/module_a/models/map/saved_location.dart';
import 'package:locate_my/modules/module_a/repositories/map/map_repository.dart';

enum MapMode { display, comparison }

class LocationViewModel extends ChangeNotifier {
  final MapRepository _mapRepository = MapRepository();
  MapMode _mode = MapMode.display;
  LatLng? _selectedLocation;
  LatLng? _originLocation;
  LatLng? _destinationLocation;
  bool _isAnalysisReportOpen = false;

  String? _selectedName;
  String? _originName;
  String? _destinationName;

  bool isWithinMalaysia(LatLng point) {
    final bounds = LatLngBounds(
      const LatLng(0.8, 98.5),
      const LatLng(7.5, 120.0),
    );
    return bounds.contains(point);
  }

  List<SavedLocation> _savedLocations = [];
  List<SavedLocation> get savedLocations => _savedLocations;

  LocationViewModel() {
    _loadSavedLocations();
    // 初始移动到马来西亚中心，避免 MapController 停留在 (0,0) 导致约束或其他问题
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(const LatLng(4.2105, 101.9758), 6.0);
    });
  }

  Future<void> _loadSavedLocations() async {
    _savedLocations = await _mapRepository.getLocalSavedLocations();
    notifyListeners();
    // Try to sync with Supabase after loading local data
    _mapRepository.syncToSupabase();
  }

  bool isLocationSaved(LatLng location) {
    const double threshold = 0.0001; // Roughly 11 meters
    return _savedLocations.any(
      (loc) =>
          (loc.location.latitude - location.latitude).abs() < threshold &&
          (loc.location.longitude - location.longitude).abs() < threshold,
    );
  }

  final MapController _mapController = MapController();
  MapController get mapController => _mapController;

  MapMode get mode => _mode;
  LatLng? get selectedLocation => _selectedLocation;
  LatLng? get originLocation => _originLocation;
  LatLng? get destinationLocation => _destinationLocation;
  bool get isAnalysisReportOpen => _isAnalysisReportOpen;

  String? get selectedName => _selectedName;
  String? get originName => _originName;
  String? get destinationName => _destinationName;

  void setMode(MapMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setAnalysisReportOpen(bool open) {
    _isAnalysisReportOpen = open;
    notifyListeners();
  }

  void setSelectedLocation(LatLng? location, String? name) {
    if (location != null && !isWithinMalaysia(location)) return;
    if (location != null) {
      // Auto-check if this location is already saved
      const double threshold = 0.0001;
      try {
        final saved = _savedLocations.firstWhere(
          (loc) =>
              (loc.location.latitude - location.latitude).abs() < threshold &&
              (loc.location.longitude - location.longitude).abs() < threshold,
        );
        _selectedLocation = saved.location;
        _selectedName = saved.name;
      } catch (_) {
        _selectedLocation = location;
        _selectedName = name;
      }
    } else {
      _selectedLocation = null;
      _selectedName = null;
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedLocation = null;
    _selectedName = null;
    _originLocation = null;
    _originName = null;
    _destinationLocation = null;
    _destinationName = null;
    notifyListeners();
  }

  void setOriginLocation(LatLng? location, String? name) {
    if (location != null && !isWithinMalaysia(location)) return;
    if (location != null) {
      const double threshold = 0.0001;
      try {
        final saved = _savedLocations.firstWhere(
          (loc) =>
              (loc.location.latitude - location.latitude).abs() < threshold &&
              (loc.location.longitude - location.longitude).abs() < threshold,
        );
        _originLocation = saved.location;
        _originName = saved.name;
      } catch (_) {
        _originLocation = location;
        _originName = name;
      }
    } else {
      _originLocation = null;
      _originName = null;
    }
    notifyListeners();
  }

  void setDestinationLocation(LatLng? location, String? name) {
    if (location != null && !isWithinMalaysia(location)) return;
    if (location != null) {
      const double threshold = 0.0001;
      try {
        final saved = _savedLocations.firstWhere(
          (loc) =>
              (loc.location.latitude - location.latitude).abs() < threshold &&
              (loc.location.longitude - location.longitude).abs() < threshold,
        );
        _destinationLocation = saved.location;
        _destinationName = saved.name;
      } catch (_) {
        _destinationLocation = location;
        _destinationName = name;
      }
    } else {
      _destinationLocation = null;
      _destinationName = null;
    }
    notifyListeners();
  }

  void moveTo(LatLng location, {double? zoom}) {
    _mapController.move(location, zoom ?? _mapController.camera.zoom);
    notifyListeners();
  }

  void addSavedLocation(String name, LatLng location) async {
    final newLoc = SavedLocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      location: location,
      createdAt: DateTime.now(),
      synced: false,
    );
    _savedLocations.add(newLoc);
    notifyListeners();
    await _mapRepository.addLocalSavedLocation(newLoc);
  }

  void removeSavedLocation(String id) async {
    _savedLocations.removeWhere((loc) => loc.id == id);
    notifyListeners();
    await _mapRepository.removeLocalSavedLocation(id);
  }
}
