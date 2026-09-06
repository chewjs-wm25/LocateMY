import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'views/app_shell.dart';
import 'providers/locale_provider.dart';

import 'providers/location_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/hazard_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/property_provider.dart';
import 'providers/nearby_facilities_provider.dart';
import 'providers/analysis/security_provider.dart';
import 'providers/analysis/infrastructure_provider.dart';
import 'providers/analysis/socio_economic_provider.dart';
import 'providers/analysis/transit_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/api_keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ChangeNotifierProvider(create: (context) => LocationProvider()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider(create: (context) => HazardProvider()),
        ChangeNotifierProvider(create: (context) => BudgetProvider()),
        ChangeNotifierProvider(create: (context) => PropertyProvider()),
        ChangeNotifierProvider(create: (context) => NearbyFacilitiesProvider()),
        ChangeNotifierProvider(create: (context) => SecurityProvider()),
        ChangeNotifierProvider(create: (context) => InfrastructureProvider()),
        ChangeNotifierProvider(create: (context) => SocioEconomicProvider()),
        ChangeNotifierProvider(create: (context) => TransitProvider()),
        ChangeNotifierProvider(create: (context) => HomeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'UI 原型展示',
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.lightTheme,
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleProvider.supportedLocales
          .map((item) => item['locale'] as Locale)
          .toList(),
      home: const AppShell(),
    );
  }
}
