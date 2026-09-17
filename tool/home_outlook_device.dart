// Opt-in Home acceptance: real Auth/Privacy/Shell, RPC and SQLite.
// Failure is injected only at the external HTTP boundary; isolated namespace.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:locatemy/app/app.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/home_relocation_outlook/home_relocation_outlook.dart';
import 'package:locatemy/l10n/language_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_privacy_device.dart' show HarnessHttpClient;

void require(bool value, String label) {
  if (!value) {
    debugPrint('HOME_DEVICE: FAILED $label');
    throw StateError(label);
  }
  debugPrint('HOME_DEVICE: PASS $label');
}

final class HomeDeviceNetwork extends http.BaseClient {
  final File offline;
  final _inner = HarnessHttpClient();
  HomeDeviceNetwork(this.offline);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (offline.existsSync() &&
        request.url.path.endsWith('/read_home_metrics')) {
      return Future.value(
        http.StreamedResponse(
          Stream.value('{"code":"offline"}'.codeUnits),
          503,
          request: request,
          headers: {'content-type': 'application/json'},
        ),
      );
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setPrefix('flutter.home.wave4.');
  final language = LanguageController(
    preferences: await SharedPreferences.getInstance(),
  );
  final directory = Directory(
    '${(await getApplicationSupportDirectory()).path}/home-wave4-harness',
  );
  await directory.create(recursive: true);
  final offline = File('${directory.path}/offline');
  if (!File('${directory.path}/started').existsSync()) {
    await language.select('zh');
    await File('${directory.path}/started').writeAsString('1');
  }
  final client = SupabaseClient(
    const String.fromEnvironment('SUPABASE_URL'),
    const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: HomeDeviceNetwork(offline),
  );
  final auth = createAuthenticationSession(client);
  final authVm = createAuthenticationViewModel(auth);
  late AccountPrivacy privacy;
  late ShellRuntime runtime;
  runtime = ShellRuntime.compose(
    authentication: auth,
    privacy: () => privacy,
    intents: [homeExploreMapBinding(() => runtime)],
  );
  require(
    await auth.signIn(
      email: const String.fromEnvironment('LOCATEMY_EMAIL'),
      password: const String.fromEnvironment('LOCATEMY_PASSWORD'),
    ) is SignInSucceeded,
    'real disposable fixture sign-in',
  );
  privacy = createAccountPrivacy(
    authenticationSession: auth,
    participants: [createAuthenticationPrivacyParticipant(auth), runtime],
    requiredParticipants: const {
      AccountPrivacyParticipantId.authenticationSession,
      AccountPrivacyParticipantId.applicationShell,
    },
    stateDirectory: Directory('${directory.path}/privacy'),
  );
  await runtime.initialize();
  require(runtime.state.gate == ShellGate.opened, 'real opened scope');
  HomeRelocationOutlook createHome() => createHomeRelocationOutlook(
    client,
    openCache: () async => openDatabase('${directory.path}/public.db'),
    clock: () => DateTime.now().add(
      offline.existsSync() ? const Duration(days: 2) : Duration.zero,
    ),
  );
  final home = createHome();
  final result = await home.load(HomeLoadRequest.cacheAllowed);
  require(result is HomeLoaded, 'real snapshot or persisted fallback');
  final snapshot = (result as HomeLoaded).snapshot;
  require(
    snapshot.relocationTiming.score != null,
    'national timing is available',
  );
  if (offline.existsSync()) {
    require(
      snapshot.freshness == HomeDataFreshness.stale,
      'persisted expired cache after process restart',
    );
    debugPrint('HOME_DEVICE: RESTART_STALE_READY');
  } else {
    require(
      snapshot.freshness == HomeDataFreshness.fresh,
      'real RPC fresh with source dates',
    );
    debugPrint('HOME_DEVICE: FRESH_READY');
  }
  runApp(
    LocateMyApp(
      authenticationViewModel: authVm,
      shellRuntime: runtime,
      languageController: language,
      shellViews: ShellViews(
        home: (context, shell) => DeviceHomePanel(
          home: home,
          createHome: createHome,
          shell: shell,
          offline: offline,
          runtime: runtime,
        ),
      ),
    ),
  );
}

final class DeviceHomePanel extends StatefulWidget {
  final HomeRelocationOutlook home;
  final HomeRelocationOutlook Function() createHome;
  final ApplicationShell shell;
  final ShellRuntime runtime;
  final File offline;
  const DeviceHomePanel({
    required this.home,
    required this.createHome,
    required this.shell,
    required this.offline,
    required this.runtime,
    super.key,
  });
  @override
  State<DeviceHomePanel> createState() => _DeviceHomePanelState();
}

final class _DeviceHomePanelState extends State<DeviceHomePanel> {
  late HomeRelocationOutlook home = widget.home;
  int revision = 0;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: HomeOutlookPage(
          key: ValueKey(revision),
          home: home,
          applicationShell: widget.shell,
        ),
      ),
      Wrap(
        children: [
          TextButton(
            onPressed: () async {
              final result = await home.load(HomeLoadRequest.refresh);
              require(
                result is HomeLoaded || result is HomeRefreshCoolingDown,
                'refresh result',
              );
              final cooling = await home.load(HomeLoadRequest.refresh);
              require(
                cooling is HomeRefreshCoolingDown &&
                    cooling.remainingSeconds > 0,
                'success cooldown via HOME-001',
              );
              debugPrint('HOME_DEVICE: COOLDOWN_READY');
            },
            child: const Text('QA Cooldown'),
          ),
          TextButton(
            onPressed: () async {
              await widget.offline.writeAsString('1');
              home = widget.createHome();
              final result = await home.load(HomeLoadRequest.refresh);
              require(
                result is HomeLoaded &&
                    result.snapshot.freshness == HomeDataFreshness.stale,
                'external network failure preserves public cache',
              );
              if (mounted) setState(() => revision++);
              debugPrint('HOME_DEVICE: STALE_READY');
            },
            child: const Text('QA Offline'),
          ),
          TextButton(
            onPressed: () async {
              if (widget.offline.existsSync()) await widget.offline.delete();
              home = widget.createHome();
              require(
                await home.load(HomeLoadRequest.refresh) is HomeLoaded,
                'real online recovery',
              );
              if (mounted) setState(() => revision++);
              debugPrint('HOME_DEVICE: RECOVERED_READY');
            },
            child: const Text('QA Recover'),
          ),
          TextButton(
            onPressed: () async {
              final old = widget.shell;
              await widget.runtime.signOut();
              require(
                widget.runtime.state.gate == ShellGate.authentication,
                'closing removes Home presentation',
              );
              require(
                await old.submit(const ExploreMapIntent())
                    is ShellAuthenticationRequired,
                'old scope intent cannot navigate',
              );
              debugPrint('HOME_DEVICE: CLOSED_READY');
            },
            child: const Text('QA Close'),
          ),
        ],
      ),
    ],
  );
}
