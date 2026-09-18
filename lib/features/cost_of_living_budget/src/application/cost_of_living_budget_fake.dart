import '../../cost_of_living_budget.dart';

import 'package:locatemy/features/map_location/map_location.dart';

class CostOfLivingBudgetFake implements CostOfLivingBudget {
  @override
  Future<CostAnalysisOutcome> analyse(CostAnalysisRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final ValidLocationReference location = request.location;

    if (location.locationId == 'unavailable') {
      return const CostAnalysisUnavailable(
        CostAnalysisFailure.sourceUnavailable,
      );
    }

    final CostAnalysis analysis = CostAnalysis(
      location: location,
      basketVersion: 'cost-basket-v1',
      modelVersion: 'v1.0-fake',
      sourceDate: DateTime.now().subtract(const Duration(days: 5)),
      observedSpend12: 1250.75,
      scenarioSpend12: 1850.75, 
      costIndex: 105.2,
      personalBudgetBurden: 35.5,
      locationBudgetBurden: 42.1,
      coverage: 0.95,
      items: [
        CostItem(
          itemCode: '1',
          name: 'AYAM BERSIH - STANDARD',
          unit: '1kg',
          monthlyQuantity: 2,
          localPrice: 9.40,
          observedSpend: 18.80,
        ),
        CostItem(
          itemCode: '118',
          name: 'TELUR AYAM GRED A',
          unit: '10 biji',
          monthlyQuantity: 3,
          localPrice: 4.50,
          observedSpend: 13.50,
        ),
      ],
    );

    if (location.locationId == 'partial') {
      return CostAnalysisPartial(analysis, [CostAvailabilityGap.lowCoverage]);
    }

    return CostAnalysisAvailable(analysis);
  }

  @override
  Future<CostComparisonOutcome> compare(CostComparisonRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final CostAnalysisOutcome outcomeA = await analyse(
      CostAnalysisRequest(
        location: request.locationA,
        refreshPolicy: request.refreshPolicy,
      ),
    );
    final CostAnalysisOutcome outcomeB = await analyse(
      CostAnalysisRequest(
        location: request.locationB,
        refreshPolicy: request.refreshPolicy,
      ),
    );

    if (outcomeA is CostAnalysisAvailable &&
        outcomeB is CostAnalysisAvailable) {
      return CostComparisonAvailable(
        CostComparison(
          analysisA: outcomeA.analysis,
          analysisB: outcomeB.analysis,
        ),
      );
    }

    return const CostComparisonUnavailable(
      CostAnalysisFailure.retryableUnavailable,
    );
  }
}
