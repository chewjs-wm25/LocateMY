// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import '../features/map_location/map_location.dart';
import '../features/crime_security/crime_security.dart';
import '../features/cost_of_living_budget/cost_of_living_budget.dart';
import '../features/nearby_facilities/nearby_facilities.dart';
import '../features/public_transportation/public_transportation.dart';
import '../features/infrastructure_coverage/infrastructure_coverage.dart';

/// Composes native business readings without calculating a location total.
final class BusinessLocationSummaryReader implements LocationSummaryReader {
  final CrimeSecurity? crime;
  final CostOfLivingBudget? cost;
  final NearbyFacilities facilities;
  final PublicTransportation transportation;
  final InfrastructureService? infrastructure;
  const BusinessLocationSummaryReader({
    CrimeSecurity? crime,
    CostOfLivingBudget? cost,
    required NearbyFacilities facilities,
    required PublicTransportation transportation,
    InfrastructureService? infrastructure,
  }) : crime = crime,
       cost = cost,
       facilities = facilities,
       transportation = transportation,
       infrastructure = infrastructure;

  @override
  Future<List<LocationSummaryReading>> read(
    ValidLocationReference location,
    DateTime date,
  ) {
    return Future.wait<LocationSummaryReading>(<Future<LocationSummaryReading>>[
      _observe(LocationSummaryMetric.safety, () {
        return _safety(location);
      }),
      _observe(LocationSummaryMetric.cost, () {
        return _cost(location);
      }),
      _observe(LocationSummaryMetric.facilities, () {
        return _facilities(location);
      }),
      _observe(LocationSummaryMetric.transportation, () {
        return _transit(location, date);
      }),
      _observe(LocationSummaryMetric.infrastructure, () {
        return _infrastructure(location, date);
      }),
    ]);
  }

  Future<LocationSummaryReading> _observe(
    LocationSummaryMetric metric,
    Future<LocationSummaryReading> Function() read,
  ) async {
    try {
      return await read();
    } catch (_) {
      // One unavailable provider must not suppress the other four readings.
      return LocationSummaryReading(metric);
    }
  }

  Future<LocationSummaryReading> _safety(
    ValidLocationReference location,
  ) async {
    final SafetyAnalysis? result = await crime?.analyse(location);
    if (result?.score == null) {
      return const LocationSummaryReading(LocationSummaryMetric.safety);
    }
    final String value = result!.score!.toStringAsFixed(1);
    return LocationSummaryReading(
      LocationSummaryMetric.safety,
      english: '$value / 100 · ${result.reportingState} (state)',
      chinese: '$value / 100 · ${result.reportingState}（州级）',
    );
  }

  Future<LocationSummaryReading> _cost(ValidLocationReference location) async {
    final CostAnalysisOutcome? outcome = await cost?.analyse(
      CostAnalysisRequest(
        location: location,
        refreshPolicy: CostRefreshPolicy.cacheAllowed,
      ),
    );
    CostAnalysis? result;
    if (outcome is CostAnalysisAvailable) {
      result = outcome.analysis;
    } else if (outcome is CostAnalysisPartial) {
      result = outcome.analysis;
    }
    if (result == null || result.costIndex == null) {
      return const LocationSummaryReading(LocationSummaryMetric.cost);
    }
    final String value = result.costIndex!.toStringAsFixed(1);
    String en = '$value (national reference 100)';
    String zh = '$value（全国基准 100）';
    if (result.isPartialBasket) {
      en += ' · Partial basket';
      zh += ' · 部分篮子';
    }
    en +=
        ' · ${result.indexedItemCount}/11 items · ${result.availableMonths} months';
    zh += ' · ${result.indexedItemCount}/11 项 · ${result.availableMonths} 个月';
    return LocationSummaryReading(
      LocationSummaryMetric.cost,
      english: en,
      chinese: zh,
    );
  }

