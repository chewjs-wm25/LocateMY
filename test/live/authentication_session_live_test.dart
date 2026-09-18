import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('SDK sign in, cached identity and current device sign out', () async {
    HttpOverrides.global = null;
    final Map<String, String> env = Platform.environment;
    final SupabaseClient client = SupabaseClient(
      env['SUPABASE_URL']!,
      env['SUPABASE_PUBLISHABLE_KEY']!,
    );
    final AuthenticationSession auth = createAuthenticationSession(client);
    try {
      expect(
        await auth.signIn(
          email: env['LOCATEMY_EMAIL']!,
          password: env['LOCATEMY_PASSWORD']!,
        ),
        isA<SignInSucceeded>(),
      );
      final AuthenticatedSession identity =
          await auth.restoreSession() as AuthenticatedSession;
      expect(identity.account.accountId, client.auth.currentUser!.id);
      expect(identity.account.email, env['LOCATEMY_EMAIL']);
      expect(await auth.signOut(), isA<SignOutSucceeded>());
      expect(await auth.restoreSession(), isA<UnauthenticatedSession>());
    } finally {
      await client.dispose();
    }
  }, skip: Platform.environment['LOCATEMY_AUTH_LIVE'] != '1');
  test(
    'SDK registration signs in immediately without email confirmation',
    () async {
      HttpOverrides.global = null;
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final Map<String, String> env = Platform.environment;
      final SupabaseClient client = SupabaseClient(
        env['SUPABASE_URL']!,
        env['SUPABASE_PUBLISHABLE_KEY']!,
        authOptions: AuthClientOptions(
          pkceAsyncStorage: SharedPreferencesGotrueAsyncStorage(),
        ),
      );
      try {
        final AuthenticationSession auth = createAuthenticationSession(client);
        final RegistrationOutcome result = await auth.register(
          email: env['LOCATEMY_REGISTRATION_EMAIL']!,
          password: env['LOCATEMY_REGISTRATION_PASSWORD']!,
          passwordConfirmation: env['LOCATEMY_REGISTRATION_PASSWORD']!,
        );
        expect(
          result,
          isA<RegistrationAuthenticated>(),
          reason: result is RegistrationRejected ? result.failure.name : null,
        );
        expect(await auth.restoreSession(), isA<AuthenticatedSession>());
        expect(await auth.signOut(), isA<SignOutSucceeded>());
      } finally {
        await client.dispose();
      }
    },
    skip: Platform.environment['LOCATEMY_REGISTRATION_LIVE'] != '1',
  );
}
