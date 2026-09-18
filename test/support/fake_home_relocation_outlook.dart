import 'package:locatemy/features/home_relocation_outlook/home_relocation_outlook.dart';

final class FakeHomeRelocationOutlook implements HomeRelocationOutlook {
  final Future<HomeLoadOutcome> Function(HomeLoadRequest) respond;
  FakeHomeRelocationOutlook(this.respond);
  @override
  Future<HomeLoadOutcome> load(HomeLoadRequest request) => respond(request);
}

HomeOutlookSnapshot homeFixture({
  HomeDataFreshness freshness = HomeDataFreshness.fresh,
  bool partial = false,
}) {
  final sources = [
    MetricSource(
      datasetId: 'cpi_headline_inflation',
      observedAt: DateTime.utc(2026, 7),
    ),
    MetricSource(datasetId: 'lfs_month_sa', observedAt: DateTime.utc(2026, 6)),
    MetricSource(
      datasetId: 'economic_indicators',
      observedAt: DateTime.utc(2026, 6),
    ),
  ];
  MacroMetricCard card(int index, int score, String direction) =>
      MacroMetricCard(
        availability: partial && index == 0
            ? MetricAvailability.unavailable
            : MetricAvailability.available,
        score: partial && index == 0 ? null : score,
        scoreUnit: partial && index == 0 ? null : 'points/100',
        directionExplanation: direction,
        source: sources[index],
        unavailableReason: partial && index == 0
            ? MetricUnavailableReason.insufficientHistory
            : null,
      );
  return HomeOutlookSnapshot(
    freshness: freshness,
    completeness: partial
        ? HomeCompleteness.partial
        : HomeCompleteness.complete,
    relocationTiming: RelocationTimingCard(
      availability: partial
          ? MetricAvailability.unavailable
          : MetricAvailability.available,
      score: partial ? null : 70,
      scoreUnit: partial ? null : 'points/100',
      status: partial ? null : 'timing.favorable',
      reasons: partial
          ? []
          : [RelocationReason(text: 'cost.easing', source: sources[0])],
      sources: [
        ...sources,
        MetricSource(
          datasetId: 'gdp_qtr_real_sa',
          observedAt: DateTime.utc(2026, 4),
        ),
      ],
      unavailableReason: partial
          ? MetricUnavailableReason.insufficientHistory
          : null,
    ),
    costPressure: card(0, 80, 'cost.easing'),
    employmentStability: card(1, 70, 'employment.stable'),
    economicMomentum: card(2, 60, 'economy.expanding'),
    householdMedianIncome: HouseholdIncomeCard(
      availability: MetricAvailability.available,
      medianIncome: 7017,
      currencyUnit: 'RM/month',
      surveyYear: 2024,
      priceBasisExplanation: 'nominal',
      source: MetricSource(
        datasetId: 'hh_income',
        observedAt: DateTime.utc(2024),
      ),
      unavailableReason: null,
    ),
    fetchedAt: DateTime.utc(2026, 9, 17),
  );
}
