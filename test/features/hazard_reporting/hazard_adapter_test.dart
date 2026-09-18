import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locatemy/features/hazard_reporting/hazard_reporting.dart';
import 'package:locatemy/features/map_location/map_location.dart';

void main() {
  test(
    'public response retains valid rows when another row cannot be decoded',
    () async {
      final SupabaseClient client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        httpClient: MockClient((http.Request request) async {
          return http.Response(
            jsonEncode({
              'reports': [
                reportJson,
                {'id': 'broken'},
              ],
              'next_cursor': 'next',
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final HazardReporting reports = createHazardReporting(
        store: createSupabaseHazardStore(client),
        currentAccountId: () {
          return 'test';
        },
      );
      final HazardPageOutcome outcome = await reports.loadPublic(
        const HazardPageRequest(
          viewportVersion: 'version',
          viewport: HazardViewport(
            GeographicPoint(latitude: 3, longitude: 101),
            GeographicPoint(latitude: 4, longitude: 102),
          ),
        ),
      );
      expect(outcome, isA<HazardPagePartial>());
      expect((outcome as HazardPagePartial).page.reports.length, 1);
      expect(outcome.page.nextCursor, 'next');
      expect(outcome.failure, HazardReadFailure.incompletePage);
      await client.dispose();
    },
  );
  test('vote rejects negative aggregate counts', () async {
    final SupabaseClient client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((http.Request request) async {
        return http.Response(
          '{"mine":"up","upvotes":-1,"downvotes":0}',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final HazardReporting reports = createHazardReporting(
      store: createSupabaseHazardStore(client),
      currentAccountId: () {
        return 'test';
      },
    );
    expect(
      await reports.vote(
        const HazardVoteRequest(HazardReportId('id'), HazardVote.up),
      ),
      isA<HazardVoteRejected>(),
    );
    await client.dispose();
  });

  test(
    'real SDK maps an authoritative created report and aggregate votes',
    () async {
      final SupabaseClient client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        httpClient: MockClient((http.Request request) async {
          expect(request.url.path, '/rest/v1/rpc/hazard_create');
          final Map<String, dynamic> body =
              jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['p_title'], 'Flooded walkway');
          return http.Response(
            jsonEncode(reportJson),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final HazardReporting hazards = createHazardReporting(
        store: createSupabaseHazardStore(client),
        currentAccountId: () {
          return 'test';
        },
      );
      final HazardCreateOutcome outcome = await hazards.create(
        const HazardCreateRequest(
          location: ValidLocationReference(
            locationId: 'map-point',
            point: GeographicPoint(latitude: 3.0738, longitude: 101.6072),
          ),
          type: HazardType.flood,
          title: '  Flooded walkway  ',
        ),
      );
      expect(outcome, isA<HazardCreated>());
      final HazardReport report = (outcome as HazardCreated).report;
      expect(report.id.value, '00000000-0000-0000-0000-000000000001');
      expect(report.author, HazardAuthorView.mine);
      expect(report.vote.upvotes, 2);
      expect(report.reportedAt, DateTime.utc(2026, 9, 17));
      await client.dispose();
    },
  );
  test(
    'public paging preserves the next cursor and viewport identity',
    () async {
      final SupabaseClient client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        httpClient: MockClient((http.Request request) async {
          expect(request.url.path, '/rest/v1/rpc/hazard_page');
          return http.Response(
            jsonEncode({
              'reports': [reportJson],
              'next_cursor': reportJson['id'],
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final HazardReporting hazards = createHazardReporting(
        store: createSupabaseHazardStore(client),
        currentAccountId: () {
          return 'test';
        },
      );
      final HazardPageOutcome result = await hazards.loadPublic(
        const HazardPageRequest(
          viewportVersion: 'viewport-7',
          viewport: HazardViewport(
            GeographicPoint(latitude: 3, longitude: 101),
            GeographicPoint(latitude: 4, longitude: 102),
          ),
        ),
      );
      final HazardPage page = (result as HazardPageAvailable).page;
      expect(page.reports.single.title, 'Flooded walkway');
      expect(page.nextCursor, reportJson['id']);
      expect(page.viewportVersion, 'viewport-7');
      await client.dispose();
    },
  );

  test(
    'RPC author denial is a permission failure rather than a network error',
    () async {
      final SupabaseClient client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        httpClient: MockClient((http.Request request) async {
          return http.Response(
            '{"code":"42501","message":"Author required"}',
            403,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final HazardStore store = createSupabaseHazardStore(client);
      final HazardCreateOutcome result = await store.create(
        const HazardCreateRequest(
          location: ValidLocationReference(
            locationId: 'point',
            point: GeographicPoint(latitude: 3, longitude: 101),
          ),
          type: HazardType.flood,
          title: 'Flood',
        ),
      );
      expect(
        (result as HazardCreateRejected).failure,
        HazardWriteFailure.permissionDenied,
      );
      await client.dispose();
    },
  );

  test('author can read, resolve, vote, retract and delete an authoritative report', () async {
    final SupabaseClient client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((http.Request request) async {
        final String rpc = request.url.path.split('/').last;
        Object? response = reportJson;
        if (rpc == 'hazard_status') {
          response = {...reportJson, 'status': 'resolved'};
        }
        if (rpc == 'hazard_delete') {
          response = true;
        }
        if (rpc == 'hazard_vote') {
          final Map<String, dynamic> body =
              jsonDecode(request.body) as Map<String, dynamic>;
          response = {
            'mine': body['p_vote'],
            'upvotes': body['p_vote'] == 'up' ? 3 : 2,
            'downvotes': 1,
          };
        }
        if (rpc == 'hazard_page') {
          response = {
            'reports': [reportJson],
            'next_cursor': null,
          };
        }
        return http.Response(
          jsonEncode(response),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final HazardReporting hazards = createHazardReporting(
      store: createSupabaseHazardStore(client),
      currentAccountId: () {
        return 'test';
      },
    );
    final HazardReportId id = HazardReportId(reportJson['id']! as String);
    expect(await hazards.loadDetail(id), isA<HazardDetailAvailable>());
    final HazardStatusChanged resolved = await hazards.changeMyStatus(
      HazardStatusRequest(id, HazardAuthorStatus.resolved),
    ) as HazardStatusChanged;
    expect(resolved.report.status, HazardAuthorStatus.resolved);
    final HazardVoteChanged voted = await hazards.vote(
      HazardVoteRequest(id, HazardVote.up),
    ) as HazardVoteChanged;
    expect(voted.state.upvotes, 3);
    final HazardVoteChanged retracted = await hazards.vote(
      HazardVoteRequest(id, HazardVote.none),
    ) as HazardVoteChanged;
    expect(retracted.state.mine, HazardVote.none);
    expect(retracted.state.upvotes, 2);
    expect(await hazards.deleteMine(id), isA<HazardDeleted>());
    await client.dispose();
  });

  test('my reports are requested as an account-owned page', () async {
    final SupabaseClient client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((http.Request request) async {
        final Map<String, dynamic> body =
            jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['p_mine'], true);
        return http.Response(
          '{"reports":[],"next_cursor":null}',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final HazardReporting hazards = createHazardReporting(
      store: createSupabaseHazardStore(client),
      currentAccountId: () {
        return 'test';
      },
    );
    final MyHazardsAvailable result = await hazards.loadMine(
      const HazardPageRequest(
        viewportVersion: 'mine',
        viewport: HazardViewport(
          GeographicPoint(latitude: -90, longitude: -180),
          GeographicPoint(latitude: 90, longitude: 180),
        ),
      ),
    ) as MyHazardsAvailable;
    expect(result.page.reports, isEmpty);
    await client.dispose();
  });

  test('incomplete nearby count never becomes a successful zero', () async {
    final SupabaseClient client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((http.Request request) async {
        return http.Response(
          '{"count":0,"radius_meters":2000,"counted_at":"2026-09-17T00:00:00Z","complete":false}',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final HazardRiskCounter counter = createHazardRiskCounter(
      store: createSupabaseHazardStore(client),
      currentAccountId: () {
        return 'test';
      },
    );
    final HazardNearbyCountOutcome result = await counter.countPending(
      const HazardNearbyCountRequest(
        ValidLocationReference(
          locationId: 'point',
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
      ),
    );
    expect(
      (result as HazardNearbyCountUnavailable).failure,
      HazardNearbyCountFailure.partialResult,
    );
    await client.dispose();
  });

  test('nearby count requires a complete 2000 metre response', () async {
    final SupabaseClient client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((http.Request request) async {
        return http.Response(
          '{"count":4,"radius_meters":2000,"counted_at":"2026-09-17T00:00:00Z","complete":true}',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final HazardRiskCounter counter = createHazardRiskCounter(
      store: createSupabaseHazardStore(client),
      currentAccountId: () {
        return 'test';
      },
    );
    final HazardNearbyCountOutcome result = await counter.countPending(
      const HazardNearbyCountRequest(
        ValidLocationReference(
          locationId: 'point',
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
      ),
    );
    expect((result as HazardNearbyCountAvailable).count, 4);
    expect(result.radiusMeters, 2000);
    await client.dispose();
  });

  test(
    'a negative aggregate count is unavailable rather than a fabricated report',
    () async {
      final SupabaseClient client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        httpClient: MockClient((http.Request request) async {
          return http.Response(
            jsonEncode({
              ...reportJson,
              'vote': {'mine': 'none', 'upvotes': -1, 'downvotes': 0},
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final HazardStore store = createSupabaseHazardStore(client);
      expect(
        await store.loadDetail(HazardReportId(reportJson['id']! as String)),
        isA<HazardDetailUnavailable>(),
      );
      await client.dispose();
    },
  );
}

const Map<String, Object?> reportJson = {
  'id': '00000000-0000-0000-0000-000000000001',
  'type': 'flood',
  'title': 'Flooded walkway',
  'description': null,
  'latitude': 3.0738,
  'longitude': 101.6072,
  'status': 'pending',
  'reported_at': '2026-09-17T00:00:00Z',
  'author': 'mine',
  'vote': {'mine': 'none', 'upvotes': 2, 'downvotes': 1},
};
