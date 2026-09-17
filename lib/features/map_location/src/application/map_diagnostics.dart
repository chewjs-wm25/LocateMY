import 'dart:async';
import 'dart:convert';

import '../domain/location_models.dart';

int _sequence = 0;
void mapDiagnostic(
  String operation,
  String result,
  Duration elapsed, [
  void Function(Map<String, Object>)? sink,
]) {
  final int ms = elapsed.inMilliseconds;
  // Fixed schema, enum outcomes and process-local IDs only. No inputs/payloads.
  String bucket = '10sOrMore';
  if (ms < 100) {
    bucket = 'under100ms';
  } else if (ms < 1000) {
    bucket = 'under1s';
  } else if (ms < 10000) {
    bucket = 'under10s';
  }
  final Map<String, Object> event = <String, Object>{
    'event': 'map.$operation.completed',
    'feature': 'map_location',
    'result': result,
    'duration_bucket': bucket,
    'correlation_id': 'map-${++_sequence}',
  };
  try {
    if (sink != null) {
      sink(event);
    } else {
      Zone.current.print(jsonEncode(event));
    }
  } catch (_) {
    /* Diagnostics never block the operation. */
  }
}

Future<T> observeMap<T>(
  String operation,
  Future<T> Function() run, [
  void Function(Map<String, Object>)? sink,
]) async {
  final Stopwatch watch = Stopwatch();
  watch.start();
  final T outcome = await run();
  String result = 'success';
  if (outcome is LocationSelectionRejected) {
    result = outcome.failure.name;
  } else if (outcome is SavedLocationRejected) {
    result = outcome.failure.name;
  } else if (outcome is SavedLocationsUnavailable) {
    result = outcome.failure.name;
  } else if (outcome is MapLayerRejected) {
    result = outcome.failure.name;
  } else if (outcome is MapLayerIntentRejected) {
    result = outcome.failure.name;
  } else if (outcome is MapLayerHidden) {
    result = 'hidden';
  }
  mapDiagnostic(operation, result, watch.elapsed, sink);
  return outcome;
}
