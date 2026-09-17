// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:locatemy/modules/geographic_context/geographic_context.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/safety_calculator.dart';
import '../domain/safety_input_rules.dart';
import 'safety_inputs_cache.dart';

import '../domain/safety_models.dart';
import 'safety_inputs_reader.dart';

final class CrimeSecurityService implements CrimeSecurity {
  final GeographicContext _geo;
  final SafetyInputsReader _reader;
  final SafetyInputsCache _cache;
  final DateTime Function() _clock;
  CrimeSecurityService(
    GeographicContext geo,
    SafetyInputsReader reader,
    SafetyInputsCache cache,
    DateTime Function() clock,
  ) : _geo = geo,
      _reader = reader,
      _cache = cache,
      _clock = clock;
  @override
  Future<SafetyAnalysis> analyse(
    ValidLocationReference location, {
    bool refresh = false,
  }) {
    return _analyse(location, refresh);
  }

  Future<SafetyAnalysis> _analyse(
    ValidLocationReference location,
    bool refresh, {
    Map<String, Object?>? sharedInputs,
  }) async {
    final String coordinateKey =
        '${location.point.latitude}:${location.point.longitude}';
    final int version = (_analysisVersions[coordinateKey] ?? 0) + 1;
    _analysisVersions[coordinateKey] = version;
    GeographicContextOutcome context;
    try {
      context = await _geo.resolve(
        GeographicContextRequest(
          location: location,
          levels: const <GeographicLevel>{GeographicLevel.reportingState},
        ),
      );
    } catch (_) {
      final SafetyAnalysis? cached = await _scopeFallback(location);
      if (cached != null) {
        return cached;
      }
      return SafetyAnalysis(
        location: location,
        availability: SafetyAvailability.unavailable,
        failure: SafetyFailure.geographicContext,
        capturedAt: _clock(),
      );
    }
    GeographicLevelOutcome? level;
    if (context is GeographicContextAvailable) {
      level = context.results[GeographicLevel.reportingState];
    }
    if (level is! GeographicLevelResolved) {
      if (context is GeographicContextUnavailable &&
          context.failure == GeographicContextFailure.sourceUnavailable) {
        final SafetyAnalysis? cached = await _scopeFallback(location);
        if (cached != null) {
          return cached;
        }
      }
      return SafetyAnalysis(
        location: location,
        availability: SafetyAvailability.unavailable,
        failure: SafetyFailure.geographicContext,
        capturedAt: _clock(),
      );
    }
    final GeographicLevelResolved resolved = level;
    String state = resolved.area.reportingStateName;
    if (state == 'W.P. Putrajaya') {
      state = 'W.P. Kuala Lumpur';
    }
    if (state == 'W.P. Labuan') {
      state = 'Sabah';
    }
    Map<String, Object?> data;
    try {
      data = sharedInputs ?? await _inputs(refresh);
    } on FormatException {
      return SafetyAnalysis(
        location: location,
        reportingState: state,
        availability: SafetyAvailability.unavailable,
        failure: SafetyFailure.sourceUnverifiable,
        capturedAt: _clock(),
      );
    } catch (_) {
      return SafetyAnalysis(
        location: location,
        reportingState: state,
        availability: SafetyAvailability.unavailable,
        failure: SafetyFailure.sourceUnavailable,
        capturedAt: _clock(),
      );
    }
    final String boundaryVersion =
        '${resolved.provenance.datasetId}:${resolved.provenance.sourceVersion}:${resolved.provenance.derivedGeometrySha256}';
    final SafetyAnalysis analysis = calculateSafety(
      location: location,
      state: state,
      boundaryVersion: boundaryVersion,
      data: data,
      capturedAt: DateTime.parse(data['_input_fetched_at'] as String),
    );
    if (analysis.availability != SafetyAvailability.unavailable &&
        _analysisVersions[coordinateKey] == version) {
      try {
        await _cache.writeScope(
          location,
          SafetyCachedScope(state, boundaryVersion, data, analysis.capturedAt),
        );
      } catch (_) {
        /* Public persistence failure leaves the online result usable. */
      }
    }
    return analysis;
  }

  final Map<String, int> _analysisVersions = <String, int>{};
  Future<SafetyAnalysis?> _scopeFallback(
    ValidLocationReference location,
  ) async {
    final SafetyCachedScope? scope = await _cache.readScope(location);
    if (scope == null) {
      return null;
    }
    return calculateSafety(
      location: location,
      state: scope.state,
      boundaryVersion: scope.boundaryVersion,
      data: scope.inputs,
      capturedAt: scope.capturedAt,
    );
  }

  @override
  Future<SafetyComparison> compare(
    ValidLocationReference a,
    ValidLocationReference b, {
    bool refresh = false,
  }) async {
    Map<String, Object?>? data;
    SafetyFailure? failure;
    try {
      data = await _inputs(refresh);
    } on FormatException {
      failure = SafetyFailure.sourceUnverifiable;
    } catch (_) {
      failure = SafetyFailure.sourceUnavailable;
    }
    if (failure != null) {
      return SafetyComparison(
        a: SafetyAnalysis(
          location: a,
          availability: SafetyAvailability.unavailable,
          failure: failure,
          capturedAt: _clock(),
        ),
        b: SafetyAnalysis(
          location: b,
          availability: SafetyAvailability.unavailable,
          failure: failure,
          capturedAt: _clock(),
        ),
        reason: SafetyComparisonReason.unavailable,
      );
    }
    final List<SafetyAnalysis> sides = await Future.wait<SafetyAnalysis>(
      <Future<SafetyAnalysis>>[
        _analyse(a, false, sharedInputs: data),
        _analyse(b, false, sharedInputs: data),
      ],
    );
    final SafetyAnalysis first = sides[0];
    final SafetyAnalysis second = sides[1];
    SafetyComparisonReason? reason;
    if (first.availability == SafetyAvailability.unavailable ||
        second.availability == SafetyAvailability.unavailable) {
      reason = SafetyComparisonReason.unavailable;
    } else if (first.availability == SafetyAvailability.partial ||
        second.availability == SafetyAvailability.partial) {
      reason = SafetyComparisonReason.incomplete;
    } else if (first.year != second.year ||
        first.boundaryVersion != second.boundaryVersion ||
        first.modelVersion != second.modelVersion ||
        first.sourceSha256 != second.sourceSha256) {
      reason = SafetyComparisonReason.scopeMismatch;
    }
    double? difference;
    if (reason == null) {
      difference = second.score! - first.score!;
    }
    return SafetyComparison(
      a: first,
      b: second,
      difference: difference,
      reason: reason,
    );
  }

  int _generation = 0;
  Future<Map<String, Object?>> _inputs(bool refresh) async {
    final Map<String, Object?>? cached = await _cache.read();
    if (!refresh && cached != null) {
      return cached;
    }
    final int generation = ++_generation;
    try {
      final Map<String, Object?> data = Map<String, Object?>.from(
        await _reader.readSafetyInputs(),
      );
      data['_input_fetched_at'] = _clock().toUtc().toIso8601String();
      validateSafetyInputs(data, _clock());
      if (generation == _generation) {
        try {
          await _cache.write(data, _clock().toUtc());
        } catch (_) {
          // Public cache write failures do not discard a verified online result.
        }
      }
      return data;
    } catch (_) {
      // Recheck expiry after the request: a slow failure cannot revive old data.
      final Map<String, Object?>? fallback = await _cache.read();
      if (fallback != null) {
        return fallback;
      }
      rethrow;
    }
  }
}
