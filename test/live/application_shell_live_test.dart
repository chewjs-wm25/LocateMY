import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/application_shell_privacy_test.dart' show TestOwnerProof;

final class LiveLateIntent implements ShellIntent {}

void main() {
  test('live Shell, Auth and Privacy validate production barrier and scope restart', () async {
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
    final auth = createAuthenticationSession(client);
    final otherAuth = createAuthenticationSession(other);
    final directory = Directory.systemTemp.createTempSync('shell-live-');
    late AccountPrivacy privacy;
    var shell = ShellRuntime.compose(
      authentication: auth,
      privacy: () => privacy,
    );
    privacy = createAccountPrivacy(
      authenticationSession: auth,
      participants: [createAuthenticationPrivacyParticipant(auth), shell],
      stateDirectory: directory,
    );
    Future<void> waitOpened() async {
      if (shell.state.gate == ShellGate.opened) return;
      await shell.changes
          .firstWhere((s) => s.gate == ShellGate.opened)
          .timeout(const Duration(seconds: 30));
    }

    try {
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
      await shell.initialize();
      expect(shell.state.gate, ShellGate.opened);
      final originalAccount = shell.state.scope!.accountId;
      final oldShell = shell.applicationShell!;
      shell.selectTab(ShellTab.map);
      shell.openAccountTask();
      final ending = shell.signOut();
      expect(shell.state.account, isNull);
      expect(shell.state.routes, isEmpty);
      await ending;
      expect(shell.state.gate, ShellGate.recovery);
      final close = shell.state.closeOutcome as AccountScopeCloseIncomplete;
      expect(close.incomplete.length, 6);
      expect(
        close.incomplete.every(
          (p) =>
              p.participantId !=
                  AccountPrivacyParticipantId.authenticationSession &&
              p.participantId != AccountPrivacyParticipantId.applicationShell,
        ),
        isTrue,
      );
      expect(await otherAuth.restoreSession(), isA<AuthenticatedSession>());
      stdout.writeln(
        'PASS: real same-account gate; private barrier precedes current-device signOut/close; six missing owners; other session retained',
      );
      await shell.dispose();
      await disposeAccountPrivacy(privacy);
      shell = ShellRuntime.compose(
        authentication: auth,
        privacy: () => privacy,
      );
      privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: [
          createAuthenticationPrivacyParticipant(auth),
          shell,
          ...AccountPrivacyParticipantId.values
              .where(
                (id) =>
                    id != AccountPrivacyParticipantId.authenticationSession &&
                    id != AccountPrivacyParticipantId.applicationShell,
              )
              .map(TestOwnerProof.new),
        ],
        stateDirectory: directory,
      );
      expect(privacy.readScope(), isA<AccountScopeClosing>());
      await shell.initialize();
      expect(shell.state.gate, ShellGate.authentication);
      expect(
        await auth.signIn(
          email: env['LOCATEMY_SHELL_B_EMAIL']!,
          password: env['LOCATEMY_SHELL_B_PASSWORD']!,
        ),
        isA<SignInSucceeded>(),
      );
      await waitOpened();
      expect(shell.state.scope!.accountId, isNot(originalAccount));
      expect(shell.state.selectedTab, ShellTab.home);
      expect(
        await oldShell.submit(LiveLateIntent()),
        isA<ShellAuthenticationRequired>(),
      );
      await shell.signOut();
      expect(shell.state.gate, ShellGate.authentication);
      stdout.writeln(
        'PASS: real durable closing restart; marked future proofs allow recovery; real second account gets fresh home scope',
      );
    } finally {
      await auth.signOut();
      await otherAuth.signOut();
      await shell.dispose();
      await disposeAccountPrivacy(privacy);
      await client.dispose();
      await other.dispose();
      directory.deleteSync(recursive: true);
    }
  }, skip: Platform.environment['LOCATEMY_SHELL_LIVE'] != '1');
}
