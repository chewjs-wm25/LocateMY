import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locatemy/features/hazard_reporting/hazard_reporting.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/app/application_shell.dart';

void main() {
  test('two live accounts publish, vote, manage and enforce author-only immutable reports', () async {
    HttpOverrides.global = null;
    final Map<String, String> env = Platform.environment;
    SupabaseClient make() {
      return SupabaseClient(
        env['SUPABASE_URL']!,
        env['SUPABASE_PUBLISHABLE_KEY']!,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
    }

    final SupabaseClient a = make();
    final SupabaseClient b = make();
    final SupabaseClient anonymous = make();
    HazardReportId? id;
    try {
      await a.auth.signInWithPassword(
        email: env['LOCATEMY_EMAIL']!,
        password: env['LOCATEMY_PASSWORD']!,
      );
      await b.auth.signInWithPassword(
        email: env['LOCATEMY_OTHER_EMAIL']!,
        password: env['LOCATEMY_OTHER_PASSWORD']!,
      );
      final AccountScope aScope = AccountScope(a.auth.currentUser!.id);
      final AccountScope bScope = AccountScope(b.auth.currentUser!.id);
      final HazardReporting author = createHazardReporting(
        store: createSupabaseHazardStore(a),
        readScope: () {
          return AccountScopeOpened(aScope);
        },
      );
      final HazardReporting other = createHazardReporting(
        store: createSupabaseHazardStore(b),
        readScope: () {
          return AccountScopeOpened(bScope);
        },
      );
      final HazardCreateOutcome outside = await author.create(
        HazardCreateRequest(
          location: const ValidLocationReference(
            locationId: 'forged-reference',
            point: GeographicPoint(latitude: 0, longitude: 0),
          ),
          type: HazardType.other,
          title: "${env['LOCATEMY_HAZARD_FIXTURE']!}-outside",
        ),
      );
      expect(
        (outside as HazardCreateRejected).failure,
        HazardWriteFailure.invalidLocation,
      );
      const ValidLocationReference location = ValidLocationReference(
        locationId: 'validated-test-point',
        point: GeographicPoint(latitude: 3.0738, longitude: 101.6072),
      );
      final HazardCreateOutcome created = await author.create(
        HazardCreateRequest(
          location: location,
          type: HazardType.flood,
          title: env['LOCATEMY_HAZARD_FIXTURE']!,
        ),
      );
      expect(created, isA<HazardCreated>());
      id = (created as HazardCreated).report.id;
      final HazardCreated profileless = await other.create(
        HazardCreateRequest(
          location: location,
          type: HazardType.other,
          title: "${env['LOCATEMY_HAZARD_FIXTURE']!}-no-profile",
        ),
      ) as HazardCreated;
      expect(
        await other.deleteMine(profileless.report.id),
        isA<HazardDeleted>(),
      );
      final HazardVoteChanged up = await author.vote(
        HazardVoteRequest(id, HazardVote.up),
      ) as HazardVoteChanged;
      expect(up.state.upvotes, 1);
      final HazardVoteChanged down = await other.vote(
        HazardVoteRequest(id, HazardVote.down),
      ) as HazardVoteChanged;
      expect(down.state.upvotes, 1);
      expect(down.state.downvotes, 1);
      final HazardVoteChanged changed = await other.vote(
        HazardVoteRequest(id, HazardVote.up),
      ) as HazardVoteChanged;
      expect(changed.state.upvotes, 2);
      expect(changed.state.downvotes, 0);
      final HazardVoteChanged retracted = await other.vote(
        HazardVoteRequest(id, HazardVote.none),
      ) as HazardVoteChanged;
      expect(retracted.state.upvotes, 1);
      expect(retracted.state.mine, HazardVote.none);
      final List<dynamic> foreignVotes = await b
          .from('crowdsourced_hazard_votes')
          .select()
          .eq('hazard_id', id.value);
      expect(foreignVotes, isEmpty);
      final HazardStatusOutcome denied = await other.changeMyStatus(
        HazardStatusRequest(id, HazardAuthorStatus.resolved),
      );
      expect(
        (denied as HazardStatusRejected).failure,
        HazardWriteFailure.permissionDenied,
      );
      expect(await other.deleteMine(id), isA<HazardDeleteRejected>());
      await expectLater(
        a
            .from('crowdsourced_hazards')
            .update({'title': 'tampered'})
            .eq('id', id.value),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        anonymous.rpc('hazard_detail', params: {'p_id': id.value}),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        anonymous.rpc('hazard_vote_counts', params: {'p_id': id.value}),
        throwsA(isA<PostgrestException>()),
      );
      final HazardRiskCounter counter = createHazardRiskCounter(
        store: createSupabaseHazardStore(a),
        readScope: () {
          return AccountScopeOpened(aScope);
        },
      );
      final HazardNearbyCountOutcome invalidCount = await counter.countPending(
        const HazardNearbyCountRequest(
          ValidLocationReference(
            locationId: 'forged',
            point: GeographicPoint(latitude: 0, longitude: 0),
          ),
        ),
      );
      expect(
        (invalidCount as HazardNearbyCountUnavailable).failure,
        HazardNearbyCountFailure.invalidLocation,
      );
      final HazardNearbyCountAvailable pending = await counter.countPending(
        const HazardNearbyCountRequest(location),
      ) as HazardNearbyCountAvailable;
      expect(pending.count, greaterThanOrEqualTo(1));
      expect(
        await author.changeMyStatus(
          HazardStatusRequest(id, HazardAuthorStatus.resolved),
        ),
        isA<HazardStatusChanged>(),
      );
      final HazardNearbyCountAvailable resolved = await counter.countPending(
        const HazardNearbyCountRequest(location),
      ) as HazardNearbyCountAvailable;
      expect(resolved.count, pending.count - 1);
      expect(await author.deleteMine(id), isA<HazardDeleted>());
      expect(
        (await author.loadDetail(id) as HazardDetailUnavailable).failure,
        HazardReadFailure.notFound,
      );
    } finally {
      if (id != null) {
        await a.from('crowdsourced_hazards').delete().eq('id', id.value);
      }
      await a.dispose();
      await b.dispose();
      await anonymous.dispose();
    }
  }, skip: Platform.environment['LOCATEMY_HAZARD_LIVE'] != '1');
  test('Haversine includes the 2 km boundary, excludes outside and resolved, and five types persist', () async {
    HttpOverrides.global = null;
    final Map<String, String> env = Platform.environment;
    final SupabaseClient client = SupabaseClient(
      env['SUPABASE_URL']!,
      env['SUPABASE_PUBLISHABLE_KEY']!,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final List<HazardReportId> ids = [];
    try {
      await client.auth.signInWithPassword(
        email: env['LOCATEMY_EMAIL']!,
        password: env['LOCATEMY_PASSWORD']!,
      );
      final AccountScope scope = AccountScope(client.auth.currentUser!.id);
      AccountScopeSnapshot readScope() {
        return AccountScopeOpened(scope);
      }

      final HazardReporting reports = createHazardReporting(
        store: createSupabaseHazardStore(client),
        readScope: readScope,
      );
      final HazardRiskCounter counter = createHazardRiskCounter(
        store: createSupabaseHazardStore(client),
        readScope: readScope,
      );
      const ValidLocationReference center = ValidLocationReference(
        locationId: 'center',
        point: GeographicPoint(latitude: 3.0738, longitude: 101.6072),
      );
      final HazardNearbyCountAvailable baseline = await counter.countPending(
        const HazardNearbyCountRequest(center),
      ) as HazardNearbyCountAvailable;
      // Independent worked points on the same meridian: 1999 m, 2000 m,
      // 2001 m north, then two at the centre (one resolved).
      const List<double> latitudes = [
        3.091777438902315,
        3.0917864321183745,
        3.091795425334434,
        3.0738,
        3.0738,
      ];
      for (int index = 0; index < HazardType.values.length; index++) {
        final HazardCreated result = await reports.create(
          HazardCreateRequest(
            location: ValidLocationReference(
              locationId: 'point-$index',
              point: GeographicPoint(
                latitude: latitudes[index],
                longitude: 101.6072,
              ),
            ),
            type: HazardType.values[index],
            title: "${env['LOCATEMY_HAZARD_FIXTURE']!}-boundary-$index",
          ),
        ) as HazardCreated;
        ids.add(result.report.id);
        expect(
          (await reports.loadDetail(
            result.report.id,
          ) as HazardDetailAvailable).report.type,
          HazardType.values[index],
        );
        if (index == 3) {
          await reports.changeMyStatus(
            HazardStatusRequest(result.report.id, HazardAuthorStatus.resolved),
          );
        }
      }
      final HazardNearbyCountAvailable count = await counter.countPending(
        const HazardNearbyCountRequest(center),
      ) as HazardNearbyCountAvailable;
      expect(count.count, baseline.count + 3);
      expect(count.radiusMeters, 2000);
      expect(count.countedAt.isUtc, true);
    } finally {
      for (final HazardReportId id in ids) {
        await client.from('crowdsourced_hazards').delete().eq('id', id.value);
      }
      await client.dispose();
    }
  }, skip: Platform.environment['LOCATEMY_HAZARD_LIVE'] != '1');

  test('real Shell, Map and Privacy route validated creation, contribute layers and invalidate old scope', () async {
    HttpOverrides.global = null;
    final Map<String, String> env = Platform.environment;
    final SupabaseClient client = SupabaseClient(
      env['SUPABASE_URL']!,
      env['SUPABASE_PUBLISHABLE_KEY']!,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final Directory directory = Directory.systemTemp.createTempSync(
      'hazard-integration-',
    );
    final AuthenticationSession auth = createAuthenticationSession(client);
    late AccountPrivacy privacy;
    late ShellRuntime shell;
    HazardReportId? id;
    await auth.signIn(
      email: env['LOCATEMY_EMAIL']!,
      password: env['LOCATEMY_PASSWORD']!,
    );
    final HazardReportingRuntime hazards = HazardReportingRuntime(
      store: createSupabaseHazardStore(client),
      readScope: () {
        return privacy.readScope();
      },
    );
    shell = ShellRuntime.compose(
      authentication: auth,
      privacy: () {
        return privacy;
      },
      intents: [
        ...mapShellBindings(() {
          return shell;
        }),
        ...hazardShellBindings(() {
          return shell;
        }),
      ],
    );
    privacy = createAccountPrivacy(
      authenticationSession: auth,
      participants: [
        createAuthenticationPrivacyParticipant(auth),
        shell,
        hazards,
      ],
      requiredParticipants: const {
        AccountPrivacyParticipantId.authenticationSession,
        AccountPrivacyParticipantId.applicationShell,
        AccountPrivacyParticipantId.hazardReporting,
      },
      stateDirectory: directory,
    );
    try {
      await shell.initialize();
      expect(shell.state.gate, ShellGate.opened);
      final AccountScope scope = shell.state.scope!;
      final LocationCoordinator locations = createLocationCoordinator(
        scope: scope,
        readScope: () {
          return privacy.readScope();
        },
        validatePoint: (GeographicPoint point) {
          return validateLocationInMalaysia(client, point);
        },
      );
      final MapLayerHost host = locationLayerHost(locations);
      final MapLayerIntentAccepted picked = await host.requestLongPress(
        const GeographicPoint(latitude: 3.0738, longitude: 101.6072),
      ) as MapLayerIntentAccepted;
      final ValidLocationReference location =
          (picked.intent as CreateHazardIntent).location;
      expect(
        await shell.submit(OpenMapLayerIntent(picked.intent)),
        isA<ShellIntentAccepted>(),
      );
      expect(shell.state.routes.last.destination, 'hazard-map-intent');
      final HazardReporting retained = hazards.reporting;
      final HazardCreated created = await retained.create(
        HazardCreateRequest(
          location: location,
          type: HazardType.traffic,
          title: "${env['LOCATEMY_HAZARD_FIXTURE']!}-integration",
        ),
      ) as HazardCreated;
      id = created.report.id;
      final HazardPageAvailable page = await retained.loadPublic(
        const HazardPageRequest(
          viewportVersion: 'integration',
          viewport: HazardViewport(
            GeographicPoint(latitude: 3, longitude: 101),
            GeographicPoint(latitude: 4, longitude: 102),
          ),
        ),
      ) as HazardPageAvailable;
      expect(
        page.page.reports.any((HazardReport report) {
          return report.id.value == id!.value;
        }),
        true,
      );
      setLocationViewport(locations, 'integration');
      expect(
        await host.contribute(
          MapLayerContribution(
            providerId: 'hazard-reporting',
            layerId: 'public-hazards',
            viewportVersion: 'integration',
            visibility: MapLayerVisibility.visible,
            items: [
              MapLayerItem(
                stableItemId: id.value,
                point: created.report.location,
                intent: ProviderDefinedIntent(
                  providerId: 'hazard-reporting',
                  action: 'detail',
                  stableItemId: id.value,
                ),
              ),
            ],
          ),
        ),
        isA<MapLayerAccepted>(),
      );
      expect(locations.read(LocationRole.single), isA<LocationAbsent>());
      expect(
        await shell.submit(
          OpenHazardDetailIntent(id: id, returnContextId: 'map'),
        ),
        isA<ShellIntentAccepted>(),
      );
      shell.back();
      expect(shell.state.routes.last.destination, 'hazard-map-intent');
      expect(
        await shell.submit(const ReturnToHazardMapIntent('map')),
        isA<ShellIntentAccepted>(),
      );
      expect(shell.state.selectedTab, ShellTab.map);
      // Delete fixture before sign-out, then prove old service cannot operate.
      await retained.deleteMine(id);
      id = null;
      await shell.signOut();
      expect(shell.state.gate, ShellGate.authentication);
      expect(
        (await retained.loadDetail(
          const HazardReportId('old'),
        ) as HazardDetailUnavailable).failure,
        HazardReadFailure.scopeUnavailable,
      );
    } finally {
      if (id != null) {
        await client.from('crowdsourced_hazards').delete().eq('id', id.value);
      }
      await shell.dispose();
      await disposeAccountPrivacy(privacy);
      await client.dispose();
      directory.deleteSync(recursive: true);
    }
  }, skip: Platform.environment['LOCATEMY_HAZARD_LIVE'] != '1');
}
