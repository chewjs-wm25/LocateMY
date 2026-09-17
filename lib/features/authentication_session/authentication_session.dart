export 'src/presentation/authentication_view_model.dart'
    show AuthenticationViewModel;
export 'src/presentation/authentication_page.dart' show AuthenticationPage;
export 'src/application/authentication_session.dart';
export 'src/domain/authentication_models.dart';

import 'package:locatemy/features/account_privacy/account_privacy.dart';

import 'src/application/authentication_session.dart';
import 'src/application/authentication_use_case.dart';
import 'src/presentation/authentication_view_model.dart';
import 'src/domain/authentication_models.dart';
import 'src/application/authentication_privacy_participant.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/data/supabase_authentication_session_adapter.dart';

AccountPrivacyParticipant createAuthenticationPrivacyParticipant(
  AuthenticationSession session,
) {
  return AuthenticationPrivacyParticipant(session);
}

AuthenticationSession createAuthenticationSession(SupabaseClient client) {
  return SupabaseAuthenticationSessionAdapter(client);
}

// Composition helpers; AUTH-001 declarations and Feature consumption stay fixed.
AuthenticationViewModel createAuthenticationViewModel(
  AuthenticationSession session,
) {
  final AuthenticationUseCase useCase = AuthenticationUseCase(session);
  return AuthenticationViewModel(useCase);
}

Future<ProfileRegistrationOutcome> retryAuthenticationOptionalProfile(
  AuthenticationSession session,
) {
  final SupabaseAuthenticationSessionAdapter adapter =
      session as SupabaseAuthenticationSessionAdapter;
  return adapter.retryOptionalProfile();
}
