import 'home_models.dart';

const homeDatasetIds = [
  'cpi_headline_inflation',
  'lfs_month_sa',
  'economic_indicators',
  'gdp_qtr_real_sa',
  'hh_income',
];
typedef Series = Map<DateTime, double>;

DateTime observationDate(String date) {
  return DateTime.parse('${date}T00:00:00Z');
}

DateTime monthBefore(DateTime date, int months) {
  return DateTime.utc(date.year, date.month - months);
}

double? percentile(
  Series history,
  DateTime at,
  int minimum, {
  bool inverted = false,
}) {
  final double? value = history[at];
  if (value == null) {
    return null;
  }
  final DateTime start = DateTime.utc(at.year - 5, at.month, at.day);
  final List<double> values = <double>[];
  for (final MapEntry<DateTime, double> entry in history.entries) {
    if (!entry.key.isBefore(start) && !entry.key.isAfter(at)) {
      values.add(entry.value);
    }
  }
  if (values.length < minimum) {
    values.clear();
    for (final MapEntry<DateTime, double> entry in history.entries) {
      if (!entry.key.isAfter(at)) {
        values.add(entry.value);
      }
    }
  }
  if (values.length < minimum) {
    return null;
  }
  int rankCount = 0;
  for (final double candidate in values) {
    if (candidate <= value + 1e-9) {
      rankCount++;
    }
  }
  final double rank = rankCount / values.length * 100;
  if (inverted) {
    return 100 - rank;
  }
  return rank;
}

double? weighted(List<(double?, double)> inputs) {
  final List<(double?, double)> usable = <(double?, double)>[];
  for (final (double?, double) input in inputs) {
    if (input.$1 != null) {
      usable.add(input);
    }
  }
  double weight = 0;
  for (final (double?, double) input in usable) {
    weight += input.$2;
  }
  if (weight + 1e-9 < 0.6) {
    return null;
  }
  double weightedTotal = 0;
  for (final (double?, double) input in usable) {
    weightedTotal += input.$1! * input.$2;
  }
  return weightedTotal / weight;
}

Series changes(Series series, int months, {bool growth = false}) {
  final Series results = <DateTime, double>{};
  for (final MapEntry<DateTime, double> entry in series.entries) {
    final double? before = series[monthBefore(entry.key, months)];
    if (before == null || (growth && before <= 0)) {
      continue;
    }
    final double result;
    if (growth) {
      result = (entry.value / before - 1) * 100;
    } else {
      result = entry.value - before;
    }
    results[entry.key] = result;
  }
  return results;
}

MacroMetricCard unavailableMacro(
  String id,
  MetricUnavailableReason reason, {
  DateTime? observedAt,
}) {
  final DateTime sourceDate =
      observedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return MacroMetricCard(
    availability: MetricAvailability.unavailable,
    score: null,
    scoreUnit: null,
    directionExplanation: null,
    source: MetricSource(datasetId: id, observedAt: sourceDate),
    unavailableReason: reason,
  );
}

MacroMetricCard macro(
  String id,
  List<Map> rows,
  double? value,
  String? direction,
) {
  final DateTime? at;
  if (rows.isEmpty) {
    at = null;
  } else {
    at = observationDate(rows.last['date'] as String);
  }
  if (value == null) {
    return unavailableMacro(
      id,
      rows.isEmpty
          ? MetricUnavailableReason.sourceMissing
          : MetricUnavailableReason.insufficientHistory,
      observedAt: at,
    );
  }
  return MacroMetricCard(
    availability: MetricAvailability.available,
    score: value.clamp(0, 100).round(),
    scoreUnit: 'points/100',
    directionExplanation: direction,
    source: MetricSource(datasetId: id, observedAt: at!),
    unavailableReason: null,
  );
}

Series field(List<Map> rows, String key) {
  final Series values = <DateTime, double>{};
  for (final Map row in rows) {
    final Object? rawValue = row[key];
    if (rawValue is num && rawValue.isFinite) {
      final DateTime date = observationDate(row['date'] as String);
      values[date] = rawValue.toDouble();
    }
  }
  return values;
}

MacroMetricCard costCard(List<Map> rows) {
  final months = <DateTime, List<(double?, double)>>{};
  const weights = {'overall': 0.4, '01': 0.2, '04': 0.25, '07': 0.15};
  for (final row in rows) {
    final double? weight = weights[row['division']];
    if (weight == null) {
      continue;
    }
    final DateTime date = observationDate(row['date'] as String);
    final List<(double?, double)> inputs = months.putIfAbsent(
      date,
      _emptyWeightedInputs,
    );
    inputs.add(((row['inflation_yoy'] as num?)?.toDouble(), weight));
  }
  final Series inflation = <DateTime, double>{
    for (final e in months.entries)
      if (weighted(e.value) case final double value) e.key: value,
  };
  final Series delta = changes(inflation, 3);
  final DateTime? at = rows.isEmpty
      ? null
      : observationDate(rows.last['date'] as String);
  final double? value;
  if (at == null) {
    value = null;
  } else {
    value = weighted(<(double?, double)>[
      (percentile(inflation, at, 24, inverted: true), 0.8),
      (percentile(delta, at, 24, inverted: true), 0.2),
    ]);
  }
  final double? difference = at == null ? null : delta[at];
  return macro(
    'cpi_headline_inflation',
    rows,
    value,
    difference == null
        ? 'cost.lowerIsBetter'
        : difference <= -0.3
        ? 'cost.easing'
        : difference >= 0.3
        ? 'cost.worsening'
        : 'cost.stable',
  );
}

