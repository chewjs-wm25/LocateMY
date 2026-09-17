// ignore_for_file: prefer_initializing_formals

// Explicit constructor parameter types and initialization lists are intentional:
// this public model is read alongside Java-oriented collaboration contracts.

sealed class SessionSnapshot {
  const SessionSnapshot();
}

final class AuthenticatedSession extends SessionSnapshot {
  final AuthenticatedAccount account;
  const AuthenticatedSession(AuthenticatedAccount account) : account = account;
}

final class UnauthenticatedSession extends SessionSnapshot {
  const UnauthenticatedSession();
}

final class SessionUnavailable extends SessionSnapshot {
  final SessionFailure failure;
  const SessionUnavailable(SessionFailure failure) : failure = failure;
}

final class AuthenticatedAccount {
  final String accountId;
  final String email;
  final EmailConfirmation confirmation;
  const AuthenticatedAccount({
    required String accountId,
    required String email,
    required EmailConfirmation confirmation,
  }) : accountId = accountId,
       email = email,
       confirmation = confirmation;
}

enum EmailConfirmation { confirmed, verificationRequired, unavailable }

sealed class SignInOutcome {
  const SignInOutcome();
}

final class SignInSucceeded extends SignInOutcome {
  final AuthenticatedAccount account;
  const SignInSucceeded(AuthenticatedAccount account) : account = account;
}

final class SignInRejected extends SignInOutcome {
  final SignInFailure failure;
  const SignInRejected(SignInFailure failure) : failure = failure;
}

sealed class RegistrationOutcome {
  const RegistrationOutcome();
}

final class RegistrationAuthenticated extends RegistrationOutcome {
  final AuthenticatedAccount account;
  final ProfileRegistrationOutcome profile;
  const RegistrationAuthenticated(
    AuthenticatedAccount account,
    ProfileRegistrationOutcome profile,
  ) : account = account,
      profile = profile;
}

final class RegistrationVerificationRequired extends RegistrationOutcome {
  final String email;
  final ProfileRegistrationOutcome profile;
  const RegistrationVerificationRequired(
    String email,
    ProfileRegistrationOutcome profile,
  ) : email = email,
      profile = profile;
}

final class RegistrationRejected extends RegistrationOutcome {
  final RegistrationFailure failure;
  const RegistrationRejected(RegistrationFailure failure) : failure = failure;
}

sealed class ProfileRegistrationOutcome {
  const ProfileRegistrationOutcome();
}

final class ProfileRegistered extends ProfileRegistrationOutcome {
  const ProfileRegistered();
}

final class ProfileRegistrationSkipped extends ProfileRegistrationOutcome {
  const ProfileRegistrationSkipped();
}

final class ProfileRegistrationFailed extends ProfileRegistrationOutcome {
  final ProfileFailure failure;
  const ProfileRegistrationFailed(ProfileFailure failure) : failure = failure;
}

sealed class SignOutOutcome {
  const SignOutOutcome();
}

final class SignOutSucceeded extends SignOutOutcome {
  const SignOutSucceeded();
}

final class SignOutRejected extends SignOutOutcome {
  final SignOutFailure failure;
  const SignOutRejected(SignOutFailure failure) : failure = failure;
}

enum SessionFailure { retryableUnavailable, unsupportedClient, remoteRejected }

enum SignInFailure {
  invalidInput,
  invalidCredentials,
  retryableUnavailable,
  unsupportedClient,
}

enum RegistrationFailure {
  invalidInput,
  accountAlreadyExists,
  retryableUnavailable,
  unsupportedClient,
}

enum ProfileFailure { retryableUnavailable, permissionDenied, unknown }

enum SignOutFailure { retryableUnavailable, remoteRejected, unsupportedClient }
