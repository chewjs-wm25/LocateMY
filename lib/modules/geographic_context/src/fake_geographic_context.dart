import 'package:locatemy/modules/geographic_context/geographic_context.dart';

import '../geographic_context.dart';

class FakeGeographicContext implements GeographicContext {
  final GeographicContextOutcome? presetOutcome;

  FakeGeographicContext({this.presetOutcome});

  @override
  Future<GeographicContextOutcome> resolve(GeographicContextRequest request) async {
    if (presetOutcome != null) return presetOutcome!;

    final sampleProvenance = BoundaryProvenance(
      datasetId: 'dosm_admin_2026',
      sourceUri: Uri.parse('https://data.gov.my/datasets/dosm_boundaries'),
      sourceVersion: 'v1.0.0',
      sourceSha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      derivedGeometrySha256: 'a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e',
      importedAt: DateTime.utc(2026, 1, 1),
    );

    final results = <GeographicLevel, GeographicLevelOutcome>{};

    if (request.levels.contains(GeographicLevel.district)) {
      results[GeographicLevel.district] = GeographicLevelResolved(
        const AdministrativeArea(
          level: GeographicLevel.district,
          stableId: 'MY-14-01',
          name: 'Kuala Lumpur',
          reportingStateId: 'MY-14',
          reportingStateName: 'W.P. Kuala Lumpur',
        ),
        sampleProvenance,
      );
    }

    if (request.levels.contains(GeographicLevel.reportingState)) {
      results[GeographicLevel.reportingState] = GeographicLevelResolved(
        const AdministrativeArea(
          level: GeographicLevel.reportingState,
          stableId: 'MY-14',
          name: 'W.P. Kuala Lumpur',
          reportingStateId: 'MY-14',
          reportingStateName: 'W.P. Kuala Lumpur',
        ),
        sampleProvenance,
      );
    }

    return GeographicContextAvailable(results);
  }
}