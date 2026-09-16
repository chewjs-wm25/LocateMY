import 'dart:async';

import 'account_scope_store.dart';

import 'package:locatemy/features/authentication_session/authentication_session.dart';

import '../domain/account_privacy_models.dart';

final class AccountPrivacyCoordinator implements AccountPrivacy {
  final AuthenticationSession _auth;
  final Map<AccountPrivacyParticipantId, List<AccountPrivacyParticipant>>
  _participants = {};
  bool _registrationUnavailable = false;
  AccountScopeSnapshot _snapshot = const AccountScopeUnavailable(
    AccountScopeFailure.scopeNotOpen,
  );
  final AccountScopeStore _journal;
  final Duration _participantTimeout;
  bool _storeUnavailable = false;
  AccountScope? _recoverableScope;
  late final StreamSubscription<SessionSnapshot> _subscription;
  String? _observedAccount;
  bool _disposed = false;
  AccountPrivacyCoordinator(
    this._auth,
    List<AccountPrivacyParticipant> participants,
    this._journal,
    this._participantTimeout,
  ) {
    try {
      for (final participant in participants) {
        (_participants[participant.participantId] ??= []).add(participant);
      }
    } catch (_) {
      _registrationUnavailable = true;
      _participants.clear();
    }
    _restoreStore();
    _subscription = _auth.watchSession().listen(
      _observe,
      onDone: () => _observe(
        const SessionUnavailable(SessionFailure.retryableUnavailable),
      ),
      onError: (Object _) {
        _observe(const SessionUnavailable(SessionFailure.retryableUnavailable));
      },
    );
  }

  void _restoreStore() {
    try {
      final pending = _journal.readPending();
      _storeUnavailable = false;
      _recoverableScope = pending != null && !pending.closing
          ? AccountScope(pending.accountId)
          : null;
      _snapshot = pending != null && pending.closing
          ? AccountScopeClosing(AccountScope(pending.accountId))
          : const AccountScopeUnavailable(AccountScopeFailure.scopeNotOpen);
    } catch (_) {
      _storeUnavailable = true;
      _recoverableScope = null;
      _snapshot = const AccountScopeUnavailable(
        AccountScopeFailure.retryableUnavailable,
      );
    }
  }

  void _observe(SessionSnapshot fact) {
    final id = fact is AuthenticatedSession ? fact.account.accountId : null;
    final opened = _snapshot;
    if (id == null ||
        (_observedAccount != null && id != _observedAccount) ||
        (opened is AccountScopeOpened && opened.scope.accountId != id)) {
      ++_revision;
      if (opened is AccountScopeOpened) {
        _blockScope(opened.scope);
      }
    }
    final recovered = _recoverableScope;
    if (recovered != null && id != recovered.accountId) _blockScope(recovered);
    _observedAccount = id;
  }

