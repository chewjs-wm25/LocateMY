// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/current_budget_reader.dart';
import '../domain/budget_models.dart';

final class SupabaseCurrentBudgetReader implements CurrentBudgetReader {
  final SupabaseClient _client;
  SupabaseCurrentBudgetReader(SupabaseClient client) : _client = client;
  @override
  Future<BudgetScenariosOutcome> readCurrent() async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('user_budget_scenarios')
          .select(
            'id,scenario_name,household_monthly_gross_income_rm,monthly_net_income,is_current,updated_at',
          )
          .eq('is_current', true)
          .limit(2)
          .timeout(const Duration(seconds: 20));
      if (rows.isEmpty) {
        return const BudgetScenariosAvailable(
          scenarios: <BudgetScenario>[],
          current: NoCurrentBudgetScenario(version: 0),
        );
      }
      if (rows.length != 1) {
        return const BudgetScenariosUnavailable(BudgetScenarioFailure.conflict);
      }
      final Map<String, dynamic> row = rows.first;
      final DateTime updated = DateTime.parse(row['updated_at'] as String);
      final Object? rawIncome = row['household_monthly_gross_income_rm'];
      double? income;
      if (rawIncome != null) {
        if (rawIncome is! num ||
            !rawIncome.toDouble().isFinite ||
            rawIncome < 0) {
          throw const FormatException('Invalid household amount');
        }
        income = rawIncome.toDouble();
      }
      final BudgetScenario scenario = BudgetScenario(
        id: row['id'] as String,
        name: row['scenario_name'] as String,
        householdMonthlyIncomeRm: income,
        monthlyNetIncomeRm: (row['monthly_net_income'] as num?)?.toDouble(),
        isCurrent: true,
        updatedAt: updated,
        version: updated.microsecondsSinceEpoch,
      );
      return BudgetScenariosAvailable(
        scenarios: List<BudgetScenario>.unmodifiable(<BudgetScenario>[
          scenario,
        ]),
        current: CurrentBudgetScenarioAvailable(
          scenario: scenario,
          version: scenario.version,
        ),
      );
    } catch (_) {
      return const BudgetScenariosUnavailable(
        BudgetScenarioFailure.retryableUnavailable,
      );
    }
  }

  @override
  Stream<BudgetScenariosOutcome> watchCurrent() {
    // Poll only while a consumer subscribes; this needs no Realtime publication.
    // A future budget writer can replace this with successful-mutation events.
    return Stream<int>.periodic(const Duration(seconds: 10), (int tick) {
      return tick;
    }).asyncMap((int tick) {
      return readCurrent();
    });
  }
}
