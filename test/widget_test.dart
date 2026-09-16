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
    await tester.tap(find.widgetWithText(FilledButton, '登录'));
    await tester.pump();
    expect(find.text('请输入邮箱。'), findsOneWidget);
    expect(find.text('请输入密码。'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'invalid');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.widgetWithText(FilledButton, '登录'));
    await tester.pump();
    expect(find.text('请输入有效的邮箱地址。'), findsOneWidget);
    expect(fake.signInCalls, 0);
  });

  testWidgets(
    'registration mismatch, verification and mode switch clear passwords',
    (tester) async {
      await launch(tester);
      await tester.ensureVisible(find.text('还没有账户？创建账户'));
      await tester.tap(find.text('还没有账户？创建账户'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'a@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'different');
      await tester.ensureVisible(find.widgetWithText(FilledButton, '创建账户'));
      await tester.tap(find.widgetWithText(FilledButton, '创建账户'));
      await tester.pump();
      expect(find.text('两次输入的密码不一致。'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.ensureVisible(find.widgetWithText(FilledButton, '创建账户'));
      await tester.tap(find.widgetWithText(FilledButton, '创建账户'));
      await tester.pumpAndSettle();
      expect(find.text('请查看邮件，完成邮箱验证后再登录。'), findsOneWidget);
      expect(find.text('已登录'), findsNothing);
      await tester.ensureVisible(find.text('已有账户？登录'));
      await tester.tap(find.text('已有账户？登录'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        isEmpty,
      );
      expect(find.text('两次输入的密码不一致。'), findsNothing);
    },
  );

  testWidgets('signed in identity, confirmation and confirmed local sign out', (
    tester,
  ) async {
    fake.restored = const AuthenticatedSession(accountA);
    await launch(tester);
    expect(find.text('a@example.com'), findsOneWidget);
    expect(find.text('邮箱已验证'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.tap(find.text('退出当前设备'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('a@example.com'), findsOneWidget);
    await tester.tap(find.text('退出当前设备'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '退出'));
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
    expect(find.text('邮箱验证状态暂不可用'), findsOneWidget);
    expect(find.text('邮箱已验证'), findsNothing);
  });

  testWidgets('unavailable session shows retry gate and no credentials', (
    tester,
  ) async {
    fake.restored = const SessionUnavailable(
      SessionFailure.retryableUnavailable,
    );
    await launch(tester);
    expect(find.text('重试'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    fake.restored = const UnauthenticatedSession();
    await tester.tap(find.text('重试'));
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
      await tester.ensureVisible(find.text('还没有账户？创建账户'));
      await tester.tap(find.text('还没有账户？创建账户'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilledButton, '创建账户'));
      expect(tester.takeException(), isNull);
    },
  );
}
