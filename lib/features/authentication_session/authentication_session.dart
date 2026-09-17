export 'src/presentation/authentication_view_model.dart'
    show AuthenticationViewModel;
export 'src/presentation/authentication_page.dart' show AuthenticationPage;
export 'src/application/authentication_session.dart';
export 'src/domain/authentication_models.dart';

import 'src/application/authentication_session.dart';
import 'src/application/authentication_use_case.dart';
import 'src/presentation/authentication_view_model.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/data/supabase_authentication_session_adapter.dart';

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
