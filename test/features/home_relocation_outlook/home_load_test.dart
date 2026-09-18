import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:locatemy/features/home_relocation_outlook/home_relocation_outlook.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const datasetIds = [
  'cpi_headline_inflation',
  'lfs_month_sa',
  'economic_indicators',
  'gdp_qtr_real_sa',
  'hh_income',
];
Map<String, dynamic> emptyData() => {
  'version': 1,
  'datasets': <String, dynamic>{
    for (final id in datasetIds) id: <Map<String, dynamic>>[],
  },
};
Map<String, dynamic> fullData() {
  final payload = emptyData();
  payload['datasets']['cpi_headline_inflation'] = [
    for (var i = 0; i < 36; i++)
      for (final division in ['overall', '01', '04', '07'])
        {
          'date': DateTime.utc(2022, 1 + i).toIso8601String().substring(0, 10),
          'division': division,
          'inflation_yoy': 36 - i,
          'inflation_mom': 0,
        },
  ];
  payload['datasets']['lfs_month_sa'] = [
    for (var i = 0; i < 48; i++)
      {
        'date': DateTime.utc(2021, 1 + i).toIso8601String().substring(0, 10),
        'u_rate': 48 - i,
        'lf_employed': 100 + i,
        'p_rate': 60 + i / 10,
      },
  ];
  payload['datasets']['economic_indicators'] = [
    for (var i = 0; i < 48; i++)
      {
        'date': DateTime.utc(2021, 1 + i).toIso8601String().substring(0, 10),
        'leading': 100 + i,
        'leading_diffusion': 75,
      },
  ];
  payload['datasets']['gdp_qtr_real_sa'] = [
    for (var i = 0; i < 16; i++)
      {
        'date': DateTime.utc(
          2021,
          1 + i * 3,
        ).toIso8601String().substring(0, 10),
        'series': 'growth_qoq',
        'value': i + 1,
      },
  ];
  payload['datasets']['hh_income'] = [
    {'date': '2024-01-01', 'income_median': 7017},
  ];
  return payload;
}

