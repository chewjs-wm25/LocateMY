import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:locatemy/features/crime_security/crime_security.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'crime_security_test.dart' show inputs, row;

void main() {
  test('read-only adapter maps a real SDK RPC result and recovers after HTTP errors', () async {
    int status = 503;
    final http.Client transport = MockClient((http.Request request) async {
      expect(request.url.path, '/rest/v1/rpc/read_safety_inputs');
      if (status != 200) {
        return http.Response(
          '{"code":"unavailable","message":"private detail"}',
          status,
          request: request,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode(
          inputs(<Map<String, Object?>>[row('Selangor', 'assault', 10)]),
        ),
        200,
        request: request,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final SupabaseClient client = SupabaseClient(
      'https://example.supabase.co',
      'public-key',
      httpClient: transport,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    try {
      final SafetyInputsReader reader = SupabaseSafetyInputsReader(client);
      await expectLater(
        reader.readSafetyInputs(),
        throwsA(isA<PostgrestException>()),
      );
      status = 200;
      expect((await reader.readSafetyInputs())['dataset_id'], 'crime_district');
    } finally {
      await client.dispose();
      transport.close();
    }
  });
}
