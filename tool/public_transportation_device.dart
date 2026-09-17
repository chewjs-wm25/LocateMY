// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
// Opt-in, isolated real Auth/Privacy/Shell/Map/RPC page verification.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/public_transportation/public_transportation.dart';
import 'package:locatemy/l10n/language_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_privacy_device.dart' show HarnessHttpClient;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setPrefix('flutter.transit.wave5.');
  final LanguageController language = LanguageController(
    preferences: await SharedPreferences.getInstance(),
  );
  await language.select('zh');
  final SupabaseClient client = SupabaseClient(
    const String.fromEnvironment('SUPABASE_URL'),
    const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    httpClient: HarnessHttpClient(),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  final AuthenticationSession auth = createAuthenticationSession(client);
  final AuthenticationViewModel authVm = createAuthenticationViewModel(auth);
  final SignInOutcome signIn = await auth.signIn(
    email: const String.fromEnvironment('LOCATEMY_EMAIL'),
    password: const String.fromEnvironment('LOCATEMY_PASSWORD'),
  );
  if (signIn is! SignInSucceeded) {
    debugPrint('TRANSIT_DEVICE: FAILED sign-in');
    return;
  }
  final Directory directory = Directory(
    '${(await getApplicationSupportDirectory()).path}/transit-wave5-harness/${signIn.account.accountId}',
  );
  await directory.create(recursive: true);
  final Database database = await openDatabase('${directory.path}/map.db');
  late AccountPrivacy privacy;
  late ShellRuntime shell;
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
  shell = ShellRuntime.compose(
    authentication: auth,
    privacy: () {
      return privacy;
    },
    intents: [
      ...mapShellBindings(() {
        return shell;
      }),
      ...transitShellBindings(
        () {
          return shell;
        },
        locations: () {
          return map.locations;
        },
      ),
    ],
    contributions: transitShellContributions(() {
      return shell;
    }),
  );
  privacy = createAccountPrivacy(
    authenticationSession: auth,
    participants: <AccountPrivacyParticipant>[
      createAuthenticationPrivacyParticipant(auth),
      shell,
      map,
    ],
    requiredParticipants: const <AccountPrivacyParticipantId>{
      AccountPrivacyParticipantId.authenticationSession,
      AccountPrivacyParticipantId.applicationShell,
      AccountPrivacyParticipantId.mapLocation,
    },
    stateDirectory: Directory('${directory.path}/privacy'),
  );
  await shell.initialize();
  if (shell.state.gate != ShellGate.opened) {
    debugPrint('TRANSIT_DEVICE: FAILED scope');
    return;
  }
  final LocationSelectionOutcome selection = await map.locations.select(
    const LocationSelectionRequest(
      role: LocationRole.single,
      point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
      displayName: 'Sunway Mentari',
    ),
  );
  if (selection is! LocationSelected) {
    debugPrint('TRANSIT_DEVICE: FAILED Map selection');
    return;
  }
  final LocationSelected a = (await map.locations.select(
    const LocationSelectionRequest(
      role: LocationRole.locationA,
      point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
      displayName: 'Sunway Mentari',
    ),
  )) as LocationSelected;
  final LocationSelected b = (await map.locations.select(
    const LocationSelectionRequest(
      role: LocationRole.locationB,
      point: GeographicPoint(latitude: 3.0838, longitude: 101.6177),
      displayName: 'Subang',
    ),
  )) as LocationSelected;
  final TransitDeviceReader reader = TransitDeviceReader(
    SupabaseTransitReader(client),
  );
  final PublicTransportation transportation = createPublicTransportation(
    reader,
  );

  debugPrint('TRANSIT_DEVICE: READY');
  runApp(
    LocateMyApp(
      authenticationViewModel: authVm,
      shellRuntime: shell,
      languageController: language,
      shellViews: ShellViews(
        home: (BuildContext context, ApplicationShell scoped) {
          return Column(
            children: <Widget>[
              TextButton(
                onPressed: () {
                  reader.controlled = true;
                  reader.offline = false;
                  scoped.submit(
                    OpenPublicTransportationIntent(
                      AnalysisReturnContext(
                        location: selection.location,
                        role: LocationRole.single,
                        analysisDate: DateTime(2026, 9, 17),
                        originalRequestIdentity: shell.currentContext!,
                      ),
                    ),
                  );
                },
                child: const Text('QA Controlled served'),
              ),
              TextButton(
                onPressed: () {
                  reader.offline = true;
                  scoped.submit(
                    OpenPublicTransportationIntent(
                      AnalysisReturnContext(
                        location: selection.location,
                        role: LocationRole.single,
                        analysisDate: DateTime(2026, 9, 17),
                        originalRequestIdentity: shell.currentContext!,
                      ),
                    ),
                  );
                },
                child: const Text('QA Controlled offline cache'),
              ),
              TextButton(
                onPressed: () async {
                  reader.controlled = false;
                  reader.offline = false;
                  await language.select('en');
                  reader.controlled = false;
                  reader.offline = false;
                  scoped.submit(
                    OpenPublicTransportationIntent(
                      AnalysisReturnContext(
                        location: selection.location,
                        role: LocationRole.single,
                        analysisDate: DateTime(2026, 9, 17),
                        originalRequestIdentity: shell.currentContext!,
                      ),
                    ),
                  );
                },
                child: const Text('QA English transportation'),
              ),
              TextButton(
                onPressed: () {
                  AnalysisReturnContext input(
                    ValidLocationReference location,
                    LocationRole role,
                  ) {
                    return AnalysisReturnContext(
                      location: location,
                      role: role,
                      analysisDate: DateTime(2026, 9, 17),
                      originalRequestIdentity: shell.currentContext!,
                    );
                  }

                  scoped.submit(
                    OpenPublicTransportationComparisonIntent(
                      input(a.location, LocationRole.locationA),
                      input(b.location, LocationRole.locationB),
                    ),
                  );
                },
                child: const Text('QA Transportation comparison'),
              ),
              TextButton(
                onPressed: () {
                  reader.controlled = false;
                  reader.offline = false;
                  scoped.submit(
                    OpenPublicTransportationIntent(
                      AnalysisReturnContext(
                        location: selection.location,
                        role: LocationRole.single,
                        analysisDate: DateTime(2026, 9, 17),
                        originalRequestIdentity: shell.currentContext!,
                      ),
                    ),
                  );
                },
                child: const Text('QA Open transportation'),
              ),
              TextButton(
                onPressed: () {
                  reader.controlled = false;
                  reader.offline = false;
                  scoped.submit(
                    OpenPublicTransportationIntent(
                      AnalysisReturnContext(
                        location: selection.location,
                        role: LocationRole.single,
                        analysisDate: DateTime(2040, 1, 1),
                        originalRequestIdentity: shell.currentContext!,
                      ),
                    ),
                  );
                },
                child: const Text('QA Outside service range'),
              ),
            ],
          );
        },
        map: (BuildContext context, ApplicationShell scoped) {
          return MapLocationPage(
            locations: map.locations,
            layerHost: locationLayerHost(map.locations),
            workspace: locationWorkspace(map.locations),
            applicationShell: scoped,
            search: createLocationSearch(apiKey: ''),
          );
        },
        tasks: transitTaskViews(transportation, map, () {
          return shell;
        }),
      ),
    ),
  );
}

/// Controlled external-boundary UI states are opt-in QA only, never a production data source.
final class TransitDeviceReader implements TransitAnalysisReader {
  final TransitAnalysisReader real;
  bool controlled = false;
  bool offline = false;
  TransitDeviceReader(TransitAnalysisReader real) : real = real;
  @override
  Future<Map<String, Object?>> readTransitAnalysis(
    TransitRequest request,
  ) async {
    if (offline) {
      throw StateError('Controlled offline boundary');
    }
    final Map<String, Object?> result = await real.readTransitAnalysis(request);
    if (!controlled) {
      return result;
    }
    result['availability_status'] = 'available';
    result['service_outcome'] = 'served';
    result['snapshot_id'] = 'controlled-transit-ui-fixture';
    result['transit_score'] = 68;
    final List<Object?> feeds = result['feeds'] as List<Object?>;
    for (final Object? value in feeds) {
      final Map<String, Object?> feed = Map<String, Object?>.from(value as Map);
      feed['availability'] = 'usable';
      feed['reason'] = null;
      feed['captured_at'] = '2026-09-17T00:00:00Z';
      feeds[feeds.indexOf(value)] = feed;
    }
    return result;
  }
}
