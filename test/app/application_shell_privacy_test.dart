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
  test(
    'current app signs out, retries and reopens without future owners',
    () async {
      final directory = Directory.systemTemp.createTempSync('shell-sign-out-');
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      late AccountPrivacy privacy;
      final shell = ShellRuntime.compose(
        authentication: auth,
        privacy: () => privacy,
      );
      privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: [createAuthenticationPrivacyParticipant(auth), shell],
        stateDirectory: directory,
        requiredParticipants: const {
          AccountPrivacyParticipantId.authenticationSession,
          AccountPrivacyParticipantId.applicationShell,
        },
      );
      addTearDown(() async {
        await shell.dispose();
        await disposeAccountPrivacy(privacy);
        await auth.changes.close();
        directory.deleteSync(recursive: true);
      });
      await shell.initialize();
      expect(shell.state.gate, ShellGate.opened);
      await shell.signOut();
      expect(
        shell.state.gate,
        ShellGate.authentication,
        reason: 'Successful logout must return to login, not unavailable',
      );
      await shell.retry();
      expect(shell.state.gate, ShellGate.authentication);
      auth.restored = const AuthenticatedSession(accountA);
      await shell.retry();
      expect(shell.state.gate, ShellGate.opened);
      await shell.signOut();
      expect(shell.state.gate, ShellGate.authentication);
    },
  );

  test(
    'current build recovers a persisted logout barrier from the old build',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'shell-old-logout-',
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
      await shell.signOut();
      expect(shell.state.gate, ShellGate.recovery);
      await shell.dispose();
      await disposeAccountPrivacy(privacy);
      shell = ShellRuntime.compose(
        authentication: auth,
        privacy: () => privacy,
      );
      privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: [createAuthenticationPrivacyParticipant(auth), shell],
        requiredParticipants: const {
          AccountPrivacyParticipantId.authenticationSession,
          AccountPrivacyParticipantId.applicationShell,
        },
        stateDirectory: directory,
      );
      addTearDown(() async {
        await shell.dispose();
        await disposeAccountPrivacy(privacy);
        await auth.changes.close();
        directory.deleteSync(recursive: true);
      });
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
    },
  );

  for (final registerOwner in [false, true]) {
    test(
      'active manifest still blocks ${registerOwner ? "registered" : "required missing"} owner failure',
      () async {
        final directory = Directory.systemTemp.createTempSync(
          'shell-active-owner-',
        );
        final auth = FakeAuthenticationSession()
          ..restored = const AuthenticatedSession(accountA);
        late AccountPrivacy privacy;
        final shell = ShellRuntime.compose(
          authentication: auth,
          privacy: () => privacy,
        );
        privacy = createAccountPrivacy(
          authenticationSession: auth,
          participants: [
            createAuthenticationPrivacyParticipant(auth),
            shell,
            if (registerOwner) _FailingMapOwner(),
          ],
          requiredParticipants: {
            AccountPrivacyParticipantId.authenticationSession,
            AccountPrivacyParticipantId.applicationShell,
            if (!registerOwner) AccountPrivacyParticipantId.mapLocation,
          },
          stateDirectory: directory,
        );
        addTearDown(() async {
          await shell.dispose();
          await disposeAccountPrivacy(privacy);
          await auth.changes.close();
          directory.deleteSync(recursive: true);
        });
        await shell.initialize();
        await shell.signOut();
        expect(shell.state.gate, ShellGate.recovery);
        await shell.retry();
        expect(shell.state.gate, ShellGate.recovery);
        expect(privacy.readScope(), isA<AccountScopeClosing>());
        final incomplete =
            shell.state.closeOutcome as AccountScopeCloseIncomplete;
        expect(
          incomplete.incomplete.single.participantId,
          AccountPrivacyParticipantId.mapLocation,
        );
      },
    );
  }

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

final class _FailingMapOwner implements AccountPrivacyParticipant {
  @override
  AccountPrivacyParticipantId get participantId =>
      AccountPrivacyParticipantId.mapLocation;
  @override
  Future<PrivateStateClearOutcome> clearPrivateState(
    AccountScope scope,
  ) async => PrivateStateClearIncomplete(
    participantId,
    scope,
    PrivateStateClearFailure.localStoreUnavailable,
  );
}
