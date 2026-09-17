// Explicit local types follow Development Standard §7.
import 'dart:convert';

import 'package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locatemy/features/socio_economic/socio_economic.dart';

void main() {
  test('read adapter sends resolved scope to stable RPC and rejects malformed envelopes', () async {
    bool malformed = false;
    final SupabaseClient client = SupabaseClient(
      'https://example.supabase.co',
      'public-key',
      httpClient: MockClient((http.Request request) async {
        expect(request.url.path, '/rest/v1/rpc/read_socio_inputs');
        expect(jsonDecode(request.body), <String, Object?>{
          'p_state': 'Selangor',
          'p_district': 'Petaling',
        });
        if (malformed) {
          return http.Response(
            '[]',
            200,
            request: request,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode(<String, Object?>{
            'version': 1,
            'state': 'Selangor',
            'district': 'Petaling',
            'income_district': <Object?>[],
            'income_state': <Object?>[],
            'gini_district': <Object?>[],
            'gini_state': <Object?>[],
            'percentiles': <Object?>[],
          }),
          200,
          request: request,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );
    final SocioInputsReader reader = SupabaseSocioInputsReader(client);
    expect((await reader.read('Selangor', 'Petaling'))['version'], 1);
    malformed = true;
    await expectLater(
      reader.read('Selangor', 'Petaling'),
      throwsFormatException,
    );
    await client.dispose();
  });
  test('budget owner maps only saved current household income and keeps null distinct from net income', () async {
    final SupabaseClient client = SupabaseClient(
      'https://example.supabase.co',
      'public-key',
      httpClient: MockClient((http.Request request) async {
        expect(request.url.path, '/rest/v1/user_budget_scenarios');
        return http.Response(
          '[{"id":"saved","scenario_name":"Saved","household_monthly_gross_income_rm":null,"monthly_net_income":6000,"is_current":true,"updated_at":"2026-09-17T00:00:00Z"}]',
          200,
          request: request,
        );
      }),
    );
    final BudgetScenariosOutcome result =
        await createSupabaseCurrentBudgetReader(client).readCurrent();
    expect(result, isA<BudgetScenariosAvailable>());
    final CurrentBudgetScenarioAvailable current =
        (result as BudgetScenariosAvailable).current
            as CurrentBudgetScenarioAvailable;
    expect(current.scenario.householdMonthlyIncomeRm, isNull);
    expect(current.scenario.monthlyNetIncomeRm, 6000);
    await client.dispose();
  });

  test(
    'real current-budget observation starts and publishes saved results',
    () async {
      final SupabaseClient client = SupabaseClient(
        'https://example.supabase.co',
        'public-key',
        httpClient: MockClient((http.Request request) async {
          return http.Response('[]', 200, request: request);
        }),
      );
      final BudgetScenariosOutcome event =
          await createSupabaseCurrentBudgetReader(client)
              .watchCurrent()
              .first
              .timeout(const Duration(seconds: 15));
      expect(event, isA<BudgetScenariosAvailable>());
      await client.dispose();
    },
  );
  test('public RPC and private current reader expose failure then recover on retry', () async {
    bool offline = true;
    final SupabaseClient client = SupabaseClient(
      'https://example.supabase.co',
      'public-key',
      httpClient: MockClient((http.Request request) async {
        if (offline) {
          return http.Response(
            '{"code":"42501","message":"Private denied detail"}',
            403,
            request: request,
          );
        }
        if (request.url.path.endsWith('read_socio_inputs')) {
          return http.Response(
            '{"version":1,"state":"Selangor","district":null,"income_district":[],"income_state":[],"gini_district":[],"gini_state":[],"percentiles":[]}',
            200,
            request: request,
          );
        }
        return http.Response('[]', 200, request: request);
      }),
    );
    final SocioInputsReader public = SupabaseSocioInputsReader(client);
    final CurrentBudgetReader private = createSupabaseCurrentBudgetReader(
      client,
    );
    await expectLater(
      public.read('Selangor', null),
      throwsA(isA<PostgrestException>()),
    );
    expect(await private.readCurrent(), isA<BudgetScenariosUnavailable>());
    offline = false;
    expect((await public.read('Selangor', null))['version'], 1);
    expect(await private.readCurrent(), isA<BudgetScenariosAvailable>());
    await client.dispose();
  });
  test(
    'read adapter rejects an envelope for a different resolved location scope',
    () async {
      final SupabaseClient client = SupabaseClient(
        'https://example.supabase.co',
        'public-key',
        httpClient: MockClient((http.Request request) async {
          return http.Response(
            '{"version":1,"state":"Johor","district":null,"income_district":[],"income_state":[],"gini_district":[],"gini_state":[],"percentiles":[]}',
            200,
            request: request,
          );
        }),
      );
      await expectLater(
        SupabaseSocioInputsReader(client).read('Selangor', 'Petaling'),
        throwsFormatException,
      );
      await client.dispose();
    },
  );
}
