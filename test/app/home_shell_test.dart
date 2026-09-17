import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/home_relocation_outlook/home_relocation_outlook.dart';

import '../support/fake_authentication_session.dart';
import '../support/fake_home_relocation_outlook.dart';
import 'application_shell_test.dart' show ControlledPrivacy;

void main() {
  testWidgets(
    'opened Home explores map through production binding without selecting a location',
    (tester) async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final privacy = ControlledPrivacy();
      late ShellRuntime shell;
      shell = ShellRuntime.compose(
        authentication: auth,
        privacy: () => privacy,
        intents: [homeExploreMapBinding(() => shell)],
      );
      final home = FakeHomeRelocationOutlook(
        (_) async => HomeLoaded(snapshot: homeFixture()),
      );
      final authVm = createAuthenticationViewModel(auth);
      await tester.pumpWidget(
        LocateMyApp(
          authenticationViewModel: authVm,
          shellRuntime: shell,
          shellViews: ShellViews(
            home: (context, scoped) =>
                HomeOutlookPage(home: home, applicationShell: scoped),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(shell.state.gate, ShellGate.opened);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('home-explore')),
        400,
      );
      await tester.tap(find.byKey(const ValueKey('home-explore')));
      await tester.pumpAndSettle();
      expect(shell.state.selectedTab, ShellTab.map);
      expect(shell.state.routes, isEmpty);
      expect(shell.state.slots, isEmpty);
      await tester.pumpWidget(const SizedBox());
      authVm.dispose();
      await tester.runAsync(() async {
        await shell.dispose();
        await auth.changes.close();
      });
    },
  );
  testWidgets(
    'Home never reads before opened and a closed account ignores a late response',
    (tester) async {
      final auth = FakeAuthenticationSession();
      final privacy = ControlledPrivacy();
      late ShellRuntime shell;
      shell = ShellRuntime.compose(
        authentication: auth,
        privacy: () => privacy,
        intents: [homeExploreMapBinding(() => shell)],
      );
      final pending = Completer<HomeLoadOutcome>();
      var reads = 0;
      final views = homeShellViews(
        () => FakeHomeRelocationOutlook((_) {
          reads++;
          return reads == 1
              ? pending.future
              : Future.value(HomeLoaded(snapshot: homeFixture()));
        }),
      );
      final authVm = createAuthenticationViewModel(auth);
      await tester.pumpWidget(
        LocateMyApp(
          authenticationViewModel: authVm,
          shellRuntime: shell,
          shellViews: views,
        ),
      );
      await tester.pumpAndSettle();
      expect(reads, 0);
      auth.restored = const AuthenticatedSession(accountA);
      auth.changes.add(auth.restored);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(reads, 1);
      final oldShell = shell.applicationShell!;
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
      expect(reads, 2);
      expect(shell.state.scope!.accountId, 'b');
      pending.complete(
        HomeLoaded(
          snapshot: homeFixture(
            freshness: HomeDataFreshness.stale,
            partial: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Expired cached data'), findsNothing);
      expect(
        await oldShell.submit(const ExploreMapIntent()),
        isA<ShellAuthenticationRequired>(),
      );
      expect(shell.state.selectedTab, ShellTab.home);
      await tester.pumpWidget(const SizedBox());
      authVm.dispose();
      await tester.runAsync(() async {
        await shell.dispose();
        await auth.changes.close();
      });
    },
  );
}
