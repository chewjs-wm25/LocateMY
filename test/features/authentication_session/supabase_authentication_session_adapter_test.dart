import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/authentication_session/src/data/supabase_authentication_session_adapter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

http.Response jsonResponse(String body, int status) => http.Response(
  body,
  status,
  headers: {
    'content-type': 'application/json',
    'x-supabase-api-version': '2024-01-01',
  },
);

Map<String, dynamic> user({String id = 'account-a', bool confirmed = true}) => {
  'id': id,
  'email': '$id@example.com',
  'app_metadata': <String, dynamic>{},
  'user_metadata': {'email_verified': true},
  'aud': 'authenticated',
  'created_at': '2026-09-01T00:00:00Z',
  if (confirmed) 'email_confirmed_at': '2026-09-01T00:00:00Z',
};

Map<String, dynamic> session({bool expired = false, bool confirmed = true}) {
  final expiry =
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + (expired ? -3600 : 3600);
  final claims = base64Url
      .encode(utf8.encode(jsonEncode({'exp': expiry})))
      .replaceAll('=', '');
  return {
    'access_token': 'header.$claims.signature',
    'refresh_token': 'test-refresh-token',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': user(confirmed: confirmed),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SupabaseAuthenticationSessionAdapter adapter;
  late Future<http.Response> Function(http.Request) respond;
  late List<http.Request> requests;

  setUp(() {
    requests = [];
    respond = (_) async => jsonResponse(jsonEncode(user()), 200);
    client = SupabaseClient(
      'https://auth.example.com',
      'sb_publishable_test',
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
      httpClient: MockClient((request) {
        requests.add(request);
        return respond(request).then(
          (response) => http.Response.bytes(
            response.bodyBytes,
            response.statusCode,
            headers: response.headers,
            request: request,
          ),
        );
      }),
    );
    adapter = SupabaseAuthenticationSessionAdapter(client);
  });
  tearDown(() async => client.dispose());

  Future<void> seed({bool expired = false}) async {
    await client.auth.setInitialSession(jsonEncode(session(expired: expired)));
    requests.clear();
  }

  test('no cached session needs no network', () async {
    expect(await adapter.restoreSession(), isA<UnauthenticatedSession>());
    expect(requests, isEmpty);
  });

  test('sign in maps invalid credentials', () async {
    respond = (_) async => jsonResponse(
      '{"code":"invalid_credentials","msg":"Invalid login credentials"}',
      400,
    );
    final result = await adapter.signIn(
      email: 'a@example.com',
      password: 'incorrect',
    ) as SignInRejected;
    expect(result.failure, SignInFailure.invalidCredentials);
  });

  test('profile failure does not undo authenticated registration', () async {
    respond = (request) async => request.url.path.contains('profiles')
        ? jsonResponse('{"code":"42501","message":"Denied"}', 403)
        : jsonResponse(jsonEncode(session()), 200);
    final result = await adapter.register(
      email: 'a@example.com',
      password: 'password123',
      passwordConfirmation: 'password123',
      username: 'Test User',
    ) as RegistrationAuthenticated;
    expect(result.profile, isA<ProfileRegistrationFailed>());
    expect(
      (result.profile as ProfileRegistrationFailed).failure,
      ProfileFailure.permissionDenied,
    );
    expect(result.account.accountId, 'account-a');
  });

  test('sign out affects only this device', () async {
    await seed();
    respond = (_) async => jsonResponse('', 204);
    expect(await adapter.signOut(), isA<SignOutSucceeded>());
    expect(requests.single.url.queryParameters['scope'], 'local');
    expect(client.auth.currentSession, isNull);
  });

  test(
    'normal logout response cannot claim success for a newer SDK identity',
    () async {
      await seed();
      respond = (http.Request request) async {
        final Map<String, dynamic> replacement = session();
        replacement['user'] = user(id: 'account-b');
        await client.auth.setInitialSession(jsonEncode(replacement));
        return jsonResponse('', 204);
      };
      expect(await adapter.signOut(), isA<SignOutRejected>());
      expect(client.auth.currentUser!.id, 'account-b');
    },
  );

  test('invalid inputs never call Auth', () async {
    expect(
      await adapter.signIn(email: '', password: ''),
      isA<SignInRejected>(),
    );
    expect(
      await adapter.register(
        email: 'a@example.com',
        password: 'a',
        passwordConfirmation: 'b',
      ),
      isA<RegistrationRejected>(),
    );
    expect(requests, isEmpty);
  });

  test('watch provides first SDK snapshot and handles sign out', () async {
    await seed();
    final snapshots = <SessionSnapshot>[];
    final subscription = adapter.watchSession().listen(snapshots.add);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(snapshots.last, isA<AuthenticatedSession>());
    respond = (_) async => jsonResponse('', 204);
    await adapter.signOut();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(snapshots.last, isA<UnauthenticatedSession>());
    await subscription.cancel();
  });

  test('rate limits offer retry and weak password offers correction', () async {
    respond = (_) async => jsonResponse(
      '{"code":"over_request_rate_limit","message":"Rate limited"}',
      429,
    );
    final signIn = await adapter.signIn(
      email: 'a@example.com',
      password: 'password',
    ) as SignInRejected;
    expect(signIn.failure, SignInFailure.retryableUnavailable);
    respond = (_) async =>
        jsonResponse('{"code":"weak_password","message":"Weak password"}', 422);
    final registration = await adapter.register(
      email: 'a@example.com',
      password: '123',
      passwordConfirmation: '123',
    ) as RegistrationRejected;
    expect(registration.failure, RegistrationFailure.invalidInput);
  });

  for (final failure in [
    ('validation_failed', 422, SignInFailure.invalidInput),
    ('unexpected_error', 400, SignInFailure.unsupportedClient),
  ]) {
    test('sign in maps ${failure.$1}', () async {
      respond = (_) async => jsonResponse(
        jsonEncode({'code': failure.$1, 'message': 'Rejected'}),
        failure.$2,
      );
      final result = await adapter.signIn(
        email: 'a@example.com',
        password: 'password',
      ) as SignInRejected;
      expect(result.failure, failure.$3);
    });
  }
  for (final failure in [
    ('user_already_exists', 422, RegistrationFailure.accountAlreadyExists),
    ('unexpected_error', 400, RegistrationFailure.unsupportedClient),
  ]) {
    test('registration maps ${failure.$1}', () async {
      respond = (_) async => jsonResponse(
        jsonEncode({'code': failure.$1, 'message': 'Rejected'}),
        failure.$2,
      );
      final result = await adapter.register(
        email: 'a@example.com',
        password: 'password',
        passwordConfirmation: 'password',
      ) as RegistrationRejected;
      expect(result.failure, failure.$3);
    });
  }
  test(
    'SDK local logout remains complete when remote revocation is offline',
    () async {
      await seed();
      respond = (_) async => throw TimeoutException('offline');
      expect(await adapter.signOut(), isA<SignOutSucceeded>());
      expect(client.auth.currentSession, isNull);
      expect(await adapter.restoreSession(), isA<UnauthenticatedSession>());
      respond = (_) async => jsonResponse('', 204);
      expect(await adapter.signOut(), isA<SignOutSucceeded>());
    },
  );
  test(
    'missing Auth email never establishes successful registration',
    () async {
      final payload = session();
      (payload['user'] as Map).remove('email');
      respond = (_) async => jsonResponse(jsonEncode(payload), 200);
      final result = await adapter.register(
        email: 'a@example.com',
        password: 'password',
        passwordConfirmation: 'password',
        username: 'User',
      );
      expect(result, isA<RegistrationRejected>());
      expect(requests.where((r) => r.url.path.contains('profiles')), isEmpty);
    },
  );
}
