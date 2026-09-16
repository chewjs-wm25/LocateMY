sealed class SessionSnapshot {
  const SessionSnapshot();
}

final class AuthenticatedSession extends SessionSnapshot {
  final AuthenticatedAccount account;
  const AuthenticatedSession(this.account);
}

final class UnauthenticatedSession extends SessionSnapshot {
  const UnauthenticatedSession();
}

final class SessionUnavailable extends SessionSnapshot {
  final SessionFailure failure;
  const SessionUnavailable(this.failure);
}

final class AuthenticatedAccount {
  final String accountId;
  final String email;
  final EmailConfirmation confirmation;
  const AuthenticatedAccount({
    required this.accountId,
    required this.email,
    required this.confirmation,
  });
}

enum EmailConfirmation { confirmed, verificationRequired, unavailable }

sealed class SignInOutcome {
  const SignInOutcome();
}

final class SignInSucceeded extends SignInOutcome {
  final AuthenticatedAccount account;
  const SignInSucceeded(this.account);
}

final class SignInRejected extends SignInOutcome {
  final SignInFailure failure;
  const SignInRejected(this.failure);
}

sealed class RegistrationOutcome {
  const RegistrationOutcome();
}

final class RegistrationAuthenticated extends RegistrationOutcome {
  final AuthenticatedAccount account;
  final ProfileRegistrationOutcome profile;
  const RegistrationAuthenticated(this.account, this.profile);
}

final class RegistrationVerificationRequired extends RegistrationOutcome {
  final String email;
  final ProfileRegistrationOutcome profile;
  const RegistrationVerificationRequired(this.email, this.profile);
}

final class RegistrationRejected extends RegistrationOutcome {
  final RegistrationFailure failure;
  const RegistrationRejected(this.failure);
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
  const ProfileRegistrationFailed(this.failure);
}

sealed class SignOutOutcome {
  const SignOutOutcome();
}

final class SignOutSucceeded extends SignOutOutcome {
  const SignOutSucceeded();
}

final class SignOutRejected extends SignOutOutcome {
  final SignOutFailure failure;
  const SignOutRejected(this.failure);
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
