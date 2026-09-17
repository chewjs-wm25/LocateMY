// Explicit parameter types and initialization follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:math';

import '../domain/location_models.dart';
import 'location_storage.dart';
import 'map_workspace.dart';
import 'map_diagnostics.dart';

class LocationService
    implements LocationCoordinator, MapLayerHost, MapWorkspace {
  LocationService({
    required String accountId,
    required Future<bool> Function(GeographicPoint) validatePoint,
    LocationStorage? storage,
    void Function(Map<String, Object>)? diagnosticSink,
  }) : accountId = accountId,
       validatePoint = validatePoint,
       storage = storage,
       diagnosticSink = diagnosticSink;
  @override
  Future<LocationSelectionOutcome> select(LocationSelectionRequest request) {
    return _observe('select', () => _select(request));
  }

  @override
  Future<LocationSelectionOutcome> swapComparisonLocations() {
    return _observe('swap', _swapComparisonLocations);
  }

  @override
  Future<MapLayerContributionOutcome> contribute(
    MapLayerContribution contribution,
  ) {
    return _observe('layer', () => _contribute(contribution));
  }

  @override
  Future<MapLayerIntentOutcome> requestLongPress(GeographicPoint point) {
    return _observe('longpress', () => _requestLongPress(point));
  }

  final void Function(Map<String, Object>)? diagnosticSink;
  Future<T> _observe<T>(String operation, Future<T> Function() run) {
    return observeMap(operation, run, diagnosticSink);
  }

  final LocationStorage? storage;
  final String accountId;
  final Future<bool> Function(GeographicPoint) validatePoint;
  final Map<LocationRole, ValidLocationReference> roles = {};
  final Set<ValidLocationReference> _issued = {};
  final Map<LocationRole, int> _requests = {};

  void invalidateSelections() {
    for (final LocationRole role in LocationRole.values) {
      _requests[role] = (_requests[role] ?? 0) + 1;
    }
  }

  @override
  bool get opened {
    return true;
  }

  @override
  List<MapLayerItem> get visibleLayerItems {
    final List<MapLayerItem> items = [];
    for (final MapLayerContribution contribution in layers.values) {
      if (contribution.visibility == MapLayerVisibility.visible) {
        items.addAll(contribution.items);
      }
    }
    return List.unmodifiable(items);
  }

  @override
  Stream<void> get changes {
    return layerChanges.stream;
  }

  @override
  void clear() {
    roles.clear();
    layers.clear();
    invalidateSelections();
    layerChanges.add(null);
  }

  @override
  void setViewport(String version) {
    if (viewport == version) {
      return;
    }
    viewport = version;
    layers.clear();
    layerChanges.add(null);
  }

  // The frozen interfaces have no transport-error variant. Fail closed using
  // scopeUnavailable without claiming the point is outside Malaysia.
  Future<bool?> _validate(GeographicPoint point) async {
    try {
      return await validatePoint(point);
    } catch (_) {
      return null;
    }
  }

  @override
  LocationRoleSnapshot read(LocationRole role) {
    if (opened && roles[role] != null) {
      return LocationPresent(role: role, location: roles[role]!);
    } else {
      return LocationAbsent(role: role);
    }
  }

  Future<LocationSelectionOutcome> _select(
    LocationSelectionRequest request,
  ) async {
    if (!opened) {
      return const LocationSelectionRejected(
        failure: LocationSelectionFailure.scopeUnavailable,
      );
    }
    final GeographicPoint p = request.point;
    if (!p.latitude.isFinite ||
        !p.longitude.isFinite ||
        p.latitude < -90 ||
        p.latitude > 90 ||
        p.longitude < -180 ||
        p.longitude > 180) {
      return const LocationSelectionRejected(
        failure: LocationSelectionFailure.invalidCoordinate,
      );
    }
    final int version = (_requests[request.role] ?? 0) + 1;
    _requests[request.role] = version;
    final bool? valid = await _validate(request.point);
    if (!opened || _requests[request.role] != version) {
      return const LocationSelectionRejected(
        failure: LocationSelectionFailure.scopeUnavailable,
      );
    }
    if (valid == null) {
      return const LocationSelectionRejected(
        failure: LocationSelectionFailure.scopeUnavailable,
      );
    }
    if (!valid) {
      return const LocationSelectionRejected(
        failure: LocationSelectionFailure.outsideMalaysia,
      );
    }
    final ValidLocationReference location = ValidLocationReference(
      locationId: '${request.point.latitude},${request.point.longitude}',
      point: request.point,
      displayName: request.displayName,
    );
    final LocationRole? otherRole = _comparisonRoleFor(request.role);
    if (otherRole != null &&
        roles[otherRole]?.locationId == location.locationId) {
      return const LocationSelectionRejected(
        failure: LocationSelectionFailure.sameComparisonPoint,
      );
    }
    _issued.add(location);
    roles[request.role] = location;
    layerChanges.add(null);
    return LocationSelected(role: request.role, location: location);
  }

  LocationRole? _comparisonRoleFor(LocationRole role) {
    if (role == LocationRole.locationA) {
      return LocationRole.locationB;
    }
    if (role == LocationRole.locationB) {
      return LocationRole.locationA;
    }
    return null;
  }

  Future<LocationSelectionOutcome> _swapComparisonLocations() async {
    if (!opened) {
      return const LocationSelectionRejected(
        failure: LocationSelectionFailure.scopeUnavailable,
      );
    }
    final ValidLocationReference? a = roles[LocationRole.locationA];
    final ValidLocationReference? b = roles[LocationRole.locationB];
    if (a == null || b == null) {
      return const LocationSelectionRejected(
        failure: LocationSelectionFailure.invalidCoordinate,
      );
    }
    _requests[LocationRole.locationA] =
        (_requests[LocationRole.locationA] ?? 0) + 1;
    _requests[LocationRole.locationB] =
        (_requests[LocationRole.locationB] ?? 0) + 1;
    roles[LocationRole.locationA] = b;
    roles[LocationRole.locationB] = a;
    layerChanges.add(null);
    return LocationSelected(role: LocationRole.locationA, location: b);
  }

  Future<void> _tail = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() run) {
    // A Future chain is necessary here to preserve the one-at-a-time durable
    // storage contract while allowing a prior failure to be reported normally.
    final Future<T> result = _tail.then((_) => run());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  Future<SavedLocationOutcome> save(SaveLocationRequest request) {
    return _observe('save', () => _serialized(() => _save(request)));
  }

  Future<SavedLocationOutcome> _save(SaveLocationRequest request) async {
    if (!opened || storage == null) {
      return const SavedLocationRejected(
        failure: SavedLocationFailure.scopeUnavailable,
      );
    }
    final String name = request.name.trim();
    if (name.isEmpty || name.runes.length > 120) {
      return const SavedLocationRejected(
        failure: SavedLocationFailure.invalidName,
      );
    }
    if (!_issued.contains(request.location)) {
      return const SavedLocationRejected(
        failure: SavedLocationFailure.invalidLocation,
      );
    }
    final String key = _newClientKey();
    final SavedRecord record = SavedRecord(
      clientKey: key,
      saved: SavedLocation(
        id: key,
        name: name,
        location: request.location,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    try {
      final SavedRecord created = await storage!.createRemote(record);
      _rows.add(created);
      _emit(_rows);
      return SavedLocationSaved(savedLocation: created.saved);
    } on SavedLocationFailure catch (failure) {
      return SavedLocationRejected(failure: failure);
    } catch (_) {
      return const SavedLocationRejected(
        failure: SavedLocationFailure.retryableUnavailable,
      );
    }
  }

  final List<SavedRecord> _rows = <SavedRecord>[];

  String _newClientKey() {
    final Random random = Random.secure();
    final StringBuffer buffer = StringBuffer();
    for (int index = 0; index < 16; index += 1) {
      final String part = random.nextInt(256).toRadixString(16).padLeft(2, '0');
      buffer.write(part);
    }
    return buffer.toString();
  }

  void _removeRecordWithClientKey(List<SavedRecord> records, String clientKey) {
    records.removeWhere((SavedRecord record) => record.clientKey == clientKey);
  }

  @override
  Future<SavedLocationOutcome> deleteSavedLocation(String id) {
    return _observe('delete', () => _serialized(() => _delete(id)));
  }

  Future<SavedLocationOutcome> _delete(String id) async {
    if (!opened || storage == null) {
      return const SavedLocationRejected(
        failure: SavedLocationFailure.scopeUnavailable,
      );
    }
    try {
      final List<SavedRecord> rows = await storage!.readRemote();
      final Iterable<SavedRecord> found = rows.where(
        (r) => r.saved.id == id && !r.deleted,
      );
      if (found.isEmpty) {
        return const SavedLocationRejected(
          failure: SavedLocationFailure.notFound,
        );
      }
      final SavedRecord deleted = await storage!.deleteRemote(found.first);
      if (!opened) {
        return const SavedLocationRejected(
          failure: SavedLocationFailure.scopeUnavailable,
        );
      }
      _removeRecordWithClientKey(rows, deleted.clientKey);
      rows.add(deleted);
      _rows.clear();
      _rows.addAll(rows);
      _emit(rows);
      return SavedLocationSaved(savedLocation: deleted.saved);
    } on SavedLocationFailure catch (failure) {
      return SavedLocationRejected(failure: failure);
    } catch (_) {
      return const SavedLocationRejected(
        failure: SavedLocationFailure.retryableUnavailable,
      );
    }
  }

  @override
  Stream<SavedLocationsSnapshot> watchSavedLocations() {
    return Stream.multi((controller) {
      final StreamSubscription<SavedLocationsSnapshot> subscription = _events
          .stream
          .listen((SavedLocationsSnapshot snapshot) {
            controller.add(snapshot);
          });
      controller.onCancel = subscription.cancel;
      loadSavedLocations();
    });
  }

  final StreamController<SavedLocationsSnapshot> _events =
      StreamController<SavedLocationsSnapshot>.broadcast();
  SavedLocationsSnapshot _snapshot(List<SavedRecord> rows) {
    if (!opened) {
      return const SavedLocationsUnavailable(
        failure: SavedLocationFailure.scopeUnavailable,
      );
    }
    final List<SavedLocation> locations = [];
    for (final SavedRecord row in rows) {
      if (!row.deleted) {
        locations.add(row.saved);
      }
    }
    return SavedLocationsAvailable(locations: List.unmodifiable(locations));
  }

  void _emit(List<SavedRecord> rows) {
    _events.add(_snapshot(rows));
  }

  @override
  Future<SavedLocationsSnapshot> loadSavedLocations() {
    return _observe(
      'load_saved',
      () => _serialized(() async {
        final SavedLocationsSnapshot result = await _loadSaved();
        if (result is SavedLocationsUnavailable) {
          _events.add(result);
        }
        return result;
      }),
    );
  }

  Future<SavedLocationsSnapshot> _loadSaved() async {
    if (!opened || storage == null) {
      return const SavedLocationsUnavailable(
        failure: SavedLocationFailure.scopeUnavailable,
      );
    }
    try {
      final List<SavedRecord> remote = await storage!.readRemote();
      _rows.clear();
      _rows.addAll(remote);
      _emit(_rows);
      return _snapshot(_rows);
    } on SavedLocationFailure catch (failure) {
      return SavedLocationsUnavailable(failure: failure);
    } catch (_) {
      return const SavedLocationsUnavailable(
        failure: SavedLocationFailure.retryableUnavailable,
      );
    }
  }

  String viewport = 'initial';
  final Map<String, MapLayerContribution> layers = {};
  final StreamController<void> layerChanges =
      StreamController<void>.broadcast();
  Future<MapLayerContributionOutcome> _contribute(
    MapLayerContribution contribution,
  ) async {
    if (!opened) {
      return const MapLayerRejected(failure: MapLayerFailure.scopeUnavailable);
    }
    if (contribution.viewportVersion != viewport) {
      return const MapLayerRejected(failure: MapLayerFailure.staleViewport);
    }
    final Set<String> itemIds = {};
    for (final MapLayerItem item in contribution.items) {
      itemIds.add(item.stableItemId);
    }
    if (contribution.providerId.trim().isEmpty ||
        contribution.layerId.trim().isEmpty ||
        itemIds.length != contribution.items.length) {
      return const MapLayerRejected(
        failure: MapLayerFailure.invalidContribution,
      );
    }
    for (final MapLayerItem item in contribution.items) {
      if (item.stableItemId.isEmpty || item.intent is! ProviderDefinedIntent) {
        return const MapLayerRejected(
          failure: MapLayerFailure.invalidContribution,
        );
      }
      final ProviderDefinedIntent intent = item.intent as ProviderDefinedIntent;
      if (intent.providerId != contribution.providerId ||
          intent.stableItemId != item.stableItemId ||
          intent.action.isEmpty) {
        return const MapLayerRejected(
          failure: MapLayerFailure.invalidContribution,
        );
      }
      if (!finitePoint(item.point)) {
        return const MapLayerRejected(
          failure: MapLayerFailure.invalidCoordinate,
        );
      }
      final bool? valid = await _validate(item.point);
      if (!opened) {
        return const MapLayerRejected(
          failure: MapLayerFailure.scopeUnavailable,
        );
      }
      if (contribution.viewportVersion != viewport) {
        return const MapLayerRejected(failure: MapLayerFailure.staleViewport);
      }
      if (valid == null) {
        return const MapLayerRejected(
          failure: MapLayerFailure.scopeUnavailable,
        );
      }
      if (!valid) {
        return const MapLayerRejected(failure: MapLayerFailure.outsideMalaysia);
      }
    }
    layers['${contribution.providerId}/${contribution.layerId}'] =
        MapLayerContribution(
          providerId: contribution.providerId,
          layerId: contribution.layerId,
          viewportVersion: contribution.viewportVersion,
          visibility: contribution.visibility,
          items: List.unmodifiable(contribution.items),
        );
    layerChanges.add(null);
    if (contribution.visibility == MapLayerVisibility.hidden) {
      return const MapLayerHidden();
    }
    return const MapLayerAccepted();
  }

  Future<MapLayerIntentOutcome> _requestLongPress(GeographicPoint point) async {
    if (!opened) {
      return const MapLayerIntentRejected(
        failure: MapLayerFailure.scopeUnavailable,
      );
    }
    if (!finitePoint(point)) {
      return const MapLayerIntentRejected(
        failure: MapLayerFailure.invalidCoordinate,
      );
    }
    final String version = viewport;
    final bool? valid = await _validate(point);
    if (!opened) {
      return const MapLayerIntentRejected(
        failure: MapLayerFailure.scopeUnavailable,
      );
    }
    if (version != viewport) {
      return const MapLayerIntentRejected(
        failure: MapLayerFailure.staleViewport,
      );
    }
    if (valid == null) {
      return const MapLayerIntentRejected(
        failure: MapLayerFailure.scopeUnavailable,
      );
    }
    if (!valid) {
      return const MapLayerIntentRejected(
        failure: MapLayerFailure.outsideMalaysia,
      );
    }
    return MapLayerIntentAccepted(
      intent: CreateHazardIntent(
        location: ValidLocationReference(
          locationId: '${point.latitude},${point.longitude}',
          point: point,
        ),
      ),
    );
  }

  static bool finitePoint(GeographicPoint p) {
    return p.latitude.isFinite &&
        p.longitude.isFinite &&
        p.latitude >= -90 &&
        p.latitude <= 90 &&
        p.longitude >= -180 &&
        p.longitude <= 180;
  }
}
