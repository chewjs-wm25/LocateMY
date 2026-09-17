import 'package:locatemy/features/map_location/map_location.dart';

/// Shared enums and domain models for the Infrastructure Coverage feature.
enum InfrastructureLoadPolicy { cacheAllowed, refresh }

final class InfrastructureWeightSettings {
  final int health;
  final int education;
  final int transit;

  const InfrastructureWeightSettings({
    this.health = 5,
    this.education = 5,
    this.transit = 5,
  });

  factory InfrastructureWeightSettings.neutral() {
    return const InfrastructureWeightSettings();
  }

  Map<String, int> toMap() {
    return <String, int>{
      'health': health,
      'education': education,
      'transit': transit,
    };
  }
}

final class InfrastructureCategoryScore {
  final String key;
  final String labelZh;
  final String labelEn;
  final int score;
  final bool missing;

  const InfrastructureCategoryScore({
    required this.key,
    required this.labelZh,
    required this.labelEn,
    required this.score,
    this.missing = false,
  });
}

final class InfrastructureCoverage {
  final int score;
  final ValidLocationReference location;
  final DateTime analysisDate;
  final InfrastructureWeightSettings weights;
  final List<InfrastructureCategoryScore> categories;
  final List<String> missingCategories;

  const InfrastructureCoverage({
    required this.score,
    required this.location,
    required this.analysisDate,
    required this.weights,
    required this.categories,
    this.missingCategories = const <String>[],
  });
}

sealed class InfrastructureLoadOutcome {
  const InfrastructureLoadOutcome();
}

final class InfrastructureAvailable extends InfrastructureLoadOutcome {
  final InfrastructureCoverage snapshot;
  const InfrastructureAvailable(this.snapshot);
}

final class InfrastructureUnavailable extends InfrastructureLoadOutcome {
  final String reason;
  const InfrastructureUnavailable(this.reason);
}

final class InfrastructurePartial extends InfrastructureLoadOutcome {
  final InfrastructureCoverage snapshot;
  const InfrastructurePartial(this.snapshot);
}
