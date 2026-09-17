import 'dart:io';

import 'package:locatemy/features/authentication_session/authentication_session.dart';

import 'src/application/account_privacy_coordinator.dart';
import 'src/data/account_scope_journal.dart';
import 'src/domain/account_privacy_models.dart';
export 'src/domain/account_privacy_models.dart';

AccountPrivacy createAccountPrivacy({
  required AuthenticationSession authenticationSession,
  required List<AccountPrivacyParticipant> participants,
  required Directory stateDirectory,
  // Build manifest: include every owner whose private state can exist in this
  // app. Omission keeps the complete eight-owner integration barrier.
  Set<AccountPrivacyParticipantId> requiredParticipants = const {
    ...AccountPrivacyParticipantId.values,
  },
  Duration participantTimeout = const Duration(seconds: 15),
}) {
  return AccountPrivacyCoordinator(
    authenticationSession,
    participants,
    AccountScopeJournal(stateDirectory),
    participantTimeout,
    requiredParticipants: requiredParticipants,
  );
}

// Composition-root teardown; disposal never erases a pending privacy barrier.
Future<void> disposeAccountPrivacy(AccountPrivacy privacy) {
  final AccountPrivacyCoordinator coordinator =
      privacy as AccountPrivacyCoordinator;
  return coordinator.dispose();
}
