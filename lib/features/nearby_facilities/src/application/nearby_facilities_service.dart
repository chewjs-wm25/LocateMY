


import 'dart:math';

import 'facility_cache.dart';
import 'facility_diagnostics.dart';

import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/facility_models.dart';

final class NearbyFacilitiesService implements NearbyFacilities {
  static const int _radiusMetres = 2000;
  static const String _mappingVersion = 'osm-facility-v1';
  static final FacilityAttribution _attribution = FacilityAttribution(
    source: '© OpenStreetMap contributors',
    copyrightUrl: Uri.parse('https://www.openstreetmap.org/copyright'),
  );
  final OverpassFacilitySource source;
  final DateTime Function() clock;
  final MapLayerHost Function()? mapLayerHost;
  final FacilityCache _cache;
  final Map<String, int> _requests = <String, int>{};
  final Expando<List<NearbyFacility>> _layerItems =
      Expando<List<NearbyFacility>>();
  final Expando<Map<String, MapMarkerKind>> _markerKinds =
      Expando<Map<String, MapMarkerKind>>();
  NearbyFacilitiesService(
    OverpassFacilitySource source, {
    required FacilityCache cache,
    DateTime Function()? clock,
    MapLayerHost Function()? mapLayerHost,
  }) : source = source,
       mapLayerHost = mapLayerHost,
       clock = clock ?? DateTime.now,
       _cache = cache;

  @override
  Future<FacilityAnalysisOutcome> analyse(FacilityAnalysisRequest request) {
    return observeFacility<FacilityAnalysisOutcome>('analyse', () {
      return _analyse(request);
    });
  }

  Future<FacilityAnalysisOutcome> _analyse(
    FacilityAnalysisRequest request,
  ) async {
    if (!_valid(request.location.point)) {
      return const FacilityAnalysisUnavailable(
        failure: FacilityFailure.invalidLocation,
      );
    }
    final String key = _cacheKey(request.location.point);
    final OverpassFacilityComplete? cached = await _cache.read(key);
    if (request.refreshPolicy == FacilityRefreshPolicy.cacheAllowed &&
        cached != null &&
        _validCache(cached)) {
      return FacilityAnalysisAvailable(
        analysis: _cached(
          _makeAnalysis(request.location, cached),
          request.location,
        ),
      );
    }
    final int generation = (_requests[key] ?? 0) + 1;
    _requests[key] = generation;
    final OverpassFacilityOutcome sourceOutcome = await source.query(
      OverpassFacilityQuery(
        centre: request.location.point,
        radiusMetres: _radiusMetres,
        mappingVersion: _mappingVersion,
      ),
    );
    if (sourceOutcome is OverpassFacilityComplete) {
      final FacilityAnalysis result = _makeAnalysis(
        request.location,
        sourceOutcome,
      );
      if (_requests[key] == generation) {
        await _cache.write(key, sourceOutcome);
      }
      return FacilityAnalysisAvailable(analysis: result);
    }
    if (cached != null && _validCache(cached)) {
      return FacilityAnalysisAvailable(
        analysis: _cached(
          _makeAnalysis(request.location, cached),
          request.location,
        ),
      );
    }
    return FacilityAnalysisUnavailable(failure: _failure(sourceOutcome));
  }

  @override
  Future<FacilityComparisonOutcome> compare(FacilityComparisonRequest request) {
    return observeFacility<FacilityComparisonOutcome>('compare', () {
      return _compare(request);
    });
  }

  Future<FacilityComparisonOutcome> _compare(
    FacilityComparisonRequest request,
  ) async {
    if (!_valid(request.locationA.point) || !_valid(request.locationB.point)) {
      return const FacilityComparisonUnavailable(
        failure: FacilityFailure.invalidLocation,
      );
    }
    if (_samePoint(request.locationA.point, request.locationB.point)) {
      return const FacilityComparisonUnavailable(
        failure: FacilityFailure.sameComparisonPoint,
      );
    }
    final FacilityAnalysisOutcome first = await analyse(
      FacilityAnalysisRequest(
        location: request.locationA,
        refreshPolicy: request.refreshPolicy,
      ),
    );
    final FacilityAnalysisOutcome second = await analyse(
      FacilityAnalysisRequest(
        location: request.locationB,
        refreshPolicy: request.refreshPolicy,
      ),
    );
    if (first is! FacilityAnalysisAvailable) {
      return FacilityComparisonNotComparable(
        locationA: first,
        locationB: second,
        failure: FacilityComparisonFailure.locationAUnavailable,
      );
    }
    if (second is! FacilityAnalysisAvailable) {
      return FacilityComparisonNotComparable(
        locationA: first,
        locationB: second,
        failure: FacilityComparisonFailure.locationBUnavailable,
      );
    }
    if (!_complete(first.analysis) || !_complete(second.analysis)) {
      return FacilityComparisonNotComparable(
        locationA: first,
        locationB: second,
        failure: FacilityComparisonFailure.incompleteResult,
      );
    }
    if (first.analysis.radiusMetres != second.analysis.radiusMetres) {
      return FacilityComparisonNotComparable(
        locationA: first,
        locationB: second,
        failure: FacilityComparisonFailure.incompatibleRadius,
      );
    }
    if (first.analysis.mappingVersion != second.analysis.mappingVersion) {
      return FacilityComparisonNotComparable(
        locationA: first,
        locationB: second,
        failure: FacilityComparisonFailure.incompatibleMappingVersion,
      );
    }
    return FacilityComparisonAvailable(
      comparison: FacilityComparison(
        locationA: first.analysis,
        locationB: second.analysis,
      ),
    );
  }

