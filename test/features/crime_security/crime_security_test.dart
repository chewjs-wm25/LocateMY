// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/crime_security/crime_security.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const ValidLocationReference sunway = ValidLocationReference(
  locationId: 'sunway',
  point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
  displayName: 'Sunway Mentari',
);
final BoundaryProvenance provenance = BoundaryProvenance(
  datasetId: 'admin',
  sourceUri: Uri.parse('https://example.com/boundary'),
  sourceVersion: 'v1',
  sourceSha256: 'hash',
  derivedGeometrySha256: 'hash',
  importedAt: DateTime.utc(2026),
);

final class GeoFixture implements GeographicContext {
  String state = 'Selangor';
  bool offline = false;
  final Map<String, String> locationStates = <String, String>{};
  GeographicLevelOutcome? outcome;
  @override
  Future<GeographicContextOutcome> resolve(
    GeographicContextRequest request,
  ) async {
    if (offline) {
      throw Exception('Geo unavailable');
    }
    final String state =
        locationStates[request.location.locationId] ?? this.state;
    return GeographicContextAvailable(<GeographicLevel, GeographicLevelOutcome>{
      GeographicLevel.reportingState:
          outcome ??
          GeographicLevelResolved(
            AdministrativeArea(
              level: GeographicLevel.reportingState,
              stableId: state,
              name: state,
              reportingStateId: state,
              reportingStateName: state,
            ),
            provenance,
          ),
    });
  }
}

Map<String, Object?> row(
  String state,
  String category,
  int crimes, {
  int year = 2023,
  String type = 'murder',
}) {
  return <String, Object?>{
    'state': state,
    'category': category,
    'year': year,
    'type': type,
    'crimes': crimes,
  };
}

Map<String, Object?> inputs(List<Map<String, Object?>> rows) {
  return <String, Object?>{
    'version': 1,
    'dataset_id': 'crime_district',
    'source_url': 'https://storage.data.gov.my/publicsafety/crime_district.csv',
    'source_sha256':
        '800d488b426cd02f068179c626f7b4d2c5ba024f5b4b838fb0986fb7001c31be',
    'verified': true,
    'latest_complete_year': 2023,
    'rows': rows,
  };
}

final class ReaderFixture implements SafetyInputsReader {
  Map<String, Object?> payload = inputs(<Map<String, Object?>>[
    row('Selangor', 'assault', 10),
    row('Selangor', 'property', 30, type: 'break_in'),
    row('Johor', 'assault', 20),
    row('Johor', 'property', 20, type: 'break_in'),
    row('Sabah', 'assault', 30),
    row('Sabah', 'property', 10, type: 'break_in'),
  ]);
  bool offline = false;
  @override
  Future<Map<String, Object?>> readSafetyInputs() async {
    if (offline) {
      throw Exception('offline');
    }
    return payload;
  }
}

final class PendingInputs implements SafetyInputsReader {
  final List<Completer<Map<String, Object?>>> pending =
      <Completer<Map<String, Object?>>>[];
  @override
  Future<Map<String, Object?>> readSafetyInputs() {
    final Completer<Map<String, Object?>> result =
        Completer<Map<String, Object?>>();
    pending.add(result);
    return result.future;
  }
}

