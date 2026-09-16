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
  final bool signOutBlocked;

  const AuthenticationViewState({
    required this.mode,
    required this.actionStatus,
    required this.session,
    required this.messageKey,
    required this.fieldErrorKey,
    this.isRestoring = false,
    this.isSigningOut = false,
    this.signOutBlocked = false,
  });

  factory AuthenticationViewState.initial() => const AuthenticationViewState(
    mode: AuthenticationMode.signIn,
    actionStatus: AuthenticationActionStatus.idle,
    session: null,
    isRestoring: true,
    messageKey: null,
    fieldErrorKey: null,
  );

  AuthenticationViewState copyWith({
    bool? isRestoring,
    bool? isSigningOut,
    bool? signOutBlocked,
    AuthenticationMode? mode,
    AuthenticationActionStatus? actionStatus,
    Object? session = _unset,
    Object? messageKey = _unset,
    Object? fieldErrorKey = _unset,
  }) => AuthenticationViewState(
    isRestoring: isRestoring ?? this.isRestoring,
    isSigningOut: isSigningOut ?? this.isSigningOut,
    signOutBlocked: signOutBlocked ?? this.signOutBlocked,
    mode: mode ?? this.mode,
    actionStatus: actionStatus ?? this.actionStatus,
    session: identical(session, _unset)
        ? this.session
        : session as SessionSnapshot?,
    messageKey: identical(messageKey, _unset)
        ? this.messageKey
        : messageKey as String?,
    fieldErrorKey: identical(fieldErrorKey, _unset)
        ? this.fieldErrorKey
        : fieldErrorKey as String?,
  );
}
