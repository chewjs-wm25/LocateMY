import 'dart:async';
import 'dart:convert';

import '../domain/facility_models.dart';

int _sequence = 0;

Future<T> observeFacility<T>(
  String operation,
  Future<T> Function() action,
) async {
  final Stopwatch watch = Stopwatch();
  watch.start();
  final T outcome = await action();
  String result = 'success';
  if (outcome is FacilityAnalysisAvailable) {
    result = outcome.analysis.dataState.name;
  } else if (outcome is FacilityAnalysisUnavailable) {
    result = outcome.failure.name;
  } else if (outcome is FacilityComparisonNotComparable) {
    result = outcome.failure.name;
  } else if (outcome is FacilityComparisonUnavailable) {
    result = outcome.failure.name;
  } else if (outcome is FacilityLayerNotPublished) {
    result = outcome.failure.name;
  }
  final int milliseconds = watch.elapsedMilliseconds;
  String duration = '10sOrMore';
  if (milliseconds < 100) {
    duration = 'under100ms';
  } else if (milliseconds < 1000) {
    duration = 'under1s';
  } else if (milliseconds < 10000) {
    duration = 'under10s';
  }
  try {
    Zone.current.print(
      jsonEncode(<String, Object>{
        'event': 'facility.$operation.completed',
        'feature': 'nearby_facilities',
        'result': result,
        'duration_bucket': duration,
        'correlation_id': 'facility-${++_sequence}',
      }),
    );
  } catch (_) {
    // Diagnostics contain no user input and never block the operation.
  }
  return outcome;
}
