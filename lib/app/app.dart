// Explicit parameter types and initialization follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

export 'src/presentation/shell_host.dart'
    show ShellViews, ShellTaskView, ShellContributionView;
export 'src/domain/shell_routes.dart';
export 'transit_composition.dart';
export 'src/application/shell_runtime.dart';
export 'src/domain/shell_state.dart';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'application_shell.dart';

import 'src/application/shell_runtime.dart';
import 'src/domain/shell_routes.dart';
import 'src/domain/shell_state.dart';
import '../features/home_relocation_outlook/home_relocation_outlook.dart';
import '../features/map_location/map_location.dart';
import '../features/nearby_facilities/nearby_facilities.dart';
import '../features/hazard_reporting/hazard_reporting.dart';
import '../features/public_transportation/public_transportation.dart';
import 'transit_composition.dart';

import 'package:sqflite/sqflite.dart';

import 'src/presentation/shell_view_model.dart';
import 'src/presentation/shell_host.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import '../l10n/language_controller.dart';

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../features/authentication_session/authentication_session.dart';
import '../features/account_privacy/account_privacy.dart';

Future<void> startLocateMy() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  final languageController = LanguageController(
    preferences: await SharedPreferences.getInstance(),
  );
  try {
    SupabaseConfig.validate();
  } on StateError {
    runApp(
      ChangeNotifierProvider.value(
        value: languageController,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.watch<LanguageController>().locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(actions: const [LanguageButton()]),
                body: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        AppLocalizations.of(context)!.configurationMissing,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  final sessionAdapter = createAuthenticationSession(Supabase.instance.client);
  final viewModel = createAuthenticationViewModel(sessionAdapter);
  late final AccountPrivacy privacy;
  late final ShellRuntime shell;
  final Database mapDatabase = await openDatabase(
    '${await getDatabasesPath()}/locatemy-map-private.db',
  );
  final MapLocationRuntime mapRuntime = MapLocationRuntime(
    readScope: () {
      return privacy.readScope();
    },
    validatePoint: (GeographicPoint point) {
      return validateLocationInMalaysia(Supabase.instance.client, point);
    },
    storageForAccount: (String id) {
      return createLocationStorage(
        client: Supabase.instance.client,
        database: mapDatabase,
        accountId: id,
      );
    },
  );
  final HazardReportingRuntime hazardRuntime = HazardReportingRuntime(
    store: createSupabaseHazardStore(Supabase.instance.client),
    readScope: () {
      return privacy.readScope();
    },
  );
  final NearbyFacilities nearbyFacilities = createNearbyFacilities(
    source: createOverpassFacilitySource(http.Client()),
    database: mapDatabase,
    scopeToken: () {
      final AccountScopeSnapshot snapshot = privacy.readScope();
      if (snapshot is AccountScopeOpened &&
          shell.state.gate == ShellGate.opened) {
        return snapshot.scope;
      }
      return null;
    },
    mapLayerHost: () => locationLayerHost(mapRuntime.locations),
  );
  final PublicTransportation transportation = createPublicTransportation(
    SupabaseTransitReader(Supabase.instance.client),
  );
  shell = ShellRuntime.compose(
    authentication: sessionAdapter,
    privacy: () => privacy,
    intents: [
      homeExploreMapBinding(() => shell),
      ...mapShellBindings(() => shell),
      ...facilityShellBindings(() {
        return shell;
      }),
      ...hazardShellBindings(() => shell),
      ...transitShellBindings(
        () {
          return shell;
        },
        locations: () {
          return mapRuntime.locations;
        },
      ),
    ],
    contributions: [
      ...facilityShellContributions(),
      ...transitShellContributions(() {
        return shell;
      }),
    ],
  );
  privacy = createAccountPrivacy(
    authenticationSession: sessionAdapter,
    participants: [
      createAuthenticationPrivacyParticipant(sessionAdapter),
      shell,
      mapRuntime,
      hazardRuntime,
    ],
    // Only these owners can create private state in the current app. Add each
    // future feature here when wiring its views/storage, even if its participant
    // is missing, so a registration defect still blocks logout.
    requiredParticipants: const {
      AccountPrivacyParticipantId.authenticationSession,
      AccountPrivacyParticipantId.applicationShell,
      AccountPrivacyParticipantId.mapLocation,
      AccountPrivacyParticipantId.hazardReporting,
    },
    stateDirectory: Directory(
      '${(await getApplicationSupportDirectory()).path}/account-privacy',
    ),
  );
  runApp(
    LocateMyApp(
      authenticationViewModel: viewModel,
      shellRuntime: shell,
      languageController: languageController,
      shellViews: mapAndHomeShellViews(
        () => createHomeRelocationOutlook(Supabase.instance.client),
        mapRuntime,
        nearbyFacilities,
        createLocationSearch(
          apiKey: const String.fromEnvironment('GEOAPIFY_API_KEY').isNotEmpty
              ? const String.fromEnvironment('GEOAPIFY_API_KEY')
              : dotenv.env['GEOAPIFY_API_KEY'] ?? '',
        ),
        hazards: hazardRuntime,
        transportation: transportation,
        runtime: () {
          return shell;
        },
      ),
      onRetryProfile: () => viewModel.retryProfile(
        () => retryAuthenticationOptionalProfile(sessionAdapter),
      ),
    ),
  );
}

final class LocateMyApp extends StatefulWidget {
  final LanguageController? languageController;
  final AuthenticationViewModel authenticationViewModel;
  final Future<void> Function()? onRetryProfile;
  final ShellRuntime? shellRuntime;
  final ShellViews shellViews;

  const LocateMyApp({
    required this.authenticationViewModel,
    this.onRetryProfile,
    this.languageController,
    this.shellRuntime,
    this.shellViews = const ShellViews(),
    super.key,
  });

  @override
  State<LocateMyApp> createState() => _LocateMyAppState();
}

final class _LocateMyAppState extends State<LocateMyApp> {
  late final LanguageController _languageController =
      widget.languageController ?? LanguageController();

  ShellViewModel? _shellViewModel;
  @override
  void initState() {
    super.initState();
    if (widget.shellRuntime != null) {
      _shellViewModel = ShellViewModel(widget.shellRuntime!);
      _shellViewModel!.initialize();
    }
  }

  @override
  void dispose() {
    _shellViewModel?.dispose();
    if (widget.languageController == null) _languageController.dispose();
    super.dispose();
  }

  Widget _authenticationPage() => AuthenticationPage(
    viewModel: widget.authenticationViewModel,
    onSignOut:
        _shellViewModel?.signOut ?? widget.authenticationViewModel.signOut,
    onRetryProfile: widget.onRetryProfile,
  );
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: _languageController,
    child: ListenableBuilder(
      listenable: Listenable.merge([?_shellViewModel]),
      builder: (context, _) => MaterialApp(
        locale: context.watch<LanguageController>().locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        title: 'LocateMY',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF155EEF))
              .copyWith(
                primary: const Color(0xFF155EEF),
                onPrimary: Colors.white,
                surface: Colors.white,
                error: const Color(0xFFC9362B),
                onSurface: const Color(0xFF172033),
              ),
          scaffoldBackgroundColor: const Color(0xFFF6F8FB),
          textTheme: ThemeData.light().textTheme.apply(
            fontFamily: 'SourceSansPro',
            bodyColor: const Color(0xFF172033),
            displayColor: const Color(0xFF172033),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            hintStyle: const TextStyle(fontSize: 15, color: Color(0xFF667085)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD9E0EA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF155EEF), width: 2),
            ),
            errorMaxLines: 3,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          useMaterial3: true,
        ),
        home: _shellViewModel == null
            ? _authenticationPage()
            : ShellHost(
                viewModel: _shellViewModel!,
                authentication: _authenticationPage(),
                views: widget.shellViews,
              ),
      ),
    ),
  );
}

