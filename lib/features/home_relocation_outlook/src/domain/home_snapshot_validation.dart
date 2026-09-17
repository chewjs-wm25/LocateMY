import 'home_models.dart';
import 'home_scoring.dart' show homeDatasetIds;

bool validCachedHome(HomeOutlookSnapshot snapshot, DateTime now) {
  if (snapshot.fetchedAt.isAfter(now)) return false;
  bool scoreValid(int? score) => score != null && score >= 0 && score <= 100;
  bool sourceValid(MetricSource source, {bool mustBeObserved = false}) =>
      homeDatasetIds.contains(source.datasetId) &&
      (!mustBeObserved ||
          !source.observedAt.isAtSameMomentAs(DateTime.utc(1970))) &&
      !source.observedAt.isAfter(snapshot.fetchedAt) &&
      source.observedAt.day == 1;
  final metrics = [
    snapshot.costPressure,
    snapshot.employmentStability,
    snapshot.economicMomentum,
  ];
  for (var i = 0; i < metrics.length; i++) {
    final m = metrics[i];
    if (m.source.datasetId != homeDatasetIds[i] ||
        !sourceValid(
          m.source,
          mustBeObserved: m.availability == MetricAvailability.available,
        )) {
      return false;
    }
    if (m.availability == MetricAvailability.available) {
      if (!scoreValid(m.score) ||
          m.scoreUnit != 'points/100' ||
          m.directionExplanation == null ||
          m.unavailableReason != null) {
        return false;
      }
    } else if (m.score != null ||
        m.scoreUnit != null ||
        m.unavailableReason == null) {
      return false;
    }
  }
  final income = snapshot.householdMedianIncome;
  if (income.source.datasetId != 'hh_income' ||
      !sourceValid(
        income.source,
        mustBeObserved: income.availability == MetricAvailability.available,
      )) {
    return false;
  }
  final hasIncome = income.availability == MetricAvailability.available;
  if (hasIncome) {
    if (income.medianIncome == null ||
        !income.medianIncome!.isFinite ||
        income.medianIncome! < 0 ||
        income.currencyUnit != 'RM/month' ||
        income.surveyYear != income.source.observedAt.year ||
        income.priceBasisExplanation == null ||
        income.unavailableReason != null) {
      return false;
    }
  } else if (income.medianIncome != null ||
      income.currencyUnit != null ||
      income.surveyYear != null ||
      income.unavailableReason == null) {
    return false;
  }
  final mainAvailable = metrics.every(
    (m) => m.availability == MetricAvailability.available,
  );
  final timing = snapshot.relocationTiming;
  if (timing.sources.any(
        (s) => !sourceValid(
          s,
          mustBeObserved: timing.availability == MetricAvailability.available,
        ),
      ) ||
      timing.reasons.length > 3 ||
      timing.reasons.any(
        (r) => !sourceValid(
          r.source,
          mustBeObserved: timing.availability == MetricAvailability.available,
        ),
      )) {
    return false;
  }
  if (mainAvailable) {
    if (timing.availability != MetricAvailability.available ||
        !scoreValid(timing.score) ||
        timing.scoreUnit != 'points/100' ||
        timing.status == null ||
        timing.unavailableReason != null) {
      return false;
    }
    if (timing.score !=
        (metrics[0].score! * 0.375 +
                metrics[1].score! * 0.3125 +
                metrics[2].score! * 0.3125)
            .round()) {
      return false;
    }
  } else if (timing.availability != MetricAvailability.unavailable ||
      timing.score != null ||
      timing.scoreUnit != null ||
      timing.status != null ||
      timing.unavailableReason == null) {
    return false;
  }
  return (snapshot.completeness == HomeCompleteness.complete) ==
      (mainAvailable && hasIncome);
}
