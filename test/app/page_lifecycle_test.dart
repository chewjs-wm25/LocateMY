import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';

import '../support/fake_authentication_session.dart';

void main() {
  testWidgets(
    'login is required and account change disposes routes and dialogs',
    (WidgetTester tester) async {
      final FakeAuthenticationSession auth = FakeAuthenticationSession();
      final AuthenticationViewModel vm = createAuthenticationViewModel(auth);
      await tester.pumpWidget(
        LocateMyApp(
          authenticationViewModel: vm,
          signedInBuilder:
              (BuildContext context, AuthenticatedAccount account) {
                return Scaffold(
                  body: Column(
                    children: <Widget>[
                      Text('Owner ${account.accountId}'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) {
                                return Scaffold(
                                  body: TextButton(
                                    onPressed: () {
                                      showDialog<void>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return const AlertDialog(
                                            content: Text('Private draft A'),
                                          );
                                        },
                                      );
                                    },
                                    child: const Text('Open draft'),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        child: const Text('Private records'),
                      ),
                    ],
                  ),
                );
              },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Owner a'), findsNothing);
      expect(find.byType(AuthenticationPage), findsOneWidget);
      auth.changes.add(const AuthenticatedSession(accountA));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Private records'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open draft'));
      await tester.pumpAndSettle();
      expect(find.text('Private draft A'), findsOneWidget);
      auth.changes.add(const AuthenticatedSession(accountB));
      await tester.pumpAndSettle();
      expect(find.text('Owner b'), findsOneWidget);
      expect(find.text('Private draft A'), findsNothing);
      expect(find.text('Open draft'), findsNothing);
      await vm.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(AuthenticationPage), findsOneWidget);
      expect(find.text('Owner b'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
      await auth.changes.close();
    },
  );

  testWidgets(
    'Android system back returns from business route to signed-in home',
    (WidgetTester tester) async {
      final FakeAuthenticationSession auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final AuthenticationViewModel vm = createAuthenticationViewModel(auth);
      await tester.pumpWidget(
        LocateMyApp(
          authenticationViewModel: vm,
          signedInBuilder:
              (BuildContext context, AuthenticatedAccount account) {
                return Scaffold(
                  body: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) {
                            return const Scaffold(body: Text('Business route'));
                          },
                        ),
                      );
                    },
                    child: const Text('Signed-in home'),
                  ),
                );
              },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Signed-in home'));
      await tester.pumpAndSettle();
      expect(find.text('Business route'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Business route'), findsNothing);
      expect(find.text('Signed-in home'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
      await auth.changes.close();
    },
  );

  testWidgets('failed logout leaves current page and identity available', (
    WidgetTester tester,
  ) async {
    final FakeAuthenticationSession auth = FakeAuthenticationSession()
      ..restored = const AuthenticatedSession(accountA)
      ..signedOut = const SignOutRejected(SignOutFailure.retryableUnavailable);
    final AuthenticationViewModel vm = createAuthenticationViewModel(auth);
    await tester.pumpWidget(
      LocateMyApp(
        authenticationViewModel: vm,
        signedInBuilder: (BuildContext context, AuthenticatedAccount account) {
          return const Scaffold(body: Text('Current private page'));
        },
      ),
    );
    await tester.pumpAndSettle();
    await vm.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Current private page'), findsOneWidget);
    expect(vm.state.session, isA<AuthenticatedSession>());
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
    await auth.changes.close();
  });
}