/// Root projects the provider's fieldless marker into Shell navigation only.
ShellIntentBinding<ExploreMapIntent> homeExploreMapBinding(
  ShellRuntime Function() runtime,
) => ShellIntentBinding<ExploreMapIntent>(
  (_) => ShellRouteRequest.tab(
    context: runtime().currentContext,
    tab: ShellTab.map,
  ),
);

/// Each opened scope gets independent requests and refresh state; only durable
/// public SQLite data is shared. Weak keys do not retain closed account scopes.
ShellViews homeShellViews(HomeRelocationOutlook Function() createHome) {
  final providers = Expando<HomeRelocationOutlook>();
  return ShellViews(
    home: (context, shell) => HomeOutlookPage(
      home: providers[shell] ??= createHome(),
      applicationShell: shell,
    ),
  );
}

List<ShellIntentBinding> mapShellBindings(ShellRuntime Function() runtime) {
  return [
    ShellIntentBinding<OpenAnalysisIntent>(
      (intent) => ShellRouteRequest.task(
        context: runtime().currentContext,
        destination: 'location-analysis',
      ),
    ),
    ShellIntentBinding<OpenLocationComparisonIntent>(
      (intent) => ShellRouteRequest.task(
        context: runtime().currentContext,
        destination: 'location-comparison',
      ),
    ),
    ShellIntentBinding<OpenMapLayerIntent>(
      (intent) => ShellRouteRequest.task(
        context: runtime().currentContext,
        destination:
            intent.intent is CreateHazardIntent ||
                (intent.intent is ProviderDefinedIntent &&
                    (intent.intent as ProviderDefinedIntent).providerId ==
                        'hazard-reporting')
            ? 'hazard-map-intent'
            : 'map-layer',
      ),
    ),
  ];
}

