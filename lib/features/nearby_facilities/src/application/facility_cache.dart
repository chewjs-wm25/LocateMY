import '../domain/facility_models.dart';

abstract interface class FacilityCache {
  Future<OverpassFacilityComplete?> read(String key);
  Future<void> write(String key, OverpassFacilityComplete result);
}
