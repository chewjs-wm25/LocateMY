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

  test(
    'SDK identity changes during logout are never masked by submission state',
    () async {
      fake.restored = const AuthenticatedSession(accountA);
      final Completer<SignOutOutcome> pending = Completer<SignOutOutcome>();
      fake.pendingSignOut = pending.future;
      await vm.initialize();
      final Future<void> logout = vm.signOut();
      fake.changes.add(const UnauthenticatedSession());
      expect(vm.state.session, isA<UnauthenticatedSession>());
      fake.changes.add(const AuthenticatedSession(accountB));
      expect((vm.state.session as AuthenticatedSession).account.accountId, 'b');
      pending.complete(const SignOutRejected(SignOutFailure.remoteRejected));
      await logout;
      expect((vm.state.session as AuthenticatedSession).account.accountId, 'b');
    },
  );

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

  test('registration without optional username signs in immediately', () async {
    await vm.initialize();
    await vm.register(
      username: ' ',
      email: ' a@example.com ',
      password: 'password123',
      passwordConfirmation: 'password123',
    );
    expect(vm.state.session, isA<AuthenticatedSession>());
    expect(vm.state.messageKey, 'registration_authenticated');
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

  test(
    'SDK refresh errors keep the current identity and show feedback',
    () async {
      fake.restored = const AuthenticatedSession(accountA);
      await vm.initialize();
      fake.changes.addError(StateError('unavailable'));
      expect(vm.state.session, isA<AuthenticatedSession>());
      expect(vm.state.messageKey, 'session_unavailable');
      fake.changes.add(const AuthenticatedSession(accountB));
      expect((vm.state.session as AuthenticatedSession).account.accountId, 'b');
    },
  );
}
