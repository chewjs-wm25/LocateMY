import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

// Opt-in Wave 2 harness. Seven marked test participants have no business payload.
// Disposable fixture credentials only; no private business pages or remote writes.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class HarnessHttpClient extends http.BaseClient {
  static const _proxyPort = int.fromEnvironment('LOCATEMY_PRIVACY_PROXY_PORT');
  final _inner = IOClient(
    HttpClient()
      ..findProxy = (_) =>
          _proxyPort == 0 ? 'DIRECT' : 'PROXY 127.0.0.1:$_proxyPort',
  );
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      final response = await http.Response.fromStream(
        await _inner.send(request),
      );
      if (response.statusCode >= 400) {
        String code = 'redacted';
        try {
          final value = (jsonDecode(response.body) as Map)['code'];
          if (value is String && RegExp(r'^[a-z_]{1,64}$').hasMatch(value)) {
            code = value;
          }
        } catch (_) {}
        debugPrint('PRIVACY_DEVICE: HTTP_FAILURE ${response.statusCode} $code');
      }
      return http.StreamedResponse(
        Stream.value(response.bodyBytes),
        response.statusCode,
        headers: response.headers,
        request: request,
      );
    } catch (error) {
      debugPrint('PRIVACY_DEVICE: NETWORK_FAILURE ${error.runtimeType}');
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: PrivacyVerification()));
}

final class HarnessTestParticipant implements AccountPrivacyParticipant {
  @override
  final AccountPrivacyParticipantId participantId;
  bool fail = false;
  HarnessTestParticipant(this.participantId);
  @override
  Future<PrivateStateClearOutcome> clearPrivateState(
    AccountScope scope,
  ) async => fail
      ? PrivateStateClearIncomplete(
          participantId,
          scope,
          PrivateStateClearFailure.fileCleanupIncomplete,
        )
      : PrivateStateCleared(participantId, scope);
}

class PrivacyVerification extends StatefulWidget {
  const PrivacyVerification({super.key});
  @override
  State<PrivacyVerification> createState() => _PrivacyVerificationState();
}

class _PrivacyVerificationState extends State<PrivacyVerification> {
  final lines = <String>[];
  void record(String message) {
    debugPrint('PRIVACY_DEVICE: $message');
    if (mounted) setState(() => lines.add(message));
  }

  void require(bool condition, String name) {
    if (!condition) throw StateError(name);
    record('PASS: $name');
  }

  @override
  void initState() {
    super.initState();
    verify();
  }

