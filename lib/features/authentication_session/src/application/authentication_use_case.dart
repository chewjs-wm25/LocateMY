import '../domain/authentication_models.dart';
import 'authentication_session.dart';

final class AuthenticationUseCase {
  final AuthenticationSession _session;
  const AuthenticationUseCase(this._session);

  Future<SessionSnapshot> restoreSession() => _session.restoreSession();
  Stream<SessionSnapshot> watchSession() => _session.watchSession();

  Future<SignInOutcome> signIn({
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return Future.value(const SignInRejected(SignInFailure.invalidInput));
    }
    return _session.signIn(email: normalizedEmail, password: password);
  }

  Future<RegistrationOutcome> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    String? username,
  }) {
    final normalizedEmail = email.trim();
    final normalizedUsername = username?.trim();
    if (normalizedEmail.isEmpty ||
        password.isEmpty ||
        passwordConfirmation.isEmpty ||
        password != passwordConfirmation) {
      return Future.value(
        const RegistrationRejected(RegistrationFailure.invalidInput),
      );
    }
    return _session.register(
      email: normalizedEmail,
      password: password,
      passwordConfirmation: passwordConfirmation,
      username: (normalizedUsername?.isEmpty ?? true)
          ? null
          : normalizedUsername,
    );
  }

  Future<SignOutOutcome> signOut() => _session.signOut();
}
