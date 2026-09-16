import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';

import '../support/fake_authentication_session.dart';
import '../support/fake_account_privacy.dart';

final class UnknownIntent implements ShellIntent {}

final class ExploreIntent implements ShellIntent {}

final class UnknownContribution implements ShellContribution {}

final class AnalysisIntent implements ShellIntent {
  final ShellRequestContext context;
  final List<String> locations;
  const AnalysisIntent(this.context, this.locations);
}

final class DetailContribution implements ShellContribution {
  final ShellRequestContext context;
  final String availability;
  final String source;
  const DetailContribution(this.context, this.availability, this.source);
}

final class ControlledPrivacy implements AccountPrivacy {
  AccountScopeSnapshot snapshot = const AccountScopeUnavailable(
    AccountScopeFailure.scopeNotOpen,
  );
  Future<OpenAccountScopeOutcome>? pendingOpen;
  Future<CloseAccountScopeOutcome>? pendingClose;
  final scopes = <AccountScope>[];
  @override
  AccountScopeSnapshot readScope() => snapshot;
  @override
  Future<OpenAccountScopeOutcome> open(AuthenticatedAccount account) async {
    final result =
        await (pendingOpen ??
            Future.value(
              AccountScopeOpenedForAccount(AccountScope(account.accountId)),
            ));
    if (result is AccountScopeOpenedForAccount) {
      snapshot = AccountScopeOpened(result.scope);
    }
    return result;
  }

  @override
  Future<CloseAccountScopeOutcome> close(
    AccountScope scope,
    AccountScopeCloseReason reason,
  ) async {
    scopes.add(scope);
    snapshot = AccountScopeClosing(scope);
    final result =
        await (pendingClose ??
            Future.value(AccountScopeClosedForAccount(scope)));
    if (result is AccountScopeClosedForAccount) {
      snapshot = AccountScopeClosed(scope);
    }
    return result;
  }
}

