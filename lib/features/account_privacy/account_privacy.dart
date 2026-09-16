import 'dart:io';

import 'package:locatemy/features/authentication_session/authentication_session.dart';

import 'src/domain/account_privacy_models.dart';
import 'src/application/account_privacy_coordinator.dart';
import 'src/data/account_scope_journal.dart';
export 'src/domain/account_privacy_models.dart';

AccountPrivacy createAccountPrivacy({
  required AuthenticationSession authenticationSession,
  required List<AccountPrivacyParticipant> participants,
  required Directory stateDirectory,
  Duration participantTimeout = const Duration(seconds: 15),
}) => AccountPrivacyCoordinator(
  authenticationSession,
  participants,
  AccountScopeJournal(stateDirectory),
  participantTimeout,
);

// Composition-root teardown; disposal never erases a pending privacy barrier.
Future<void> disposeAccountPrivacy(AccountPrivacy privacy) =>
    (privacy as AccountPrivacyCoordinator).dispose();
