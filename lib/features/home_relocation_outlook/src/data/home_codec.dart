import '../domain/home_models.dart';

Map<String, dynamic> encodeHomeOutlookSnapshot(HomeOutlookSnapshot value) => {
  'freshness': value.freshness.name,
  'completeness': value.completeness.name,
  'relocationTiming': encodeRelocationTimingCard(value.relocationTiming),
  'costPressure': encodeMacroMetricCard(value.costPressure),
  'employmentStability': encodeMacroMetricCard(value.employmentStability),
  'economicMomentum': encodeMacroMetricCard(value.economicMomentum),
  'householdMedianIncome': encodeHouseholdIncomeCard(
    value.householdMedianIncome,
  ),
  'fetchedAt': value.fetchedAt.toIso8601String(),
};
HomeOutlookSnapshot decodeHomeOutlookSnapshot(Map<String, dynamic> data) =>
    HomeOutlookSnapshot(
      freshness: HomeDataFreshness.values.byName(data['freshness'] as String),
      completeness: HomeCompleteness.values.byName(
        data['completeness'] as String,
      ),
      relocationTiming: decodeRelocationTimingCard(
        Map<String, dynamic>.from(data['relocationTiming'] as Map),
      ),
      costPressure: decodeMacroMetricCard(
        Map<String, dynamic>.from(data['costPressure'] as Map),
      ),
      employmentStability: decodeMacroMetricCard(
        Map<String, dynamic>.from(data['employmentStability'] as Map),
      ),
      economicMomentum: decodeMacroMetricCard(
        Map<String, dynamic>.from(data['economicMomentum'] as Map),
      ),
      householdMedianIncome: decodeHouseholdIncomeCard(
        Map<String, dynamic>.from(data['householdMedianIncome'] as Map),
      ),
      fetchedAt: DateTime.parse(data['fetchedAt'] as String),
    );

Map<String, dynamic> encodeRelocationTimingCard(RelocationTimingCard value) => {
  'availability': value.availability.name,
  'score': value.score,
  'scoreUnit': value.scoreUnit,
  'status': value.status,
  'reasons': value.reasons.map(encodeRelocationReason).toList(),
  'sources': value.sources.map(encodeMetricSource).toList(),
  'unavailableReason': value.unavailableReason?.name,
};
RelocationTimingCard decodeRelocationTimingCard(Map<String, dynamic> data) =>
    RelocationTimingCard(
      availability: MetricAvailability.values.byName(
        data['availability'] as String,
      ),
      score: data['score'] as int?,
      scoreUnit: data['scoreUnit'] as String?,
      status: data['status'] as String?,
      reasons: (data['reasons'] as List)
          .map(
            (row) =>
                decodeRelocationReason(Map<String, dynamic>.from(row as Map)),
          )
          .toList(),
      sources: (data['sources'] as List)
          .map(
            (row) => decodeMetricSource(Map<String, dynamic>.from(row as Map)),
          )
          .toList(),
      unavailableReason: data['unavailableReason'] == null
          ? null
          : MetricUnavailableReason.values.byName(
              data['unavailableReason'] as String,
            ),
    );

Map<String, dynamic> encodeRelocationReason(RelocationReason value) => {
  'text': value.text,
  'source': encodeMetricSource(value.source),
};
RelocationReason decodeRelocationReason(Map<String, dynamic> data) =>
    RelocationReason(
      text: data['text'] as String,
      source: decodeMetricSource(
        Map<String, dynamic>.from(data['source'] as Map),
      ),
    );

Map<String, dynamic> encodeMacroMetricCard(MacroMetricCard value) => {
  'availability': value.availability.name,
  'score': value.score,
  'scoreUnit': value.scoreUnit,
  'directionExplanation': value.directionExplanation,
  'source': encodeMetricSource(value.source),
  'unavailableReason': value.unavailableReason?.name,
};
MacroMetricCard decodeMacroMetricCard(Map<String, dynamic> data) =>
    MacroMetricCard(
      availability: MetricAvailability.values.byName(
        data['availability'] as String,
      ),
      score: data['score'] as int?,
      scoreUnit: data['scoreUnit'] as String?,
      directionExplanation: data['directionExplanation'] as String?,
      source: decodeMetricSource(
        Map<String, dynamic>.from(data['source'] as Map),
      ),
      unavailableReason: data['unavailableReason'] == null
          ? null
          : MetricUnavailableReason.values.byName(
              data['unavailableReason'] as String,
            ),
    );

Map<String, dynamic> encodeHouseholdIncomeCard(HouseholdIncomeCard value) => {
  'availability': value.availability.name,
  'medianIncome': value.medianIncome,
  'currencyUnit': value.currencyUnit,
  'surveyYear': value.surveyYear,
  'priceBasisExplanation': value.priceBasisExplanation,
  'source': encodeMetricSource(value.source),
  'unavailableReason': value.unavailableReason?.name,
};
HouseholdIncomeCard decodeHouseholdIncomeCard(Map<String, dynamic> data) =>
    HouseholdIncomeCard(
      availability: MetricAvailability.values.byName(
        data['availability'] as String,
      ),
      medianIncome: data['medianIncome'] as num?,
      currencyUnit: data['currencyUnit'] as String?,
      surveyYear: data['surveyYear'] as int?,
      priceBasisExplanation: data['priceBasisExplanation'] as String?,
      source: decodeMetricSource(
        Map<String, dynamic>.from(data['source'] as Map),
      ),
      unavailableReason: data['unavailableReason'] == null
          ? null
          : MetricUnavailableReason.values.byName(
              data['unavailableReason'] as String,
            ),
    );

Map<String, dynamic> encodeMetricSource(MetricSource value) => {
  'datasetId': value.datasetId,
  'observedAt': value.observedAt.toIso8601String(),
};
MetricSource decodeMetricSource(Map<String, dynamic> data) => MetricSource(
  datasetId: data['datasetId'] as String,
  observedAt: DateTime.parse(data['observedAt'] as String),
);