ShellViews mapAndHomeShellViews(
  HomeRelocationOutlook Function() createHome,
  MapLocationRuntime map,
  NearbyFacilities nearbyFacilities,
  LocationSearch search, {
  HazardReportingRuntime? hazards,
  PublicTransportation? transportation,
  ShellRuntime Function()? runtime,
}) {
  final ShellViews home = homeShellViews(createHome);
  final Expando<ApplicationShell> facilityShells = Expando<ApplicationShell>();
  ApplicationShell? facilityShell() {
    final ShellRuntime? active = runtime?.call();
    final ShellRequestContext? request = active?.currentContext;
    if (active == null || request == null) {
      return null;
    }
    return facilityShells[request] ??= active.applicationShell!;
  }

  final Expando<ValueNotifier<String?>> facilityViewports =
      Expando<ValueNotifier<String?>>();
  final Expando<_HazardMapSession> hazardSessions =
      Expando<_HazardMapSession>();
  _HazardMapSession session() {
    // The opened AccountScope is stable; scoped Shell wrappers are ephemeral.
    final AccountScope scope = runtime!().state.scope!;
    final _HazardMapSession? previous = hazardSessions[scope];
    if (previous != null) {
      return previous;
    }
    final _HazardMapSession value = _HazardMapSession();
    hazardSessions[scope] = value;
    return value;
  }

  ShellRequestContext analysisRequest(ShellIntent intent) {
    return runtime!().state.routes.firstWhere((ShellNavigationEntry entry) {
      return identical(entry.intent, intent);
    }).context;
  }

  return ShellViews(
    home: home.home,
    map: (BuildContext context, ApplicationShell scoped) {
      if (runtime == null) {
        return MapLocationPage(
          locations: map.locations,
          layerHost: locationLayerHost(map.locations),
          workspace: locationWorkspace(map.locations),
          applicationShell: scoped,
          search: search,
        );
      }
      final AccountScope scope = runtime().state.scope!;
      final ValueNotifier<String?> viewport = facilityViewports[scope] ??=
          ValueNotifier<String?>(null);
      _HazardMapSession? current;
      if (hazards != null) {
        current = session();
      }
      final Widget mapPage = MapLocationPage(
        locations: map.locations,
        layerHost: locationLayerHost(map.locations),
        workspace: locationWorkspace(map.locations),
        applicationShell: scoped,
        search: search,
        layerFocus: current?.focus,
        onViewport:
            (
              String version,
              GeographicPoint southWest,
              GeographicPoint northEast,
            ) {
              viewport.value = version;
              current?.viewport.value = HazardPageRequest(
                viewportVersion: version,
                viewport: HazardViewport(southWest, northEast),
              );
            },
      );
      Widget child = mapPage;
      if (hazards != null && current != null) {
        child = HazardMapPanel(
          hazards: hazards.reporting,
          host: locationLayerHost(map.locations),
          viewport: current.viewport,
          revision: current.revision,
          onMine: () {
            scoped.submit(const OpenMyHazardsIntent('map'));
          },
          child: mapPage,
        );
      }
      return NearbyFacilitiesMapPanel(
        key: ValueKey(scope),
        facilities: nearbyFacilities,
        locations: map.locations,
        workspace: locationWorkspace(map.locations),
        viewport: viewport,
        child: child,
      );
    },
    contributions: <ShellContributionView>[
      ShellContributionView<NearbyFacilitiesSummaryContribution>((
        BuildContext context,
        NearbyFacilitiesSummaryContribution contribution,
      ) {
        return NearbyFacilitiesSummaryCard(contribution: contribution);
      }),
      ShellContributionView<NearbyFacilitiesComparisonContribution>((
        BuildContext context,
        NearbyFacilitiesComparisonContribution contribution,
      ) {
        return NearbyFacilitiesComparisonCard(contribution: contribution);
      }),
    ],
    tasks: [
      if (transportation != null && runtime != null)
        ...transitTaskViews(transportation, map, runtime),
      ShellTaskView<OpenNearbyFacilitiesIntent>('nearby-facilities', (
        BuildContext context,
        OpenNearbyFacilitiesIntent intent,
      ) {
        return NearbyFacilitiesPage(
          facilities: nearbyFacilities,
          location: intent.location,
          applicationShell: facilityShell(),
          returnContext: intent.returnContext ?? runtime?.call().currentContext,
        );
      }, ownsScaffold: true),
      ShellTaskView<OpenNearbyFacilitiesComparisonIntent>(
        'nearby-facilities-comparison',
        (BuildContext context, OpenNearbyFacilitiesComparisonIntent intent) {
          return NearbyFacilitiesPage(
            facilities: nearbyFacilities,
            location: intent.locationA,
            locationB: intent.locationB,
            applicationShell: facilityShell(),
            returnContext:
                intent.returnContext ?? runtime?.call().currentContext,
          );
        },
        ownsScaffold: true,
      ),
      if (hazards != null && runtime != null)
        ..._hazardTaskViews(hazards, runtime, session),

      ShellTaskView<OpenAnalysisIntent>(
        'location-analysis',
        (context, intent) => transportation != null && runtime != null
            ? TransportationAnalysisMenu(
                a: intent.location,
                runtime: runtime(),
                request: analysisRequest(intent),
                onNearby: () {
                  runtime().submit(
                    OpenNearbyFacilitiesIntent(location: intent.location),
                  );
                },
              )
            : NearbyFacilitiesPage(
                facilities: nearbyFacilities,
                location: intent.location,
                applicationShell: facilityShell(),
                returnContext: runtime?.call().currentContext,
              ),
        ownsScaffold: true,
      ),
      ShellTaskView<OpenLocationComparisonIntent>('location-comparison', (
        BuildContext context,
        OpenLocationComparisonIntent intent,
      ) {
        if (transportation != null && runtime != null) {
          return TransportationAnalysisMenu(
            a: intent.locationA,
            b: intent.locationB,
            runtime: runtime(),
            request: analysisRequest(intent),
            onNearby: () {
              runtime().submit(
                OpenNearbyFacilitiesComparisonIntent(
                  locationA: intent.locationA,
                  locationB: intent.locationB,
                ),
              );
            },
          );
        }
        return NearbyFacilitiesPage(
          facilities: nearbyFacilities,
          location: intent.locationA,
          locationB: intent.locationB,
          applicationShell: facilityShell(),
          returnContext: runtime?.call().currentContext,
        );
      }, ownsScaffold: true),
      ShellTaskView<OpenMapLayerIntent>(
        'map-layer',
        (c, i) => MapFutureDestination(
          locations: i.intent is CreateHazardIntent
              ? [(i.intent as CreateHazardIntent).location]
              : [],
        ),
      ),
    ],
  );
}

