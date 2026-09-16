export 'src/application/authentication_session.dart';
export 'src/domain/authentication_models.dart';

import 'package:locatemy/features/account_privacy/account_privacy.dart';

import 'src/application/authentication_session.dart';
import 'src/application/authentication_privacy_participant.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/data/supabase_authentication_session_adapter.dart';

AccountPrivacyParticipant createAuthenticationPrivacyParticipant(
  AuthenticationSession session,
) => AuthenticationPrivacyParticipant(session);

AuthenticationSession createAuthenticationSession(SupabaseClient client) =>
    SupabaseAuthenticationSessionAdapter(client);
