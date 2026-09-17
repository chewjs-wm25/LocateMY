import '../domain/transit_models.dart';

/// External standardized-data boundary; application owns this seam.
abstract interface class TransitAnalysisReader {
  Future<Map<String, Object?>> readTransitAnalysis(TransitRequest request);
}
