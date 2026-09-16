import '../geographic_context.dart';

class GeographicContextResolver {
  GeographicContextOutcome processCandidates({
    required List<Map<String, dynamic>> rawRows,
    required Set<GeographicLevel> requestedLevels,
  }) {
    if (rawRows.isEmpty) {
      final outcomes = <GeographicLevel, GeographicLevelOutcome>{};
      for (final level in requestedLevels) {
        outcomes[level] = const GeographicLevelUnresolved(
          GeographicContextFailure.noCoverage,
        );
      }
      return GeographicContextAvailable(outcomes);
    }

    final first = rawRows.first;

    if (!_isValidString(first['source_dataset']) ||
        !_isValidString(first['source_url']) ||
        !_isValidString(first['source_version']) ||
        !_isValidString(first['source_sha256']) ||
        !_isValidString(first['derived_geometry_sha256']) ||
        !_isValidString(first['imported_at'])) {
      return const GeographicContextUnavailable(
        GeographicContextFailure.versionUnverifiable,
      );
    }

    final Uri? sourceUri = Uri.tryParse(first['source_url'] as String);
    final DateTime? importedAt = DateTime.tryParse(
      first['imported_at'] as String,
    );

    if (sourceUri == null || !sourceUri.isAbsolute || importedAt == null) {
      return const GeographicContextUnavailable(
        GeographicContextFailure.versionUnverifiable,
      );
    }

    final provenance = BoundaryProvenance(
      datasetId: first['source_dataset'] as String,
      sourceUri: sourceUri,
      sourceVersion: first['source_version'] as String,
      sourceSha256: first['source_sha256'] as String,
      derivedGeometrySha256: first['derived_geometry_sha256'] as String,
      importedAt: importedAt.toUtc(),
    );

    final outcomes = <GeographicLevel, GeographicLevelOutcome>{};

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

    if (requestedLevels.contains(GeographicLevel.reportingState)) {
      final uniqueStateNames = rawRows
          .map((r) => r['state'])
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toSet();

      if (uniqueStateNames.isEmpty) {
        outcomes[GeographicLevel.reportingState] =
            const GeographicLevelUnresolved(
              GeographicContextFailure.versionUnverifiable,
            );
      } else if (uniqueStateNames.length == 1) {
        outcomes[GeographicLevel.reportingState] = GeographicLevelResolved(
          _mapToArea(rawRows.first, GeographicLevel.reportingState),
          provenance,
        );
      } else {
        outcomes[GeographicLevel.reportingState] = GeographicLevelAmbiguous(
          rawRows
              .map((r) => _mapToArea(r, GeographicLevel.reportingState))
              .toList(),
          provenance,
        );
      }
    }

    return GeographicContextAvailable(outcomes);
  }

  bool _isValidString(dynamic val) {
    return val is String && val.trim().isNotEmpty;
  }

  AdministrativeArea _mapToArea(
    Map<String, dynamic> row,
    GeographicLevel level,
  ) {
    final stateName = row['state'] as String;
    final districtName = row['district'] as String;
    final boundaryId = row['boundary_id'] as String;

    if (level == GeographicLevel.reportingState) {
      return AdministrativeArea(
        level: GeographicLevel.reportingState,
        stableId: stateName,
        name: stateName,
        reportingStateId: stateName,
        reportingStateName: stateName,
      );
    }

    return AdministrativeArea(
      level: GeographicLevel.district,
      stableId: boundaryId,
      name: districtName,
      reportingStateId: stateName,
      reportingStateName: stateName,
    );
  }
}
