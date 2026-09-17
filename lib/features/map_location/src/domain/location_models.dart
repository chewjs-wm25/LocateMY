// Explicit parameter types and initialization follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

abstract interface class LocationCoordinator {
  Future<LocationSelectionOutcome> select(LocationSelectionRequest request);
  LocationRoleSnapshot read(LocationRole role);
  Future<LocationSelectionOutcome> swapComparisonLocations();
  Future<SavedLocationOutcome> save(SaveLocationRequest request);
  Future<SavedLocationOutcome> deleteSavedLocation(String savedLocationId);
  Stream<SavedLocationsSnapshot> watchSavedLocations();
  Future<SavedLocationsSnapshot> synchronizeSavedLocations();
}

enum LocationRole { single, locationA, locationB, property }

final class GeographicPoint {
  final double latitude;
  final double longitude;
  const GeographicPoint({required double latitude, required double longitude})
    : latitude = latitude,
      longitude = longitude;
}

final class LocationSelectionRequest {
  final LocationRole role;
  final GeographicPoint point;
  final String? displayName;

  const LocationSelectionRequest({
    required LocationRole role,
    required GeographicPoint point,
    String? displayName,
  }) : role = role,
       point = point,
       displayName = displayName;
}

final class ValidLocationReference {
  final String locationId;
  final GeographicPoint point;
  final String? displayName;

  const ValidLocationReference({
    required String locationId,
    required GeographicPoint point,
    String? displayName,
  }) : locationId = locationId,
       point = point,
       displayName = displayName;
}

sealed class LocationRoleSnapshot {
  const LocationRoleSnapshot();
}

final class LocationPresent extends LocationRoleSnapshot {
  final LocationRole role;
  final ValidLocationReference location;

  const LocationPresent({
    required LocationRole role,
    required ValidLocationReference location,
  }) : role = role,
       location = location;
}

final class LocationAbsent extends LocationRoleSnapshot {
  final LocationRole role;
  const LocationAbsent({required LocationRole role}) : role = role;
}

sealed class LocationSelectionOutcome {
  const LocationSelectionOutcome();
}

final class LocationSelected extends LocationSelectionOutcome {
  final LocationRole role;
  final ValidLocationReference location;

  const LocationSelected({
    required LocationRole role,
    required ValidLocationReference location,
  }) : role = role,
       location = location;
}

final class LocationSelectionRejected extends LocationSelectionOutcome {
  final LocationSelectionFailure failure;

  const LocationSelectionRejected({required LocationSelectionFailure failure})
    : failure = failure;
}

enum LocationSelectionFailure {
  invalidCoordinate,
  outsideMalaysia,
  sameComparisonPoint,
  scopeUnavailable,
}

final class SaveLocationRequest {
  final ValidLocationReference location;
  final String name;
  const SaveLocationRequest({
    required ValidLocationReference location,
    required String name,
  }) : location = location,
       name = name;
}

sealed class SavedLocationOutcome {
  const SavedLocationOutcome();
}

final class SavedLocationSaved extends SavedLocationOutcome {
  final SavedLocation savedLocation;
  const SavedLocationSaved({required SavedLocation savedLocation})
    : savedLocation = savedLocation;
}

final class SavedLocationQueued extends SavedLocationOutcome {
  final SavedLocation savedLocation;
  const SavedLocationQueued({required SavedLocation savedLocation})
    : savedLocation = savedLocation;
}

final class SavedLocationRejected extends SavedLocationOutcome {
  final SavedLocationFailure failure;
  const SavedLocationRejected({required SavedLocationFailure failure})
    : failure = failure;
}

final class SavedLocation {
  final String id;
  final String name;
  final ValidLocationReference location;
  final DateTime createdAt;
  final SavedLocationSyncState syncState;

  const SavedLocation({
    required String id,
    required String name,
    required ValidLocationReference location,
    required DateTime createdAt,
    required SavedLocationSyncState syncState,
  }) : id = id,
       name = name,
       location = location,
       createdAt = createdAt,
       syncState = syncState;
}

enum SavedLocationSyncState { synchronized, queued, retryableFailure }

enum SavedLocationFailure {
  invalidName,
  invalidLocation,
  offlineDeleteUnsupported,
  retryableUnavailable,
  permissionDenied,
  conflict,
  scopeUnavailable,
  notFound,
}

sealed class SavedLocationsSnapshot {
  const SavedLocationsSnapshot();
}

final class SavedLocationsAvailable extends SavedLocationsSnapshot {
  final List<SavedLocation> locations;
  const SavedLocationsAvailable({required List<SavedLocation> locations})
    : locations = locations;
}

final class SavedLocationsUnavailable extends SavedLocationsSnapshot {
  final SavedLocationFailure failure;
  const SavedLocationsUnavailable({required SavedLocationFailure failure})
    : failure = failure;
}

abstract interface class MapLayerHost {
  Future<MapLayerContributionOutcome> contribute(
    MapLayerContribution contribution,
  );
  Future<MapLayerIntentOutcome> requestLongPress(GeographicPoint point);
}

final class MapLayerContribution {
  final String providerId;
  final String layerId;
  final String viewportVersion;
  final MapLayerVisibility visibility;
  final List<MapLayerItem> items;

  const MapLayerContribution({
    required String providerId,
    required String layerId,
    required String viewportVersion,
    required MapLayerVisibility visibility,
    required List<MapLayerItem> items,
  }) : providerId = providerId,
       layerId = layerId,
       viewportVersion = viewportVersion,
       visibility = visibility,
       items = items;
}

enum MapLayerVisibility { visible, hidden }

final class MapLayerItem {
  final String stableItemId;
  final GeographicPoint point;
  final MapLayerIntent intent;

  const MapLayerItem({
    required String stableItemId,
    required GeographicPoint point,
    required MapLayerIntent intent,
  }) : stableItemId = stableItemId,
       point = point,
       intent = intent;
}

sealed class MapLayerIntent {
  const MapLayerIntent();
}

final class ProviderDefinedIntent extends MapLayerIntent {
  final String providerId;
  final String action;
  final String stableItemId;

  const ProviderDefinedIntent({
    required String providerId,
    required String action,
    required String stableItemId,
  }) : providerId = providerId,
       action = action,
       stableItemId = stableItemId;
}

final class CreateHazardIntent extends MapLayerIntent {
  final ValidLocationReference location;
  const CreateHazardIntent({required ValidLocationReference location})
    : location = location;
}

sealed class MapLayerContributionOutcome {
  const MapLayerContributionOutcome();
}

final class MapLayerAccepted extends MapLayerContributionOutcome {
  const MapLayerAccepted();
}

final class MapLayerHidden extends MapLayerContributionOutcome {
  const MapLayerHidden();
}

final class MapLayerRejected extends MapLayerContributionOutcome {
  final MapLayerFailure failure;
  const MapLayerRejected({required MapLayerFailure failure})
    : failure = failure;
}

sealed class MapLayerIntentOutcome {
  const MapLayerIntentOutcome();
}

final class MapLayerIntentAccepted extends MapLayerIntentOutcome {
  final MapLayerIntent intent;
  const MapLayerIntentAccepted({required MapLayerIntent intent})
    : intent = intent;
}

final class MapLayerIntentRejected extends MapLayerIntentOutcome {
  final MapLayerFailure failure;
  const MapLayerIntentRejected({required MapLayerFailure failure})
    : failure = failure;
}

enum MapLayerFailure {
  invalidContribution,
  invalidCoordinate,
  outsideMalaysia,
  scopeUnavailable,
  staleViewport,
  unauthenticated,
}
