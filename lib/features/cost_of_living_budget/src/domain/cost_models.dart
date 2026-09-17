// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';

enum CostRefreshPolicy { cacheAllowed, refresh }

final class CostAnalysisRequest {
  final ValidLocationReference location;
  final CostRefreshPolicy refreshPolicy;

  const CostAnalysisRequest({
    required ValidLocationReference location,
    required CostRefreshPolicy refreshPolicy,
  }) : location = location,
       refreshPolicy = refreshPolicy;
}

final class CostComparisonRequest {
  final ValidLocationReference locationA;
  final ValidLocationReference locationB;
  final CostRefreshPolicy refreshPolicy;

  const CostComparisonRequest({
    required ValidLocationReference locationA,
    required ValidLocationReference locationB,
    required CostRefreshPolicy refreshPolicy,
  }) : locationA = locationA,
       locationB = locationB,
       refreshPolicy = refreshPolicy;
}

final class CpiEquivalentRequest {
  final ValidLocationReference location;
  final double inputMonthlySpendRm;
  final CostRefreshPolicy refreshPolicy;

  const CpiEquivalentRequest({
    required ValidLocationReference location,
    required double inputMonthlySpendRm,
    required CostRefreshPolicy refreshPolicy,
  }) : location = location,
       inputMonthlySpendRm = inputMonthlySpendRm,
       refreshPolicy = refreshPolicy;
}

sealed class CostAnalysisOutcome {
  const CostAnalysisOutcome();
}

final class CostAnalysisAvailable extends CostAnalysisOutcome {
  final CostAnalysis analysis;
  const CostAnalysisAvailable(CostAnalysis analysis) : analysis = analysis;
}

final class CostAnalysisPartial extends CostAnalysisOutcome {
  final CostAnalysis analysis;
  final List<CostAvailabilityGap> gaps;
  CostAnalysisPartial(CostAnalysis analysis, List<CostAvailabilityGap> gaps)
    : analysis = analysis,
      gaps = List<CostAvailabilityGap>.unmodifiable(gaps);
}

final class CostAnalysisUnavailable extends CostAnalysisOutcome {
  final CostAnalysisFailure failure;
  const CostAnalysisUnavailable(CostAnalysisFailure failure)
    : failure = failure;
}

sealed class CostComparisonOutcome {
  const CostComparisonOutcome();
}

final class CostComparisonAvailable extends CostComparisonOutcome {
  final CostComparison comparison;
  const CostComparisonAvailable(CostComparison comparison)
    : comparison = comparison;
}

final class CostComparisonPartial extends CostComparisonOutcome {
  final CostComparison comparison;
  final List<CostAvailabilityGap> gaps;
  CostComparisonPartial(
    CostComparison comparison,
    List<CostAvailabilityGap> gaps,
  ) : comparison = comparison,
      gaps = List<CostAvailabilityGap>.unmodifiable(gaps);
}

final class CostComparisonUnavailable extends CostComparisonOutcome {
  final CostAnalysisFailure failure;
  const CostComparisonUnavailable(CostAnalysisFailure failure)
    : failure = failure;
}

sealed class CpiEquivalentOutcome {
  const CpiEquivalentOutcome();
}

final class CpiEquivalentAvailable extends CpiEquivalentOutcome {
  final CpiEquivalentReading reading;
  const CpiEquivalentAvailable(CpiEquivalentReading reading)
    : reading = reading;
}

final class CpiEquivalentUnavailable extends CpiEquivalentOutcome {
  final CpiEquivalentFailure failure;
  const CpiEquivalentUnavailable(CpiEquivalentFailure failure)
    : failure = failure;
}

enum CostAnalysisFailure {
  invalidLocation,
  sameComparisonPoint,
  geographicContextUnavailable,
  sourceUnavailable,
  permissionDenied,
  retryableUnavailable,
  scopeUnavailable,
  incompatibleMetadata,
}

enum CpiEquivalentFailure {
  invalidInput,
  geographicContextUnavailable,
  cpiUnavailable,
  noCommonMonth,
  retryableUnavailable,
  scopeUnavailable,
}

enum CostAvailabilityGap {
  lowCoverage,
  baselineIncomplete,
  notComparable,
  missingHousingInput,
  missingTransportInput,
  missingNetIncomeInput,
  geographicContextIncomplete,
}

// Data structures for Analysis and Comparison

final class CostAnalysis {
  final ValidLocationReference location;
  final AdministrativeArea? district;
  final AdministrativeArea? reportingState;
  final String basketVersion;
  final String modelVersion;
  final DateTime? sourceDate;
  final double? observedSpend12;
  final double? scenarioSpend12;
  final double? costIndex;
  final double? personalBudgetBurden;
  final double? locationBudgetBurden;
  final List<CostItem> items;
  final double? coverage;
  final int availableMonths;
  final String? currentScenarioId;

  CostAnalysis({
    required ValidLocationReference location,
    AdministrativeArea? district,
    AdministrativeArea? reportingState,
    required String basketVersion,
    required String modelVersion,
    DateTime? sourceDate,
    double? observedSpend12,
    double? scenarioSpend12,
    double? costIndex,
    double? personalBudgetBurden,
    double? locationBudgetBurden,
    required List<CostItem> items,
    required double? coverage,
    int availableMonths = 0,
    String? currentScenarioId,
  }) : location = location,
       district = district,
       reportingState = reportingState,
       basketVersion = basketVersion,
       modelVersion = modelVersion,
       sourceDate = sourceDate,
       observedSpend12 = observedSpend12,
       scenarioSpend12 = scenarioSpend12,
       costIndex = costIndex,
       personalBudgetBurden = personalBudgetBurden,
       locationBudgetBurden = locationBudgetBurden,
       items = List<CostItem>.unmodifiable(items),
       coverage = coverage,
       availableMonths = availableMonths,
       currentScenarioId = currentScenarioId;
}

final class CostComparison {
  final CostAnalysis analysisA;
  final CostAnalysis analysisB;
  final bool comparable;

  const CostComparison({
    required CostAnalysis analysisA,
    required CostAnalysis analysisB,
    bool comparable = true,
  }) : analysisA = analysisA,
       analysisB = analysisB,
       comparable = comparable;
}

final class CostItem {
  final String itemCode;
  final String name;
  final String unit;
  final double monthlyQuantity;
  final double? localPrice;
  final double? observedSpend;
  final int premiseCount;
  final int recordCount;
  final List<DateTime> months;

  CostItem({
    required String itemCode,
    required String name,
    required String unit,
    required double monthlyQuantity,
    double? localPrice,
    double? observedSpend,
    int premiseCount = 0,
    int recordCount = 0,
    List<DateTime> months = const <DateTime>[],
  }) : itemCode = itemCode,
       name = name,
       unit = unit,
       monthlyQuantity = monthlyQuantity,
       localPrice = localPrice,
       observedSpend = observedSpend,
       premiseCount = premiseCount,
       recordCount = recordCount,
       months = List<DateTime>.unmodifiable(months);
}

final class CpiEquivalentReading {
  final double equivalentRm;
  final DateTime date;
  final String reportingStateName;
  final String cpiScope; // Headline/Overall

  const CpiEquivalentReading({
    required double equivalentRm,
    required DateTime date,
    required String reportingStateName,
    required String cpiScope,
  }) : equivalentRm = equivalentRm,
       date = date,
       reportingStateName = reportingStateName,
       cpiScope = cpiScope;
}
