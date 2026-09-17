// Explicit constructors follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/facility_models.dart';

final class FacilitiesViewModel extends ChangeNotifier {
  final NearbyFacilities facilities;
  final ValidLocationReference location;
  final ValidLocationReference? locationB;
  final ApplicationShell? shell;
  final Object? returnContext;
  FacilityAnalysisOutcome? outcome;
  FacilityComparisonOutcome? comparison;
  DateTime? attemptedAt;
  bool loading = false;
  int _generation = 0;
  bool _disposed = false;

  FacilitiesViewModel({
    required NearbyFacilities facilities,
    required ValidLocationReference location,
    ValidLocationReference? locationB,
    ApplicationShell? shell,
    Object? returnContext,
  }) : facilities = facilities,
       location = location,
       locationB = locationB,
       shell = shell,
       returnContext = returnContext;

  Future<void> load([
    FacilityRefreshPolicy policy = FacilityRefreshPolicy.cacheAllowed,
  ]) async {
    if (_disposed || loading) {
      return;
    }
    final int generation = ++_generation;
    loading = true;
    outcome = null;
    comparison = null;
    attemptedAt = DateTime.now();
    notifyListeners();
    try {
      final ValidLocationReference? second = locationB;
      if (second == null) {
        final FacilityAnalysisOutcome result = await facilities.analyse(
          FacilityAnalysisRequest(location: location, refreshPolicy: policy),
        );
        if (_disposed || generation != _generation) {
          return;
        }
        outcome = result;
        final ApplicationShell? target = shell;
        if (target != null) {
          await target.publish(
            NearbyFacilitiesSummaryContribution(
              location: location,
              outcome: result,
              returnContext: returnContext,
            ),
          );
        }
      } else {
        final FacilityComparisonOutcome result = await facilities.compare(
          FacilityComparisonRequest(
            locationA: location,
            locationB: second,
            refreshPolicy: policy,
          ),
        );
        if (_disposed || generation != _generation) {
          return;
        }
        comparison = result;
        final ApplicationShell? target = shell;
        if (target != null) {
          await target.publish(
            NearbyFacilitiesComparisonContribution(
              locationA: location,
              locationB: second,
              outcome: result,
              returnContext: returnContext,
            ),
          );
        }
      }
    } catch (_) {
      if (!_disposed && generation == _generation) {
        outcome = const FacilityAnalysisUnavailable(
          failure: FacilityFailure.retryableUnavailable,
        );
        comparison = const FacilityComparisonUnavailable(
          failure: FacilityFailure.retryableUnavailable,
        );
      }
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation += 1;
    super.dispose();
  }
}
