// Explicit constructor parameters follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/infrastructure_coverage/infrastructure_coverage.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/public_transportation/public_transportation.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';
import 'package:locatemy/l10n/app_localizations.dart';

const ValidLocationReference location = ValidLocationReference(
  locationId: 'test',
  point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
);

final class GeoFixture implements GeographicContext {
  GeographicLevelOutcome? district;
  bool offline = false;
  @override
  Future<GeographicContextOutcome> resolve(
    GeographicContextRequest request,
  ) async {
    if (offline) {
      return const GeographicContextUnavailable(
        GeographicContextFailure.sourceUnavailable,
      );
    }
    final BoundaryProvenance source = BoundaryProvenance(
      datasetId: 'admin',
      sourceUri: Uri.parse('https://example.com/admin'),
      sourceVersion: 'v1',
      sourceSha256: 'hash',
      derivedGeometrySha256: 'hash',
      importedAt: DateTime.utc(2026),
    );
    return GeographicContextAvailable(<GeographicLevel, GeographicLevelOutcome>{
      GeographicLevel.reportingState: GeographicLevelResolved(
        const AdministrativeArea(
          level: GeographicLevel.reportingState,
          stableId: 'Selangor',
          name: 'Selangor',
          reportingStateId: 'Selangor',
          reportingStateName: 'Selangor',
        ),
        source,
      ),
      GeographicLevel.district:
          district ??
          GeographicLevelResolved(
            const AdministrativeArea(
              level: GeographicLevel.district,
              stableId: 'petaling',
              name: 'Petaling',
              reportingStateId: 'Selangor',
              reportingStateName: 'Selangor',
            ),
            source,
          ),
    });
  }
}

final class Inputs implements InfrastructureInputsReader {
  bool offline = false;
  final Map<String, Object?> payload = <String, Object?>{
    'amenities': <Object?>[
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2024-01-01',
        'piped_water': 100,
        'electricity': 0,
      },
    ],
    'beds': <Object?>[
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2024-01-01',
        'type': 'public',
        'beds': 10,
      },
      <String, Object?>{
        'state': 'Other',
        'district': 'Else',
        'date': '2024-01-01',
        'type': 'public',
        'beds': 30,
      },
    ],
    'population': <Object?>[
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2023-01-01',
        'sex': 'both',
        'age': 'overall',
        'ethnicity': 'overall',
        'population': 10,
      },
      <String, Object?>{
        'state': 'Other',
        'district': 'Else',
        'date': '2024-01-01',
        'sex': 'both',
        'age': 'overall',
        'ethnicity': 'overall',
        'population': 10,
      },
    ],
    'schools': <Object?>[],
    'teachers': <Object?>[],
    'enrolment': <Object?>[],
  };
  @override
  Future<Map<String, Object?>> read(String state, String district) async {
    if (offline) {
      throw StateError('offline');
    }
    return payload;
  }
}

final class Transit implements PublicTransportation {
  TransitRequest? last;
  TransitLoadOutcome? result;
  @override
  Future<TransitLoadOutcome> load(TransitRequest request) async {
    last = request;
    if (result != null) {
      return result!;
    }
    return const TransitUnavailable(
      TransitUnavailableReason.noUsableFeed,
      <FeedStatus>[],
    );
  }

  @override
  Future<TransitComparisonOutcome> compare(TransitComparisonRequest request) {
    throw UnimplementedError();
  }
}

final class Weights implements InfrastructureWeightsStore {
  bool failed = false;
  bool readFailed = false;
  int saves = 0;
  InfrastructureWeightSettings saved = const InfrastructureWeightSettings();
  @override
  Future<InfrastructureWeightSettings> read() async {
    if (readFailed) {
      throw StateError('offline');
    }
    return saved;
  }

  @override
  Future<void> save(InfrastructureWeightSettings weights) async {
    saves++;
    if (failed) {
      throw StateError('offline');
    }
    saved = weights;
  }
}

InfrastructureService service(
  GeoFixture geo,
  Inputs reader,
  Transit transit,
  Weights weights,
) {
  return InfrastructureService(
    geo: geo,
    reader: reader,
    transportation: transit,
    weightsStore: weights,
  );
}

