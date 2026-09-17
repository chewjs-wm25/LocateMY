import 'dart:async';

import 'package:flutter/foundation.dart';

import '../application/authentication_use_case.dart';
import '../domain/authentication_models.dart';
import 'authentication_view_state.dart';

final class AuthenticationViewModel extends ChangeNotifier {
  final AuthenticationUseCase _useCase;
  AuthenticationViewState _state = AuthenticationViewState.initial();
  StreamSubscription<SessionSnapshot>? _sessionSubscription;
  bool _disposed = false;
  Future<void>? _initialization;
  int _sessionRevision = 0;
  int _actionRevision = 0;

  AuthenticationViewModel(AuthenticationUseCase useCase) : _useCase = useCase;

  AuthenticationViewState get state {
    return _state;
  }

  Future<void> initialize() {
    _initialization ??= _initialize();
    return _initialization!;
  }

  Future<void> _initialize() async {
    _sessionSubscription = _useCase.watchSession().listen(
      _acceptSession,
      onError: (_) => _acceptSession(
        const SessionUnavailable(SessionFailure.retryableUnavailable),
      ),
    );
    await retrySession();
  }

  void _acceptSession(SessionSnapshot snapshot) {
    ++_sessionRevision;
    if (snapshot is! AuthenticatedSession &&
        _state.actionStatus == AuthenticationActionStatus.submitting) {
      ++_actionRevision;
    }
    if (_state.isSigningOut || _state.signOutBlocked) {
      return;
    }
    String? messageKey;
    if (snapshot is SessionUnavailable) {
      messageKey = 'session_unavailable';
    } else if (_isCurrentAccount(snapshot)) {
      messageKey = _state.messageKey;
    }
    _publish(
      _state.copyWith(
        session: snapshot,
        isRestoring: false,
        messageKey: messageKey,
      ),
    );
  }

  Future<void> retrySession() async {
    if (_disposed || _state.isSigningOut || _state.signOutBlocked) {
      return;
    }
    final int revision = ++_sessionRevision;
    _publish(
      _state.copyWith(isRestoring: true, session: null, messageKey: null),
    );
    final SessionSnapshot snapshot = await _useCase.restoreSession();
    if (!_disposed && revision == _sessionRevision) {
      _acceptSession(snapshot);
    }
  }

  // Invoked by the composition root after its UI barrier is in place.
  // Wave 1 contains no private scopes; full privacy close belongs to Shell.
  Future<void> signOut() async {
    if (_disposed || _state.isSigningOut) {
      return;
    }
    ++_sessionRevision;
    ++_actionRevision;
    _publish(
      _state.copyWith(
        session: null,
        isSigningOut: true,
        signOutBlocked: true,
        messageKey: null,
      ),
    );
    final SignOutOutcome outcome = await _useCase.signOut();
    switch (outcome) {
      case SignOutSucceeded():
        {
          _publish(
            _state.copyWith(
              session: const UnauthenticatedSession(),
              isSigningOut: false,
              signOutBlocked: false,
              mode: AuthenticationMode.signIn,
              actionStatus: AuthenticationActionStatus.idle,
              messageKey: null,
            ),
          );
        }
      case SignOutRejected(:final SignOutFailure failure):
        {
          final String messageKey = _signOutMessageKey(failure);
          _publish(
            _state.copyWith(isSigningOut: false, messageKey: messageKey),
          );
        }
    }
  }

  void showSignIn() {
    _publish(
      _state.copyWith(
        mode: AuthenticationMode.signIn,
        actionStatus: AuthenticationActionStatus.idle,
        messageKey: null,
        fieldErrorKey: null,
      ),
    );
  }

