import '../domain/authentication_models.dart';
import 'authentication_session.dart';

final class AuthenticationUseCase {
  final AuthenticationSession _session;
  const AuthenticationUseCase(this._session);

  Future<SessionSnapshot> restoreSession() {
    return _session.restoreSession();
  }

  Stream<SessionSnapshot> watchSession() {
    return _session.watchSession();
  }

  Future<SignInOutcome> signIn({
    required String email,
    required String password,
  }) {
    final String normalizedEmail = email.trim();
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
    final String normalizedEmail = email.trim();
    final String? normalizedUsername = username?.trim();
    if (normalizedEmail.isEmpty ||
        password.isEmpty ||
        passwordConfirmation.isEmpty ||
        password != passwordConfirmation) {
      return Future.value(
        const RegistrationRejected(RegistrationFailure.invalidInput),
      );
    }
    String? registrationUsername;
    if (normalizedUsername == null || normalizedUsername.isEmpty) {
      registrationUsername = null;
    } else {
      registrationUsername = normalizedUsername;
    }
    return _session.register(
      email: normalizedEmail,
      password: password,
      passwordConfirmation: passwordConfirmation,
      username: registrationUsername,
    );
  }

  Future<SignOutOutcome> signOut() {
    return _session.signOut();
  }
}