  Future<LocationSummaryReading> _facilities(
    ValidLocationReference location,
  ) async {
    final FacilityAnalysisOutcome outcome = await facilities.analyse(
      FacilityAnalysisRequest(
        location: location,
        refreshPolicy: FacilityRefreshPolicy.cacheAllowed,
      ),
    );
    if (outcome is! FacilityAnalysisAvailable) {
      return const LocationSummaryReading(LocationSummaryMetric.facilities);
    }
    final List<String> en = <String>[];
    final List<String> zh = <String>[];
    for (final FacilityCategoryResult category in outcome.analysis.categories) {
      final String labelEn;
      final String labelZh;
      switch (category.category) {
        case FacilityCategory.health:
          labelEn = 'Healthcare';
          labelZh = '医疗';
          break;
        case FacilityCategory.education:
          labelEn = 'Education';
          labelZh = '教育';
          break;
        case FacilityCategory.dailyLiving:
          labelEn = 'Daily living';
          labelZh = '日常生活';
          break;
        case FacilityCategory.transport:
          labelEn = 'Transport';
          labelZh = '交通';
          break;
        case FacilityCategory.leisureGreen:
          labelEn = 'Leisure';
          labelZh = '休闲绿地';
          break;
      }
      String valueEn = 'Unknown';
      String valueZh = '未知';
      if (category.state != FacilityCategoryState.unknown) {
        if (category.state == FacilityCategoryState.completeEmpty) {
          valueEn = '0 recorded';
          valueZh = '0 项已收录';
        } else if (category.count != null) {
          valueEn = '${category.count} recorded';
          valueZh = '${category.count} 项已收录';
        } else {
          valueEn = 'Covered · count unknown';
          valueZh = '已覆盖 · 数量未知';
        }
        if (category.nearest.isNotEmpty) {
          double nearest = category.nearest.first.distanceMetres;
          for (final NearbyFacility facility in category.nearest) {
            if (facility.distanceMetres < nearest) {
              nearest = facility.distanceMetres;
            }
          }
          valueEn += ' · nearest ${nearest.round()} m';
          valueZh += ' · 最近 ${nearest.round()} m';
        }
      }
      en.add('$labelEn: $valueEn');
      zh.add('$labelZh: $valueZh');
    }
    return LocationSummaryReading(
      LocationSummaryMetric.facilities,
      english: en.join('\n'),
      chinese: zh.join('\n'),
    );
  }

  Future<LocationSummaryReading> _transit(
    ValidLocationReference location,
    DateTime date,
  ) async {
    final TransitLoadOutcome outcome = await transportation.load(
      TransitRequest(
        location: location,
        analysisDate: date,
        policy: TransitLoadPolicy.cacheAllowed,
      ),
    );
    final int count;
    final int? nearest;
    bool partial = false;
    if (outcome is TransitAvailable) {
      count = outcome.snapshot.uniqueStopCount;
      nearest = outcome.snapshot.nearestDistanceMeters;
    } else if (outcome is TransitIncomplete) {
      count = outcome.snapshot.uniqueStopCount;
      nearest = outcome.snapshot.nearestDistanceMeters;
      partial = true;
    } else {
      return const LocationSummaryReading(LocationSummaryMetric.transportation);
    }
    String en = '$count stops within 1.5 km';
    String zh = '1.5 km 内 $count 个站点';
    if (partial) {
      en += ' · Incomplete';
      zh += ' · 资料不完整';
    }
    if (nearest != null) {
      final int minutes = (nearest / 80).ceil();
      en +=
          ' · nearest $nearest m · about $minutes min walking (straight-line estimate)';
      zh += ' · 最近 $nearest m · 步行约 $minutes 分钟（直线距离粗估）';
    }
    return LocationSummaryReading(
      LocationSummaryMetric.transportation,
      english: en,
      chinese: zh,
    );
  }

  Future<LocationSummaryReading> _infrastructure(
    ValidLocationReference location,
    DateTime date,
  ) async {
    // Summary always uses neutral priorities, never account preview weights.
    final InfrastructureLoadOutcome? outcome = await infrastructure?.summary(
      location,
      date,
    );
    InfrastructureCoverage? result;
    if (outcome is InfrastructureAvailable) {
      result = outcome.snapshot;
    } else if (outcome is InfrastructurePartial) {
      result = outcome.snapshot;
    }
    if (result == null) {
      return const LocationSummaryReading(LocationSummaryMetric.infrastructure);
    }
    String en = 'ICI unavailable';
    String zh = 'ICI 不可计算';
    if (result.score != null) {
      en = 'ICI ${result.score} / 100';
      zh = en;
    }
    InfrastructureCategoryScore? lowest;
    final List<String> missingEn = <String>[];
    final List<String> missingZh = <String>[];
    for (final InfrastructureCategoryScore category in result.categories) {
      if (category.score == null) {
        missingEn.add(category.labelEn);
        missingZh.add(category.labelZh);
      } else if (lowest == null || category.score! < lowest.score!) {
        lowest = category;
      }
    }
    if (missingEn.isNotEmpty) {
      en += ' · Missing: ${missingEn.join(', ')}';
      zh += ' · 缺失：${missingZh.join('、')}';
    } else if (lowest != null) {
      en += ' · Lowest: ${lowest.labelEn} ${lowest.score!.toStringAsFixed(1)}';
      zh += ' · 最低：${lowest.labelZh} ${lowest.score!.toStringAsFixed(1)}';
    }
    return LocationSummaryReading(
      LocationSummaryMetric.infrastructure,
      english: en,
      chinese: zh,
    );
  }
}
