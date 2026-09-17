import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/authentication_session/src/application/authentication_use_case.dart';
import 'package:locatemy/features/authentication_session/src/presentation/authentication_view_state.dart';

import '../../support/fake_authentication_session.dart';

void main() {
  late FakeAuthenticationSession fake;
  late AuthenticationViewModel vm;
  setUp(() {
    fake = FakeAuthenticationSession();
    final AuthenticationUseCase useCase = AuthenticationUseCase(fake);
    vm = AuthenticationViewModel(useCase);
  });
  tearDown(() async {
    vm.dispose();
    await fake.changes.close();
  });

  test(
    'initialization is shared and restore does not overwrite newer event',
    () async {
      final Completer<SessionSnapshot> restore = Completer<SessionSnapshot>();
      fake.pendingRestore = restore.future;
      final Future<void> first = vm.initialize();
      final Future<void> second = vm.initialize();
      fake.changes.add(const AuthenticatedSession(accountB));
      restore.complete(const AuthenticatedSession(accountA));
      await Future.wait([first, second]);
      expect(fake.restoreCalls, 1);
      expect((vm.state.session as AuthenticatedSession).account.accountId, 'b');
    },
  );

  test('retry unavailable session and recover', () async {
    fake.restored = const SessionUnavailable(
      SessionFailure.retryableUnavailable,
    );
    await vm.initialize();
    expect(vm.state.session, isA<SessionUnavailable>());
    fake.restored = const AuthenticatedSession(accountA);
    await vm.retrySession();
    expect(vm.state.session, isA<AuthenticatedSession>());
    expect(vm.state.isRestoring, false);
  });

  test('sign in trims email and blocks duplicate submission', () async {
    await vm.initialize();
    final response = Completer<SignInOutcome>();
    fake.pendingSignIn = response.future;
    final first = vm.signIn(email: ' a@example.com ', password: 'password');
    await vm.signIn(email: 'a@example.com', password: 'password');
    expect(fake.signInCalls, 1);
    expect(fake.submittedEmail, 'a@example.com');
    response.complete(const SignInSucceeded(accountA));
    await first;
    expect(vm.state.actionStatus, AuthenticationActionStatus.succeeded);
    expect(vm.state.session, isA<AuthenticatedSession>());
  });

  test('registration verification never claims a session', () async {
    await vm.initialize();
    await vm.register(
      username: ' ',
      email: ' a@example.com ',
      password: 'password123',
      passwordConfirmation: 'password123',
    );
    expect(vm.state.session, isA<UnauthenticatedSession>());
    expect(vm.state.messageKey, 'verification_email_sent');
    expect(fake.submittedUsername, isNull);
  });

  test('profile failure preserves successful authentication', () async {
    await vm.initialize();
    fake.registered = const RegistrationAuthenticated(
      accountA,
      ProfileRegistrationFailed(ProfileFailure.permissionDenied),
    );
    await vm.register(
      username: 'Test User',
      email: 'a@example.com',
      password: 'password123',
      passwordConfirmation: 'password123',
    );
    expect(vm.state.session, isA<AuthenticatedSession>());
    expect(vm.state.messageKey, 'registration_authenticated_profile_failed');
  });

  test(
    'sign out failure keeps identity hidden and blocks another login',
    () async {
      fake.restored = const AuthenticatedSession(accountA);
      await vm.initialize();
      fake.signedOut = const SignOutRejected(
        SignOutFailure.retryableUnavailable,
      );
      await vm.signOut();
      fake.changes.add(const AuthenticatedSession(accountA));
      expect(vm.state.session, isNull);
      expect(vm.state.signOutBlocked, true);
      await vm.signIn(email: 'b@example.com', password: 'password');
      expect(fake.signInCalls, 0);
      fake.signedOut = const SignOutSucceeded();
      await vm.signOut();
      expect(vm.state.signOutBlocked, false);
      fake.signedIn = const SignInSucceeded(accountB);
      await vm.signIn(email: 'b@example.com', password: 'password');
      expect((vm.state.session as AuthenticatedSession).account.accountId, 'b');
    },
  );

  test('stream unavailability replaces authenticated snapshot', () async {
    fake.restored = const AuthenticatedSession(accountA);
    await vm.initialize();
    fake.changes.add(const SessionUnavailable(SessionFailure.remoteRejected));
    expect(vm.state.session, isA<SessionUnavailable>());
    expect(vm.state.messageKey, 'session_unavailable');
  });

  test(
    'disposing during restore cancels subscription and ignores completion',
    () async {
      final response = Completer<SessionSnapshot>();
      fake.pendingRestore = response.future;
      final initializing = vm.initialize();
      vm.dispose();
      response.complete(const AuthenticatedSession(accountA));
      await initializing;
      expect(fake.changes.hasListener, false);
      // Replace the disposed instance for tearDown.
      vm = AuthenticationViewModel(AuthenticationUseCase(fake));
    },
  );
  test('late login completion cannot reopen an unavailable session', () async {
    await vm.initialize();
    final response = Completer<SignInOutcome>();
    fake.pendingSignIn = response.future;
    final signingIn = vm.signIn(email: 'a@example.com', password: 'password');
    fake.changes.add(const SessionUnavailable(SessionFailure.remoteRejected));
    response.complete(const SignInSucceeded(accountA));
    await signingIn;
    expect(vm.state.session, isA<SessionUnavailable>());
    expect(vm.state.actionStatus, AuthenticationActionStatus.idle);
  });
  test('late login cannot replace a newer authenticated account', () async {
    await vm.initialize();
    final response = Completer<SignInOutcome>();
    fake.pendingSignIn = response.future;
    final signingIn = vm.signIn(email: 'a@example.com', password: 'password');
    fake.changes.add(const AuthenticatedSession(accountB));
    response.complete(const SignInSucceeded(accountA));
    await signingIn;
    expect((vm.state.session as AuthenticatedSession).account.accountId, 'b');
  });

  test('profile retry feedback cannot cross account boundaries', () async {
    fake.restored = const AuthenticatedSession(accountA);
    await vm.initialize();
    final response = Completer<ProfileRegistrationOutcome>();
    final retrying = vm.retryProfile(() => response.future);
    fake.changes.add(const AuthenticatedSession(accountB));
    response.complete(const ProfileRegistered());
    await retrying;
    expect(vm.state.messageKey, isNull);
    expect(vm.state.actionStatus, AuthenticationActionStatus.idle);
  });
  test(
    'late rejected login feedback cannot cross to another account',
    () async {
      await vm.initialize();
      final response = Completer<SignInOutcome>();
      fake.pendingSignIn = response.future;
      final signingIn = vm.signIn(email: 'a@example.com', password: 'password');
      fake.changes.add(const AuthenticatedSession(accountB));
      response.complete(const SignInRejected(SignInFailure.invalidCredentials));
      await signingIn;
      expect(vm.state.messageKey, isNull);
      expect((vm.state.session as AuthenticatedSession).account.accountId, 'b');
    },
  );

  test('stream errors keep gate closed and can recover', () async {
    fake.restored = const AuthenticatedSession(accountA);
    await vm.initialize();
    fake.changes.addError(StateError('unavailable'));
    expect(vm.state.session, isA<SessionUnavailable>());
    fake.changes.add(const AuthenticatedSession(accountB));
    expect((vm.state.session as AuthenticatedSession).account.accountId, 'b');
  });
}
