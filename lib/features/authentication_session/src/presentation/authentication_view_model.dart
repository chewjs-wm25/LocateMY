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

  AuthenticationViewModel(this._useCase);

  AuthenticationViewState get state => _state;

  Future<void> initialize() => _initialization ??= _initialize();

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
    if (_state.isSigningOut || _state.signOutBlocked) return;
    _publish(
      _state.copyWith(
        session: snapshot,
        isRestoring: false,
        messageKey: snapshot is SessionUnavailable
            ? 'session_unavailable'
            : snapshot is AuthenticatedSession &&
                  _state.session is AuthenticatedSession &&
                  snapshot.account.accountId ==
                      (_state.session as AuthenticatedSession).account.accountId
            ? _state.messageKey
            : null,
      ),
    );
  }

  Future<void> retrySession() async {
    if (_disposed || _state.isSigningOut || _state.signOutBlocked) return;
    final revision = ++_sessionRevision;
    _publish(
      _state.copyWith(isRestoring: true, session: null, messageKey: null),
    );
    final snapshot = await _useCase.restoreSession();
    if (!_disposed && revision == _sessionRevision) _acceptSession(snapshot);
  }

  // Invoked by the composition root after its UI barrier is in place.
  // Wave 1 contains no private scopes; full privacy close belongs to Shell.
  Future<void> signOut() async {
    if (_disposed || _state.isSigningOut) return;
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
    final outcome = await _useCase.signOut();
    switch (outcome) {
      case SignOutSucceeded():
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
      case SignOutRejected(:final failure):
        _publish(
          _state.copyWith(
            isSigningOut: false,
            messageKey: switch (failure) {
              SignOutFailure.retryableUnavailable =>
                'sign_out_retryable_unavailable',
              SignOutFailure.remoteRejected => 'sign_out_remote_rejected',
              SignOutFailure.unsupportedClient => 'sign_out_unsupported_client',
            },
          ),
        );
    }
  }

  void showSignIn() => _publish(
    _state.copyWith(
      mode: AuthenticationMode.signIn,
      actionStatus: AuthenticationActionStatus.idle,
      messageKey: null,
      fieldErrorKey: null,
    ),
  );

  void showRegistration() => _publish(
    _state.copyWith(
      mode: AuthenticationMode.register,
      actionStatus: AuthenticationActionStatus.idle,
      messageKey: null,
      fieldErrorKey: null,
    ),
  );

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
    final actionRevision = _actionRevision;
    final outcome = await _useCase.signIn(email: email, password: password);
    if (_disposed ||
        actionRevision != _actionRevision ||
        _hasDifferentEmail(email) ||
        (outcome is SignInSucceeded &&
            _hasDifferentAccount(outcome.account.accountId))) {
      _publish(_state.copyWith(actionStatus: AuthenticationActionStatus.idle));
      return;
    }
    switch (outcome) {
      case SignInSucceeded(:final account):
        _publish(
          _state.copyWith(
            actionStatus: AuthenticationActionStatus.succeeded,
            session: AuthenticatedSession(account),
            messageKey: 'sign_in_succeeded',
          ),
        );
      case SignInRejected(:final failure):
        _publish(
          _state.copyWith(
            actionStatus: AuthenticationActionStatus.failed,
            messageKey: _signInMessageKey(failure),
            fieldErrorKey: failure == SignInFailure.invalidInput
                ? 'invalid_input'
                : null,
          ),
        );
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
    final actionRevision = _actionRevision;
    final outcome = await _useCase.register(
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
      case RegistrationAuthenticated(:final account, :final profile):
        _publish(
          _state.copyWith(
            actionStatus: AuthenticationActionStatus.succeeded,
            session: AuthenticatedSession(account),
            messageKey: _registrationMessageKey(profile),
          ),
        );
      case RegistrationVerificationRequired(:final profile):
        _publish(
          _state.copyWith(
            actionStatus: AuthenticationActionStatus.succeeded,
            session: const UnauthenticatedSession(),
            messageKey: _verificationMessageKey(profile),
          ),
        );
      case RegistrationRejected(:final failure):
        _publish(
          _state.copyWith(
            actionStatus: AuthenticationActionStatus.failed,
            messageKey: _registrationFailureMessageKey(failure),
            fieldErrorKey: failure == RegistrationFailure.invalidInput
                ? 'invalid_input'
                : null,
          ),
        );
    }
  }

  Future<void> retryProfile(
    Future<ProfileRegistrationOutcome> Function() retry,
  ) async {
    if (_state.session is! AuthenticatedSession ||
        _state.actionStatus == AuthenticationActionStatus.submitting) {
      return;
    }
    if (_disposed) return;
    final accountId =
        (_state.session as AuthenticatedSession).account.accountId;
    final actionRevision = _actionRevision;
    _publish(
      _state.copyWith(actionStatus: AuthenticationActionStatus.submitting),
    );
    final result = await retry();
    if (_disposed ||
        actionRevision != _actionRevision ||
        _state.session is! AuthenticatedSession ||
        _hasDifferentAccount(accountId)) {
      _publish(_state.copyWith(actionStatus: AuthenticationActionStatus.idle));
      return;
    }
    _publish(
      _state.copyWith(
        actionStatus: AuthenticationActionStatus.idle,
        messageKey: result is ProfileRegistrationFailed
            ? 'profile_retry_failed'
            : result is ProfileRegistered
            ? 'profile_retry_succeeded'
            : 'profile_retry_skipped',
      ),
    );
  }

  void clearFeedback() => _publish(
    _state.copyWith(
      actionStatus: AuthenticationActionStatus.idle,
      messageKey: null,
      fieldErrorKey: null,
    ),
  );

  String _signInMessageKey(SignInFailure failure) => switch (failure) {
    SignInFailure.invalidInput => 'sign_in_invalid_input',
    SignInFailure.invalidCredentials => 'sign_in_invalid_credentials',
    SignInFailure.retryableUnavailable => 'sign_in_retryable_unavailable',
    SignInFailure.unsupportedClient => 'sign_in_unsupported_client',
  };

  String _registrationFailureMessageKey(
    RegistrationFailure failure,
  ) => switch (failure) {
    RegistrationFailure.invalidInput => 'registration_invalid_input',
    RegistrationFailure.accountAlreadyExists => 'registration_account_exists',
    RegistrationFailure.retryableUnavailable =>
      'registration_retryable_unavailable',
    RegistrationFailure.unsupportedClient => 'registration_unsupported_client',
  };

  String _registrationMessageKey(ProfileRegistrationOutcome profile) =>
      switch (profile) {
        ProfileRegistered() ||
        ProfileRegistrationSkipped() => 'registration_authenticated',
        ProfileRegistrationFailed() =>
          'registration_authenticated_profile_failed',
      };

  String _verificationMessageKey(ProfileRegistrationOutcome profile) =>
      switch (profile) {
        ProfileRegistered() ||
        ProfileRegistrationSkipped() => 'verification_email_sent',
        ProfileRegistrationFailed() =>
          'verification_email_sent_profile_retry_needed',
      };

  bool _hasDifferentEmail(String email) =>
      _state.session is AuthenticatedSession &&
      (_state.session as AuthenticatedSession).account.email.toLowerCase() !=
          email.trim().toLowerCase();

  bool _hasDifferentAccount(String accountId) =>
      _state.session is AuthenticatedSession &&
      (_state.session as AuthenticatedSession).account.accountId != accountId;

  void _publish(AuthenticationViewState nextState) {
    if (_disposed) return;
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
