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
import 'location_summary.dart';
import '../l10n/language_controller.dart';
import '../l10n/app_localizations.dart';
import '../features/authentication_session/authentication_session.dart';
import '../features/account_center/account_center.dart';
import '../features/home_relocation_outlook/home_relocation_outlook.dart';
import '../features/map_location/map_location.dart';
import '../features/nearby_facilities/nearby_facilities.dart';
import '../features/hazard_reporting/hazard_reporting.dart';
import '../features/public_transportation/public_transportation.dart';
import '../features/crime_security/crime_security.dart';
import '../features/socio_economic/socio_economic.dart';
import '../features/infrastructure_coverage/infrastructure_coverage.dart';
import '../features/cost_of_living_budget/cost_of_living_budget.dart';
import '../features/property_inspection/property_inspection.dart';
import '../modules/geographic_context/geographic_context.dart';

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
                theme: _locateMyTheme(),
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

/// Shared presentation tokens mirrored from the LocateMY mobile prototype.
ThemeData _locateMyTheme() {
  const Color primary = Color(0xFF155EEF);
  const Color primarySoft = Color(0xFFEAF2FF);
  const Color ink = Color(0xFF172033);
  const Color muted = Color(0xFF667085);
  const Color canvas = Color(0xFFF6F8FB);
  const Color border = Color(0xFFD9E0EA);
  const Color danger = Color(0xFFC9362B);
  const BorderRadius cardRadius = BorderRadius.all(Radius.circular(14));
  const RoundedRectangleBorder controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  final TextTheme textTheme = ThemeData.light().textTheme
      .apply(fontFamily: 'SourceSansPro', bodyColor: ink, displayColor: ink)
      .copyWith(
        titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        titleSmall: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
        bodySmall: const TextStyle(fontSize: 13, height: 1.4, color: muted),
        labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primarySoft,
      onPrimaryContainer: primary,
      secondary: Color(0xFF16865C),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE8F6F0),
      onSecondaryContainer: Color(0xFF16865C),
      surface: Colors.white,
      onSurface: ink,
      surfaceContainerHighest: primarySoft,
      outline: border,
      error: danger,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: canvas,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'SourceSansPro',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      hintStyle: const TextStyle(fontSize: 15, color: muted),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: danger),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: danger, width: 2),
      ),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: controlShape,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: ink,
        side: const BorderSide(color: border),
        shape: controlShape,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 74,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      iconTheme: WidgetStatePropertyAll(IconThemeData(size: 22)),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: primarySoft,
      side: const BorderSide(color: border),
      shape: const RoundedRectangleBorder(borderRadius: cardRadius),
      labelStyle: const TextStyle(fontSize: 14, color: ink),
      secondaryLabelStyle: const TextStyle(fontSize: 14, color: primary),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      titleTextStyle: TextStyle(
        fontFamily: 'SourceSansPro',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      contentTextStyle: TextStyle(
        fontFamily: 'SourceSansPro',
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
    ),
  );
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
  late final CrimeSecurity _crime = createCrimeSecurity(
    geographicContext: createGeographicContext(widget.client),
    reader: SupabaseSafetyInputsReader(widget.client),
    database: widget.database,
  );
  late final BudgetScenarioStore _budget = createBudgetScenarioStore(
    client: widget.client,
  );
  late final CurrentBudgetReader _currentBudget =
      createSupabaseCurrentBudgetReader(widget.client);
  late final CostOfLivingBudget _cost = createCostOfLivingBudget(
    geographicContext: createGeographicContext(widget.client),
    reader: SupabaseCostPublicReader(widget.client),
    budget: _currentBudget,
    database: widget.database,
  );
  late final SocioEconomic _socio = createSocioEconomic(
    geographicContext: createGeographicContext(widget.client),
    reader: SupabaseSocioInputsReader(widget.client),
    budget: _currentBudget,
    database: widget.database,
  );
  late final InfrastructureService _infrastructure =
      createInfrastructureCoverage(
        geographicContext: createGeographicContext(widget.client),
        reader: SupabaseInfrastructureInputsReader(widget.client),
        transportation: widget.transportation,
        weightsStore: SupabaseInfrastructureWeightsStore(widget.client),
        database: widget.database,
      );
  late final PropertyInspectionService _property = PropertyInspectionService(
    store: SupabasePropertyStore(widget.client),
    risk: PropertyBusinessRiskReader(
      geo: createGeographicContext(widget.client),
      crime: _crime,
      hazards: createHazardRiskCounter(
        store: createSupabaseHazardStore(widget.client),
        currentAccountId: () {
          return widget.client.auth.currentUser?.id;
        },
      ),
    ),
  );
  late final PropertyPhotoPicker _photoPicker = DevicePropertyPhotoPicker();
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
      crime: _crime,
      socio: _socio,
      infrastructure: _infrastructure,
      cost: _cost,
      budgetStore: _budget,
      currentBudget: _currentBudget,
      property: _property,
      photoPicker: _photoPicker,
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
  final CrimeSecurity? crime;
  final SocioEconomic? socio;
  final InfrastructureService? infrastructure;
  final CostOfLivingBudget? cost;
  final BudgetScenarioStore? budgetStore;
  final CurrentBudgetReader? currentBudget;
  final PropertyInspectionService? property;
  final PropertyPhotoPicker? photoPicker;
  final Future<ValidLocationReference?> Function(BuildContext)?
  choosePropertyLocation;
  final bool showTiles;
  const LocateMyPages({
    required LocationCoordinator locations,
    required HazardReporting hazards,
    required NearbyFacilities facilities,
    required HomeRelocationOutlook home,
    required LocationSearch search,
    required PublicTransportation transportation,
    CrimeSecurity? crime,
    SocioEconomic? socio,
    InfrastructureService? infrastructure,
    CostOfLivingBudget? cost,
    BudgetScenarioStore? budgetStore,
    CurrentBudgetReader? currentBudget,
    PropertyInspectionService? property,
    PropertyPhotoPicker? photoPicker,
    Future<ValidLocationReference?> Function(BuildContext)?
    choosePropertyLocation,
    bool showTiles = true,
    super.key,
  }) : locations = locations,
       hazards = hazards,
       facilities = facilities,
       home = home,
       search = search,
       transportation = transportation,
       crime = crime,
       socio = socio,
       infrastructure = infrastructure,
       cost = cost,
       budgetStore = budgetStore,
       currentBudget = currentBudget,
       property = property,
       photoPicker = photoPicker,
       choosePropertyLocation = choosePropertyLocation,
       showTiles = showTiles;
  @override
  State<LocateMyPages> createState() {
    return _LocateMyPagesState();
  }
}

