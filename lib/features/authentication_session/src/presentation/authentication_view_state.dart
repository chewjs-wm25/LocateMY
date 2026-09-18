import '../domain/authentication_models.dart';

enum AuthenticationMode { signIn, register }

enum AuthenticationActionStatus { idle, submitting, succeeded, failed }

const _unset = Object();

final class AuthenticationViewState {
  final AuthenticationMode mode;
  final AuthenticationActionStatus actionStatus;
  final SessionSnapshot? session;
  final String? messageKey;
  final String? fieldErrorKey;
  final bool isRestoring;
  final bool isSigningOut;

  const AuthenticationViewState({
    required this.mode,
    required this.actionStatus,
    required this.session,
    required this.messageKey,
    required this.fieldErrorKey,
    this.isRestoring = false,
    this.isSigningOut = false,
  });

  factory AuthenticationViewState.initial() {
    return const AuthenticationViewState(
      mode: AuthenticationMode.signIn,
      actionStatus: AuthenticationActionStatus.idle,
      session: null,
      isRestoring: true,
      messageKey: null,
      fieldErrorKey: null,
    );
  }

  AuthenticationViewState copyWith({
    bool? isRestoring,
    bool? isSigningOut,
    AuthenticationMode? mode,
    AuthenticationActionStatus? actionStatus,
    Object? session = _unset,
    Object? messageKey = _unset,
    Object? fieldErrorKey = _unset,
  }) {
    final SessionSnapshot? nextSession;
    if (identical(session, _unset)) {
      nextSession = this.session;
    } else {
      nextSession = session as SessionSnapshot?;
    }
    final String? nextMessageKey;
    if (identical(messageKey, _unset)) {
      nextMessageKey = this.messageKey;
    } else {
      nextMessageKey = messageKey as String?;
    }
    final String? nextFieldErrorKey;
    if (identical(fieldErrorKey, _unset)) {
      nextFieldErrorKey = this.fieldErrorKey;
    } else {
      nextFieldErrorKey = fieldErrorKey as String?;
    }
    return AuthenticationViewState(
      isRestoring: isRestoring ?? this.isRestoring,
      isSigningOut: isSigningOut ?? this.isSigningOut,
      mode: mode ?? this.mode,
      actionStatus: actionStatus ?? this.actionStatus,
      session: nextSession,
      messageKey: nextMessageKey,
      fieldErrorKey: nextFieldErrorKey,
    );
  }
}