final class PendingInputs implements InfrastructureInputsReader {
  final List<Completer<Map<String, Object?>>> pending =
      <Completer<Map<String, Object?>>>[];
  @override
  Future<Map<String, Object?>> read(String state, String district) {
    final Completer<Map<String, Object?>> call =
        Completer<Map<String, Object?>>();
    pending.add(call);
    return call.future;
  }
}

final class MemoryCache implements InfrastructurePublicCache {
  final Map<String, Map<String, Object?>> saved =
      <String, Map<String, Object?>>{};
  int writes = 0;
  @override
  Future<Map<String, Object?>?> read(String key) async {
    return saved[key];
  }

  @override
  Future<void> write(String key, Map<String, Object?> payload) async {
    writes++;
    saved[key] = payload;
  }
}

final class DelayedCache implements InfrastructurePublicCache {
  final String blockedKey;
  DelayedCache([String blockedKey = 'Selangor:Petaling'])
    : blockedKey = blockedKey;
  final Map<String, Map<String, Object?>> values =
      <String, Map<String, Object?>>{};
  final Completer<void> started = Completer<void>();
  final Completer<void> release = Completer<void>();
  bool delayed = false;
  @override
  Future<Map<String, Object?>?> read(String key) async {
    return values[key];
  }

  @override
  Future<void> write(String key, Map<String, Object?> payload) async {
    if (key == blockedKey && !delayed) {
      delayed = true;
      started.complete();
      await release.future;
    }
    values[key] = payload;
  }
}

