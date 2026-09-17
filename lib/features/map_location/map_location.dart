export 'src/application/map_runtime.dart' show MapLocationRuntime;
export 'src/domain/location_intents.dart';
export 'src/presentation/map_location_page.dart';

import 'package:sqflite/sqflite.dart';
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

import '../account_privacy/account_privacy.dart';
import 'src/domain/location_models.dart';
import 'src/application/location_service.dart';
import 'src/application/location_storage.dart';
export 'src/application/location_storage.dart';

LocationCoordinator createLocationCoordinator({
  required AccountScope scope,
  required AccountScopeSnapshot Function() readScope,
  required Future<bool> Function(GeographicPoint) validatePoint,
  LocationStorage? storage,
  void Function(Map<String, Object>)? diagnosticSink,
}) {
  return LocationService(
    scope: scope,
    readScope: readScope,
    validatePoint: validatePoint,
    storage: storage,
    diagnosticSink: diagnosticSink,
  );
}

AccountPrivacyParticipant locationPrivacyParticipant(
  LocationCoordinator locations,
) {
  return locations as LocationService;
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
  required Database database,
  required String accountId,
}) {
  return LocationStore(client, database, accountId);
}

Future<bool> validateLocationInMalaysia(
  SupabaseClient client,
  GeographicPoint point,
) {
  return validateMalaysiaPoint(client, point);
}
