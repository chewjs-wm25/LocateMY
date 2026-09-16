import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';

import '../../support/fake_authentication_session.dart';

void main() {
  test('Auth proves only a known ended current device session without signing out for Shell', () async {
    final auth = FakeAuthenticationSession();
    final participant = createAuthenticationPrivacyParticipant(auth);
    const scope = AccountScope('a');
    auth.restored = const AuthenticatedSession(accountA);
    expect(
      await participant.clearPrivateState(scope),
      isA<PrivateStateClearIncomplete>(),
    );
    for (final failure in SessionFailure.values) {
      auth.restored = SessionUnavailable(failure);
      expect(
        await participant.clearPrivateState(scope),
        isA<PrivateStateClearIncomplete>(),
      );
    }
    auth.restored = const UnauthenticatedSession();
    final result =
        await participant.clearPrivateState(scope) as PrivateStateCleared;
    expect(
      result.participantId,
      AccountPrivacyParticipantId.authenticationSession,
    );
    expect(result.scope, same(scope));
    await auth.changes.close();
  });
}
