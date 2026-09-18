import '../domain/transit_models.dart';


abstract interface class TransitAnalysisReader {
  Future<Map<String, Object?>> readTransitAnalysis(TransitRequest request);
}