/// Development slot until Wave 5/6 providers register their real task views.
class MapFutureDestination extends StatelessWidget {
  final List<ValidLocationReference> locations;
  const MapFutureDestination({
    required List<ValidLocationReference> locations,
    super.key,
  }) : locations = locations;
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n =
        AppLocalizations.of(context) ??
        lookupAppLocalizations(Localizations.localeOf(context));
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.mapFeatureNotConnected),
        for (final location in locations)
          Text(
            location.displayName ??
                '${location.point.latitude}, ${location.point.longitude}',
          ),
        Text(l10n.mapLocationRetained),
      ],
    );
  }
}

final class _HazardMapSession {
  final ValueNotifier<HazardPageRequest?> viewport = ValueNotifier(null);
  final ValueNotifier<int> revision = ValueNotifier(0);
  final ValueNotifier<GeographicPoint?> focus = ValueNotifier(null);
}

List<ShellIntentBinding> hazardShellBindings(ShellRuntime Function() runtime) {
  return [
    ShellIntentBinding<OpenHazardComposerIntent>((
      OpenHazardComposerIntent intent,
    ) {
      return ShellRouteRequest.task(
        context: runtime().currentContext,
        destination: 'hazard-composer',
      );
    }),
    ShellIntentBinding<OpenHazardDetailIntent>((OpenHazardDetailIntent intent) {
      return ShellRouteRequest.task(
        context: runtime().currentContext,
        destination: 'hazard-detail',
      );
    }),
    ShellIntentBinding<OpenMyHazardsIntent>((OpenMyHazardsIntent intent) {
      return ShellRouteRequest.task(
        context: runtime().currentContext,
        destination: 'my-hazards',
      );
    }),
    ShellIntentBinding<ReturnToHazardMapIntent>((
      ReturnToHazardMapIntent intent,
    ) {
      return ShellRouteRequest.tab(
        context: runtime().currentContext,
        tab: ShellTab.map,
      );
    }),
  ];
}

