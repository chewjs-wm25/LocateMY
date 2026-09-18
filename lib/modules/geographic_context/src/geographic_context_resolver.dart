import 'geographic_context_models.dart';

final class GeographicContextResolver {
  GeographicContextOutcome processCandidates({
    required List<Map<String, dynamic>> rawRows,
    required Set<GeographicLevel> requestedLevels,
  }) {
    if (rawRows.isEmpty) {
      final Map<GeographicLevel, GeographicLevelOutcome> outcomes =
          <GeographicLevel, GeographicLevelOutcome>{};
      for (final level in requestedLevels) {
        outcomes[level] = const GeographicLevelUnresolved(
          GeographicContextFailure.noCoverage,
        );
      }
      return GeographicContextAvailable(Map.unmodifiable(outcomes));
    }

    final List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.of(
      rawRows,
    );
    rows.sort(_compareBoundaryIds);
    const provenanceFields = [
      'source_dataset',
      'source_url',
      'source_version',
      'source_sha256',
      'geometry_transform',
      'derived_geometry_sha256',
      'imported_at',
    ];
    final Map<String, dynamic> first = rows.first;
    for (final row in rows) {
      if (!_hasRequiredStrings(row, provenanceFields)) {
        return const GeographicContextUnavailable(
          GeographicContextFailure.versionUnverifiable,
        );
      }
      if (!_hasMatchingProvenance(row, first, provenanceFields)) {
        return const GeographicContextUnavailable(
          GeographicContextFailure.versionUnverifiable,
        );
      }
    }
    final Uri? sourceUri = Uri.tryParse(first['source_url'] as String);
    final String timestamp = first['imported_at'] as String;
    final DateTime? importedAt = _parseImportedAt(timestamp);
    if (sourceUri == null || !sourceUri.isAbsolute || importedAt == null) {
      return const GeographicContextUnavailable(
        GeographicContextFailure.versionUnverifiable,
      );
    }

    final BoundaryProvenance provenance = BoundaryProvenance(
      datasetId: first['source_dataset'] as String,
      sourceUri: sourceUri,
      sourceVersion: first['source_version'] as String,
      sourceSha256: first['source_sha256'] as String,
      derivedGeometrySha256: first['derived_geometry_sha256'] as String,
      importedAt: importedAt.toUtc(),
    );

    final Map<GeographicLevel, GeographicLevelOutcome> outcomes =
        <GeographicLevel, GeographicLevelOutcome>{};

    if (requestedLevels.contains(GeographicLevel.district)) {
      if (rows.length == 1) {
        outcomes[GeographicLevel.district] = GeographicLevelResolved(
          _mapToArea(rows.first, GeographicLevel.district),
          provenance,
        );
      } else {
        outcomes[GeographicLevel.district] = GeographicLevelAmbiguous(
          _districtCandidates(rows),
          provenance,
        );
      }
    }

    if (requestedLevels.contains(GeographicLevel.reportingState)) {
      final Set<String> uniqueStateNames = _uniqueStateNames(rows);

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
          _reportingStateCandidates(rows, uniqueStateNames),
          provenance,
        );
      }
    }

    return GeographicContextAvailable(Map.unmodifiable(outcomes));
  }

  DateTime? _parseImportedAt(String value) {
    final RegExp pattern = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:Z|[+-](?:[01]\d|2[0-3]):?[0-5]\d)$',
    );
    final RegExpMatch? match = pattern.firstMatch(value);
    if (match == null) {
      return null;
    }
    final List<int> parts = <int>[];
    for (int index = 1; index <= 6; index++) {
      parts.add(int.parse(match.group(index)!));
    }
    final DateTime date = DateTime.utc(parts[0], parts[1], parts[2]);
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

  int _compareBoundaryIds(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    final String leftId = '${left['boundary_id']}';
    final String rightId = '${right['boundary_id']}';
    return leftId.compareTo(rightId);
  }

  bool _hasRequiredStrings(
    Map<String, dynamic> row,
    List<String> provenanceFields,
  ) {
    final List<String> requiredFields = <String>[
      'boundary_id',
      'state',
      'district',
      ...provenanceFields,
    ];
    for (final String field in requiredFields) {
      if (!_isValidString(row[field])) {
        return false;
      }
    }
    return true;
  }

  bool _hasMatchingProvenance(
    Map<String, dynamic> row,
    Map<String, dynamic> firstRow,
    List<String> provenanceFields,
  ) {
    for (final String field in provenanceFields) {
      if (row[field] != firstRow[field]) {
        return false;
      }
    }
    return true;
  }

  Set<String> _uniqueStateNames(List<Map<String, dynamic>> rows) {
    final Set<String> stateNames = <String>{};
    for (final Map<String, dynamic> row in rows) {
      final dynamic state = row['state'];
      if (state is String && state.trim().isNotEmpty) {
        stateNames.add(state);
      }
    }
    return stateNames;
  }

  List<AdministrativeArea> _reportingStateCandidates(
    List<Map<String, dynamic>> rows,
    Set<String> stateNames,
  ) {
    final List<AdministrativeArea> candidates = <AdministrativeArea>[];
    for (final String stateName in stateNames) {
      final Map<String, dynamic> row = rows.firstWhere(
        (Map<String, dynamic> row) => row['state'] == stateName,
      );
      candidates.add(_mapToArea(row, GeographicLevel.reportingState));
    }
    return List<AdministrativeArea>.unmodifiable(candidates);
  }

  List<AdministrativeArea> _districtCandidates(
    List<Map<String, dynamic>> rows,
  ) {
    final List<AdministrativeArea> candidates = <AdministrativeArea>[];
    for (final Map<String, dynamic> row in rows) {
      candidates.add(_mapToArea(row, GeographicLevel.district));
    }
    return List<AdministrativeArea>.unmodifiable(candidates);
  }

  bool _isValidString(dynamic value) {
    return value is String && value.trim().isNotEmpty;
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
