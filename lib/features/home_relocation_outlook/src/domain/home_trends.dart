import 'home_models.dart';
import 'home_scoring.dart';

enum HomeComparisonBasis { currentObservationsApproximation }

final class HomeTrendPoint {
  final DateTime observedAt;
  final int score;

  const HomeTrendPoint(this.observedAt, this.score);
}

final class HomeTrendHistory {
  final HomeComparisonBasis basis;
  final Map<String, List<HomeTrendPoint>> metrics;

  const HomeTrendHistory(this.metrics)
    : basis = HomeComparisonBasis.currentObservationsApproximation;
}

HomeTrendHistory reconstructHomeTrends(
  Map<String, dynamic> payload,
  HomeOutlookSnapshot current,
  DateTime fetchedAt,
) {
  final Map data = payload['datasets'] as Map;
  final Map<String, List<HomeTrendPoint>> metrics =
      <String, List<HomeTrendPoint>>{};
  final List<MacroMetricCard> cards = <MacroMetricCard>[
    current.costPressure,
    current.employmentStability,
    current.economicMomentum,
  ];
  for (final MacroMetricCard card in cards) {
    final List<HomeTrendPoint> points = <HomeTrendPoint>[];
    DateTime effectiveDate(
      HomeOutlookSnapshot snapshot,
      MacroMetricCard metric,
    ) {
      DateTime date = metric.source.observedAt;
      if (metric.source.datasetId == 'economic_indicators') {
        for (final source in snapshot.relocationTiming.sources) {
          if (source.datasetId == 'gdp_qtr_real_sa' &&
              source.observedAt.isAfter(date)) {
            date = source.observedAt;
          }
        }
      }
      return date;
    }

    final DateTime endpoint = effectiveDate(current, card);
    if (card.availability == MetricAvailability.available) {
      for (int i = 5; i >= 0; i--) {
        final DateTime at = monthBefore(endpoint, i);
        final String cutoff = at.toIso8601String().substring(0, 10);
        final Map<String, dynamic> datasets = <String, dynamic>{};
        for (final String id in homeDatasetIds) {
          final Object? input = data[id];
          final List<dynamic> records;
          if (input is List) {
            records = input;
          } else {
            records = <dynamic>[];
          }
          final List<dynamic> filteredRecords = <dynamic>[];
          for (final dynamic row in records) {
            if (row is Map &&
                row['date'] is String &&
                (row['date'] as String).compareTo(cutoff) <= 0) {
              filteredRecords.add(row);
            }
          }
          datasets[id] = filteredRecords;
        }
        final Map<String, dynamic> historical = <String, dynamic>{
          'version': 1,
          'datasets': datasets,
        };
        final HomeOutlookSnapshot? snapshot = scoreHome(historical, fetchedAt);
        if (snapshot == null) {
          continue;
        }
        final MacroMetricCard metric = _cardForDataset(
          card.source.datasetId,
          snapshot,
        );
        
        if (metric.score != null && effectiveDate(snapshot, metric) == at) {
          points.add(HomeTrendPoint(at, metric.score!));
        }
      }
    }
    metrics[card.source.datasetId] = List.unmodifiable(points);
  }
  return HomeTrendHistory(Map.unmodifiable(metrics));
}

MacroMetricCard _cardForDataset(
  String datasetId,
  HomeOutlookSnapshot snapshot,
) {
  if (datasetId == 'cpi_headline_inflation') {
    return snapshot.costPressure;
  }
  if (datasetId == 'lfs_month_sa') {
    return snapshot.employmentStability;
  }
  return snapshot.economicMomentum;
}
