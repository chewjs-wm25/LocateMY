// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/public_transportation/public_transportation.dart';

void main() {
  final ValidLocationReference location = ValidLocationReference(
    locationId: 'sunway',
    point: const GeographicPoint(latitude: 3.0738, longitude: 101.6077),
    displayName: 'Sunway Mentari',
  );

  test('distant station coordinates cannot be represented as nearby', () async {
    final Map<String, Object?> payload = servedPayload();
    final Map<String, Object?> station =
        (payload['stations'] as List<Object?>).single as Map<String, Object?>;
    station['latitude'] = 4.0;
    final TransitLoadOutcome outcome =
        await createPublicTransportation(FakeTransitReader(payload)).load(
          TransitRequest(
            location: location,
            analysisDate: DateTime(2026, 9, 17),
            policy: TransitLoadPolicy.refresh,
          ),
        );
    expect(outcome, isA<TransitUnavailable>());
  });

  test('malformed refresh keeps the last successful result', () async {
    final Map<String, Object?> payload = servedPayload();
    final PublicTransportation transportation = createPublicTransportation(
      FakeTransitReader(payload),
    );
    final TransitRequest request = TransitRequest(
      location: location,
      analysisDate: DateTime(2026, 9, 17),
      policy: TransitLoadPolicy.refresh,
    );
    final TransitLoadOutcome first = await transportation.load(request);
    payload.remove('snapshot_id');
    expect(await transportation.load(request), same(first));
  });

  test('unavailable RPC cannot publish an unverified feed identity', () async {
    final List<Object?> feeds = usableFeeds();
    (feeds[0] as Map<String, Object?>)['feed_id'] = 'wrong-feed';
    final TransitUnavailable outcome =
        (await createPublicTransportation(
              FakeTransitReader(<String, Object?>{
                'availability_status': 'unavailable',
                'unavailable_reason': 'no_usable_feed',
                'feeds': feeds,
              }),
            ).load(
              TransitRequest(
                location: location,
                analysisDate: DateTime(2026, 9, 17),
                policy: TransitLoadPolicy.refresh,
              ),
            ))
            as TransitUnavailable;
    expect(outcome.reason, TransitUnavailableReason.sourceUnverifiable);
  });

  test(
    'sixteen unrelated feeds cannot claim the expected official snapshot',
    () async {
      final Map<String, Object?> payload = servedPayload();
      final List<Object?> wrongFeeds = usableFeeds();
      for (int i = 0; i < wrongFeeds.length; i++) {
        (wrongFeeds[i] as Map<String, Object?>)['feed_id'] = 'unrelated-$i';
      }
      payload['feeds'] = wrongFeeds;
      final TransitLoadOutcome outcome =
          await createPublicTransportation(FakeTransitReader(payload)).load(
            TransitRequest(
              location: location,
              analysisDate: DateTime(2026, 9, 17),
              policy: TransitLoadPolicy.refresh,
            ),
          );
      expect(outcome, isA<TransitUnavailable>());
    },
  );

  test('unverified provenance cannot become an available score', () async {
    final Map<String, Object?> payload = servedPayload();
    payload.remove('snapshot_id');
    final PublicTransportation transportation = createPublicTransportation(
      FakeTransitReader(payload),
    );
    final TransitLoadOutcome outcome = await transportation.load(
      TransitRequest(
        location: location,
        analysisDate: DateTime(2026, 9, 15),
        policy: TransitLoadPolicy.refresh,
      ),
    );
    expect(outcome, isA<TransitUnavailable>());
    expect(
      (outcome as TransitUnavailable).reason,
      TransitUnavailableReason.sourceUnverifiable,
    );
  });

  test(
    'canonical stations are sorted by distance without truncating the result',
    () async {
      final Map<String, Object?> payload = servedPayload();
      final List<Object?> stations = <Object?>[];
      for (int index = 34; index >= 0; index--) {
        stations.add(<String, Object?>{
          'feed_id': 'gtfs_static_ktmb',
          'stop_id': 's$index',
          'name': 'Station $index',
          'latitude': 3.0738 + (100 + index) / 111195,
          'longitude': 101.6077,
          'station_type': 'bus',
          'distance_m': 100 + index,
        });
      }
      payload['stations'] = stations;
      payload['unique_stop_count'] = 35;
      payload['nearest_distance_m'] = 100;
      final TransitLoadOutcome outcome =
          await createPublicTransportation(FakeTransitReader(payload)).load(
            TransitRequest(
              location: location,
              analysisDate: DateTime(2026, 9, 15),
              policy: TransitLoadPolicy.refresh,
            ),
          );
      final TransitSnapshot snapshot = (outcome as TransitAvailable).snapshot;
      expect(snapshot.stations.length, 35);
      expect(snapshot.stations.first.stopId, 's0');
      expect(snapshot.stations.last.stopId, 's34');
    },
  );

  test('offline refresh retains the last successful canonical facts', () async {
    final FakeTransitReader reader = FakeTransitReader(servedPayload());
    final PublicTransportation transportation = createPublicTransportation(
      reader,
    );
    final TransitRequest request = TransitRequest(
      location: location,
      analysisDate: DateTime(2026, 9, 15),
      policy: TransitLoadPolicy.refresh,
    );
    final TransitLoadOutcome first = await transportation.load(request);
    reader.offline = true;
    final TransitLoadOutcome offline = await transportation.load(request);
    expect(offline, same(first));
  });

  test('an available label cannot hide a failed expected feed', () async {
    final Map<String, Object?> payload = _incompletePayload();
    payload['availability_status'] = 'available';
    payload['service_outcome'] = 'served';
    payload['transit_score'] = 68;
    final TransitLoadOutcome outcome =
        await createPublicTransportation(FakeTransitReader(payload)).load(
          TransitRequest(
            location: location,
            analysisDate: DateTime(2026, 9, 15),
            policy: TransitLoadPolicy.refresh,
          ),
        );
    expect(outcome, isA<TransitUnavailable>());
    expect(
      (outcome as TransitUnavailable).reason,
      TransitUnavailableReason.sourceUnverifiable,
    );
  });

  test('unknown feed status cannot be treated as usable', () async {
    final Map<String, Object?> payload = servedPayload();
    payload['feeds'] = <Object?>[
      <String, Object?>{
        'feed_id': 'gtfs_static_ktmb',
        'source_id': 'official',
        'source_url': 'https://api.data.gov.my',
        'captured_at': '2026-09-17T00:00:00Z',
        'availability': 'unexpected',
      },
    ];
    final TransitLoadOutcome outcome =
        await createPublicTransportation(FakeTransitReader(payload)).load(
          TransitRequest(
            location: location,
            analysisDate: DateTime(2026, 9, 17),
            policy: TransitLoadPolicy.refresh,
          ),
        );
    expect(outcome, isA<TransitUnavailable>());
    expect(
      (outcome as TransitUnavailable).reason,
      TransitUnavailableReason.sourceUnverifiable,
    );
  });

  test(
    'RPC coordinates and radius cannot be relabelled as the requested location',
    () async {
      final Map<String, Object?> payload = servedPayload();
      payload['latitude'] = 4.0;
      payload['radius_m'] = 2000;
      final TransitLoadOutcome outcome =
          await createPublicTransportation(FakeTransitReader(payload)).load(
            TransitRequest(
              location: location,
              analysisDate: DateTime(2026, 9, 17),
              policy: TransitLoadPolicy.refresh,
            ),
          );
      expect(outcome, isA<TransitUnavailable>());
      expect(
        (outcome as TransitUnavailable).reason,
        TransitUnavailableReason.sourceUnverifiable,
      );
    },
  );

  test('available served result preserves canonical transit facts', () async {
    final FakeTransitReader reader = FakeTransitReader(servedPayload());
    final TransitLoadOutcome outcome = await createPublicTransportation(reader)
        .load(
          TransitRequest(
            location: location,
            analysisDate: DateTime(2026, 9, 15),
            policy: TransitLoadPolicy.cacheAllowed,
          ),
        );

    expect(outcome, isA<TransitAvailable>());
    final TransitSnapshot snapshot = (outcome as TransitAvailable).snapshot;
    expect(snapshot.radiusMeters, 1500);
    expect(snapshot.score!.value, 68);
    expect(snapshot.uniqueStopCount, 1);
    expect(snapshot.uniqueRouteCount, 4);
    expect(snapshot.stations.single.name, 'Mentari BRT');
  });

  test('an incomplete feed result exposes its observed score', () async {
    final Map<String, Object?> payload = _incompletePayload();
    payload['unique_route_count'] = 4;
    payload['transit_score'] = 68;
    final FakeTransitReader reader = FakeTransitReader(payload);
    final TransitLoadOutcome outcome = await createPublicTransportation(reader)
        .load(
          TransitRequest(
            location: location,
            analysisDate: DateTime(2026, 9, 15),
            policy: TransitLoadPolicy.cacheAllowed,
          ),
        );

    expect(outcome, isA<TransitIncomplete>());
    final TransitPartialSnapshot snapshot =
        (outcome as TransitIncomplete).snapshot;
    expect(snapshot.uniqueStopCount, 1);
    expect(snapshot.score?.value, 68);
    expect(
      snapshot.feeds
          .where((FeedStatus feed) {
            return feed.availability == FeedAvailability.failed;
          })
          .single
          .availability,
      FeedAvailability.failed,
    );
  });

  test('comparison preserves side facts for provenance mismatch, partial, unavailable and unscored service', () async {
    final ValidLocationReference b = ValidLocationReference(
      locationId: 'side-b',
      point: location.point,
    );
    for (final String scenario in <String>[
      'provenance',
      'partial',
      'unavailable',
      'noStops',
      'noActiveRoutes',
    ]) {
      final Map<String, Object?> side = servedPayload();
      final TransitComparisonReason reason;
      if (scenario == 'provenance') {
        side['reference_grid_version'] = 'another-grid';
        reason = TransitComparisonReason.provenanceMismatch;
      } else if (scenario == 'partial') {
        side.addAll(_incompletePayload());
        reason = TransitComparisonReason.sideIncomplete;
      } else if (scenario == 'unavailable') {
        side['availability_status'] = 'unavailable';
        side['unavailable_reason'] = 'source_unverifiable';
        reason = TransitComparisonReason.sideUnavailable;
      } else {
        side['unique_route_count'] = 0;
        side['transit_score'] = null;
        if (scenario == 'noStops') {
          side['stations'] = <Object?>[];
          side['unique_stop_count'] = 0;
          side['nearest_distance_m'] = null;
          side['service_outcome'] = 'no_stops';
        } else {
          side['service_outcome'] = 'no_active_routes';
        }
        reason = TransitComparisonReason.serviceOutcomeNotScored;
      }
      final PublicTransportation provider = createPublicTransportation(
        PerSideTransitReader(side),
      );
      final TransitComparisonOutcome outcome = await provider.compare(
        TransitComparisonRequest(
          TransitRequest(
            location: location,
            analysisDate: DateTime(2026, 9, 15),
            policy: TransitLoadPolicy.refresh,
          ),
          TransitRequest(
            location: b,
            analysisDate: DateTime(2026, 9, 15),
            policy: TransitLoadPolicy.refresh,
          ),
        ),
      );
      expect(outcome, isA<TransitIncomparable>(), reason: scenario);
      final TransitIncomparable pair = outcome as TransitIncomparable;
      expect(pair.reason, reason, reason: scenario);
      expect((pair.a as TransitAvailable).snapshot.score!.value, 68);
      if (scenario == 'noStops' || scenario == 'noActiveRoutes') {
        expect((pair.b as TransitAvailable).snapshot.score, isNull);
      }
    }
  });

  test(
    'comparison rejects served results with different analysis dates',
    () async {
      final FakeTransitReader reader = FakeTransitReader(servedPayload());
      final PublicTransportation transportation = createPublicTransportation(
        reader,
      );
      final TransitRequest a = TransitRequest(
        location: location,
        analysisDate: DateTime(2026, 9, 15),
        policy: TransitLoadPolicy.cacheAllowed,
      );
      final TransitRequest b = TransitRequest(
        location: location,
        analysisDate: DateTime(2026, 9, 16),
        policy: TransitLoadPolicy.cacheAllowed,
      );

      final TransitComparisonOutcome outcome = await transportation.compare(
        TransitComparisonRequest(a, b),
      );

      expect(outcome, isA<TransitIncomparable>());
      expect(
        (outcome as TransitIncomparable).reason,
        TransitComparisonReason.analysisDateMismatch,
      );
    },
  );
}

