// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:locatemy/features/map_location/map_location.dart';

abstract interface class PublicTransportation {
  Future<TransitLoadOutcome> load(TransitRequest request);
  Future<TransitComparisonOutcome> compare(TransitComparisonRequest request);
}

final class TransitRequest {
  final ValidLocationReference location;
  final DateTime analysisDate;
  final TransitLoadPolicy policy;
  const TransitRequest({
    required ValidLocationReference location,
    required DateTime analysisDate,
    required TransitLoadPolicy policy,
  }) : location = location,
       analysisDate = analysisDate,
       policy = policy;
}

enum TransitLoadPolicy { cacheAllowed, refresh }

sealed class TransitLoadOutcome {
  const TransitLoadOutcome();
}

final class TransitAvailable extends TransitLoadOutcome {
  final TransitSnapshot snapshot;
  const TransitAvailable(TransitSnapshot snapshot) : snapshot = snapshot;
}

final class TransitIncomplete extends TransitLoadOutcome {
  final TransitPartialSnapshot snapshot;
  const TransitIncomplete(TransitPartialSnapshot snapshot)
    : snapshot = snapshot;
}

final class TransitUnavailable extends TransitLoadOutcome {
  final TransitUnavailableReason reason;
  final List<FeedStatus> feeds;
  const TransitUnavailable(
    TransitUnavailableReason reason,
    List<FeedStatus> feeds,
  ) : reason = reason,
      feeds = feeds;
}

enum TransitUnavailableReason {
  noUsableFeed,
  analysisDateOutsideServiceRange,
  retryableUnavailable,
  sourceUnverifiable,
}

enum TransitServiceOutcome { served, noStops, noActiveRoutes }

enum TransitStationType { bus, rail, ferry, other }

enum FeedAvailability { usable, stale, missing, failed, outOfServiceRange }

final class TransitScore {
  final int value;
  const TransitScore(int value) : value = value;
}

final class TransitStation {
  final String feedId;
  final String stopId;
  final String name;
  final GeographicPoint point;
  final TransitStationType type;
  final int distanceMeters;
  final String? parentStation;
  const TransitStation({
    required String feedId,
    required String stopId,
    required String name,
    required GeographicPoint point,
    required TransitStationType type,
    required int distanceMeters,
    String? parentStation,
  }) : feedId = feedId,
       stopId = stopId,
       name = name,
       point = point,
       type = type,
       distanceMeters = distanceMeters,
       parentStation = parentStation;
}

final class FeedStatus {
  final String feedId;
  final String sourceId;
  final Uri sourceUrl;
  final DateTime? capturedAt;
  final FeedAvailability availability;
  final String? reason;
  const FeedStatus({
    required String feedId,
    required String sourceId,
    required Uri sourceUrl,
    required DateTime? capturedAt,
    required FeedAvailability availability,
    required String? reason,
  }) : feedId = feedId,
       sourceId = sourceId,
       sourceUrl = sourceUrl,
       capturedAt = capturedAt,
       availability = availability,
       reason = reason;
}

final class TransitProvenance {
  final String snapshotId;
  final String referenceGridVersion;
  final DateTime generatedAt;
  const TransitProvenance({
    required String snapshotId,
    required String referenceGridVersion,
    required DateTime generatedAt,
  }) : snapshotId = snapshotId,
       referenceGridVersion = referenceGridVersion,
       generatedAt = generatedAt;
}

final class TransitSnapshot {
  final ValidLocationReference location;
  final DateTime analysisDate;
  final int radiusMeters;
  final List<TransitStation> stations;
  final int uniqueStopCount;
  final int? nearestDistanceMeters;
  final int uniqueRouteCount;
  final TransitServiceOutcome serviceOutcome;
  final TransitScore? score;
  final List<FeedStatus> feeds;
  final TransitProvenance provenance;
  const TransitSnapshot({
    required ValidLocationReference location,
    required DateTime analysisDate,
    required int radiusMeters,
    required List<TransitStation> stations,
    required int uniqueStopCount,
    required int? nearestDistanceMeters,
    required int uniqueRouteCount,
    required TransitServiceOutcome serviceOutcome,
    required TransitScore? score,
    required List<FeedStatus> feeds,
    required TransitProvenance provenance,
  }) : location = location,
       analysisDate = analysisDate,
       radiusMeters = radiusMeters,
       stations = stations,
       uniqueStopCount = uniqueStopCount,
       nearestDistanceMeters = nearestDistanceMeters,
       uniqueRouteCount = uniqueRouteCount,
       serviceOutcome = serviceOutcome,
       score = score,
       feeds = feeds,
       provenance = provenance;
}

final class TransitPartialSnapshot {
  final ValidLocationReference location;
  final DateTime analysisDate;
  final int radiusMeters;
  final List<TransitStation> stations;
  final int uniqueStopCount;
  final int? nearestDistanceMeters;
  final int uniqueRouteCount;
  final List<FeedStatus> feeds;
  final TransitProvenance provenance;
  const TransitPartialSnapshot({
    required ValidLocationReference location,
    required DateTime analysisDate,
    required int radiusMeters,
    required List<TransitStation> stations,
    required int uniqueStopCount,
    required int? nearestDistanceMeters,
    required int uniqueRouteCount,
    required List<FeedStatus> feeds,
    required TransitProvenance provenance,
  }) : location = location,
       analysisDate = analysisDate,
       radiusMeters = radiusMeters,
       stations = stations,
       uniqueStopCount = uniqueStopCount,
       nearestDistanceMeters = nearestDistanceMeters,
       uniqueRouteCount = uniqueRouteCount,
       feeds = feeds,
       provenance = provenance;
}

final class TransitComparisonRequest {
  final TransitRequest a;
  final TransitRequest b;
  const TransitComparisonRequest(TransitRequest a, TransitRequest b)
    : a = a,
      b = b;
}

sealed class TransitComparisonOutcome {
  const TransitComparisonOutcome();
}

final class TransitComparable extends TransitComparisonOutcome {
  final TransitSnapshot a;
  final TransitSnapshot b;
  const TransitComparable(TransitSnapshot a, TransitSnapshot b) : a = a, b = b;
}

final class TransitIncomparable extends TransitComparisonOutcome {
  final TransitLoadOutcome a;
  final TransitLoadOutcome b;
  final TransitComparisonReason reason;
  const TransitIncomparable(
    TransitLoadOutcome a,
    TransitLoadOutcome b,
    TransitComparisonReason reason,
  ) : a = a,
      b = b,
      reason = reason;
}

enum TransitComparisonReason {
  sideUnavailable,
  sideIncomplete,
  analysisDateMismatch,
  radiusMismatch,
  provenanceMismatch,
  serviceOutcomeNotScored,
}
