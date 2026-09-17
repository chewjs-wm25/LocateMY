// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:math' as math;

import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/transit_models.dart';
import 'transit_analysis_reader.dart';

PublicTransportation createPublicTransportation(TransitAnalysisReader reader) {
  return PublicTransportationService(reader);
}

const Map<String, String> _expectedFeedSources = <String, String>{
  'gtfs_static_ktmb': 'https://api.data.gov.my/gtfs-static/ktmb',
  'gtfs_static_prasarana_rapid_rail_kl':
      'https://api.data.gov.my/gtfs-static/prasarana?category=rapid-rail-kl',
  'gtfs_static_prasarana_rapid_bus_kl':
      'https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-kl',
  'gtfs_static_prasarana_rapid_bus_penang':
      'https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-penang',
  'gtfs_static_prasarana_rapid_bus_kuantan': 'https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-kuantan',
  'gtfs_static_prasarana_rapid_bus_mrtfeeder': 'https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-mrtfeeder',
  'gtfs_static_mybas_kangar':
      'https://api.data.gov.my/gtfs-static/mybas-kangar',
  'gtfs_static_mybas_alor_setar':
      'https://api.data.gov.my/gtfs-static/mybas-alor-setar',
  'gtfs_static_mybas_kota_bharu':
      'https://api.data.gov.my/gtfs-static/mybas-kota-bharu',
  'gtfs_static_mybas_kuala_terengganu':
      'https://api.data.gov.my/gtfs-static/mybas-kuala-terengganu',
  'gtfs_static_mybas_ipoh': 'https://api.data.gov.my/gtfs-static/mybas-ipoh',
  'gtfs_static_mybas_seremban_a':
      'https://api.data.gov.my/gtfs-static/mybas-seremban-a',
  'gtfs_static_mybas_seremban_b':
      'https://api.data.gov.my/gtfs-static/mybas-seremban-b',
  'gtfs_static_mybas_melaka':
      'https://api.data.gov.my/gtfs-static/mybas-melaka',
  'gtfs_static_mybas_johor': 'https://api.data.gov.my/gtfs-static/mybas-johor',
  'gtfs_static_mybas_kuching':
      'https://api.data.gov.my/gtfs-static/mybas-kuching',
};

final class PublicTransportationService implements PublicTransportation {
  final TransitAnalysisReader _reader;
  final Map<String, TransitLoadOutcome> _lastSuccess =
      <String, TransitLoadOutcome>{};
  PublicTransportationService(TransitAnalysisReader reader) : _reader = reader;
  @override
  Future<TransitLoadOutcome> load(TransitRequest request) async {
    final String key =
        '${request.location.locationId}:${request.location.point.latitude}:${request.location.point.longitude}:${_date(request.analysisDate)}';
    try {
      final Map<String, Object?> payload = await _reader.readTransitAnalysis(
        request,
      );
      final TransitLoadOutcome outcome = _outcome(payload, request);
      if (outcome is TransitAvailable || outcome is TransitIncomplete) {
        _lastSuccess.remove(key);
        _lastSuccess[key] = outcome;
        if (_lastSuccess.length > 100) {
          _lastSuccess.remove(_lastSuccess.keys.first);
        }
      }
      return outcome;
    } on FormatException {
      final TransitLoadOutcome? previous = _lastSuccess[key];
      if (previous != null) {
        return previous;
      }
      return const TransitUnavailable(
        TransitUnavailableReason.sourceUnverifiable,
        <FeedStatus>[],
      );
    } on TypeError {
      final TransitLoadOutcome? previous = _lastSuccess[key];
      if (previous != null) {
        return previous;
      }
      return const TransitUnavailable(
        TransitUnavailableReason.sourceUnverifiable,
        <FeedStatus>[],
      );
    } catch (_) {
      final TransitLoadOutcome? previous = _lastSuccess[key];
      if (previous != null) {
        return previous;
      }
      return const TransitUnavailable(
        TransitUnavailableReason.retryableUnavailable,
        <FeedStatus>[],
      );
    }
  }