final class FakeTransitReader implements TransitAnalysisReader {
  final Map<String, Object?> payload;
  bool offline = false;
  FakeTransitReader(Map<String, Object?> payload) : payload = payload;

  @override
  Future<Map<String, Object?>> readTransitAnalysis(
    TransitRequest request,
  ) async {
    if (offline) {
      throw Exception('Offline');
    }
    final Map<String, Object?> response = Map<String, Object?>.from(payload);
    response.putIfAbsent('analysis_date', () {
      return '${request.analysisDate.year}-${request.analysisDate.month.toString().padLeft(2, '0')}-${request.analysisDate.day.toString().padLeft(2, '0')}';
    });
    response.putIfAbsent('latitude', () {
      return request.location.point.latitude;
    });
    response.putIfAbsent('longitude', () {
      return request.location.point.longitude;
    });
    return response;
  }
}

Map<String, Object?> servedPayload() {
  return <String, Object?>{
    'availability_status': 'available',
    'service_outcome': 'served',
    'radius_m': 1500,
    'unique_stop_count': 1,
    'nearest_distance_m': 180,
    'unique_route_count': 4,
    'transit_score': 68,
    'snapshot_id': 'snapshot-1',
    'reference_grid_version': 'grid-1',
    'generated_at': '2026-09-15T00:00:00Z',
    'feeds': usableFeeds(),
    'stations': <Object?>[
      <String, Object?>{
        'feed_id': 'gtfs_static_ktmb',
        'stop_id': 'm1',
        'name': 'Mentari BRT',
        'latitude': 3.0738 + 180 / 111195,
        'longitude': 101.6077,
        'station_type': 'bus',
        'distance_m': 180,
      },
    ],
  };
}

