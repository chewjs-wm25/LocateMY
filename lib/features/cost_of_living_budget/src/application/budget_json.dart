// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../cost_of_living_budget.dart';

abstract interface class BudgetJsonFiles {
  Future<BudgetJsonOutcome> exportSaved(BudgetScenario scenario);
  Future<List<BudgetJsonFile>> list();
  Future<BudgetJsonOutcome> open(String path);
}

final class BudgetJsonFile {
  final String path;
  final String name;
  const BudgetJsonFile({required String path, required String name})
    : path = path,
      name = name;
}

final class BudgetExportCopy {
  final BudgetScenario scenario;
  final DateTime exportedAt;
  const BudgetExportCopy({
    required BudgetScenario scenario,
    required DateTime exportedAt,
  }) : scenario = scenario,
       exportedAt = exportedAt;
}

sealed class BudgetJsonOutcome {
  const BudgetJsonOutcome();
}

final class BudgetJsonExported extends BudgetJsonOutcome {
  final BudgetJsonFile file;
  const BudgetJsonExported(BudgetJsonFile file) : file = file;
}

final class BudgetJsonAvailable extends BudgetJsonOutcome {
  final BudgetExportCopy copy;
  const BudgetJsonAvailable(BudgetExportCopy copy) : copy = copy;
}

final class BudgetJsonFailed extends BudgetJsonOutcome {
  final BudgetJsonFailure failure;
  const BudgetJsonFailed(BudgetJsonFailure failure) : failure = failure;
}

enum BudgetJsonFailure {
  readFailed,
  exportFailed,
  unsupportedVersion,
  notSaved,
}

BudgetJsonFiles createBudgetJsonFiles({
  required BudgetScenarioStore budgetStore,
  Future<Directory> Function()? directory,
  DateTime Function()? clock,
}) {
  return LocalBudgetJsonFiles(
    budgetStore,
    directory ?? getApplicationDocumentsDirectory,
    clock ?? DateTime.now,
  );
}

final class LocalBudgetJsonFiles implements BudgetJsonFiles {
  final BudgetScenarioStore _store;
  final Future<Directory> Function() _directory;
  final DateTime Function() _clock;
  int _sequence = 0;
  LocalBudgetJsonFiles(
    BudgetScenarioStore store,
    Future<Directory> Function() directory,
    DateTime Function() clock,
  ) : _store = store,
      _directory = directory,
      _clock = clock;
  Future<Directory> _root() async {
    final Directory parent = await _directory();
    return Directory('${parent.path}/budget_exports').create(recursive: true);
  }

