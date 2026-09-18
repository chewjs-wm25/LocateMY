


import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/location_models.dart';
import '../application/map_workspace.dart';
import '../application/location_search.dart';

class MapViewModel extends ChangeNotifier {
  MapViewModel(
    LocationCoordinator locations,
    LocationSearch search,
    MapLayerHost layerHost,
    MapWorkspace workspace, {
    required void Function(ValidLocationReference) onAnalysis,
    required void Function(ValidLocationReference, ValidLocationReference)
    onComparison,
    required void Function(MapLayerIntent) onLayerSelected,
  }) : locations = locations,
       search = search,
       layerHost = layerHost,
       workspace = workspace,
       onAnalysis = onAnalysis,
       onComparison = onComparison,
       onLayerSelected = onLayerSelected {
    subscription = locations.watchSavedLocations().listen((
      SavedLocationsSnapshot snapshot,
    ) {
      saved = snapshot;
      if (snapshot is SavedLocationsAvailable) {
        lastAvailable = snapshot;
      }
      if (snapshot is SavedLocationsUnavailable) {
        lastAvailable = null;
      }
      _notify();
    });
    layersSubscription = workspace.changes.listen((void _) {
      _notify();
    });
  }
  final LocationCoordinator locations;
  final MapLayerHost layerHost;
  final MapWorkspace workspace;
  final void Function(ValidLocationReference) onAnalysis;
  final void Function(ValidLocationReference, ValidLocationReference)
  onComparison;
  final void Function(MapLayerIntent) onLayerSelected;
  final LocationSearch search;
  late final StreamSubscription<SavedLocationsSnapshot> subscription;
  StreamSubscription<void>? layersSubscription;
  LocationRole role = LocationRole.single;
  bool compare = false;
  bool expanded = false;
  bool busy = false;
  bool layerVisible = true;
  bool _disposed = false;
  int _searchVersion = 0;
  int _selectionVersion = 0;
  Timer? _debounce;
  String? message;
  LocationSearchOutcome? searchOutcome;
  SavedLocationsSnapshot? saved;
  SavedLocationsAvailable? lastAvailable;
  List<SavedLocation> get savedRows {
    SavedLocationsAvailable? available = lastAvailable;
    if (saved is SavedLocationsAvailable) {
      available = saved as SavedLocationsAvailable;
    }
    if (available == null) {
      return [];
    }
    return available.locations;
  }

  List<MapLayerItem> get layerItems {
    if (layerVisible) {
      return workspace.visibleLayerItems;
    } else {
      return [];
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  ValidLocationReference? read(LocationRole r) {
    final LocationRoleSnapshot value = locations.read(r);
    if (value is LocationPresent) {
      return value.location;
    }
    return null;
  }

  void setRole(LocationRole r) {
    ++_selectionVersion;
    role = r;
    _notify();
  }

  void mode(bool value) {
    ++_selectionVersion;
    compare = value;
    if (value) {
      role = LocationRole.locationA;
    } else {
      role = LocationRole.single;
    }
    _notify();
  }

  void query(String text) {
    final int version = ++_searchVersion;
    _debounce?.cancel();
    searchOutcome = null;
    message = null;
    _notify();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final LocationSearchOutcome result = await search.search(text);
      if (_disposed || version != _searchVersion || !workspace.opened) {
        return;
      }
      searchOutcome = result;
      _notify();
    });
  }

  Future<bool> select(GeographicPoint point, [String? name]) async {
    final int version = ++_selectionVersion;
    message = null;
    _notify();
    try {
      final LocationSelectionOutcome result = await locations.select(
        LocationSelectionRequest(role: role, point: point, displayName: name),
      );
      if (_disposed || version != _selectionVersion || !workspace.opened) {
        return false;
      }
      if (result is LocationSelectionRejected) {
        message = result.failure.name;
      } else {
        ++_searchVersion;
        searchOutcome = null;
      }
    } catch (_) {
      if (_disposed || version != _selectionVersion || !workspace.opened) {
        return false;
      }
      message = 'unavailable';
    }
    _notify();
    return message == null;
  }

  Future<void> swap() async {
    ++_selectionVersion;
    final LocationSelectionOutcome result = await locations
        .swapComparisonLocations();
    if (result is LocationSelectionRejected) {
      message = result.failure.name;
    }
    _notify();
  }

  void clear() {
    ++_selectionVersion;
    workspace.clear();
    ++_searchVersion;
    searchOutcome = null;
    message = null;
    _notify();
  }

  Future<void> analyze() async {
    final ValidLocationReference? selected = read(LocationRole.single);
    if (selected != null) {
      onAnalysis(selected);
    }
  }

  Future<void> comparison() async {
    final ValidLocationReference? a = read(LocationRole.locationA),
        b = read(LocationRole.locationB);
    if (a != null && b != null) {
      onComparison(a, b);
    }
  }

  Future<void> longPress(GeographicPoint point) async {
    try {
      final MapLayerIntentOutcome result = await layerHost.requestLongPress(
        point,
      );
      if (result is MapLayerIntentAccepted) {
        if (!_disposed) {
          onLayerSelected(result.intent);
        }
      } else {
        message = (result as MapLayerIntentRejected).failure.name;
      }
    } catch (_) {
      message = 'unavailable';
    }
    _notify();
  }

  Future<void> save(ValidLocationReference location, String name) async {
    if (busy) {
      return;
    }
    busy = true;
    _notify();
    try {
      final SavedLocationOutcome result = await locations.save(
        SaveLocationRequest(location: location, name: name),
      );
      
      switch (result) {
        case SavedLocationSaved():
          message = 'saved';
        case SavedLocationRejected(:final failure):
          message = failure.name;
      }
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> remove(String id) async {
    if (busy) {
      return;
    }
    busy = true;
    _notify();
    try {
      final SavedLocationOutcome result = await locations.deleteSavedLocation(
        id,
      );
      if (result is SavedLocationRejected) {
        message = result.failure.name;
      } else {
        message = 'deleted';
      }
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> refresh() async {
    if (busy) {
      return;
    }
    busy = true;
    _notify();
    try {
      saved = await locations.loadSavedLocations();
    } finally {
      busy = false;
      _notify();
    }
  }

  void viewport(String version) {
    workspace.setViewport(version);
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_selectionVersion;
    ++_searchVersion;
    _debounce?.cancel();
    subscription.cancel();
    layersSubscription?.cancel();
    super.dispose();
  }
}
