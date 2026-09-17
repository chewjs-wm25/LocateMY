import 'package:locatemy/features/map_location/map_location.dart';

/// Minimal domain models for Infrastructure Coverage feature.
final class InfrastructureCoverage {
  final int? score; // 0-100 or null when unavailable
  final ValidLocationReference location;
  final DateTime analysisDate;

  InfrastructureCoverage({this.score, required this.location, required this.analysisDate});
}

sealed class InfrastructureLoadOutcome {}

final class InfrastructureAvailable extends InfrastructureLoadOutcome {
  final InfrastructureCoverage snapshot;
  InfrastructureAvailable(this.snapshot);
}

final class InfrastructureUnavailable extends InfrastructureLoadOutcome {
  final String reason;
  InfrastructureUnavailable(this.reason);
}

final class InfrastructurePartial extends InfrastructureLoadOutcome {
  final InfrastructureCoverage snapshot;
  InfrastructurePartial(this.snapshot);
}
