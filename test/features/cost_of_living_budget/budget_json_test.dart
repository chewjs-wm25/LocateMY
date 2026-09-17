import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart';

final class SavedStore implements BudgetScenarioStore {
  final BudgetScenario scenario = BudgetScenario(
    id: 'saved',
    name: 'My budget',
    housingExpenseRm: 0,
    isCurrent: true,
    updatedAt: DateTime.utc(2026),
    version: 1,
  );
  @override
  Future<BudgetScenariosOutcome> read() async {
    return BudgetScenariosAvailable(
      scenarios: <BudgetScenario>[scenario],
      current: CurrentBudgetScenarioAvailable(scenario: scenario, version: 1),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('No cloud mutation permitted');
  }
}

void main() {
  test('saved budget exports real copies with null and zero; reopening never writes account', () async {
    final Directory root = await Directory.systemTemp.createTemp('budget-test');
    try {
      final BudgetJsonFiles files = createBudgetJsonFiles(
        budgetStore: SavedStore(),
        directory: () async {
          return root;
        },
      );
      final BudgetScenario scenario = BudgetScenario(
        id: 'saved',
        name: 'My budget',
        housingExpenseRm: 0,
        isCurrent: true,
        updatedAt: DateTime.utc(2026),
        version: 1,
      );
      final BudgetJsonExported exported =
          await files.exportSaved(scenario) as BudgetJsonExported;
      expect(await File(exported.file.path).exists(), true);
      final Map<String, dynamic> json = jsonDecode(
        await File(exported.file.path).readAsString(),
      ) as Map<String, dynamic>;
      expect((json['scenario'] as Map)['transport_rm'], isNull);
      expect((json['scenario'] as Map)['housing_rm'], 0);
      expect(json.containsKey('user_id'), false);
      final BudgetJsonAvailable opened =
          await files.open(exported.file.path) as BudgetJsonAvailable;
      expect(opened.copy.scenario.isCurrent, false);
      expect((await files.list()).length, 1);
      final BudgetJsonFiles reopened = createBudgetJsonFiles(
        budgetStore: SavedStore(),
        directory: () async {
          return root;
        },
      );
      expect((await reopened.list()).length, 1);
    } finally {
      await root.delete(recursive: true);
    }
  });
  test('real corrupted missing unsupported and invalid-date copies fail without cloud mutation', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'budget-errors',
    );
    try {
      final BudgetJsonFiles files = createBudgetJsonFiles(
        budgetStore: SavedStore(),
        directory: () async {
          return root;
        },
      );
      final BudgetJsonExported exported =
          await files.exportSaved(SavedStore().scenario) as BudgetJsonExported;
      final File file = File(exported.file.path);
      final String original = await file.readAsString();
      final List<String> corruptions = <String>[
        '{',
        original.replaceFirst('"version": 1', '"version": 99'),
        original.replaceFirst('"housing_rm": 0.0,', ''),
        original.replaceFirst('"housing_rm": 0.0', '"housing_rm": -1'),
        original.replaceFirst('"exported_at": "', '"exported_at": "invalid-'),
      ];
      for (int i = 0; i < corruptions.length; i++) {
        await file.writeAsString(corruptions[i]);
        final BudgetJsonFailed result =
            await files.open(file.path) as BudgetJsonFailed;
        expect(
          result.failure,
          i == 1
              ? BudgetJsonFailure.unsupportedVersion
              : BudgetJsonFailure.readFailed,
        );
      }
      await file.delete();
      expect(await files.open(file.path), isA<BudgetJsonFailed>());
    } finally {
      await root.delete(recursive: true);
    }
  });
}
