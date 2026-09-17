// Explicit constructor initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';
import '../l10n/language_controller.dart';
import '../l10n/app_localizations.dart';
import '../features/authentication_session/authentication_session.dart';
import '../features/home_relocation_outlook/home_relocation_outlook.dart';
import '../features/map_location/map_location.dart';
import '../features/nearby_facilities/nearby_facilities.dart';
import '../features/hazard_reporting/hazard_reporting.dart';
import '../features/public_transportation/public_transportation.dart';

Future<void> startLocateMy() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  final LanguageController language = LanguageController(
    preferences: await SharedPreferences.getInstance(),
  );
  try {
    SupabaseConfig.validate();
  } on StateError {
    runApp(
      ChangeNotifierProvider.value(
        value: language,
        child: Builder(
          builder: (BuildContext context) {
            return MaterialApp(
              locale: context.watch<LanguageController>().locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (BuildContext context) {
                  return Scaffold(
                    appBar: AppBar(actions: const [LanguageButton()]),
                    body: Center(
                      child: Text(
                        AppLocalizations.of(context)!.configurationMissing,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
    return;
  }
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  final SupabaseClient client = Supabase.instance.client;
  final AuthenticationSession authentication = createAuthenticationSession(
    client,
  );
  final Database database = await openDatabase(
    '${await getDatabasesPath()}/locatemy-map-private.db',
  );
  // One-time removal of the obsolete private cache. Public facility data stays.
  await database.execute('DROP TABLE IF EXISTS map_saved_records');
  final LocationSearch search = createLocationSearch(
    apiKey: const String.fromEnvironment('GEOAPIFY_API_KEY').isNotEmpty
        ? const String.fromEnvironment('GEOAPIFY_API_KEY')
        : dotenv.env['GEOAPIFY_API_KEY'] ?? '',
  );
  final PublicTransportation transportation = createPublicTransportation(
    SupabaseTransitReader(client),
  );
  runApp(
    LocateMyApp(
      authenticationViewModel: createAuthenticationViewModel(authentication),
      languageController: language,
      signedInBuilder: (BuildContext context, AuthenticatedAccount account) {
        return _ProductionPages(
          client: client,
          database: database,
          search: search,
          transportation: transportation,
          account: account,
        );
      },
    ),
  );
}

/// Page entry seam used by the app and its existing Widget test harness.
final class LocateMyApp extends StatefulWidget {
  final LanguageController? languageController;
  final AuthenticationViewModel authenticationViewModel;
  final Widget Function(BuildContext, AuthenticatedAccount)? signedInBuilder;
  const LocateMyApp({
    required AuthenticationViewModel authenticationViewModel,
    LanguageController? languageController,
    Widget Function(BuildContext, AuthenticatedAccount)? signedInBuilder,
    super.key,
  }) : authenticationViewModel = authenticationViewModel,
       languageController = languageController,
       signedInBuilder = signedInBuilder;
  @override
  State<LocateMyApp> createState() {
    return _LocateMyAppState();
  }
}

final class _LocateMyAppState extends State<LocateMyApp> {
  late final LanguageController _language =
      widget.languageController ?? LanguageController();
  @override
  void initState() {
    super.initState();
    widget.authenticationViewModel.initialize();
  }

  @override
  void dispose() {
    if (widget.languageController == null) {
      _language.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _language,
      child: AnimatedBuilder(
        animation: widget.authenticationViewModel,
        builder: (BuildContext context, Widget? child) {
          return Builder(
            builder: (BuildContext context) {
              final SessionSnapshot? identity =
                  widget.authenticationViewModel.state.session;
              final String accountKey = identity is AuthenticatedSession
                  ? identity.account.accountId
                  : 'signed-out';
              return MaterialApp(
                key: ValueKey(accountKey),
                locale: context.watch<LanguageController>().locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                title: 'LocateMY',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  colorScheme:
                      ColorScheme.fromSeed(seedColor: const Color(0xFF155EEF))
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
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF667085),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD9E0EA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF155EEF),
                        width: 2,
                      ),
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
                home: AnimatedBuilder(
                  animation: widget.authenticationViewModel,
                  builder: (BuildContext context, Widget? child) {
                    final SessionSnapshot? session =
                        widget.authenticationViewModel.state.session;
                    if (session is AuthenticatedSession &&
                        widget.signedInBuilder != null) {
                      // The account-keyed MaterialApp owns the ordinary route stack.
                      return InheritedAuthentication(
                        viewModel: widget.authenticationViewModel,
                        child: widget.signedInBuilder!(
                          context,
                          session.account,
                        ),
                      );
                    }
                    return AuthenticationPage(
                      viewModel: widget.authenticationViewModel,
                      onSignOut: widget.authenticationViewModel.signOut,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class InheritedAuthentication extends InheritedWidget {
  final AuthenticationViewModel viewModel;
  const InheritedAuthentication({
    required AuthenticationViewModel viewModel,
    required super.child,
    super.key,
  }) : viewModel = viewModel;
  static AuthenticationViewModel of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedAuthentication>()!
        .viewModel;
  }

  @override
  bool updateShouldNotify(InheritedAuthentication oldWidget) {
    return viewModel != oldWidget.viewModel;
  }
}

final class _ProductionPages extends StatefulWidget {
  final SupabaseClient client;
  final Database database;
  final LocationSearch search;
  final PublicTransportation transportation;
  final AuthenticatedAccount account;
  const _ProductionPages({
    required SupabaseClient client,
    required Database database,
    required LocationSearch search,
    required PublicTransportation transportation,
    required AuthenticatedAccount account,
  }) : client = client,
       database = database,
       search = search,
       transportation = transportation,
       account = account;
  @override
  State<_ProductionPages> createState() {
    return _ProductionPagesState();
  }
}

final class _ProductionPagesState extends State<_ProductionPages> {
  late final MapLocationRuntime _map = MapLocationRuntime(
    accountId: widget.account.accountId,
    validatePoint: (GeographicPoint point) {
      return validateLocationInMalaysia(widget.client, point);
    },
    storageForAccount: (String accountId) {
      return createLocationStorage(client: widget.client, accountId: accountId);
    },
  );
  late final HazardReportingRuntime _hazards = HazardReportingRuntime(
    store: createSupabaseHazardStore(widget.client),
    currentAccountId: () {
      return widget.client.auth.currentUser?.id;
    },
  );
  late final http.Client _http = http.Client();
  late final NearbyFacilities _facilities = createNearbyFacilities(
    source: createOverpassFacilitySource(_http),
    database: widget.database,
    mapLayerHost: () {
      return locationLayerHost(_map.locations);
    },
  );
  late final HomeRelocationOutlook _home = createHomeRelocationOutlook(
    widget.client,
  );
  @override
  void dispose() {
    _http.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocateMyPages(
      locations: _map.locations,
      hazards: _hazards.reporting,
      facilities: _facilities,
      home: _home,
      search: widget.search,
      transportation: widget.transportation,
    );
  }
}

/// Signed-in production pages composed from the existing business services.
final class LocateMyPages extends StatefulWidget {
  final LocationCoordinator locations;
  final HazardReporting hazards;
  final NearbyFacilities facilities;
  final HomeRelocationOutlook home;
  final LocationSearch search;
  final PublicTransportation transportation;
  final bool showTiles;
  const LocateMyPages({
    required LocationCoordinator locations,
    required HazardReporting hazards,
    required NearbyFacilities facilities,
    required HomeRelocationOutlook home,
    required LocationSearch search,
    required PublicTransportation transportation,
    bool showTiles = true,
    super.key,
  }) : locations = locations,
       hazards = hazards,
       facilities = facilities,
       home = home,
       search = search,
       transportation = transportation,
       showTiles = showTiles;
  @override
  State<LocateMyPages> createState() {
    return _LocateMyPagesState();
  }
}

final class _LocateMyPagesState extends State<LocateMyPages> {
  final ValueNotifier<HazardPageRequest?> _viewport = ValueNotifier(null);
  final ValueNotifier<String?> _facilityViewport = ValueNotifier(null);
  final ValueNotifier<int> _revision = ValueNotifier(0);
  final ValueNotifier<GeographicPoint?> _focus = ValueNotifier(null);
  int _tab = 0;
  bool _choosingHazard = false;
  String _text(String en, String zh) {
    if (Localizations.localeOf(context).languageCode == 'zh') {
      return zh;
    }
    return en;
  }

  void _changed() {
    _revision.value++;
  }

  void _push(Widget page, [String? title]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          if (title == null) {
            return page;
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: const [LanguageButton()],
            ),
            body: page,
          );
        },
      ),
    );
  }

  void _locate(HazardReport report) {
    _focus.value = report.location;
    Navigator.of(context).popUntil((Route<dynamic> route) {
      return route.isFirst;
    });
    setState(() {
      _tab = 1;
    });
  }

  void _detail(HazardReportId id) {
    _push(
      HazardDetailLoader(
        showHeading: false,
        hazards: widget.hazards,
        id: id,
        onChanged: _changed,
        onDeleted: () {
          Navigator.of(context).pop();
        },
        onLocate: _locate,
      ),
      _text('Hazard details', '隐患详情'),
    );
  }

  void _composer(ValidLocationReference location) {
    setState(() {
      _choosingHazard = false;
    });
    _push(
      HazardComposerPage(
        showHeading: false,
        hazards: widget.hazards,
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
          _changed();
          Navigator.of(context).pop();
          _mine();
        },
      ),
      _text('Report hazard', '上报隐患'),
    );
  }

  void _mine() {
    _push(
      MyHazardsPage(
        showHeading: false,
        hazards: widget.hazards,
        request: const HazardPageRequest(
          viewportVersion: 'mine',
          viewport: HazardViewport(
            GeographicPoint(latitude: -90, longitude: -180),
            GeographicPoint(latitude: 90, longitude: 180),
          ),
        ),
        onOpen: (HazardReport report) {
          _detail(report.id);
        },
        onLocate: _locate,
        onCreate: () {
          Navigator.of(context).popUntil((Route<dynamic> route) {
            return route.isFirst;
          });
          setState(() {
            _tab = 1;
            _choosingHazard = true;
          });
        },
      ),
      _text('My hazards', '我的隐患'),
    );
  }

  void _layer(MapLayerIntent intent) {
    if (intent is CreateHazardIntent) {
      _composer(intent.location);
    }
    if (intent is ProviderDefinedIntent &&
        intent.providerId == 'hazard-reporting' &&
        intent.action == 'detail') {
      _detail(HazardReportId(intent.stableItemId));
    }
  }

  void _analysis(ValidLocationReference a, [ValidLocationReference? b]) {
    _push(
      LocationAnalysisMenu(
        location: a,
        locationB: b,
        facilities: widget.facilities,
        transportation: widget.transportation,
      ),
    );
  }

  @override
  void dispose() {
    _viewport.dispose();
    _facilityViewport.dispose();
    _revision.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final Widget map = MapLocationPage(
      locations: widget.locations,
      layerHost: locationLayerHost(widget.locations),
      workspace: locationWorkspace(widget.locations),
      search: widget.search,
      showTiles: widget.showTiles,
      layerFocus: _focus,
      onAnalysis: _analysis,
      onComparison: (ValidLocationReference a, ValidLocationReference b) {
        _analysis(a, b);
      },
      onLayerSelected: _layer,
      onViewport: (String version, GeographicPoint sw, GeographicPoint ne) {
        _viewport.value = HazardPageRequest(
          viewportVersion: version,
          viewport: HazardViewport(sw, ne),
        );
        _facilityViewport.value = version;
      },
      detailAction: StreamBuilder<void>(
        stream: locationWorkspace(widget.locations).changes,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          final LocationRoleSnapshot selected = widget.locations.read(
            LocationRole.single,
          );
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                if (_choosingHazard)
                  Text(_text('Choose a location, then confirm.', '选择位置后确认。')),
                FilledButton.tonalIcon(
                  key: ValueKey(
                    _choosingHazard
                        ? 'hazard-confirm-location'
                        : 'hazard-start-report',
                  ),
                  onPressed: _choosingHazard
                      ? selected is LocationPresent
                            ? () {
                                _composer(selected.location);
                              }
                            : null
                      : () {
                          setState(() {
                            _choosingHazard = true;
                          });
                        },
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: Text(
                    _text(
                      _choosingHazard
                          ? 'Report at this location'
                          : 'Report hazard',
                      _choosingHazard ? '在此位置上报' : '上报隐患',
                    ),
                  ),
                ),
                if (_choosingHazard)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _choosingHazard = false;
                      });
                    },
                    child: Text(l.cancel),
                  ),
              ],
            ),
          );
        },
      ),
    );
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          setState(() {
            _tab = 0;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tab == 0 ? 'LocateMY' : l.shellMap),
          actions: [
            const LanguageButton(),
            TextButton(
              key: const ValueKey('shell-account'),
              onPressed: () {
                _push(
                  AuthenticationPage(
                    viewModel: InheritedAuthentication.of(context),
                    onSignOut: InheritedAuthentication.of(context).signOut,
                  ),
                );
              },
              child: Text(l.shellAccount),
            ),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          children: [
            HomeOutlookPage(
              home: widget.home,
              onExploreMap: () {
                setState(() {
                  _tab = 1;
                });
              },
            ),
            Column(
              children: [
                Expanded(
                  child: HazardMapPanel(
                    hazards: widget.hazards,
                    host: locationLayerHost(widget.locations),
                    viewport: _viewport,
                    revision: _revision,
                    onMine: _mine,
                    child: NearbyFacilitiesMapPanel(
                      facilities: widget.facilities,
                      locations: widget.locations,
                      workspace: locationWorkspace(widget.locations),
                      viewport: _facilityViewport,
                      child: map,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (int tab) {
            setState(() {
              _tab = tab;
            });
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              label: l.shellHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              label: l.shellMap,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ordinary routes carry validated coordinates; pending analyses stay explicit.
final class LocationAnalysisMenu extends StatelessWidget {
  final ValidLocationReference location;
  final ValidLocationReference? locationB;
  final NearbyFacilities facilities;
  final PublicTransportation transportation;
  const LocationAnalysisMenu({
    required ValidLocationReference location,
    ValidLocationReference? locationB,
    required NearbyFacilities facilities,
    required PublicTransportation transportation,
    super.key,
  }) : location = location,
       locationB = locationB,
       facilities = facilities,
       transportation = transportation;
  @override
  Widget build(BuildContext context) {
    final bool zh = Localizations.localeOf(context).languageCode == 'zh';
    final ValidLocationReference? second = locationB;
    final DateTime date = DateTime.now();
    void open(Widget page) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return page;
          },
        ),
      );
    }

    AnalysisReturnContext input(
      ValidLocationReference point,
      LocationRole role,
    ) {
      return AnalysisReturnContext(
        location: point,
        role: role,
        analysisDate: date,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(zh ? '地点分析' : 'Location analysis'),
        actions: const [LanguageButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            location.displayName ??
                '${location.point.latitude}, ${location.point.longitude}',
          ),
          if (second != null)
            Text(
              second.displayName ??
                  '${second.point.latitude}, ${second.point.longitude}',
            ),
          ListTile(
            title: Text(zh ? '周边设施' : 'Nearby facilities'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              open(
                NearbyFacilitiesPage(
                  facilities: facilities,
                  location: location,
                  locationB: second,
                ),
              );
            },
          ),
          ListTile(
            title: Text(zh ? '公共交通' : 'Public transportation'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (second == null) {
                open(
                  PublicTransportationPage(
                    transportation: transportation,
                    location: location,
                    analysisDate: date,
                  ),
                );
              } else {
                open(
                  PublicTransportationComparisonPage(
                    transportation: transportation,
                    a: input(location, LocationRole.locationA),
                    b: input(second, LocationRole.locationB),
                    onOpenStations: (AnalysisReturnContext selected) {
                      open(
                        PublicTransportationPage(
                          transportation: transportation,
                          location: selected.location,
                          analysisDate: selected.analysisDate,
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
          for (final String name
              in zh
                  ? ['生活成本', '治安', '社会经济', '基础设施']
                  : [
                      'Cost of living',
                      'Crime and security',
                      'Socio-economic',
                      'Infrastructure',
                    ])
            ListTile(
              title: Text(name),
              subtitle: Text(zh ? '尚未实现' : 'Not implemented yet'),
            ),
        ],
      ),
    );
  }
}