void main() {
  test(
    'private intents require authenticated same-account opened scope',
    () async {
      final auth = FakeAuthenticationSession();
      final privacy = FakeAccountPrivacy();
      final shell = ShellRuntime(authentication: auth, privacy: privacy);
      await shell.initialize();
      expect(shell.state.gate, ShellGate.authentication);
      expect(
        await shell.submit(UnknownIntent()),
        isA<ShellAuthenticationRequired>(),
      );
      auth.restored = const AuthenticatedSession(accountA);
      privacy.opens.add(
        const AccountScopeOpenedForAccount(AccountScope('wrong')),
      );
      await shell.retry();
      expect(shell.state.gate, ShellGate.recovery);
      expect(
        await shell.publish(UnknownContribution()),
        isA<ShellContributionAuthenticationRequired>(),
      );
      await shell.dispose();
      await auth.changes.close();
    },
  );
  test(
    'close hides private state immediately and retries the same old scope',
    () async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final privacy = ControlledPrivacy();
      final shell = ShellRuntime(authentication: auth, privacy: privacy);
      await shell.initialize();
      final oldScope = shell.state.scope!;
      final pending = Completer<CloseAccountScopeOutcome>();
      privacy.pendingClose = pending.future;
      final exiting = shell.signOut();
      expect(shell.state.gate, ShellGate.closing);
      expect(shell.state.account, isNull);
      expect(
        await shell.submit(UnknownIntent()),
        isA<ShellAuthenticationRequired>(),
      );
      await Future<void>.delayed(Duration.zero);
      pending.complete(
        AccountScopeCloseIncomplete(oldScope, [
          PrivateStateClearIncomplete(
            AccountPrivacyParticipantId.propertyInspection,
            oldScope,
            PrivateStateClearFailure.fileCleanupIncomplete,
          ),
        ]),
      );
      await exiting;
      expect(shell.state.gate, ShellGate.recovery);
      auth.changes.add(const AuthenticatedSession(accountB));
      await Future<void>.delayed(Duration.zero);
      expect(shell.state.gate, ShellGate.recovery);
      privacy.pendingClose = Future.value(
        AccountScopeClosedForAccount(oldScope),
      );
      await shell.retry();
      expect(shell.state.gate, ShellGate.authentication);
      expect(privacy.scopes, [same(oldScope), same(oldScope)]);
      await shell.dispose();
      await auth.changes.close();
    },
  );

  test(
    'typed navigation keeps ordered snapshots and original return context',
    () async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final shell = ShellRuntime(
        authentication: auth,
        privacy: ControlledPrivacy(),
        intents: [
          ShellIntentBinding<AnalysisIntent>(
            (input) => input.locations.isEmpty
                ? const ShellRouteRequest.rejected(
                    ShellRejectionReason.missingInput,
                  )
                : ShellRouteRequest.task(
                    context: input.context,
                    destination: 'analysis',
                  ),
          ),
        ],
      );
      await shell.initialize();
      final origin = shell.currentContext!;
      final missing = await shell.submit(AnalysisIntent(origin, const []));
      expect(
        (missing as ShellIntentRejected).reason,
        ShellRejectionReason.missingInput,
      );
      final input = AnalysisIntent(origin, const ['B-location', 'A-location']);
      expect(await shell.submit(input), isA<ShellIntentAccepted>());
      expect(shell.state.routes.single.intent, same(input));
      expect(
        (await shell.submit(input) as ShellIntentRejected).reason,
        ShellRejectionReason.staleInput,
      );
      shell.back();
      expect(shell.currentContext, same(origin));
      expect(shell.state.routes, isEmpty);
      await shell.dispose();
      await auth.changes.close();
    },
  );

  test('progressive contributions retain unavailable and metadata; stale cannot replace', () async {
    final auth = FakeAuthenticationSession()
      ..restored = const AuthenticatedSession(accountA);
    final shell = ShellRuntime(
      authentication: auth,
      privacy: ControlledPrivacy(),
      contributions: [
        ShellContributionBinding<DetailContribution>(
          (input) =>
              ShellSlotRequest(context: input.context, slot: input.source),
        ),
      ],
    );
    await shell.initialize();
    final context = shell.currentContext!;
    final unavailable = DetailContribution(
      context,
      'unavailable',
      'official / 2025 / state',
    );
    final partial = DetailContribution(context, 'partial', 'OSM / 2026 / 2 km');
    expect(await shell.publish(unavailable), isA<ShellContributionAccepted>());
    expect(await shell.publish(partial), isA<ShellContributionAccepted>());
    expect(shell.state.slots.values, [same(unavailable), same(partial)]);
    shell.beginRequest();
    expect(
      (await shell.publish(unavailable) as ShellContributionRejected).reason,
      ShellRejectionReason.staleInput,
    );
    expect(shell.state.slots, isEmpty);
    await shell.dispose();
    await auth.changes.close();
  });

  test(
    'sign out during pending open cannot show login before old scope closes',
    () async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final privacy = ControlledPrivacy();
      final pending = Completer<OpenAccountScopeOutcome>();
      privacy.pendingOpen = pending.future;
      final shell = ShellRuntime(authentication: auth, privacy: privacy);
      final starting = shell.initialize();
      await Future<void>.delayed(Duration.zero);
      final exiting = shell.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(shell.state.gate, ShellGate.closing);
      final scope = AccountScope('a');
      pending.complete(AccountScopeOpenedForAccount(scope));
      await starting;
      await exiting;
      expect(privacy.scopes, [same(scope)]);
      expect(shell.state.gate, ShellGate.authentication);
      await shell.dispose();
      await auth.changes.close();
    },
  );

  test(
    'repeated same-account facts during open do not reset or close its scope',
    () async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final privacy = ControlledPrivacy();
      final pending = Completer<OpenAccountScopeOutcome>();
      privacy.pendingOpen = pending.future;
      final shell = ShellRuntime(authentication: auth, privacy: privacy);
      final starting = shell.initialize();
      await Future<void>.delayed(Duration.zero);
      auth.changes.add(const AuthenticatedSession(accountA));
      pending.complete(const AccountScopeOpenedForAccount(AccountScope('a')));
      await starting;
      await Future<void>.delayed(Duration.zero);
      expect(shell.state.gate, ShellGate.opened);
      expect(privacy.scopes, isEmpty);
      await shell.dispose();
      await auth.changes.close();
    },
  );

  test(
    'old scoped Shell cannot replay a fieldless intent into a new account',
    () async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      late ShellRuntime shell;
      shell = ShellRuntime(
        authentication: auth,
        privacy: ControlledPrivacy(),
        intents: [
          ShellIntentBinding<ExploreIntent>(
            (_) => ShellRouteRequest.tab(
              context: shell.currentContext,
              tab: ShellTab.map,
            ),
          ),
        ],
      );
      await shell.initialize();
      final oldShell = shell.applicationShell!;
      expect(
        await oldShell.submit(ExploreIntent()),
        isA<ShellIntentAccepted>(),
      );
      await shell.signOut();
      auth.restored = const AuthenticatedSession(
        AuthenticatedAccount(
          accountId: 'b',
          email: 'b@example.com',
          confirmation: EmailConfirmation.confirmed,
        ),
      );
      await shell.retry();
      expect(shell.state.selectedTab, ShellTab.home);
      expect(
        await oldShell.submit(ExploreIntent()),
        isA<ShellAuthenticationRequired>(),
      );
      expect(shell.state.selectedTab, ShellTab.home);
      expect(
        await oldShell.publish(UnknownContribution()),
        isA<ShellContributionAuthenticationRequired>(),
      );
      await shell.dispose();
      await auth.changes.close();
    },
  );
  test(
    'failed sign out without an opened scope retries exit instead of reopening',
    () async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(
          AuthenticatedAccount(
            accountId: 'a',
            email: 'a@example.com',
            confirmation: EmailConfirmation.verificationRequired,
          ),
        );
      final privacy = ControlledPrivacy();
      final shell = ShellRuntime(authentication: auth, privacy: privacy);
      await shell.initialize();
      auth.signedOut = const SignOutRejected(
        SignOutFailure.retryableUnavailable,
      );
      await shell.signOut();
      auth.restored = const AuthenticatedSession(accountA);
      await shell.retry();
      expect(shell.state.gate, ShellGate.recovery);
      expect(shell.state.signOutFailure, SignOutFailure.retryableUnavailable);
      auth.signedOut = const SignOutSucceeded();
      await shell.retry();
      expect(shell.state.gate, ShellGate.authentication);
      await shell.dispose();
      await auth.changes.close();
    },
  );
}
