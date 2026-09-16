import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/authentication_session/src/data/supabase_authentication_session_adapter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class EvidenceClient extends http.BaseClient {
  final _inner = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await http.Response.fromStream(await _inner.send(request));
    if (response.statusCode >= 300) {
      String? code;
      try {
        code = (jsonDecode(response.body) as Map)['code'] as String?;
      } catch (_) {}
      stdout.writeln(
        'Live HTTP ${request.method} ${request.url.path}: ${response.statusCode}, code=$code',
      );
    }
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }

  @override
  void close() => _inner.close();
}

void main() {
  test(
    'live Auth lifecycle and profiles owner isolation',
    () async {
      HttpOverrides.global = null;
      final env = Platform.environment;
      final url = env['SUPABASE_URL']!;
      final key = env['SUPABASE_PUBLISHABLE_KEY']!;
      final secret = env['SUPABASE_SECRET_KEY']!;
      final nonce = DateTime.now().microsecondsSinceEpoch;
      final password =
          'Qa!${List.generate(32, (_) => Random.secure().nextInt(10)).join()}';
      final clients = List.generate(
        3,
        (_) => SupabaseClient(
          url,
          key,
          authOptions: const AuthClientOptions(
            autoRefreshToken: false,
            authFlowType: AuthFlowType.implicit,
          ),
          httpClient: EvidenceClient(),
        ),
      );
      final a = SupabaseAuthenticationSessionAdapter(clients[0]);
      final b = SupabaseAuthenticationSessionAdapter(clients[1]);
      final otherDevice = SupabaseAuthenticationSessionAdapter(clients[2]);
      final createdIds = <String>[];
      final admin = http.Client();
      Future<Map<String, dynamic>> adminRequest(
        String path,
        String method, [
        Map<String, dynamic>? body,
      ]) async {
        final request = http.Request(
          method,
          Uri.parse('$url/auth/v1/admin/$path'),
        );
        request.headers.addAll({
          'apikey': secret,
          'Authorization': 'Bearer $secret',
          'Content-Type': 'application/json',
        });
        if (body != null) request.body = jsonEncode(body);
        final response = await http.Response.fromStream(
          await admin.send(request),
        );
        if (response.statusCode >= 300) {
          throw StateError(
            'Admin operation failed (${response.statusCode}); response redacted',
          );
        }
        return response.body.isEmpty
            ? {}
            : jsonDecode(response.body) as Map<String, dynamic>;
      }

      try {
        expect(await a.restoreSession(), isA<UnauthenticatedSession>());
        final emailA = 'locatemy.qa.$nonce.a@gmail.com';
        final emailB = 'locatemy.qa.$nonce.b@gmail.com';
        final registration = await a.register(
          email: emailA,
          password: password,
          passwordConfirmation: password,
          username: 'Wave1 QA',
        );
        final userA = clients[0].auth.currentUser;
        // Confirm-email signUp returns no session; create isolated admin fixtures
        // when outbound email is limited, without changing project settings.
        String idA;
        if (registration is RegistrationVerificationRequired) {
          final users = await adminRequest('users?page=1&per_page=1000', 'GET');
          final found = (users['users'] as List)
              .cast<Map<String, dynamic>>()
              .where((u) => u['email'] == emailA)
              .single;
          idA = found['id'] as String;
          createdIds.add(idA);
          await adminRequest('users/$idA', 'PUT', {'email_confirm': true});
        } else if (registration is RegistrationAuthenticated && userA != null) {
          idA = userA.id;
          createdIds.add(idA);
        } else if (registration is RegistrationRejected &&
            registration.failure == RegistrationFailure.retryableUnavailable) {
          stdout.writeln(
            'Registration temporarily unavailable; remaining checks use isolated admin fixture',
          );
          final fixtureA = await adminRequest('users', 'POST', {
            'email': emailA,
            'password': password,
            'email_confirm': true,
          });
          idA = fixtureA['id'] as String;
          createdIds.add(idA);
        } else {
          throw StateError(
            'Real registration did not succeed; result: ${registration.runtimeType}, failure: ${registration is RegistrationRejected ? registration.failure : 'none'}',
          );
        }
        final fixtureB = await adminRequest('users', 'POST', {
          'email': emailB,
          'password': password,
          'email_confirm': true,
        });
        final idB = fixtureB['id'] as String;
        createdIds.add(idB);
        expect(
          await a.signIn(email: emailA, password: password),
          isA<SignInSucceeded>(),
        );
        expect(
          await b.signIn(email: emailB, password: password),
          isA<SignInSucceeded>(),
        );
        expect(
          await otherDevice.signIn(email: emailA, password: password),
          isA<SignInSucceeded>(),
        );
        final restored = await a.restoreSession();
        expect(restored, isA<AuthenticatedSession>());
        expect(
          (restored as AuthenticatedSession).account.confirmation,
          EmailConfirmation.confirmed,
        );
        if (registration is RegistrationVerificationRequired) {
          expect(await a.retryOptionalProfile(), isA<ProfileRegistered>());
        }
        final profiles = clients[0].from('profiles');
        await profiles.upsert({'id': idA, 'username': 'Wave1 QA'});
        expect((await profiles.select().eq('id', idA)).length, 1);
        await profiles.update({'username': 'Wave1 updated'}).eq('id', idA);
        expect(
          (await profiles.select('username').eq('id', idA)).single['username'],
          'Wave1 updated',
        );
        final foreign = clients[1].from('profiles');
        expect(await foreign.select().eq('id', idA), isEmpty);
        expect(
          await foreign
              .update({'username': 'forbidden'})
              .eq('id', idA)
              .select(),
          isEmpty,
        );
        expect(await foreign.delete().eq('id', idA).select(), isEmpty);
        await expectLater(
          foreign.upsert({'id': idA, 'username': 'forbidden'}),
          throwsA(isA<PostgrestException>()),
        );
        await expectLater(
          profiles.update({'id': idB}).eq('id', idA),
          throwsA(isA<PostgrestException>()),
        );
        final anonymous = SupabaseClient(
          url,
          key,
          httpClient: EvidenceClient(),
        );
        Future<void> expectAnonymousDenied(Future<dynamic> operation) async {
          try {
            expect(await operation, isEmpty);
          } on PostgrestException catch (error) {
            expect(error.code, '42501');
          }
        }

        try {
          await expectAnonymousDenied(
            anonymous.from('profiles').select().eq('id', idA),
          );
          await expectLater(
            anonymous.from('profiles').insert({'id': idA}),
            throwsA(isA<PostgrestException>()),
          );
          await expectAnonymousDenied(
            anonymous
                .from('profiles')
                .update({'username': 'forbidden'})
                .eq('id', idA)
                .select(),
          );
          await expectAnonymousDenied(
            anonymous.from('profiles').delete().eq('id', idA).select(),
          );
        } finally {
          await anonymous.dispose();
        }
        expect(await a.signOut(), isA<SignOutSucceeded>());
        expect(await a.restoreSession(), isA<UnauthenticatedSession>());
        expect(await otherDevice.restoreSession(), isA<AuthenticatedSession>());
        expect(
          (await clients[2].from('profiles').select().eq('id', idA)).length,
          1,
        );
        await clients[2].from('profiles').delete().eq('id', idA);
        expect(
          await clients[2].from('profiles').select().eq('id', idA),
          isEmpty,
        );
        expect(await b.restoreSession(), isA<AuthenticatedSession>());
      } finally {
        for (final client in clients) {
          await client.dispose();
        }
        for (final id in createdIds) {
          await adminRequest('users/$id', 'DELETE');
        }
        admin.close();
      }
    },
    skip: Platform.environment['LOCATEMY_AUTH_LIVE'] != '1',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