  void _blockScope(AccountScope scope) {
    _recoverableScope = null;
    _snapshot = AccountScopeClosing(scope);
    try {
      _journal.recordClosing(scope.accountId);
    } catch (_) {
      // Access stays blocked; Shell close retries durable sealing before cleanup.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    ++_revision;
    if (_snapshot case AccountScopeOpened(:final scope)) {
      _snapshot = AccountScopeClosing(scope);
    }
    await _subscription.cancel();
  }

  @override
  AccountScopeSnapshot readScope() => _snapshot;

  final Set<AccountPrivacyParticipantId> _cleared = {};
  Future<CloseAccountScopeOutcome>? _closing;
  int _revision = 0;

  @override
  Future<OpenAccountScopeOutcome> open(AuthenticatedAccount account) async {
    if (!_disposed && _storeUnavailable) {
      _restoreStore();
    }
    if (_disposed || _storeUnavailable) {
      return const AccountScopeOpenRejected(
        AccountScopeFailure.retryableUnavailable,
      );
    }
    if (_snapshot is AccountScopeClosing) {
      return const AccountScopeOpenRejected(AccountScopeFailure.scopeClosing);
    }
    if (account.accountId.trim().isEmpty) {
      return const AccountScopeOpenRejected(
        AccountScopeFailure.identityMismatch,
      );
    }
    final revision = _revision;
    try {
      final current = await _auth.restoreSession();
      if (revision != _revision || _snapshot is AccountScopeClosing) {
        return const AccountScopeOpenRejected(AccountScopeFailure.scopeClosing);
      }
      if (_recoverableScope != null &&
          (current is! AuthenticatedSession ||
              current.account.accountId != _recoverableScope!.accountId)) {
        _blockScope(_recoverableScope!);
      }
      if (_snapshot is AccountScopeOpened) {
        _observe(current);
      } else {
        _observedAccount = current is AuthenticatedSession
            ? current.account.accountId
            : null;
      }
      if (_snapshot is AccountScopeClosing) {
        return const AccountScopeOpenRejected(
          AccountScopeFailure.identityMismatch,
        );
      }
      if (current is! AuthenticatedSession) {
        return const AccountScopeOpenRejected(
          AccountScopeFailure.retryableUnavailable,
        );
      }
      if (current.account.accountId != account.accountId) {
        return const AccountScopeOpenRejected(
          AccountScopeFailure.identityMismatch,
        );
      }
      if (_snapshot case AccountScopeOpened(:final scope)) {
        if (scope.accountId != account.accountId) {
          return const AccountScopeOpenRejected(
            AccountScopeFailure.identityMismatch,
          );
        }
        return AccountScopeOpenedForAccount(scope);
      }
      final scope = _recoverableScope ?? AccountScope(account.accountId);
      if (_recoverableScope == null) _journal.recordOpened(scope.accountId);
      _recoverableScope = null;
      _cleared.clear();
      _snapshot = AccountScopeOpened(scope);
      return AccountScopeOpenedForAccount(scope);
    } catch (_) {
      _observe(const SessionUnavailable(SessionFailure.retryableUnavailable));
      return const AccountScopeOpenRejected(
        AccountScopeFailure.retryableUnavailable,
      );
    }
  }

  @override
  Future<CloseAccountScopeOutcome> close(
    AccountScope scope,
    AccountScopeCloseReason reason,
  ) {
    if (_disposed) {
      return Future.value(
        AccountScopeCloseRejected(
          scope,
          AccountScopeFailure.retryableUnavailable,
        ),
      );
    }
    final current = switch (_snapshot) {
      AccountScopeOpened(:final scope) ||
      AccountScopeClosing(:final scope) ||
      AccountScopeClosed(:final scope) => scope,
      _ => null,
    };
    if (!identical(current, scope)) {
      return Future.value(
        AccountScopeCloseRejected(scope, AccountScopeFailure.identityMismatch),
      );
    }
    if (_snapshot is AccountScopeClosed) {
      return Future.value(AccountScopeClosedForAccount(scope));
    }
    if (_closing != null) return _closing!;
    ++_revision;
    _snapshot = AccountScopeClosing(scope);
    try {
      _journal.recordClosing(scope.accountId);
    } catch (_) {
      return Future.value(
        AccountScopeCloseRejected(
          scope,
          AccountScopeFailure.retryableUnavailable,
        ),
      );
    }
    final operation = _clear(scope);
    _closing = operation;
    operation.whenComplete(() => _closing = null);
    return operation;
  }

  Future<CloseAccountScopeOutcome> _clear(AccountScope scope) async {
    final incomplete = <PrivateStateClearIncomplete>[];
    for (final id in AccountPrivacyParticipantId.values) {
      if (_cleared.contains(id)) continue;
      if (_disposed) {
        incomplete.add(
          PrivateStateClearIncomplete(
            id,
            scope,
            PrivateStateClearFailure.retryableUnavailable,
          ),
        );
        continue;
      }
      final matches = _registrationUnavailable
          ? <AccountPrivacyParticipant>[]
          : (_participants[id] ?? <AccountPrivacyParticipant>[]);
      if (matches.length != 1) {
        incomplete.add(
          PrivateStateClearIncomplete(
            id,
            scope,
            PrivateStateClearFailure.scopeUnavailable,
          ),
        );
        continue;
      }
      try {
        final result = await matches.single
            .clearPrivateState(scope)
            .timeout(_participantTimeout);
        if (_disposed) {
          incomplete.add(
            PrivateStateClearIncomplete(
              id,
              scope,
              PrivateStateClearFailure.retryableUnavailable,
            ),
          );
          continue;
        }
        if (result is PrivateStateCleared &&
            result.participantId == id &&
            identical(result.scope, scope)) {
          _cleared.add(id);
        } else if (result is PrivateStateClearIncomplete &&
            result.participantId == id &&
            identical(result.scope, scope)) {
          incomplete.add(result);
        } else {
          incomplete.add(
            PrivateStateClearIncomplete(
              id,
              scope,
              PrivateStateClearFailure.scopeUnavailable,
            ),
          );
        }
      } catch (_) {
        incomplete.add(
          PrivateStateClearIncomplete(
            id,
            scope,
            PrivateStateClearFailure.retryableUnavailable,
          ),
        );
      }
    }
    if (incomplete.isNotEmpty) {
      return AccountScopeCloseIncomplete(scope, List.unmodifiable(incomplete));
    }
    if (_disposed) {
      return AccountScopeCloseIncomplete(
        scope,
        List.unmodifiable([
          PrivateStateClearIncomplete(
            AccountPrivacyParticipantId.applicationShell,
            scope,
            PrivateStateClearFailure.retryableUnavailable,
          ),
        ]),
      );
    }
    try {
      _journal.finish();
    } catch (_) {
      return AccountScopeCloseRejected(
        scope,
        AccountScopeFailure.retryableUnavailable,
      );
    }
    _snapshot = AccountScopeClosed(scope);
    return AccountScopeClosedForAccount(scope);
  }
}
