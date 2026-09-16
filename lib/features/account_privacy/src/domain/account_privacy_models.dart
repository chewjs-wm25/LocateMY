import 'package:locatemy/features/authentication_session/authentication_session.dart';

abstract interface class AccountPrivacy {
  AccountScopeSnapshot readScope();
  Future<OpenAccountScopeOutcome> open(AuthenticatedAccount account);
  Future<CloseAccountScopeOutcome> close(
    AccountScope scope,
    AccountScopeCloseReason reason,
  );
}

final class AccountScope {
  final String accountId;
  const AccountScope(this.accountId);
}

sealed class AccountScopeSnapshot {
  const AccountScopeSnapshot();
}

final class AccountScopeOpened extends AccountScopeSnapshot {
  final AccountScope scope;
  const AccountScopeOpened(this.scope);
}

final class AccountScopeClosing extends AccountScopeSnapshot {
  final AccountScope scope;
  const AccountScopeClosing(this.scope);
}

final class AccountScopeClosed extends AccountScopeSnapshot {
  final AccountScope scope;
  const AccountScopeClosed(this.scope);
}

final class AccountScopeUnavailable extends AccountScopeSnapshot {
  final AccountScopeFailure failure;
  const AccountScopeUnavailable(this.failure);
}

enum AccountScopeFailure {
  identityMismatch,
  scopeNotOpen,
  scopeClosing,
  retryableUnavailable,
}

enum AccountScopeCloseReason { signOut, sessionInvalidated, accountSwitch }

sealed class OpenAccountScopeOutcome {
  const OpenAccountScopeOutcome();
}

final class AccountScopeOpenedForAccount extends OpenAccountScopeOutcome {
  final AccountScope scope;
  const AccountScopeOpenedForAccount(this.scope);
}

final class AccountScopeOpenRejected extends OpenAccountScopeOutcome {
  final AccountScopeFailure failure;
  const AccountScopeOpenRejected(this.failure);
}

sealed class CloseAccountScopeOutcome {
  const CloseAccountScopeOutcome();
}

final class AccountScopeClosedForAccount extends CloseAccountScopeOutcome {
  final AccountScope scope;
  const AccountScopeClosedForAccount(this.scope);
}

final class AccountScopeCloseIncomplete extends CloseAccountScopeOutcome {
  final AccountScope scope;
  final List<PrivateStateClearIncomplete> incomplete;
  const AccountScopeCloseIncomplete(this.scope, this.incomplete);
}

final class AccountScopeCloseRejected extends CloseAccountScopeOutcome {
  final AccountScope scope;
  final AccountScopeFailure failure;
  const AccountScopeCloseRejected(this.scope, this.failure);
}

abstract interface class AccountPrivacyParticipant {
  AccountPrivacyParticipantId get participantId;
  Future<PrivateStateClearOutcome> clearPrivateState(AccountScope scope);
}

enum AccountPrivacyParticipantId {
  authenticationSession,
  applicationShell,
  mapLocation,
  costLivingBudget,
  infrastructureCoverage,
  hazardReporting,
  propertyInspection,
  accountCenter,
}

sealed class PrivateStateClearOutcome {
  const PrivateStateClearOutcome();
}

final class PrivateStateCleared extends PrivateStateClearOutcome {
  final AccountPrivacyParticipantId participantId;
  final AccountScope scope;
  const PrivateStateCleared(this.participantId, this.scope);
}

final class PrivateStateClearIncomplete extends PrivateStateClearOutcome {
  final AccountPrivacyParticipantId participantId;
  final AccountScope scope;
  final PrivateStateClearFailure failure;
  const PrivateStateClearIncomplete(
    this.participantId,
    this.scope,
    this.failure,
  );
}

enum PrivateStateClearFailure {
  localStoreUnavailable,
  fileCleanupIncomplete,
  queuedWorkCleanupIncomplete,
  scopeUnavailable,
  retryableUnavailable,
}
