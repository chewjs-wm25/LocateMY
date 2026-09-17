// Explicit constructors follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:locatemy/app/app.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/home_relocation_outlook/home_relocation_outlook.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/nearby_facilities/nearby_facilities.dart';
import 'package:locatemy/l10n/language_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_privacy_device.dart' show HarnessHttpClient;

/// Fault injection at the external HTTP boundary; feature implementations remain real.
final class FacilityDeviceClient extends http.BaseClient {
  final File mode;
  final http.Client inner = HarnessHttpClient();
  FacilityDeviceClient(File mode) : mode = mode;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final String value = mode.existsSync() ? mode.readAsStringSync() : 'live';
    if (value == 'offline') {
      throw http.ClientException('QA network unavailable');
    }
    if (value == 'rate') {
      return http.StreamedResponse(
        Stream<List<int>>.value(utf8.encode('rate limited')),
        429,
      );
    }
    return inner.send(request);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Credentials are supplied at runtime over adb-reversed loopback, never built into the APK.
  final HttpClient configurationClient = HttpClient();
  final HttpClientRequest request = await configurationClient.getUrl(
    Uri.parse(
      'http://127.0.0.1:${const int.fromEnvironment('FACILITY_QA_PORT')}/fixture',
    ),
  );
  final HttpClientResponse response = await request.close();
  final Map<String, dynamic> fixture = jsonDecode(
    await response.transform(utf8.decoder).join(),
  ) as Map<String, dynamic>;
  configurationClient.close();
  final SupabaseClient client = SupabaseClient(
    fixture['SUPABASE_URL'] as String,
    fixture['SUPABASE_PUBLISHABLE_KEY'] as String,
    httpClient: HarnessHttpClient(),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  final AuthenticationSession authentication = createAuthenticationSession(
    client,
  );
  final AuthenticationViewModel authenticationVm =
      createAuthenticationViewModel(authentication);
  if (await authentication.signIn(
    email: fixture['LOCATEMY_EMAIL'] as String,
    password: fixture['LOCATEMY_PASSWORD'] as String,
  ) is! SignInSucceeded) {
    throw StateError('QA sign-in failed');
  }
  fixture.clear();
  final Directory directory = Directory(
    '${(await getApplicationSupportDirectory()).path}/facility-wave5',
  );
  await directory.create(recursive: true);
  final File mode = File('${directory.path}/network-mode');
  final LanguageController language = LanguageController(
    preferences: await SharedPreferences.getInstance(),
  );
  await language.select('zh');
  late AccountPrivacy privacy;
  late ShellRuntime shell;
  final Database database = await openDatabase(
    '${directory.path}/public-and-map.db',
  );
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
  final NearbyFacilities facilities = createNearbyFacilities(
    source: createOverpassFacilitySource(FacilityDeviceClient(mode)),
    database: database,
    scopeToken: () {
      final AccountScopeSnapshot snapshot = privacy.readScope();
      if (snapshot is AccountScopeOpened &&
          shell.state.gate == ShellGate.opened) {
        return snapshot.scope;
      }
      return null;
    },
    mapLayerHost: () {
      return locationLayerHost(map.locations);
    },
  );
  shell = ShellRuntime.compose(
    authentication: authentication,
    privacy: () {
      return privacy;
    },
    intents: <ShellIntentBinding>[
      ...mapShellBindings(() {
        return shell;
      }),
      ...facilityShellBindings(() {
        return shell;
      }),
    ],
    contributions: facilityShellContributions(),
  );
  privacy = createAccountPrivacy(
    authenticationSession: authentication,
    participants: <AccountPrivacyParticipant>[
      createAuthenticationPrivacyParticipant(authentication),
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
  final LocationSelectionOutcome selected = await map.locations.select(
    const LocationSelectionRequest(
      role: LocationRole.single,
      point: GeographicPoint(latitude: 3.0738, longitude: 101.6072),
      displayName: 'Sunway Mentari',
    ),
  );
  if (selected is! LocationSelected) {
    throw StateError('QA location validation failed');
  }
  final ValidLocationReference location = selected.location;
  final ShellViews production = mapAndHomeShellViews(
    () {
      return createHomeRelocationOutlook(client);
    },
    map,
    facilities,
    createLocationSearch(apiKey: ''),
    runtime: () {
      return shell;
    },
  );
  runApp(
    LocateMyApp(
      authenticationViewModel: authenticationVm,
      shellRuntime: shell,
      languageController: language,
      shellViews: ShellViews(
        map: production.map,
        tasks: production.tasks,
        contributions: production.contributions,
        home: (BuildContext context, ApplicationShell scoped) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              const Text('Nearby Facilities Wave 5 QA'),
              FilledButton(
                onPressed: () {
                  scoped.submit(OpenNearbyFacilitiesIntent(location: location));
                },
                child: const Text('QA Facilities'),
              ),
              TextButton(
                onPressed: () async {
                  await mode.writeAsString('offline');
                  debugPrint('FACILITY_DEVICE: OFFLINE');
                },
                child: const Text('QA Offline'),
              ),
              TextButton(
                onPressed: () async {
                  await mode.writeAsString('live');
                  debugPrint('FACILITY_DEVICE: ONLINE');
                },
                child: const Text('QA Recover'),
              ),
              TextButton(
                onPressed: () async {
                  await mode.writeAsString('rate');
                  final LocationSelectionOutcome second = await map.locations
                      .select(
                        const LocationSelectionRequest(
                          role: LocationRole.locationB,
                          point: GeographicPoint(
                            latitude: 3.14,
                            longitude: 101.69,
                          ),
                          displayName: 'Kuala Lumpur',
                        ),
                      );
                  if (second is LocationSelected) {
                    await scoped.submit(
                      OpenNearbyFacilitiesIntent(location: second.location),
                    );
                  }
                },
                child: const Text('QA Failure'),
              ),
              TextButton(
                onPressed: () async {
                  await mode.writeAsString('live');
                  final LocationSelectionOutcome second = await map.locations
                      .select(
                        const LocationSelectionRequest(
                          role: LocationRole.locationB,
                          point: GeographicPoint(
                            latitude: 3.14,
                            longitude: 101.69,
                          ),
                          displayName: 'Kuala Lumpur',
                        ),
                      );
                  if (second is LocationSelected) {
                    await scoped.submit(
                      OpenNearbyFacilitiesComparisonIntent(
                        locationA: location,
                        locationB: second.location,
                      ),
                    );
                  }
                },
                child: const Text('QA Compare'),
              ),
              TextButton(
                onPressed: () async {
                  final FacilityAnalysisOutcome result = await facilities
                      .analyse(
                        FacilityAnalysisRequest(
                          location: location,
                          refreshPolicy: FacilityRefreshPolicy.cacheAllowed,
                        ),
                      );
                  if (result is FacilityAnalysisAvailable) {
                    locationWorkspace(map.locations).setViewport('facility-qa');
                    final FacilityLayerOutcome layer = await facilities
                        .contributeLayer(
                          FacilityLayerRequest(
                            analysis: result.analysis,
                            viewportVersion: 'facility-qa',
                          ),
                        );
                    debugPrint(
                      'FACILITY_DEVICE: LAYER_${layer is FacilityLayerPublished ? 'PASS' : 'FAILED'}',
                    );
                  }
                },
                child: const Text('QA Layer'),
              ),
              TextButton(
                onPressed: () async {
                  final NearbyFacilitiesSummaryContribution stale =
                      NearbyFacilitiesSummaryContribution(
                        location: location,
                        outcome: const FacilityAnalysisUnavailable(
                          failure: FacilityFailure.sourceUnavailable,
                        ),
                        returnContext: shell.currentContext,
                      );
                  await shell.signOut();
                  final ShellContributionOutcome outcome = await scoped.publish(
                    stale,
                  );
                  debugPrint(
                    'FACILITY_DEVICE: CLOSED_${outcome is ShellContributionAuthenticationRequired || outcome is ShellContributionRejected ? 'PASS' : 'FAILED'}',
                  );
                },
                child: const Text('QA Close'),
              ),
            ],
          );
        },
      ),
    ),
  );
  debugPrint('FACILITY_DEVICE: READY');
}
