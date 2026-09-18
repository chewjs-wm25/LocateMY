


import 'geographic_context_models.dart';

final class FakeGeographicContext implements GeographicContext {
  final GeographicContextOutcome? presetOutcome;

  FakeGeographicContext({GeographicContextOutcome? presetOutcome})
    : presetOutcome = presetOutcome;

  @override
  Future<GeographicContextOutcome> resolve(
    GeographicContextRequest request,
  ) async {
    final Set<GeographicLevel> levels = Set<GeographicLevel>.unmodifiable(
      request.levels,
    );
    if (levels.isEmpty) {
      throw ArgumentError.value(levels, 'levels', 'must not be empty');
    }
    final GeographicContextOutcome? preset = presetOutcome;
    if (preset is GeographicContextAvailable) {
      final Map<GeographicLevel, GeographicLevelOutcome> results =
          <GeographicLevel, GeographicLevelOutcome>{};
      for (final level in levels) {
        final GeographicLevelOutcome? outcome = preset.results[level];
        if (outcome == null) {
          throw StateError('Fake preset is missing requested level');
        }
        if (outcome is GeographicLevelAmbiguous) {
          results[level] = GeographicLevelAmbiguous(
            List<AdministrativeArea>.unmodifiable(outcome.candidates),
            outcome.provenance,
          );
        } else {
          results[level] = outcome;
        }
      }
      return GeographicContextAvailable(Map.unmodifiable(results));
    }
    if (preset != null) {
      return preset;
    }

    final BoundaryProvenance sampleProvenance = BoundaryProvenance(
      datasetId: 'dosm_admin_2026',
      sourceUri: Uri.parse('https://data.gov.my/datasets/dosm_boundaries'),
      sourceVersion: 'v1.0.0',
      sourceSha256:
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      derivedGeometrySha256:
          'a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e',
      importedAt: DateTime.utc(2026, 1, 1),
    );

    final Map<GeographicLevel, GeographicLevelOutcome> results =
        <GeographicLevel, GeographicLevelOutcome>{};

    if (request.levels.contains(GeographicLevel.district)) {
      results[GeographicLevel.district] = GeographicLevelResolved(
        const AdministrativeArea(
          level: GeographicLevel.district,
          stableId: 'MY-14-01',
          name: 'Kuala Lumpur',
          reportingStateId: 'W.P. Kuala Lumpur',
          reportingStateName: 'W.P. Kuala Lumpur',
        ),
        sampleProvenance,
      );
    }

    if (request.levels.contains(GeographicLevel.reportingState)) {
      results[GeographicLevel.reportingState] = GeographicLevelResolved(
        const AdministrativeArea(
          level: GeographicLevel.reportingState,
          stableId: 'W.P. Kuala Lumpur',
          name: 'W.P. Kuala Lumpur',
          reportingStateId: 'W.P. Kuala Lumpur',
          reportingStateName: 'W.P. Kuala Lumpur',
        ),
        sampleProvenance,
      );
    }

    return GeographicContextAvailable(Map.unmodifiable(results));
  }
}
