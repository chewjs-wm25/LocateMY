import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/l10n/language_controller.dart';
import 'package:locatemy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_authentication_session.dart';

void main() {
  test('both language bundles have complete matching resources', () {
    Set<String> keys(String locale) =>
        (jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
                as Map<String, dynamic>)
            .keys
            .where((key) => !key.startsWith('@'))
            .toSet();
    expect(keys('zh'), keys('en'));
  });

  test(
    'device preference defaults to Chinese and survives reconstruction',
    () async {
      SharedPreferences.setMockInitialValues({
        LanguageController.preferenceKey: 42,
      });
      final preferences = await SharedPreferences.getInstance();
      final controller = LanguageController(preferences: preferences);
      expect(controller.locale, const Locale('zh'));
      final first = controller.select('zh');
      final second = controller.select('en');
      expect(await first, isTrue);
      expect(await second, isTrue);
      final restored = LanguageController(preferences: preferences);
      expect(restored.locale, const Locale('en'));
      controller.dispose();
      restored.dispose();
    },
  );

  late FakeAuthenticationSession fake;
  late AuthenticationViewModel vm;
  late LanguageController language;
  setUp(() {
    fake = FakeAuthenticationSession();
    vm = createAuthenticationViewModel(fake);
    language = LanguageController();
  });
  tearDown(() async {
    vm.dispose();
    language.dispose();
    await fake.changes.close();
  });
  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(
      LocateMyApp(authenticationViewModel: vm, languageController: language),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('switching translates existing validation and preserves input', (
    tester,
  ) async {
    await launch(tester);
    await tester.enterText(find.byType(TextFormField).first, 'invalid');
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, '登录'));
    await tester.pumpAndSettle();
    expect(find.text('请输入有效的邮箱地址。'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('language-switch')));
    await tester.tap(find.byKey(const ValueKey('language-switch')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('请输入有效的邮箱地址。'), findsNothing);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      'secret123',
    );
    expect(fake.signInCalls, 0);
  });

  testWidgets('English registration feedback and confirmation are translated', (
    tester,
  ) async {
    await language.select('en');
    await launch(tester);
    await tester.ensureVisible(find.text('New here? Create an account'));
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'a@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.enterText(find.byType(TextFormField).at(3), 'other');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(3), 'password123');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Signed in'), findsOneWidget);
  });

  testWidgets('English registration fits small screen with 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await language.select('en');
    await launch(tester);
    await tester.ensureVisible(find.text('New here? Create an account'));
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create account'),
    );
    expect(tester.takeException(), isNull);
  });
}
