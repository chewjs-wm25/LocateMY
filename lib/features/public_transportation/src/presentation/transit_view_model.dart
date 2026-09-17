// Explicit constructor initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/transit_models.dart';

/// Owns request identity and selection for one page, never global Map state.
final class TransitViewModel extends ChangeNotifier {
  final PublicTransportation _transportation;
  final MapLayerHost? _mapLayerHost;
  final MapWorkspace? _mapWorkspace;
  MapLayerContributionOutcome? _layerOutcome;
  String _viewportVersion = '';
  ValidLocationReference _location;
  DateTime _analysisDate;
  TransitLoadOutcome? _outcome;
  TransitStation? _selected;
  bool _loading = false;
  bool _retainedPreviousResult = false;
  bool _closed = false;
  int _revision = 0;

  TransitViewModel({
    required PublicTransportation transportation,
    required ValidLocationReference location,
    required DateTime analysisDate,
    MapLayerHost? mapLayerHost,
    MapWorkspace? mapWorkspace,
  }) : _transportation = transportation,
       _location = location,
       _analysisDate = analysisDate,
       _mapLayerHost = mapLayerHost,
       _mapWorkspace = mapWorkspace;

  MapLayerContributionOutcome? get layerOutcome {
    return _layerOutcome;
  }

  TransitLoadOutcome? get outcome {
    return _outcome;
  }

  TransitStation? get selected {
    return _selected;
  }

  bool get loading {
    return _loading;
  }

  bool get retainedPreviousResult {
    return _retainedPreviousResult;
  }

  DateTime get analysisDate {
    return _analysisDate;
  }

  Future<void> changeLocation(
    ValidLocationReference location,
    DateTime analysisDate,
  ) async {
    _location = location;
    _analysisDate = analysisDate;
    _outcome = null;
    _selected = null;
    _retainedPreviousResult = false;
    await load(TransitLoadPolicy.cacheAllowed);
  }

  Future<void> load(TransitLoadPolicy policy) async {
    if (_closed) {
      return;
    }
    final int revision = ++_revision;
    final TransitLoadOutcome? previous = _outcome;
    _viewportVersion = 'transit:${identityHashCode(this)}:$revision';
    _mapWorkspace?.setViewport(_viewportVersion);
    _layerOutcome = null;
    final TransitRequest request = TransitRequest(
      location: _location,
      analysisDate: _analysisDate,
      policy: policy,
    );
    _loading = true;
    _selected = null;
    notifyListeners();
    TransitLoadOutcome result;
    try {
      result = await _transportation.load(request);
    } catch (_) {
      result = const TransitUnavailable(
        TransitUnavailableReason.retryableUnavailable,
        <FeedStatus>[],
      );
    }
    if (_closed || revision != _revision) {
      return;
    }
    _retainedPreviousResult =
        policy == TransitLoadPolicy.refresh &&
        previous != null &&
        identical(previous, result);
    _outcome = result;
    _loading = false;
    notifyListeners();
    final MapLayerHost? host = _mapLayerHost;
    if (host != null) {
      final List<MapLayerItem> items = <MapLayerItem>[];
      List<TransitStation> stations = <TransitStation>[];
      if (result is TransitAvailable) {
        stations = result.snapshot.stations;
      } else if (result is TransitIncomplete) {
        stations = result.snapshot.stations;
      }
      if (result is! TransitUnavailable) {
        items.add(
          MapLayerItem(
            stableItemId: 'analysis-center',
            point: _location.point,
            intent: const ProviderDefinedIntent(
              providerId: 'public-transportation',
              action: 'coverage-radius-1500m',
              stableItemId: 'analysis-center',
            ),
          ),
        );
        for (final TransitStation station in stations) {
          final String id = '${station.feedId}:${station.stopId}';
          items.add(
            MapLayerItem(
              stableItemId: id,
              point: station.point,
              intent: ProviderDefinedIntent(
                providerId: 'public-transportation',
                action: 'select-station',
                stableItemId: id,
              ),
            ),
          );
        }
      }
      MapLayerContributionOutcome layer;
      try {
        layer = await host.contribute(
          MapLayerContribution(
            providerId: 'public-transportation',
            layerId: 'stations',
            viewportVersion: _viewportVersion,
            visibility: result is TransitUnavailable
                ? MapLayerVisibility.hidden
                : MapLayerVisibility.visible,
            items: List<MapLayerItem>.unmodifiable(items),
          ),
        );
      } catch (_) {
        layer = const MapLayerRejected(
          failure: MapLayerFailure.scopeUnavailable,
        );
      }
      if (_closed || revision != _revision) {
        return;
      }
      _layerOutcome = layer;
      notifyListeners();
    }
  }

  void select(String stableId) {
    final TransitLoadOutcome? outcome = _outcome;
    List<TransitStation> stations = <TransitStation>[];
    if (outcome is TransitAvailable) {
      stations = outcome.snapshot.stations;
    } else if (outcome is TransitIncomplete) {
      stations = outcome.snapshot.stations;
    }
    _selected = null;
    for (final TransitStation station in stations) {
      if ('${station.feedId}:${station.stopId}' == stableId) {
        _selected = station;
        break;
      }
    }
    notifyListeners();
  }

  Future<void> _hideLayer() async {
    final MapLayerHost? host = _mapLayerHost;
    if (host == null) {
      return;
    }
    try {
      await host.contribute(
        MapLayerContribution(
          providerId: 'public-transportation',
          layerId: 'stations',
          viewportVersion: _viewportVersion,
          visibility: MapLayerVisibility.hidden,
          items: const <MapLayerItem>[],
        ),
      );
    } catch (_) {
      // The owned workspace was already invalidated synchronously above.
    }
  }

  @override
  void dispose() {
    _closed = true;
    ++_revision;
    _viewportVersion = 'closed:${identityHashCode(this)}:$_revision';
    _mapWorkspace?.setViewport(_viewportVersion);
    _hideLayer();
    _selected = null;
    _outcome = null;
    super.dispose();
  }
}
