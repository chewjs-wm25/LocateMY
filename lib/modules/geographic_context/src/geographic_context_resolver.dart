import 'geographic_context_models.dart';

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
      return GeographicContextAvailable(Map.unmodifiable(outcomes));
    }

    final rows = List<Map<String, dynamic>>.of(rawRows)
      ..sort((a, b) => '${a['boundary_id']}'.compareTo('${b['boundary_id']}'));
    const provenanceFields = [
      'source_dataset',
      'source_url',
      'source_version',
      'source_sha256',
      'geometry_transform',
      'derived_geometry_sha256',
      'imported_at',
    ];
    final first = rows.first;
    for (final row in rows) {
      if ([
        'boundary_id',
        'state',
        'district',
        ...provenanceFields,
      ].any((key) => !_isValidString(row[key]))) {
        return const GeographicContextUnavailable(
          GeographicContextFailure.versionUnverifiable,
        );
      }
      if (provenanceFields.any((key) => row[key] != first[key])) {
        return const GeographicContextUnavailable(
          GeographicContextFailure.versionUnverifiable,
        );
      }
    }
    final sourceUri = Uri.tryParse(first['source_url'] as String);
    final timestamp = first['imported_at'] as String;
    final importedAt = _parseImportedAt(timestamp);
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
      if (rows.length == 1) {
        outcomes[GeographicLevel.district] = GeographicLevelResolved(
          _mapToArea(rows.first, GeographicLevel.district),
          provenance,
        );
      } else {
        outcomes[GeographicLevel.district] = GeographicLevelAmbiguous(
          List.unmodifiable(
            rows.map((r) => _mapToArea(r, GeographicLevel.district)),
          ),
          provenance,
        );
      }
    }

    if (requestedLevels.contains(GeographicLevel.reportingState)) {
      final uniqueStateNames = rows
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
          _mapToArea(rows.first, GeographicLevel.reportingState),
          provenance,
        );
      } else {
        outcomes[GeographicLevel.reportingState] = GeographicLevelAmbiguous(
          List.unmodifiable(
            uniqueStateNames.map(
              (state) => _mapToArea(
                rows.firstWhere((row) => row['state'] == state),
                GeographicLevel.reportingState,
              ),
            ),
          ),
          provenance,
        );
      }
    }

    return GeographicContextAvailable(Map.unmodifiable(outcomes));
  }

  DateTime? _parseImportedAt(String value) {
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:Z|[+-](?:[01]\d|2[0-3]):?[0-5]\d)$',
    ).firstMatch(value);
    if (match == null) {
      return null;
    }
    final parts = [for (var i = 1; i <= 6; i++) int.parse(match.group(i)!)];
    final date = DateTime.utc(parts[0], parts[1], parts[2]);
    if (date.year != parts[0] ||
        date.month != parts[1] ||
        date.day != parts[2] ||
        parts[3] > 23 ||
        parts[4] > 59 ||
        parts[5] > 59) {
      return null;
    }
    return DateTime.tryParse(value)?.toUtc();
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
