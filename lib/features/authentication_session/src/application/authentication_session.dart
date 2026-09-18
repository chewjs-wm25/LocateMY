import '../domain/authentication_models.dart';

abstract interface class AuthenticationSession {
  Future<SessionSnapshot> restoreSession();
  Stream<SessionSnapshot> watchSession();
  Future<SignInOutcome> signIn({
    required String email,
    required String password,
  });
  Future<RegistrationOutcome> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    String? username,
  });
  Future<SignOutOutcome> signOut();
}
