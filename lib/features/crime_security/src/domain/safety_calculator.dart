import 'dart:math' as math;

import 'package:locatemy/features/map_location/map_location.dart';

import 'safety_models.dart';

SafetyAnalysis calculateSafety({
  required ValidLocationReference location,
  required String state,
  required String boundaryVersion,
  required Map<String, Object?> data,
  required DateTime capturedAt,
}) {
  final List<dynamic> rows = data['rows'] as List<dynamic>;
  final Map<String, Map<String, int>> totals = <String, Map<String, int>>{};
  for (final dynamic raw in rows) {
    final Map<String, dynamic> r = Map<String, dynamic>.from(raw as Map);
    if (r['state'] == 'Malaysia' || r['type'] == 'all') {
      continue;
    }
    if (r['year'] != data['latest_complete_year']) {
      continue;
    }
    final String category = r['category'] as String;
    final String s = r['state'] as String;
    final Map<String, int> states = totals.putIfAbsent(category, () {
      return <String, int>{};
    });
    states[s] = (states[s] ?? 0) + (r['crimes'] as int);
  }
  double risk = 0;
  int count = 0;
  double availableWeight = 0;
  int categories = 0;
  for (final String category in <String>['assault', 'property']) {
    final Map<String, int>? states = totals[category];
    if (states == null || states[state] == null) {
      continue;
    }
    final int value = states[state]!;
    int lower = 0;
    for (final int other in states.values) {
      if (math.log(1 + other) <= math.log(1 + value)) {
        lower++;
      }
    }
    double weight = 0.4;
    if (category == 'assault') {
      weight = 0.6;
    }
    risk += weight * 100 * lower / states.length;
    count += value;
    availableWeight += weight;
    categories++;
  }
  final int year = data['latest_complete_year'] as int;
  final Map<String, Map<int, int>> series = <String, Map<int, int>>{
    'assault': <int, int>{},
    'property': <int, int>{},
  };
  for (final dynamic raw in rows) {
    final Map<String, dynamic> row = Map<String, dynamic>.from(raw as Map);
    if (row['state'] != state || row['type'] == 'all') {
      continue;
    }
    final int y = row['year'] as int;
    if (y < year - 4 || y > year) {
      continue;
    }
    for (final String key in <String>[
      row['category'] as String,
      'type:${row['type']}',
    ]) {
      final Map<int, int> values = series.putIfAbsent(key, () {
        return <int, int>{};
      });
      values[y] = (values[y] ?? 0) + (row['crimes'] as int);
    }
  }
  series['all'] = <int, int>{};
  for (int y = year - 4; y <= year; y++) {
    final int? assault = series['assault']![y];
    final int? property = series['property']![y];
    if (assault != null && property != null) {
      series['all']![y] = assault + property;
    }
  }
  final Map<String, List<CrimeYearCount>> trends =
      <String, List<CrimeYearCount>>{};
  for (final MapEntry<String, Map<int, int>> entry in series.entries) {
    final List<CrimeYearCount> points = <CrimeYearCount>[];
    for (int y = year - 4; y <= year; y++) {
      points.add(CrimeYearCount(y, entry.value[y]));
    }
    trends[entry.key] = List<CrimeYearCount>.unmodifiable(points);
  }
  SafetyAvailability availability = SafetyAvailability.partial;
  if (categories == 2) {
    availability = SafetyAvailability.complete;
  }
  double? score;
  SafetyFailure? failure;
  int? latestCount;
  if (categories == 0) {
    availability = SafetyAvailability.unavailable;
    failure = SafetyFailure.noData;
  } else {
    score = (100 - risk / availableWeight).clamp(0, 100).toDouble();
  }
  if (categories == 2) {
    latestCount = count;
  }
  bool hasHistory = false;
  for (final Map<int, int> values in series.values) {
    if (values.isNotEmpty) {
      hasHistory = true;
      break;
    }
  }
  if (!hasHistory) {
    trends.clear();
  }
  return SafetyAnalysis(
    location: location,
    reportingState: state,
    boundaryVersion: boundaryVersion,
    sourceSha256: data['source_sha256'] as String,
    trends: trends,
    year: data['latest_complete_year'] as int,
    score: score,
    failure: failure,
    latestCount: latestCount,
    availability: availability,
    capturedAt: capturedAt,
  );
}
