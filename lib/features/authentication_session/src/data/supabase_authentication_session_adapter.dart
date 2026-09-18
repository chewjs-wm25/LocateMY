import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/authentication_session.dart';
import '../domain/authentication_models.dart';

final class SupabaseAuthenticationSessionAdapter
    implements AuthenticationSession {
  final SupabaseClient _client;
  SupabaseAuthenticationSessionAdapter(SupabaseClient client)
    : _client = client;
  static const _requestTimeout = Duration(seconds: 15);

  @override
  Future<SessionSnapshot> restoreSession() async {
    return _mapSession(_client.auth.currentSession);
  }

  @override
  Stream<SessionSnapshot> watchSession() {
    return _client.auth.onAuthStateChange.map((AuthState state) {
      return _mapSession(state.session);
    });
  }

  @override
  Future<SignInOutcome> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return const SignInRejected(SignInFailure.invalidInput);
    }
    try {
      final AuthResponse response = await _client.auth
          .signInWithPassword(email: email.trim(), password: password)
          .timeout(_requestTimeout);
      final Session? session = response.session;
      if (session == null) {
        return const SignInRejected(SignInFailure.unsupportedClient);
      }

      final AuthenticatedAccount account = _mapAccount(session.user);
      return SignInSucceeded(account);
    } on SocketException {
      return const SignInRejected(SignInFailure.retryableUnavailable);
    } on TimeoutException {
      return const SignInRejected(SignInFailure.retryableUnavailable);
    } on AuthRetryableFetchException {
      return const SignInRejected(SignInFailure.retryableUnavailable);
    } on AuthException catch (error) {
      return SignInRejected(_mapSignInFailure(error));
    } catch (_) {
      return const SignInRejected(SignInFailure.unsupportedClient);
    }
  }

  @override
  Future<RegistrationOutcome> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    String? username,
  }) async {
    if (email.trim().isEmpty ||
        password.isEmpty ||
        password != passwordConfirmation) {
      return const RegistrationRejected(RegistrationFailure.invalidInput);
    }
    try {
      final AuthResponse response = await _client.auth
          .signUp(email: email.trim(), password: password)
          .timeout(_requestTimeout);
      final Session? session = response.session;
      if (session == null) {
        return const RegistrationRejected(
          RegistrationFailure.unsupportedClient,
        );
      }
      final AuthenticatedAccount account = _mapAccount(session.user);
      final ProfileRegistrationOutcome profile = await _writeOptionalProfile(
        accountId: account.accountId,
        username: username,
      );

      if (_client.auth.currentSession?.user.id != account.accountId) {
        return const RegistrationRejected(
          RegistrationFailure.retryableUnavailable,
        );
      }
      return RegistrationAuthenticated(account, profile);
    } on SocketException {
      return const RegistrationRejected(
        RegistrationFailure.retryableUnavailable,
      );
    } on TimeoutException {
      return const RegistrationRejected(
        RegistrationFailure.retryableUnavailable,
      );
    } on AuthRetryableFetchException {
      return const RegistrationRejected(
        RegistrationFailure.retryableUnavailable,
      );
    } on AuthException catch (error) {
      return RegistrationRejected(_mapRegistrationFailure(error));
    } catch (_) {
      return const RegistrationRejected(RegistrationFailure.unsupportedClient);
    }
  }

  @override
  Future<SignOutOutcome> signOut() async {
    try {
      await _client.auth
          .signOut(scope: SignOutScope.local)
          .timeout(_requestTimeout);
      return _deviceSignOutOutcome(SignOutFailure.remoteRejected);
    } on SocketException {
      return _deviceSignOutOutcome(SignOutFailure.retryableUnavailable);
    } on TimeoutException {
      return _deviceSignOutOutcome(SignOutFailure.retryableUnavailable);
    } on AuthRetryableFetchException {
      return _deviceSignOutOutcome(SignOutFailure.retryableUnavailable);
    } on AuthException {
      return _deviceSignOutOutcome(SignOutFailure.remoteRejected);
    } catch (_) {
      return _deviceSignOutOutcome(SignOutFailure.unsupportedClient);
    }
  }

  SignOutOutcome _deviceSignOutOutcome(SignOutFailure failure) {
    if (_client.auth.currentSession == null) {
      return const SignOutSucceeded();
    }
    return SignOutRejected(failure);
  }

  SessionSnapshot _mapSession(Session? session) {
    if (session == null) {
      return const UnauthenticatedSession();
    }

    try {
      return AuthenticatedSession(_mapAccount(session.user));
    } on FormatException {
      return const UnauthenticatedSession();
    }
  }

  AuthenticatedAccount _mapAccount(User user) {
    final String? email = user.email?.trim();
    if (email == null || email.isEmpty) {
      throw const FormatException('Email/password user has no email.');
    }
    return AuthenticatedAccount(accountId: user.id, email: email.trim());
  }

  Future<ProfileRegistrationOutcome> _writeOptionalProfile({
    required String accountId,
    required String? username,
  }) async {
    final String? normalizedUsername = username?.trim();
    if (normalizedUsername == null || normalizedUsername.isEmpty) {
      return const ProfileRegistrationSkipped();
    }
    try {
      await _client
          .from('profiles')
          .upsert({'id': accountId, 'username': normalizedUsername})
          .timeout(_requestTimeout);
      return const ProfileRegistered();
    } on PostgrestException catch (error) {
      if (error.code == '42501' || error.code == '401' || error.code == '403') {
        return const ProfileRegistrationFailed(ProfileFailure.permissionDenied);
      }
      return const ProfileRegistrationFailed(ProfileFailure.unknown);
    } on SocketException {
      return const ProfileRegistrationFailed(
        ProfileFailure.retryableUnavailable,
      );
    } on TimeoutException {
      return const ProfileRegistrationFailed(
        ProfileFailure.retryableUnavailable,
      );
    } catch (_) {
      return const ProfileRegistrationFailed(ProfileFailure.unknown);
    }
  }

  SignInFailure _mapSignInFailure(AuthException error) {
    if (error is AuthRetryableFetchException) {
      return SignInFailure.retryableUnavailable;
    }
    const invalidCredentialCodes = {
      'invalid_credentials',
      'invalid_grant',
      'email_not_confirmed',
    };
    if (error.statusCode == '429' || error.code == 'over_request_rate_limit') {
      return SignInFailure.retryableUnavailable;
    }
    if (error.code == 'validation_failed' ||
        error.code == 'email_address_invalid') {
      return SignInFailure.invalidInput;
    }
    if (invalidCredentialCodes.contains(error.code)) {
      return SignInFailure.invalidCredentials;
    }
    return SignInFailure.unsupportedClient;
  }

  RegistrationFailure _mapRegistrationFailure(AuthException error) {
    if (error is AuthRetryableFetchException) {
      return RegistrationFailure.retryableUnavailable;
    }
    const existingAccountCodes = {'user_already_exists', 'email_exists'};
    if (existingAccountCodes.contains(error.code)) {
      return RegistrationFailure.accountAlreadyExists;
    }
    if ({
      'weak_password',
      'validation_failed',
      'email_address_invalid',
    }.contains(error.code)) {
      return RegistrationFailure.invalidInput;
    }
    if (error.statusCode == '429' ||
        error.code == 'over_email_send_rate_limit' ||
        error.code == 'over_request_rate_limit') {
      return RegistrationFailure.retryableUnavailable;
    }
    return RegistrationFailure.unsupportedClient;
  }
}
