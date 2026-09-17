// Explicit parameter types and initialization follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/map_location/map_location.dart';

abstract interface class NearbyFacilities {
  Future<FacilityAnalysisOutcome> analyse(FacilityAnalysisRequest request);
  Future<FacilityComparisonOutcome> compare(FacilityComparisonRequest request);
  Future<FacilityLayerOutcome> contributeLayer(FacilityLayerRequest request);
}

enum FacilityRefreshPolicy { cacheAllowed, refresh }

final class FacilityAnalysisRequest {
  final ValidLocationReference location;
  final FacilityRefreshPolicy refreshPolicy;
  const FacilityAnalysisRequest({
    required ValidLocationReference location,
    required FacilityRefreshPolicy refreshPolicy,
  }) : location = location,
       refreshPolicy = refreshPolicy;
}

final class FacilityComparisonRequest {
  final ValidLocationReference locationA;
  final ValidLocationReference locationB;
  final FacilityRefreshPolicy refreshPolicy;
  const FacilityComparisonRequest({
    required ValidLocationReference locationA,
    required ValidLocationReference locationB,
    required FacilityRefreshPolicy refreshPolicy,
  }) : locationA = locationA,
       locationB = locationB,
       refreshPolicy = refreshPolicy;
}

final class FacilityLayerRequest {
  final FacilityAnalysis analysis;
  final String viewportVersion;
  const FacilityLayerRequest({
    required FacilityAnalysis analysis,
    required String viewportVersion,
  }) : analysis = analysis,
       viewportVersion = viewportVersion;
}

sealed class FacilityAnalysisOutcome {
  const FacilityAnalysisOutcome();
}

final class FacilityAnalysisAvailable extends FacilityAnalysisOutcome {
  final FacilityAnalysis analysis;
  const FacilityAnalysisAvailable({required FacilityAnalysis analysis})
    : analysis = analysis;
}

final class FacilityAnalysisUnavailable extends FacilityAnalysisOutcome {
  final FacilityFailure failure;
  const FacilityAnalysisUnavailable({required FacilityFailure failure})
    : failure = failure;
}

sealed class FacilityComparisonOutcome {
  const FacilityComparisonOutcome();
}

final class FacilityComparisonAvailable extends FacilityComparisonOutcome {
  final FacilityComparison comparison;
  const FacilityComparisonAvailable({required FacilityComparison comparison})
    : comparison = comparison;
}

final class FacilityComparisonNotComparable extends FacilityComparisonOutcome {
  final FacilityAnalysisOutcome locationA;
  final FacilityAnalysisOutcome locationB;
  final FacilityComparisonFailure failure;
  const FacilityComparisonNotComparable({
    required FacilityAnalysisOutcome locationA,
    required FacilityAnalysisOutcome locationB,
    required FacilityComparisonFailure failure,
  }) : locationA = locationA,
       locationB = locationB,
       failure = failure;
}

final class FacilityComparisonUnavailable extends FacilityComparisonOutcome {
  final FacilityFailure failure;
  const FacilityComparisonUnavailable({required FacilityFailure failure})
    : failure = failure;
}

sealed class FacilityLayerOutcome {
  const FacilityLayerOutcome();
}

final class FacilityLayerPublished extends FacilityLayerOutcome {
  const FacilityLayerPublished();
}

final class FacilityLayerNotPublished extends FacilityLayerOutcome {
  final FacilityLayerFailure failure;
  const FacilityLayerNotPublished({required FacilityLayerFailure failure})
    : failure = failure;
}

enum FacilityFailure {
  invalidLocation,
  sameComparisonPoint,
  sourceUnavailable,
  rateLimited,
  invalidPayload,
  incompleteResponse,
  retryableUnavailable,
  scopeUnavailable,
}

enum FacilityComparisonFailure {
  locationAUnavailable,
  locationBUnavailable,
  incompleteResult,
  incompatibleRadius,
  incompatibleMappingVersion,
}

enum FacilityLayerFailure {
  analysisUnavailable,
  analysisIncomplete,
  mapUnavailable,
  staleViewport,
  scopeUnavailable,
}

final class FacilityAnalysis {
  final ValidLocationReference location;
  final int radiusMetres;
  final String mappingVersion;
  final FacilityDataState dataState;
  final DateTime observedAt;
  final FacilityAttribution attribution;
  final List<FacilityCategoryResult> categories;
  const FacilityAnalysis({
    required ValidLocationReference location,
    required int radiusMetres,
    required String mappingVersion,
    required FacilityDataState dataState,
    required DateTime observedAt,
    required FacilityAttribution attribution,
    required List<FacilityCategoryResult> categories,
  }) : location = location,
       radiusMetres = radiusMetres,
       mappingVersion = mappingVersion,
       dataState = dataState,
       observedAt = observedAt,
       attribution = attribution,
       categories = categories;
}

enum FacilityDataState { fresh, cached }

