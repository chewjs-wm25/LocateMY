import 'dart:collection';

import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';

// Consumer-only scripted fake. Never registered by production composition.
final class FakeAccountPrivacy implements AccountPrivacy {
  AccountScopeSnapshot snapshot = const AccountScopeUnavailable(
    AccountScopeFailure.scopeNotOpen,
  );
  final Queue<OpenAccountScopeOutcome> opens;
  final Queue<CloseAccountScopeOutcome> closes;
  FakeAccountPrivacy({
    Iterable<OpenAccountScopeOutcome> opens = const [],
    Iterable<CloseAccountScopeOutcome> closes = const [],
  }) : opens = Queue<OpenAccountScopeOutcome>.of(opens),
       closes = Queue<CloseAccountScopeOutcome>.of(closes);
  @override
  AccountScopeSnapshot readScope() {
    return snapshot;
  }

  @override
  Future<OpenAccountScopeOutcome> open(AuthenticatedAccount account) async {
    final OpenAccountScopeOutcome result = opens.removeFirst();
    if (result is AccountScopeOpenedForAccount) {
      snapshot = AccountScopeOpened(result.scope);
    }
    return result;
  }

  @override
  Future<CloseAccountScopeOutcome> close(
    AccountScope scope,
    AccountScopeCloseReason reason,
  ) {
    snapshot = AccountScopeClosing(scope);
    final CloseAccountScopeOutcome result = closes.removeFirst();
    return Future<CloseAccountScopeOutcome>(() {
      if (result is AccountScopeClosedForAccount) {
        snapshot = AccountScopeClosed(result.scope);
      }
      return result;
    });
  }
}
