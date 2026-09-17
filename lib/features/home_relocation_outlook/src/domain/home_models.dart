abstract interface class HomeRelocationOutlook {
  Future<HomeLoadOutcome> load(HomeLoadRequest request);
}

enum HomeLoadRequest { cacheAllowed, refresh }

sealed class HomeLoadOutcome {}

final class HomeLoaded extends HomeLoadOutcome {
  HomeLoaded({required this.snapshot});

  final HomeOutlookSnapshot snapshot;
}

final class HomeRefreshCoolingDown extends HomeLoadOutcome {
  HomeRefreshCoolingDown({
    required this.snapshot,
    required this.remainingSeconds,
  });

  final HomeOutlookSnapshot snapshot;
  final int remainingSeconds;
}

final class HomeUnavailable extends HomeLoadOutcome {
  HomeUnavailable({required this.reason});

  final HomeUnavailableReason reason;
}

final class HomeOutlookSnapshot {
  HomeOutlookSnapshot({
    required this.freshness,
    required this.completeness,
    required this.relocationTiming,
    required this.costPressure,
    required this.employmentStability,
    required this.economicMomentum,
    required this.householdMedianIncome,
    required this.fetchedAt,
  });

  final HomeDataFreshness freshness;
  final HomeCompleteness completeness;
  final RelocationTimingCard relocationTiming;
  final MacroMetricCard costPressure;
  final MacroMetricCard employmentStability;
  final MacroMetricCard economicMomentum;
  final HouseholdIncomeCard householdMedianIncome;
  final DateTime fetchedAt;
}

enum HomeDataFreshness { fresh, cached, stale }

enum HomeCompleteness { complete, partial }

enum MetricAvailability { available, unavailable }

enum HomeUnavailableReason {
  retryableUnavailable,
  noCachedResult,
  sourceSchemaChanged,
  sourceDataUnverifiable,
}

enum MetricUnavailableReason {
  sourceMissing,
  sourceSchemaChanged,
  insufficientHistory,
  sourceDataUnverifiable,
  retryableUnavailable,
}

final class RelocationTimingCard {
  RelocationTimingCard({
    required this.availability,
    required this.score,
    required this.scoreUnit,
    required this.status,
    required this.reasons,
    required this.sources,
    required this.unavailableReason,
  });

  final MetricAvailability availability;
  final int? score;
  final String? scoreUnit;
  final String? status;
  final List<RelocationReason> reasons;
  final List<MetricSource> sources;
  final MetricUnavailableReason? unavailableReason;
}

final class RelocationReason {
  RelocationReason({required this.text, required this.source});

  final String text;
  final MetricSource source;
}

final class MacroMetricCard {
  MacroMetricCard({
    required this.availability,
    required this.score,
    required this.scoreUnit,
    required this.directionExplanation,
    required this.source,
    required this.unavailableReason,
  });

  final MetricAvailability availability;
  final int? score;
  final String? scoreUnit;
  final String? directionExplanation;
  final MetricSource source;
  final MetricUnavailableReason? unavailableReason;
}

final class HouseholdIncomeCard {
  HouseholdIncomeCard({
    required this.availability,
    required this.medianIncome,
    required this.currencyUnit,
    required this.surveyYear,
    required this.priceBasisExplanation,
    required this.source,
    required this.unavailableReason,
  });

  final MetricAvailability availability;
  final num? medianIncome;
  final String? currencyUnit;
  final int? surveyYear;
  final String? priceBasisExplanation;
  final MetricSource source;
  final MetricUnavailableReason? unavailableReason;
}

final class MetricSource {
  MetricSource({required this.datasetId, required this.observedAt});

  final String datasetId;
  final DateTime observedAt;
}