  @override
  Future<TransitComparisonOutcome> compare(
    TransitComparisonRequest request,
  ) async {
    final List<TransitLoadOutcome> sides =
        await Future.wait<TransitLoadOutcome>(<Future<TransitLoadOutcome>>[
          load(request.a),
          load(request.b),
        ]);
    final TransitLoadOutcome a = sides[0];
    final TransitLoadOutcome b = sides[1];
    if (a is! TransitAvailable || b is! TransitAvailable) {
      TransitComparisonReason reason = TransitComparisonReason.sideUnavailable;
      if (a is TransitIncomplete || b is TransitIncomplete) {
        reason = TransitComparisonReason.sideIncomplete;
      }
      return TransitIncomparable(a, b, reason);
    }
    if (_date(a.snapshot.analysisDate) != _date(b.snapshot.analysisDate)) {
      return TransitIncomparable(
        a,
        b,
        TransitComparisonReason.analysisDateMismatch,
      );
    }
    if (a.snapshot.radiusMeters != b.snapshot.radiusMeters) {
      return TransitIncomparable(a, b, TransitComparisonReason.radiusMismatch);
    }
    if (a.snapshot.provenance.snapshotId != b.snapshot.provenance.snapshotId ||
        a.snapshot.provenance.referenceGridVersion !=
            b.snapshot.provenance.referenceGridVersion ||
        !_sameFeeds(a.snapshot.feeds, b.snapshot.feeds)) {
      return TransitIncomparable(
        a,
        b,
        TransitComparisonReason.provenanceMismatch,
      );
    }
    if (a.snapshot.serviceOutcome != TransitServiceOutcome.served ||
        b.snapshot.serviceOutcome != TransitServiceOutcome.served ||
        a.snapshot.score == null ||
        b.snapshot.score == null) {
      return TransitIncomparable(
        a,
        b,
        TransitComparisonReason.serviceOutcomeNotScored,
      );
    }
    return TransitComparable(a.snapshot, b.snapshot);
  }

