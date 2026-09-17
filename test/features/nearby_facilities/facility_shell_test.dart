import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/nearby_facilities/nearby_facilities.dart';

import '../../support/fake_account_privacy.dart';
import '../../support/fake_authentication_session.dart';

void main() {
  testWidgets('root page preserves the explicit opaque return context', (
    WidgetTester tester,
  ) async {
    final Object returnContext = Object();
    final ShellViews views = mapAndHomeShellViews(
      () {
        throw StateError('Home is not used');
      },
      MapLocationRuntime(
        readScope: () {
          return AccountScopeClosed(AccountScope('unused'));
        },
        validatePoint: (GeographicPoint point) async {
          return true;
        },
        storageForAccount: (String accountId) {
          throw StateError('Storage is not used');
        },
      ),
      createNearbyFacilities(
        source: createOverpassFacilitySource(http.Client()),
      ),
      createLocationSearch(apiKey: 'unused'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            final ShellTaskView task = views.tasks.firstWhere((
              ShellTaskView view,
            ) {
              return view.destination == 'nearby-facilities';
            });
            final NearbyFacilitiesPage page = task.build(
              context,
              OpenNearbyFacilitiesIntent(
                location: const ValidLocationReference(
                  locationId: 'a',
                  point: GeographicPoint(latitude: 3, longitude: 101),
                ),
                returnContext: returnContext,
              ),
            ) as NearbyFacilitiesPage;
            expect(page.returnContext, same(returnContext));
            return const SizedBox();
          },
        ),
      ),
    );
  });
  testWidgets(
    'root projects an unavailable summary instead of hiding its reason',
    (WidgetTester tester) async {
      final ShellViews views = mapAndHomeShellViews(
        () {
          throw StateError('Home is not used');
        },
        MapLocationRuntime(
          readScope: () {
            return AccountScopeClosed(AccountScope('unused'));
          },
          validatePoint: (GeographicPoint point) async {
            return true;
          },
          storageForAccount: (String accountId) {
            throw StateError('Storage is not used');
          },
        ),
        createNearbyFacilities(
          source: createOverpassFacilitySource(http.Client()),
        ),
        createLocationSearch(apiKey: 'unused'),
      );
      const NearbyFacilitiesSummaryContribution contribution =
          NearbyFacilitiesSummaryContribution(
            location: ValidLocationReference(
              locationId: 'a',
              point: GeographicPoint(latitude: 3, longitude: 101),
            ),
            outcome: FacilityAnalysisUnavailable(
              failure: FacilityFailure.incompleteResponse,
            ),
          );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return views.contributions
                    .firstWhere((ShellContributionView view) {
                      return view.matches(contribution);
                    })
                    .build(context, contribution);
              },
            ),
          ),
        ),
      );
      expect(
        find.text('The response is incomplete; coverage is unknown.'),
        findsOneWidget,
      );
      expect(find.text('0 / 5'), findsNothing);
    },
  );
  test('real Shell routes facilities and retains original unavailable contribution and rejects it after returning', () async {
    final AccountScope scope = AccountScope('a');
    final FakeAuthenticationSession auth = FakeAuthenticationSession();
    auth.restored = const AuthenticatedSession(accountA);
    final FakeAccountPrivacy privacy = FakeAccountPrivacy(
      opens: <OpenAccountScopeOutcome>[AccountScopeOpenedForAccount(scope)],
    );
    late ShellRuntime shell;
    shell = ShellRuntime(
      authentication: auth,
      privacy: privacy,
      intents: facilityShellBindings(() {
        return shell;
      }),
      contributions: facilityShellContributions(),
    );
    await shell.initialize();
    const ValidLocationReference location = ValidLocationReference(
      locationId: 'a',
      point: GeographicPoint(latitude: 3, longitude: 101),
    );
    expect(
      await shell.applicationShell!.submit(
        const OpenNearbyFacilitiesIntent(location: location),
      ),
      isA<ShellIntentAccepted>(),
    );
    expect(shell.state.routes.last.destination, 'nearby-facilities');
    final NearbyFacilitiesSummaryContribution contribution =
        NearbyFacilitiesSummaryContribution(
          location: location,
          outcome: const FacilityAnalysisUnavailable(
            failure: FacilityFailure.incompleteResponse,
          ),
          returnContext: shell.currentContext,
        );
    expect(
      await shell.applicationShell!.publish(contribution),
      isA<ShellContributionAccepted>(),
    );
    expect(shell.state.slots['nearby-facilities-summary'], same(contribution));
    shell.back();
    expect(
      await shell.applicationShell!.publish(contribution),
      isA<ShellContributionRejected>(),
    );
    shell.dispose();
    await auth.changes.close();
  });
}
