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
  String? _pendingProfileEmail;
  String? _pendingUsername;

  Future<ProfileRegistrationOutcome> retryOptionalProfile() async {
    final SessionSnapshot snapshot = await restoreSession();
    if (snapshot is! AuthenticatedSession ||
        snapshot.account.email.toLowerCase() !=
            _pendingProfileEmail?.toLowerCase() ||
        _pendingUsername == null) {
      return const ProfileRegistrationSkipped();
    }
    final ProfileRegistrationOutcome result = await _writeOptionalProfile(
      accountId: snapshot.account.accountId,
      username: _pendingUsername,
    );
    if (result is ProfileRegistered) {
      _pendingUsername = null;
      _pendingProfileEmail = null;
    }
    return result;
  }

  static const _requestTimeout = Duration(seconds: 15);

  @override
  Future<SessionSnapshot> restoreSession() async {
    try {
      final Session? session = await _client.auth.getSession().timeout(
        _requestTimeout,
      );
      if (session == null) {
        return const UnauthenticatedSession();
      }
      if (_isExpired(session)) {
        return const SessionUnavailable(SessionFailure.retryableUnavailable);
      }
      final User? user =
          (await _client.auth
                  .getUser(session.accessToken)
                  .timeout(_requestTimeout))
              .user;
      // A response for an old token must never resurrect a signed-out account.
      if (_client.auth.currentSession?.accessToken != session.accessToken ||
          user == null ||
          user.id != session.user.id) {
        return const SessionUnavailable(SessionFailure.remoteRejected);
      }
      final AuthenticatedAccount account = _mapAccount(user);
      return AuthenticatedSession(account);
    } on SocketException {
      return const SessionUnavailable(SessionFailure.retryableUnavailable);
    } on TimeoutException {
      return const SessionUnavailable(SessionFailure.retryableUnavailable);
    } on AuthRetryableFetchException {
      return const SessionUnavailable(SessionFailure.retryableUnavailable);
    } on AuthException {
      return const SessionUnavailable(SessionFailure.remoteRejected);
    } catch (_) {
      return const SessionUnavailable(SessionFailure.unsupportedClient);
    }
  }

  @override
  Stream<SessionSnapshot> watchSession() {
    late StreamController<SessionSnapshot> controller;
    StreamSubscription<AuthState>? subscription;
    Timer? expiryTimer;
    int revision = 0;

    void emit(SessionSnapshot snapshot) {
      if (controller.isClosed) {
        return;
      }
      expiryTimer?.cancel();
      controller.add(snapshot);
      if (snapshot is AuthenticatedSession) {
        final int? expiry = _client.auth.currentSession?.expiresAt;
        if (expiry != null) {
          final Duration remaining = DateTime.fromMillisecondsSinceEpoch(
            expiry * 1000,
          ).difference(DateTime.now());
          expiryTimer = Timer(
            remaining.isNegative ? Duration.zero : remaining,
            () {
              controller.add(
                const SessionUnavailable(SessionFailure.retryableUnavailable),
              );
            },
          );
        }
      }
    }

    Future<void> verify() async {
      final int requestRevision = ++revision;
      final SessionSnapshot snapshot = await restoreSession();
      if (requestRevision == revision) {
        emit(snapshot);
      }
    }

    controller = StreamController<SessionSnapshot>(
      onListen: () {
        subscription = _client.auth.onAuthStateChange.listen(
          (state) {
            if (state.event == AuthChangeEvent.initialSession) {
              // SDK callbacks must finish before calling methods that refresh.
              unawaited(Future<void>(verify));
            } else {
              ++revision;
              final bool sessionWasRejected =
                  state.signOutReason == SignOutReason.sessionExpired ||
                  state.signOutReason == SignOutReason.sessionMissing;
              if (sessionWasRejected) {
                emit(const SessionUnavailable(SessionFailure.remoteRejected));
              } else {
                emit(_mapSession(state.session));
              }
            }
          },
          onError: (Object error, StackTrace stack) {
            ++revision;
            emit(SessionUnavailable(_mapSessionFailure(error)));
          },
        );
        unawaited(Future<void>(verify));
      },
      onCancel: () async {
        ++revision;
        expiryTimer?.cancel();
        await subscription?.cancel();
      },
    );
    return controller.stream;
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
      if (_isExpired(session)) {
        return const SignInRejected(SignInFailure.retryableUnavailable);
      }
      if (_pendingProfileEmail?.toLowerCase() !=
          session.user.email?.toLowerCase()) {
        _pendingProfileEmail = null;
        _pendingUsername = null;
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
      _pendingProfileEmail = email.trim();
      _pendingUsername = username?.trim();
      final AuthResponse response = await _client.auth
          .signUp(email: email.trim(), password: password)
          .timeout(_requestTimeout);
      final Session? session = response.session;
      if (session == null) {
        if (response.user == null) {
          return const RegistrationRejected(
            RegistrationFailure.unsupportedClient,
          );
        }
        final String? normalizedUsername = username?.trim();
        final ProfileRegistrationOutcome profile;
        if (normalizedUsername == null || normalizedUsername.isEmpty) {
          profile = const ProfileRegistrationSkipped();
        } else {
          profile = const ProfileRegistrationFailed(
            ProfileFailure.permissionDenied,
          );
        }
        return RegistrationVerificationRequired(email.trim(), profile);
      }
      if (_isExpired(session)) {
        return const RegistrationRejected(
          RegistrationFailure.retryableUnavailable,
        );
      }
      final AuthenticatedAccount account = _mapAccount(session.user);
      final ProfileRegistrationOutcome profile = await _writeOptionalProfile(
        accountId: account.accountId,
        username: username,
      );
      if (profile is ProfileRegistered ||
          profile is ProfileRegistrationSkipped) {
        _pendingProfileEmail = null;
        _pendingUsername = null;
      }
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
      _pendingUsername = null;
      _pendingProfileEmail = null;
      return const SignOutSucceeded();
    } on SocketException {
      return const SignOutRejected(SignOutFailure.retryableUnavailable);
    } on TimeoutException {
      return const SignOutRejected(SignOutFailure.retryableUnavailable);
    } on AuthRetryableFetchException {
      return const SignOutRejected(SignOutFailure.retryableUnavailable);
    } on AuthException {
      return const SignOutRejected(SignOutFailure.remoteRejected);
    } catch (_) {
      return const SignOutRejected(SignOutFailure.unsupportedClient);
    }
  }

  bool _isExpired(Session session) {
    final int? expiry = session.expiresAt;
    if (expiry == null) {
      return true;
    }
    return DateTime.now().millisecondsSinceEpoch >= expiry * 1000;
  }

  SessionSnapshot _mapSession(Session? session) {
    if (session == null) {
      return const UnauthenticatedSession();
    }
    if (_isExpired(session)) {
      return const SessionUnavailable(SessionFailure.retryableUnavailable);
    }
    try {
      return AuthenticatedSession(_mapAccount(session.user));
    } on FormatException {
      return const SessionUnavailable(SessionFailure.unsupportedClient);
    }
  }

  AuthenticatedAccount _mapAccount(User user) {
    final String? email = user.email?.trim();
    if (email == null || email.isEmpty) {
      throw const FormatException('Email/password user has no email.');
    }
    final EmailConfirmation confirmation;
    if (user.emailConfirmedAt != null) {
      confirmation = EmailConfirmation.confirmed;
    } else {
      confirmation = EmailConfirmation.verificationRequired;
    }
    return AuthenticatedAccount(
      accountId: user.id,
      email: email.trim(),
      confirmation: confirmation,
    );
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

  SessionFailure _mapSessionFailure(Object error) {
    if (error is TimeoutException ||
        error is SocketException ||
        error is AuthRetryableFetchException) {
      return SessionFailure.retryableUnavailable;
    }
    if (error is AuthException) {
      return SessionFailure.remoteRejected;
    }
    return SessionFailure.unsupportedClient;
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
