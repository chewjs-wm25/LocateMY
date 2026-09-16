import 'package:locatemy/features/map_location/map_location.dart';

abstract interface class GeographicContext {
  Future<GeographicContextOutcome> resolve(GeographicContextRequest request);
}

enum GeographicLevel { district, reportingState }

final class GeographicContextRequest {
  final ValidLocationReference location;
  final Set<GeographicLevel> levels;

  const GeographicContextRequest({
    required this.location,
    required this.levels,
  });
}

sealed class GeographicContextOutcome {
  const GeographicContextOutcome();
}

final class GeographicContextAvailable extends GeographicContextOutcome {
  final Map<GeographicLevel, GeographicLevelOutcome> results;
  const GeographicContextAvailable(this.results);
}

final class GeographicContextUnavailable extends GeographicContextOutcome {
  final GeographicContextFailure failure;
  final BoundaryProvenance? provenance;
  const GeographicContextUnavailable(this.failure, {this.provenance});
}

sealed class GeographicLevelOutcome {
  const GeographicLevelOutcome();
}

final class GeographicLevelResolved extends GeographicLevelOutcome {
  final AdministrativeArea area;
  final BoundaryProvenance provenance;
  const GeographicLevelResolved(this.area, this.provenance);
}

final class GeographicLevelUnresolved extends GeographicLevelOutcome {
  final GeographicContextFailure failure;
  final BoundaryProvenance? provenance;
  const GeographicLevelUnresolved(this.failure, {this.provenance});
}

final class GeographicLevelAmbiguous extends GeographicLevelOutcome {
  final List<AdministrativeArea> candidates;
  final BoundaryProvenance provenance;
  const GeographicLevelAmbiguous(this.candidates, this.provenance);
}

final class AdministrativeArea {
  final GeographicLevel level;
  final String stableId;
  final String name;
  final String reportingStateId;
  final String reportingStateName;

  const AdministrativeArea({
    required this.level,
    required this.stableId,
    required this.name,
    required this.reportingStateId,
    required this.reportingStateName,
  });
}

final class BoundaryProvenance {
  final String datasetId;
  final Uri sourceUri;
  final String sourceVersion;
  final String sourceSha256;
  final String derivedGeometrySha256;
  final DateTime importedAt;

  const BoundaryProvenance({
    required this.datasetId,
    required this.sourceUri,
    required this.sourceVersion,
    required this.sourceSha256,
    required this.derivedGeometrySha256,
    required this.importedAt,
  });
}

enum GeographicContextFailure {
  noCoverage,
  sourceUnavailable,
  versionUnverifiable,
  scopeUnavailable,
}
