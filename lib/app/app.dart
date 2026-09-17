// Explicit parameter types and initialization follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

export 'src/presentation/shell_host.dart'
    show ShellViews, ShellTaskView, ShellContributionView;
export 'src/domain/shell_routes.dart';
export 'src/application/shell_runtime.dart';
export 'src/domain/shell_state.dart';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import 'src/application/shell_runtime.dart';
import 'src/domain/shell_routes.dart';
import 'src/domain/shell_state.dart';
import '../features/home_relocation_outlook/home_relocation_outlook.dart';
import '../features/map_location/map_location.dart';

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
  shell = ShellRuntime.compose(
    authentication: sessionAdapter,
    privacy: () => privacy,
    intents: [
      homeExploreMapBinding(() => shell),
      ...mapShellBindings(() => shell),
    ],
  );
  privacy = createAccountPrivacy(
    authenticationSession: sessionAdapter,
    participants: [
      createAuthenticationPrivacyParticipant(sessionAdapter),
      shell,
      mapRuntime,
    ],
    // Only these owners can create private state in the current app. Add each
    // future feature here when wiring its views/storage, even if its participant
    // is missing, so a registration defect still blocks logout.
    requiredParticipants: const {
      AccountPrivacyParticipantId.authenticationSession,
      AccountPrivacyParticipantId.applicationShell,
      AccountPrivacyParticipantId.mapLocation,
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
        createLocationSearch(
          apiKey: const String.fromEnvironment('GEOAPIFY_API_KEY').isNotEmpty
              ? const String.fromEnvironment('GEOAPIFY_API_KEY')
              : dotenv.env['GEOAPIFY_API_KEY'] ?? '',
        ),
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
        destination: 'map-layer',
      ),
    ),
  ];
}

ShellViews mapAndHomeShellViews(
  HomeRelocationOutlook Function() createHome,
  MapLocationRuntime map,
  LocationSearch search,
) {
  final ShellViews home = homeShellViews(createHome);
  return ShellViews(
    home: home.home,
    map: (context, shell) => MapLocationPage(
      locations: map.locations,
      layerHost: locationLayerHost(map.locations),
      workspace: locationWorkspace(map.locations),
      applicationShell: shell,
      search: search,
    ),
    tasks: [
      ShellTaskView<OpenAnalysisIntent>(
        'location-analysis',
        (c, i) => MapFutureDestination(locations: [i.location]),
      ),
      ShellTaskView<OpenLocationComparisonIntent>(
        'location-comparison',
        (c, i) => MapFutureDestination(locations: [i.locationA, i.locationB]),
      ),
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
