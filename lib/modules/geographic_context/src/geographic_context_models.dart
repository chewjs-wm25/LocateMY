// Explicit constructor parameters make immutable field initialization visible.
// ignore_for_file: prefer_initializing_formals

import 'package:locatemy/features/map_location/map_location.dart';

abstract interface class GeographicContext {
  Future<GeographicContextOutcome> resolve(GeographicContextRequest request);
}

enum GeographicLevel { district, reportingState }

final class GeographicContextRequest {
  final ValidLocationReference location;
  final Set<GeographicLevel> levels;

  const GeographicContextRequest({
    required ValidLocationReference location,
    required Set<GeographicLevel> levels,
  }) : location = location,
       levels = levels;
}

sealed class GeographicContextOutcome {
  const GeographicContextOutcome();
}

final class GeographicContextAvailable extends GeographicContextOutcome {
  final Map<GeographicLevel, GeographicLevelOutcome> results;
  const GeographicContextAvailable(
    Map<GeographicLevel, GeographicLevelOutcome> results,
  ) : results = results;
}

final class GeographicContextUnavailable extends GeographicContextOutcome {
  final GeographicContextFailure failure;
  final BoundaryProvenance? provenance;
  const GeographicContextUnavailable(
    GeographicContextFailure failure, {
    BoundaryProvenance? provenance,
  }) : failure = failure,
       provenance = provenance;
}

sealed class GeographicLevelOutcome {
  const GeographicLevelOutcome();
}

final class GeographicLevelResolved extends GeographicLevelOutcome {
  final AdministrativeArea area;
  final BoundaryProvenance provenance;
  const GeographicLevelResolved(
    AdministrativeArea area,
    BoundaryProvenance provenance,
  ) : area = area,
      provenance = provenance;
}

final class GeographicLevelUnresolved extends GeographicLevelOutcome {
  final GeographicContextFailure failure;
  final BoundaryProvenance? provenance;
  const GeographicLevelUnresolved(
    GeographicContextFailure failure, {
    BoundaryProvenance? provenance,
  }) : failure = failure,
       provenance = provenance;
}

final class GeographicLevelAmbiguous extends GeographicLevelOutcome {
  final List<AdministrativeArea> candidates;
  final BoundaryProvenance provenance;
  const GeographicLevelAmbiguous(
    List<AdministrativeArea> candidates,
    BoundaryProvenance provenance,
  ) : candidates = candidates,
      provenance = provenance;
}

final class AdministrativeArea {
  final GeographicLevel level;
  final String stableId;
  final String name;
  final String reportingStateId;
  final String reportingStateName;

  const AdministrativeArea({
    required GeographicLevel level,
    required String stableId,
    required String name,
    required String reportingStateId,
    required String reportingStateName,
  }) : level = level,
       stableId = stableId,
       name = name,
       reportingStateId = reportingStateId,
       reportingStateName = reportingStateName;
}

final class BoundaryProvenance {
  final String datasetId;
  final Uri sourceUri;
  final String sourceVersion;
  final String sourceSha256;
  final String derivedGeometrySha256;
  final DateTime importedAt;

  const BoundaryProvenance({
    required String datasetId,
    required Uri sourceUri,
    required String sourceVersion,
    required String sourceSha256,
    required String derivedGeometrySha256,
    required DateTime importedAt,
  }) : datasetId = datasetId,
       sourceUri = sourceUri,
       sourceVersion = sourceVersion,
       sourceSha256 = sourceSha256,
       derivedGeometrySha256 = derivedGeometrySha256,
       importedAt = importedAt;
}

enum GeographicContextFailure {
  noCoverage,
  sourceUnavailable,
  versionUnverifiable,
  scopeUnavailable,
}
