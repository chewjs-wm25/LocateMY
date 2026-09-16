import 'dart:async';

import 'package:locatemy/features/authentication_session/authentication_session.dart';

const accountA = AuthenticatedAccount(
  accountId: 'a',
  email: 'a@example.com',
  confirmation: EmailConfirmation.confirmed,
);
const accountB = AuthenticatedAccount(
  accountId: 'b',
  email: 'b@example.com',
  confirmation: EmailConfirmation.verificationRequired,
);

final class FakeAuthenticationSession implements AuthenticationSession {
  final changes = StreamController<SessionSnapshot>.broadcast(sync: true);
  SessionSnapshot restored = const UnauthenticatedSession();
  Future<SessionSnapshot>? pendingRestore;
  Future<SignInOutcome>? pendingSignIn;
  SignInOutcome signedIn = const SignInSucceeded(accountA);
  RegistrationOutcome registered = const RegistrationVerificationRequired(
    'a@example.com',
    ProfileRegistrationSkipped(),
  );
  SignOutOutcome signedOut = const SignOutSucceeded();
  int restoreCalls = 0;
  int signInCalls = 0;
  String? submittedEmail;
  String? submittedUsername;

  @override
  Future<SessionSnapshot> restoreSession() {
    ++restoreCalls;
    return pendingRestore ?? Future.value(restored);
  }

  @override
  Stream<SessionSnapshot> watchSession() => changes.stream;
  @override
  Future<SignInOutcome> signIn({
    required String email,
    required String password,
  }) {
    ++signInCalls;
    submittedEmail = email;
    return pendingSignIn ?? Future.value(signedIn);
  }

  @override
  Future<RegistrationOutcome> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    String? username,
  }) async {
    submittedEmail = email;
    submittedUsername = username;
    return registered;
  }

  @override
  Future<SignOutOutcome> signOut() async {
    changes.add(const UnauthenticatedSession());
    return signedOut;
  }
}
