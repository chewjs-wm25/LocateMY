import 'package:locatemy/features/map_location/map_location.dart';


abstract interface class CrimeAndSecurity {
  Future<SafetyLoadOutcome> load(SafetyRequest request);
  Future<SafetyComparisonOutcome> compare(SafetyComparisonRequest request);
}


final class CrimeReturnToMapIntent {
  final ValidLocationReference location;
  final Object? returnContext;

  const CrimeReturnToMapIntent({required this.location, this.returnContext});
}


final class OpenCrimeSecurityIntent {
  final ValidLocationReference location;
  final Object? returnContext;

  const OpenCrimeSecurityIntent({required this.location, this.returnContext});
}


final class OpenCrimeSecurityComparisonIntent {
  final ValidLocationReference locationA;
  final ValidLocationReference locationB;
  final Object? returnContext;

  const OpenCrimeSecurityComparisonIntent({
    required this.locationA,
    required this.locationB,
    this.returnContext,
  });
}


final class PropertyArchiveIntent {
  final Object? returnContext;

  const PropertyArchiveIntent({this.returnContext});
}


final class PropertyAddIntent {
  final Object? returnContext;

  const PropertyAddIntent({this.returnContext});
}

final class SafetyRequest {
  final ValidLocationReference location;
  final SafetyLoadPolicy policy;
  final SafetyTrendFilter filter;

  const SafetyRequest({
    required this.location,
    required this.policy,
    required this.filter,
  });
}

enum SafetyLoadPolicy { cacheAllowed, refresh }

sealed class SafetyTrendFilter {
  const SafetyTrendFilter();
}

final class AllCrimeTrend extends SafetyTrendFilter {
  const AllCrimeTrend();
}

final class CategoryTrend extends SafetyTrendFilter {
  final CrimeCategory category;
  const CategoryTrend(this.category);
}

final class TypeTrend extends SafetyTrendFilter {
  final String type;
  const TypeTrend(this.type);
}

enum CrimeCategory { assault, property }

sealed class SafetyLoadOutcome {
  const SafetyLoadOutcome();
}

final class SafetyAvailable extends SafetyLoadOutcome {
  final SafetySnapshot snapshot;
  const SafetyAvailable(this.snapshot);
}

final class SafetyPartiallyAvailable extends SafetyLoadOutcome {
  final SafetySnapshot snapshot;
  const SafetyPartiallyAvailable(this.snapshot);
}

final class SafetyUnavailable extends SafetyLoadOutcome {
  final SafetyUnavailableReason reason;
  const SafetyUnavailable(this.reason);
}

final class SafetySnapshot {
  final ValidLocationReference location;
  final ReportingState state;
  final SafetyScore score;
  final AnnualCrimeCount latestCompleteYearCount;
  final SafetyTrend trend;
  final List<SafetyTrendFilter> availableFilters;
  final SafetyFreshness freshness;
  final SafetyCompleteness completeness;
  final SafetyProvenance provenance;

  const SafetySnapshot({
    required this.location,
    required this.state,
    required this.score,
    required this.latestCompleteYearCount,
    required this.trend,
    required this.availableFilters,
    required this.freshness,
    required this.completeness,
    required this.provenance,
  });
}

enum SafetyFreshness { fresh, cached, stale }

enum SafetyCompleteness { complete, partial }

enum SafetyUnavailableReason {
  stateUnresolved,
  stateAmbiguous,
  sourceMissing,
  noValidCategory,
  incompleteYear,
  retryableUnavailable,
  sourceUnverifiable,
}

final class SafetyScore {
  final int value;
  const SafetyScore(this.value);
}

final class AnnualCrimeCount {
  final int value;
  final int year;
  const AnnualCrimeCount(this.value, this.year);
}

final class SafetyTrend {
  final SafetyTrendFilter filter;
  final List<AnnualCrimePoint> points;
  const SafetyTrend(this.filter, this.points);
}

final class AnnualCrimePoint {
  final int year;
  final int convictedCases;
  const AnnualCrimePoint(this.year, this.convictedCases);
}

final class ReportingState {
  final String stableId;
  final String name;
  const ReportingState(this.stableId, this.name);
}

final class SafetyProvenance {
  final String source;
  final String modelVersion;
  final String boundaryVersion;
  const SafetyProvenance({
    required this.source,
    required this.modelVersion,
    required this.boundaryVersion,
  });
}

final class SafetyComparisonRequest {
  final SafetyRequest a;
  final SafetyRequest b;
  const SafetyComparisonRequest(this.a, this.b);
}

sealed class SafetyComparisonOutcome {
  const SafetyComparisonOutcome();
}

final class SafetyComparable extends SafetyComparisonOutcome {
  final SafetySnapshot a;
  final SafetySnapshot b;
  const SafetyComparable(this.a, this.b);
}

final class SafetyIncomparable extends SafetyComparisonOutcome {
  final SafetyLoadOutcome a;
  final SafetyLoadOutcome b;
  final SafetyComparisonReason reason;
  const SafetyIncomparable(this.a, this.b, this.reason);
}

enum SafetyComparisonReason {
  sideUnavailable,
  yearMismatch,
  completenessMismatch,
  provenanceMismatch,
}
