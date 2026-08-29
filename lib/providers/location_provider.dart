import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum MapMode { display, comparison }

class LocationProvider extends ChangeNotifier {
  MapMode _mode = MapMode.display;
  LatLng? _selectedLocation;
  LatLng? _originLocation;
  LatLng? _destinationLocation;

  String? _selectedName;
  String? _originName;
  String? _destinationName;

  MapMode get mode => _mode;
  LatLng? get selectedLocation => _selectedLocation;
  LatLng? get originLocation => _originLocation;
  LatLng? get destinationLocation => _destinationLocation;

  String? get selectedName => _selectedName;
  String? get originName => _originName;
  String? get destinationName => _destinationName;

  void setMode(MapMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setSelectedLocation(LatLng? location, String? name) {
    _selectedLocation = location;
    _selectedName = name;
    notifyListeners();
  }

  void setOriginLocation(LatLng? location, String? name) {
    _originLocation = location;
    _originName = name;
    notifyListeners();
  }

  void setDestinationLocation(LatLng? location, String? name) {
    _destinationLocation = location;
    _destinationName = name;
    notifyListeners();
  }
}