List<(double?, double)> _emptyWeightedInputs() {
  return <(double?, double)>[];
}

MacroMetricCard employmentCard(List<Map> rows) {
  if (rows.isEmpty) {
    return unavailableMacro(
      'lfs_month_sa',
      MetricUnavailableReason.sourceMissing,
    );
  }
  final unemployment = field(rows, 'u_rate'),
      growth = changes(field(rows, 'lf_employed'), 12, growth: true),
      participation = changes(field(rows, 'p_rate'), 3);
  final at = observationDate(rows.last['date'] as String);
  double? scoreAt(DateTime date) {
    return weighted(<(double?, double)>[
      (percentile(unemployment, date, 24, inverted: true), 0.5),
      (percentile(growth, date, 24), 0.35),
      (percentile(participation, date, 24), 0.15),
    ]);
  }

  final value = scoreAt(at), previous = scoreAt(monthBefore(at, 3));
  final difference = value == null || previous == null
      ? null
      : value - previous;
  return macro(
    'lfs_month_sa',
    rows,
    value,
    difference == null
        ? 'employment.comparisonUnavailable'
        : difference >= 5
        ? 'employment.improving'
        : difference <= -5
        ? 'employment.weakening'
        : 'employment.stable',
  );
}

MacroMetricCard economyCard(List<Map> rows, List<Map> gdpRows) {
  if (rows.isEmpty) {
    return unavailableMacro(
      'economic_indicators',
      MetricUnavailableReason.sourceMissing,
    );
  }
  final at = observationDate(rows.last['date'] as String);
  final diffusion = field(rows, 'leading_diffusion');
  final growth = changes(field(rows, 'leading'), 6, growth: true);
  final List<Map> quarterlyGrowthRows = <Map>[];
  for (final Map row in gdpRows) {
    if (row['series'] == 'growth_qoq') {
      quarterlyGrowthRows.add(row);
    }
  }
  final Series gdp = field(quarterlyGrowthRows, 'value');
  double? scoreAt(DateTime date, {bool current = false}) {
    final List<DateTime> quarters = <DateTime>[];
    for (final DateTime quarter in gdp.keys) {
      if (current || !quarter.isAfter(date)) {
        quarters.add(quarter);
      }
    }
    quarters.sort();
    final spread = diffusion[date];
    return weighted([
      (spread == null || spread < 0 || spread > 100 ? null : spread, 0.4),
      (percentile(growth, date, 24), 0.3),
      (quarters.isEmpty ? null : percentile(gdp, quarters.last, 8), 0.3),
    ]);
  }

  final value = scoreAt(at, current: true),
      previous = scoreAt(monthBefore(at, 3));
  final difference = value == null || previous == null
      ? null
      : value - previous;
  final direction = value == null
      ? null
      : value < 40 || (difference != null && difference <= -10)
      ? 'economy.weakening'
      : value >= 60 && difference != null && difference >= -5
      ? 'economy.expanding'
      : 'economy.stable';
  return macro('economic_indicators', rows, value, direction);
}

bool validRecord(String id, Map row, DateTime fetchedAt) {
  final date = row['date'];
  if (date is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
    return false;
  }
  final parsed = DateTime.tryParse('${date}T00:00:00Z');
  if (parsed == null ||
      parsed.toIso8601String().substring(0, 10) != date ||
      parsed.isAfter(fetchedAt) ||
      parsed.day != 1) {
    return false;
  }
  if (id == 'gdp_qtr_real_sa' && ![1, 4, 7, 10].contains(parsed.month)) {
    return false;
  }
  if (id == 'hh_income' && parsed.month != 1) return false;
  for (final e in row.entries) {
    if (['date', 'division', 'series'].contains(e.key)) continue;
    if (e.value != null && (e.value is! num || !(e.value as num).isFinite)) {
      return false;
    }
  }
  if (id == 'cpi_headline_inflation' && row['division'] is! String) {
    return false;
  }
  if (id == 'gdp_qtr_real_sa' && row['series'] is! String) return false;
  for (final key in ['u_rate', 'p_rate', 'leading_diffusion']) {
    final value = row[key];
    if (value is num && (value < 0 || value > 100)) return false;
  }
  for (final key in ['lf_employed', 'leading']) {
    final value = row[key];
    if (value is num && value <= 0) return false;
  }
  final median = row['income_median'];
  if (median is num && median < 0) return false;
  return true;
}