void main() {
  test(
    'ICI consumes and labels the canonical partial transportation score',
    () async {
      final Transit transit = Transit();
      transit.result = TransitIncomplete(
        TransitPartialSnapshot(
          location: location,
          analysisDate: DateTime(2026, 9, 18),
          radiusMeters: 1500,
          stations: const <TransitStation>[],
          uniqueStopCount: 49,
          nearestDistanceMeters: 192,
          uniqueRouteCount: 24,
          feeds: const <FeedStatus>[],
          provenance: TransitProvenance(
            snapshotId: 'partial',
            referenceGridVersion: 'grid',
            generatedAt: DateTime.utc(2026, 9, 18),
          ),
          score: const TransitScore(87),
          distanceOnly: true,
        ),
      );
      final InfrastructureService api = service(
        GeoFixture(),
        Inputs(),
        transit,
        Weights(),
      );
      final InfrastructureAvailable result = await api.fetch(
        location,
        DateTime(2026, 9, 18),
      ) as InfrastructureAvailable;
      expect(result.snapshot.categories.last.score, 87);
      // Fixture observes water 100, power 0, healthcare 50; education is missing.
    expect(result.snapshot.score, 59);
      expect(result.snapshot.transitPartial, isTrue);
      expect(result.snapshot.transitDistanceOnly, isTrue);
    },
  );
  test('education reference percentiles use each target input year and reject entire invalid newest aggregate', () async {
    final Inputs inputs = Inputs();
    inputs.payload['schools'] = <Object?>[
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2025-06-30',
        'stage': 'primary',
        'type': 'public',
        'schools': 10,
      },
      <String, Object?>{
        'state': 'Other',
        'district': 'Else',
        'date': '2025-06-30',
        'stage': 'primary',
        'type': 'public',
        'schools': 30,
      },
    ];
    inputs.payload['teachers'] = <Object?>[
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2022-01-01',
        'sex': 'both',
        'teachers': 10,
      },
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2024-01-01',
        'sex': 'both',
        'teachers': 999,
      },
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2024-01-01',
        'sex': 'both',
        'teachers': null,
      },
      <String, Object?>{
        'state': 'Other',
        'district': 'Else',
        'date': '2022-01-01',
        'sex': 'both',
        'teachers': 30,
      },
      <String, Object?>{
        'state': 'Other',
        'district': 'Else',
        'date': '2024-01-01',
        'sex': 'both',
        'teachers': 0,
      },
    ];
    inputs.payload['enrolment'] = <Object?>[
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2023-01-01',
        'sex': 'both',
        'students': 100,
      },
      <String, Object?>{
        'state': 'Other',
        'district': 'Else',
        'date': '2023-01-01',
        'sex': 'both',
        'students': 100,
      },
    ];
    final InfrastructureAvailable result = await service(
      GeoFixture(),
      inputs,
      Transit(),
      Weights(),
    ).fetch(location, DateTime(2026)) as InfrastructureAvailable;
    expect(result.snapshot.categories[3].score, 50);
    expect(result.snapshot.sourceYears['teachers'], 2022);
    expect(result.snapshot.sourceYears['enrolment'], 2023);
    expect(result.snapshot.sourceYears['schools'], 2025);
    expect(result.snapshot.populationYears['education'], 2023);
  });

  testWidgets(
    'single and A/B show necessary population-year difference without query metadata',
    (WidgetTester tester) async {
      final InfrastructureService api = service(
        GeoFixture(),
        Inputs(),
        Transit(),
        Weights(),
      );
      for (final bool compare in <bool>[false, true]) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: InfrastructureCoveragePage(
              service: api,
              location: location,
              locationB: compare ? location : null,
              analysisDate: DateTime(2026),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Healthcare uses population 2023'),
          findsWidgets,
        );
        expect(find.textContaining('Statistics: 2024'), findsWidgets);
        expect(find.textContaining('TTL'), findsNothing);
        expect(find.textContaining('Queried'), findsNothing);
      }
    },
  );

  test('actual component and population years survive weight preview and A/B evaluation', () async {
    final InfrastructureService api = service(
      GeoFixture(),
      Inputs(),
      Transit(),
      Weights(),
    );
    final InfrastructureViewModel model = InfrastructureViewModel(
      service: api,
      location: location,
      analysisDate: DateTime(2026),
    );
    await model.readWeights();
    await model.load();
    final InfrastructureCoverage initial =
        (model.outcome as InfrastructureAvailable).snapshot;
    expect(initial.sourceYears['health'], 2024);
    expect(initial.populationYears['health'], 2023);
    await model.updateWeights(health: 1);
    expect(
      (model.outcome as InfrastructureAvailable)
          .snapshot
          .populationYears['health'],
      2023,
    );
    final List<InfrastructureLoadOutcome> comparison = await api.compare(
      location,
      location,
      DateTime(2026),
    );
    expect(
      (comparison.last as InfrastructureAvailable)
          .snapshot
          .sourceYears['health'],
      2024,
    );
    model.dispose();
  });

  test('in-flight older cache writes finish before the newer write for shared coordinate or district key', () async {
    for (final String blockedKey in <String>[
      'Selangor:Petaling',
      'coordinate:3.0738:101.6077',
    ]) {
      for (final bool sameCoordinate in <bool>[true, false]) {
        final PendingInputs reader = PendingInputs();
        final DelayedCache cache = DelayedCache(blockedKey);
        final InfrastructureService api = InfrastructureService(
          geo: GeoFixture(),
          reader: reader,
          transportation: Transit(),
          weightsStore: Weights(),
          cache: cache,
        );
        final Map<String, Object?> old = <String, Object?>{
          ...Inputs().payload,
          'tag': 'old',
        };
        final Map<String, Object?> newer = <String, Object?>{
          ...Inputs().payload,
          'tag': 'new',
        };
        final Future<InfrastructureLoadOutcome> first = api.fetch(
          location,
          DateTime(2026),
          policy: InfrastructureLoadPolicy.refresh,
        );
        await Future<void>.delayed(Duration.zero);
        reader.pending[0].complete(old);
        await cache.started.future;
        final ValidLocationReference secondLocation = sameCoordinate
            ? location
            : const ValidLocationReference(
                locationId: 'second',
                point: GeographicPoint(latitude: 3.074, longitude: 101.608),
              );
        final Future<InfrastructureLoadOutcome> second = api.fetch(
          secondLocation,
          DateTime(2026),
          policy: InfrastructureLoadPolicy.refresh,
        );
        await Future<void>.delayed(Duration.zero);
        reader.pending[1].complete(newer);
        await Future<void>.delayed(Duration.zero);
        cache.release.complete();
        await Future.wait(<Future<InfrastructureLoadOutcome>>[first, second]);
        expect((await cache.read('Selangor:Petaling'))!['tag'], 'new');
        final String coordinate =
            'coordinate:${secondLocation.point.latitude}:${secondLocation.point.longitude}';
        expect(
          ((await cache.read(coordinate))!['inputs'] as Map)['tag'],
          'new',
        );
      }
    }
  });

  test('invalid latest hospital aggregate falls back as a whole and preserves zero observation', () async {
    final Inputs inputs = Inputs();
    final List<Object?> beds = List<Object?>.from(
      inputs.payload['beds'] as List,
    );
    beds.addAll(<Object?>[
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2025-01-01',
        'type': 'public',
        'beds': 999,
      },
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2025-01-01',
        'type': 'private',
        'beds': null,
      },
    ]);
    inputs.payload['beds'] = beds;
    final InfrastructureAvailable result = await service(
      GeoFixture(),
      inputs,
      Transit(),
      Weights(),
    ).fetch(location, DateTime(2026)) as InfrastructureAvailable;
    expect(result.snapshot.categories[2].score, 50);
    (beds.first as Map<String, Object?>)['beds'] = 0;
    final InfrastructureAvailable zero = await service(
      GeoFixture(),
      inputs,
      Transit(),
      Weights(),
    ).fetch(location, DateTime(2026)) as InfrastructureAvailable;
    expect(zero.snapshot.categories[2].score, 50);
  });

  test('education combines latest valid schools and both-sex resources from their own years', () async {
    final Inputs inputs = Inputs();
    inputs.payload['schools'] = <Object?>[
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2025-06-30',
        'stage': 'primary',
        'type': 'public',
        'schools': 10,
      },
    ];
    inputs.payload['teachers'] = <Object?>[
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2022-01-01',
        'stage': 'primary',
        'sex': 'both',
        'teachers': 10,
      },
    ];
    inputs.payload['enrolment'] = <Object?>[
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2023-01-01',
        'stage': 'primary',
        'sex': 'both',
        'students': 100,
      },
    ];
    final InfrastructureAvailable result = await service(
      GeoFixture(),
      inputs,
      Transit(),
      Weights(),
    ).fetch(location, DateTime(2026)) as InfrastructureAvailable;
    expect(result.snapshot.categories[3].score, 100);
  });

  test('amenities choose latest valid percentage independently without turning malformed input into zero', () async {
    final Inputs inputs = Inputs();
    inputs.payload['amenities'] = <Object?>[
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2024-01-01',
        'piped_water': 100,
        'electricity': 0,
      },
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2025-01-01',
        'piped_water': null,
        'electricity': 101,
      },
    ];
    final InfrastructureAvailable result = await service(
      GeoFixture(),
      inputs,
      Transit(),
      Weights(),
    ).fetch(location, DateTime(2026)) as InfrastructureAvailable;
    expect(result.snapshot.categories[0].score, 100);
    expect(result.snapshot.categories[1].score, 0);
  });

  test(
    'older public response cannot overwrite cache after a newer refresh',
    () async {
      final PendingInputs inputs = PendingInputs();
      final MemoryCache cache = MemoryCache();
      final InfrastructureService api = InfrastructureService(
        geo: GeoFixture(),
        reader: inputs,
        transportation: Transit(),
        weightsStore: Weights(),
        cache: cache,
      );
      final Future<InfrastructureLoadOutcome> first = api.fetch(
        location,
        DateTime(2026),
        policy: InfrastructureLoadPolicy.refresh,
      );
      await Future<void>.delayed(Duration.zero);
      final Future<InfrastructureLoadOutcome> second = api.fetch(
        location,
        DateTime(2026),
        policy: InfrastructureLoadPolicy.refresh,
      );
      await Future<void>.delayed(Duration.zero);
      inputs.pending[1].complete(Inputs().payload);
      await second;
      final int writes = cache.writes;
      inputs.pending[0].complete(<String, Object?>{});
      await first;
      expect(cache.writes, writes);
    },
  );

  test('SQLite public cache expires after three days and survives offline only before expiry', () async {
    sqfliteFfiInit();
    final Database database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    DateTime now = DateTime.utc(2026);
    final Inputs reader = Inputs();
    final GeoFixture geo = GeoFixture();
    final InfrastructureService api = createInfrastructureCoverage(
      geographicContext: geo,
      reader: reader,
      transportation: Transit(),
      weightsStore: Weights(),
      database: database,
      clock: () {
        return now;
      },
    );
    expect(
      await api.fetch(location, DateTime(2026)),
      isA<InfrastructureAvailable>(),
    );
    reader.offline = true;
    geo.offline = true;
    now = now.add(const Duration(days: 2));
    expect(
      await api.fetch(location, DateTime(2026)),
      isA<InfrastructureAvailable>(),
    );
    now = now.add(const Duration(days: 1));
    final InfrastructurePartial expired =
        await api.fetch(location, DateTime(2026)) as InfrastructurePartial;
    expect(expired.snapshot.score, isNull);
    await database.close();
  });
  test('education aggregates both-sex resources and valid zero beds remains a percentile observation', () async {
    final Inputs reader = Inputs();
    reader.payload['schools'] = <Object?>[
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2024-01-01',
        'stage': 'primary',
        'type': 'public',
        'schools': 10,
      },
    ];
    reader.payload['teachers'] = <Object?>[
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2024-01-01',
        'stage': 'primary',
        'sex': 'both',
        'teachers': 5,
      },
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2024-01-01',
        'stage': 'primary',
        'sex': 'female',
        'teachers': 999,
      },
    ];
    reader.payload['enrolment'] = <Object?>[
      <String, Object?>{
        'state': 'Selangor',
        'district': 'Petaling',
        'date': '2024-01-01',
        'stage': 'primary',
        'sex': 'both',
        'students': 100,
      },
    ];
    final InfrastructureAvailable result = await service(
      GeoFixture(),
      reader,
      Transit(),
      Weights(),
    ).fetch(location, DateTime(2026)) as InfrastructureAvailable;
    expect(result.snapshot.categories[3].score, 100);
    expect(result.snapshot.score, 63);
  });

  test('late results after location change and disposal never replace current observations', () async {
    final PendingInputs reader = PendingInputs();
    final InfrastructureViewModel model = InfrastructureViewModel(
      service: service(GeoFixture(), Inputs(), Transit(), Weights()),
      location: location,
      analysisDate: DateTime(2026),
    );
    model.dispose();
    await model.load();
    expect(model.outcome, isNull);
    final InfrastructureViewModel pending = InfrastructureViewModel(
      service: InfrastructureService(
        geo: GeoFixture(),
        reader: reader,
        transportation: Transit(),
        weightsStore: Weights(),
      ),
      location: location,
      analysisDate: DateTime(2026),
    );
    final Future<void> first = pending.load();
    await Future<void>.delayed(Duration.zero);
    final Future<void> second = pending.changeLocation(
      location,
      DateTime(2027),
    );
    await Future<void>.delayed(Duration.zero);
    final Inputs payload = Inputs();
    reader.pending[1].complete(payload.payload);
    await second;
    reader.pending[0].complete(<String, Object?>{});
    await first;
    expect(
      (pending.outcome as InfrastructureAvailable).snapshot.analysisDate,
      DateTime(2027),
    );
    pending.dispose();
  });
  test('weights read failure disables preview and can be retried', () async {
    final Weights store = Weights();
    store.readFailed = true;
    final InfrastructureViewModel model = InfrastructureViewModel(
      service: service(GeoFixture(), Inputs(), Transit(), store),
      location: location,
      analysisDate: DateTime(2026),
    );
    await model.readWeights();
    await model.updateWeights(health: 10);
    expect(model.weights.health, 5);
    expect(model.weightsFailed, isTrue);
    store.readFailed = false;
    await model.readWeights();
    expect(model.weightsLoaded, isTrue);
    model.dispose();
  });

  test('failed refresh uses cache without extending its expiry', () async {
    final Inputs reader = Inputs();
    final MemoryCache cache = MemoryCache();
    final InfrastructureService api = InfrastructureService(
      geo: GeoFixture(),
      reader: reader,
      transportation: Transit(),
      weightsStore: Weights(),
      cache: cache,
    );
    await api.fetch(
      location,
      DateTime(2026),
      policy: InfrastructureLoadPolicy.refresh,
    );
    final int writes = cache.writes;
    reader.offline = true;
    expect(
      await api.fetch(
        location,
        DateTime(2026),
        policy: InfrastructureLoadPolicy.refresh,
      ),
      isA<InfrastructureAvailable>(),
    );
    expect(cache.writes, writes);
  });

  test('resolved district raw statistics use same-year national percentile and canonical transit scope', () async {
    final Inputs inputs = Inputs();
    final Transit transit = Transit();
    final InfrastructureService api = service(
      GeoFixture(),
      inputs,
      transit,
      Weights(),
    );
    final InfrastructureAvailable result = await api.fetch(
      location,
      DateTime(2026, 9, 17),
    ) as InfrastructureAvailable;
    expect(result.snapshot.score, 50);
    expect(result.snapshot.categories[2].score, 50);
    expect(result.snapshot.categories.last.score, isNull);
    expect(transit.last!.location, location);
    expect(transit.last!.analysisDate, DateTime(2026, 9, 17));
    final List<InfrastructureLoadOutcome> both = await api.compare(
      location,
      location,
      DateTime(2026),
    );
    expect((both.first as InfrastructureAvailable).snapshot.weights.health, 5);
    expect(
      ((await api.summary(
        location,
        DateTime(2026),
      )) as InfrastructureAvailable).snapshot.weights.health,
      5,
    );
  });
  test('ambiguous district never chooses a candidate or substitutes state observations', () async {
    final GeoFixture geo = GeoFixture();
    geo.district = const GeographicLevelUnresolved(
      GeographicContextFailure.noCoverage,
    );
    final InfrastructurePartial result = await service(
      geo,
      Inputs(),
      Transit(),
      Weights(),
    ).fetch(location, DateTime(2026)) as InfrastructurePartial;
    expect(result.snapshot.score, isNull);
    expect(result.snapshot.categories.first.score, isNull);
  });
  test('population older than two years makes health missing and aggregate unavailable', () async {
    final Inputs reader = Inputs();
    reader.payload['population'] = <Object?>[];
    final InfrastructurePartial result = await service(
      GeoFixture(),
      reader,
      Transit(),
      Weights(),
    ).fetch(location, DateTime(2026)) as InfrastructurePartial;
    expect(result.snapshot.categories[2].score, isNull);
    expect(result.snapshot.score, isNull);
  });
  test('preview changes aggregate without fetching or saving until explicit action; failed save can recover', () async {
    final Weights store = Weights();
    final InfrastructureViewModel model = InfrastructureViewModel(
      service: service(GeoFixture(), Inputs(), Transit(), store),
      location: location,
      analysisDate: DateTime(2026),
    );
    await model.readWeights();
    await model.load();
    await model.updateWeights(health: 10);
    expect(model.preview, isTrue);
    expect(store.saves, 0);
    expect((model.outcome as InfrastructureAvailable).snapshot.score, 50);
    store.failed = true;
    await model.saveWeights();
    expect(model.preview, isTrue);
    expect(model.saveFailed, isTrue);
    store.failed = false;
    await model.saveWeights();
    expect(model.preview, isFalse);
    expect(store.saved.health, 10);
    await model.updateWeights(health: 1);
    model.restoreWeights();
    expect(model.weights.health, 10);
    model.dispose();
  });
  testWidgets(
    'page shows raw components and save failure; comparison has neutral priorities',
    (WidgetTester tester) async {
      final Weights weights = Weights();
      final InfrastructureService api = service(
        GeoFixture(),
        Inputs(),
        Transit(),
        weights,
      );
      Widget page({bool compare = false, double scale = 1}) {
        return MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: InfrastructureCoveragePage(
              service: api,
              location: location,
              locationB: compare ? location : null,
              analysisDate: DateTime(2026),
            ),
          ),
        );
      }

      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(find.text('50 / 100'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
      expect(find.textContaining('Analysis date'), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('Healthcare')),
        300,
      );
      await tester.drag(
        find.byKey(const ValueKey<String>('Healthcare')),
        const Offset(100, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unsaved preview'), findsOneWidget);
      weights.failed = true;
      await tester.scrollUntilVisible(find.text('Save priorities'), 300);
      await tester.tap(find.text('Save priorities'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Save failed.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(page(compare: true, scale: 2));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
