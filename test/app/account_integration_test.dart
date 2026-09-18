// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/account_center/account_center.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart';
import 'package:locatemy/l10n/app_localizations.dart';
import 'package:locatemy/l10n/language_controller.dart';
import 'package:provider/provider.dart';

import '../support/fake_authentication_session.dart';
import '../features/cost_of_living_budget/budget_json_test.dart'
    show SavedStore;

void main() {
  for (final String language in <String>['en', 'zh']) {
    testWidgets(
      'account journeys, budget updates and failed logout at 320px 200% in $language',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final FakeAuthenticationSession auth = FakeAuthenticationSession();
        auth.restored = const AuthenticatedSession(accountA);
        auth.signedOut = const SignOutRejected(
          SignOutFailure.retryableUnavailable,
        );
        final AuthenticationViewModel model = createAuthenticationViewModel(
          auth,
        );
        model.initialize();
        final LanguageController languages = LanguageController();
        final BudgetReader reader = BudgetReader();
        await tester.pumpWidget(
          ChangeNotifierProvider<LanguageController>.value(
            value: languages,
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (BuildContext context, Widget? child) {
                return MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                );
              },
              home: Scaffold(
                body: Builder(
                  builder: (BuildContext context) {
                    void open(String title) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) {
                            return Scaffold(
                              appBar: AppBar(),
                              body: Text(title),
                            );
                          },
                        ),
                      );
                    }

                    return AccountCenterPage(
                      authentication: model,
                      currentBudget: reader,
                      budgetStore: SavedStore(),
                      onMyHazards: () {
                        open('Hazard records');
                      },
                      onPropertyPortfolio: () {
                        open('Property records');
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('a@example.com'), findsOneWidget);
        for (final String key in <String>[
          'account-my-hazards',
          'account-property-portfolio',
        ]) {
          await tester.ensureVisible(find.byKey(ValueKey<String>(key)));
          await tester.tap(find.byKey(ValueKey<String>(key)));
          await tester.pumpAndSettle();
          expect(
            find.text(
              key == 'account-my-hazards'
                  ? 'Hazard records'
                  : 'Property records',
            ),
            findsOneWidget,
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
        }
        reader.events.add(
          BudgetScenariosAvailable(
            scenarios: <BudgetScenario>[reader.scenario],
            current: CurrentBudgetScenarioAvailable(
              scenario: reader.scenario,
              version: 1,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.textContaining(language == 'zh' ? '住房支出:' : 'Housing expense:'),
        );
        expect(find.textContaining('RM 0.00'), findsOneWidget);
        expect(
          find.textContaining(
            language == 'zh' ? '交通支出: 未填写' : 'Transport expense: Not provided',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('account-current-budget')),
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('account-current-budget')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(BudgetScenariosPage), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        reader.events.add(
          const BudgetScenariosUnavailable(
            BudgetScenarioFailure.retryableUnavailable,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            language == 'zh' ? '暂无法读取当前预案' : 'Unable to read current scenario',
          ),
          findsOneWidget,
        );
        final String signOut = language == 'zh'
            ? '退出当前设备'
            : 'Sign out of this device';
        auth.pendingSignOut = Completer<SignOutOutcome>().future;
        await tester.ensureVisible(find.text(signOut));
        await tester.tap(find.text(signOut));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.widgetWithText(TextButton, language == 'zh' ? '取消' : 'Cancel'),
        );
        await tester.tap(
          find.widgetWithText(TextButton, language == 'zh' ? '取消' : 'Cancel'),
        );
        await tester.pumpAndSettle();
        expect(model.state.isSigningOut, isFalse);
        expect(model.state.session, isA<AuthenticatedSession>());
        auth.pendingSignOut = null;
        await tester.ensureVisible(find.text(signOut));
        await tester.tap(find.text(signOut));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.widgetWithText(
            FilledButton,
            language == 'zh' ? '退出' : 'Sign out',
          ),
        );
        await tester.tap(
          find.widgetWithText(
            FilledButton,
            language == 'zh' ? '退出' : 'Sign out',
          ),
        );
        await tester.pumpAndSettle();
        expect(model.state.session, isA<AuthenticatedSession>());
        expect(find.text('a@example.com'), findsOneWidget);
        expect(tester.takeException(), isNull);
        auth.signedOut = const SignOutSucceeded();
        await tester.ensureVisible(find.text(signOut));
        await tester.tap(find.text(signOut));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.widgetWithText(
            FilledButton,
            language == 'zh' ? '退出' : 'Sign out',
          ),
        );
        await tester.tap(
          find.widgetWithText(
            FilledButton,
            language == 'zh' ? '退出' : 'Sign out',
          ),
        );
        await tester.pumpAndSettle();
        expect(model.state.session, isA<UnauthenticatedSession>());
        expect(find.text('a@example.com'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        model.dispose();
        languages.dispose();
        await reader.events.close();
        await auth.changes.close();
      },
    );
  }
}

final class BudgetReader implements CurrentBudgetReader {
  final StreamController<BudgetScenariosOutcome> events =
      StreamController<BudgetScenariosOutcome>.broadcast();
  final BudgetScenario scenario = BudgetScenario(
    id: 'zero',
    name: 'Zero housing',
    housingExpenseRm: 0,
    monthlyNetIncomeRm: 3500,
    householdMonthlyIncomeRm: 8000,
    isCurrent: true,
    updatedAt: DateTime.utc(2026),
    version: 1,
  );
  @override
  Future<BudgetScenariosOutcome> readCurrent() async {
    return BudgetScenariosAvailable(
      scenarios: <BudgetScenario>[],
      current: const NoCurrentBudgetScenario(version: 0),
    );
  }

  @override
  Stream<BudgetScenariosOutcome> watchCurrent() {
    return events.stream;
  }
}