void main() {
  setUpAll(sqfliteFfiInit);
  test(
    'no imported observations and no cache give a typed unavailable result',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/rest/v1/rpc/read_home_metrics');
          return http.Response(
            jsonEncode(emptyData()),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final home = createHomeRelocationOutlook(
        client,
        openCache: () async => db,
      );
      final result = await home.load(HomeLoadRequest.cacheAllowed);
      expect(
        result,
        isA<HomeUnavailable>().having(
          (r) => r.reason,
          'reason',
          HomeUnavailableReason.noCachedResult,
        ),
      );
    },
  );
  test(
    'income alone remains available without inventing macro scores',
    () async {
      final payload = emptyData();
      payload['datasets']['hh_income'] = [
        {'date': '2024-01-01', 'income_median': 7017},
      ];
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode(payload),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      addTearDown(client.dispose);
      final result = await createHomeRelocationOutlook(
        client,
        openCache: () async => db,
      ).load(HomeLoadRequest.cacheAllowed);
      expect(result, isA<HomeLoaded>());
      final snapshot = (result as HomeLoaded).snapshot;
      expect(snapshot.completeness, HomeCompleteness.partial);
      expect(snapshot.householdMedianIncome.medianIncome, 7017);
      expect(snapshot.householdMedianIncome.surveyYear, 2024);
      expect(snapshot.householdMedianIncome.currencyUnit, 'RM/month');
      expect(snapshot.relocationTiming.score, isNull);
      expect(
        snapshot.costPressure.unavailableReason,
        MetricUnavailableReason.sourceMissing,
      );
    },
  );

  test('cost pressure ranks 36 falling monthly observations and retains source date', () async {
    final payload = emptyData();
    payload['datasets']['cpi_headline_inflation'] = [
      for (var i = 0; i < 36; i++)
        for (final division in ['overall', '01', '04', '07'])
          {
            'date': DateTime.utc(
              2022,
              1 + i,
            ).toIso8601String().substring(0, 10),
            'division': division,
            'inflation_yoy': 36 - i,
            'inflation_mom': 0,
          },
    ];
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (request) async =>
            http.Response(jsonEncode(payload), 200, request: request),
      ),
    );
    addTearDown(client.dispose);
    final result = await createHomeRelocationOutlook(
      client,
      openCache: () async => db,
    ).load(HomeLoadRequest.cacheAllowed);
    expect(result, isA<HomeLoaded>());
    final snapshot = (result as HomeLoaded).snapshot;
    
    expect(snapshot.costPressure.score, 78);
    expect(snapshot.costPressure.source.observedAt, DateTime.utc(2024, 12));
    expect(snapshot.costPressure.directionExplanation, 'cost.easing');
    expect(snapshot.householdMedianIncome.medianIncome, isNull);
    expect(snapshot.relocationTiming.score, isNull);
  });

  test('employment uses unemployment, annual growth and participation with their design weights', () async {
    final payload = emptyData();
    payload['datasets']['lfs_month_sa'] = [
      for (var i = 0; i < 48; i++)
        {
          'date': DateTime.utc(2021, 1 + i).toIso8601String().substring(0, 10),
          'u_rate': 48 - i,
          'lf_employed': 100 + i,
          'p_rate': 60 + i / 10,
        },
    ];
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (r) async => http.Response(jsonEncode(payload), 200, request: r),
      ),
    );
    addTearDown(client.dispose);
    final result = await createHomeRelocationOutlook(
      client,
      openCache: () async => db,
    ).load(HomeLoadRequest.cacheAllowed);
    final snapshot = (result as HomeLoaded).snapshot;
    
    
    expect(snapshot.employmentStability.score, 65);
    expect(
      snapshot.employmentStability.source.observedAt,
      DateTime.utc(2024, 12),
    );
    expect(
      snapshot.employmentStability.directionExplanation,
      'employment.stable',
    );
  });

  test('economic momentum uses diffusion directly and GDP growth rather than absolute GDP', () async {
    final payload = emptyData();
    payload['datasets']['economic_indicators'] = [
      for (var i = 0; i < 48; i++)
        {
          'date': DateTime.utc(2021, 1 + i).toIso8601String().substring(0, 10),
          'leading': 100 + i,
          'leading_diffusion': 75,
        },
    ];
    payload['datasets']['gdp_qtr_real_sa'] = [
      for (var i = 0; i < 16; i++)
        for (final series in ['growth_qoq', 'abs'])
          {
            'date': DateTime.utc(
              2021,
              1 + i * 3,
            ).toIso8601String().substring(0, 10),
            'series': series,
            'value': series == 'abs' ? 999999 - i : i + 1,
          },
    ];
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (r) async => http.Response(jsonEncode(payload), 200, request: r),
      ),
    );
    addTearDown(client.dispose);
    final snapshot = ((await createHomeRelocationOutlook(
      client,
      openCache: () async => db,
    ).load(HomeLoadRequest.cacheAllowed)) as HomeLoaded).snapshot;
    
    expect(snapshot.economicMomentum.score, 61);
    expect(snapshot.economicMomentum.directionExplanation, 'economy.expanding');
    expect(snapshot.economicMomentum.source.observedAt, DateTime.utc(2024, 12));
  });

  test('complete timing combines three scores, ranks reasons and retains quarterly sources', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (r) async => http.Response(jsonEncode(fullData()), 200, request: r),
      ),
    );
    addTearDown(client.dispose);
    final snapshot = ((await createHomeRelocationOutlook(
      client,
      openCache: () async => db,
    ).load(HomeLoadRequest.cacheAllowed)) as HomeLoaded).snapshot;
    expect(snapshot.relocationTiming.score, 69);
    expect(snapshot.relocationTiming.status, 'timing.wait');
    expect(snapshot.completeness, HomeCompleteness.complete);
    expect(snapshot.relocationTiming.reasons.map((r) => r.source.datasetId), [
      'cpi_headline_inflation',
      'lfs_month_sa',
      'economic_indicators',
    ]);
    expect(
      snapshot.relocationTiming.sources
          .singleWhere((s) => s.datasetId == 'gdp_qtr_real_sa')
          .observedAt,
      DateTime.utc(2024, 10),
    );
  });

  test('a changed CPI schema disables cost and timing while preserving other cards', () async {
    final payload = fullData();
    for (final row in payload['datasets']['cpi_headline_inflation']) {
      row.remove('inflation_yoy');
    }
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (r) async => http.Response(jsonEncode(payload), 200, request: r),
      ),
    );
    addTearDown(client.dispose);
    final result = await createHomeRelocationOutlook(
      client,
      openCache: () async => db,
    ).load(HomeLoadRequest.refresh);
    expect(result, isA<HomeLoaded>());
    final snapshot = (result as HomeLoaded).snapshot;
    expect(
      snapshot.costPressure.unavailableReason,
      MetricUnavailableReason.sourceSchemaChanged,
    );
    expect(snapshot.relocationTiming.score, isNull);
    expect(snapshot.employmentStability.score, 65);
    expect(snapshot.householdMedianIncome.medianIncome, 7017);
  });

  test('successful refresh cools for exactly 60 seconds with ceiling remaining seconds', () async {
    var now = DateTime.utc(2026, 9, 17);
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (r) async => http.Response(jsonEncode(fullData()), 200, request: r),
      ),
    );
    addTearDown(client.dispose);
    final home = createHomeRelocationOutlook(
      client,
      openCache: () async => db,
      clock: () => now,
    );
    expect(await home.load(HomeLoadRequest.refresh), isA<HomeLoaded>());
    now = now.add(const Duration(milliseconds: 18500));
    expect(
      await home.load(HomeLoadRequest.refresh),
      isA<HomeRefreshCoolingDown>().having(
        (r) => r.remainingSeconds,
        'remaining',
        42,
      ),
    );
    now = now.add(const Duration(milliseconds: 41500));
    expect(await home.load(HomeLoadRequest.refresh), isA<HomeLoaded>());
  });

  test('persisted public snapshot survives service restart and offline expiry without restoring cooldown', () async {
    var now = DateTime.utc(2026, 9, 17);
    var offline = false;
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (r) async => offline
            ? http.Response('{"code":"offline"}', 503, request: r)
            : http.Response(jsonEncode(fullData()), 200, request: r),
      ),
    );
    addTearDown(client.dispose);
    final home = createHomeRelocationOutlook(
      client,
      openCache: () async => db,
      clock: () => now,
    );
    final first = await home.load(HomeLoadRequest.refresh) as HomeLoaded;
    offline = true;
    now = now.add(const Duration(days: 2));
    final restarted = createHomeRelocationOutlook(
      client,
      openCache: () async => db,
      clock: () => now,
    );
    final recovered = await restarted.load(HomeLoadRequest.refresh);
    expect(recovered, isA<HomeLoaded>());
    final snapshot = (recovered as HomeLoaded).snapshot;
    expect(snapshot.freshness, HomeDataFreshness.stale);
    expect(snapshot.fetchedAt, first.snapshot.fetchedAt);
    expect(snapshot.relocationTiming.score, 69);
    offline = false;
    expect(
      await restarted.load(HomeLoadRequest.refresh),
      isA<HomeLoaded>().having(
        (r) => r.snapshot.freshness,
        'freshness',
        HomeDataFreshness.fresh,
      ),
    );
  });

  test('simultaneous refreshes share one external read and both receive the result', () async {
    final response = Completer<http.Response>();
    final started = Completer<void>();
    var requested = false;
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((r) async {
        if (requested) {
          return http.Response('{"code":"duplicate"}', 503, request: r);
        }
        requested = true;
        started.complete();
        final result = await response.future;
        return http.Response(result.body, result.statusCode, request: r);
      }),
    );
    addTearDown(client.dispose);
    final home = createHomeRelocationOutlook(client, openCache: () async => db);
    final first = home.load(HomeLoadRequest.refresh);
    await started.future;
    final second = home.load(HomeLoadRequest.refresh);
    response.complete(http.Response(jsonEncode(fullData()), 200));
    final results = await Future.wait([first, second]);
    expect(results, everyElement(isA<HomeLoaded>()));
    expect(
      (results[0] as HomeLoaded).snapshot.fetchedAt,
      (results[1] as HomeLoaded).snapshot.fetchedAt,
    );
  });

  test(
    'older online source dates do not replace a newer public snapshot',
    () async {
      var now = DateTime.utc(2026, 9, 17);
      var payload = fullData();
      var offline = false;
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        httpClient: MockClient(
          (r) async => offline
              ? http.Response('{}', 503, request: r)
              : http.Response(jsonEncode(payload), 200, request: r),
        ),
      );
      addTearDown(client.dispose);
      final home = createHomeRelocationOutlook(
        client,
        openCache: () async => db,
        clock: () => now,
      );
      await home.load(HomeLoadRequest.cacheAllowed);
      payload = fullData();
      payload['datasets']['hh_income'] = [
        {'date': '2022-01-01', 'income_median': 6000},
      ];
      now = now.add(const Duration(minutes: 1));
      final result = await home.load(HomeLoadRequest.refresh) as HomeLoaded;
      expect(result.snapshot.householdMedianIncome.medianIncome, 7017);
      expect(result.snapshot.freshness, HomeDataFreshness.cached);
      offline = true;
      final restarted = createHomeRelocationOutlook(
        client,
        openCache: () async => db,
        clock: () => now,
      );
      expect(
        (await restarted.load(
          HomeLoadRequest.cacheAllowed,
        ) as HomeLoaded).snapshot.householdMedianIncome.medianIncome,
        7017,
      );
    },
  );

  test('unverifiable observations are classified and a corrected refresh is immediately retryable', () async {
    var payload = fullData();
    payload['datasets']['cpi_headline_inflation'].last['date'] = '2024-02-31';
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (r) async => http.Response(jsonEncode(payload), 200, request: r),
      ),
    );
    addTearDown(client.dispose);
    final home = createHomeRelocationOutlook(client, openCache: () async => db);
    final first = await home.load(HomeLoadRequest.refresh) as HomeLoaded;
    expect(
      first.snapshot.costPressure.unavailableReason,
      MetricUnavailableReason.sourceDataUnverifiable,
    );
    payload = fullData();
    expect(
      await home.load(HomeLoadRequest.refresh),
      isA<HomeLoaded>().having(
        (r) => r.snapshot.relocationTiming.score,
        'timing',
        69,
      ),
    );
  });

  test('CPI category weight at 60 percent is usable while 55 percent remains unknown', () async {
    for (final divisions in [
      ['overall', '01'],
      ['overall', '07'],
    ]) {
      final payload = fullData();
      payload['datasets']['cpi_headline_inflation'] =
          (payload['datasets']['cpi_headline_inflation'] as List)
              .where((r) => divisions.contains(r['division']))
              .toList();
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        httpClient: MockClient(
          (r) async => http.Response(jsonEncode(payload), 200, request: r),
        ),
      );
      try {
        final snapshot = ((await createHomeRelocationOutlook(
          client,
          openCache: () async => db,
        ).load(HomeLoadRequest.cacheAllowed)) as HomeLoaded).snapshot;
        expect(snapshot.costPressure.score, divisions.last == '01' ? 78 : null);
        expect(
          snapshot.relocationTiming.score,
          divisions.last == '01' ? 69 : null,
        );
      } finally {
        await db.close();
        await client.dispose();
      }
    }
  });
  test('insufficient monthly history cannot be replaced by zeros and income does not affect timing', () async {
    final payload = fullData();
    payload['datasets']['lfs_month_sa'] =
        (payload['datasets']['lfs_month_sa'] as List).take(23).toList();
    payload['datasets']['hh_income'] = [];
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (r) async => http.Response(jsonEncode(payload), 200, request: r),
      ),
    );
    addTearDown(client.dispose);
    final snapshot = ((await createHomeRelocationOutlook(
      client,
      openCache: () async => db,
    ).load(HomeLoadRequest.cacheAllowed)) as HomeLoaded).snapshot;
    expect(
      snapshot.employmentStability.unavailableReason,
      MetricUnavailableReason.insufficientHistory,
    );
    expect(snapshot.relocationTiming.score, isNull);
    expect(snapshot.costPressure.score, 78);
    expect(snapshot.householdMedianIncome.medianIncome, isNull);
  });
  for (final code in ['503', 'schema']) {
    test(
      'no cache maps $code external failure into a typed public outcome',
      () async {
        final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
        addTearDown(db.close);
        final client = SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          httpClient: MockClient(
            (r) async => http.Response(
              code == 'schema'
                  ? '{"version":2,"datasets":{}}'
                  : '{"code":"offline"}',
              code == 'schema' ? 200 : 503,
              request: r,
            ),
          ),
        );
        addTearDown(client.dispose);
        expect(
          await createHomeRelocationOutlook(
            client,
            openCache: () async => db,
          ).load(HomeLoadRequest.refresh),
          isA<HomeUnavailable>().having(
            (r) => r.reason,
            'reason',
            code == 'schema'
                ? HomeUnavailableReason.sourceSchemaChanged
                : HomeUnavailableReason.retryableUnavailable,
          ),
        );
      },
    );
  }
  test('late response from an older provider cannot overwrite a newer durable public cache', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final oldClient = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((r) async {
        started.complete();
        final response = await pending.future;
        return http.Response(response.body, response.statusCode, request: r);
      }),
    );
    addTearDown(oldClient.dispose);
    final newClient = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (r) async => http.Response(jsonEncode(fullData()), 200, request: r),
      ),
    );
    addTearDown(newClient.dispose);
    final oldHome = createHomeRelocationOutlook(
      oldClient,
      openCache: () async => db,
    );
    final oldLoad = oldHome.load(HomeLoadRequest.cacheAllowed);
    await started.future;
    await createHomeRelocationOutlook(
      newClient,
      openCache: () async => db,
    ).load(HomeLoadRequest.cacheAllowed);
    final older = fullData();
    older['datasets']['hh_income'] = [
      {'date': '2022-01-01', 'income_median': 6000},
    ];
    pending.complete(http.Response(jsonEncode(older), 200));
    await oldLoad;
    final offline = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((r) async => http.Response('{}', 503, request: r)),
    );
    addTearDown(offline.dispose);
    final recovered = await createHomeRelocationOutlook(
      offline,
      openCache: () async => db,
    ).load(HomeLoadRequest.cacheAllowed) as HomeLoaded;
    expect(recovered.snapshot.householdMedianIncome.medianIncome, 7017);
  });
  test('current economy uses each dataset latest date when GDP is newer than monthly indicators', () async {
    final payload = fullData();
    payload['datasets']['gdp_qtr_real_sa'].add({
      'date': '2025-01-01',
      'series': 'growth_qoq',
      'value': 0,
    });
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (r) async => http.Response(jsonEncode(payload), 200, request: r),
      ),
    );
    addTearDown(client.dispose);
    final snapshot = ((await createHomeRelocationOutlook(
      client,
      openCache: () async => db,
    ).load(HomeLoadRequest.cacheAllowed)) as HomeLoaded).snapshot;
    
    expect(snapshot.economicMomentum.score, 32);
    expect(snapshot.economicMomentum.source.observedAt, DateTime.utc(2024, 12));
    expect(
      snapshot.relocationTiming.sources
          .singleWhere((s) => s.datasetId == 'gdp_qtr_real_sa')
          .observedAt,
      DateTime.utc(2025, 1),
    );
  });
  test('corrupted cached scores are rejected instead of displayed as verified statistics', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (r) async => http.Response(jsonEncode(fullData()), 200, request: r),
      ),
    );
    addTearDown(client.dispose);
    await createHomeRelocationOutlook(
      client,
      openCache: () async => db,
    ).load(HomeLoadRequest.cacheAllowed);
    
    final row = (await db.query('home_public_cache')).single;
    final corrupt = jsonDecode(row['result_payload'] as String) as Map;
    corrupt['costPressure']['score'] = 300;
    await db.update(
      'home_public_cache',
      {'result_payload': jsonEncode(corrupt)},
      where: 'cache_key = ?',
      whereArgs: ['national'],
    );
    final offline = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((r) async => http.Response('{}', 503, request: r)),
    );
    addTearDown(offline.dispose);
    expect(
      await createHomeRelocationOutlook(
        offline,
        openCache: () async => db,
      ).load(HomeLoadRequest.cacheAllowed),
      isA<HomeUnavailable>().having(
        (r) => r.reason,
        'reason',
        HomeUnavailableReason.retryableUnavailable,
      ),
    );
  });
  test('HOME-001 diagnostic events classify outcomes and never include source payload or credentials', () async {
    final events = <String>[];
    await runZoned(
      () async {
        final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
        addTearDown(db.close);
        var response = jsonEncode(fullData());
        var status = 200;
        final client = SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          httpClient: MockClient(
            (r) async => http.Response(response, status, request: r),
          ),
        );
        addTearDown(client.dispose);
        final home = createHomeRelocationOutlook(
          client,
          openCache: () async => db,
        );
        await home.load(HomeLoadRequest.refresh);
        await home.load(HomeLoadRequest.refresh);
        status = 503;
        response = '{"password":"sensitive-password","email":"private@example.com","token":"private-token","coordinates":"1.23,4.56"}';
        await home.load(HomeLoadRequest.cacheAllowed);
        final emptyDb = await databaseFactoryFfi.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false),
        );
        addTearDown(emptyDb.close);
        await createHomeRelocationOutlook(
          client,
          openCache: () async => emptyDb,
        ).load(HomeLoadRequest.cacheAllowed);
        status = 200;
        response = '{"version":2,"datasets":{}}';
        await createHomeRelocationOutlook(
          client,
          openCache: () async => emptyDb,
        ).load(HomeLoadRequest.cacheAllowed);
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          events.add(line);
        },
      ),
    );
    final diagnostics = events
        .where((e) => e.contains('home.load.completed'))
        .map((e) => jsonDecode(e) as Map)
        .toList();
    expect(diagnostics.map((e) => e['result']), [
      'fresh',
      'cooldown',
      'cached',
      'retryableUnavailable',
      'sourceSchemaChanged',
    ]);
    for (final event in diagnostics) {
      expect(event.keys.toSet(), {
        'event',
        'feature',
        'result',
        'duration_bucket',
        'correlation_id',
      });
      expect(event['feature'], 'home_relocation_outlook');
      expect(
        event['duration_bucket'],
        isIn(['under100ms', 'under1s', 'under10s', '10sOrMore']),
      );
      expect(event['correlation_id'], matches(r'^home-[0-9]+$'));
    }
    for (final forbidden in [
      'sensitive-password',
      'private@example.com',
      'private-token',
      '1.23,4.56',
      'password',
      'email',
      'token',
      'coordinates',
    ]) {
      expect(diagnostics.toString(), isNot(contains(forbidden)));
    }
  });
  test('temporary SQLite initialization failure can recover and persist a later public result', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    var opens = 0;
    var offline = false;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (r) async => http.Response(
          offline ? '{}' : jsonEncode(fullData()),
          offline ? 503 : 200,
          request: r,
        ),
      ),
    );
    addTearDown(client.dispose);
    final home = createHomeRelocationOutlook(
      client,
      openCache: () async {
        if (++opens == 1) throw StateError('temporary storage unavailable');
        return db;
      },
    );
    await home.load(HomeLoadRequest.cacheAllowed);
    final recovered = await home.load(HomeLoadRequest.refresh) as HomeLoaded;
    expect(recovered.snapshot.freshness, HomeDataFreshness.fresh);
    expect(opens, greaterThanOrEqualTo(2));
    offline = true;
    final restarted = await createHomeRelocationOutlook(
      client,
      openCache: () async => db,
    ).load(HomeLoadRequest.cacheAllowed);
    expect(restarted, isA<HomeLoaded>());
    expect(
      (restarted as HomeLoaded).snapshot.freshness,
      HomeDataFreshness.cached,
    );
  });
  for (final frequency in ['monthly', 'quarterly']) {
    test(
      '$frequency percentile falls back to older valid history when the five-year window is short',
      () async {
        final payload = fullData();
        if (frequency == 'monthly') {
          final records = payload['datasets']['cpi_headline_inflation'] as List;
          for (var i = 0; i < 36; i++) {
            final date =
                (i < 13
                        ? DateTime.utc(2010, 1 + i)
                        : DateTime.utc(2023, 1 + i - 13))
                    .toIso8601String()
                    .substring(0, 10);
            for (var j = 0; j < 4; j++) {
              records[i * 4 + j]['date'] = date;
            }
          }
        } else {
          final records = payload['datasets']['gdp_qtr_real_sa'] as List;
          for (var i = 0; i < 16; i++) {
            records[i]['date'] =
                (i < 10
                        ? DateTime.utc(2010, 1 + i * 3)
                        : DateTime.utc(2023, 1 + (i - 10) * 3))
                    .toIso8601String()
                    .substring(0, 10);
          }
        }
        final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
        addTearDown(db.close);
        final client = SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          httpClient: MockClient(
            (r) async => http.Response(jsonEncode(payload), 200, request: r),
          ),
        );
        addTearDown(client.dispose);
        final snapshot = (await createHomeRelocationOutlook(
          client,
          openCache: () async => db,
        ).load(HomeLoadRequest.cacheAllowed) as HomeLoaded).snapshot;
        expect(
          frequency == 'monthly'
              ? snapshot.costPressure.score
              : snapshot.economicMomentum.score,
          frequency == 'monthly' ? 78 : 61,
        );
      },
    );
  }
  for (final schemaChanged in [true, false]) {
    test(
      'invalid supplemental GDP ${schemaChanged ? "schema" : "data"} is partial and cannot start refresh cooldown',
      () async {
        var payload = fullData();
        if (schemaChanged) {
          payload['datasets']['gdp_qtr_real_sa'][0].remove('value');
        } else {
          payload['datasets']['gdp_qtr_real_sa'][0]['date'] = '2099-01-01';
        }
        final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
        addTearDown(db.close);
        var reads = 0;
        final client = SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          httpClient: MockClient((r) async {
            reads++;
            return http.Response(jsonEncode(payload), 200, request: r);
          }),
        );
        addTearDown(client.dispose);
        final home = createHomeRelocationOutlook(
          client,
          openCache: () async => db,
        );
        final broken = await home.load(HomeLoadRequest.refresh) as HomeLoaded;
        expect(broken.snapshot.completeness, HomeCompleteness.partial);
        expect(
          broken.snapshot.economicMomentum.unavailableReason,
          schemaChanged
              ? MetricUnavailableReason.sourceSchemaChanged
              : MetricUnavailableReason.sourceDataUnverifiable,
        );
        expect(broken.snapshot.costPressure.score, 78);
        expect(await db.query('home_public_cache'), isEmpty);
        payload = fullData();
        payload['datasets']['gdp_qtr_real_sa'] = <Map<String, dynamic>>[];
        final fixed = await home.load(HomeLoadRequest.refresh);
        expect(fixed, isA<HomeLoaded>());
        expect(reads, 2);
        expect((fixed as HomeLoaded).snapshot.economicMomentum.score, 44);
        expect(
          await home.load(HomeLoadRequest.refresh),
          isA<HomeRefreshCoolingDown>(),
        );
      },
    );
  }
  test('available cards with an unknown observation date in corrupted SQLite are rejected', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    var offline = false;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (r) async => http.Response(
          offline ? '{}' : jsonEncode(fullData()),
          offline ? 503 : 200,
          request: r,
        ),
      ),
    );
    addTearDown(client.dispose);
    await createHomeRelocationOutlook(
      client,
      openCache: () async => db,
    ).load(HomeLoadRequest.cacheAllowed);
    final row = (await db.query('home_public_cache')).single;
    final corrupt = jsonDecode(row['result_payload'] as String) as Map;
    corrupt['costPressure']['source']['observedAt'] =
        '1970-01-01T00:00:00.000Z';
    await db.update(
      'home_public_cache',
      {'result_payload': jsonEncode(corrupt)},
      where: 'cache_key = ?',
      whereArgs: ['national'],
    );
    offline = true;
    expect(
      await createHomeRelocationOutlook(
        client,
        openCache: () async => db,
      ).load(HomeLoadRequest.cacheAllowed),
      isA<HomeUnavailable>(),
    );
  });
}
