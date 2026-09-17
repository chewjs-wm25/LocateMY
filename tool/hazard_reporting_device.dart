// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
// Opt-in acceptance harness: real Auth, Privacy, Shell, Map and Hazard Adapter.
// Only failure is injected at the HTTP boundary; fixture login is never shown.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:locatemy/app/app.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/hazard_reporting/hazard_reporting.dart';
import 'package:locatemy/features/home_relocation_outlook/home_relocation_outlook.dart';
import 'package:locatemy/features/nearby_facilities/nearby_facilities.dart';
import 'package:locatemy/l10n/language_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_privacy_device.dart' show HarnessHttpClient;

final class HazardDeviceNetwork extends http.BaseClient {
  final File offline;
  final http.Client inner = HarnessHttpClient();
  HazardDeviceNetwork(File offline) : offline = offline;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (offline.existsSync() && request.url.path.contains('/rpc/hazard_')) {
      throw http.ClientException('QA external boundary unavailable');
    }
    return inner.send(request);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setPrefix('flutter.hazard.wave5.');
  final LanguageController language = LanguageController(
    preferences: await SharedPreferences.getInstance(),
  );
  final Directory directory = Directory(
    '${(await getApplicationSupportDirectory()).path}/hazard-wave5-harness',
  );
  await directory.create(recursive: true);
  final File started = File('${directory.path}/started');
  if (!started.existsSync()) {
    await language.select('zh');
    await started.writeAsString('1');
  }
  final File offline = File('${directory.path}/offline');
  final SupabaseClient client = SupabaseClient(
    const String.fromEnvironment('SUPABASE_URL'),
    const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    httpClient: HazardDeviceNetwork(offline),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  final AuthenticationSession auth = createAuthenticationSession(client);
  final AuthenticationViewModel authVm = createAuthenticationViewModel(auth);
  if (await auth.signIn(
    email: const String.fromEnvironment('LOCATEMY_EMAIL'),
    password: const String.fromEnvironment('LOCATEMY_PASSWORD'),
  ) is! SignInSucceeded) {
    throw StateError('Fixture sign-in failed');
  }
  late AccountPrivacy privacy;
  late ShellRuntime shell;
  final Database database = await openDatabase('${directory.path}/map.db');
  final MapLocationRuntime map = MapLocationRuntime(
    readScope: () {
      return privacy.readScope();
    },
    validatePoint: (GeographicPoint point) {
      return validateLocationInMalaysia(client, point);
    },
    storageForAccount: (String id) {
      return createLocationStorage(
        client: client,
        database: database,
        accountId: id,
      );
    },
  );
  final HazardReportingRuntime hazards = HazardReportingRuntime(
    store: createSupabaseHazardStore(client),
    readScope: () {
      return privacy.readScope();
    },
  );
  shell = ShellRuntime.compose(
    authentication: auth,
    privacy: () {
      return privacy;
    },
    intents: [
      ...mapShellBindings(() {
        return shell;
      }),
      ...hazardShellBindings(() {
        return shell;
      }),
    ],
  );
  privacy = createAccountPrivacy(
    authenticationSession: auth,
    participants: [
      createAuthenticationPrivacyParticipant(auth),
      shell,
      map,
      hazards,
    ],
    requiredParticipants: const {
      AccountPrivacyParticipantId.authenticationSession,
      AccountPrivacyParticipantId.applicationShell,
      AccountPrivacyParticipantId.mapLocation,
      AccountPrivacyParticipantId.hazardReporting,
    },
    stateDirectory: Directory('${directory.path}/privacy'),
  );
  await shell.initialize();
  final MapLayerIntentOutcome selected = await locationLayerHost(map.locations)
      .requestLongPress(
        const GeographicPoint(latitude: 3.0738, longitude: 101.6072),
      );
  if (selected is! MapLayerIntentAccepted ||
      selected.intent is! CreateHazardIntent) {
    throw StateError('Real Map location validation failed');
  }
  final ValidLocationReference location =
      (selected.intent as CreateHazardIntent).location;
  final NearbyFacilities nearby = createNearbyFacilities(
    source: createOverpassFacilitySource(HarnessHttpClient()),
    mapLayerHost: () {
      return locationLayerHost(map.locations);
    },
  );
  final ShellViews production = mapAndHomeShellViews(
    () {
      return createHomeRelocationOutlook(client);
    },
    map,
    nearby,
    createLocationSearch(apiKey: ''),
    hazards: hazards,
    runtime: () {
      return shell;
    },
  );
  runApp(
    LocateMyApp(
      authenticationViewModel: authVm,
      shellRuntime: shell,
      languageController: language,
      shellViews: ShellViews(
        map: production.map,
        tasks: production.tasks,
        home: (BuildContext context, ApplicationShell scoped) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Hazard Wave 5 QA'),
              FilledButton(
                onPressed: () {
                  scoped.submit(
                    OpenHazardComposerIntent(
                      location: location,
                      returnContextId: 'map',
                    ),
                  );
                },
                child: const Text('QA Composer'),
              ),
              FilledButton(
                onPressed: () {
                  scoped.submit(const OpenMyHazardsIntent('map'));
                },
                child: const Text('QA My Reports'),
              ),
              TextButton(
                onPressed: () async {
                  await offline.writeAsString('1');
                  debugPrint('HAZARD_DEVICE: OFFLINE_READY');
                },
                child: const Text('QA Offline'),
              ),
              TextButton(
                onPressed: () async {
                  if (offline.existsSync()) {
                    await offline.delete();
                  }
                  debugPrint('HAZARD_DEVICE: ONLINE_READY');
                },
                child: const Text('QA Recover'),
              ),
              TextButton(
                onPressed: () async {
                  await shell.signOut();
                  debugPrint('HAZARD_DEVICE: CLOSED_READY');
                },
                child: const Text('QA Close'),
              ),
            ],
          );
        },
      ),
    ),
  );
  debugPrint('HAZARD_DEVICE: READY');
}