  void showRegistration() {
    _publish(
      _state.copyWith(
        mode: AuthenticationMode.register,
        actionStatus: AuthenticationActionStatus.idle,
        messageKey: null,
        fieldErrorKey: null,
      ),
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    if (_disposed ||
        _state.isRestoring ||
        _state.signOutBlocked ||
        _state.session is! UnauthenticatedSession ||
        _state.actionStatus == AuthenticationActionStatus.submitting) {
      return;
    }
    _publish(
      _state.copyWith(
        actionStatus: AuthenticationActionStatus.submitting,
        messageKey: null,
        fieldErrorKey: null,
      ),
    );
    final int actionRevision = _actionRevision;
    final SignInOutcome outcome = await _useCase.signIn(
      email: email,
      password: password,
    );
    if (_disposed ||
        actionRevision != _actionRevision ||
        _hasDifferentEmail(email) ||
        (outcome is SignInSucceeded &&
            _hasDifferentAccount(outcome.account.accountId))) {
      _publish(_state.copyWith(actionStatus: AuthenticationActionStatus.idle));
      return;
    }
    switch (outcome) {
      case SignInSucceeded(:final AuthenticatedAccount account):
        {
          _publish(
            _state.copyWith(
              actionStatus: AuthenticationActionStatus.succeeded,
              session: AuthenticatedSession(account),
              messageKey: 'sign_in_succeeded',
            ),
          );
        }
      case SignInRejected(:final SignInFailure failure):
        {
          String? fieldErrorKey;
          if (failure == SignInFailure.invalidInput) {
            fieldErrorKey = 'invalid_input';
          }
          _publish(
            _state.copyWith(
              actionStatus: AuthenticationActionStatus.failed,
              messageKey: _signInMessageKey(failure),
              fieldErrorKey: fieldErrorKey,
            ),
          );
        }
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (_disposed ||
        _state.isRestoring ||
        _state.signOutBlocked ||
        _state.session is! UnauthenticatedSession ||
        _state.actionStatus == AuthenticationActionStatus.submitting) {
      return;
    }
    _publish(
      _state.copyWith(
        actionStatus: AuthenticationActionStatus.submitting,
        messageKey: null,
        fieldErrorKey: null,
      ),
    );
    final int actionRevision = _actionRevision;
    final RegistrationOutcome outcome = await _useCase.register(
      username: username,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    if (_disposed ||
        actionRevision != _actionRevision ||
        _hasDifferentEmail(email) ||
        (outcome is RegistrationAuthenticated &&
            _hasDifferentAccount(outcome.account.accountId))) {
      _publish(_state.copyWith(actionStatus: AuthenticationActionStatus.idle));
      return;
    }
    switch (outcome) {
      case RegistrationAuthenticated(
        :final AuthenticatedAccount account,
        :final ProfileRegistrationOutcome profile,
      ):
        {
          _publish(
            _state.copyWith(
              actionStatus: AuthenticationActionStatus.succeeded,
              session: AuthenticatedSession(account),
              messageKey: _registrationMessageKey(profile),
            ),
          );
        }
      case RegistrationVerificationRequired(
        :final ProfileRegistrationOutcome profile,
      ):
        {
          _publish(
            _state.copyWith(
              actionStatus: AuthenticationActionStatus.succeeded,
              session: const UnauthenticatedSession(),
              messageKey: _verificationMessageKey(profile),
            ),
          );
        }
      case RegistrationRejected(:final RegistrationFailure failure):
        {
          String? fieldErrorKey;
          if (failure == RegistrationFailure.invalidInput) {
            fieldErrorKey = 'invalid_input';
          }
          _publish(
            _state.copyWith(
              actionStatus: AuthenticationActionStatus.failed,
              messageKey: _registrationFailureMessageKey(failure),
              fieldErrorKey: fieldErrorKey,
            ),
          );
        }
    }
  }

  Future<void> retryProfile(
    Future<ProfileRegistrationOutcome> Function() retry,
  ) async {
    if (_state.session is! AuthenticatedSession ||
        _state.actionStatus == AuthenticationActionStatus.submitting ||
        _disposed) {
      return;
    }
    final String accountId =
        (_state.session as AuthenticatedSession).account.accountId;
    final int actionRevision = _actionRevision;
    _publish(
      _state.copyWith(actionStatus: AuthenticationActionStatus.submitting),
    );
    final ProfileRegistrationOutcome result = await retry();
    if (_disposed ||
        actionRevision != _actionRevision ||
        _state.session is! AuthenticatedSession ||
        _hasDifferentAccount(accountId)) {
      _publish(_state.copyWith(actionStatus: AuthenticationActionStatus.idle));
      return;
    }
    final String messageKey = _profileRetryMessageKey(result);
    _publish(
      _state.copyWith(
        actionStatus: AuthenticationActionStatus.idle,
        messageKey: messageKey,
      ),
    );
  }

  void clearFeedback() {
    _publish(
      _state.copyWith(
        actionStatus: AuthenticationActionStatus.idle,
        messageKey: null,
        fieldErrorKey: null,
      ),
    );
  }

  String _signInMessageKey(SignInFailure failure) {
    switch (failure) {
      case SignInFailure.invalidInput:
        return 'sign_in_invalid_input';
      case SignInFailure.invalidCredentials:
        return 'sign_in_invalid_credentials';
      case SignInFailure.retryableUnavailable:
        return 'sign_in_retryable_unavailable';
      case SignInFailure.unsupportedClient:
        return 'sign_in_unsupported_client';
    }
  }

  String _registrationFailureMessageKey(RegistrationFailure failure) {
    switch (failure) {
      case RegistrationFailure.invalidInput:
        return 'registration_invalid_input';
      case RegistrationFailure.accountAlreadyExists:
        return 'registration_account_exists';
      case RegistrationFailure.retryableUnavailable:
        return 'registration_retryable_unavailable';
      case RegistrationFailure.unsupportedClient:
        return 'registration_unsupported_client';
    }
  }

  String _registrationMessageKey(ProfileRegistrationOutcome profile) {
    if (profile is ProfileRegistrationFailed) {
      return 'registration_authenticated_profile_failed';
    }
    return 'registration_authenticated';
  }

  String _verificationMessageKey(ProfileRegistrationOutcome profile) {
    if (profile is ProfileRegistrationFailed) {
      return 'verification_email_sent_profile_retry_needed';
    }
    return 'verification_email_sent';
  }

  String _signOutMessageKey(SignOutFailure failure) {
    switch (failure) {
      case SignOutFailure.retryableUnavailable:
        return 'sign_out_retryable_unavailable';
      case SignOutFailure.remoteRejected:
        return 'sign_out_remote_rejected';
      case SignOutFailure.unsupportedClient:
        return 'sign_out_unsupported_client';
    }
  }

  String _profileRetryMessageKey(ProfileRegistrationOutcome result) {
    if (result is ProfileRegistrationFailed) {
      return 'profile_retry_failed';
    }
    if (result is ProfileRegistered) {
      return 'profile_retry_succeeded';
    }
    return 'profile_retry_skipped';
  }

  bool _isCurrentAccount(SessionSnapshot snapshot) {
    if (snapshot is! AuthenticatedSession ||
        _state.session is! AuthenticatedSession) {
      return false;
    }
    final String snapshotAccountId = snapshot.account.accountId;
    final String stateAccountId =
        (_state.session as AuthenticatedSession).account.accountId;
    return snapshotAccountId == stateAccountId;
  }

  bool _hasDifferentEmail(String email) {
    if (_state.session is! AuthenticatedSession) {
      return false;
    }
    final String currentEmail = (_state.session as AuthenticatedSession)
        .account
        .email
        .toLowerCase();
    return currentEmail != email.trim().toLowerCase();
  }

  bool _hasDifferentAccount(String accountId) {
    if (_state.session is! AuthenticatedSession) {
      return false;
    }
    final String currentAccountId =
        (_state.session as AuthenticatedSession).account.accountId;
    return currentAccountId != accountId;
  }

  void _publish(AuthenticationViewState nextState) {
    if (_disposed) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionSubscription?.cancel();
    super.dispose();
  }
}
