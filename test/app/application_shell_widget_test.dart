import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/src/application/authentication_use_case.dart';

import '../support/fake_authentication_session.dart';
import 'application_shell_test.dart'
    show ControlledPrivacy, AnalysisIntent, DetailContribution;

import 'package:locatemy/app/application_shell.dart';

void main() {
  testWidgets(
    'opened Shell has two stateful tabs and a returning account task',
    (tester) async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final shell = ShellRuntime(
        authentication: auth,
        privacy: ControlledPrivacy(),
      );
      final vm = AuthenticationViewModel(AuthenticationUseCase(auth));
      await tester.pumpWidget(
        LocateMyApp(
          authenticationViewModel: vm,
          shellRuntime: shell,
          shellViews: ShellViews(
            home: (_, _) => const CounterPage(),
            map: (_, _) => const Text('map fixture'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationDestination), findsNWidgets(2));
      await tester.tap(find.text('count 0'));
      await tester.pump();
      await tester.tap(find.text('地图'));
      await tester.pumpAndSettle();
      expect(find.text('map fixture'), findsOneWidget);
      await tester.tap(find.text('首页'));
      await tester.pumpAndSettle();
      expect(find.text('count 1'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('shell-account')));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('count 1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
      await tester.runAsync(() async {
        await shell.dispose();
        await auth.changes.close();
      });
    },
  );
  testWidgets(
    'session invalidation removes private task dialogs and keeps language',
    (tester) async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final shell = ShellRuntime(
        authentication: auth,
        privacy: ControlledPrivacy(),
      );
      final vm = AuthenticationViewModel(AuthenticationUseCase(auth));
      await tester.pumpWidget(
        LocateMyApp(authenticationViewModel: vm, shellRuntime: shell),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language-switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('shell-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out of this device'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      auth.restored = const UnauthenticatedSession();
      auth.changes.add(const UnauthenticatedSession());
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Sign in'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
      await tester.runAsync(() async {
        await shell.dispose();
        await auth.changes.close();
      });
    },
  );

  testWidgets(
    'task receives original ordered input and presents provider contribution',
    (tester) async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final shell = ShellRuntime(
        authentication: auth,
        privacy: ControlledPrivacy(),
        intents: [
          ShellIntentBinding<AnalysisIntent>(
            (input) => ShellRouteRequest.task(
              context: input.context,
              destination: 'analysis',
            ),
          ),
        ],
        contributions: [
          ShellContributionBinding<DetailContribution>(
            (input) =>
                ShellSlotRequest(context: input.context, slot: input.source),
          ),
        ],
      );
      final vm = AuthenticationViewModel(AuthenticationUseCase(auth));
      await tester.pumpWidget(
        LocateMyApp(
          authenticationViewModel: vm,
          shellRuntime: shell,
          shellViews: ShellViews(
            tasks: [
              ShellTaskView<AnalysisIntent>(
                'analysis',
                (_, input) => Text(input.locations.join(' → ')),
              ),
            ],
            contributions: [
              ShellContributionView<DetailContribution>(
                (_, input) => Text('${input.availability} | ${input.source}'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        await shell.submit(
          AnalysisIntent(shell.currentContext!, const ['B', 'A']),
        ),
        isA<ShellIntentAccepted>(),
      );
      await tester.pumpAndSettle();
      expect(find.text('B → A'), findsOneWidget);
      await shell.publish(
        DetailContribution(
          shell.currentContext!,
          'unavailable',
          'official / 2025 / state',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('unavailable | official / 2025 / state'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
      await tester.runAsync(() async {
        await shell.dispose();
        await auth.changes.close();
      });
    },
  );

  for (final english in [false, true]) {
    testWidgets(
      'small screen 200% text and recovery remain accessible (${english ? 'en' : 'zh'})',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final semantics = tester.ensureSemantics();

        final auth = FakeAuthenticationSession()
          ..restored = const AuthenticatedSession(accountA);
        final privacy = ControlledPrivacy();
        final shell = ShellRuntime(authentication: auth, privacy: privacy);
        final vm = AuthenticationViewModel(AuthenticationUseCase(auth));
        await tester.pumpWidget(
          LocateMyApp(authenticationViewModel: vm, shellRuntime: shell),
        );
        await tester.pumpAndSettle();
        if (english) {
          await tester.tap(find.byKey(const ValueKey('language-switch')));
          await tester.pumpAndSettle();
        }
        expect(find.byTooltip(english ? 'Account' : '账户'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('shell-account')));
        await tester.pumpAndSettle();
        final scope = shell.state.scope!;
        privacy.pendingClose = Future.value(
          AccountScopeCloseIncomplete(scope, [
            PrivateStateClearIncomplete(
              AccountPrivacyParticipantId.propertyInspection,
              scope,
              PrivateStateClearFailure.fileCleanupIncomplete,
            ),
          ]),
        );
        await shell.signOut();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(english ? 'Retry' : '重试'));
        expect(find.byType(NavigationBar), findsNothing);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('language-switch')), findsOneWidget);
        semantics.dispose();
        await tester.pumpWidget(const SizedBox());
        vm.dispose();
        await tester.runAsync(() async {
          await shell.dispose();
          await auth.changes.close();
        });
      },
    );
  }
  testWidgets(
    'Auth rejection after scope closes reports the real sign-out failure',
    (tester) async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final shell = ShellRuntime(
        authentication: auth,
        privacy: ControlledPrivacy(),
      );
      final vm = AuthenticationViewModel(AuthenticationUseCase(auth));
      await tester.pumpWidget(
        LocateMyApp(authenticationViewModel: vm, shellRuntime: shell),
      );
      await tester.pumpAndSettle();
      auth.signedOut = const SignOutRejected(SignOutFailure.remoteRejected);
      await shell.signOut();
      await tester.pumpAndSettle();
      expect(find.text('退出请求被拒绝，请重试或联系支持。'), findsOneWidget);
      expect(find.text('旧账户清理尚未完成，私有内容已关闭。请重试完成清理。'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
      await tester.runAsync(() async {
        await shell.dispose();
        await auth.changes.close();
      });
    },
  );
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});
  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int count = 0;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => count++),
    child: Text('count $count'),
  );
}
