import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';

import '../support/fake_authentication_session.dart';

// Test-only future Owner proof; never a production registration.
final class TestOwnerProof implements AccountPrivacyParticipant {
  @override
  final AccountPrivacyParticipantId participantId;
  TestOwnerProof(this.participantId);
  @override
  Future<PrivateStateClearOutcome> clearPrivateState(
    AccountScope scope,
  ) async => PrivateStateCleared(participantId, scope);
}

void main() {
  test('real Privacy and Shell keep missing-owner barrier and recover across restart', () async {
    final directory = Directory.systemTemp.createTempSync(
      'shell-privacy-test-',
    );
    final auth = FakeAuthenticationSession()
      ..restored = const AuthenticatedSession(accountA);
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
    await shell.initialize();
    expect(shell.state.gate, ShellGate.opened);
    shell.selectTab(ShellTab.map);
    shell.openAccountTask();
    await shell.signOut();
    expect(shell.state.gate, ShellGate.recovery);
    final incomplete = shell.state.closeOutcome as AccountScopeCloseIncomplete;
    expect(
      incomplete.incomplete.map((p) => p.participantId).toSet(),
      AccountPrivacyParticipantId.values
          .where(
            (p) =>
                p != AccountPrivacyParticipantId.authenticationSession &&
                p != AccountPrivacyParticipantId.applicationShell,
          )
          .toSet(),
    );
    expect(shell.state.routes, isEmpty);
    expect(shell.state.slots, isEmpty);
    await shell.dispose();
    await disposeAccountPrivacy(privacy);
    shell = ShellRuntime.compose(authentication: auth, privacy: () => privacy);
    privacy = createAccountPrivacy(
      authenticationSession: auth,
      participants: [
        createAuthenticationPrivacyParticipant(auth),
        shell,
        ...AccountPrivacyParticipantId.values
            .where(
              (p) =>
                  p != AccountPrivacyParticipantId.authenticationSession &&
                  p != AccountPrivacyParticipantId.applicationShell,
            )
            .map(TestOwnerProof.new),
      ],
      stateDirectory: directory,
    );
    expect(privacy.readScope(), isA<AccountScopeClosing>());
    await shell.initialize();
    expect(shell.state.gate, ShellGate.authentication);
    auth.restored = const AuthenticatedSession(
      AuthenticatedAccount(
        accountId: 'b',
        email: 'b@example.com',
        confirmation: EmailConfirmation.confirmed,
      ),
    );
    await shell.retry();
    expect(shell.state.gate, ShellGate.opened);
    expect(shell.state.scope!.accountId, 'b');
    expect(shell.state.selectedTab, ShellTab.home);
    await shell.signOut();
    await shell.dispose();
    await disposeAccountPrivacy(privacy);
    await auth.changes.close();
    directory.deleteSync(recursive: true);
  });
}
