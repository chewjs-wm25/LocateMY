import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'live Auth identity, current device exit proof and A to B privacy barrier',
    () async {
      HttpOverrides.global = null;
      final env = Platform.environment;
      final client = SupabaseClient(
        env['SUPABASE_URL']!,
        env['SUPABASE_PUBLISHABLE_KEY']!,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final other = SupabaseClient(
        env['SUPABASE_URL']!,
        env['SUPABASE_PUBLISHABLE_KEY']!,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final directory = Directory.systemTemp.createTempSync('privacy-live-');
      final auth = createAuthenticationSession(client);
      final otherAuth = createAuthenticationSession(other);
      final participant = createAuthenticationPrivacyParticipant(auth);
      final privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: [participant],
        stateDirectory: directory,
      );
      try {
        const invalid = AuthenticatedAccount(
          accountId: 'invalid',
          email: 'fixture@example.com',
          confirmation: EmailConfirmation.confirmed,
        );
        expect(await privacy.open(invalid), isA<AccountScopeOpenRejected>());
        expect(
          await auth.signIn(
            email: env['LOCATEMY_EMAIL']!,
            password: env['LOCATEMY_PASSWORD']!,
          ),
          isA<SignInSucceeded>(),
        );
        expect(
          await otherAuth.signIn(
            email: env['LOCATEMY_EMAIL']!,
            password: env['LOCATEMY_PASSWORD']!,
          ),
          isA<SignInSucceeded>(),
        );
        final a = (await auth.restoreSession() as AuthenticatedSession).account;
        final opened = await privacy.open(a);
        expect(opened, isA<AccountScopeOpenedForAccount>());
        final scope = (opened as AccountScopeOpenedForAccount).scope;
        expect(
          await participant.clearPrivateState(scope),
          isA<PrivateStateClearIncomplete>(),
        );
        expect(await auth.signOut(), isA<SignOutSucceeded>());
        expect(
          await participant.clearPrivateState(scope),
          isA<PrivateStateCleared>(),
        );
        final incomplete = await privacy.close(
          scope,
          AccountScopeCloseReason.signOut,
        ) as AccountScopeCloseIncomplete;
        expect(
          incomplete.incomplete.map((p) => p.participantId).toSet(),
          AccountPrivacyParticipantId.values
              .where(
                (id) => id != AccountPrivacyParticipantId.authenticationSession,
              )
              .toSet(),
        );
        expect(await otherAuth.restoreSession(), isA<AuthenticatedSession>());
        expect(
          await auth.signIn(
            email: env['LOCATEMY_PRIVACY_B_EMAIL']!,
            password: env['LOCATEMY_PRIVACY_B_PASSWORD']!,
          ),
          isA<SignInSucceeded>(),
        );
        final b = (await auth.restoreSession() as AuthenticatedSession).account;
        expect(b.accountId, isNot(a.accountId));
        expect(await privacy.open(b), isA<AccountScopeOpenRejected>());
        expect(privacy.readScope(), isA<AccountScopeClosing>());
        // Seven future production participants are deliberately absent.
        // Full barrier completion/A→B is tested with marked fakes/device harness.
        stdout.writeln(
          'PASS: live identity/open; ended-session proof; seven missing owners block B; other device retained',
        );
      } finally {
        await auth.signOut();
        await otherAuth.signOut();
        await disposeAccountPrivacy(privacy);
        await client.dispose();
        await other.dispose();
        directory.deleteSync(recursive: true);
      }
    },
    skip: Platform.environment['LOCATEMY_PRIVACY_LIVE'] != '1',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
