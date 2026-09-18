


import 'domain/facility_models.dart';

final class FakeNearbyFacilities implements NearbyFacilities {
  FacilityAnalysisOutcome analysisOutcome;
  FacilityComparisonOutcome comparisonOutcome;
  FacilityLayerOutcome layerOutcome;
  FakeNearbyFacilities({
    required FacilityAnalysisOutcome analysisOutcome,
    required FacilityComparisonOutcome comparisonOutcome,
    required FacilityLayerOutcome layerOutcome,
  }) : analysisOutcome = analysisOutcome,
       comparisonOutcome = comparisonOutcome,
       layerOutcome = layerOutcome;
  @override
  Future<FacilityAnalysisOutcome> analyse(
    FacilityAnalysisRequest request,
  ) async {
    return analysisOutcome;
  }

  @override
  Future<FacilityComparisonOutcome> compare(
    FacilityComparisonRequest request,
  ) async {
    return comparisonOutcome;
  }

  @override
  Future<FacilityLayerOutcome> contributeLayer(
    FacilityLayerRequest request,
  ) async {
    return layerOutcome;
  }
}
