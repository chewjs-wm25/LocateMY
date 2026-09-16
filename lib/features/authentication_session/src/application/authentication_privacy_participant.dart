import 'package:locatemy/features/account_privacy/account_privacy.dart';

import 'authentication_session.dart';
import '../domain/authentication_models.dart';

// Shell ends the session first. This participant verifies, never initiates it.
final class AuthenticationPrivacyParticipant
    implements AccountPrivacyParticipant {
  final AuthenticationSession _session;
  AuthenticationPrivacyParticipant(this._session);
  @override
  AccountPrivacyParticipantId get participantId =>
      AccountPrivacyParticipantId.authenticationSession;

  @override
  Future<PrivateStateClearOutcome> clearPrivateState(AccountScope scope) async {
    if (scope.accountId.trim().isEmpty) {
      return PrivateStateClearIncomplete(
        participantId,
        scope,
        PrivateStateClearFailure.scopeUnavailable,
      );
    }
    try {
      final current = await _session.restoreSession();
      if (current is UnauthenticatedSession) {
        return PrivateStateCleared(participantId, scope);
      }
      return PrivateStateClearIncomplete(
        participantId,
        scope,
        current is SessionUnavailable &&
                current.failure == SessionFailure.retryableUnavailable
            ? PrivateStateClearFailure.retryableUnavailable
            : PrivateStateClearFailure.scopeUnavailable,
      );
    } catch (_) {
      return PrivateStateClearIncomplete(
        participantId,
        scope,
        PrivateStateClearFailure.retryableUnavailable,
      );
    }
  }
}
