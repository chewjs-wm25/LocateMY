// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import '../../../map_location/map_location.dart';

final class SocioReading {
  final double value;
  final int year;
  final String state;
  final String? district;
  const SocioReading(double value, int year, String state, String? district)
    : value = value,
      year = year,
      state = state,
      district = district;
}

final class SocioAnalysis {
  final ValidLocationReference location;
  // Government source facts stay internal; no user or account data is cached.
  static const String modelVersion = 'socio-v1';
  static const Map<String, String> sourceUrls = <String, String>{
    'hh_income_district':
        'https://open.dosm.gov.my/data-catalogue/hh_income_district',
    'hh_income_state':
        'https://open.dosm.gov.my/data-catalogue/hh_income_state',
    'hh_inequality_district':
        'https://open.dosm.gov.my/data-catalogue/hh_inequality_district',
    'hh_inequality_state':
        'https://open.dosm.gov.my/data-catalogue/hh_inequality_state',
    'hies_state_percentile':
        'https://open.dosm.gov.my/data-catalogue/hies_state_percentile',
  };
  final String? state;
  final String? district;
  final String? boundaryVersion;
  final SocioReading? income;
  final SocioReading? gini;
  final double? giniChange;
  final SocioFailure? failure;
  final IncomePosition? position;

  /// Latest complete median series used for income-position estimation.
  final List<double> distribution;
  final int? distributionYear;
  final int? completeDistributionYear;

  /// Survey-aligned observed curve, including a partial year; never padded or smoothed.
  final Map<int, double> distributionPoints;
  final SocioStructure? structure;
  const SocioAnalysis({
    required ValidLocationReference location,
    String? state,
    String? district,
    String? boundaryVersion,
    SocioReading? income,
    SocioReading? gini,
    double? giniChange,
    SocioFailure? failure,
    List<double> distribution = const <double>[],
    int? distributionYear,
    int? completeDistributionYear,
    SocioStructure? structure,
    IncomePosition? position,
    Map<int, double> distributionPoints = const <int, double>{},
  }) : location = location,
       state = state,
       district = district,
       boundaryVersion = boundaryVersion,
       income = income,
       gini = gini,
       giniChange = giniChange,
       failure = failure,
       distribution = distribution,
       distributionYear = distributionYear,
       completeDistributionYear = completeDistributionYear,
       structure = structure,
       position = position,
       distributionPoints = distributionPoints;
  SocioAnalysis withoutPosition() {
    return SocioAnalysis(
      location: location,
      state: state,
      district: district,
      boundaryVersion: boundaryVersion,
      income: income,
      gini: gini,
      giniChange: giniChange,
      failure: failure,
      distribution: distribution,
      distributionYear: distributionYear,
      completeDistributionYear: completeDistributionYear,
      distributionPoints: distributionPoints,
      structure: structure,
    );
  }
}

enum SocioFailure { geographyUnavailable, sourceUnavailable }

abstract interface class SocioEconomic {
  Future<SocioComparison> compare(
    ValidLocationReference a,
    ValidLocationReference b, {
    bool refresh = false,
  });
  Stream<void> get changes;
  Future<SocioAnalysis> analyse(
    ValidLocationReference location, {
    bool refresh = false,
  });
}

final class SocioGroup {
  final double mean;
  final double share;
  const SocioGroup(double mean, double share) : mean = mean, share = share;
}

final class SocioStructure {
  final SocioGroup b40;
  final SocioGroup m40;
  final SocioGroup t20;
  final double? b40Threshold;
  final double? m40Threshold;
  final int year;
  const SocioStructure(
    SocioGroup b40,
    SocioGroup m40,
    SocioGroup t20,
    double? b40Threshold,
    double? m40Threshold,
    int year,
  ) : b40 = b40,
      m40 = m40,
      t20 = t20,
      b40Threshold = b40Threshold,
      m40Threshold = m40Threshold,
      year = year;
}

enum IncomePositionBoundary { belowP1, withinDistribution, aboveP100 }

final class IncomePosition {
  final double householdIncome;
  final double? percentile;
  final IncomePositionBoundary boundary;
  final int year;
  const IncomePosition(
    double householdIncome,
    double? percentile,
    IncomePositionBoundary boundary,
    int year,
  ) : householdIncome = householdIncome,
      percentile = percentile,
      boundary = boundary,
      year = year;
}

final class SocioComparison {
  final SocioAnalysis a;
  final SocioAnalysis b;
  const SocioComparison(SocioAnalysis a, SocioAnalysis b) : a = a, b = b;
  double? get incomeDifference {
    return _difference(a.income, b.income);
  }

  double? get giniDifference {
    return _difference(a.gini, b.gini);
  }

  double? _difference(SocioReading? first, SocioReading? second) {
    if (first == null ||
        second == null ||
        first.year != second.year ||
        (first.district == null) != (second.district == null) ||
        a.boundaryVersion == null ||
        a.boundaryVersion != b.boundaryVersion) {
      return null;
    }
    return second.value - first.value;
  }
}
