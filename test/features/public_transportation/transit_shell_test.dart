import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'public_transportation_page_test.dart'
    show PendingReader, stationPayload;
import '../map_location/location_coordinator_test.dart' show MemoryStorage;

import 'package:locatemy/app/app.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/public_transportation/public_transportation.dart';

import '../../support/fake_authentication_session.dart';
import '../../app/application_shell_test.dart' show ControlledPrivacy;

void main() {
  testWidgets(
    'production task uses stable request, real local Map host and scoped Shell publication',
    (WidgetTester tester) async {
      final FakeAuthenticationSession auth = FakeAuthenticationSession();
      auth.restored = const AuthenticatedSession(accountA);
      final ControlledPrivacy privacy = ControlledPrivacy();
      final MapLocationRuntime map = MapLocationRuntime(
        readScope: privacy.readScope,
        validatePoint: (GeographicPoint point) async {
          return true;
        },
        storageForAccount: (String id) {
          return MemoryStorage();
        },
      );
      late ShellRuntime shell;
      shell = ShellRuntime.compose(
        authentication: auth,
        privacy: () {
          return privacy;
        },
        intents: transitShellBindings(
          () {
            return shell;
          },
          locations: () {
            return map.locations;
          },
        ),
        contributions: transitShellContributions(() {
          return shell;
        }),
      );
      await shell.initialize();
      final LocationSelected selected = (await map.locations.select(
        const LocationSelectionRequest(
          role: LocationRole.single,
          point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
        ),
      )) as LocationSelected;
      final OpenPublicTransportationIntent intent =
          OpenPublicTransportationIntent(
            AnalysisReturnContext(
              location: selected.location,
              role: LocationRole.single,
              analysisDate: DateTime(2026, 9, 17),
              originalRequestIdentity: shell.currentContext!,
            ),
          );
      await shell.applicationShell!.submit(intent);
      final PendingReader reader = PendingReader();
      final List<ShellTaskView> views = transitTaskViews(
        createPublicTransportation(reader),
        map,
        () {
          return shell;
        },
      );
      final ShellTaskView task = views.firstWhere((ShellTaskView view) {
        return view.matches('public-transportation', intent);
      });
      Widget page() {
        return MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return task.build(context, intent);
            },
          ),
        );
      }

      await tester.pumpWidget(page());
      reader.pending[selected.location.locationId]!.complete(
        stationPayload('Mentari BRT'),
      );
      await tester.pumpAndSettle();
      expect(
        shell.state.slots['public-transportation-single'],
        isA<PublicTransportationContribution>(),
      );
      expect(locationWorkspace(map.locations).visibleLayerItems, isEmpty);
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(find.text('68'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(shell.state.selectedTab, ShellTab.map);
      expect(
        (map.locations.read(LocationRole.single) as LocationPresent).location,
        same(selected.location),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await shell.dispose();
        await auth.changes.close();
      });
    },
  );

  test('real comparison route preserves both canonical sides and rejects old facts after Map swaps roles', () async {
    final FakeAuthenticationSession auth = FakeAuthenticationSession();
    auth.restored = const AuthenticatedSession(accountA);
    final ControlledPrivacy privacy = ControlledPrivacy();
    late ShellRuntime shell;
    late LocationCoordinator locations;
    shell = ShellRuntime.compose(
      authentication: auth,
      privacy: () {
        return privacy;
      },
      intents: transitShellBindings(
        () {
          return shell;
        },
        locations: () {
          return locations;
        },
      ),
      contributions: transitShellContributions(() {
        return shell;
      }),
    );
    await shell.initialize();
    locations = createLocationCoordinator(
      scope: shell.state.scope!,
      readScope: privacy.readScope,
      validatePoint: (GeographicPoint point) async {
        return true;
      },
    );
    final LocationSelected a = (await locations.select(
      const LocationSelectionRequest(
        role: LocationRole.locationA,
        point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
      ),
    )) as LocationSelected;
    final LocationSelected b = (await locations.select(
      const LocationSelectionRequest(
        role: LocationRole.locationB,
        point: GeographicPoint(latitude: 3.0838, longitude: 101.6177),
      ),
    )) as LocationSelected;
    AnalysisReturnContext context(
      ValidLocationReference location,
      LocationRole role,
    ) {
      return AnalysisReturnContext(
        location: location,
        role: role,
        analysisDate: DateTime(2026, 9, 17),
        originalRequestIdentity: shell.currentContext!,
      );
    }

    expect(
      await shell.applicationShell!.submit(
        OpenPublicTransportationComparisonIntent(
          context(a.location, LocationRole.locationA),
          context(b.location, LocationRole.locationB),
        ),
      ),
      isA<ShellIntentAccepted>(),
    );
    final AnalysisReturnContext taskA = context(
      a.location,
      LocationRole.locationA,
    );
    final AnalysisReturnContext taskB = context(
      b.location,
      LocationRole.locationB,
    );
    const TransitUnavailable unavailable = TransitUnavailable(
      TransitUnavailableReason.noUsableFeed,
      <FeedStatus>[],
    );
    final PublicTransportationComparisonContribution contribution =
        PublicTransportationComparisonContribution(
          const TransitIncomparable(
            unavailable,
            unavailable,
            TransitComparisonReason.sideUnavailable,
          ),
          taskA,
          taskB,
        );
    expect(
      await shell.applicationShell!.publish(contribution),
      isA<ShellContributionAccepted>(),
    );
    expect(
      shell.state.slots['public-transportation-comparison'],
      same(contribution),
    );
    final ApplicationShell old = shell.applicationShell!;
    expect(
      await old.submit(ReturnToMapIntent(taskA)),
      isA<ShellIntentAccepted>(),
    );
    await locations.swapComparisonLocations();
    expect(
      (locations.read(LocationRole.locationA) as LocationPresent).location,
      same(b.location),
    );
    expect(
      await shell.applicationShell!.submit(
        OpenPublicTransportationComparisonIntent(
          context(b.location, LocationRole.locationA),
          context(a.location, LocationRole.locationB),
        ),
      ),
      isA<ShellIntentAccepted>(),
    );
    expect(
      (await old.publish(contribution) as ShellContributionRejected).reason,
      ShellRejectionReason.staleInput,
    );
    expect(shell.state.slots, isEmpty);
    await shell.dispose();
    await auth.changes.close();
  });

  test('real Shell accepts current Transit facts and rejects them after returning to the unchanged Map', () async {
    final FakeAuthenticationSession auth = FakeAuthenticationSession();
    auth.restored = const AuthenticatedSession(accountA);
    final ControlledPrivacy privacy = ControlledPrivacy();
    late ShellRuntime shell;
    late LocationCoordinator locations;
    shell = ShellRuntime.compose(
      authentication: auth,
      privacy: () {
        return privacy;
      },
      intents: transitShellBindings(
        () {
          return shell;
        },
        locations: () {
          return locations;
        },
      ),
      contributions: transitShellContributions(() {
        return shell;
      }),
    );
    await shell.initialize();
    locations = createLocationCoordinator(
      scope: shell.state.scope!,
      readScope: privacy.readScope,
      validatePoint: (GeographicPoint point) async {
        return true;
      },
    );
    final LocationSelected selected = (await locations.select(
      const LocationSelectionRequest(
        role: LocationRole.single,
        point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
      ),
    )) as LocationSelected;
    final DateTime date = DateTime(2026, 9, 17);
    final AnalysisReturnContext origin = AnalysisReturnContext(
      location: selected.location,
      role: LocationRole.single,
      analysisDate: date,
      originalRequestIdentity: shell.currentContext!,
    );
    expect(
      await shell.applicationShell!.submit(
        OpenPublicTransportationIntent(origin),
      ),
      isA<ShellIntentAccepted>(),
    );
    final AnalysisReturnContext task = AnalysisReturnContext(
      location: selected.location,
      role: LocationRole.single,
      analysisDate: date,
      originalRequestIdentity: shell.currentContext!,
    );
    final PublicTransportationContribution contribution =
        PublicTransportationContribution(
          const TransitUnavailable(
            TransitUnavailableReason.noUsableFeed,
            <FeedStatus>[],
          ),
          task,
        );
    expect(
      await shell.applicationShell!.publish(contribution),
      isA<ShellContributionAccepted>(),
    );
    expect(
      shell.state.slots['public-transportation-single'],
      same(contribution),
    );
    final ApplicationShell old = shell.applicationShell!;
    expect(
      await old.submit(ReturnToMapIntent(task)),
      isA<ShellIntentAccepted>(),
    );
    expect(shell.state.selectedTab, ShellTab.map);
    expect(shell.state.routes, isEmpty);
    expect(
      (locations.read(LocationRole.single) as LocationPresent).location,
      same(selected.location),
    );
    final ShellContributionRejected late =
        (await old.publish(contribution)) as ShellContributionRejected;
    expect(late.reason, ShellRejectionReason.staleInput);
    await shell.dispose();
    await auth.changes.close();
  });
}