  @override
  Future<BudgetJsonOutcome> exportSaved(BudgetScenario scenario) async {
    try {
      final BudgetScenariosOutcome outcome = await _store.read();
      BudgetScenario? saved;
      if (outcome is BudgetScenariosAvailable) {
        for (final BudgetScenario row in outcome.scenarios) {
          if (row.id == scenario.id) {
            saved = row;
            break;
          }
        }
      }
      if (saved == null) {
        return const BudgetJsonFailed(BudgetJsonFailure.notSaved);
      }
      final DateTime now = _clock().toUtc();
      final Directory root = await _root();
      final String id = saved.id.replaceAll(RegExp('[^A-Za-z0-9_-]'), '_');
      File file;
      do {
        _sequence++;
        file = File(
          '${root.path}/$id-${now.microsecondsSinceEpoch}-$_sequence.json',
        );
      } while (await file.exists());
      final Map<String, Object?> data = <String, Object?>{
        'format': 'locatemy-budget-scenario',
        'version': 1,
        'exported_at': now.toIso8601String(),
        'scenario': <String, Object?>{
          'id': saved.id,
          'name': saved.name,
          'extra_living_expenses_rm': saved.additionalLivingExpenseRm,
          'housing_rm': saved.housingExpenseRm,
          'transport_rm': saved.transportExpenseRm,
          'monthly_net_income_rm': saved.monthlyNetIncomeRm,
          'household_monthly_gross_income_rm': saved.householdMonthlyIncomeRm,
        },
      };
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
        encoding: utf8,
        flush: true,
      );
      return BudgetJsonExported(
        BudgetJsonFile(path: file.path, name: file.uri.pathSegments.last),
      );
    } catch (_) {
      return const BudgetJsonFailed(BudgetJsonFailure.exportFailed);
    }
  }

  @override
  Future<List<BudgetJsonFile>> list() async {
    final Directory root = await _root();
    final List<BudgetJsonFile> result = <BudgetJsonFile>[];
    await for (final FileSystemEntity entity in root.list(followLinks: false)) {
      if (entity is File && entity.path.endsWith('.json')) {
        result.add(
          BudgetJsonFile(path: entity.path, name: entity.uri.pathSegments.last),
        );
      }
    }
    result.sort((BudgetJsonFile a, BudgetJsonFile b) {
      return b.name.compareTo(a.name);
    });
    return List<BudgetJsonFile>.unmodifiable(result);
  }

  @override
  Future<BudgetJsonOutcome> open(String path) async {
    try {
      final Directory root = await _root();
      final File file = File(path);
      // No external path or symlink import: this is an application export viewer.
      final String resolved = await file.resolveSymbolicLinks();
      final String actualRoot = await root.resolveSymbolicLinks();
      if (!resolved.startsWith('$actualRoot/')) {
        return const BudgetJsonFailed(BudgetJsonFailure.readFailed);
      }
      final Object? decoded = jsonDecode(
        await file.readAsString(encoding: utf8),
      );
      if (decoded is! Map || decoded['format'] != 'locatemy-budget-scenario') {
        return const BudgetJsonFailed(BudgetJsonFailure.readFailed);
      }
      if (decoded['version'] is! int) {
        return const BudgetJsonFailed(BudgetJsonFailure.readFailed);
      }
      if (decoded['version'] != 1) {
        return const BudgetJsonFailed(BudgetJsonFailure.unsupportedVersion);
      }
      final Object? date = decoded['exported_at'];
      if (date is! String ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$')
              .hasMatch(date)) {
        throw const FormatException('Invalid date');
      }
      final DateTime exported = DateTime.parse(date);
      final String canonical = exported.toUtc().toIso8601String();
      // DateTime.parse normalizes impossible dates; compare the calendar portion.
      if (canonical.substring(0, 19) != date.substring(0, 19)) {
        throw const FormatException('Invalid date');
      }
      final Object? raw = decoded['scenario'];
      if (raw is! Map ||
          raw['id'] is! String ||
          (raw['id'] as String).trim().isEmpty ||
          raw['name'] is! String ||
          (raw['name'] as String).trim().isEmpty ||
          (raw['name'] as String).length > 120) {
        throw const FormatException('Invalid scenario');
      }
      double? amount(String key) {
        if (!raw.containsKey(key)) {
          throw const FormatException('Missing field');
        }
        final Object? value = raw[key];
        if (value == null) {
          return null;
        }
        if (value is! num || !value.toDouble().isFinite || value < 0) {
          throw const FormatException('Invalid amount');
        }
        return value.toDouble();
      }

      return BudgetJsonAvailable(
        BudgetExportCopy(
          exportedAt: exported,
          scenario: BudgetScenario(
            id: raw['id'] as String,
            name: raw['name'] as String,
            additionalLivingExpenseRm: amount('extra_living_expenses_rm'),
            housingExpenseRm: amount('housing_rm'),
            transportExpenseRm: amount('transport_rm'),
            monthlyNetIncomeRm: amount('monthly_net_income_rm'),
            householdMonthlyIncomeRm: amount(
              'household_monthly_gross_income_rm',
            ),
            isCurrent: false,
            updatedAt: exported,
            version: 1,
          ),
        ),
      );
    } catch (_) {
      return const BudgetJsonFailed(BudgetJsonFailure.readFailed);
    }
  }
}
