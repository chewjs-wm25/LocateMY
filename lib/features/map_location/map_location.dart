export 'src/application/location_summary_reader.dart';
export 'src/application/map_runtime.dart' show MapLocationRuntime;
export 'src/presentation/map_location_page.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/data/location_store.dart';

import 'package:http/http.dart' as http;

import 'src/data/geoapify_search.dart';
import 'src/application/location_search.dart';
import 'src/application/map_workspace.dart';
export 'src/application/map_workspace.dart';
export 'src/application/location_search.dart'
    show
        LocationSearch,
        LocationSearchOutcome,
        LocationSearchAvailable,
        LocationSearchUnavailable,
        LocationSearchCandidate;
export 'src/domain/location_models.dart';

import 'src/domain/location_models.dart';
import 'src/application/location_service.dart';
import 'src/application/location_storage.dart';
export 'src/application/location_storage.dart';

LocationCoordinator createLocationCoordinator({
  required String accountId,
  required Future<bool> Function(GeographicPoint) validatePoint,
  LocationStorage? storage,
  void Function(Map<String, Object>)? diagnosticSink,
}) {
  return LocationService(
    accountId: accountId,
    validatePoint: validatePoint,
    storage: storage,
    diagnosticSink: diagnosticSink,
  );
}

MapLayerHost locationLayerHost(LocationCoordinator locations) {
  return locations as LocationService;
}

MapWorkspace locationWorkspace(LocationCoordinator locations) {
  return locations as LocationService;
}

void setLocationViewport(LocationCoordinator locations, String version) {
  locationWorkspace(locations).setViewport(version);
}

LocationSearch createLocationSearch({
  required String apiKey,
  http.Client? client,
}) {
  return GeoapifySearch(apiKey, client ?? http.Client());
}

LocationStorage createLocationStorage({
  required SupabaseClient client,
  required String accountId,
}) {
  return LocationStore(client, accountId);
}

Future<bool> validateLocationInMalaysia(
  SupabaseClient client,
  GeographicPoint point,
) {
  return validateMalaysiaPoint(client, point);
}
