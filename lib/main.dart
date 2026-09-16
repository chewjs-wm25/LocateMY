import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'features/authentication_session/src/application/authentication_use_case.dart';
import 'features/authentication_session/src/data/supabase_authentication_session_adapter.dart';
import 'features/authentication_session/src/presentation/authentication_page.dart';
import 'features/authentication_session/src/presentation/authentication_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  try {
    SupabaseConfig.validate();
  } on StateError {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'LocateMY is not configured. Set the Supabase project URL and publishable key, then restart the app.',
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
      onRetryProfile: () =>
          viewModel.retryProfile(sessionAdapter.retryOptionalProfile),
    ),
  );
}

final class LocateMyApp extends StatelessWidget {
  final AuthenticationViewModel authenticationViewModel;
  final Future<void> Function()? onRetryProfile;

  const LocateMyApp({
    required this.authenticationViewModel,
    this.onRetryProfile,
    super.key,
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LocateMY',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
    ),
    home: AuthenticationPage(
      viewModel: authenticationViewModel,
      onSignOut: authenticationViewModel.signOut,
      onRetryProfile: onRetryProfile,
    ),
  );
}
