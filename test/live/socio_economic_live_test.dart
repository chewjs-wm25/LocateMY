import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/socio_economic/socio_economic.dart';
import 'package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('real Geo Socio RPC and budget current read with authenticated allow and anonymous/write deny', () async {
    HttpOverrides.global = null;
    sqfliteFfiInit();
    final Map<String, String> env = Platform.environment;
    final SupabaseClient client = SupabaseClient(
      env['SUPABASE_URL']!,
      env['SUPABASE_PUBLISHABLE_KEY']!,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final SupabaseClient anon = SupabaseClient(
      env['SUPABASE_URL']!,
      env['SUPABASE_PUBLISHABLE_KEY']!,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final Database database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    String? fixtureId;
    try {
      await client.auth.signInWithPassword(
        email: env['LOCATEMY_EMAIL']!,
        password: env['LOCATEMY_PASSWORD']!,
      );
      final CurrentBudgetReader budget = createSupabaseCurrentBudgetReader(
        client,
      );
      final BudgetScenariosOutcome initial = await budget.readCurrent();
      expect(initial, isA<BudgetScenariosAvailable>());
      if (initial is BudgetScenariosAvailable &&
          initial.current is NoCurrentBudgetScenario) {
        final BudgetScenarioStore store = createBudgetScenarioStore(
          client: client,
        );
        final BudgetScenarioMutationSaved saved = await store.create(
          const BudgetScenarioDraft(
            name: 'Socio live verification temporary',
            householdMonthlyIncomeRm: 6300,
            monthlyNetIncomeRm: 1,
          ),
        ) as BudgetScenarioMutationSaved;
        fixtureId = saved.scenario.id;
        await store.selectCurrent(fixtureId);
      }
      final SocioEconomic socio = createSocioEconomic(
        geographicContext: createGeographicContext(client),
        reader: SupabaseSocioInputsReader(client),
        budget: budget,
        database: database,
      );
      const ValidLocationReference a = ValidLocationReference(
        locationId: 'sunway',
        point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
        displayName: 'Sunway Mentari',
      );
      const ValidLocationReference b = ValidLocationReference(
        locationId: 'johor',
        point: GeographicPoint(latitude: 1.4927, longitude: 103.7414),
        displayName: 'Johor Bahru',
      );
      final SocioAnalysis result = await socio.analyse(a, refresh: true);
      expect(result.state, 'Selangor');
      expect(result.district, 'Petaling');
      expect(result.income?.year, 2024);
      expect(result.income?.value, isPositive);
      expect(result.gini?.year, 2024);
      expect(result.gini?.value, inInclusiveRange(0, 1));
      expect(result.distribution.length, 100);
      expect(result.structure, isNotNull);
      if (fixtureId != null) {
        expect(result.position?.householdIncome, 6300);
        expect(result.position?.percentile, isNotNull);
        await client
            .from('user_budget_scenarios')
            .update(<String, Object?>{
              'household_monthly_gross_income_rm': null,
            })
            .eq('id', fixtureId);
        expect((await socio.analyse(a)).position, isNull);
        await client
            .from('user_budget_scenarios')
            .update(<String, Object?>{
              'household_monthly_gross_income_rm': 6300,
            })
            .eq('id', fixtureId);
        expect((await socio.analyse(a)).position?.householdIncome, 6300);
      }
      final SocioComparison comparison = await socio.compare(a, b);
      expect(comparison.b.state, 'Johor');
      expect(comparison.incomeDifference, isNotNull);
      await expectLater(
        anon.rpc(
          'read_socio_inputs',
          params: <String, Object?>{
            'p_state': 'Selangor',
            'p_district': 'Petaling',
          },
        ),
        throwsA(
          isA<PostgrestException>().having(
            (PostgrestException error) {
              return error.code;
            },
            'anonymous deny',
            '42501',
          ),
        ),
      );
      for (final SupabaseClient caller in <SupabaseClient>[client, anon]) {
        await expectLater(
          caller.from('hh_income_state').insert(<String, Object?>{
            'state': 'Denied',
            'date': '2024-01-01',
            'income_median': 0,
            'income_mean': 0,
          }),
          throwsA(
            isA<PostgrestException>().having(
              (PostgrestException error) {
                return error.code;
              },
              'write deny',
              '42501',
            ),
          ),
        );
      }
      expect(
        await createSupabaseCurrentBudgetReader(anon).readCurrent(),
        isA<BudgetScenariosUnavailable>(),
      );
    } finally {
      if (fixtureId != null) {
        await client.from('user_budget_scenarios').delete().eq('id', fixtureId);
      }
      await database.close();
      await client.auth.signOut();
      await client.dispose();
      await anon.dispose();
    }
  }, skip: Platform.environment['LOCATEMY_SOCIO_LIVE'] != '1');
}
