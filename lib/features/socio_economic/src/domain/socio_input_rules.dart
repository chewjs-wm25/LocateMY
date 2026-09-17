// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'socio_models.dart';

/// Deterministic DOSM readings and percentile rules; no SDK or private records.
final class SocioInputRules {
  const SocioInputRules();
  SocioReading? reading(
    Object? rows,
    String state,
    String? district,
    String field, {
    int? year,
  }) {
    if (rows is! List) {
      return null;
    }
    SocioReading? selected;
    for (final Object? raw in rows) {
      if (raw is! Map || raw[field] is! num || raw['date'] is! String) {
        continue;
      }
      final DateTime? date = DateTime.tryParse(raw['date'] as String);
      final double value = (raw[field] as num).toDouble();
      if (date == null ||
          !value.isFinite ||
          value < 0 ||
          (field == 'gini' && value > 1)) {
        continue;
      }
      final int rowYear = date.year;
      if (year != null && rowYear != year) {
        continue;
      }
      if (selected == null || rowYear > selected.year) {
        selected = SocioReading(
          (raw[field] as num).toDouble(),
          rowYear,
          state,
          district,
        );
      }
    }
    return selected;
  }

  Set<int> years(Object? rows, String state, String? district, String field) {
    final Set<int> years = <int>{};
    if (rows is! List) {
      return years;
    }
    for (final Object? raw in rows) {
      if (raw is! Map || raw['date'] is! String) {
        continue;
      }
      final DateTime? date = DateTime.tryParse(raw['date'] as String);
      if (date != null &&
          reading(rows, state, district, field, year: date.year) != null) {
        years.add(date.year);
      }
    }
    return years;
  }

  SocioPercentiles percentiles(Object? raw, {int? surveyYear}) {
    if (raw is! List) {
      return const SocioPercentiles();
    }
    final Map<int, Map<String, Map<int, double>>> years =
        <int, Map<String, Map<int, double>>>{};
    for (final Object? value in raw) {
      if (value is! Map ||
          value['income'] is! num ||
          value['percentile'] is! int ||
          value['date'] is! String ||
          value['variable'] is! String) {
        continue;
      }
      final DateTime? date = DateTime.tryParse(value['date'] as String);
      if (date == null) {
        continue;
      }
      final int year = date.year;
      if (surveyYear != null && year != surveyYear) {
        continue;
      }
      final int p = value['percentile'] as int;
      final String variable = value['variable'] as String;
      final double income = (value['income'] as num).toDouble();
      if (p < 1 || p > 100 || !income.isFinite || income < 0) {
        continue;
      }
      final Map<String, Map<int, double>> variables = years.putIfAbsent(
        year,
        () {
          return <String, Map<int, double>>{};
        },
      );
      final Map<int, double> observations = variables.putIfAbsent(variable, () {
        return <int, double>{};
      });
      observations[p] = income;
    }
    final List<int> sorted = years.keys.toList();
    sorted.sort((int a, int b) {
      return b.compareTo(a);
    });
    List<double> medians = <double>[];
    int? distributionYear;
    int? curveYear;
    Map<int, double> curve = <int, double>{};
    SocioStructure? structure;
    for (final int year in sorted) {
      final Map<String, Map<int, double>> variables = years[year]!;
      final Map<int, double> median = variables['median'] ?? <int, double>{};
      if (curve.isEmpty && median.isNotEmpty) {
        curve = Map<int, double>.unmodifiable(median);
        curveYear = year;
      }
      if (medians.isEmpty && median.length == 100) {
        for (int p = 1; p <= 100; p++) {
          medians.add(median[p]!);
        }
        distributionYear = year;
      }
      final Map<int, double> means = variables['mean'] ?? <int, double>{};
      if (structure == null && means.length == 100) {
        double b40 = 0;
        double m40 = 0;
        double t20 = 0;
        for (int p = 1; p <= 100; p++) {
          if (p <= 40) {
            b40 += means[p]!;
          } else if (p <= 80) {
            m40 += means[p]!;
          } else {
            t20 += means[p]!;
          }
        }
        final double total = b40 + m40 + t20;
        if (total.isFinite && total > 0) {
          structure = SocioStructure(
            SocioGroup(b40 / 40, b40 / total),
            SocioGroup(m40 / 40, m40 / total),
            SocioGroup(t20 / 20, t20 / total),
            variables['maximum']?[40],
            variables['maximum']?[80],
            year,
          );
        }
      }
    }
    return SocioPercentiles(
      medians: List<double>.unmodifiable(medians),
      year: distributionYear,
      structure: structure,
      observations: curve,
      curveYear: curveYear,
    );
  }

  IncomePosition? position(SocioPercentiles distribution, double income) {
    final List<double> points = distribution.medians;
    for (int i = 1; i < points.length; i++) {
      if (points[i] < points[i - 1]) {
        return null;
      }
    }
    if (income < points.first) {
      return IncomePosition(
        income,
        null,
        IncomePositionBoundary.belowP1,
        distribution.year!,
      );
    }
    if (income > points.last) {
      return IncomePosition(
        income,
        null,
        IncomePositionBoundary.aboveP100,
        distribution.year!,
      );
    }
    for (int i = 0; i < points.length; i++) {
      if (income == points[i]) {
        return IncomePosition(
          income,
          (i + 1).toDouble(),
          IncomePositionBoundary.withinDistribution,
          distribution.year!,
        );
      }
      if (i > 0 && income < points[i]) {
        final double percentile =
            i + (income - points[i - 1]) / (points[i] - points[i - 1]);
        return IncomePosition(
          income,
          percentile,
          IncomePositionBoundary.withinDistribution,
          distribution.year!,
        );
      }
    }
    return null;
  }
}

final class SocioPercentiles {
  final List<double> medians;
  final int? year;
  final SocioStructure? structure;
  final Map<int, double> observations;
  final int? curveYear;
  const SocioPercentiles({
    List<double> medians = const <double>[],
    int? year,
    SocioStructure? structure,
    Map<int, double> observations = const <int, double>{},
    int? curveYear,
  }) : medians = medians,
       year = year,
       structure = structure,
       observations = observations,
       curveYear = curveYear;
}
