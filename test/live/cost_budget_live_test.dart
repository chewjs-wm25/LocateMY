

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/socio_economic/socio_economic.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';

void main() {
  test('real price partial CPI missing online budget current notifications and owner allow deny restore', () async {
    HttpOverrides.global = null;
    final Map<String, String> env = Platform.environment;
    SupabaseClient client() {
      return SupabaseClient(
        env['SUPABASE_URL']!,
        env['SUPABASE_PUBLISHABLE_KEY']!,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
    }

    final SupabaseClient a = client();
    final SupabaseClient b = client();
    final SupabaseClient anon = client();
    final List<String> ids = <String>[];
    String? original;
    try {
      await a.auth.signInWithPassword(
        email: env['LOCATEMY_EMAIL']!,
        password: env['LOCATEMY_PASSWORD']!,
      );
      await b.auth.signInWithPassword(
        email: env['LOCATEMY_OTHER_EMAIL']!,
        password: env['LOCATEMY_OTHER_PASSWORD']!,
      );
      final BudgetScenarioStore store = createBudgetScenarioStore(client: a);
      final CurrentBudgetReader reader = createSupabaseCurrentBudgetReader(a);
      final BudgetScenariosAvailable before =
          await store.read() as BudgetScenariosAvailable;
      if (before.current is CurrentBudgetScenarioAvailable) {
        original =
            (before.current as CurrentBudgetScenarioAvailable).scenario.id;
      }
      final BudgetScenarioMutationSaved first = await store.create(
        const BudgetScenarioDraft(
          name: 'QA zero',
          housingExpenseRm: 0,
          transportExpenseRm: 0,
          monthlyNetIncomeRm: 3500,
          householdMonthlyIncomeRm: 8000,
        ),
      ) as BudgetScenarioMutationSaved;
      ids.add(first.scenario.id);
      final BudgetScenarioMutationSaved second = await store.create(
        const BudgetScenarioDraft(name: 'QA null'),
      ) as BudgetScenarioMutationSaved;
      ids.add(second.scenario.id);
      await store.selectCurrent(first.scenario.id);
      expect(
        (await reader.readCurrent() as BudgetScenariosAvailable).current,
        isA<CurrentBudgetScenarioAvailable>(),
      );
      final SocioEconomic socio = createSocioEconomic(
        geographicContext: createGeographicContext(a),
        reader: SupabaseSocioInputsReader(a),
        budget: reader,
      );
      const ValidLocationReference jointLocation = ValidLocationReference(
        locationId: 'joint-petaling',
        point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
        displayName: 'Petaling',
      );
      final CostOfLivingBudget jointCost = createCostOfLivingBudget(
        geographicContext: createGeographicContext(a),
        reader: SupabaseCostPublicReader(a),
        budget: reader,
      );
      final CostAnalysisOutcome selectedCost = await jointCost.analyse(
        const CostAnalysisRequest(
          location: jointLocation,
          refreshPolicy: CostRefreshPolicy.refresh,
        ),
      );
      CostAnalysis selectedAnalysis;
      if (selectedCost is CostAnalysisAvailable) {
        selectedAnalysis = selectedCost.analysis;
      } else {
        expect(selectedCost, isA<CostAnalysisPartial>());
        selectedAnalysis = (selectedCost as CostAnalysisPartial).analysis;
      }
      expect(selectedAnalysis.personalBudgetBurden, isNotNull);
      expect(
        selectedAnalysis.personalBudgetBurden,
        closeTo(100 * selectedAnalysis.observedSpend12! / 3500, 0.000001),
      );
      expect(
        (await socio.analyse(jointLocation)).position?.householdIncome,
        8000,
      );
      final Future<BudgetScenariosOutcome> changed = reader
          .watchCurrent()
          .firstWhere((BudgetScenariosOutcome event) {
            return event is BudgetScenariosAvailable &&
                event.current is CurrentBudgetScenarioAvailable &&
                (event.current as CurrentBudgetScenarioAvailable).scenario.id ==
                    second.scenario.id;
          })
          .timeout(const Duration(seconds: 15));
      await store.selectCurrent(second.scenario.id);
      await changed;
      expect((await socio.analyse(jointLocation)).position, isNull);
      final BudgetScenariosAvailable selected =
          await store.read() as BudgetScenariosAvailable;
      expect(
        selected.scenarios.where((BudgetScenario scenario) {
          return scenario.isCurrent;
        }).length,
        1,
      );
      expect(
        (selected.current as CurrentBudgetScenarioAvailable)
            .scenario
            .householdMonthlyIncomeRm,
        isNull,
      );
      expect(
        await b
            .from('user_budget_scenarios')
            .select('id')
            .eq('id', first.scenario.id),
        isEmpty,
      );
      await expectLater(
        b.from('user_budget_scenarios').insert(<String, Object?>{
          'user_id': a.auth.currentUser!.id,
          'scenario_name': 'Forbidden',
        }),
        throwsA(isA<PostgrestException>()),
      );
      expect(
        (await createBudgetScenarioStore(client: b)
            .selectCurrent(first.scenario.id)),
        isA<BudgetScenarioMutationRejected>(),
      );
      await expectLater(
        b
            .from('user_budget_scenarios')
            .update(<String, Object?>{'scenario_name': 'bad'})
            .eq('id', first.scenario.id)
            .select(),
        completion(isEmpty),
      );
      await expectLater(
        a
            .from('user_budget_scenarios')
            .update(<String, Object?>{'user_id': b.auth.currentUser!.id})
            .eq('id', first.scenario.id),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        a
            .from('user_budget_scenarios')
            .update(<String, Object?>{'housing_expense': -1})
            .eq('id', first.scenario.id),
        throwsA(isA<PostgrestException>()),
      );
      expect(
        await createSupabaseCurrentBudgetReader(anon).readCurrent(),
        isA<BudgetScenariosUnavailable>(),
      );
      await expectLater(
        anon.rpc(
          'read_cost_inputs',
          params: <String, Object?>{
            'input_state': 'Selangor',
            'input_district': 'Petaling',
          },
        ),
        throwsA(isA<PostgrestException>()),
      );
      final CostOfLivingBudget cost = createCostOfLivingBudget(
        geographicContext: createGeographicContext(a),
        reader: SupabaseCostPublicReader(a),
        budget: reader,
      );
      const ValidLocationReference location = ValidLocationReference(
        locationId: 'live',
        point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
      );
      final Stopwatch watch = Stopwatch()..start();
      final CostAnalysisPartial result = await cost.analyse(
        const CostAnalysisRequest(
          location: location,
          refreshPolicy: CostRefreshPolicy.refresh,
        ),
      ) as CostAnalysisPartial;
      watch.stop();
      expect(result.analysis.items.length, 11);
      expect(result.analysis.availableMonths, 12);
      expect(result.analysis.observedSpend12, greaterThan(0));
      expect(result.analysis.coverage, greaterThan(0));
      expect(result.analysis.coverage, lessThan(1));
      expect(result.analysis.costIndex, greaterThan(0));
      expect(result.analysis.indexedItemCount, greaterThan(0));
      expect(result.analysis.indexedItemCount, lessThan(11));
      expect(result.analysis.personalBudgetBurden, isNull);
      expect(result.gaps, contains(CostAvailabilityGap.baselineIncomplete));
      print(
        'REAL_PRICE_RPC: ${watch.elapsedMilliseconds}ms; 11 items, 12 months, partial basket index',
      );
      await store.delete(second.scenario.id);
      expect(
        (await reader.readCurrent() as BudgetScenariosAvailable).current,
        isA<NoCurrentBudgetScenario>(),
      );
      expect(
        (await store.read() as BudgetScenariosAvailable).scenarios.any((
          BudgetScenario scenario,
        ) {
          return scenario.id == first.scenario.id;
        }),
        true,
      );
    } finally {
      for (final String id in ids) {
        await createBudgetScenarioStore(client: a).delete(id);
      }
      if (original != null) {
        await createBudgetScenarioStore(client: a).selectCurrent(original);
      }
      await a.dispose();
      await b.dispose();
      await anon.dispose();
    }
  }, skip: Platform.environment['LOCATEMY_COST_LIVE'] != '1');
}
