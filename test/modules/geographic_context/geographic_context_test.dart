import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> row({String id = 'b1', String state = 'Selangor'}) => {
  'boundary_id': id,
  'district': 'Petaling',
  'state': state,
  'source_dataset': 'dosm',
  'source_url': 'https://example.com/boundaries',
  'source_version': 'v1',
  'source_sha256': 'source-hash',
  'geometry_transform': 'make-valid',
  'derived_geometry_sha256': 'geometry-hash',
  'imported_at': '2026-09-14T08:00:00Z',
};

const location = ValidLocationReference(
  locationId: 'valid-map-fixture',
  point: GeographicPoint(latitude: 3.1, longitude: 101.6),
  displayName: 'Private name never sent',
);
GeographicContextRequest request([Set<GeographicLevel>? levels]) =>
    GeographicContextRequest(
      location: location,
      levels: levels ?? GeographicLevel.values.toSet(),
    );

void main() {
  late SupabaseClient client;
  late GeographicContext geo;
  late Future<http.Response> Function(http.Request) respond;
  late List<http.Request> calls;
  http.Response json(Object data, [int status = 200]) => http.Response(
    jsonEncode(data),
    status,
    headers: {'content-type': 'application/json'},
  );
  Future<void> seed({bool confirmed = true, bool anonymous = false}) async {
    await client.auth.setInitialSession(
      jsonEncode({
        'access_token': 'test-token',
        'refresh_token': 'test-refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': 'account-a',
          'aud': 'authenticated',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'created_at': '2026-09-01T00:00:00Z',
          if (confirmed) 'email_confirmed_at': '2026-09-01T00:00:00Z',
          'is_anonymous': anonymous,
        },
      }),
    );
  }

  setUp(() {
    calls = [];
    respond = (_) async => json([row()]);
    client = SupabaseClient(
      'https://geo.example.com',
      'sb_publishable_test',
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
      httpClient: MockClient((r) {
        calls.add(r);
        if (r.url.path.contains('/auth/')) {
          return Future.value(json(<String, dynamic>{}));
        }
        return respond(r).then(
          (response) => http.Response.bytes(
            response.bodyBytes,
            response.statusCode,
            headers: response.headers,
            request: r,
          ),
        );
      }),
    );
    geo = createGeographicContext(client);
  });
  tearDown(() => client.dispose());

  test('confirmed authenticated RPC resolves only requested levels with immutable results', () async {
    await seed();
    final levels = {GeographicLevel.district};
    final result =
        await geo.resolve(request(levels)) as GeographicContextAvailable;
    expect(result.results.keys, levels);
    final call = calls.single;
    expect(
      call.url.path,
      '/rest/v1/rpc/read_administrative_boundary_candidates',
    );
    expect(call.method, 'POST');
    expect(jsonDecode(call.body), {'latitude': 3.1, 'longitude': 101.6});
    expect(call.headers['Authorization'], 'Bearer test-token');
    expect(() => result.results.clear(), throwsUnsupportedError);
    final district =
        result.results[GeographicLevel.district] as GeographicLevelResolved;
    expect(district.area.stableId, 'b1');
    expect(district.provenance.importedAt.isUtc, isTrue);
  });
  test('missing, unconfirmed and anonymous sessions never read RPC', () async {
    for (final setup in [
      () async {},
      () => seed(confirmed: false),
      () => seed(anonymous: true),
    ]) {
      await setup();
      final result =
          await geo.resolve(request()) as GeographicContextUnavailable;
      expect(result.failure, GeographicContextFailure.scopeUnavailable);
    }
    expect(calls, isEmpty);
  });
  test(
    'empty mutated levels are a programming error and do not read source',
    () async {
      await seed();
      final levels = {GeographicLevel.district};
      final input = request(levels);
      levels.clear();
      await expectLater(geo.resolve(input), throwsArgumentError);
      expect(calls, isEmpty);
    },
  );

  test('zero coverage is an independent unresolved result for every requested level', () async {
    await seed();
    respond = (_) async => json([]);
    final result = await geo.resolve(request()) as GeographicContextAvailable;
    expect(result.results.keys.toSet(), GeographicLevel.values.toSet());
    for (final value in result.results.values) {
      expect(
        (value as GeographicLevelUnresolved).failure,
        GeographicContextFailure.noCoverage,
      );
      expect(value.provenance, isNull); // RPC zero rows carries no provenance.
    }
  });
  test(
    'boundary candidates sort by stable ID and reporting states deduplicate',
    () async {
      await seed();
      respond = (_) async =>
          json([row(id: 'c', state: 'Johor'), row(id: 'b'), row(id: 'a')]);
      final result = await geo.resolve(request()) as GeographicContextAvailable;
      final district =
          result.results[GeographicLevel.district] as GeographicLevelAmbiguous;
      final state =
          result.results[GeographicLevel.reportingState]
              as GeographicLevelAmbiguous;
      expect(district.candidates.map((c) => c.stableId), ['a', 'b', 'c']);
      expect(state.candidates.map((c) => c.stableId), ['Selangor', 'Johor']);
      expect(() => district.candidates.clear(), throwsUnsupportedError);
      expect(() => state.candidates.clear(), throwsUnsupportedError);
    },
  );
  test('same-state district overlap retains partial success', () async {
    await seed();
    respond = (_) async => json([row(id: 'b'), row(id: 'a')]);
    final result = await geo.resolve(request()) as GeographicContextAvailable;
    expect(
      result.results[GeographicLevel.district],
      isA<GeographicLevelAmbiguous>(),
    );
    expect(
      result.results[GeographicLevel.reportingState],
      isA<GeographicLevelResolved>(),
    );
  });
  test(
    'every candidate and all provenance fields must be trustworthy',
    () async {
      await seed();
      for (final field in row().keys) {
        for (final invalid in [null, '', 42]) {
          final bad = row(id: 'b')..[field] = invalid;
          respond = (_) async => json([row(), bad]);
          final result =
              await geo.resolve(request()) as GeographicContextUnavailable;
          expect(
            result.failure,
            GeographicContextFailure.versionUnverifiable,
            reason: field,
          );
        }
      }
      for (final field in [
        'source_version',
        'source_dataset',
        'geometry_transform',
        'derived_geometry_sha256',
        'source_sha256',
        'source_url',
        'imported_at',
      ]) {
        respond = (_) async =>
            json([row(), row(id: 'b')..[field] = 'different']);
        expect(
          (await geo.resolve(
            request(),
          ) as GeographicContextUnavailable).failure,
          GeographicContextFailure.versionUnverifiable,
        );
      }
      for (final bad in [
        row()..['source_url'] = '/relative',
        row()..['imported_at'] = '2026-09-14T08:00:00',
        row()..['imported_at'] = 'invalid',
        row()..['imported_at'] = '2026-02-30T08:00:00Z',
        row()..['imported_at'] = '2026-09-14T24:00:00Z',
      ]) {
        respond = (_) async => json([bad]);
        expect(
          (await geo.resolve(
            request(),
          ) as GeographicContextUnavailable).failure,
          GeographicContextFailure.versionUnverifiable,
        );
      }
    },
  );
  test('permission, source, malformed response and recovery remain distinguishable', () async {
    await seed();
    for (final code in ['42501', 'PGRST301', 'PGRST302', 'PGRST303', 'XX000']) {
      respond = (_) async =>
          json({'code': code, 'message': 'unavailable'}, 403);
      expect(
        (await geo.resolve(request()) as GeographicContextUnavailable).failure,
        code == 'XX000'
            ? GeographicContextFailure.sourceUnavailable
            : GeographicContextFailure.scopeUnavailable,
      );
    }
    respond = (_) async => throw const SocketException('offline');
    expect(
      (await geo.resolve(request()) as GeographicContextUnavailable).failure,
      GeographicContextFailure.sourceUnavailable,
    );
    respond = (_) async => throw http.ClientException('offline');
    expect(
      (await geo.resolve(request()) as GeographicContextUnavailable).failure,
      GeographicContextFailure.sourceUnavailable,
    );
    respond = (_) async => throw TimeoutException('timeout');
    expect(
      (await geo.resolve(request()) as GeographicContextUnavailable).failure,
      GeographicContextFailure.sourceUnavailable,
    );
    respond = (_) async => http.Response(
      'not JSON',
      200,
      headers: {'content-type': 'application/json'},
    );
    expect(
      (await geo.resolve(request()) as GeographicContextUnavailable).failure,
      GeographicContextFailure.versionUnverifiable,
    );
    for (final bad in [
      <String, dynamic>{},
      [null],
      ['invalid'],
    ]) {
      respond = (_) async => json(bad);
      expect(
        (await geo.resolve(request()) as GeographicContextUnavailable).failure,
        GeographicContextFailure.versionUnverifiable,
      );
    }
    respond = (_) async => json([row()]);
    expect(await geo.resolve(request()), isA<GeographicContextAvailable>());
  });
  test('requests snapshot levels and concurrent late responses keep their own version', () async {
    await seed();
    final old = Completer<http.Response>();
    var count = 0;
    respond = (_) {
      count++;
      return count == 1
          ? old.future
          : Future.value(json([row()..['source_version'] = 'v2']));
    };
    final levels = {GeographicLevel.district};
    final pending = geo.resolve(request(levels));
    levels.add(GeographicLevel.reportingState);
    final inputB = GeographicContextRequest(
      location: const ValidLocationReference(
        locationId: 'map-b',
        point: GeographicPoint(latitude: 2.3, longitude: 104.1),
      ),
      levels: GeographicLevel.values.toSet(),
    );
    final newer = await geo.resolve(inputB) as GeographicContextAvailable;
    expect(jsonDecode(calls[0].body)['latitude'], 3.1);
    expect(jsonDecode(calls[1].body)['latitude'], 2.3);
    old.complete(json([row()]));
    final older = await pending as GeographicContextAvailable;
    expect(older.results.keys, [GeographicLevel.district]);
    expect(
      (older.results.values.single as GeographicLevelResolved)
          .provenance
          .sourceVersion,
      'v1',
    );
    expect(
      (newer.results.values.first as GeographicLevelResolved)
          .provenance
          .sourceVersion,
      'v2',
    );
    expect(
      (await geo.resolve(
        request(),
      ) as GeographicContextAvailable).results.values.first,
      isA<GeographicLevelResolved>().having(
        (r) => r.provenance.sourceVersion,
        'version',
        'v2',
      ),
    );
  });
  test(
    'logout blocks pending results and subsequent reads, login can recover',
    () async {
      await seed();
      final response = Completer<http.Response>();
      final entered = Completer<void>();
      respond = (_) {
        entered.complete();
        return response.future;
      };
      final pending = geo.resolve(request());
      await entered.future;
      await client.auth.signOut(scope: SignOutScope.local);
      response.complete(json([row()]));
      expect(
        (await pending as GeographicContextUnavailable).failure,
        GeographicContextFailure.scopeUnavailable,
      );
      final count = calls.length;
      expect(
        (await geo.resolve(request()) as GeographicContextUnavailable).failure,
        GeographicContextFailure.scopeUnavailable,
      );
      expect(calls.length, count);
      await seed();
      respond = (_) async => json([row()]);
      expect(await geo.resolve(request()), isA<GeographicContextAvailable>());
    },
  );
}
