import 'dart:io';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';

import '../../support/fake_authentication_session.dart';

final class TestParticipant implements AccountPrivacyParticipant {
  @override
  final AccountPrivacyParticipantId participantId;
  PrivateStateClearFailure? failure;
  Future<PrivateStateClearOutcome> Function(AccountScope)? response;
  TestParticipant(this.participantId);
  @override
  Future<PrivateStateClearOutcome> clearPrivateState(AccountScope scope) async {
    final Future<PrivateStateClearOutcome> Function(AccountScope)? handler =
        response;
    if (handler != null) {
      return await handler(scope);
    }
    final PrivateStateClearFailure? currentFailure = failure;
    if (currentFailure == null) {
      return PrivateStateCleared(participantId, scope);
    }
    return PrivateStateClearIncomplete(participantId, scope, currentFailure);
  }
}

final class UnavailableRegistration implements AccountPrivacyParticipant {
  @override
  AccountPrivacyParticipantId get participantId {
    throw StateError('registration unavailable');
  }

  @override
  Future<PrivateStateClearOutcome> clearPrivateState(AccountScope scope) async {
    throw StateError('unregistered owner');
  }
}

void main() {
  late Directory directory;
  test('ordinary restart with unavailable or different Auth blocks the old account before login', () async {
    for (final fact in [
      const UnauthenticatedSession(),
      ...SessionFailure.values.map(SessionUnavailable.new),
      const AuthenticatedSession(accountB),
    ]) {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: [],
        stateDirectory: directory,
      );
      await privacy.open(accountA);
      await disposeAccountPrivacy(privacy);
      auth.restored = fact;
      final restarted = createAccountPrivacy(
        authenticationSession: auth,
        participants: [],
        stateDirectory: directory,
      );
      final account = fact is AuthenticatedSession ? fact.account : accountA;
      expect(await restarted.open(account), isA<AccountScopeOpenRejected>());
      expect(
        (restarted.readScope() as AccountScopeClosing).scope.accountId,
        'a',
      );
      auth.restored = const AuthenticatedSession(accountB);
      expect(await restarted.open(accountB), isA<AccountScopeOpenRejected>());
      await disposeAccountPrivacy(restarted);
      await auth.changes.close();
      directory.deleteSync(recursive: true);
      directory.createSync();
    }
  });
  test(
    'ordinary same-account restart can reopen without clearing private drafts',
    () async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: [],
        stateDirectory: directory,
      );
      await privacy.open(accountA);
      await disposeAccountPrivacy(privacy);
      final restarted = createAccountPrivacy(
        authenticationSession: auth,
        participants: [],
        stateDirectory: directory,
      );
      expect(restarted.readScope(), isNot(isA<AccountScopeOpened>()));
      expect(
        await restarted.open(accountA),
        isA<AccountScopeOpenedForAccount>(),
      );
      await disposeAccountPrivacy(restarted);
      await auth.changes.close();
    },
  );
  test('temporarily unreadable restart journal cannot be overwritten by a new open', () async {
    final auth = FakeAuthenticationSession()
      ..restored = const AuthenticatedSession(accountA);
    final privacy = createAccountPrivacy(
      authenticationSession: auth,
      participants: [],
      stateDirectory: directory,
    );
    final scope =
        (await privacy.open(accountA) as AccountScopeOpenedForAccount).scope;
    await privacy.close(scope, AccountScopeCloseReason.signOut);
    await disposeAccountPrivacy(privacy);
    Process.runSync('chmod', ['000', directory.path]);
    late AccountPrivacy recovered;
    try {
      recovered = createAccountPrivacy(
        authenticationSession: auth,
        participants: [],
        stateDirectory: directory,
      );
      expect(recovered.readScope(), isNot(isA<AccountScopeOpened>()));
    } finally {
      Process.runSync('chmod', ['700', directory.path]);
    }
    expect(await recovered.open(accountA), isA<AccountScopeOpenRejected>());
    expect(recovered.readScope(), isA<AccountScopeClosing>());
    await disposeAccountPrivacy(recovered);
    await auth.changes.close();
  });
  test('barrier file cleanup failure remains closing without blaming a cleared owner', () async {
    final auth = FakeAuthenticationSession()
      ..restored = const AuthenticatedSession(accountA);
    final participants = AccountPrivacyParticipantId.values
        .map(TestParticipant.new)
        .toList();
    final privacy = createAccountPrivacy(
      authenticationSession: auth,
      participants: participants,
      stateDirectory: directory,
    );
    final scope =
        (await privacy.open(accountA) as AccountScopeOpenedForAccount).scope;
    Process.runSync('chmod', ['500', directory.path]);
    try {
      final result = await privacy.close(
        scope,
        AccountScopeCloseReason.signOut,
      );
      expect(result, isA<AccountScopeCloseRejected>());
      expect(
        (result as AccountScopeCloseRejected).failure,
        AccountScopeFailure.retryableUnavailable,
      );
      expect(privacy.readScope(), isA<AccountScopeClosing>());
    } finally {
      Process.runSync('chmod', ['700', directory.path]);
    }
    expect(
      await privacy.close(scope, AccountScopeCloseReason.signOut),
      isA<AccountScopeClosedForAccount>(),
    );
    await disposeAccountPrivacy(privacy);
    await auth.changes.close();
  });
  test(
    'fresh B authentication cannot replace opened A before A cleanup',
    () async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: [],
        stateDirectory: directory,
      );
      final scope =
          (await privacy.open(accountA) as AccountScopeOpenedForAccount).scope;
      auth.restored = const AuthenticatedSession(accountB);
      expect(await privacy.open(accountB), isA<AccountScopeOpenRejected>());
      expect((privacy.readScope() as AccountScopeClosing).scope, same(scope));
      await disposeAccountPrivacy(privacy);
      await auth.changes.close();
    },
  );
  test(
    'unavailable participant registration remains a typed incomplete barrier',
    () async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: [UnavailableRegistration()],
        stateDirectory: directory,
      );
      final scope =
          (await privacy.open(accountA) as AccountScopeOpenedForAccount).scope;
      final result = await privacy.close(
        scope,
        AccountScopeCloseReason.signOut,
      ) as AccountScopeCloseIncomplete;
      expect(
        result.incomplete.map((p) => p.participantId).toSet(),
        AccountPrivacyParticipantId.values.toSet(),
      );
      expect(privacy.readScope(), isA<AccountScopeClosing>());
      await disposeAccountPrivacy(privacy);
      await auth.changes.close();
    },
  );
  test(
    'unwritable local storage never opens and can recover before authorization',
    () async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final blocked = File('${directory.path}/blocked')
        ..writeAsStringSync('file instead of directory');
      final privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: [],
        stateDirectory: Directory(blocked.path),
      );
      expect(await privacy.open(accountA), isA<AccountScopeOpenRejected>());
      expect(privacy.readScope(), isNot(isA<AccountScopeOpened>()));
      blocked.deleteSync();
      expect(await privacy.open(accountA), isA<AccountScopeOpenedForAccount>());
      await disposeAccountPrivacy(privacy);
      await auth.changes.close();
    },
  );
  test('corrupt persisted barriers fail closed on restart', () async {
    final auth = FakeAuthenticationSession()
      ..restored = const AuthenticatedSession(accountA);
    final privacy = createAccountPrivacy(
      authenticationSession: auth,
      participants: [],
      stateDirectory: directory,
    );
    await privacy.open(accountA);
    await disposeAccountPrivacy(privacy);
    (directory.listSync().single as File).writeAsStringSync('corrupt barrier');
    final recovered = createAccountPrivacy(
      authenticationSession: auth,
      participants: [],
      stateDirectory: directory,
    );
    expect(recovered.readScope(), isA<AccountScopeUnavailable>());
    expect(await recovered.open(accountA), isA<AccountScopeOpenRejected>());
    await disposeAccountPrivacy(recovered);
    await auth.changes.close();
  });
  test('concurrent calls preserve scope identity and switching rejects stale scopes', () async {
    final auth = FakeAuthenticationSession()
      ..restored = const AuthenticatedSession(accountA);
    final participants = AccountPrivacyParticipantId.values
        .map(TestParticipant.new)
        .toList();
    final privacy = createAccountPrivacy(
      authenticationSession: auth,
      participants: participants,
      stateDirectory: directory,
    );
    final opened = await Future.wait([
      privacy.open(accountA),
      privacy.open(accountA),
    ]);
    final scope = (opened.first as AccountScopeOpenedForAccount).scope;
    expect((opened.last as AccountScopeOpenedForAccount).scope, same(scope));
    expect(
      await privacy.close(
        AccountScope(scope.accountId),
        AccountScopeCloseReason.signOut,
      ),
      isA<AccountScopeCloseRejected>(),
    );
    final delayed = Completer<PrivateStateClearOutcome>();
    participants.last.response = (_) => delayed.future;
    final close1 = privacy.close(scope, AccountScopeCloseReason.accountSwitch);
    final close2 = privacy.close(scope, AccountScopeCloseReason.signOut);
    auth.restored = const AuthenticatedSession(accountB);
    expect(await privacy.open(accountB), isA<AccountScopeOpenRejected>());
    delayed.complete(
      PrivateStateCleared(participants.last.participantId, scope),
    );
    expect(await close1, isA<AccountScopeClosedForAccount>());
    expect(await close2, isA<AccountScopeClosedForAccount>());
    final next = await privacy.open(accountB) as AccountScopeOpenedForAccount;
    expect(next.scope.accountId, 'b');
    expect(
      await privacy.close(scope, AccountScopeCloseReason.signOut),
      isA<AccountScopeCloseRejected>(),
    );
    expect((privacy.readScope() as AccountScopeOpened).scope, same(next.scope));
    await auth.changes.close();
  });
  test(
    'late cleanup from a disposed coordinator cannot erase a restart barrier',
    () async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final participants = AccountPrivacyParticipantId.values
          .map(TestParticipant.new)
          .toList();
      final privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: participants,
        stateDirectory: directory,
      );
      final scope =
          (await privacy.open(accountA) as AccountScopeOpenedForAccount).scope;
      final delayed = Completer<PrivateStateClearOutcome>();
      participants.last.response = (_) => delayed.future;
      final closing = privacy.close(scope, AccountScopeCloseReason.signOut);
      await Future<void>.delayed(Duration.zero);
      await disposeAccountPrivacy(privacy);
      delayed.complete(
        PrivateStateCleared(participants.last.participantId, scope),
      );
      expect(await closing, isA<AccountScopeCloseIncomplete>());
      final recovered = createAccountPrivacy(
        authenticationSession: auth,
        participants: [],
        stateDirectory: directory,
      );
      expect(recovered.readScope(), isA<AccountScopeClosing>());
      await disposeAccountPrivacy(recovered);
      await auth.changes.close();
    },
  );
  test(
    'fresh unavailable or mismatched Auth facts revoke an existing scope',
    () async {
      for (final fact in [
        const SessionUnavailable(SessionFailure.retryableUnavailable),
        const UnauthenticatedSession(),
        const AuthenticatedSession(accountB),
      ]) {
        final auth = FakeAuthenticationSession()
          ..restored = const AuthenticatedSession(accountA);
        final privacy = createAccountPrivacy(
          authenticationSession: auth,
          participants: [],
          stateDirectory: directory,
        );
        await privacy.open(accountA);
        auth.restored = fact;
        expect(await privacy.open(accountA), isA<AccountScopeOpenRejected>());
        expect(privacy.readScope(), isA<AccountScopeClosing>());
        await disposeAccountPrivacy(privacy);
        await auth.changes.close();
        directory.deleteSync(recursive: true);
        directory.createSync();
      }
    },
  );
  test('a stalled participant reports retryable failure and late proof cannot bypass retry', () async {
    final auth = FakeAuthenticationSession()
      ..restored = const AuthenticatedSession(accountA);
    final participants = AccountPrivacyParticipantId.values
        .map(TestParticipant.new)
        .toList();
    final delayed = Completer<PrivateStateClearOutcome>();
    participants.last.response = (_) => delayed.future;
    final privacy = createAccountPrivacy(
      authenticationSession: auth,
      participants: participants,
      stateDirectory: directory,
      participantTimeout: const Duration(milliseconds: 10),
    );
    final scope =
        (await privacy.open(accountA) as AccountScopeOpenedForAccount).scope;
    final result = await privacy.close(
      scope,
      AccountScopeCloseReason.signOut,
    ) as AccountScopeCloseIncomplete;
    expect(
      result.incomplete.single.failure,
      PrivateStateClearFailure.retryableUnavailable,
    );
    delayed.complete(
      PrivateStateCleared(participants.last.participantId, scope),
    );
    await Future<void>.delayed(Duration.zero);
    expect(privacy.readScope(), isA<AccountScopeClosing>());
    participants.last.response = null;
    expect(
      await privacy.close(scope, AccountScopeCloseReason.signOut),
      isA<AccountScopeClosedForAccount>(),
    );
    await auth.changes.close();
  });
  test('each owner failure remains precise and retries never restore already cleared state', () async {
    for (final id in AccountPrivacyParticipantId.values) {
      for (final failure in PrivateStateClearFailure.values) {
        final auth = FakeAuthenticationSession()
          ..restored = const AuthenticatedSession(accountA);
        final participants = AccountPrivacyParticipantId.values
            .map(TestParticipant.new)
            .toList();
        participants[id.index].failure = failure;
        final privacy = createAccountPrivacy(
          authenticationSession: auth,
          participants: participants,
          stateDirectory: directory,
        );
        final scope = (await privacy.open(
          accountA,
        ) as AccountScopeOpenedForAccount).scope;
        final first = await privacy.close(
          scope,
          AccountScopeCloseReason.signOut,
        ) as AccountScopeCloseIncomplete;
        expect(first.incomplete.single.participantId, id);
        expect(first.incomplete.single.failure, failure);
        for (final p in participants) {
          p.failure = PrivateStateClearFailure.localStoreUnavailable;
        }
        participants[id.index].failure = null;
        expect(
          await privacy.close(scope, AccountScopeCloseReason.signOut),
          isA<AccountScopeClosedForAccount>(),
        );
        await disposeAccountPrivacy(privacy);
        await auth.changes.close();
      }
    }
  });
  test('missing registrations, duplicate registrations and forged proofs cannot close', () async {
    for (final mode in [
      'missing',
      'duplicate',
      'wrongId',
      'wrongScope',
      'throw',
    ]) {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final participants = AccountPrivacyParticipantId.values
          .map(TestParticipant.new)
          .toList();
      final target = participants.last;
      if (mode == 'missing') participants.removeLast();
      if (mode == 'duplicate') {
        participants.add(TestParticipant(target.participantId));
      }
      if (mode == 'wrongId') {
        target.response = (scope) async =>
            PrivateStateCleared(AccountPrivacyParticipantId.mapLocation, scope);
      }
      if (mode == 'wrongScope') {
        target.response = (scope) async => PrivateStateCleared(
          target.participantId,
          AccountScope(scope.accountId),
        );
      }
      if (mode == 'throw') {
        target.response = (_) async => throw StateError('store failure');
      }
      final privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: participants,
        stateDirectory: directory,
      );
      final scope =
          (await privacy.open(accountA) as AccountScopeOpenedForAccount).scope;
      final result = await privacy.close(
        scope,
        AccountScopeCloseReason.signOut,
      ) as AccountScopeCloseIncomplete;
      expect(result.incomplete.single.participantId, target.participantId);
      expect(privacy.readScope(), isA<AccountScopeClosing>());
      await disposeAccountPrivacy(privacy);
      await auth.changes.close();
      directory.deleteSync(recursive: true);
      directory.createSync();
    }
  });
  test(
    'authentication loss blocks an opened scope and invalidates pending opens',
    () async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: [],
        stateDirectory: directory,
      );
      final scope =
          (await privacy.open(accountA) as AccountScopeOpenedForAccount).scope;
      final delayed = Completer<SessionSnapshot>();
      auth.pendingRestore = delayed.future;
      final opening = privacy.open(accountA);
      auth.changes.add(const UnauthenticatedSession());
      expect(privacy.readScope(), isA<AccountScopeClosing>());
      delayed.complete(const AuthenticatedSession(accountA));
      expect(await opening, isA<AccountScopeOpenRejected>());
      expect(
        await privacy.close(scope, AccountScopeCloseReason.sessionInvalidated),
        isA<AccountScopeCloseIncomplete>(),
      );
      await auth.changes.close();
    },
  );
  setUp(() {
    directory = Directory.systemTemp.createTempSync('privacy-test-');
  });
  tearDown(() {
    directory.deleteSync(recursive: true);
  });
  test('restarting a coordinator restores closing and requires the old scope cleanup', () async {
    final auth = FakeAuthenticationSession()
      ..restored = const AuthenticatedSession(accountA);
    final privacy = createAccountPrivacy(
      authenticationSession: auth,
      participants: [],
      stateDirectory: directory,
    );
    final scope =
        (await privacy.open(accountA) as AccountScopeOpenedForAccount).scope;
    await privacy.close(scope, AccountScopeCloseReason.signOut);
    final recovered = createAccountPrivacy(
      authenticationSession: auth,
      participants: AccountPrivacyParticipantId.values
          .map(TestParticipant.new)
          .toList(),
      stateDirectory: directory,
    );
    expect(recovered.readScope(), isA<AccountScopeClosing>());
    expect(await recovered.open(accountA), isA<AccountScopeOpenRejected>());
    final oldScope = (recovered.readScope() as AccountScopeClosing).scope;
    expect(
      await recovered.close(oldScope, AccountScopeCloseReason.signOut),
      isA<AccountScopeClosedForAccount>(),
    );
    expect(await recovered.open(accountA), isA<AccountScopeOpenedForAccount>());
    await auth.changes.close();
  });
  test(
    'late authentication cannot reopen a scope after close starts',
    () async {
      final auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      final privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: [],
        stateDirectory: directory,
      );
      final scope =
          (await privacy.open(accountA) as AccountScopeOpenedForAccount).scope;
      final delayed = Completer<SessionSnapshot>();
      auth.pendingRestore = delayed.future;
      final opening = privacy.open(accountA);
      await privacy.close(scope, AccountScopeCloseReason.signOut);
      delayed.complete(const AuthenticatedSession(accountA));
      expect(await opening, isA<AccountScopeOpenRejected>());
      expect(privacy.readScope(), isA<AccountScopeClosing>());
      await auth.changes.close();
    },
  );
  test('closing immediately blocks access and only all eight proofs close the scope', () async {
    final auth = FakeAuthenticationSession()
      ..restored = const AuthenticatedSession(accountA);
    final participants = AccountPrivacyParticipantId.values
        .map(TestParticipant.new)
        .toList();
    participants.last.failure = PrivateStateClearFailure.fileCleanupIncomplete;
    final privacy = createAccountPrivacy(
      authenticationSession: auth,
      participants: participants,
      stateDirectory: directory,
    );
    final scope =
        (await privacy.open(accountA) as AccountScopeOpenedForAccount).scope;
    final closing = privacy.close(scope, AccountScopeCloseReason.signOut);
    expect(privacy.readScope(), isA<AccountScopeClosing>());
    final incomplete = await closing as AccountScopeCloseIncomplete;
    expect(
      incomplete.incomplete.single.participantId,
      AccountPrivacyParticipantId.accountCenter,
    );
    expect(await privacy.open(accountA), isA<AccountScopeOpenRejected>());
    participants.last.failure = null;
    expect(
      await privacy.close(scope, AccountScopeCloseReason.signOut),
      isA<AccountScopeClosedForAccount>(),
    );
    expect(privacy.readScope(), isA<AccountScopeClosed>());
    expect(
      await privacy.close(scope, AccountScopeCloseReason.signOut),
      isA<AccountScopeClosedForAccount>(),
    );
    await auth.changes.close();
  });
  test(
    'only the current authenticated account can open a private scope',
    () async {
      final auth = FakeAuthenticationSession();
      final privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: [],
        stateDirectory: directory,
      );
      expect(await privacy.open(accountA), isA<AccountScopeOpenRejected>());
      expect(privacy.readScope(), isNot(isA<AccountScopeOpened>()));
      auth.restored = const AuthenticatedSession(accountA);
      final result = await privacy.open(accountA);
      expect(result, isA<AccountScopeOpenedForAccount>());
      expect((privacy.readScope() as AccountScopeOpened).scope.accountId, 'a');
      expect(await privacy.open(accountB), isA<AccountScopeOpenRejected>());
      await auth.changes.close();
    },
  );
}