List<ShellTaskView> _hazardTaskViews(
  HazardReportingRuntime hazards,
  ShellRuntime Function() runtime,
  _HazardMapSession Function() session,
) {
  void changed() {
    session().revision.value++;
  }

  void locate(HazardReport report, String returnContextId) {
    session().focus.value = report.location;
    runtime().submit(ReturnToHazardMapIntent(returnContextId));
  }

  Widget detail(HazardReportId id, String returnContextId) {
    return HazardDetailLoader(
      showHeading: false,
      hazards: hazards.reporting,
      id: id,
      onChanged: changed,
      onDeleted: () {
        runtime().back();
      },
      onLocate: (HazardReport report) {
        locate(report, returnContextId);
      },
    );
  }

  Widget composer(ValidLocationReference location, String returnContextId) {
    return HazardComposerPage(
      showHeading: false,
      hazards: hazards.reporting,
      location: location,
      request: (HazardType type, String title, String? description) {
        return HazardCreateRequest(
          location: location,
          type: type,
          title: title,
          description: description,
        );
      },
      onCreated: () {
        changed();
        runtime().back();
        runtime().submit(OpenMyHazardsIntent(returnContextId));
      },
    );
  }

  return [
    ShellTaskView<OpenHazardComposerIntent>(
      'hazard-composer',
      (BuildContext context, OpenHazardComposerIntent intent) {
        return composer(intent.location, intent.returnContextId);
      },
      title: (BuildContext context, OpenHazardComposerIntent intent) {
        return hazardPageTitle(context, HazardPageKind.composer);
      },
    ),
    ShellTaskView<OpenHazardDetailIntent>(
      'hazard-detail',
      (BuildContext context, OpenHazardDetailIntent intent) {
        return detail(intent.id, intent.returnContextId);
      },
      title: (BuildContext context, OpenHazardDetailIntent intent) {
        return hazardPageTitle(context, HazardPageKind.detail);
      },
    ),
    ShellTaskView<OpenMyHazardsIntent>(
      'my-hazards',
      (BuildContext context, OpenMyHazardsIntent intent) {
        return MyHazardsPage(
          showHeading: false,
          hazards: hazards.reporting,
          refreshSignal: session().revision,
          request: const HazardPageRequest(
            viewportVersion: 'mine',
            viewport: HazardViewport(
              GeographicPoint(latitude: -90, longitude: -180),
              GeographicPoint(latitude: 90, longitude: 180),
            ),
          ),
          onLocate: (HazardReport report) {
            locate(report, intent.returnContextId);
          },
          onOpen: (HazardReport report) {
            runtime().submit(
              OpenHazardDetailIntent(
                id: report.id,
                returnContextId: intent.returnContextId,
              ),
            );
          },
          onCreate: () {
            runtime().submit(ReturnToHazardMapIntent(intent.returnContextId));
          },
        );
      },
      title: (BuildContext context, OpenMyHazardsIntent intent) {
        return hazardPageTitle(context, HazardPageKind.mine);
      },
    ),
    ShellTaskView<OpenMapLayerIntent>(
      'hazard-map-intent',
      (BuildContext context, OpenMapLayerIntent intent) {
        final MapLayerIntent marker = intent.intent;
        if (marker is CreateHazardIntent) {
          return composer(marker.location, 'map');
        }
        if (marker is ProviderDefinedIntent &&
            marker.providerId == 'hazard-reporting' &&
            marker.action == 'detail') {
          return detail(HazardReportId(marker.stableItemId), 'map');
        }
        return const SizedBox();
      },
      title: (BuildContext context, OpenMapLayerIntent intent) {
        return hazardPageTitle(
          context,
          intent.intent is CreateHazardIntent
              ? HazardPageKind.composer
              : HazardPageKind.detail,
        );
      },
    ),
  ];
}

