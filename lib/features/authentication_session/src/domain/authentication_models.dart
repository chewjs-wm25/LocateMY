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

final class AuthenticatedAccount {
  final String accountId;
  final String email;
  const AuthenticatedAccount({required String accountId, required String email})
    : accountId = accountId,
      email = email;
}

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