final class FacilityCategoryResult {
  final FacilityCategory category;
  final FacilityCategoryState state;
  final List<NearbyFacility> nearest;
  final int? count;
  const FacilityCategoryResult({
    required FacilityCategory category,
    required FacilityCategoryState state,
    required List<NearbyFacility> nearest,
    int? count,
  }) : category = category,
       state = state,
       nearest = nearest,
       count = count;
}

enum FacilityCategory {
  health,
  education,
  dailyLiving,
  transport,
  leisureGreen,
}

enum FacilityCategoryState { covered, completeEmpty, unknown }

final class NearbyFacility {
  final String stableId;
  final String displayName;
  final GeographicPoint point;
  final double distanceMetres;
  const NearbyFacility({
    required String stableId,
    required String displayName,
    required GeographicPoint point,
    required double distanceMetres,
  }) : stableId = stableId,
       displayName = displayName,
       point = point,
       distanceMetres = distanceMetres;
}

final class FacilityAttribution {
  final String source;
  final Uri copyrightUrl;
  const FacilityAttribution({required String source, required Uri copyrightUrl})
    : source = source,
      copyrightUrl = copyrightUrl;
}

final class FacilityComparison {
  final FacilityAnalysis locationA;
  final FacilityAnalysis locationB;
  const FacilityComparison({
    required FacilityAnalysis locationA,
    required FacilityAnalysis locationB,
  }) : locationA = locationA,
       locationB = locationB;
}

abstract interface class OverpassFacilitySource {
  Future<OverpassFacilityOutcome> query(OverpassFacilityQuery query);
}

final class OverpassFacilityQuery {
  final GeographicPoint centre;
  final int radiusMetres;
  final String mappingVersion;
  const OverpassFacilityQuery({
    required GeographicPoint centre,
    required int radiusMetres,
    required String mappingVersion,
  }) : centre = centre,
       radiusMetres = radiusMetres,
       mappingVersion = mappingVersion;
}

sealed class OverpassFacilityOutcome {
  const OverpassFacilityOutcome();
}

final class OverpassFacilityComplete extends OverpassFacilityOutcome {
  final List<OverpassElement> elements;
  final DateTime queriedAt;
  const OverpassFacilityComplete({
    required List<OverpassElement> elements,
    required DateTime queriedAt,
  }) : elements = elements,
       queriedAt = queriedAt;
}

final class OverpassFacilityFailed extends OverpassFacilityOutcome {
  final OverpassFailure failure;
  const OverpassFacilityFailed({required OverpassFailure failure})
    : failure = failure;
}

final class OverpassFacilityPartial extends OverpassFacilityOutcome {
  final OverpassFailure failure;
  const OverpassFacilityPartial({required OverpassFailure failure})
    : failure = failure;
}

enum OverpassFailure {
  timeout,
  rateLimited,
  networkUnavailable,
  invalidPayload,
  responseTruncated,
  cancelled,
}

final class OverpassElement {
  final String elementType;
  final String osmId;
  final GeographicPoint representativePoint;
  final Map<String, String> tags;
  const OverpassElement({
    required String elementType,
    required String osmId,
    required GeographicPoint representativePoint,
    required Map<String, String> tags,
  }) : elementType = elementType,
       osmId = osmId,
       representativePoint = representativePoint,
       tags = tags;
}

final class OpenNearbyFacilitiesIntent implements ShellIntent {
  final ValidLocationReference location;
  final Object? returnContext;
  const OpenNearbyFacilitiesIntent({
    required ValidLocationReference location,
    Object? returnContext,
  }) : location = location,
       returnContext = returnContext;
}

final class OpenNearbyFacilitiesComparisonIntent implements ShellIntent {
  final ValidLocationReference locationA;
  final ValidLocationReference locationB;
  final Object? returnContext;
  const OpenNearbyFacilitiesComparisonIntent({
    required ValidLocationReference locationA,
    required ValidLocationReference locationB,
    Object? returnContext,
  }) : locationA = locationA,
       locationB = locationB,
       returnContext = returnContext;
}

final class NearbyFacilitiesSummaryContribution implements ShellContribution {
  final ValidLocationReference location;
  final FacilityAnalysisOutcome outcome;
  final Object? returnContext;
  const NearbyFacilitiesSummaryContribution({
    required ValidLocationReference location,
    required FacilityAnalysisOutcome outcome,
    Object? returnContext,
  }) : location = location,
       outcome = outcome,
       returnContext = returnContext;
}

final class NearbyFacilitiesComparisonContribution
    implements ShellContribution {
  final ValidLocationReference locationA;
  final ValidLocationReference locationB;
  final FacilityComparisonOutcome outcome;
  final Object? returnContext;
  const NearbyFacilitiesComparisonContribution({
    required ValidLocationReference locationA,
    required ValidLocationReference locationB,
    required FacilityComparisonOutcome outcome,
    Object? returnContext,
  }) : locationA = locationA,
       locationB = locationB,
       outcome = outcome,
       returnContext = returnContext;
}
