import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:locate_my/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:locate_my/core/app_theme.dart';
import 'package:locate_my/app/views/app_shell.dart';
import 'package:locate_my/app/navigation/app_router.dart';
import 'package:locate_my/app/view_models/locale_view_model.dart';
import 'package:locate_my/app/view_models/navigation_view_model.dart';
import 'package:locate_my/modules/module_a/module_a_providers.dart';
import 'package:locate_my/modules/module_b/module_b_providers.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locate_my/core/api_keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocaleViewModel()),
        ChangeNotifierProvider(create: (context) => NavigationViewModel()),
        ...moduleAProviders,
        ...moduleBProviders,
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeViewModel = Provider.of<LocaleViewModel>(context);

    return MaterialApp(
      title: 'UI 原型展示',
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.lightTheme,
      locale: localeViewModel.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleViewModel.supportedLocales
          .map((item) => item['locale'] as Locale)
          .toList(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const AppShell(),
    );
  }
}
