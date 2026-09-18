// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart';
import 'package:locatemy/l10n/app_localizations.dart';

import 'cost_production_test.dart' show BudgetReader, Prices;
import '../infrastructure_coverage/infrastructure_behavior_test.dart'
    show GeoFixture, location;

void main() {
  testWidgets(
    'queued current observation after page disposal starts no request or notification',
    (WidgetTester tester) async {
      final LateCurrentReader current = LateCurrentReader();
      final CountingPrices prices = CountingPrices();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CostBudgetPage(
            location: location,
            service: createCostOfLivingBudget(
              geographicContext: GeoFixture(),
              reader: prices,
            ),
            currentBudget: current,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(prices.requests, 1);
      await tester.pumpWidget(const SizedBox());
      current.events.deliverAlreadyQueued(
        BudgetScenariosAvailable(
          scenarios: <BudgetScenario>[],
          current: const NoCurrentBudgetScenario(version: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(prices.requests, 1);
    },
  );
  testWidgets(
    'Chinese cost report separates unitless index from monthly money and offers temporary input',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CostBudgetPage(
            location: location,
            service: createCostOfLivingBudget(
              geographicContext: GeoFixture(),
              reader: Prices(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('生活成本'), findsOneWidget);
      expect(find.text('200.0'), findsOneWidget);
      expect(find.text('RM 430.00 /月'), findsOneWidget);
      expect(find.text('本地商品单价'), findsNothing);
      expect(find.byKey(const ValueKey<String>('cpi-input')), findsOneWidget);
    },
  );
  testWidgets(
    'Chinese partial basket report shows index, item count and partial pressure label',
    (WidgetTester tester) async {
      final Prices prices = Prices();
      prices.baselineMissing = true;
      final BudgetReader budget = BudgetReader();
      budget.scenario = BudgetScenario(
        id: 'partial',
        name: 'Partial',
        housingExpenseRm: 100,
        transportExpenseRm: 0,
        monthlyNetIncomeRm: 1000,
        isCurrent: true,
        updatedAt: DateTime.utc(2026),
        version: 1,
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CostBudgetPage(
            location: location,
            service: createCostOfLivingBudget(
              geographicContext: GeoFixture(),
              reader: prices,
              budget: budget,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('部分篮子指数'), findsOneWidget);
      expect(find.textContaining('可观测项目 10 / 11'), findsOneWidget);
      expect(find.textContaining('资料不完整：部分篮子指数'), findsOneWidget);
      expect(find.textContaining('部分篮子个人预算压力'), findsOneWidget);
      expect(find.text('200.0'), findsOneWidget);
      expect(find.text('部分篮子个人预算压力: 45.0%'), findsOneWidget);
    },
  );
  testWidgets(
    'unchanged current observation preserves bottom scrolling and typed temporary input',
    (WidgetTester tester) async {
      final StreamController<BudgetScenariosOutcome> events =
          StreamController<BudgetScenariosOutcome>.broadcast();
      final CurrentEvents reader = CurrentEvents(events);
      final Prices slow = Prices();
      slow.delay = const Duration(milliseconds: 100);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CostBudgetPage(
            location: location,
            service: createCostOfLivingBudget(
              geographicContext: GeoFixture(),
              reader: slow,
            ),
            currentBudget: reader,
          ),
        ),
      );
      await tester.pumpAndSettle();
      events.add(
        BudgetScenariosAvailable(
          scenarios: <BudgetScenario>[],
          current: const NoCurrentBudgetScenario(version: 0),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('cpi-input')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('cpi-input')),
        '1000',
      );
      final double before = tester
          .getTopLeft(find.byKey(const ValueKey<String>('cpi-input')))
          .dy;
      events.add(
        BudgetScenariosAvailable(
          scenarios: <BudgetScenario>[],
          current: const NoCurrentBudgetScenario(version: 0),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey<String>('cpi-input'))).dy,
        before,
      );
      expect(find.text('1000'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await events.close();
    },
  );
}

final class CurrentEvents implements CurrentBudgetReader {
  final StreamController<BudgetScenariosOutcome> events;
  CurrentEvents(StreamController<BudgetScenariosOutcome> events)
    : events = events;
  @override
  Stream<BudgetScenariosOutcome> watchCurrent() {
    return events.stream;
  }

  @override
  Future<BudgetScenariosOutcome> readCurrent() async {
    return BudgetScenariosAvailable(
      scenarios: <BudgetScenario>[],
      current: const NoCurrentBudgetScenario(version: 0),
    );
  }
}

final class CountingPrices implements CostPublicReader {
  final Prices _prices = Prices();
  int requests = 0;
  @override
  Future<Map<String, Object?>> read(String state, String district) {
    requests++;
    return _prices.read(state, district);
  }
}

// External current stream seam: cancellation cannot retract a callback that a
// source has already queued. Deliver that callback after the page leaves.
final class LateCurrentStream extends Stream<BudgetScenariosOutcome> {
  void Function(BudgetScenariosOutcome)? _queued;
  @override
  StreamSubscription<BudgetScenariosOutcome> listen(
    void Function(BudgetScenariosOutcome)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _queued = onData;
    return const Stream<BudgetScenariosOutcome>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  void deliverAlreadyQueued(BudgetScenariosOutcome event) {
    _queued!(event);
  }
}

final class LateCurrentReader implements CurrentBudgetReader {
  final LateCurrentStream events = LateCurrentStream();
  @override
  Stream<BudgetScenariosOutcome> watchCurrent() {
    return events;
  }

  @override
  Future<BudgetScenariosOutcome> readCurrent() async {
    return BudgetScenariosAvailable(
      scenarios: <BudgetScenario>[],
      current: const NoCurrentBudgetScenario(version: 0),
    );
  }
}
