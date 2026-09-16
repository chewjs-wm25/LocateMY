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

  test('restore checks Auth and uses its current email confirmation', () async {
    await seed();
    respond = (_) async =>
        jsonResponse(jsonEncode(user(confirmed: false)), 200);
    final result = await adapter.restoreSession() as AuthenticatedSession;
    expect(requests.single.url.path, '/auth/v1/user');
    expect(result.account.confirmation, EmailConfirmation.verificationRequired);
  });

  test('offline restore cannot authorize cached identity', () async {
    await seed();
    respond = (_) async => throw TimeoutException('offline');
    final result = await adapter.restoreSession() as SessionUnavailable;
    expect(result.failure, SessionFailure.retryableUnavailable);
  });

  test('expired session refreshes before restoring identity', () async {
    respond = (request) async => jsonResponse(
      jsonEncode(request.url.path.endsWith('/token') ? session() : user()),
      200,
    );
    final errors = client.auth.onAuthStateChange.listen(
      (_) {},
      onError: (_) {},
    );
    await seed(expired: true);
    await errors.cancel();
    expect(await adapter.restoreSession(), isA<AuthenticatedSession>());
    expect(requests.last.url.path, '/auth/v1/user');
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

  test('registration without a session requires verification', () async {
    respond = (_) async =>
        jsonResponse(jsonEncode(user(confirmed: false)), 200);
    final result = await adapter.register(
      email: 'a@example.com',
      password: 'password123',
      passwordConfirmation: 'password123',
    );
    expect(result, isA<RegistrationVerificationRequired>());
    expect(
      (result as RegistrationVerificationRequired).profile,
      isA<ProfileRegistrationSkipped>(),
    );
    expect(requests.where((r) => r.url.path.contains('profiles')), isEmpty);
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

  test('watch provides first verified snapshot and handles sign out', () async {
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
  test('remote rejection never authorizes a cached session', () async {
    await seed();
    respond = (_) async => jsonResponse(
      '{"code":"session_not_found","message":"Session revoked"}',
      401,
    );
    final result = await adapter.restoreSession() as SessionUnavailable;
    expect(result.failure, SessionFailure.remoteRejected);
  });

  test('failed expired refresh does not authorize expired cache', () async {
    await seed(expired: true);
    respond = (_) async => jsonResponse('{"message":"Unavailable"}', 503);
    final errors = client.auth.onAuthStateChange.listen(
      (_) {},
      onError: (_) {},
    );
    final result = await adapter.restoreSession() as SessionUnavailable;
    expect(result.failure, SessionFailure.retryableUnavailable);
    await errors.cancel();
  });

  test('late restore cannot resurrect identity after sign out', () async {
    await seed();
    final response = Completer<http.Response>();
    respond = (_) => response.future;
    final restoring = adapter.restoreSession();
    await Future<void>.delayed(Duration.zero);
    respond = (_) async => jsonResponse('', 204);
    await adapter.signOut();
    response.complete(jsonResponse(jsonEncode(user()), 200));
    expect(await restoring, isA<SessionUnavailable>());
  });

  test(
    'profile can be retried separately from successful registration',
    () async {
      respond = (request) async => request.url.path.contains('profiles')
          ? jsonResponse('{"code":"42501","message":"Denied"}', 403)
          : jsonResponse(jsonEncode(session()), 200);
      await adapter.register(
        email: 'account-a@example.com',
        password: 'password123',
        passwordConfirmation: 'password123',
        username: 'Test User',
      );
      respond = (request) async => request.url.path.contains('profiles')
          ? jsonResponse('null', 201)
          : jsonResponse(jsonEncode(user()), 200);
      expect(await adapter.retryOptionalProfile(), isA<ProfileRegistered>());
      expect(
        await adapter.retryOptionalProfile(),
        isA<ProfileRegistrationSkipped>(),
      );
    },
  );

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
  test(
    'expired registration cannot establish authenticated result or profile',
    () async {
      respond = (_) async =>
          jsonResponse(jsonEncode(session(expired: true)), 200);
      final result = await adapter.register(
        email: 'a@example.com',
        password: 'password123',
        passwordConfirmation: 'password123',
        username: 'Test User',
      );
      expect(result, isA<RegistrationRejected>());
      expect(requests.where((r) => r.url.path.contains('profiles')), isEmpty);
    },
  );

  test(
    'blank optional username is skipped when verification is required',
    () async {
      respond = (_) async =>
          jsonResponse(jsonEncode(user(confirmed: false)), 200);
      final result = await adapter.register(
        email: 'a@example.com',
        password: 'password123',
        passwordConfirmation: 'password123',
        username: ' ',
      ) as RegistrationVerificationRequired;
      expect(result.profile, isA<ProfileRegistrationSkipped>());
    },
  );
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
    'network sign out failure preserves rejection and retry recovery',
    () async {
      await seed();
      respond = (_) async => throw TimeoutException('offline');
      final result = await adapter.signOut() as SignOutRejected;
      expect(result.failure, SignOutFailure.retryableUnavailable);
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
