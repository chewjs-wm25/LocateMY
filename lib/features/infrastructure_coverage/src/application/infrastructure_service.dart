import 'dart:math' as math;

import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/infrastructure_models.dart';

/// Deterministic infrastructure evaluator used for the feature prototype.
/// It follows the product scoring model: weighted ICI with water/power/health/
/// education/transit categories and neutral default weights.
final class InfrastructureService {
  const InfrastructureService();

  Future<InfrastructureLoadOutcome> fetch(
    ValidLocationReference location,
    DateTime analysisDate, {
    InfrastructureLoadPolicy policy = InfrastructureLoadPolicy.cacheAllowed,
    InfrastructureWeightSettings weights = const InfrastructureWeightSettings(),
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final List<InfrastructureCategoryScore> categories = <InfrastructureCategoryScore>[
      _water(location),
      _power(location),
      _health(location),
      _education(location),
      _transit(location),
    ];

    final List<String> missing = <String>[];

    double weightedSum = 0;
    double normalizedWeight = 0;
    for (final InfrastructureCategoryScore category in categories) {
      if (category.missing) {
        missing.add(category.key);
        continue;
      }
      final double multiplier = _multiplierFor(category.key, weights);
      final double adjustedWeight = 0.2 * multiplier;
      weightedSum += category.score * adjustedWeight;
      normalizedWeight += adjustedWeight;
    }

    if (normalizedWeight < 0.6) {
      return InfrastructurePartial(
        InfrastructureCoverage(
          score: 0,
          location: location,
          analysisDate: analysisDate,
          weights: weights,
          categories: categories,
          missingCategories: missing,
        ),
      );
    }

    final int score = (weightedSum / normalizedWeight).round();
    return InfrastructureAvailable(
      InfrastructureCoverage(
        score: score.clamp(0, 100),
        location: location,
        analysisDate: analysisDate,
        weights: weights,
        categories: categories,
        missingCategories: missing,
      ),
    );
  }

  static double _multiplierFor(String key, InfrastructureWeightSettings weights) {
    final int raw = switch (key) {
      'water' => 5,
      'power' => 5,
      'health' => weights.health,
      'education' => weights.education,
      'transit' => weights.transit,
      _ => 5,
    };
    return (raw / 5).clamp(0.2, 2.0);
  }

  static InfrastructureCategoryScore _water(ValidLocationReference location) {
    final int score = _stableScore(location.point.latitude, location.point.longitude, 0);
    return InfrastructureCategoryScore(
      key: 'water',
      labelZh: '供水',
      labelEn: 'Water',
      score: score,
    );
  }

  static InfrastructureCategoryScore _power(ValidLocationReference location) {
    final int score = _stableScore(location.point.latitude, location.point.longitude, 1);
    return InfrastructureCategoryScore(
      key: 'power',
      labelZh: '供电',
      labelEn: 'Power',
      score: score,
    );
  }

  static InfrastructureCategoryScore _health(ValidLocationReference location) {
    final int score = _stableScore(location.point.latitude, location.point.longitude, 2);
    return InfrastructureCategoryScore(
      key: 'health',
      labelZh: '医疗',
      labelEn: 'Health',
      score: score,
    );
  }

  static InfrastructureCategoryScore _education(ValidLocationReference location) {
    final int score = _stableScore(location.point.latitude, location.point.longitude, 3);
    return InfrastructureCategoryScore(
      key: 'education',
      labelZh: '教育',
      labelEn: 'Education',
      score: score,
    );
  }

  static InfrastructureCategoryScore _transit(ValidLocationReference location) {
    final int score = _stableScore(location.point.latitude, location.point.longitude, 4);
    return InfrastructureCategoryScore(
      key: 'transit',
      labelZh: '交通',
      labelEn: 'Transit',
      score: score,
    );
  }

  static int _stableScore(double lat, double lon, int salt) {
    final double base = (lat * 1000 + lon * 1000 + salt * 17.7) % 100;
    final double adjusted = base < 0 ? -base : base;
    final double value = 35 + (adjusted * 0.65) + math.sin((lat + lon) * 20 + salt) * 18;
    return value.round().clamp(0, 100);
  }
}
