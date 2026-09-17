// Explicit constructor initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/home_models.dart';
import '../domain/home_trends.dart';
import '../application/home_dependencies.dart';

final class HomeViewModel extends ChangeNotifier {
  final HomeRelocationOutlook home;
  final void Function() onExploreMap;
  HomeOutlookSnapshot? snapshot;
  HomeTrendHistory trendHistory = const HomeTrendHistory({});
  HomeUnavailableReason? unavailable;
  String? navigationReason;
  bool busy = false;
  int remainingSeconds = 0;
  bool _disposed = false;
  Timer? _timer;

  HomeViewModel(HomeRelocationOutlook home, void Function() onExploreMap)
    : home = home,
      onExploreMap = onExploreMap;

  Future<void> initialize() {
    return _load(HomeLoadRequest.cacheAllowed);
  }

  Future<void> refresh() {
    return _load(HomeLoadRequest.refresh);
  }

  Future<void> _load(HomeLoadRequest request) async {
    if (_disposed ||
        busy ||
        (request == HomeLoadRequest.refresh && remainingSeconds > 0)) {
      return;
    }
    busy = true;
    notifyListeners();
    late final HomeLoadOutcome result;
    try {
      result = await home.load(request);
    } catch (_) {
      result = HomeUnavailable(
        reason: HomeUnavailableReason.retryableUnavailable,
      );
    }
    if (_disposed) {
      return;
    }
    busy = false;
    switch (result) {
      case HomeLoaded(:final snapshot):
        this.snapshot = snapshot;
        if (home case final HomeTrendReader reader) {
          trendHistory = reader.trendHistory;
        }
        unavailable = null;
        final bool invalid = _hasUnverifiableMetric(snapshot);
        if (request == HomeLoadRequest.refresh &&
            snapshot.freshness == HomeDataFreshness.fresh &&
            !invalid) {
          _cool(60);
        }
      case HomeRefreshCoolingDown(:final snapshot, :final remainingSeconds):
        this.snapshot = snapshot;
        if (home case final HomeTrendReader reader) {
          trendHistory = reader.trendHistory;
        }
        unavailable = null;
        _cool(remainingSeconds);
      case HomeUnavailable(:final reason):
        unavailable = reason;
    }
    notifyListeners();
  }

  bool _hasUnverifiableMetric(HomeOutlookSnapshot snapshot) {
    final List<MetricUnavailableReason?> reasons = <MetricUnavailableReason?>[
      snapshot.costPressure.unavailableReason,
      snapshot.employmentStability.unavailableReason,
      snapshot.economicMomentum.unavailableReason,
      snapshot.householdMedianIncome.unavailableReason,
    ];
    for (final MetricUnavailableReason? reason in reasons) {
      if (reason == MetricUnavailableReason.sourceSchemaChanged ||
          reason == MetricUnavailableReason.sourceDataUnverifiable) {
        return true;
      }
    }
    return false;
  }

  void _cool(int seconds) {
    _timer?.cancel();
    remainingSeconds = seconds;
    final DateTime until = DateTime.now().add(Duration(seconds: seconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      remainingSeconds =
          (until.difference(DateTime.now()).inMilliseconds / 1000).ceil().clamp(
            0,
            60,
          );
      if (remainingSeconds == 0) {
        timer.cancel();
      }
      notifyListeners();
    });
  }

  Future<void> explore() async {
    if (_disposed) {
      return;
    }
    onExploreMap();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
