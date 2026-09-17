import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart';
import 'package:locatemy/l10n/app_localizations.dart';

import 'budget_json_test.dart' show SavedStore;

void main() {
  testWidgets('export success and open action are immediately visible', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final Directory root = Directory.systemTemp.createTempSync('budget-page');
    addTearDown(() async {
      await root.delete(recursive: true);
    });
    final BudgetScenarioStore store = ManySavedStore();
    final BudgetJsonFiles files = createBudgetJsonFiles(
      budgetStore: store,
      directory: () async {
        return root;
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BudgetScenariosPage(store: store, files: files),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Export JSON').first);
    await tester.runAsync(() async {
      await tester.tap(find.text('Export JSON').first);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(
      find.text('Export saved on this device').hitTestable(),
      findsOneWidget,
    );
    expect(find.text('Open exported copy').hitTestable(), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Open exported copy'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(find.text('My budget'), findsOneWidget);
    expect(
      find.text(
        'Exported copy. Does not select a current scenario or write to cloud.',
      ),
      findsOneWidget,
    );
  });
  testWidgets(
    'budget editor localizes validation and preserves input at 200 percent',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final ValueNotifier<Locale> locale = ValueNotifier<Locale>(
        const Locale('zh'),
      );
      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: locale,
          builder: (BuildContext context, Locale language, Widget? child) {
            return MaterialApp(
              locale: language,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (BuildContext context, Widget? child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: const Size(360, 640),
                    textScaler: const TextScaler.linear(2),
                  ),
                  child: child!,
                );
              },
              home: BudgetEditorPage(store: SavedStore()),
            );
          },
        ),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('budget-save')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('budget-save')));
      await tester.pumpAndSettle();
      expect(find.text('请输入 1–120 个字符'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey<String>('budget-field-0')),
        'Preserved',
      );
      locale.value = const Locale('en');
      await tester.pumpAndSettle();
      expect(find.text('Preserved'), findsOneWidget);
      expect(find.text('Enter 1–120 characters'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('budget-field-2')),
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('budget-field-2')),
        '-1',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('budget-save')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('budget-save')));
      await tester.pumpAndSettle();
      expect(find.text('Enter a finite nonnegative amount'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      locale.dispose();
    },
  );
}

final class ManySavedStore implements BudgetScenarioStore {
  @override
  Future<BudgetScenariosOutcome> read() async {
    final List<BudgetScenario> scenarios = <BudgetScenario>[
      SavedStore().scenario,
    ];
    for (int i = 0; i < 5; i++) {
      scenarios.add(
        BudgetScenario(
          id: 'other-$i',
          name: 'Other $i',
          isCurrent: false,
          updatedAt: DateTime.utc(2026),
          version: 1,
        ),
      );
    }
    return BudgetScenariosAvailable(
      scenarios: scenarios,
      current: const NoCurrentBudgetScenario(version: 1),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('No cloud writes permitted');
  }
}
