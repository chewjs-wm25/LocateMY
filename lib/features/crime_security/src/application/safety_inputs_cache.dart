

import 'package:locatemy/features/map_location/map_location.dart';

abstract interface class SafetyInputsCache {
  Future<SafetyCachedScope?> readScope(ValidLocationReference location);
  Future<void> writeScope(
    ValidLocationReference location,
    SafetyCachedScope scope,
  );
  Future<Map<String, Object?>?> read();
  Future<void> write(Map<String, Object?> inputs, DateTime fetched);
}



final class SafetyCachedScope {
  final String state;
  final String boundaryVersion;
  final Map<String, Object?> inputs;
  final DateTime capturedAt;
  SafetyCachedScope(
    String state,
    String boundaryVersion,
    Map<String, Object?> inputs,
    DateTime capturedAt,
  ) : state = state,
      boundaryVersion = boundaryVersion,
      inputs = inputs,
      capturedAt = capturedAt;
}