HomeOutlookSnapshot? scoreHome(
  Map<String, dynamic> payload,
  DateTime fetchedAt,
) {
  final data = payload['datasets'] as Map;
  const fields = {
    'cpi_headline_inflation': [
      'date',
      'division',
      'inflation_yoy',
      'inflation_mom',
    ],
    'lfs_month_sa': ['date', 'lf_employed', 'u_rate', 'p_rate'],
    'economic_indicators': ['date', 'leading', 'leading_diffusion'],
    'gdp_qtr_real_sa': ['date', 'series', 'value'],
    'hh_income': ['date', 'income_median'],
  };
  final failures = <String, MetricUnavailableReason>{};
  final rows = <String, List<Map>>{};
  for (final id in homeDatasetIds) {
    final input = data[id];
    if (input is! List ||
        input.any(
          (row) =>
              row is! Map || fields[id]!.any((key) => !row.containsKey(key)),
        )) {
      failures[id] = MetricUnavailableReason.sourceSchemaChanged;
      rows[id] = [];
      continue;
    }
    final records = input.cast<Map>().toList();
    final keys = <String>{};
    if (records.any(
      (r) =>
          !validRecord(id, r, fetchedAt) ||
          !keys.add('${r['date']}:${r['division'] ?? r['series'] ?? ''}'),
    )) {
      failures[id] = MetricUnavailableReason.sourceDataUnverifiable;
      rows[id] = [];
      continue;
    }
    rows[id] = records
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }
  if (rows.values.every((r) => r.isEmpty) && failures.isEmpty) return null;
  final cards = [
    costCard(rows[homeDatasetIds[0]]!),
    employmentCard(rows[homeDatasetIds[1]]!),
    economyCard(rows[homeDatasetIds[2]]!, rows[homeDatasetIds[3]]!),
  ];
  for (var i = 0; i < 3; i++) {
    final failure =
        failures[homeDatasetIds[i]] ??
        (i == 2 ? failures['gdp_qtr_real_sa'] : null);
    if (failure != null) {
      cards[i] = unavailableMacro(homeDatasetIds[i], failure);
    }
  }
  final income = rows['hh_income']!;
  final incomeDate = income.isEmpty
      ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
      : observationDate(income.last['date'] as String);
  final median = income.isEmpty ? null : income.last['income_median'] as num?;
  final complete = cards.every((c) => c.score != null);
  final total = complete
      ? (cards[0].score! * 0.375 +
                cards[1].score! * 0.3125 +
                cards[2].score! * 0.3125)
            .round()
      : null;
  const impacts = [0.375, 0.3125, 0.3125];
  final indices = [0, 1, 2]
    ..sort(
      (a, b) => ((cards[b].score ?? 50) - 50).abs().toDouble().compareTo(
        ((cards[a].score ?? 50) - 50).abs().toDouble(),
      ),
    );
  indices.sort(
    (a, b) => (((cards[b].score ?? 50) - 50).abs() * impacts[b]).compareTo(
      ((cards[a].score ?? 50) - 50).abs() * impacts[a],
    ),
  );
  final sources = cards.map((c) => c.source).toList();
  final gdp = rows['gdp_qtr_real_sa']!
      .where((r) => r['series'] == 'growth_qoq')
      .toList();
  if (gdp.isNotEmpty) {
    sources.add(
      MetricSource(
        datasetId: 'gdp_qtr_real_sa',
        observedAt: observationDate(gdp.last['date'] as String),
      ),
    );
  }
  return HomeOutlookSnapshot(
    freshness: HomeDataFreshness.fresh,
    completeness: complete && median != null
        ? HomeCompleteness.complete
        : HomeCompleteness.partial,
    relocationTiming: RelocationTimingCard(
      availability: complete
          ? MetricAvailability.available
          : MetricAvailability.unavailable,
      score: total,
      scoreUnit: complete ? 'points/100' : null,
      status: total == null
          ? null
          : total >= 70
          ? 'timing.favorable'
          : total >= 45
          ? 'timing.wait'
          : 'timing.defer',
      reasons: complete
          ? [
              for (final index in indices)
                RelocationReason(
                  text: cards[index].directionExplanation!,
                  source: cards[index].source,
                ),
            ]
          : [],
      sources: sources,
      unavailableReason: complete
          ? null
          : cards.firstWhere((c) => c.score == null).unavailableReason,
    ),
    costPressure: cards[0],
    employmentStability: cards[1],
    economicMomentum: cards[2],
    householdMedianIncome: HouseholdIncomeCard(
      availability: median == null
          ? MetricAvailability.unavailable
          : MetricAvailability.available,
      medianIncome: median,
      currencyUnit: median == null ? null : 'RM/month',
      surveyYear: median == null ? null : incomeDate.year,
      priceBasisExplanation: median == null ? null : 'nominal',
      source: MetricSource(datasetId: 'hh_income', observedAt: incomeDate),
      unavailableReason: median == null
          ? failures['hh_income'] ?? MetricUnavailableReason.sourceMissing
          : null,
    ),
    fetchedAt: fetchedAt,
  );
}
