

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/facility_models.dart';


final class FacilityMapViewModel {
  final NearbyFacilities facilities;
  final LocationCoordinator locations;
  final MapWorkspace workspace;
  final ValueNotifier<String?> viewport;
  StreamSubscription<void>? _changes;
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;
  String? _published;
  FacilityMapViewModel({
    required NearbyFacilities facilities,
    required LocationCoordinator locations,
    required MapWorkspace workspace,
    required ValueNotifier<String?> viewport,
  }) : facilities = facilities,
       locations = locations,
       workspace = workspace,
       viewport = viewport;

  void start() {
    _changes = workspace.changes.listen((void event) {
      _schedule();
    });
    viewport.addListener(_schedule);
    _schedule();
  }

  void _schedule() {
    if (_disposed) {
      return;
    }
    _generation += 1;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 100), _publish);
  }

  Future<void> _publish() async {
    final int generation = _generation;
    final String? version = viewport.value;
    final LocationRoleSnapshot selected = locations.read(LocationRole.single);
    if (_disposed ||
        !workspace.opened ||
        version == null ||
        selected is! LocationPresent) {
      return;
    }
    final ValidLocationReference location = selected.location;
    final String identity = '${location.locationId}:$version';
    if (_published == identity) {
      return;
    }
    if (_published != null) {
      
      _published = null;
      await locationLayerHost(locations).contribute(
        MapLayerContribution(
          providerId: 'nearby-facilities',
          layerId: 'facilities',
          viewportVersion: version,
          visibility: MapLayerVisibility.hidden,
          items: const <MapLayerItem>[],
        ),
      );
      _schedule();
      return;
    }
    try {
      final FacilityAnalysisOutcome result = await facilities.analyse(
        FacilityAnalysisRequest(
          location: location,
          refreshPolicy: FacilityRefreshPolicy.cacheAllowed,
        ),
      );
      if (_disposed ||
          generation != _generation ||
          viewport.value != version ||
          !workspace.opened) {
        return;
      }
      final LocationRoleSnapshot current = locations.read(LocationRole.single);
      if (current is! LocationPresent ||
          !identical(current.location, location)) {
        return;
      }
      if (result is FacilityAnalysisAvailable) {
        
        _published = identity;
        final FacilityLayerOutcome layer = await facilities.contributeLayer(
          FacilityLayerRequest(
            analysis: result.analysis,
            viewportVersion: version,
          ),
        );
        if (layer is! FacilityLayerPublished && _published == identity) {
          _published = null;
        }
      }
    } catch (_) {
      _published = null;
    }
  }

  void dispose() {
    _disposed = true;
    _generation += 1;
    _timer?.cancel();
    _changes?.cancel();
    viewport.removeListener(_schedule);
  }
}

final class NearbyFacilitiesMapPanel extends StatefulWidget {
  final NearbyFacilities facilities;
  final LocationCoordinator locations;
  final MapWorkspace workspace;
  final ValueNotifier<String?> viewport;
  final Widget child;
  const NearbyFacilitiesMapPanel({
    required NearbyFacilities facilities,
    required LocationCoordinator locations,
    required MapWorkspace workspace,
    required ValueNotifier<String?> viewport,
    required Widget child,
    super.key,
  }) : facilities = facilities,
       locations = locations,
       workspace = workspace,
       viewport = viewport,
       child = child;
  @override
  State<NearbyFacilitiesMapPanel> createState() {
    return _NearbyFacilitiesMapPanelState();
  }
}

final class _NearbyFacilitiesMapPanelState
    extends State<NearbyFacilitiesMapPanel> {
  late final FacilityMapViewModel _model = FacilityMapViewModel(
    facilities: widget.facilities,
    locations: widget.locations,
    workspace: widget.workspace,
    viewport: widget.viewport,
  );
  @override
  void initState() {
    super.initState();
    _model.start();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
