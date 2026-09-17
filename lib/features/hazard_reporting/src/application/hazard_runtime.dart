import 'hazard_service.dart';
import '../domain/hazard_models.dart';

final class HazardReportingRuntime {
  final HazardReporting reporting;
  HazardReportingRuntime({
    required HazardStore store,
    required String? Function() currentAccountId,
  }) : reporting = HazardService(store, currentAccountId);
  HazardRiskCounter get counter {
    return reporting as HazardRiskCounter;
  }
}
