// Explicit field initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../cost_of_living_budget.dart';

final class SupabaseBudgetScenarioStore
    implements BudgetScenarioStore, CurrentBudgetReader {
  final SupabaseClient _client;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  SupabaseBudgetScenarioStore(SupabaseClient client) : _client = client;
  @override
  Future<BudgetScenariosOutcome> read() async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('user_budget_scenarios')
          .select(
            'id,scenario_name,basket_adjustment,housing_expense,transport_expense,monthly_net_income,household_monthly_gross_income_rm,is_current,updated_at',
          )
          .order('updated_at', ascending: false)
          .timeout(const Duration(seconds: 20));
      final List<BudgetScenario> scenarios = <BudgetScenario>[];
      BudgetScenario? selected;
      for (final Map<String, dynamic> row in rows) {
        final BudgetScenario scenario = decodeBudgetRow(row);
        scenarios.add(scenario);
        if (scenario.isCurrent) {
          if (selected != null) {
            return const BudgetScenariosUnavailable(
              BudgetScenarioFailure.conflict,
            );
          }
          selected = scenario;
        }
      }
      return BudgetScenariosAvailable(
        scenarios: List<BudgetScenario>.unmodifiable(scenarios),
        current: _current(selected),
      );
    } catch (error) {
      return BudgetScenariosUnavailable(_failure(error));
    }
  }

  CurrentBudgetScenarioSnapshot _current(BudgetScenario? scenario) {
    if (scenario == null) {
      return const NoCurrentBudgetScenario(version: 0);
    }
    return CurrentBudgetScenarioAvailable(
      scenario: scenario,
      version: scenario.version,
    );
  }

  @override
  Future<BudgetScenariosOutcome> readCurrent() {
    return read();
  }

  @override
  Stream<BudgetScenariosOutcome> watchCurrent() {
    return watch();
  }

  @override
  Stream<BudgetScenariosOutcome> watch() {
    late StreamController<BudgetScenariosOutcome> controller;
    Timer? timer;
    StreamSubscription<void>? subscription;
    bool reading = false;
    bool pending = false;
    Future<void> refresh() async {
      if (controller.isClosed) {
        return;
      }
      if (reading) {
        pending = true;
        return;
      }
      reading = true;
      final BudgetScenariosOutcome outcome = await read();
      reading = false;
      if (!controller.isClosed) {
        controller.add(outcome);
      }
      if (pending && !controller.isClosed) {
        pending = false;
        await refresh();
      }
    }

    controller = StreamController<BudgetScenariosOutcome>(
      onListen: () {
        subscription = _changes.stream.listen((_) {
          refresh();
        });
        timer = Timer.periodic(const Duration(seconds: 10), (_) {
          refresh();
        });
        refresh();
      },
      onCancel: () async {
        timer?.cancel();
        await subscription?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  BudgetScenarioFailure? _validate(BudgetScenarioDraft draft) {
    if (draft.name.trim().isEmpty || draft.name.trim().length > 120) {
      return BudgetScenarioFailure.invalidName;
    }
    final List<double?> amounts = <double?>[
      draft.additionalLivingExpenseRm,
      draft.housingExpenseRm,
      draft.transportExpenseRm,
      draft.monthlyNetIncomeRm,
      draft.householdMonthlyIncomeRm,
    ];
    for (final double? amount in amounts) {
      if (amount != null && (!amount.isFinite || amount < 0)) {
        return BudgetScenarioFailure.invalidAmount;
      }
    }
    return null;
  }

  Map<String, Object?> _values(BudgetScenarioDraft draft) {
    return <String, Object?>{
      'scenario_name': draft.name.trim(),
      'basket_adjustment': draft.additionalLivingExpenseRm,
      'housing_expense': draft.housingExpenseRm,
      'transport_expense': draft.transportExpenseRm,
      'monthly_net_income': draft.monthlyNetIncomeRm,
      'household_monthly_gross_income_rm': draft.householdMonthlyIncomeRm,
    };
  }

  @override
  Future<BudgetScenarioMutationOutcome> create(BudgetScenarioDraft draft) {
    return _save(draft, null);
  }

  @override
  Future<BudgetScenarioMutationOutcome> update(BudgetScenarioUpdate update) {
    return _save(update.values, update.scenarioId);
  }

  Future<BudgetScenarioMutationOutcome> _save(
    BudgetScenarioDraft draft,
    String? id,
  ) async {
    final BudgetScenarioFailure? invalid = _validate(draft);
    if (invalid != null) {
      return BudgetScenarioMutationRejected(invalid);
    }
    final String? owner = _client.auth.currentUser?.id;
    if (owner == null) {
      return const BudgetScenarioMutationRejected(
        BudgetScenarioFailure.scopeUnavailable,
      );
    }
    try {
      final Map<String, Object?> values = _values(draft);
      Map<String, dynamic>? row;
      if (id == null) {
        values['user_id'] = owner;
        row = await _client
            .from('user_budget_scenarios')
            .insert(values)
            .select()
            .single()
            .timeout(const Duration(seconds: 20));
      } else {
        row = await _client
            .from('user_budget_scenarios')
            .update(values)
            .eq('id', id)
            .select()
            .maybeSingle()
            .timeout(const Duration(seconds: 20));
      }
      if (row == null) {
        return const BudgetScenarioMutationRejected(
          BudgetScenarioFailure.notFound,
        );
      }
      final BudgetScenario scenario = decodeBudgetRow(row);
      _changes.add(null);
      final BudgetScenariosOutcome result = await read();
      CurrentBudgetScenarioSnapshot current = _current(
        scenario.isCurrent ? scenario : null,
      );
      if (result is BudgetScenariosAvailable) {
        current = result.current;
      }
      return BudgetScenarioMutationSaved(scenario: scenario, current: current);
    } catch (error) {
      return BudgetScenarioMutationRejected(_failure(error));
    }
  }

  @override
  Future<BudgetScenarioMutationOutcome> selectCurrent(String scenarioId) async {
    try {
      final Object? raw = await _client
          .rpc(
            'select_current_budget',
            params: <String, Object?>{'scenario_id': scenarioId},
          )
          .timeout(const Duration(seconds: 20));
      if (raw is! Map<String, dynamic>) {
        return const BudgetScenarioMutationRejected(
          BudgetScenarioFailure.notFound,
        );
      }
      final BudgetScenario scenario = decodeBudgetRow(raw);
      _changes.add(null);
      return BudgetScenarioMutationSaved(
        scenario: scenario,
        current: _current(scenario),
      );
    } catch (error) {
      return BudgetScenarioMutationRejected(_failure(error));
    }
  }

  @override
  Future<BudgetScenarioMutationOutcome> delete(String scenarioId) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('user_budget_scenarios')
          .delete()
          .eq('id', scenarioId)
          .select('id')
          .timeout(const Duration(seconds: 20));
      if (rows.isEmpty) {
        return const BudgetScenarioMutationRejected(
          BudgetScenarioFailure.notFound,
        );
      }
      _changes.add(null);
      final BudgetScenariosOutcome result = await read();
      CurrentBudgetScenarioSnapshot current = const NoCurrentBudgetScenario(
        version: 0,
      );
      if (result is BudgetScenariosAvailable) {
        current = result.current;
      }
      return BudgetScenarioMutationDeleted(
        scenarioId: scenarioId,
        current: current,
      );
    } catch (error) {
      return BudgetScenarioMutationRejected(_failure(error));
    }
  }

  BudgetScenarioFailure _failure(Object error) {
    if (error is PostgrestException) {
      if (error.code == '42501') {
        return BudgetScenarioFailure.permissionDenied;
      }
      if (error.code == '23505') {
        return BudgetScenarioFailure.conflict;
      }
    }
    return BudgetScenarioFailure.retryableUnavailable;
  }
}

BudgetScenario decodeBudgetRow(Map<String, dynamic> row) {
  double? amount(String key) {
    final Object? raw = row[key];
    if (raw == null) {
      return null;
    }
    if (raw is! num || !raw.toDouble().isFinite || raw < 0) {
      throw const FormatException('Invalid amount');
    }
    return raw.toDouble();
  }

  final DateTime updated = DateTime.parse(row['updated_at'] as String);
  return BudgetScenario(
    id: row['id'] as String,
    name: row['scenario_name'] as String,
    additionalLivingExpenseRm: amount('basket_adjustment'),
    housingExpenseRm: amount('housing_expense'),
    transportExpenseRm: amount('transport_expense'),
    monthlyNetIncomeRm: amount('monthly_net_income'),
    householdMonthlyIncomeRm: amount('household_monthly_gross_income_rm'),
    isCurrent: row['is_current'] as bool,
    updatedAt: updated,
    version: updated.microsecondsSinceEpoch,
  );
}
