import '../domain/location_models.dart';
import 'location_service.dart';
import 'location_storage.dart';

/// Owned by the signed-in page tree and replaced when its account changes.
final class MapLocationRuntime {
  final LocationCoordinator locations;
  MapLocationRuntime({
    required String accountId,
    required Future<bool> Function(GeographicPoint) validatePoint,
    required LocationStorage Function(String) storageForAccount,
  }) : locations = LocationService(
         accountId: accountId,
         validatePoint: validatePoint,
         storage: storageForAccount(accountId),
       );
}
