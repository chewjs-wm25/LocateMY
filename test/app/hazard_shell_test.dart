// Explicit declarations follow Development Standard §7.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/hazard_reporting/hazard_reporting.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/nearby_facilities/nearby_facilities.dart';
import 'package:locatemy/features/home_relocation_outlook/home_relocation_outlook.dart';

import '../support/fake_authentication_session.dart';
import '../support/fake_home_relocation_outlook.dart';
import '../features/map_location/location_coordinator_test.dart'
    show MemoryStorage;
import 'application_shell_test.dart' show ControlledPrivacy;

final class EntryHazardStore implements HazardStore {
  @override
  Future<MyHazardsOutcome> loadMine(HazardPageRequest request) async {
    return MyHazardsAvailable(HazardPage([], null, request.viewportVersion));
  }

  @override
  Future<HazardPageOutcome> loadPublic(HazardPageRequest request) async {
    return HazardPageAvailable(HazardPage([], null, request.viewportVersion));
  }

  // Unused writes are deliberately unsupported by this navigation fixture.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

final class EntryFacilities implements NearbyFacilities {
  // FacilityMapViewModel isolates provider failures from map navigation.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  for (final bool english in [false, true]) {
    for (final double scale in [1.0, 2.0]) {
      testWidgets(
        'new report guides selection, confirms and isolates accounts: English=$english scale=$scale',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(720, 1600);
          tester.view.devicePixelRatio = 2;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          String guidance = '选择隐患位置，然后确认进入报告表单。';
          String newReport = '＋ 新建隐患报告';
          final FakeAuthenticationSession auth = FakeAuthenticationSession();
          auth.restored = const AuthenticatedSession(accountA);
          final ControlledPrivacy privacy = ControlledPrivacy();
          late ShellRuntime shell;
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
          await shell.initialize();
          final MapLocationRuntime map = MapLocationRuntime(
            readScope: privacy.readScope,
            validatePoint: (GeographicPoint point) async {
              return point.latitude == 3;
            },
            storageForAccount: (String id) {
              return MemoryStorage();
            },
          );
          final HazardReportingRuntime hazards = HazardReportingRuntime(
            store: EntryHazardStore(),
            readScope: privacy.readScope,
          );
          final ShellViews production = mapAndHomeShellViews(
            () {
              return FakeHomeRelocationOutlook((HomeLoadRequest request) async {
                return HomeLoaded(snapshot: homeFixture());
              });
            },
            map,
            EntryFacilities(),
            createLocationSearch(apiKey: ''),
            hazards: hazards,
            runtime: () {
              return shell;
            },
          );
          final AuthenticationViewModel authVm = createAuthenticationViewModel(
            auth,
          );
          await tester.pumpWidget(
            LocateMyApp(
              authenticationViewModel: authVm,
              shellRuntime: shell,
              shellViews: ShellViews(
                home: (BuildContext context, ApplicationShell scoped) {
                  return const SizedBox();
                },
                map: production.map,
                tasks: production.tasks,
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (english) {
            await tester.tap(find.byKey(const ValueKey('language-switch')));
            await tester.pumpAndSettle();
            guidance = 'Choose a hazard location, then confirm to open the report form.';
            newReport = '+ New hazard report';
          }
          await shell.submit(const OpenMyHazardsIntent('map'));
          await tester.pumpAndSettle();
          await tester.tap(find.text(newReport));
          await tester.pumpAndSettle();
          expect(shell.state.selectedTab, ShellTab.map);
          expect(find.text(guidance), findsOneWidget);
          final Finder confirm = find.byKey(
            const ValueKey('hazard-confirm-location'),
          );
          expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
          await map.locations.select(
            const LocationSelectionRequest(
              role: LocationRole.single,
              point: GeographicPoint(latitude: 0, longitude: 101),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
          final LocationSelectionOutcome outcome = await map.locations.select(
            const LocationSelectionRequest(
              role: LocationRole.single,
              point: GeographicPoint(latitude: 3, longitude: 101),
            ),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(confirm);
          final VoidCallback openComposer = tester
              .widget<FilledButton>(confirm)
              .onPressed!;
          openComposer();
          openComposer();
          await tester.pumpAndSettle();
          expect(find.byType(HazardComposerPage), findsOneWidget);
          expect(shell.state.routes.length, 1);
          final OpenHazardComposerIntent intent =
              shell.state.routes.last.intent! as OpenHazardComposerIntent;
          expect(
            identical(intent.location, (outcome as LocationSelected).location),
            isTrue,
          );
          expect(intent.returnContextId, 'map');
          shell.back();
          await tester.pumpAndSettle();
          expect(find.text(guidance), findsNothing);
          await tester.tap(find.byKey(const ValueKey('hazard-start-report')));
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byKey(const ValueKey('hazard-cancel-report')),
          );
          await tester.tap(find.byKey(const ValueKey('hazard-cancel-report')));
          await tester.pumpAndSettle();
          expect(find.text(guidance), findsNothing);
          await tester.tap(find.byKey(const ValueKey('hazard-start-report')));
          await tester.pumpAndSettle();
          await shell.signOut();
          await tester.pumpAndSettle();
          auth.restored = const AuthenticatedSession(
            AuthenticatedAccount(
              accountId: 'b',
              email: 'b@example.com',
              confirmation: EmailConfirmation.confirmed,
            ),
          );
          auth.changes.add(auth.restored);
          await tester.pumpAndSettle();
          shell.selectTab(ShellTab.map);
          await tester.pumpAndSettle();
          expect(find.text(guidance), findsNothing);
          expect(
            map.locations.read(LocationRole.single),
            isA<LocationAbsent>(),
          );
          await tester.pumpWidget(const SizedBox());
          authVm.dispose();
          await tester.runAsync(() async {
            await shell.dispose();
            await auth.changes.close();
          });
        },
      );
    }
  }
}
