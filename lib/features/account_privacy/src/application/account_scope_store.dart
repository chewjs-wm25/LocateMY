// Privacy owns only durable barrier identity, not business payloads.
final class AccountScopeCheckpoint {
  final String accountId;
  final bool closing;
  const AccountScopeCheckpoint(this.accountId, {required this.closing});
}

abstract interface class AccountScopeStore {
  AccountScopeCheckpoint? readPending();
  void recordOpened(String accountId);
  void recordClosing(String accountId);
  void finish();
}
