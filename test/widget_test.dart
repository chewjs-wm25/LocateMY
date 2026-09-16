import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/authentication_session/src/application/authentication_use_case.dart';
import 'package:locatemy/features/authentication_session/src/presentation/authentication_view_model.dart';
import 'package:locatemy/main.dart';

import 'support/fake_authentication_session.dart';

void main() {
  late FakeAuthenticationSession fake;
  late AuthenticationViewModel vm;
  setUp(() {
    fake = FakeAuthenticationSession();
    vm = AuthenticationViewModel(AuthenticationUseCase(fake));
  });
  tearDown(() async {
    vm.dispose();
    await fake.changes.close();
  });
  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(LocateMyApp(authenticationViewModel: vm));
    await tester.pumpAndSettle();
  }

  testWidgets('empty and malformed email are validated before submission', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'invalid');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(fake.signInCalls, 0);
  });

  testWidgets(
    'registration mismatch, verification and mode switch clear passwords',
    (tester) async {
      await launch(tester);
      await tester.tap(find.text('Need an account? Register'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'a@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'different');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pump();
      expect(find.text('Passwords do not match.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Check your email and verify your account before signing in.',
        ),
        findsOneWidget,
      );
      expect(find.text('Signed in'), findsNothing);
      await tester.tap(find.text('Already have an account? Sign in'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        isEmpty,
      );
      expect(find.text('Passwords do not match.'), findsNothing);
    },
  );

  testWidgets('signed in identity, confirmation and confirmed local sign out', (
    tester,
  ) async {
    fake.restored = const AuthenticatedSession(accountA);
    await launch(tester);
    expect(find.text('a@example.com'), findsOneWidget);
    expect(find.text('Email verified'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.tap(find.text('Sign out on this device'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('a@example.com'), findsOneWidget);
    await tester.tap(find.text('Sign out on this device'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('a@example.com'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('unknown confirmation is never displayed as verified', (
    tester,
  ) async {
    fake.restored = const AuthenticatedSession(
      AuthenticatedAccount(
        accountId: 'a',
        email: 'a@example.com',
        confirmation: EmailConfirmation.unavailable,
      ),
    );
    await launch(tester);
    expect(find.text('Email verification status unavailable'), findsOneWidget);
    expect(find.text('Email verified'), findsNothing);
  });

  testWidgets('unavailable session shows retry gate and no credentials', (
    tester,
  ) async {
    fake.restored = const SessionUnavailable(
      SessionFailure.retryableUnavailable,
    );
    await launch(tester);
    expect(find.text('Retry session'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    fake.restored = const UnauthenticatedSession();
    await tester.tap(find.text('Retry session'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets(
    'small screen and large text remain scrollable without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: LocateMyApp(authenticationViewModel: vm),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Need an account? Register'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Create account'),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
