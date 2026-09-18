import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locatemy/features/cost_of_living_budget/cost_of_living_budget.dart';

void main() {
  test('online budget preserves absent amounts and current deletion never chooses another', () async {
    final List<Map<String, Object?>> saved = <Map<String, Object?>>[];
    final SupabaseClient client = SupabaseClient(
      'https://budget.test',
      'anon',
      httpClient: MockClient((http.Request request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode(saved),
            200,
            request: request,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        if (request.method == 'POST') {
          final Map<String, dynamic> row =
              jsonDecode(request.body) as Map<String, dynamic>;
          saved.add(<String, Object?>{
            ...row,
            'id': 'saved',
            'updated_at': '2026-09-18T00:00:00Z',
            'is_current': false,
          });
          return http.Response(
            jsonEncode(saved.last),
            201,
            request: request,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        saved.clear();
        return http.Response(
          '[{"id":"saved"}]',
          200,
          request: request,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );
    await client.auth.recoverSession(
      jsonEncode(<String, Object?>{
        'access_token': 'test-token',
        'refresh_token': 'refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': <String, Object?>{
          'id': 'owner',
          'app_metadata': <String, Object?>{},
          'user_metadata': <String, Object?>{},
          'aud': 'authenticated',
          'created_at': '2026-01-01T00:00:00Z',
        },
      }),
    );
    final BudgetScenarioStore store = createBudgetScenarioStore(client: client);
    final BudgetScenarioMutationOutcome created = await store.create(
      const BudgetScenarioDraft(name: 'Zero', housingExpenseRm: 0),
    );
    expect(created, isA<BudgetScenarioMutationSaved>());
    final BudgetScenario scenario =
        (created as BudgetScenarioMutationSaved).scenario;
    expect(scenario.housingExpenseRm, 0);
    expect(scenario.transportExpenseRm, isNull);
    await store.delete(scenario.id);
    expect(
      (await store.read() as BudgetScenariosAvailable).current,
      isA<NoCurrentBudgetScenario>(),
    );
    await client.dispose();
  });
}