void main() {
  sqfliteFfiInit();
  late Database db;
  late ReaderFixture reader;
  late GeoFixture geo;
  late CrimeSecurity crime;
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    reader = ReaderFixture();
    geo = GeoFixture();
    crime = createCrimeSecurity(
      geographicContext: geo,
      reader: reader,
      database: db,
      clock: () {
        return DateTime.utc(2026, 9, 17);
      },
    );
  });
  tearDown(() async {
    await db.close();
  });
  test(
    'state safety uses 60:40 category percentiles across actual states',
    () async {
      final SafetyAnalysis result = await crime.analyse(sunway);
      // Assault rank 1/3, property rank 3/3 => risk 60, safety 40.
      expect(result.score, closeTo(40, 0.00001));
      expect(result.latestCount, 40);
      expect(result.availability, SafetyAvailability.complete);
      expect(result.reportingState, 'Selangor');
    },
  );
  test('one category normalizes its weight and marks partial without inventing total', () async {
    reader.payload = inputs(<Map<String, Object?>>[
      row('Selangor', 'assault', 0),
      row('Johor', 'assault', 10),
    ]);
    final SafetyAnalysis result = await crime.analyse(sunway);
    expect(result.score, 50);
    expect(result.availability, SafetyAvailability.partial);
    expect(result.latestCount, isNull);
  });

  test(
    'unresolved and ambiguous locations never choose a default state',
    () async {
      geo.outcome = const GeographicLevelUnresolved(
        GeographicContextFailure.noCoverage,
      );
      final SafetyAnalysis unresolved = await crime.analyse(sunway);
      expect(unresolved.score, isNull);
      expect(unresolved.failure, SafetyFailure.geographicContext);
      geo.outcome = GeographicLevelAmbiguous(
        <AdministrativeArea>[],
        provenance,
      );
      expect(
        (await crime.analyse(sunway)).availability,
        SafetyAvailability.unavailable,
      );
    },
  );

  test('unverified sources and empty latest year remain unavailable', () async {
    reader.payload['verified'] = false;
    expect(
      (await crime.analyse(sunway)).failure,
      SafetyFailure.sourceUnverifiable,
    );
    reader.payload = inputs(<Map<String, Object?>>[
      row('Selangor', 'assault', 10, year: 2022),
    ]);
    final SafetyAnalysis missing = await crime.analyse(sunway, refresh: true);
    expect(missing.availability, SafetyAvailability.unavailable);
    expect(missing.score, isNull);
    reader.payload = inputs(<Map<String, Object?>>[]);
    expect(
      (await crime.analyse(sunway, refresh: true)).failure,
      SafetyFailure.noData,
    );
  });

  test(
    'five year trends retain gaps and dynamic types, excluding national totals',
    () async {
      final List<Map<String, Object?>> rows = List<Map<String, Object?>>.from(
        reader.payload['rows'] as List,
      );
      rows.addAll(<Map<String, Object?>>[
        row('Selangor', 'assault', 5, year: 2019),
        row('Selangor', 'property', 7, year: 2019, type: 'break_in'),
        row('Malaysia', 'assault', 9999),
        row('Malaysia', 'property', 9999, type: 'break_in'),
      ]);
      reader.payload = inputs(rows);
      final SafetyAnalysis result = await crime.analyse(sunway);
      expect(result.score, closeTo(40, 0.00001));
      expect(
        result.trends['all']!.map((CrimeYearCount p) {
          return p.count;
        }).toList(),
        <int?>[12, null, null, null, 40],
      );
      expect(result.trends['type:murder']!.last.count, 10);
      geo.state = 'W.P. Labuan';
      expect((await crime.analyse(sunway)).reportingState, 'Sabah');
    },
  );

  test('malformed, negative and duplicate source rows cannot produce a safety score', () async {
    for (final Map<String, Object?> bad in <Map<String, Object?>>[
      row('Selangor', 'assault', -1),
      row('Selangor', 'assault', 10),
      <String, Object?>{'state': 'Selangor', 'category': 'assault'},
    ]) {
      final List<Map<String, Object?>> rows = List<Map<String, Object?>>.from(
        ReaderFixture().payload['rows'] as List,
      );
      rows.add(bad);
      reader.payload = inputs(rows);
      final SafetyAnalysis result = await crime.analyse(sunway, refresh: true);
      expect(result.score, isNull);
      expect(result.failure, SafetyFailure.sourceUnverifiable);
    }
  });

  test('durable public cache survives restart and offline refresh but expires after three days', () async {
    DateTime now = DateTime.utc(2026, 9, 17);
    crime = createCrimeSecurity(
      geographicContext: geo,
      reader: reader,
      database: db,
      clock: () {
        return now;
      },
    );
    expect((await crime.analyse(sunway)).score, closeTo(40, 0.00001));
    reader.offline = true;
    final CrimeSecurity restarted = createCrimeSecurity(
      geographicContext: geo,
      reader: reader,
      database: db,
      clock: () {
        return now;
      },
    );
    expect(
      (await restarted.analyse(sunway, refresh: true)).score,
      closeTo(40, 0.00001),
    );
    now = now.add(const Duration(days: 3));
    expect(
      (await restarted.analyse(sunway, refresh: true)).failure,
      SafetyFailure.sourceUnavailable,
    );
    reader.offline = false;
    expect(
      (await restarted.analyse(sunway, refresh: true)).availability,
      SafetyAvailability.complete,
    );
  });

  test('A/B returns a neutral B minus A difference only for complete matching scope', () async {
    const ValidLocationReference b = ValidLocationReference(
      locationId: 'b',
      point: GeographicPoint(latitude: 1.5, longitude: 103.7),
      displayName: 'Johor',
    );
    final SafetyComparison same = await crime.compare(sunway, b);
    expect(same.difference, 0);
    expect(same.a.score, 40);
    expect(same.b.score, 40);
    reader.payload = inputs(<Map<String, Object?>>[
      row('Selangor', 'assault', 10),
      row('Johor', 'assault', 20),
    ]);
    final SafetyComparison partial = await crime.compare(
      sunway,
      b,
      refresh: true,
    );
    expect(partial.difference, isNull);
    expect(partial.reason, SafetyComparisonReason.incomplete);
    expect(partial.a.availability, SafetyAvailability.partial);
  });

  test(
    'failed Geo lookup is an unavailable result and recovers on retry',
    () async {
      geo.offline = true;
      expect(
        (await crime.analyse(sunway)).failure,
        SafetyFailure.geographicContext,
      );
      geo.offline = false;
      expect((await crime.analyse(sunway)).score, closeTo(40, 0.00001));
    },
  );

  test('tied crime scales share the inclusive rank and all-zero counts are real data', () async {
    reader.payload = inputs(<Map<String, Object?>>[
      row('Selangor', 'assault', 10),
      row('Johor', 'assault', 10),
      row('Sabah', 'assault', 30),
      row('Selangor', 'property', 30, type: 'break_in'),
      row('Johor', 'property', 20, type: 'break_in'),
      row('Sabah', 'property', 10, type: 'break_in'),
    ]);
    expect((await crime.analyse(sunway)).score, closeTo(20, 0.00001));
    reader.payload = inputs(<Map<String, Object?>>[
      row('Selangor', 'assault', 0),
      row('Selangor', 'property', 0, type: 'break_in'),
    ]);
    final SafetyAnalysis zero = await crime.analyse(sunway, refresh: true);
    expect(zero.score, 0);
    expect(zero.latestCount, 0);
    expect(zero.availability, SafetyAvailability.complete);
  });
  test(
    'A/B preserves the successful side when the other state has no data',
    () async {
      geo.locationStates['b'] = 'Perlis';
      const ValidLocationReference b = ValidLocationReference(
        locationId: 'b',
        point: GeographicPoint(latitude: 6.4, longitude: 100.2),
      );
      final SafetyComparison result = await crime.compare(sunway, b);
      expect(result.a.score, 40);
      expect(result.b.score, isNull);
      expect(result.difference, isNull);
      expect(result.reason, SafetyComparisonReason.unavailable);
    },
  );
  test(
    'corrupt public cache is ignored and online retry restores a valid result',
    () async {
      await crime.analyse(sunway);
      await db.update('crime_public_cache', <String, Object?>{
        'payload': 'corrupt',
      });
      reader.offline = true;
      expect(
        (await crime.analyse(sunway)).failure,
        SafetyFailure.sourceUnavailable,
      );
      reader.offline = false;
      expect((await crime.analyse(sunway)).score, 40);
    },
  );
  test('an older concurrent response cannot overwrite the most recent cached input', () async {
    final PendingInputs source = PendingInputs();
    crime = createCrimeSecurity(
      geographicContext: geo,
      reader: source,
      database: db,
    );
    final Future<SafetyAnalysis> old = crime.analyse(sunway, refresh: true);
    while (source.pending.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    final Future<SafetyAnalysis> latest = crime.analyse(sunway, refresh: true);
    while (source.pending.length < 2) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    source.pending[1].complete(ReaderFixture().payload);
    expect((await latest).score, 40);
    source.pending[0].complete(
      inputs(<Map<String, Object?>>[
        row('Selangor', 'assault', 0),
        row('Selangor', 'property', 0, type: 'break_in'),
      ]),
    );
    expect((await old).score, 0);
    reader.offline = true;
    final CrimeSecurity restarted = createCrimeSecurity(
      geographicContext: geo,
      reader: reader,
      database: db,
    );
    expect((await restarted.analyse(sunway)).score, 40);
  });
  test('a cached state result remains readable when both Geo and crime sources are offline', () async {
    final SafetyAnalysis initial = await crime.analyse(sunway);
    expect(initial.score, 40);
    geo.offline = true;
    reader.offline = true;
    final CrimeSecurity restarted = createCrimeSecurity(
      geographicContext: geo,
      reader: reader,
      database: db,
      clock: () {
        return DateTime.utc(2026, 9, 17);
      },
    );
    expect((await restarted.analyse(sunway)).score, 40);
    const ValidLocationReference other = ValidLocationReference(
      locationId: 'uncached',
      point: GeographicPoint(latitude: 3.5, longitude: 101.8),
    );
    expect((await restarted.analyse(other)).score, isNull);
    geo.offline = false;
    geo.outcome = const GeographicLevelUnresolved(
      GeographicContextFailure.noCoverage,
    );
    expect((await restarted.analyse(sunway)).score, isNull);
  });
  test(
    'unexpected states and mismatched source years are unverifiable',
    () async {
      final List<Map<String, Object?>> rows = List<Map<String, Object?>>.from(
        reader.payload['rows'] as List,
      );
      rows.add(row('Invented state', 'assault', 999));
      reader.payload = inputs(rows);
      expect(
        (await crime.analyse(sunway)).failure,
        SafetyFailure.sourceUnverifiable,
      );
      reader.payload = ReaderFixture().payload;
      reader.payload['latest_complete_year'] = 2025;
      expect(
        (await crime.analyse(sunway, refresh: true)).failure,
        SafetyFailure.sourceUnverifiable,
      );
    },
  );
  test(
    'missing latest year does not discard a valid historical trend',
    () async {
      reader.payload = inputs(<Map<String, Object?>>[
        row('Selangor', 'assault', 8, year: 2022),
      ]);
      final SafetyAnalysis result = await crime.analyse(sunway);
      expect(result.score, isNull);
      expect(result.trends['assault']![3].count, 8);
      expect(result.trends['assault']!.last.count, isNull);
    },
  );
}
