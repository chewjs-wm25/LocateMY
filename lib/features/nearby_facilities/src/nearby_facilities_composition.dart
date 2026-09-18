import 'package:sqflite/sqflite.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import 'domain/facility_models.dart';
import 'application/nearby_facilities_service.dart';
import 'data/facility_cache.dart';

NearbyFacilities createNearbyFacilities({
  required OverpassFacilitySource source,
  Database? database,
  DateTime Function()? clock,
  MapLayerHost Function()? mapLayerHost,
}) {
  return NearbyFacilitiesService(
    source,
    cache: PublicFacilityCache(database),
    clock: clock,
    mapLayerHost: mapLayerHost,
  );
}