Map<String, Object?> _incompletePayload() {
  return <String, Object?>{
    'availability_status': 'incomplete',
    'transit_score': null,
    'radius_m': 1500,
    'unique_stop_count': 1,
    'nearest_distance_m': 180,
    'unique_route_count': 0,
    'snapshot_id': 'snapshot-1',
    'reference_grid_version': 'grid-1',
    'generated_at': '2026-09-15T00:00:00Z',
    'feeds': partialFeeds(),
    'stations': <Object?>[
      <String, Object?>{
        'feed_id': 'gtfs_static_ktmb',
        'stop_id': 'm1',
        'name': 'Mentari BRT',
        'latitude': 3.0738 + 180 / 111195,
        'longitude': 101.6077,
        'station_type': 'bus',
        'distance_m': 180,
      },
    ],
  };
}

List<Object?> usableFeeds() {
  final List<Object?> feeds = <Object?>[];
  for (int i = 0; i < 16; i++) {
    feeds.add(<String, Object?>{
      'feed_id': expectedTestFeeds[i][0],
      'source_id': expectedTestFeeds[i][0],
      'source_url': expectedTestFeeds[i][1],
      'captured_at': '2026-09-17T00:00:00Z',
      'availability': 'usable',
    });
  }
  return feeds;
}

List<Object?> partialFeeds() {
  final List<Object?> feeds = usableFeeds();
  final Map<String, Object?> failed = feeds[15] as Map<String, Object?>;
  failed['availability'] = 'failed';
  failed['reason'] = 'test failure';
  return feeds;
}

