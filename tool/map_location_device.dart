// Explicit parameter types and initialization follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

// Opt-in real Map/Privacy/Shell device acceptance in an isolated namespace.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:locatemy/app/app.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/l10n/language_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_privacy_device.dart' show HarnessHttpClient;

void require(bool condition, String name) {
  if (!condition) {
    debugPrint('MAP_DEVICE: FAILED $name');
    throw StateError(name);
  }
  debugPrint('MAP_DEVICE: PASS $name');
}

class MapDeviceNetwork extends http.BaseClient {
  MapDeviceNetwork(File offline) : offline = offline;
  final File offline;
  final HarnessHttpClient inner = HarnessHttpClient();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest r) {
    if (offline.existsSync() && r.url.path.contains('user_saved_locations')) {
      throw http.ClientException('QA unavailable');
    }
    return inner.send(r);
  }

  @override
  void close() {
    inner.close();
  }
}

class MapProxy extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..findProxy = (_) =>
          'PROXY 127.0.0.1:${const int.fromEnvironment('LOCATEMY_PRIVACY_PROXY_PORT')}';
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MapProxy();
  SharedPreferences.setPrefix('flutter.map.wave4.');
  final LanguageController language = LanguageController(
    preferences: await SharedPreferences.getInstance(),
  );
  final Directory dir = Directory(
    '${(await getApplicationSupportDirectory()).path}/map-wave4-harness',
  );
  await dir.create(recursive: true);
  final File offline = File('${dir.path}/offline');
  final File started = File('${dir.path}/started');
  if (!started.existsSync()) {
    await language.select('zh');
    await started.writeAsString('1');
  }
  final SupabaseClient client = SupabaseClient(
    const String.fromEnvironment('SUPABASE_URL'),
    const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    httpClient: MapDeviceNetwork(offline),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  final auth = createAuthenticationSession(client),
      authVm = createAuthenticationViewModel(
        createAuthenticationSession(client),
      );
  require(
    await auth.signIn(
      email: const String.fromEnvironment('LOCATEMY_EMAIL'),
      password: const String.fromEnvironment('LOCATEMY_PASSWORD'),
    ) is SignInSucceeded,
    'real confirmed sign-in',
  );
  final Database db = await openDatabase('${dir.path}/map.db');
  late AccountPrivacy privacy;
  late ShellRuntime shell;
  final MapLocationRuntime map = MapLocationRuntime(
    readScope: () => privacy.readScope(),
    validatePoint: (p) => validateLocationInMalaysia(client, p),
    storageForAccount: (id) =>
        createLocationStorage(client: client, database: db, accountId: id),
  );
  shell = ShellRuntime.compose(
    authentication: auth,
    privacy: () => privacy,
    intents: mapShellBindings(() => shell),
  );
  privacy = createAccountPrivacy(
    authenticationSession: auth,
    participants: [createAuthenticationPrivacyParticipant(auth), shell, map],
    requiredParticipants: const {
      AccountPrivacyParticipantId.authenticationSession,
      AccountPrivacyParticipantId.applicationShell,
      AccountPrivacyParticipantId.mapLocation,
    },
    stateDirectory: Directory('${dir.path}/privacy'),
  );
  await shell.initialize();
  require(shell.state.gate == ShellGate.opened, 'production privacy gate');
  final LocationCoordinator locations = map.locations;
  final SavedLocationsSnapshot saved = await locations
      .synchronizeSavedLocations();
  if (offline.existsSync()) {
    // read_saved_locations is readable, replay create fails at external HTTP seam.
    require(
      saved is SavedLocationsUnavailable,
      'offline replay reports unavailable',
    );
    debugPrint('MAP_DEVICE: RESTART_QUEUED_READY');
  } else {
    require(saved is SavedLocationsAvailable, 'real favorites read');
    debugPrint('MAP_DEVICE: READY');
  }
  runApp(
    LocateMyApp(
      authenticationViewModel: authVm,
      shellRuntime: shell,
      languageController: language,
      shellViews: ShellViews(
        home: (context, scoped) => DeviceMapPanel(
          locations: locations,
          shell: scoped,
          runtime: shell,
          language: language,
          offline: offline,
        ),
        map: (context, scoped) => MapLocationPage(
          locations: locations,
          layerHost: locationLayerHost(locations),
          workspace: locationWorkspace(locations),
          applicationShell: scoped,
          search: createLocationSearch(
            apiKey: const String.fromEnvironment('GEOAPIFY_API_KEY'),
            client: HarnessHttpClient(),
          ),
        ),
        tasks: [
          ShellTaskView<OpenAnalysisIntent>(
            'location-analysis',
            (c, i) => MapFutureDestination(locations: [i.location]),
          ),
          ShellTaskView<OpenLocationComparisonIntent>(
            'location-comparison',
            (c, i) =>
                MapFutureDestination(locations: [i.locationA, i.locationB]),
          ),
          ShellTaskView<OpenMapLayerIntent>(
            'map-layer',
            (c, i) => MapFutureDestination(locations: []),
          ),
        ],
      ),
    ),
  );
}

