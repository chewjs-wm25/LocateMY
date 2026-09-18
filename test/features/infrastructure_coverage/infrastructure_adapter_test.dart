import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locatemy/features/infrastructure_coverage/infrastructure_coverage.dart';

void main() {
  test('weights SDK adapter defaults missing rows validates integer levels and surfaces save failure then recovery', () async {
    String mode = 'empty';
    bool denied = false;
    final String claims = base64Url
        .encode(
          utf8.encode(
            jsonEncode(<String, Object?>{
              'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
            }),
          ),
        )
        .replaceAll('=', '');
    final SupabaseClient client = SupabaseClient(
      'https://example.supabase.co',
      'public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((http.Request request) async {
        if (request.url.path == '/auth/v1/token') {
          return http.Response(
            jsonEncode(<String, Object?>{
              'access_token': 'header.$claims.signature',
              'refresh_token': 'test-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': <String, Object?>{
                'id': 'account-a',
                'aud': 'authenticated',
                'app_metadata': <String, Object?>{},
                'user_metadata': <String, Object?>{},
                'created_at': '2026-01-01T00:00:00Z',
              },
            }),
            200,
            request: request,
          );
        }
        expect(request.url.path, '/rest/v1/user_ici_preferences');
        if (request.method == 'POST') {
          final Map<String, Object?> body = Map<String, Object?>.from(
            jsonDecode(request.body) as Map,
          );
          expect(body['user_id'], 'account-a');
          expect(body['health'], 1);
          expect(body['education'], 10);
          expect(body.containsKey('weight_health'), isFalse);
          if (denied) {
            return http.Response(
              '{"code":"42501","message":"denied"}',
              403,
              request: request,
            );
          }
          return http.Response('', 201, request: request);
        }
        expect(request.url.queryParameters['user_id'], 'eq.account-a');
        if (mode == 'empty') {
          return http.Response('null', 200, request: request);
        }
        if (mode == 'invalid') {
          return http.Response(
            '{"health":0,"education":5,"transit":5}',
            200,
            request: request,
          );
        }
        return http.Response(
          '{"health":1,"education":10,"transit":5}',
          200,
          request: request,
        );
      }),
    );
    await client.auth.signInWithPassword(
      email: 'fixture@example.com',
      password: 'fixture-password',
    );
    final SupabaseInfrastructureWeightsStore store =
        SupabaseInfrastructureWeightsStore(client);
    expect((await store.read()).health, 5);
    mode = 'invalid';
    await expectLater(store.read(), throwsFormatException);
    mode = 'valid';
    expect((await store.read()).education, 10);
    denied = true;
    await expectLater(
      store.save(const InfrastructureWeightSettings(health: 1, education: 10)),
      throwsA(isA<PostgrestException>()),
    );
    denied = false;
    await store.save(
      const InfrastructureWeightSettings(health: 1, education: 10),
    );
    await client.dispose();
  });

  test('real SDK read adapter sends resolved scope rejects malformed and denied responses and recovers', () async {
    String mode = 'valid';
    final SupabaseClient client = SupabaseClient(
      'https://example.supabase.co',
      'public-key',
      httpClient: MockClient((http.Request request) async {
        expect(request.url.path, '/rest/v1/rpc/read_infrastructure_inputs');
        expect(jsonDecode(request.body), <String, Object?>{
          'p_state': 'Selangor',
          'p_district': 'Petaling',
        });
        if (mode == 'denied') {
          return http.Response(
            '{"code":"42501","message":"denied"}',
            403,
            request: request,
          );
        }
        if (mode == 'malformed') {
          return http.Response('{}', 200, request: request);
        }
        if (mode == 'scope') {
          return http.Response(
            '{"version":1,"state":"Other","district":"Petaling"}',
            200,
            request: request,
          );
        }
        return http.Response(
          jsonEncode(<String, Object?>{
            'version': 1,
            'state': 'Selangor',
            'district': 'Petaling',
            'amenities': <Object?>[],
            'beds': <Object?>[],
            'population': <Object?>[],
            'schools': <Object?>[],
            'teachers': <Object?>[],
            'enrolment': <Object?>[],
          }),
          200,
          request: request,
        );
      }),
    );
    final InfrastructureInputsReader reader =
        SupabaseInfrastructureInputsReader(client);
    expect((await reader.read('Selangor', 'Petaling'))['version'], 1);
    mode = 'malformed';
    await expectLater(
      reader.read('Selangor', 'Petaling'),
      throwsFormatException,
    );
    mode = 'scope';
    await expectLater(
      reader.read('Selangor', 'Petaling'),
      throwsFormatException,
    );
    mode = 'denied';
    await expectLater(
      reader.read('Selangor', 'Petaling'),
      throwsA(isA<PostgrestException>()),
    );
    mode = 'valid';
    expect((await reader.read('Selangor', 'Petaling'))['schools'], isEmpty);
    await client.dispose();
  });
}