final class _LocateMyPagesState extends State<LocateMyPages> {
  GeographicPoint? _hazardCenter;
  HazardPageRequest? _lastMapViewport;
  final ValueNotifier<HazardPageRequest?> _viewport = ValueNotifier(null);
  final ValueNotifier<String?> _facilityViewport = ValueNotifier(null);
  final ValueNotifier<int> _revision = ValueNotifier(0);
  final ValueNotifier<GeographicPoint?> _focus = ValueNotifier(null);
  int _tab = 0;
  bool _choosingHazard = false;
  int _mapReturnVersion = 0;
  String _text(String en, String zh) {
    if (Localizations.localeOf(context).languageCode == 'zh') {
      return zh;
    }
    return en;
  }

  late final LocationSummaryReader _summary = BusinessLocationSummaryReader(
    crime: widget.crime,
    cost: widget.cost,
    facilities: widget.facilities,
    transportation: widget.transportation,
    infrastructure: widget.infrastructure,
  );

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

  Future<void> _showCrimeLocation(ValidLocationReference location) async {
    final LocationSelectionOutcome selected = await widget.locations.select(
      LocationSelectionRequest(
        role: LocationRole.single,
        point: location.point,
        displayName: location.displayName,
      ),
    );
    if (!mounted) {
      return;
    }
    if (selected is! LocationSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Unable to select this location. Try again.',
              '暂无法选择该地点，请重试。',
            ),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).popUntil((Route<dynamic> route) {
      return route.isFirst;
    });
    setState(() {
      _tab = 1;
      _mapReturnVersion++;
      _focus.value = location.point;
    });
  }

  Future<ValidLocationReference?> _choosePropertyLocation(
    BuildContext context,
  ) {
    return Navigator.of(context).push<ValidLocationReference>(
      MaterialPageRoute<ValidLocationReference>(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_text('Choose property location', '选择实勘地点')),
            ),
            body: MapLocationPage(
              locations: widget.locations,
              layerHost: locationLayerHost(widget.locations),
              workspace: locationWorkspace(widget.locations),
              search: widget.search,
              showTiles: widget.showTiles,
              onAnalysis: (ValidLocationReference location) {
                Navigator.pop(context, location);
              },
              onComparison: (
                ValidLocationReference a,
                ValidLocationReference b,
              ) {},
              onLayerSelected: (MapLayerIntent intent) {},
              detailAction: StreamBuilder<void>(
                stream: locationWorkspace(widget.locations).changes,
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  final LocationRoleSnapshot selected = widget.locations.read(
                    LocationRole.single,
                  );
                  return FilledButton(
                    onPressed: selected is LocationPresent
                        ? () {
                            Navigator.pop(context, selected.location);
                          }
                        : null,
                    child: Text(_text('Use selected location', '使用所选地点')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _analysis(ValidLocationReference a, [ValidLocationReference? b]) {
    _push(
      LocationAnalysisMenu(
        location: a,
        locationB: b,
        facilities: widget.facilities,
        transportation: widget.transportation,
        crime: widget.crime,
        socio: widget.socio,
        infrastructure: widget.infrastructure,
        cost: widget.cost,
        budgetStore: widget.budgetStore,
        currentBudget: widget.currentBudget,
        property: widget.property,
        photoPicker: widget.photoPicker,
        choosePropertyLocation: _choosePropertyLocation,
        onShowMap: _showCrimeLocation,
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
      key: ValueKey<int>(_mapReturnVersion),
      locations: widget.locations,
      layerHost: locationLayerHost(widget.locations),
      workspace: locationWorkspace(widget.locations),
      search: widget.search,
      showTiles: widget.showTiles,
      layerFocus: _focus,
      summaryReader: _summary,

      onAnalysis: _analysis,
      onComparison: (ValidLocationReference a, ValidLocationReference b) {
        _analysis(a, b);
      },
      onLayerSelected: _layer,
      onLayerLocation: (GeographicPoint? point) {
        if (point?.latitude == _hazardCenter?.latitude &&
            point?.longitude == _hazardCenter?.longitude) {
          return;
        }
        _hazardCenter = point;
        final HazardPageRequest? previous = _lastMapViewport;
        if (point == null) {
          _viewport.value = null;
        } else if (previous != null) {
          _viewport.value = HazardPageRequest(
            viewportVersion: previous.viewportVersion,
            viewport: previous.viewport,
            mapCenter: point,
          );
        }
      },
      onViewport: (String version, GeographicPoint sw, GeographicPoint ne) {
        _lastMapViewport = HazardPageRequest(
          viewportVersion: version,
          viewport: HazardViewport(sw, ne),
          mapCenter: _hazardCenter,
        );
        _viewport.value = _hazardCenter == null ? null : _lastMapViewport;
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
                  AccountCenterPage(
                    authentication: InheritedAuthentication.of(context),
                    currentBudget: widget.currentBudget,
                    budgetStore: widget.budgetStore,
                    onMyHazards: _mine,
                    onPropertyPortfolio: widget.property == null
                        ? null
                        : () {
                            _push(
                              PropertyInspectionPortfolioPage(
                                service: widget.property!,
                                photoPicker: widget.photoPicker,
                                chooseLocation: _choosePropertyLocation,
                              ),
                            );
                          },
                  ),
                  _text('Account settings', '账号设置'),
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
  final CrimeSecurity? crime;
  final SocioEconomic? socio;
  final InfrastructureService? infrastructure;
  final CostOfLivingBudget? cost;
  final BudgetScenarioStore? budgetStore;
  final CurrentBudgetReader? currentBudget;
  final PropertyInspectionService? property;
  final PropertyPhotoPicker? photoPicker;
  final Future<ValidLocationReference?> Function(BuildContext)?
  choosePropertyLocation;
  final void Function(ValidLocationReference)? onShowMap;
  const LocationAnalysisMenu({
    required ValidLocationReference location,
    ValidLocationReference? locationB,
    required NearbyFacilities facilities,
    required PublicTransportation transportation,
    CrimeSecurity? crime,
    SocioEconomic? socio,
    InfrastructureService? infrastructure,
    CostOfLivingBudget? cost,
    BudgetScenarioStore? budgetStore,
    CurrentBudgetReader? currentBudget,
    PropertyInspectionService? property,
    PropertyPhotoPicker? photoPicker,
    Future<ValidLocationReference?> Function(BuildContext)?
    choosePropertyLocation,
    void Function(ValidLocationReference)? onShowMap,
    super.key,
  }) : location = location,
       locationB = locationB,
       facilities = facilities,
       transportation = transportation,
       crime = crime,
       socio = socio,
       infrastructure = infrastructure,
       cost = cost,
       budgetStore = budgetStore,
       currentBudget = currentBudget,
       property = property,
       photoPicker = photoPicker,
       choosePropertyLocation = choosePropertyLocation,
       onShowMap = onShowMap;
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

    final List<Widget> cards = <Widget>[
      _AnalysisCategoryCard(
        title: zh ? '生活成本' : 'Cost of living',
        description: zh
            ? '生活成本指数与估算月支出'
            : 'Cost index and estimated monthly spending',
        accent: const Color(0xFFB76E00),
        icon: Icons.account_balance_wallet_outlined,
        onTap: cost == null
            ? null
            : () {
                open(
                  CostBudgetPage(
                    location: location,
                    locationB: second,
                    service: cost!,
                    budgetStore: budgetStore,
                    currentBudget: currentBudget,
                  ),
                );
              },
      ),
      _AnalysisCategoryCard(
        title: zh ? '治安与犯罪' : 'Crime and security',
        description: zh ? '州级安全指数与犯罪趋势' : 'State safety index and crime trends',
        accent: const Color(0xFF16865C),
        icon: Icons.shield_outlined,
        onTap: crime == null
            ? null
            : () {
                open(
                  CrimeSecurityPage(
                    crime: crime!,
                    location: location,
                    locationB: second,
                    onShowMap: onShowMap,
                    onPortfolio: property == null
                        ? null
                        : () {
                            open(
                              PropertyInspectionPortfolioPage(
                                service: property!,
                                photoPicker: photoPicker,
                                chooseLocation: choosePropertyLocation,
                              ),
                            );
                          },
                    onAddProperty: property == null
                        ? null
                        : (ValidLocationReference point) {
                            open(
                              PropertyInspectionFormPage(
                                service: property!,
                                photoPicker: photoPicker,
                                chooseLocation: choosePropertyLocation,
                                location: point,
                              ),
                            );
                          },
                  ),
                );
              },
      ),
      _AnalysisCategoryCard(
        title: zh ? '社会经济' : 'Socio-economic',
        description: zh
            ? '家庭收入与收入分布'
            : 'Household income and income distribution',
        accent: const Color(0xFF155EEF),
        icon: Icons.people_outline,
        onTap: socio == null
            ? null
            : () {
                open(
                  SocioEconomicPage(
                    socio: socio!,
                    location: location,
                    locationB: second,
                  ),
                );
              },
      ),
      _AnalysisCategoryCard(
        title: zh ? '基础设施' : 'Infrastructure',
        description: zh
            ? '供水、供电与公共服务覆盖'
            : 'Water, electricity and public service coverage',
        accent: const Color(0xFF16865C),
        icon: Icons.apartment_outlined,
        onTap: infrastructure == null
            ? null
            : () {
                open(
                  InfrastructureCoveragePage(
                    service: infrastructure!,
                    location: location,
                    locationB: second,
                    analysisDate: date,
                  ),
                );
              },
      ),
      _AnalysisCategoryCard(
        title: zh ? '周边设施' : 'Nearby facilities',
        description: zh ? '2 km 范围内已收录设施' : 'Recorded facilities within 2 km',
        accent: const Color(0xFF1E8A7A),
        icon: Icons.local_hospital_outlined,
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
      _AnalysisCategoryCard(
        title: zh ? '公共交通' : 'Public transportation',
        description: zh
            ? '1.5 km 站点与交通连通性'
            : 'Stops within 1.5 km and transit connectivity',
        accent: const Color(0xFF155EEF),
        icon: Icons.directions_transit_outlined,
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
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FB),
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF172033),
        title: Text(
          second == null
              ? (zh ? '地点分析' : 'Location analysis')
              : (zh ? '地点比较' : 'Location comparison'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: const [LanguageButton()],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _locationHeading(location, second == null ? null : 'A'),
                  if (second != null) ...<Widget>[
                    const SizedBox(height: 16),
                    _locationHeading(second, 'B'),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1F44),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          zh
                              ? '从六个角度了解地点'
                              : 'Explore six aspects of a location',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          zh ? '选择下方类别，查看详细数据与覆盖情况。' : 'Choose a category below to explore detailed data and coverage.',
                          style: const TextStyle(
                            color: Color(0xFFC8D7F2),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    zh ? '六类地区分析' : 'Regional analysis',
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final bool twoColumns =
                              constraints.maxWidth >= 328 &&
                              MediaQuery.textScalerOf(context).scale(16) <= 20;
                          final List<Widget> rows = <Widget>[];
                          final int columns = twoColumns ? 2 : 1;
                          for (
                            int index = 0;
                            index < cards.length;
                            index += columns
                          ) {
                            if (index > 0) {
                              rows.add(const SizedBox(height: 16));
                            }
                            if (twoColumns) {
                              rows.add(
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Expanded(child: cards[index]),
                                      const SizedBox(width: 16),
                                      Expanded(child: cards[index + 1]),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              rows.add(cards[index]);
                            }
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: rows,
                          );
                        },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      zh ? '各类分析分别展示统计或覆盖情况，不合并为地点总分。' : 'Each category presents its own statistics or coverage, without a combined location score.',
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationHeading(ValidLocationReference point, String? role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (role != null)
          Text(
            role,
            style: const TextStyle(
              color: Color(0xFF155EEF),
              fontWeight: FontWeight.w700,
            ),
          ),
        Text(
          point.displayName ??
              '${point.point.latitude}, ${point.point.longitude}',
          style: const TextStyle(
            color: Color(0xFF172033),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

final class _AnalysisCategoryCard extends StatelessWidget {
  final String title;
  final String description;
  final Color accent;
  final IconData icon;
  final VoidCallback? onTap;

  const _AnalysisCategoryCard({
    required String title,
    required String description,
    required Color accent,
    required IconData icon,
    VoidCallback? onTap,
  }) : title = title,
       description = description,
       accent = accent,
       icon = icon,
       onTap = onTap;

  @override
  Widget build(BuildContext context) {
    final bool zh = Localizations.localeOf(context).languageCode == 'zh';
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD9E0EA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(width: 5, child: ColoredBox(color: accent)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(icon, color: accent, size: 22),
                          const Spacer(),
                          if (onTap != null)
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF667085),
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF172033),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      if (onTap == null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          zh ? '尚未实现' : 'Not implemented yet',
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