class DeviceMapPanel extends StatelessWidget {
  const DeviceMapPanel({
    required LocationCoordinator locations,
    required ApplicationShell shell,
    required ShellRuntime runtime,
    required LanguageController language,
    required File offline,
    super.key,
  }) : locations = locations,
       shell = shell,
       runtime = runtime,
       language = language,
       offline = offline;
  final LocationCoordinator locations;
  final ApplicationShell shell;
  final ShellRuntime runtime;
  final LanguageController language;
  final File offline;
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        TextButton(
          onPressed: () async {
            final LocationSelectionOutcome selected = await locations.select(
              const LocationSelectionRequest(
                role: LocationRole.single,
                point: GeographicPoint(latitude: 3.0738, longitude: 101.5183),
                displayName: 'Shah Alam',
              ),
            );
            require(selected is LocationSelected, 'real valid selection');
            debugPrint('MAP_DEVICE: SELECTED_READY');
          },
          child: const Text('QA Pick'),
        ),
        TextButton(
          onPressed: () async {
            final LocationSelectionOutcome selected = await locations.select(
              const LocationSelectionRequest(
                role: LocationRole.single,
                point: GeographicPoint(latitude: 3, longitude: 104),
              ),
            );
            require(
              selected is LocationSelectionRejected &&
                  selected.failure == LocationSelectionFailure.outsideMalaysia,
              'ocean rejected',
            );
            debugPrint('MAP_DEVICE: REJECTED_READY');
          },
          child: const Text('QA Outside'),
        ),
        TextButton(
          onPressed: () async {
            final LocationPresent selected =
                locations.read(LocationRole.single) as LocationPresent;
            await offline.writeAsString('1');
            require(
              await locations.save(
                SaveLocationRequest(
                  location: selected.location,
                  name: 'Queued QA location',
                ),
              ) is SavedLocationQueued,
              'durable offline create',
            );
            debugPrint('MAP_DEVICE: QUEUED_READY');
          },
          child: const Text('QA Queue'),
        ),
        TextButton(
          onPressed: () async {
            if (offline.existsSync()) await offline.delete();
            final SavedLocationsSnapshot result = await locations
                .synchronizeSavedLocations();
            debugPrint(
              'MAP_DEVICE: SYNC_STATE ${result.runtimeType} ${result is SavedLocationsUnavailable ? result.failure.name : (result as SavedLocationsAvailable).locations.map((r) => r.syncState.name).join(',')}',
            );
            require(
              result is SavedLocationsAvailable &&
                  result.locations.any(
                    (r) =>
                        r.name == 'Queued QA location' &&
                        r.syncState == SavedLocationSyncState.synchronized,
                  ),
              'durable replay synchronized',
            );
            debugPrint('MAP_DEVICE: RECOVERED_READY');
          },
          child: const Text('QA Recover'),
        ),
        TextButton(
          onPressed: () async {
            final ApplicationShell old = shell;
            await runtime.signOut();
            require(
              runtime.state.gate == ShellGate.authentication,
              'scope closed',
            );
            require(
              locations.read(LocationRole.single) is LocationAbsent,
              'private selections cleared',
            );
            require(
              await old.submit(
                const OpenAnalysisIntent(
                  location: ValidLocationReference(
                    locationId: 'stale',
                    point: GeographicPoint(latitude: 3, longitude: 101),
                  ),
                ),
              ) is ShellAuthenticationRequired,
              'old scope intent denied',
            );
            debugPrint('MAP_DEVICE: CLOSED_READY');
          },
          child: const Text('QA Close'),
        ),
      ],
    );
  }
}
