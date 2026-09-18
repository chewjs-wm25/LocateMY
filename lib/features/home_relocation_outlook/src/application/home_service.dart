import 'dart:async';
import 'dart:convert';

import '../domain/home_models.dart';
import '../domain/home_scoring.dart';
import '../domain/home_trends.dart';
import 'home_dependencies.dart';

final class HomeService implements HomeRelocationOutlook, HomeTrendReader {
  @override
  HomeTrendHistory trendHistory = const HomeTrendHistory({});
  final HomeReader reader;
  final PublicHomeCache cache;
  final DateTime Function() clock;
  HomeOutlookSnapshot? _snapshot;
  DateTime? _lastRefresh;

  HomeService(this.reader, this.cache, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  Future<HomeLoadOutcome>? _inFlight;

  @override
  Future<HomeLoadOutcome> load(HomeLoadRequest request) {
    final Future<HomeLoadOutcome>? existingLoad = _inFlight;
    if (existingLoad != null) {
      return existingLoad;
    }
    final Future<HomeLoadOutcome> newLoad = _observedLoad(request)
        .whenComplete(() {
          _inFlight = null;
        });
    _inFlight = newLoad;
    return newLoad;
  }

  static int _eventSequence = 0;
  Future<HomeLoadOutcome> _observedLoad(HomeLoadRequest request) async {
    final Stopwatch elapsed = Stopwatch();
    elapsed.start();
    final HomeLoadOutcome outcome = await _execute(request);
    final String result = _resultName(outcome);
    final int milliseconds = elapsed.elapsedMilliseconds;
    
    Zone.current.print(
      jsonEncode({
        'event': 'home.load.completed',
        'feature': 'home_relocation_outlook',
        'result': result,
        'duration_bucket': _durationBucket(milliseconds),
        'correlation_id': 'home-${++_eventSequence}',
      }),
    );
    return outcome;
  }

  String _resultName(HomeLoadOutcome outcome) {
    if (outcome is HomeRefreshCoolingDown) {
      return 'cooldown';
    }
    if (outcome is HomeUnavailable) {
      return outcome.reason.name;
    }
    final HomeOutlookSnapshot snapshot = (outcome as HomeLoaded).snapshot;
    if (snapshot.freshness == HomeDataFreshness.fresh &&
        snapshot.completeness == HomeCompleteness.partial) {
      return 'partial';
    }
    return snapshot.freshness.name;
  }

  String _durationBucket(int milliseconds) {
    if (milliseconds < 100) {
      return 'under100ms';
    }
    if (milliseconds < 1000) {
      return 'under1s';
    }
    if (milliseconds < 10000) {
      return 'under10s';
    }
    return '10sOrMore';
  }

  Future<HomeLoadOutcome> _execute(HomeLoadRequest request) async {
    final DateTime? last = _lastRefresh;
    if (request == HomeLoadRequest.refresh &&
        last != null &&
        _snapshot != null) {
      final int remaining = 60000 - clock().difference(last).inMilliseconds;
      if (remaining > 0) {
        return HomeRefreshCoolingDown(
          snapshot: _snapshot!,
          remainingSeconds: (remaining / 1000).ceil(),
        );
      }
    }
    _snapshot ??= await cache.read();
    try {
      final Map<String, dynamic> payload = await reader.read();
      final HomeOutlookSnapshot? snapshot = scoreHome(payload, clock().toUtc());
      if (snapshot != null) {
        final HomeOutlookSnapshot? previous = _snapshot;
        if (previous != null && regresses(snapshot, previous)) {
          return _fallback(HomeUnavailableReason.sourceDataUnverifiable);
        }
        _snapshot = snapshot;
        trendHistory = reconstructHomeTrends(
          payload,
          snapshot,
          clock().toUtc(),
        );
        final bool verifiable = _isVerifiable(snapshot);
        if (verifiable && (previous == null || isNewer(snapshot, previous))) {
          await cache.write(snapshot);
        }
        if (verifiable && request == HomeLoadRequest.refresh) {
          _lastRefresh = clock();
        }
        return HomeLoaded(snapshot: snapshot);
      }
      return _fallback(HomeUnavailableReason.noCachedResult);
    } on HomeReadFailure catch (e) {
      return _fallback(e.reason);
    } catch (_) {
      return _fallback(HomeUnavailableReason.sourceDataUnverifiable);
    }
  }

  bool _isVerifiable(HomeOutlookSnapshot snapshot) {
    final List<MetricUnavailableReason?> reasons = <MetricUnavailableReason?>[
      snapshot.costPressure.unavailableReason,
      snapshot.employmentStability.unavailableReason,
      snapshot.economicMomentum.unavailableReason,
      snapshot.householdMedianIncome.unavailableReason,
    ];
    for (final MetricUnavailableReason? reason in reasons) {
      if (reason == MetricUnavailableReason.sourceSchemaChanged ||
          reason == MetricUnavailableReason.sourceDataUnverifiable) {
        return false;
      }
    }
    return true;
  }

  HomeLoadOutcome _fallback(HomeUnavailableReason reason) {
    final HomeOutlookSnapshot? snapshot = _snapshot;
    if (snapshot == null) {
      return HomeUnavailable(reason: reason);
    }
    final HomeDataFreshness freshness;
    if (clock().difference(snapshot.fetchedAt) >= const Duration(days: 1)) {
      freshness = HomeDataFreshness.stale;
    } else {
      freshness = HomeDataFreshness.cached;
    }
    return HomeLoaded(snapshot: withFreshness(snapshot, freshness));
  }
}

HomeOutlookSnapshot withFreshness(
  HomeOutlookSnapshot snapshot,
  HomeDataFreshness freshness,
) {
  return HomeOutlookSnapshot(
    freshness: freshness,
    completeness: snapshot.completeness,
    relocationTiming: snapshot.relocationTiming,
    costPressure: snapshot.costPressure,
    employmentStability: snapshot.employmentStability,
    economicMomentum: snapshot.economicMomentum,
    householdMedianIncome: snapshot.householdMedianIncome,
    fetchedAt: snapshot.fetchedAt,
  );
}

Map<String, DateTime> sourceDates(HomeOutlookSnapshot snapshot) {
  final Map<String, DateTime> dates = <String, DateTime>{};
  final List<MetricSource> sources = <MetricSource>[
    ...snapshot.relocationTiming.sources,
    snapshot.householdMedianIncome.source,
  ];
  for (final MetricSource source in sources) {
    dates[source.datasetId] = source.observedAt;
  }
  return dates;
}

bool regresses(HomeOutlookSnapshot candidate, HomeOutlookSnapshot previous) {
  final Map<String, DateTime> candidateDates = sourceDates(candidate);
  final Map<String, DateTime> previousDates = sourceDates(previous);
  for (final MapEntry<String, DateTime> entry in previousDates.entries) {
    final DateTime? candidateDate = candidateDates[entry.key];
    if (candidateDate == null || candidateDate.isBefore(entry.value)) {
      return true;
    }
  }
  return false;
}

bool isNewer(HomeOutlookSnapshot candidate, HomeOutlookSnapshot previous) {
  final Map<String, DateTime> previousDates = sourceDates(previous);
  final Map<String, DateTime> candidateDates = sourceDates(candidate);
  for (final MapEntry<String, DateTime> entry in candidateDates.entries) {
    final DateTime? previousDate = previousDates[entry.key];
    if (previousDate == null || entry.value.isAfter(previousDate)) {
      return true;
    }
  }
  return false;
}