  @override
  Future<FacilityLayerOutcome> contributeLayer(FacilityLayerRequest request) {
    return observeFacility<FacilityLayerOutcome>('contributeLayer', () {
      return _contributeLayer(request);
    });
  }

  Future<FacilityLayerOutcome> _contributeLayer(
    FacilityLayerRequest request,
  ) async {
    if (!_complete(request.analysis)) {
      return const FacilityLayerNotPublished(
        failure: FacilityLayerFailure.analysisIncomplete,
      );
    }
    final MapLayerHost Function()? hostFactory = mapLayerHost;
    final List<NearbyFacility>? facilities = _layerItems[request.analysis];
    if (hostFactory == null || facilities == null) {
      return const FacilityLayerNotPublished(
        failure: FacilityLayerFailure.mapUnavailable,
      );
    }
    final MapLayerContributionOutcome outcome = await hostFactory().contribute(
      MapLayerContribution(
        providerId: 'nearby-facilities',
        layerId: 'facilities',
        viewportVersion: request.viewportVersion,
        visibility: MapLayerVisibility.visible,
        items: facilities
            .map((NearbyFacility facility) {
              return MapLayerItem(
                stableItemId: facility.stableId,
                point: facility.point,
                markerKind:
                    _markerKinds[request.analysis]?[facility.stableId] ??
                    MapMarkerKind.generic,
                intent: ProviderDefinedIntent(
                  providerId: 'nearby-facilities',
                  action: 'facilitySelected',
                  stableItemId: facility.stableId,
                ),
              );
            })
            .toList(growable: false),
      ),
    );
    if (outcome is MapLayerAccepted) {
      return const FacilityLayerPublished();
    }
    if (outcome is MapLayerRejected &&
        outcome.failure == MapLayerFailure.staleViewport) {
      return const FacilityLayerNotPublished(
        failure: FacilityLayerFailure.staleViewport,
      );
    }
    if (outcome is MapLayerRejected &&
        outcome.failure == MapLayerFailure.scopeUnavailable) {
      return const FacilityLayerNotPublished(
        failure: FacilityLayerFailure.scopeUnavailable,
      );
    }
    return const FacilityLayerNotPublished(
      failure: FacilityLayerFailure.mapUnavailable,
    );
  }

  FacilityAnalysis _makeAnalysis(
    ValidLocationReference location,
    OverpassFacilityComplete sourceOutcome,
  ) {
    final Map<FacilityCategory, List<NearbyFacility>> matches =
        <FacilityCategory, List<NearbyFacility>>{
          for (final FacilityCategory category in FacilityCategory.values)
            category: <NearbyFacility>[],
        };
    final Set<String> seen = <String>{};
    final Map<String, MapMarkerKind> markerKinds = <String, MapMarkerKind>{};
    for (final OverpassElement element in sourceOutcome.elements) {
      final String stableId = '${element.elementType}_${element.osmId}';
      final FacilityCategory? category = _category(element.tags);
      final double distance = _distance(
        location.point,
        element.representativePoint,
      );
      if (category == null || distance > _radiusMetres || !seen.add(stableId)) {
        continue;
      }
      String displayName = element.tags['name']?.trim() ?? '';
      if (displayName.isEmpty) {
        displayName = '未命名地点';
      }
      matches[category]!.add(
        NearbyFacility(
          stableId: stableId,
          displayName: displayName,
          point: element.representativePoint,
          distanceMetres: distance,
        ),
      );
      markerKinds[stableId] = _markerKind(category);
    }
    final List<NearbyFacility> layerItems = <NearbyFacility>[];
    final List<FacilityCategoryResult> categories = <FacilityCategoryResult>[];
    for (final FacilityCategory category in FacilityCategory.values) {
      final List<NearbyFacility> items = matches[category]!;
      items.sort((NearbyFacility a, NearbyFacility b) {
        final int order = a.distanceMetres.compareTo(b.distanceMetres);
        if (order == 0) {
          return a.stableId.compareTo(b.stableId);
        }
        return order;
      });
      layerItems.addAll(items);
      categories.add(
        FacilityCategoryResult(
          category: category,
          count: items.length,
          state: items.isEmpty
              ? FacilityCategoryState.completeEmpty
              : FacilityCategoryState.covered,
          nearest: List<NearbyFacility>.unmodifiable(items.take(3)),
        ),
      );
    }
    final FacilityAnalysis analysis = FacilityAnalysis(
      location: location,
      radiusMetres: _radiusMetres,
      mappingVersion: _mappingVersion,
      dataState: FacilityDataState.fresh,
      observedAt: sourceOutcome.queriedAt,
      attribution: _attribution,
      categories: List<FacilityCategoryResult>.unmodifiable(categories),
    );
    _layerItems[analysis] = List<NearbyFacility>.unmodifiable(layerItems);
    _markerKinds[analysis] = Map<String, MapMarkerKind>.unmodifiable(
      markerKinds,
    );
    return analysis;
  }