const List<List<String>> expectedTestFeeds = <List<String>>[
  <String>['gtfs_static_ktmb', 'https://api.data.gov.my/gtfs-static/ktmb'],
  <String>[
    'gtfs_static_prasarana_rapid_rail_kl',
    'https://api.data.gov.my/gtfs-static/prasarana?category=rapid-rail-kl',
  ],
  <String>[
    'gtfs_static_prasarana_rapid_bus_kl',
    'https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-kl',
  ],
  <String>[
    'gtfs_static_prasarana_rapid_bus_penang',
    'https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-penang',
  ],
  <String>[
    'gtfs_static_prasarana_rapid_bus_kuantan',
    'https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-kuantan',
  ],
  <String>[
    'gtfs_static_prasarana_rapid_bus_mrtfeeder',
    'https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-mrtfeeder',
  ],
  <String>[
    'gtfs_static_mybas_kangar',
    'https://api.data.gov.my/gtfs-static/mybas-kangar',
  ],
  <String>[
    'gtfs_static_mybas_alor_setar',
    'https://api.data.gov.my/gtfs-static/mybas-alor-setar',
  ],
  <String>[
    'gtfs_static_mybas_kota_bharu',
    'https://api.data.gov.my/gtfs-static/mybas-kota-bharu',
  ],
  <String>[
    'gtfs_static_mybas_kuala_terengganu',
    'https://api.data.gov.my/gtfs-static/mybas-kuala-terengganu',
  ],
  <String>[
    'gtfs_static_mybas_ipoh',
    'https://api.data.gov.my/gtfs-static/mybas-ipoh',
  ],
  <String>[
    'gtfs_static_mybas_seremban_a',
    'https://api.data.gov.my/gtfs-static/mybas-seremban-a',
  ],
  <String>[
    'gtfs_static_mybas_seremban_b',
    'https://api.data.gov.my/gtfs-static/mybas-seremban-b',
  ],
  <String>[
    'gtfs_static_mybas_melaka',
    'https://api.data.gov.my/gtfs-static/mybas-melaka',
  ],
  <String>[
    'gtfs_static_mybas_johor',
    'https://api.data.gov.my/gtfs-static/mybas-johor',
  ],
  <String>[
    'gtfs_static_mybas_kuching',
    'https://api.data.gov.my/gtfs-static/mybas-kuching',
  ],
];

final class PerSideTransitReader implements TransitAnalysisReader {
  final Map<String, Object?> b;
  PerSideTransitReader(Map<String, Object?> b) : b = b;
  @override
  Future<Map<String, Object?>> readTransitAnalysis(TransitRequest request) {
    final Map<String, Object?> payload = request.location.locationId == 'side-b'
        ? b
        : servedPayload();
    return FakeTransitReader(payload).readTransitAnalysis(request);
  }
}
