// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import 'transit_models.dart';

/// Immutable input plus the opaque request identity supplied by the root.
final class AnalysisReturnContext {
  final ValidLocationReference location;
  final LocationRole role;
  final DateTime analysisDate;
  final Object originalRequestIdentity;
  const AnalysisReturnContext({
    required ValidLocationReference location,
    required LocationRole role,
    required DateTime analysisDate,
    required Object originalRequestIdentity,
  }) : location = location,
       role = role,
       analysisDate = analysisDate,
       originalRequestIdentity = originalRequestIdentity;
}

final class OpenPublicTransportationIntent implements ShellIntent {
  final AnalysisReturnContext returnContext;
  const OpenPublicTransportationIntent(AnalysisReturnContext returnContext)
    : returnContext = returnContext;
}

final class OpenPublicTransportationComparisonIntent implements ShellIntent {
  final AnalysisReturnContext a;
  final AnalysisReturnContext b;
  const OpenPublicTransportationComparisonIntent(
    AnalysisReturnContext a,
    AnalysisReturnContext b,
  ) : a = a,
      b = b;
}

final class ReturnToMapIntent implements ShellIntent {
  final AnalysisReturnContext returnContext;
  const ReturnToMapIntent(AnalysisReturnContext returnContext)
    : returnContext = returnContext;
}

final class PublicTransportationContribution implements ShellContribution {
  final TransitLoadOutcome outcome;
  final AnalysisReturnContext returnContext;
  const PublicTransportationContribution(
    TransitLoadOutcome outcome,
    AnalysisReturnContext returnContext,
  ) : outcome = outcome,
      returnContext = returnContext;
}

final class PublicTransportationComparisonContribution
    implements ShellContribution {
  final TransitComparisonOutcome outcome;
  final AnalysisReturnContext a;
  final AnalysisReturnContext b;
  const PublicTransportationComparisonContribution(
    TransitComparisonOutcome outcome,
    AnalysisReturnContext a,
    AnalysisReturnContext b,
  ) : outcome = outcome,
      a = a,
      b = b;
}
