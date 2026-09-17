// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:locatemy/features/map_location/map_location.dart';

enum SafetyAvailability { complete, partial, unavailable }

enum SafetyFailure {
  geographicContext,
  sourceUnverifiable,
  sourceUnavailable,
  noData,
}

enum SafetyComparisonReason { unavailable, incomplete, scopeMismatch }

final class SafetyComparison {
  final SafetyAnalysis a;
  final SafetyAnalysis b;
  final double? difference;
  final SafetyComparisonReason? reason;
  const SafetyComparison({
    required SafetyAnalysis a,
    required SafetyAnalysis b,
    double? difference,
    SafetyComparisonReason? reason,
  }) : a = a,
       b = b,
       difference = difference,
       reason = reason;
}

abstract interface class CrimeSecurity {
  Future<SafetyComparison> compare(
    ValidLocationReference a,
    ValidLocationReference b, {
    bool refresh = false,
  });
  Future<SafetyAnalysis> analyse(
    ValidLocationReference location, {
    bool refresh = false,
  });
}

final class CrimeYearCount {
  final int year;
  final int? count;
  const CrimeYearCount(int year, int? count) : year = year, count = count;
}

final class SafetyAnalysis {
  final ValidLocationReference location;
  final String? reportingState;
  final int? year;
  final double? score;
  final int? latestCount;
  final SafetyAvailability availability;
  final SafetyFailure? failure;
  final String modelVersion;
  final String? boundaryVersion;
  final String? sourceSha256;
  final DateTime capturedAt;
  final Map<String, List<CrimeYearCount>> trends;
  SafetyAnalysis({
    required ValidLocationReference location,
    String? reportingState,
    int? year,
    double? score,
    int? latestCount,
    required SafetyAvailability availability,
    SafetyFailure? failure,
    String modelVersion = 'safety-state-v1',
    String? boundaryVersion,
    String? sourceSha256,
    required DateTime capturedAt,
    Map<String, List<CrimeYearCount>> trends =
        const <String, List<CrimeYearCount>>{},
  }) : location = location,
       reportingState = reportingState,
       year = year,
       score = score,
       latestCount = latestCount,
       availability = availability,
       failure = failure,
       modelVersion = modelVersion,
       boundaryVersion = boundaryVersion,
       sourceSha256 = sourceSha256,
       capturedAt = capturedAt,
       trends = _freezeTrends(trends);
}

Map<String, List<CrimeYearCount>> _freezeTrends(
  Map<String, List<CrimeYearCount>> trends,
) {
  final Map<String, List<CrimeYearCount>> copy =
      <String, List<CrimeYearCount>>{};
  for (final MapEntry<String, List<CrimeYearCount>> entry in trends.entries) {
    copy[entry.key] = List<CrimeYearCount>.unmodifiable(entry.value);
  }
  return Map<String, List<CrimeYearCount>>.unmodifiable(copy);
}
