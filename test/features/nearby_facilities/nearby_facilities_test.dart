


import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/nearby_facilities/nearby_facilities.dart';

void main() {
  test('complete OSM response creates ordered coverage and excludes points beyond 2km', () async {
    final NearbyFacilities facilities = createNearbyFacilities(
      source: _Source(
        OverpassFacilityComplete(
          elements: <OverpassElement>[
            OverpassElement(
              elementType: 'node',
              osmId: 'clinic',
              representativePoint: GeographicPoint(
                latitude: 3.0005,
                longitude: 101,
              ),
              tags: <String, String>{'amenity': 'clinic', 'name': 'Clinic A'},
            ),
            OverpassElement(
              elementType: 'node',
              osmId: 'pharmacy',
              representativePoint: GeographicPoint(
                latitude: 3.001,
                longitude: 101,
              ),
              tags: <String, String>{'amenity': 'pharmacy'},
            ),
            OverpassElement(
              elementType: 'node',
              osmId: 'school',
              representativePoint: GeographicPoint(
                latitude: 3.002,
                longitude: 101,
              ),
              tags: <String, String>{'amenity': 'school', 'name': 'School'},
            ),
            OverpassElement(
              elementType: 'node',
              osmId: 'outside',
              representativePoint: GeographicPoint(
                latitude: 3.03,
                longitude: 101,
              ),
              tags: <String, String>{'amenity': 'hospital'},
            ),
          ],
          queriedAt: DateTime.utc(2026, 9, 17),
        ),
      ),
    );

    final FacilityAnalysisOutcome outcome = await facilities.analyse(
      const FacilityAnalysisRequest(
        location: ValidLocationReference(
          locationId: 'sunway',
          point: GeographicPoint(latitude: 3, longitude: 101),
          displayName: 'Sunway Mentari',
        ),
        refreshPolicy: FacilityRefreshPolicy.refresh,
      ),
    );

    final FacilityAnalysis analysis =
        (outcome as FacilityAnalysisAvailable).analysis;
    expect(analysis.radiusMetres, 2000);
    expect(
      analysis.categories.map((FacilityCategoryResult item) {
        return item.category;
      }),
      FacilityCategory.values,
    );
    expect(analysis.categories[0].state, FacilityCategoryState.covered);
    expect(
      analysis.categories[0].nearest.map((NearbyFacility item) {
        return item.displayName;
      }),
      <String>['Clinic A', '未命名地点'],
    );
    expect(analysis.categories[1].state, FacilityCategoryState.covered);
    expect(analysis.categories[2].state, FacilityCategoryState.completeEmpty);
  });

  test('refresh failure falls back only to a valid complete cache', () async {
    final _QueueSource source = _QueueSource(<OverpassFacilityOutcome>[
      OverpassFacilityComplete(
        elements: const <OverpassElement>[],
        queriedAt: DateTime.utc(2026, 9, 17),
      ),
      const OverpassFacilityPartial(failure: OverpassFailure.responseTruncated),
    ]);
    final NearbyFacilities facilities = createNearbyFacilities(
      source: source,
      clock: () {
        return DateTime.utc(2026, 9, 17, 1);
      },
    );
    const FacilityAnalysisRequest request = FacilityAnalysisRequest(
      location: ValidLocationReference(
        locationId: 'sunway',
        point: GeographicPoint(latitude: 3, longitude: 101),
      ),
      refreshPolicy: FacilityRefreshPolicy.refresh,
    );

    await facilities.analyse(request);
    final FacilityAnalysisOutcome outcome = await facilities.analyse(request);

    final FacilityAnalysis analysis =
        (outcome as FacilityAnalysisAvailable).analysis;
    expect(analysis.dataState, FacilityDataState.cached);
    expect(
      analysis.categories.every((FacilityCategoryResult category) {
        return category.state == FacilityCategoryState.completeEmpty;
      }),
      isTrue,
    );
  });

  test(
    'partial response without cache is unavailable rather than empty',
    () async {
      final NearbyFacilities facilities = createNearbyFacilities(
        source: _Source(
          const OverpassFacilityPartial(
            failure: OverpassFailure.responseTruncated,
          ),
        ),
      );

      final FacilityAnalysisOutcome outcome = await facilities.analyse(
        const FacilityAnalysisRequest(
          location: ValidLocationReference(
            locationId: 'sunway',
            point: GeographicPoint(latitude: 3, longitude: 101),
          ),
          refreshPolicy: FacilityRefreshPolicy.refresh,
        ),
      );

      expect(
        (outcome as FacilityAnalysisUnavailable).failure,
        FacilityFailure.incompleteResponse,
      );
    },
  );
  test('a cached coordinate binds to the caller location without inheriting its previous name', () async {
    final NearbyFacilities facilities = createNearbyFacilities(
      source: _Source(
        OverpassFacilityComplete(
          elements: const <OverpassElement>[],
          queriedAt: DateTime.utc(2026, 9, 17),
        ),
      ),
      clock: () {
        return DateTime.utc(2026, 9, 17, 1);
      },
    );
    const GeographicPoint point = GeographicPoint(latitude: 3, longitude: 101);
    await facilities.analyse(
      const FacilityAnalysisRequest(
        location: ValidLocationReference(
          locationId: 'old',
          point: point,
          displayName: 'Private old name',
        ),
        refreshPolicy: FacilityRefreshPolicy.refresh,
      ),
    );
    const ValidLocationReference current = ValidLocationReference(
      locationId: 'new',
      point: point,
      displayName: 'Current name',
    );
    final FacilityAnalysisOutcome outcome = await facilities.analyse(
      const FacilityAnalysisRequest(
        location: current,
        refreshPolicy: FacilityRefreshPolicy.cacheAllowed,
      ),
    );
    expect(
      (outcome as FacilityAnalysisAvailable).analysis.location,
      same(current),
    );
  });

  test(
    'counts include all unique facilities while nearest is limited to three',
    () async {
      final NearbyFacilities facilities = createNearbyFacilities(
        source: _Source(
          OverpassFacilityComplete(
            elements: List<OverpassElement>.generate(5, (int index) {
              return OverpassElement(
                elementType: 'node',
                osmId: '$index',
                representativePoint: GeographicPoint(
                  latitude: 3 + index * 0.001,
                  longitude: 101,
                ),
                tags: const <String, String>{'amenity': 'clinic'},
              );
            }),
            queriedAt: DateTime.utc(2026, 9, 17),
          ),
        ),
      );
      final FacilityAnalysisOutcome outcome = await facilities.analyse(
        const FacilityAnalysisRequest(
          location: ValidLocationReference(
            locationId: 'a',
            point: GeographicPoint(latitude: 3, longitude: 101),
          ),
          refreshPolicy: FacilityRefreshPolicy.refresh,
        ),
      );
      final FacilityCategoryResult health =
          (outcome as FacilityAnalysisAvailable).analysis.categories.first;
      expect(health.count, 5);
      expect(health.nearest.length, 3);
    },
  );

  test(
    'complete public cache survives recreation and expires exactly at 24 hours',
    () async {
      sqfliteFfiInit();
      final Directory directory = await Directory.systemTemp.createTemp(
        'facility-cache',
      );
      final String path = '${directory.path}/public.db';
      Database database = await databaseFactoryFfi.openDatabase(path);
      DateTime now = DateTime.utc(2026, 9, 17, 1);
      const FacilityAnalysisRequest request = FacilityAnalysisRequest(
        location: ValidLocationReference(
          locationId: 'a',
          point: GeographicPoint(latitude: 3, longitude: 101),
          displayName: 'Private name',
        ),
        refreshPolicy: FacilityRefreshPolicy.cacheAllowed,
      );
      final NearbyFacilities first = createNearbyFacilities(
        source: _Source(
          OverpassFacilityComplete(
            elements: const <OverpassElement>[],
            queriedAt: DateTime.utc(2026, 9, 17),
          ),
        ),
        database: database,
        clock: () {
          return now;
        },
      );
      await first.analyse(request);
      await database.close();
      database = await databaseFactoryFfi.openDatabase(path);
      final NearbyFacilities second = createNearbyFacilities(
        source: const _Source(
          OverpassFacilityFailed(failure: OverpassFailure.networkUnavailable),
        ),
        database: database,
        clock: () {
          return now;
        },
      );
      final FacilityAnalysisOutcome cached = await second.analyse(request);
      expect(
        (cached as FacilityAnalysisAvailable).analysis.dataState,
        FacilityDataState.cached,
      );
      now = DateTime.utc(2026, 9, 18);
      expect(await second.analyse(request), isA<FacilityAnalysisUnavailable>());
      await database.close();
      await directory.delete(recursive: true);
    },
  );

  test('legacy cache without provenance is invalidated instead of presented as current', () async {
    sqfliteFfiInit();
    final Database database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    await database.execute(
      'CREATE TABLE facility_public_cache (coordinate_key TEXT PRIMARY KEY, payload TEXT NOT NULL)',
    );
    await database.insert('facility_public_cache', <String, Object>{
      'coordinate_key': '3.0,101.0,2000,osm-facility-v1',
      'payload': jsonEncode(<String, Object>{
        'queriedAt': '2026-09-17T00:00:00.000Z',
        'elements': <Object>[],
      }),
    });
    final NearbyFacilities facilities = createNearbyFacilities(
      source: const _Source(
        OverpassFacilityFailed(failure: OverpassFailure.networkUnavailable),
      ),
      database: database,
      clock: () {
        return DateTime.utc(2026, 9, 17, 1);
      },
    );
    final FacilityAnalysisOutcome outcome = await facilities.analyse(
      const FacilityAnalysisRequest(
        location: ValidLocationReference(
          locationId: 'a',
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
        refreshPolicy: FacilityRefreshPolicy.cacheAllowed,
      ),
    );
    expect(outcome, isA<FacilityAnalysisUnavailable>());
    await database.close();
  });

  test('a future-dated observation is not a valid fallback cache', () async {
    final _QueueSource source = _QueueSource(<OverpassFacilityOutcome>[
      OverpassFacilityComplete(
        elements: const <OverpassElement>[],
        queriedAt: DateTime.utc(2026, 9, 18),
      ),
      const OverpassFacilityFailed(failure: OverpassFailure.networkUnavailable),
    ]);
    final NearbyFacilities facilities = createNearbyFacilities(
      source: source,
      clock: () {
        return DateTime.utc(2026, 9, 17);
      },
    );
    const FacilityAnalysisRequest request = FacilityAnalysisRequest(
      location: ValidLocationReference(
        locationId: 'a',
        point: GeographicPoint(latitude: 3, longitude: 101),
      ),
      refreshPolicy: FacilityRefreshPolicy.refresh,
    );
    await facilities.analyse(request);
    expect(
      await facilities.analyse(request),
      isA<FacilityAnalysisUnavailable>(),
    );
  });

  test(
    'late older refresh cannot overwrite the latest observation in the cache',
    () async {
      final _ConcurrentSource source = _ConcurrentSource();
      final NearbyFacilities facilities = createNearbyFacilities(
        source: source,
      );
      const FacilityAnalysisRequest request = FacilityAnalysisRequest(
        location: ValidLocationReference(
          locationId: 'a',
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
        refreshPolicy: FacilityRefreshPolicy.refresh,
      );
      final Future<FacilityAnalysisOutcome> old = facilities.analyse(request);
      await Future<void>.delayed(Duration.zero);
      final Future<FacilityAnalysisOutcome> latest = facilities.analyse(
        request,
      );
      await Future<void>.delayed(Duration.zero);
      source.responses[1].complete(
        OverpassFacilityComplete(
          elements: const <OverpassElement>[
            OverpassElement(
              elementType: 'node',
              osmId: 'new',
              representativePoint: GeographicPoint(latitude: 3, longitude: 101),
              tags: <String, String>{'amenity': 'clinic'},
            ),
          ],
          queriedAt: DateTime.now(),
        ),
      );
      await latest;
      source.responses[0].complete(
        OverpassFacilityComplete(
          elements: const <OverpassElement>[],
          queriedAt: DateTime.now(),
        ),
      );
      await old;
      final FacilityAnalysisOutcome cached = await facilities.analyse(
        FacilityAnalysisRequest(
          location: request.location,
          refreshPolicy: FacilityRefreshPolicy.cacheAllowed,
        ),
      );
      expect(
        (cached as FacilityAnalysisAvailable).analysis.categories.first.count,
        1,
      );
    },
  );
  test('OSM identity deduplication and overlapping tags obey product category priority', () async {
    final List<OverpassElement> elements = <OverpassElement>[
      const OverpassElement(
        elementType: 'node',
        osmId: '1',
        representativePoint: GeographicPoint(latitude: 3, longitude: 101),
        tags: <String, String>{
          'amenity': 'pharmacy',
          'shop': 'supermarket',
          'leisure': 'park',
        },
      ),
      const OverpassElement(
        elementType: 'way',
        osmId: '1',
        representativePoint: GeographicPoint(latitude: 3, longitude: 101),
        tags: <String, String>{
          'amenity': 'school',
          'public_transport': 'platform',
        },
      ),
      const OverpassElement(
        elementType: 'relation',
        osmId: '1',
        representativePoint: GeographicPoint(latitude: 3, longitude: 101),
        tags: <String, String>{'highway': 'bus_stop', 'shop': 'convenience'},
      ),
    ];
    elements.add(elements.first);
    final NearbyFacilities facilities = createNearbyFacilities(
      source: _Source(
        OverpassFacilityComplete(elements: elements, queriedAt: DateTime.now()),
      ),
    );
    final FacilityAnalysisAvailable outcome = await facilities.analyse(
      const FacilityAnalysisRequest(
        location: ValidLocationReference(
          locationId: 'a',
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
        refreshPolicy: FacilityRefreshPolicy.refresh,
      ),
    ) as FacilityAnalysisAvailable;
    expect(
      outcome.analysis.categories.map((FacilityCategoryResult item) {
        return item.count;
      }),
      <int>[1, 1, 0, 1, 0],
    );
  });
  test('circle filtering excludes bounding-box corners and retains near-radius facilities', () async {
    final NearbyFacilities facilities = createNearbyFacilities(
      source: _Source(
        OverpassFacilityComplete(
          elements: const <OverpassElement>[
            OverpassElement(
              elementType: 'node',
              osmId: 'inside',
              representativePoint: GeographicPoint(
                latitude: 0,
                longitude: 0.01798,
              ),
              tags: <String, String>{'amenity': 'clinic'},
            ),
            OverpassElement(
              elementType: 'node',
              osmId: 'outside',
              representativePoint: GeographicPoint(
                latitude: 0,
                longitude: 0.018,
              ),
              tags: <String, String>{'amenity': 'clinic'},
            ),
            OverpassElement(
              elementType: 'node',
              osmId: 'corner',
              representativePoint: GeographicPoint(
                latitude: 0.014,
                longitude: 0.014,
              ),
              tags: <String, String>{'amenity': 'clinic'},
            ),
          ],
          queriedAt: DateTime.now(),
        ),
      ),
    );
    final FacilityAnalysisAvailable outcome = await facilities.analyse(
      const FacilityAnalysisRequest(
        location: ValidLocationReference(
          locationId: 'a',
          point: GeographicPoint(latitude: 0, longitude: 0),
        ),
        refreshPolicy: FacilityRefreshPolicy.refresh,
      ),
    ) as FacilityAnalysisAvailable;
    expect(outcome.analysis.categories.first.count, 1);
    expect(
      outcome.analysis.categories.first.nearest.single.stableId,
      'node_inside',
    );
    expect(
      outcome.analysis.categories.first.nearest.single.distanceMetres,
      closeTo(1999.3, 0.2),
    );
  });
  test('comparison preserves A/B order and reports a missing B without replacing its result', () async {
    final NearbyFacilities facilities = createNearbyFacilities(
      source: _QueueSource(<OverpassFacilityOutcome>[
        OverpassFacilityComplete(
          elements: const <OverpassElement>[],
          queriedAt: DateTime.now(),
        ),
        const OverpassFacilityPartial(
          failure: OverpassFailure.responseTruncated,
        ),
      ]),
    );
    const ValidLocationReference a = ValidLocationReference(
      locationId: 'a',
      point: GeographicPoint(latitude: 3, longitude: 101),
    );
    const ValidLocationReference b = ValidLocationReference(
      locationId: 'b',
      point: GeographicPoint(latitude: 4, longitude: 101),
    );
    final FacilityComparisonNotComparable result = await facilities.compare(
      const FacilityComparisonRequest(
        locationA: a,
        locationB: b,
        refreshPolicy: FacilityRefreshPolicy.refresh,
      ),
    ) as FacilityComparisonNotComparable;
    expect(
      (result.locationA as FacilityAnalysisAvailable).analysis.location,
      same(a),
    );
    expect(
      (result.locationB as FacilityAnalysisUnavailable).failure,
      FacilityFailure.incompleteResponse,
    );
    expect(result.failure, FacilityComparisonFailure.locationBUnavailable);
    expect(
      (await facilities.compare(
        const FacilityComparisonRequest(
          locationA: a,
          locationB: a,
          refreshPolicy: FacilityRefreshPolicy.refresh,
        ),
      ) as FacilityComparisonUnavailable).failure,
      FacilityFailure.sameComparisonPoint,
    );
  });
  test('analysis emits a sanitized diagnostic without the location name or coordinates', () async {
    final List<String> events = <String>[];
    await runZoned<Future<void>>(
      () async {
        final NearbyFacilities facilities = createNearbyFacilities(
          source: _Source(
            OverpassFacilityComplete(
              elements: const <OverpassElement>[],
              queriedAt: DateTime.now(),
            ),
          ),
        );
        await facilities.analyse(
          const FacilityAnalysisRequest(
            location: ValidLocationReference(
              locationId: 'private-id',
              point: GeographicPoint(latitude: 3.0738, longitude: 101.6072),
              displayName: 'Private favorite name',
            ),
            refreshPolicy: FacilityRefreshPolicy.refresh,
          ),
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          events.add(line);
        },
      ),
    );
    expect(events.length, 1);
    final Map<String, dynamic> event =
        jsonDecode(events.single) as Map<String, dynamic>;
    expect(event['event'], 'facility.analyse.completed');
    expect(event['result'], 'fresh');
    expect(event.keys.toSet(), <String>{
      'event',
      'feature',
      'result',
      'duration_bucket',
      'correlation_id',
    });
    expect(events.single, isNot(contains('Private favorite name')));
    expect(events.single, isNot(contains('3.0738')));
    expect(events.single, isNot(contains('private-id')));
  });
}

final class _Source implements OverpassFacilitySource {
  final OverpassFacilityOutcome outcome;
  const _Source(OverpassFacilityOutcome outcome) : outcome = outcome;

  @override
  Future<OverpassFacilityOutcome> query(OverpassFacilityQuery query) async {
    return outcome;
  }
}

final class _QueueSource implements OverpassFacilitySource {
  final List<OverpassFacilityOutcome> outcomes;
  _QueueSource(List<OverpassFacilityOutcome> outcomes) : outcomes = outcomes;

  @override
  Future<OverpassFacilityOutcome> query(OverpassFacilityQuery query) async {
    return outcomes.removeAt(0);
  }
}

final class _ConcurrentSource implements OverpassFacilitySource {
  final List<Completer<OverpassFacilityOutcome>> responses =
      <Completer<OverpassFacilityOutcome>>[];
  @override
  Future<OverpassFacilityOutcome> query(OverpassFacilityQuery query) {
    final Completer<OverpassFacilityOutcome> response =
        Completer<OverpassFacilityOutcome>();
    responses.add(response);
    return response.future;
  }
}
