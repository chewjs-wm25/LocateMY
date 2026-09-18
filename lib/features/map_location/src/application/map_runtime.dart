import '../domain/location_models.dart';
import 'location_service.dart';
import 'location_storage.dart';


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