  Future<void> verify() async {
    final client = SupabaseClient(
      const String.fromEnvironment('SUPABASE_URL'),
      const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: HarnessHttpClient(),
    );
    final auth = createAuthenticationSession(client);
    AccountPrivacy? privacy;
    try {
      final directory = Directory(
        '${(await getApplicationSupportDirectory()).path}/privacy-wave2-harness',
      );
      final fakes = AccountPrivacyParticipantId.values
          .where(
            (id) => id != AccountPrivacyParticipantId.authenticationSession,
          )
          .map(HarnessTestParticipant.new)
          .toList();
      privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: [createAuthenticationPrivacyParticipant(auth), ...fakes],
        stateDirectory: directory,
      );
      record('START: real AUTH-001; seven TEST FAKE owners; no private pages');
      final initial = privacy.readScope();
      final restarting = initial is AccountScopeClosing;
      if (initial is AccountScopeClosing) {
        require(
          await privacy.open(
            const AuthenticatedAccount(
              accountId: 'invalid',
              email: 'fixture@example.com',
              confirmation: EmailConfirmation.confirmed,
            ),
          ) is AccountScopeOpenRejected,
          'restart blocks opening',
        );
        require(
          await privacy.close(initial.scope, AccountScopeCloseReason.signOut)
              is AccountScopeClosedForAccount,
          'restart recovers old barrier with all proofs',
        );
      }
      Future<AuthenticatedAccount> login(bool b) async {
        final result = await auth.signIn(
          email: b
              ? const String.fromEnvironment('LOCATEMY_PRIVACY_B_EMAIL')
              : const String.fromEnvironment('LOCATEMY_EMAIL'),
          password: b
              ? const String.fromEnvironment('LOCATEMY_PRIVACY_B_PASSWORD')
              : const String.fromEnvironment('LOCATEMY_PASSWORD'),
        );
        if (result is! SignInSucceeded) {
          record(
            'FAIL DETAIL: login ${result is SignInRejected ? result.failure.name : result.runtimeType}',
          );
          throw StateError('fixture login');
        }
        final current = await auth.restoreSession();
        if (current is! AuthenticatedSession) {
          record(
            'FAIL DETAIL: restore ${current is SessionUnavailable ? current.failure.name : current.runtimeType}',
          );
          throw StateError('fixture restore');
        }
        return current.account;
      }

      final a = await login(false);
      final opened = await privacy.open(a);
      require(
        opened is AccountScopeOpenedForAccount,
        'real A identity opens scope',
      );
      var oldScope = (opened as AccountScopeOpenedForAccount).scope;
      require(
        (await privacy.open(a) as AccountScopeOpenedForAccount).scope ==
            oldScope,
        'same account open is idempotent',
      );
      await disposeAccountPrivacy(privacy);
      privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: [createAuthenticationPrivacyParticipant(auth), ...fakes],
        stateDirectory: directory,
      );
      require(
        privacy.readScope() is! AccountScopeOpened,
        'ordinary rebuild requires fresh Auth before private access',
      );
      final restoredOpen = await privacy.open(a);
      require(
        restoredOpen is AccountScopeOpenedForAccount,
        'ordinary same-account rebuild preserves open scope without cleanup',
      );
      oldScope = (restoredOpen as AccountScopeOpenedForAccount).scope;
      final authParticipant = createAuthenticationPrivacyParticipant(auth);
      require(
        await authParticipant.clearPrivateState(oldScope)
            is PrivateStateClearIncomplete,
        'active session cannot provide exit proof',
      );
      require(
        await auth.signOut() is SignOutSucceeded,
        'real current device signOut',
      );
      require(
        await authParticipant.clearPrivateState(oldScope)
            is PrivateStateCleared,
        'real Auth participant exit proof',
      );
      fakes.last.fail = true;
      final pending = privacy.close(
        oldScope,
        AccountScopeCloseReason.accountSwitch,
      );
      require(
        privacy.readScope() is AccountScopeClosing,
        'close immediately blocks private access',
      );
      final incomplete = await pending;
      require(
        incomplete is AccountScopeCloseIncomplete &&
            incomplete.incomplete.single.participantId ==
                AccountPrivacyParticipantId.accountCenter,
        'exact owner cleanup failure',
      );
      final b = await login(true);
      require(
        a.accountId != b.accountId &&
            await privacy.open(b) is AccountScopeOpenRejected,
        'B blocked while A cleanup incomplete',
      );
      require(
        await auth.signOut() is SignOutSucceeded,
        'B test session ends before recovery',
      );
      fakes.last.fail = false;
      require(
        await privacy.close(oldScope, AccountScopeCloseReason.accountSwitch)
            is AccountScopeClosedForAccount,
        'same old scope retry completes',
      );
      final bAgain = await login(true);
      final bOpened = await privacy.open(bAgain);
      require(
        bOpened is AccountScopeOpenedForAccount &&
            !identical((bOpened).scope, oldScope),
        'real B gets new scope after A closes',
      );
      await auth.signOut();
      require(
        await privacy.close(
          (bOpened as AccountScopeOpenedForAccount).scope,
          AccountScopeCloseReason.signOut,
        ) is AccountScopeClosedForAccount,
        'B closes',
      );
      if (!restarting) {
        final again = await login(false);
        final againScope =
            (await privacy.open(again) as AccountScopeOpenedForAccount).scope;
        await auth.signOut();
        fakes.last.fail = true;
        require(
          await privacy.close(againScope, AccountScopeCloseReason.signOut)
              is AccountScopeCloseIncomplete,
          'pending barrier saved for actual process restart',
        );
        record('READY_RESTART');
      } else {
        record('ALL PASS');
      }
    } catch (error) {
      record(
        'FAILED: ${error is StateError ? error.message : error.runtimeType}',
      );
    } finally {
      await auth.signOut();
      if (privacy != null) await disposeAccountPrivacy(privacy);
      await client.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account Privacy · Wave 2')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: lines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(line),
            ),
          )
          .toList(),
    ),
  );
}
