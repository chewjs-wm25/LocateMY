import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locatemy/features/property_inspection/property_inspection.dart';

void main() {
  test('real SDK maps database errors then permits ordinary online read retry without caching a fake success', () async {
    bool failing = true;
    final SupabaseClient client = SupabaseClient(
      'https://property.test',
      'public-test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((http.Request request) async {
        if (failing) {
          return http.Response(
            '{"code":"42501","message":"denied"}',
            403,
            request: request,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        return http.Response(
          '[]',
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
    final PropertyInspectionService service = PropertyInspectionService(
      store: SupabasePropertyStore(client),
      risk: NeverRisk(),
    );
    await expectLater(service.list(), throwsA(isA<PostgrestException>()));
    failing = false;
    expect(await service.list(), isEmpty);
    await client.auth.signOut(scope: SignOutScope.local);
    await expectLater(service.list(), throwsA(isA<PropertyFailure>()));
    await client.dispose();
  });
  test('malformed authoritative row is rejected instead of receiving default coordinates or zero price', () async {
    final SupabaseClient client = SupabaseClient(
      'https://property.test',
      'public-test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((http.Request request) async {
        return http.Response(
          '[{"id":"broken"}]',
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
    final PropertyInspectionService service = PropertyInspectionService(
      store: SupabasePropertyStore(client),
      risk: NeverRisk(),
    );
    await expectLater(service.read('broken'), throwsA(anything));
    await client.dispose();
  });
}

class NeverRisk implements PropertyRiskReader {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
