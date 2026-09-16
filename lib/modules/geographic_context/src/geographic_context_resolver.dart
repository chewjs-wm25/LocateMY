import 'package:locatemy/modules/geographic_context/geographic_context.dart';

class GeographicContextResolver {
  GeographicContextOutcome processCandidates({
    required List<Map<String, dynamic>> rawRows,
    required Set<GeographicLevel> requestedLevels,
  }) {
    if (rawRows.isEmpty) {
      final outcomes = <GeographicLevel, GeographicLevelOutcome>{};
      for (final level in requestedLevels) {
        outcomes[level] = const GeographicLevelUnresolved(GeographicContextFailure.noCoverage);
      }
      return GeographicContextAvailable(outcomes);
    }

    // Verify presence of provenance fields across rows
    final first = rawRows.first;
    if (first['source_dataset'] == null ||
        first['source_url'] == null ||
        first['source_version'] == null ||
        first['source_sha256'] == null ||
        first['derived_geometry_sha256'] == null ||
        first['imported_at'] == null) {
      return const GeographicContextUnavailable(GeographicContextFailure.versionUnverifiable);
    }

    final provenance = BoundaryProvenance(
      datasetId: first['source_dataset'] as String,
      sourceUri: Uri.parse(first['source_url'] as String),
      sourceVersion: first['source_version'] as String,
      sourceSha256: first['source_sha256'] as String,
      derivedGeometrySha256: first['derived_geometry_sha256'] as String,
      importedAt: DateTime.parse(first['imported_at'] as String).toUtc(),
    );

    final outcomes = <GeographicLevel, GeographicLevelOutcome>{};

    // 1. Resolve District Level
    if (requestedLevels.contains(GeographicLevel.district)) {
      if (rawRows.length == 1) {
        outcomes[GeographicLevel.district] = GeographicLevelResolved(
          _mapToArea(rawRows.first, GeographicLevel.district),
          provenance,
        );
      } else {
        outcomes[GeographicLevel.district] = GeographicLevelAmbiguous(
          rawRows.map((r) => _mapToArea(r, GeographicLevel.district)).toList(),
          provenance,
        );
      }
    }

    // 2. Resolve Reporting State Level
    if (requestedLevels.contains(GeographicLevel.reportingState)) {
      final uniqueStateIds = rawRows.map((r) => r['state']['id'] as String).toSet();

      if (uniqueStateIds.length == 1) {
        outcomes[GeographicLevel.reportingState] = GeographicLevelResolved(
          _mapToArea(rawRows.first, GeographicLevel.reportingState),
          provenance,
        );
      } else {
        outcomes[GeographicLevel.reportingState] = GeographicLevelAmbiguous(
          rawRows.map((r) => _mapToArea(r, GeographicLevel.reportingState)).toList(),
          provenance,
        );
      }
    }

    return GeographicContextAvailable(outcomes);
  }

  AdministrativeArea _mapToArea(Map<String, dynamic> row, GeographicLevel level) {
    final state = row['state'] as Map<String, dynamic>;
    final district = row['district'] as Map<String, dynamic>;

    if (level == GeographicLevel.reportingState) {
      return AdministrativeArea(
        level: GeographicLevel.reportingState,
        stableId: state['id'] as String,
        name: state['name'] as String,
        reportingStateId: state['id'] as String,
        reportingStateName: state['name'] as String,
      );
    }

    return AdministrativeArea(
      level: GeographicLevel.district,
      stableId: row['boundary_id'] as String,
      name: district['name'] as String,
      reportingStateId: state['id'] as String,
      reportingStateName: state['name'] as String,
    );
  }
}