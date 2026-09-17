import '../../cost_of_living_budget.dart';

class CostOfLivingBudgetFake implements CostOfLivingBudget {
  @override
  Future<CostAnalysisOutcome> analyse(CostAnalysisRequest request) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return a fixture based on location ID
    final location = request.location;

    // Example: return unavailable for specific IDs
    if (location.locationId == 'unavailable') {
      return const CostAnalysisUnavailable(
        CostAnalysisFailure.sourceUnavailable,
      );
    }

    final analysis = CostAnalysis(
      location: location,
      basketVersion: 'cost-basket-v1',
      modelVersion: 'v1.0-fake',
      sourceDate: DateTime.now().subtract(const Duration(days: 5)),
      observedSpend12: 1250.75,
      scenarioSpend12: 1850.75, // Assuming some housing/transport
      costIndex: 105.2,
      personalBudgetBurden: 35.5,
      locationBudgetBurden: 42.1,
      coverage: 0.95,
      items: [
        const CostItem(
          itemCode: '1',
          name: 'AYAM BERSIH - STANDARD',
          unit: '1kg',
          monthlyQuantity: 2,
          localPrice: 9.40,
          observedSpend: 18.80,
        ),
        const CostItem(
          itemCode: '118',
          name: 'TELUR AYAM GRED A',
          unit: '10 biji',
          monthlyQuantity: 3,
          localPrice: 4.50,
          observedSpend: 13.50,
        ),
        // Add more items if needed for the fake
      ],
    );

    if (location.locationId == 'partial') {
      return CostAnalysisPartial(analysis, [CostAvailabilityGap.lowCoverage]);
    }

    return CostAnalysisAvailable(analysis);
  }

  @override
  Future<CostComparisonOutcome> compare(CostComparisonRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final outcomeA = await analyse(
      CostAnalysisRequest(
        location: request.locationA,
        refreshPolicy: request.refreshPolicy,
      ),
    );
    final outcomeB = await analyse(
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

  @override
  Future<CpiEquivalentOutcome> calculateCpiEquivalent(
    CpiEquivalentRequest request,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (request.inputMonthlySpendRm < 0) {
      return const CpiEquivalentUnavailable(CpiEquivalentFailure.invalidInput);
    }

    return CpiEquivalentAvailable(
      CpiEquivalentReading(
        equivalentRm: request.inputMonthlySpendRm * 1.02, // Fake multiplier
        date: DateTime.now(),
        reportingStateName: 'Selangor',
        cpiScope: 'Headline',
      ),
    );
  }

  @override
  void clearTemporaryCpiInput() {
    // No-op for fake
  }
}
