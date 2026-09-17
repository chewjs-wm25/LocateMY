import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  for (final String code in ['42501', 'PGRST301']) {
    test(
      'remote permission $code is not a retryable network failure',
      () async {
        sqfliteFfiInit();
        final Database db = await databaseFactoryFfi.openDatabase(
          inMemoryDatabasePath,
        );
        final SupabaseClient client = SupabaseClient(
          'https://example.test',
          'public',
          httpClient: MockClient((request) async {
            if (request.url.path.contains('/auth/')) {
              return http.Response(
                jsonEncode({
                  'access_token': 'test',
                  'refresh_token': 'test',
                  'token_type': 'bearer',
                  'expires_in': 3600,
                  'user': {
                    'id': 'a',
                    'aud': 'authenticated',
                    'email': 'fixture@example.test',
                    'created_at': '2026-01-01T00:00:00Z',
                  },
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            return http.Response(
              jsonEncode({'code': code, 'message': 'denied'}),
              403,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }),
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        await client.auth.signInWithPassword(
          email: 'fixture@example.test',
          password: 'fixture',
        );
        final LocationStorage store = createLocationStorage(
          client: client,
          database: db,
          accountId: 'a',
        );
        await expectLater(
          store.readRemote(),
          throwsA(SavedLocationFailure.permissionDenied),
        );
        await client.dispose();
        await db.close();
      },
    );
  }
}