  bool _sameFeeds(List<FeedStatus> a, List<FeedStatus> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i].feedId != b[i].feedId ||
          a[i].sourceId != b[i].sourceId ||
          a[i].sourceUrl != b[i].sourceUrl ||
          a[i].availability != b[i].availability) {
        return false;
      }
    }
    return true;
  }

  String _date(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _string(Map<String, Object?> row, String field) {
    final Object? value = row[field];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing $field');
    }
    return value;
  }

  int _count(Map<String, Object?> row, String field) {
    final Object? value = row[field];
    if (value is! int || value < 0) {
      throw FormatException('Invalid $field');
    }
    return value;
  }

  List<Map<String, Object?>> _rows(Object? value) {
    if (value is! List) {
      throw const FormatException('Missing result rows');
    }
    final List<Map<String, Object?>> rows = <Map<String, Object?>>[];
    for (final Object? row in value) {
      if (row is! Map) {
        throw const FormatException('Invalid result row');
      }
      rows.add(Map<String, Object?>.from(row));
    }
    return rows;
  }

  TransitLoadOutcome _outcome(
    Map<String, Object?> raw,
    TransitRequest request,
  ) {
    final List<FeedStatus> feeds = _feeds(raw['feeds']);
    if (feeds.length != 16) {
      throw const FormatException('Expected feed registry is incomplete');
    }
    for (final FeedStatus feed in feeds) {
      if (_expectedFeedSources[feed.feedId] != feed.sourceUrl.toString() ||
          feed.sourceId != feed.feedId) {
        throw const FormatException(
          'Feed identity or official source mismatch',
        );
      }
    }
    final String availability = _string(raw, 'availability_status');
    if (availability == 'unavailable') {
      TransitUnavailableReason reason;
      switch (raw['unavailable_reason']) {
        case 'no_usable_feed':
          reason = TransitUnavailableReason.noUsableFeed;
          break;
        case 'analysis_date_outside_service_range':
          reason = TransitUnavailableReason.analysisDateOutsideServiceRange;
          break;
        case 'retryable_unavailable':
          reason = TransitUnavailableReason.retryableUnavailable;
          break;
        case 'source_unverifiable':
          reason = TransitUnavailableReason.sourceUnverifiable;
          break;
        default:
          throw const FormatException('Unknown unavailable reason');
      }
      return TransitUnavailable(reason, feeds);
    }
    if (availability != 'available' && availability != 'incomplete') {
      throw const FormatException('Unknown availability');
    }
    if (raw['radius_m'] != 1500 ||
        raw['analysis_date'] != _date(request.analysisDate) ||
        raw['latitude'] != request.location.point.latitude ||
        raw['longitude'] != request.location.point.longitude) {
      throw const FormatException('Result does not match requested scope');
    }
    int usable = 0;
    for (final FeedStatus feed in feeds) {
      if (feed.availability == FeedAvailability.usable) {
        usable++;
      }
    }
    if ((availability == 'available' && usable != 16) ||
        (availability == 'incomplete' && (usable == 0 || usable == 16))) {
      return TransitUnavailable(
        TransitUnavailableReason.sourceUnverifiable,
        feeds,
      );
    }
    final DateTime generatedAt = DateTime.parse(_string(raw, 'generated_at'))
        .toUtc();
    final TransitProvenance provenance = TransitProvenance(
      snapshotId: _string(raw, 'snapshot_id'),
      referenceGridVersion: _string(raw, 'reference_grid_version'),
      generatedAt: generatedAt,
    );
    final List<TransitStation> stations = _stations(
      raw['stations'],
      request.location.point,
    );
    for (final TransitStation station in stations) {
      bool hasUsableFeed = false;
      for (final FeedStatus feed in feeds) {
        if (feed.feedId == station.feedId &&
            feed.availability == FeedAvailability.usable) {
          hasUsableFeed = true;
          break;
        }
      }
      if (!hasUsableFeed) {
        throw const FormatException('Station has no usable expected feed');
      }
    }
    final int stops = _count(raw, 'unique_stop_count');
    final int routes = _count(raw, 'unique_route_count');
    final int? nearest = raw['nearest_distance_m'] as int?;
    if (stops != stations.length ||
        (stops == 0 && nearest != null) ||
        (stops > 0 && nearest != stations.first.distanceMeters)) {
      throw const FormatException('Incomplete station facts');
    }
    if (availability == 'incomplete') {
      return TransitIncomplete(
        TransitPartialSnapshot(
          location: request.location,
          analysisDate: request.analysisDate,
          radiusMeters: 1500,
          stations: stations,
          uniqueStopCount: stops,
          nearestDistanceMeters: nearest,
          uniqueRouteCount: routes,
          feeds: feeds,
          provenance: provenance,
        ),
      );
    }
    TransitServiceOutcome service;
    TransitScore? score;
    switch (raw['service_outcome']) {
      case 'served':
        final int value = _count(raw, 'transit_score');
        if (stops == 0 || routes == 0 || value > 100) {
          throw const FormatException('Invalid served facts');
        }
        service = TransitServiceOutcome.served;
        score = TransitScore(value);
        break;
      case 'no_stops':
        if (stops != 0 || routes != 0 || raw['transit_score'] != null) {
          throw const FormatException('Invalid no-stops facts');
        }
        service = TransitServiceOutcome.noStops;
        break;
      case 'no_active_routes':
        if (stops == 0 || routes != 0 || raw['transit_score'] != null) {
          throw const FormatException('Invalid zero-route facts');
        }
        service = TransitServiceOutcome.noActiveRoutes;
        break;
      default:
        throw const FormatException('Unknown service outcome');
    }
    return TransitAvailable(
      TransitSnapshot(
        location: request.location,
        analysisDate: request.analysisDate,
        radiusMeters: 1500,
        stations: stations,
        uniqueStopCount: stops,
        nearestDistanceMeters: nearest,
        uniqueRouteCount: routes,
        serviceOutcome: service,
        score: score,
        feeds: feeds,
        provenance: provenance,
      ),
    );
  }

  List<TransitStation> _stations(Object? value, GeographicPoint center) {
    final List<TransitStation> stations = <TransitStation>[];
    final Set<String> ids = <String>{};
    for (final Map<String, Object?> row in _rows(value)) {
      final String feedId = _string(row, 'feed_id');
      final String stopId = _string(row, 'stop_id');
      if (!ids.add('$feedId:$stopId')) {
        throw const FormatException('Duplicate station');
      }
      final double latitude = (row['latitude'] as num).toDouble();
      final double longitude = (row['longitude'] as num).toDouble();
      final int distance = _count(row, 'distance_m');
      if (!latitude.isFinite ||
          !longitude.isFinite ||
          latitude.abs() > 90 ||
          longitude.abs() > 180 ||
          distance > 1500) {
        throw const FormatException('Station outside analysis range');
      }
      final double radians = math.pi / 180;
      final double latitudeDelta = (latitude - center.latitude) * radians;
      final double longitudeDelta = (longitude - center.longitude) * radians;
      final double halfLatitudeSin = math.sin(latitudeDelta / 2);
      final double halfLongitudeSin = math.sin(longitudeDelta / 2);
      final double haversine =
          halfLatitudeSin * halfLatitudeSin +
          math.cos(center.latitude * radians) *
              math.cos(latitude * radians) *
              halfLongitudeSin *
              halfLongitudeSin;
      final double geometricDistance =
          6371008.8 * 2 * math.asin(math.sqrt(haversine.clamp(0, 1)));
      // PostGIS uses the WGS84 ellipsoid; this spherical sanity check allows
      // its maximum 0.6% deviation plus integer-rounding tolerance.
      if ((geometricDistance - distance).abs() >
          2 + geometricDistance * 0.006) {
        throw const FormatException(
          'Station coordinates and distance disagree',
        );
      }
      TransitStationType type;
      switch (row['station_type']) {
        case 'bus':
          type = TransitStationType.bus;
          break;
        case 'rail':
          type = TransitStationType.rail;
          break;
        case 'ferry':
          type = TransitStationType.ferry;
          break;
        case 'other':
          type = TransitStationType.other;
          break;
        default:
          throw const FormatException('Unknown station type');
      }
      stations.add(
        TransitStation(
          feedId: feedId,
          stopId: stopId,
          name: _string(row, 'name'),
          point: GeographicPoint(latitude: latitude, longitude: longitude),
          type: type,
          distanceMeters: distance,
          parentStation: row['parent_station'] as String?,
        ),
      );
    }
    stations.sort((TransitStation a, TransitStation b) {
      final int order = a.distanceMeters.compareTo(b.distanceMeters);
      if (order != 0) {
        return order;
      }
      return '${a.feedId}:${a.stopId}'.compareTo('${b.feedId}:${b.stopId}');
    });
    return List<TransitStation>.unmodifiable(stations);
  }

  List<FeedStatus> _feeds(Object? value) {
    final List<FeedStatus> feeds = <FeedStatus>[];
    final Set<String> ids = <String>{};
    for (final Map<String, Object?> row in _rows(value)) {
      final String id = _string(row, 'feed_id');
      if (!ids.add(id)) {
        throw const FormatException('Duplicate feed');
      }
      final Uri source = Uri.parse(_string(row, 'source_url'));
      if (!source.hasAuthority ||
          (source.scheme != 'https' && source.scheme != 'http')) {
        throw const FormatException('Unverified source URL');
      }
      FeedAvailability availability;
      switch (row['availability']) {
        case 'usable':
          availability = FeedAvailability.usable;
          break;
        case 'stale':
          availability = FeedAvailability.usable;
          break;
        case 'missing':
          availability = FeedAvailability.missing;
          break;
        case 'failed':
          availability = FeedAvailability.failed;
          break;
        case 'out_of_service_range':
          availability = FeedAvailability.outOfServiceRange;
          break;
        default:
          throw const FormatException('Unknown feed status');
      }
      feeds.add(
        FeedStatus(
          feedId: id,
          sourceId: _string(row, 'source_id'),
          sourceUrl: source,
          availability: availability,
          reason: row['reason'] as String?,
        ),
      );
    }
    feeds.sort((FeedStatus a, FeedStatus b) {
      return a.feedId.compareTo(b.feedId);
    });
    return List<FeedStatus>.unmodifiable(feeds);
  }
}
