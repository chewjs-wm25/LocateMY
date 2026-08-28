import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LocateMyApp());
}

class LocateMyApp extends StatelessWidget {
  const LocateMyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocateMY - Malaysia Relocation Decision Support System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}
