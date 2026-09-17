import 'dart:async';

import 'account_scope_store.dart';

import 'package:locatemy/features/authentication_session/authentication_session.dart';

import '../domain/account_privacy_models.dart';

final class AccountPrivacyCoordinator implements AccountPrivacy {
  final AuthenticationSession _auth;
  final Map<AccountPrivacyParticipantId, List<AccountPrivacyParticipant>>
  _participants =
      <AccountPrivacyParticipantId, List<AccountPrivacyParticipant>>{};
  final Set<AccountPrivacyParticipantId> _requiredParticipants;
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
    this._participantTimeout, {
    Set<AccountPrivacyParticipantId> requiredParticipants = const {
      ...AccountPrivacyParticipantId.values,
    },
  }) : _requiredParticipants = Set<AccountPrivacyParticipantId>.of(
         requiredParticipants,
       ) {
    _requiredParticipants.add(
      AccountPrivacyParticipantId.authenticationSession,
    );
    _requiredParticipants.add(AccountPrivacyParticipantId.applicationShell);
    try {
      for (final AccountPrivacyParticipant participant in participants) {
        final AccountPrivacyParticipantId id = participant.participantId;
        _requiredParticipants.add(id);
        final List<AccountPrivacyParticipant> registeredParticipants =
            _participants.putIfAbsent(id, () {
              return <AccountPrivacyParticipant>[];
            });
        registeredParticipants.add(participant);
      }
    } catch (_) {
      _registrationUnavailable = true;
      _participants.clear();
    }
    _restoreStore();
    _subscription = _auth.watchSession().listen(
      _observe,
      onDone: () {
        _observe(const SessionUnavailable(SessionFailure.retryableUnavailable));
      },
      onError: (Object _) {
        _observe(const SessionUnavailable(SessionFailure.retryableUnavailable));
      },
    );
  }

  void _restoreStore() {
    try {
      final AccountScopeCheckpoint? pending = _journal.readPending();
      _storeUnavailable = false;
      if (pending != null && !pending.closing) {
        _recoverableScope = AccountScope(pending.accountId);
      } else {
        _recoverableScope = null;
      }
      if (pending != null && pending.closing) {
        _snapshot = AccountScopeClosing(AccountScope(pending.accountId));
      } else {
        _snapshot = const AccountScopeUnavailable(
          AccountScopeFailure.scopeNotOpen,
        );
      }
    } catch (_) {
      _storeUnavailable = true;
      _recoverableScope = null;
      _snapshot = const AccountScopeUnavailable(
        AccountScopeFailure.retryableUnavailable,
      );
    }
  }

  void _observe(SessionSnapshot fact) {
    final String? id;
    if (fact is AuthenticatedSession) {
      id = fact.account.accountId;
    } else {
      id = null;
    }
    final AccountScopeSnapshot opened = _snapshot;
    if (id == null ||
        (_observedAccount != null && id != _observedAccount) ||
        (opened is AccountScopeOpened && opened.scope.accountId != id)) {
      ++_revision;
      if (opened is AccountScopeOpened) {
        _blockScope(opened.scope);
      }
    }
    final AccountScope? recovered = _recoverableScope;
    if (recovered != null && id != recovered.accountId) {
      _blockScope(recovered);
    }
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
    final AccountScopeSnapshot snapshot = _snapshot;
    if (snapshot is AccountScopeOpened) {
      _snapshot = AccountScopeClosing(snapshot.scope);
    }
    await _subscription.cancel();
  }

  @override
  AccountScopeSnapshot readScope() {
    return _snapshot;
  }

  final Set<AccountPrivacyParticipantId> _cleared =
      <AccountPrivacyParticipantId>{};
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
    final int revision = _revision;
    try {
      final SessionSnapshot current = await _auth.restoreSession();
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
        if (current is AuthenticatedSession) {
          _observedAccount = current.account.accountId;
        } else {
          _observedAccount = null;
        }
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
      final AccountScope scope;
      if (_recoverableScope != null) {
        scope = _recoverableScope!;
      } else {
        scope = AccountScope(account.accountId);
        _journal.recordOpened(scope.accountId);
      }
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
    final AccountScopeSnapshot snapshot = _snapshot;
    final AccountScope? current;
    if (snapshot is AccountScopeOpened) {
      current = snapshot.scope;
    } else if (snapshot is AccountScopeClosing) {
      current = snapshot.scope;
    } else if (snapshot is AccountScopeClosed) {
      current = snapshot.scope;
    } else {
      current = null;
    }
    if (!identical(current, scope)) {
      return Future.value(
        AccountScopeCloseRejected(scope, AccountScopeFailure.identityMismatch),
      );
    }
    if (_snapshot is AccountScopeClosed) {
      return Future.value(AccountScopeClosedForAccount(scope));
    }
    if (_closing != null) {
      return _closing!;
    }
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
    final Future<CloseAccountScopeOutcome> operation = _clear(scope);
    _closing = operation;
    operation.whenComplete(() {
      _closing = null;
    });
    return operation;
  }

  Future<CloseAccountScopeOutcome> _clear(AccountScope scope) async {
    final List<PrivateStateClearIncomplete> incomplete =
        <PrivateStateClearIncomplete>[];
    for (final AccountPrivacyParticipantId id in _requiredParticipants) {
      if (_cleared.contains(id)) {
        continue;
      }
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
      final List<AccountPrivacyParticipant> matches;
      if (_registrationUnavailable) {
        matches = <AccountPrivacyParticipant>[];
      } else {
        final List<AccountPrivacyParticipant>? registered = _participants[id];
        if (registered != null) {
          matches = registered;
        } else {
          matches = <AccountPrivacyParticipant>[];
        }
      }
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
        final PrivateStateClearOutcome result = await matches.single
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
