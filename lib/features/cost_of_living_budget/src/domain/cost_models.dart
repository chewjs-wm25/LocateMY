import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';

enum CostRefreshPolicy { cacheAllowed, refresh }

final class CostAnalysisRequest {
  final ValidLocationReference location;
  final CostRefreshPolicy refreshPolicy;

  const CostAnalysisRequest({
    required this.location,
    required this.refreshPolicy,
  });
}

final class CostComparisonRequest {
  final ValidLocationReference locationA;
  final ValidLocationReference locationB;
  final CostRefreshPolicy refreshPolicy;

  const CostComparisonRequest({
    required this.locationA,
    required this.locationB,
    required this.refreshPolicy,
  });
}

final class CpiEquivalentRequest {
  final ValidLocationReference location;
  final double inputMonthlySpendRm;
  final CostRefreshPolicy refreshPolicy;

  const CpiEquivalentRequest({
    required this.location,
    required this.inputMonthlySpendRm,
    required this.refreshPolicy,
  });
}

sealed class CostAnalysisOutcome {
  const CostAnalysisOutcome();
}

final class CostAnalysisAvailable extends CostAnalysisOutcome {
  final CostAnalysis analysis;
  const CostAnalysisAvailable(this.analysis);
}

final class CostAnalysisPartial extends CostAnalysisOutcome {
  final CostAnalysis analysis;
  final List<CostAvailabilityGap> gaps;
  const CostAnalysisPartial(this.analysis, this.gaps);
}

final class CostAnalysisUnavailable extends CostAnalysisOutcome {
  final CostAnalysisFailure failure;
  const CostAnalysisUnavailable(this.failure);
}

sealed class CostComparisonOutcome {
  const CostComparisonOutcome();
}

final class CostComparisonAvailable extends CostComparisonOutcome {
  final CostComparison comparison;
  const CostComparisonAvailable(this.comparison);
}

final class CostComparisonPartial extends CostComparisonOutcome {
  final CostComparison comparison;
  final List<CostAvailabilityGap> gaps;
  const CostComparisonPartial(this.comparison, this.gaps);
}

final class CostComparisonUnavailable extends CostComparisonOutcome {
  final CostAnalysisFailure failure;
  const CostComparisonUnavailable(this.failure);
}

sealed class CpiEquivalentOutcome {
  const CpiEquivalentOutcome();
}

final class CpiEquivalentAvailable extends CpiEquivalentOutcome {
  final CpiEquivalentReading reading;
  const CpiEquivalentAvailable(this.reading);
}

final class CpiEquivalentUnavailable extends CpiEquivalentOutcome {
  final CpiEquivalentFailure failure;
  const CpiEquivalentUnavailable(this.failure);
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
  final double coverage;

  const CostAnalysis({
    required this.location,
    this.district,
    this.reportingState,
    required this.basketVersion,
    required this.modelVersion,
    this.sourceDate,
    this.observedSpend12,
    this.scenarioSpend12,
    this.costIndex,
    this.personalBudgetBurden,
    this.locationBudgetBurden,
    required this.items,
    required this.coverage,
  });
}

final class CostComparison {
  final CostAnalysis analysisA;
  final CostAnalysis analysisB;

  const CostComparison({required this.analysisA, required this.analysisB});
}

final class CostItem {
  final String itemCode;
  final String name;
  final String unit;
  final double monthlyQuantity;
  final double? localPrice;
  final double? observedSpend;

  const CostItem({
    required this.itemCode,
    required this.name,
    required this.unit,
    required this.monthlyQuantity,
    this.localPrice,
    this.observedSpend,
  });
}

final class CpiEquivalentReading {
  final double equivalentRm;
  final DateTime date;
  final String reportingStateName;
  final String cpiScope; // Headline/Overall

  const CpiEquivalentReading({
    required this.equivalentRm,
    required this.date,
    required this.reportingStateName,
    required this.cpiScope,
  });
}
