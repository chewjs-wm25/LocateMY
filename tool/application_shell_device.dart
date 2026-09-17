// Opt-in device QA: real Auth/Privacy/Shell with SIX labelled future test proofs.
// Isolated preference/journal namespace; disposable fixture credentials only.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/l10n/language_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_privacy_device.dart' show HarnessHttpClient;

final class HarnessIntent implements ShellIntent {
  final ShellRequestContext context;
  final List<String> orderedLocations;
  const HarnessIntent(this.context, this.orderedLocations);
}

final class HarnessContribution implements ShellContribution {
  final ShellRequestContext context;
  final String availability;
  final String metadata;
  const HarnessContribution(this.context, this.availability, this.metadata);
}

final class FutureOwnerTestProof implements AccountPrivacyParticipant {
  @override
  final AccountPrivacyParticipantId participantId;
  bool failOnce = false;
  FutureOwnerTestProof(this.participantId);
  @override
  Future<PrivateStateClearOutcome> clearPrivateState(AccountScope scope) async {
    if (failOnce) {
      failOnce = false;
      return PrivateStateClearIncomplete(
        participantId,
        scope,
        PrivateStateClearFailure.fileCleanupIncomplete,
      );
    }
    return PrivateStateCleared(participantId, scope);
  }
}

void require(bool condition, String name) {
  if (!condition) {
    debugPrint('SHELL_DEVICE: FAILED $name');
    throw StateError(name);
  }
  debugPrint('SHELL_DEVICE: PASS $name');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setPrefix('flutter.shell.wave3.');
  final language = LanguageController(
    preferences: await SharedPreferences.getInstance(),
  );
  final client = SupabaseClient(
    const String.fromEnvironment('SUPABASE_URL'),
    const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: HarnessHttpClient(),
  );
  final auth = createAuthenticationSession(client);
  final authVm = createAuthenticationViewModel(auth);
  final directory = Directory(
    '${(await getApplicationSupportDirectory()).path}/privacy-wave3-harness',
  );
  final restart = File('${directory.path}/restart-step');
  if (!restart.existsSync()) await language.select('zh');
  late AccountPrivacy privacy;
  late ShellRuntime shell;
  shell = ShellRuntime.compose(
    authentication: auth,
    privacy: () => privacy,
    intents: [
      ShellIntentBinding<HarnessIntent>(
        (input) => ShellRouteRequest.task(
          context: input.context,
          destination: 'harness-analysis',
        ),
      ),
    ],
    contributions: [
      ShellContributionBinding<HarnessContribution>(
        (input) =>
            ShellSlotRequest(context: input.context, slot: input.metadata),
      ),
    ],
  );
  final proofs = AccountPrivacyParticipantId.values
      .where(
        (id) =>
            id != AccountPrivacyParticipantId.authenticationSession &&
            id != AccountPrivacyParticipantId.applicationShell,
      )
      .map(FutureOwnerTestProof.new)
      .toList();
  privacy = createAccountPrivacy(
    authenticationSession: auth,
    participants: [
      createAuthenticationPrivacyParticipant(auth),
      shell,
      ...proofs,
    ],
    stateDirectory: directory,
  );
  var phase = 'initial';
  Future<void> signIn(bool b) async {
    require(
      await auth.signIn(
        email: b
            ? const String.fromEnvironment('LOCATEMY_SHELL_B_EMAIL')
            : const String.fromEnvironment('LOCATEMY_EMAIL'),
        password: b
            ? const String.fromEnvironment('LOCATEMY_SHELL_B_PASSWORD')
            : const String.fromEnvironment('LOCATEMY_PASSWORD'),
      ) is SignInSucceeded,
      'real fixture sign-in',
    );
    if (shell.state.gate != ShellGate.opened) {
      await shell.changes
          .firstWhere((s) => s.gate == ShellGate.opened)
          .timeout(const Duration(seconds: 30));
    }
  }

  shell.changes.listen((state) {
    if (phase == 'retry' && state.gate == ShellGate.authentication) {
      phase = 'switching';
      Future<void>.microtask(() async {
        await signIn(true);
        require(
          shell.state.selectedTab == ShellTab.home &&
              shell.state.routes.isEmpty &&
              shell.state.slots.isEmpty,
          'B has fresh navigation and slots',
        );
        require(
          language.locale.languageCode == 'en',
          'language survives account switch',
        );
        phase = 'B';
        debugPrint('SHELL_DEVICE: B_READY');
      });
    }
  });
  Future<void> verify() async {
    final original = shell.applicationShell!;
    shell.selectTab(ShellTab.map);
    shell.selectTab(ShellTab.home);
    final context = shell.currentContext!;
    final input = HarnessIntent(context, const ['B snapshot', 'A snapshot']);
    require(
      await original.submit(input) is ShellIntentAccepted &&
          identical(shell.state.routes.last.intent, input),
      'ordered immutable typed task input',
    );
    final contribution = HarnessContribution(
      shell.currentContext!,
      'unavailable',
      'official / 2025 / state / cached',
    );
    require(
      await original.publish(contribution) is ShellContributionAccepted &&
          identical(shell.state.slots.values.single, contribution),
      'provider metadata and unavailable retained',
    );
    shell.beginRequest();
    require(
      await original.publish(contribution) is ShellContributionRejected &&
          shell.state.slots.isEmpty,
      'stale response does not cover current slot',
    );
    shell.back();
    require(
      identical(shell.currentContext, context),
      'original return context restored',
    );
    proofs.last.failOnce = true;
    phase = 'retry';
    await shell.signOut();
    require(
      shell.state.gate == ShellGate.recovery &&
          shell.state.account == null &&
          shell.state.routes.isEmpty,
      'close failure hides old private content',
    );
    require(
      await original.submit(input) is ShellAuthenticationRequired,
      'late old-scope task blocked',
    );
    debugPrint('SHELL_DEVICE: RECOVERY_READY');
  }

  Future<void> prepareRestart() async {
    proofs.last.failOnce = true;
    restart.writeAsStringSync('closing', flush: true);
    phase = 'restart';
    await shell.signOut();
    require(
      shell.state.gate == ShellGate.recovery,
      'durable closing before process restart',
    );
    debugPrint('SHELL_DEVICE: READY_RESTART');
  }

  runApp(
    LocateMyApp(
      authenticationViewModel: authVm,
      shellRuntime: shell,
      languageController: language,
      shellViews: ShellViews(
        home: (_, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('QA HARNESS — SIX FUTURE OWNER TEST PROOFS'),
              TextButton(onPressed: verify, child: const Text('VERIFY SHELL')),
              TextButton(
                onPressed: prepareRestart,
                child: const Text('VERIFY RESTART'),
              ),
            ],
          ),
        ),
        map: (_, _) =>
            const Center(child: Text('MAP QA SLOT — NO SELECTED LOCATION')),
        tasks: [
          ShellTaskView<HarnessIntent>(
            'harness-analysis',
            (_, input) => Text(input.orderedLocations.join(' → ')),
          ),
        ],
        contributions: [
          ShellContributionView<HarnessContribution>(
            (_, input) => Text('${input.availability} | ${input.metadata}'),
          ),
        ],
      ),
    ),
  );
  try {
    if (restart.existsSync()) {
      require(
        privacy.readScope() is AccountScopeClosing,
        'process restart recovers closing journal',
      );
      await shell.initialize();
      require(
        shell.state.gate == ShellGate.authentication,
        'old scope closes before login after restart',
      );
      await signIn(false);
      require(
        language.locale.languageCode == 'en',
        'device language persists across process restart',
      );
      restart.deleteSync();
      await shell.signOut();
      require(
        shell.state.gate == ShellGate.authentication,
        'final fixture scope closed',
      );
      await (await SharedPreferences.getInstance()).clear();
      debugPrint('SHELL_DEVICE: ALL PASS');
    } else {
      await shell.initialize();
      await signIn(false);
      debugPrint('SHELL_DEVICE: INITIAL_READY');
    }
  } catch (_) {
    debugPrint('SHELL_DEVICE: FAILED device flow');
  }
}