  FacilityAnalysis _cached(
    FacilityAnalysis value,
    ValidLocationReference location,
  ) {
    final FacilityAnalysis result = FacilityAnalysis(
      location: location,
      radiusMetres: value.radiusMetres,
      mappingVersion: value.mappingVersion,
      dataState: FacilityDataState.cached,
      observedAt: value.observedAt,
      attribution: value.attribution,
      categories: value.categories,
    );
    _layerItems[result] = _layerItems[value];
    _markerKinds[result] = _markerKinds[value];
    return result;
  }

  MapMarkerKind _markerKind(FacilityCategory category) {
    switch (category) {
      case FacilityCategory.health:
        return MapMarkerKind.facilityHealth;
      case FacilityCategory.education:
        return MapMarkerKind.facilityEducation;
      case FacilityCategory.dailyLiving:
        return MapMarkerKind.facilityDailyLiving;
      case FacilityCategory.transport:
        return MapMarkerKind.facilityTransport;
      case FacilityCategory.leisureGreen:
        return MapMarkerKind.facilityLeisureGreen;
    }
  }

  bool _complete(FacilityAnalysis value) {
    if (value.categories.length != 5) {
      return false;
    }
    final Set<FacilityCategory> seen = <FacilityCategory>{};
    for (final FacilityCategoryResult item in value.categories) {
      if (item.state == FacilityCategoryState.unknown ||
          !seen.add(item.category)) {
        return false;
      }
    }
    return true;
  }

  bool _valid(GeographicPoint point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude.abs() <= 90 &&
        point.longitude.abs() <= 180;
  }

  bool _samePoint(GeographicPoint a, GeographicPoint b) {
    return a.latitude == b.latitude && a.longitude == b.longitude;
  }

  String _cacheKey(GeographicPoint point) {
    return '${point.latitude},${point.longitude},$_radiusMetres,$_mappingVersion';
  }

  bool _validCache(OverpassFacilityComplete cached) {
    final Duration age = clock().difference(cached.queriedAt);
    return !age.isNegative && age < const Duration(hours: 24);
  }

  FacilityFailure _failure(OverpassFacilityOutcome value) {
    if (value is OverpassFacilityPartial) {
      return FacilityFailure.incompleteResponse;
    }
    final OverpassFailure failure = (value as OverpassFacilityFailed).failure;
    if (failure == OverpassFailure.rateLimited) {
      return FacilityFailure.rateLimited;
    }
    if (failure == OverpassFailure.invalidPayload) {
      return FacilityFailure.invalidPayload;
    }
    if (failure == OverpassFailure.networkUnavailable ||
        failure == OverpassFailure.timeout) {
      return FacilityFailure.sourceUnavailable;
    }
    return FacilityFailure.retryableUnavailable;
  }

  FacilityCategory? _category(Map<String, String> tags) {
    final String? amenity = tags['amenity'];
    if (<String>{
      'hospital',
      'clinic',
      'doctors',
      'dentist',
      'pharmacy',
    }.contains(amenity)) {
      return FacilityCategory.health;
    }
    if (<String>{
      'school',
      'college',
      'university',
      'kindergarten',
      'childcare',
    }.contains(amenity)) {
      return FacilityCategory.education;
    }
    if (tags['highway'] == 'bus_stop' ||
        <String>{
          'platform',
          'station',
          'stop_position',
        }.contains(tags['public_transport']) ||
        <String>{'station', 'halt', 'tram_stop'}.contains(tags['railway']) ||
        <String>{'ferry_terminal', 'charging_station'}.contains(amenity)) {
      return FacilityCategory.transport;
    }
    if (<String>{'supermarket', 'convenience'}.contains(tags['shop']) ||
        <String>{'marketplace', 'bank', 'atm', 'fuel'}.contains(amenity)) {
      return FacilityCategory.dailyLiving;
    }
    if (<String>{
      'park',
      'garden',
      'playground',
      'sports_centre',
      'fitness_centre',
    }.contains(tags['leisure'])) {
      return FacilityCategory.leisureGreen;
    }
    return null;
  }

  double _distance(GeographicPoint a, GeographicPoint b) {
    const double earth = 6371000;
    final double lat = (b.latitude - a.latitude) * pi / 180;
    final double lon = (b.longitude - a.longitude) * pi / 180;
    final double x =
        sin(lat / 2) * sin(lat / 2) +
        cos(a.latitude * pi / 180) *
            cos(b.latitude * pi / 180) *
            sin(lon / 2) *
            sin(lon / 2);
    return earth * 2 * atan2(sqrt(x), sqrt(1 - x));
  }
}
