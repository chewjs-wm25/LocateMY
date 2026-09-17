import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';
import '../domain/cost_models.dart';

abstract interface class CostInputsReader {
  Future<CostInputsOutcome> read(CostInputsRequest request);
}

final class CostInputsRequest {
  final ValidLocationReference location;
  final AdministrativeArea district;
  final AdministrativeArea reportingState;
  final BoundaryProvenance districtProvenance;
  final BoundaryProvenance reportingStateProvenance;
  final String basketVersion;
  final CostRefreshPolicy refreshPolicy;

  const CostInputsRequest({
    required this.location,
    required this.district,
    required this.reportingState,
    required this.districtProvenance,
    required this.reportingStateProvenance,
    required this.basketVersion,
    required this.refreshPolicy,
  });
}

sealed class CostInputsOutcome {
  const CostInputsOutcome();
}

final class CostInputsAvailable extends CostInputsOutcome {
  final CostInputs inputs;
  const CostInputsAvailable(this.inputs);
}

final class CostInputsPartial extends CostInputsOutcome {
  final CostInputs inputs;
  final List<CostInputGap> gaps;
  const CostInputsPartial(this.inputs, this.gaps);
}

final class CostInputsUnavailable extends CostInputsOutcome {
  final CostInputFailure failure;
  const CostInputsUnavailable(this.failure);
}

enum CostInputFailure {
  invalidGeographicContext,
  sourceUnavailable,
  permissionDenied,
  retryableUnavailable,
  incompatibleVersion,
}

enum CostInputGap {
  missingPriceData,
  missingIncomeData,
  missingCpiData,
}

// Data structures for inputs from the View/RPC

final class CostInputs {
  final List<CostInputItem> items;
  final double? districtMedianIncome;
  final Map<String, double> cpiData; // e.g. "Headline": 123.4
  final DateTime sourceDate;
  final String basketVersion;

  const CostInputs({
    required this.items,
    this.districtMedianIncome,
    required this.cpiData,
    required this.sourceDate,
    required this.basketVersion,
  });
}

final class CostInputItem {
  final String itemCode;
  final double? medianPrice;
  final int premiseCount;
  final int recordCount;

  const CostInputItem({
    required this.itemCode,
    this.medianPrice,
    required this.premiseCount,
    required this.recordCount,
  });
}
