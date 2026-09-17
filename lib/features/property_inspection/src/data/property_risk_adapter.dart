// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/crime_security/crime_security.dart';
import 'package:locatemy/features/hazard_reporting/hazard_reporting.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';

import '../domain/property_models.dart';
import '../application/property_service.dart';

final class PropertyBusinessRiskReader implements PropertyRiskReader {
  final GeographicContext geo;
  final CrimeSecurity crime;
  final HazardRiskCounter hazards;
  PropertyBusinessRiskReader({
    required GeographicContext geo,
    required CrimeSecurity crime,
    required HazardRiskCounter hazards,
  }) : geo = geo,
       crime = crime,
       hazards = hazards;
  @override
  Future<PropertyRiskSnapshot> capture(ValidLocationReference location) async {
    final DateTime now = DateTime.now().toUtc();
    try {
      final GeographicContextOutcome context = await geo.resolve(
        GeographicContextRequest(
          location: location,
          levels: const <GeographicLevel>{GeographicLevel.reportingState},
        ),
      );
      if (context is! GeographicContextAvailable) {
        return PropertyRiskSnapshot.unavailable(now);
      }
      final GeographicLevelOutcome? state =
          context.results[GeographicLevel.reportingState];
      if (state is! GeographicLevelResolved) {
        return PropertyRiskSnapshot.unavailable(now);
      }
      final SafetyAnalysis safety = await crime.analyse(location);
      final HazardNearbyCountOutcome count = await hazards.countPending(
        HazardNearbyCountRequest(location),
      );
      if (safety.availability != SafetyAvailability.complete ||
          safety.score == null ||
          safety.year == null ||
          safety.sourceSha256 == null ||
          safety.boundaryVersion == null ||
          safety.reportingState != state.area.reportingStateName ||
          count is! HazardNearbyCountAvailable ||
          count.radiusMeters != 2000) {
        return PropertyRiskSnapshot.unavailable(now);
      }
      return PropertyRiskSnapshot(<String, Object?>{
        'snapshot_availability': 'available',
        'snapshot_latitude': location.point.latitude,
        'snapshot_longitude': location.point.longitude,
        'reporting_state': safety.reportingState,
        'safety_index': safety.score,
        'safety_source_year': safety.year,
        'safety_source_id': safety.sourceSha256,
        'safety_model_boundary_version':
            '${safety.modelVersion}/${safety.boundaryVersion}',
        'safety_completeness': 'complete',
        'hazard_pending_count': count.count,
        'hazard_radius_m': 2000,
        'hazard_counted_at': count.countedAt.toUtc().toIso8601String(),
        'snapshot_captured_at': now.toIso8601String(),
      });
    } catch (_) {
      return PropertyRiskSnapshot.unavailable(now);
    }
  }
}