List<ShellIntentBinding> facilityShellBindings(
  ShellRuntime Function() runtime,
) {
  return <ShellIntentBinding>[
    ShellIntentBinding<OpenNearbyFacilitiesIntent>((
      OpenNearbyFacilitiesIntent intent,
    ) {
      return ShellRouteRequest.task(
        context: runtime().currentContext,
        destination: 'nearby-facilities',
      );
    }),
    ShellIntentBinding<OpenNearbyFacilitiesComparisonIntent>((
      OpenNearbyFacilitiesComparisonIntent intent,
    ) {
      return ShellRouteRequest.task(
        context: runtime().currentContext,
        destination: 'nearby-facilities-comparison',
      );
    }),
  ];
}

List<ShellContributionBinding> facilityShellContributions() {
  return <ShellContributionBinding>[
    ShellContributionBinding<NearbyFacilitiesSummaryContribution>((
      NearbyFacilitiesSummaryContribution input,
    ) {
      if (input.returnContext is! ShellRequestContext) {
        return const ShellSlotRequest.rejected(
          ShellRejectionReason.missingInput,
        );
      }
      return ShellSlotRequest(
        context: input.returnContext as ShellRequestContext,
        slot: 'nearby-facilities-summary',
      );
    }),
    ShellContributionBinding<NearbyFacilitiesComparisonContribution>((
      NearbyFacilitiesComparisonContribution input,
    ) {
      if (input.returnContext is! ShellRequestContext) {
        return const ShellSlotRequest.rejected(
          ShellRejectionReason.missingInput,
        );
      }
      return ShellSlotRequest(
        context: input.returnContext as ShellRequestContext,
        slot: 'nearby-facilities-comparison',
      );
    }),
  ];
}
