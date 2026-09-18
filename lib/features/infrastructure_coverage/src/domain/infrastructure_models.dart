// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:locatemy/features/map_location/map_location.dart';

/// Shared enums and domain models for the Infrastructure Coverage feature.
enum InfrastructureLoadPolicy { cacheAllowed, refresh }

final class InfrastructureWeightSettings {
  final int health;
  final int education;
  final int transit;

  const InfrastructureWeightSettings({
    int health = 5,
    int education = 5,
    int transit = 5,
  }) : health = health,
       education = education,
       transit = transit;

  factory InfrastructureWeightSettings.neutral() {
    return const InfrastructureWeightSettings();
  }

  bool get valid {
    return health >= 1 &&
        health <= 10 &&
        education >= 1 &&
        education <= 10 &&
        transit >= 1 &&
        transit <= 10;
  }

  bool same(InfrastructureWeightSettings other) {
    return health == other.health &&
        education == other.education &&
        transit == other.transit;
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
  final double? score;
  final bool missing;

  const InfrastructureCategoryScore({
    required String key,
    required String labelZh,
    required String labelEn,
    required double? score,
    bool missing = false,
  }) : key = key,
       labelZh = labelZh,
       labelEn = labelEn,
       score = score,
       missing = missing;
}

final class InfrastructureCoverage {
  final int? score;
  final ValidLocationReference location;
  final DateTime analysisDate;
  final InfrastructureWeightSettings weights;
  final List<InfrastructureCategoryScore> categories;
  final List<String> missingCategories;
  final String? district;
  final String? state;
  final Map<String, int> sourceYears;
  final Map<String, int> populationYears;
  final bool transitPartial;
  final bool transitDistanceOnly;

  InfrastructureCoverage({
    required int? score,
    required ValidLocationReference location,
    required DateTime analysisDate,
    required InfrastructureWeightSettings weights,
    required List<InfrastructureCategoryScore> categories,
    List<String> missingCategories = const <String>[],
    String? district,
    String? state,
    Map<String, int> sourceYears = const <String, int>{},
    Map<String, int> populationYears = const <String, int>{},
    bool transitPartial = false,
    bool transitDistanceOnly = false,
  }) : transitPartial = transitPartial,
       transitDistanceOnly = transitDistanceOnly,
       score = score,
       location = location,
       analysisDate = analysisDate,
       weights = weights,
       categories = categories,
       missingCategories = missingCategories,
       district = district,
       state = state,
       sourceYears = Map<String, int>.unmodifiable(sourceYears),
       populationYears = Map<String, int>.unmodifiable(populationYears);
}

sealed class InfrastructureLoadOutcome {
  const InfrastructureLoadOutcome();
}

final class InfrastructureAvailable extends InfrastructureLoadOutcome {
  final InfrastructureCoverage snapshot;
  const InfrastructureAvailable(InfrastructureCoverage snapshot)
    : snapshot = snapshot;
}

final class InfrastructureUnavailable extends InfrastructureLoadOutcome {
  final String reason;
  const InfrastructureUnavailable(String reason) : reason = reason;
}

final class InfrastructurePartial extends InfrastructureLoadOutcome {
  final InfrastructureCoverage snapshot;
  const InfrastructurePartial(InfrastructureCoverage snapshot)
    : snapshot = snapshot;
}
