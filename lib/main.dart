import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/supabase_config.dart';
import 'l10n/app_localizations.dart';
import 'l10n/language_controller.dart';
import 'features/authentication_session/src/application/authentication_use_case.dart';
import 'features/authentication_session/src/data/supabase_authentication_session_adapter.dart';
import 'features/authentication_session/src/presentation/authentication_page.dart';
import 'features/authentication_session/src/presentation/authentication_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  final languageController = LanguageController(
    preferences: await SharedPreferences.getInstance(),
  );
  try {
    SupabaseConfig.validate();
  } on StateError {
    runApp(
      LanguageScope(
        controller: languageController,
        child: ListenableBuilder(
          listenable: languageController,
          builder: (context, _) => MaterialApp(
            locale: languageController.locale,
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

  final sessionAdapter = SupabaseAuthenticationSessionAdapter(
    Supabase.instance.client,
  );
  final viewModel = AuthenticationViewModel(
    AuthenticationUseCase(sessionAdapter),
  );
  runApp(
    LocateMyApp(
      authenticationViewModel: viewModel,
      languageController: languageController,
      onRetryProfile: () =>
          viewModel.retryProfile(sessionAdapter.retryOptionalProfile),
    ),
  );
}

final class LocateMyApp extends StatefulWidget {
  final LanguageController? languageController;
  final AuthenticationViewModel authenticationViewModel;
  final Future<void> Function()? onRetryProfile;

  const LocateMyApp({
    required this.authenticationViewModel,
    this.onRetryProfile,
    this.languageController,
    super.key,
  });

  @override
  State<LocateMyApp> createState() => _LocateMyAppState();
}

final class _LocateMyAppState extends State<LocateMyApp> {
  late final LanguageController _languageController =
      widget.languageController ?? LanguageController();

  @override
  void dispose() {
    if (widget.languageController == null) _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LanguageScope(
    controller: _languageController,
    child: ListenableBuilder(
      listenable: _languageController,
      builder: (context, _) => MaterialApp(
        locale: _languageController.locale,
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
        home: AuthenticationPage(
          viewModel: widget.authenticationViewModel,
          onSignOut: widget.authenticationViewModel.signOut,
          onRetryProfile: widget.onRetryProfile,
        ),
      ),
    ),
  );
}
