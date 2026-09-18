import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:locatemy/features/home_relocation_outlook/home_relocation_outlook.dart';
import 'package:locatemy/l10n/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_load_test.dart' show fullData;

void main() {
  testWidgets(
    'production homepage exposes real six-observation trends and their approximation basis',
    (tester) async {
      sqfliteFfiInit();
      final db = (await tester.runAsync(
        () => databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath),
      ))!;
      final client = (await tester.runAsync(
        () async => SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          httpClient: MockClient(
            (r) async => http.Response(jsonEncode(fullData()), 200, request: r),
          ),
        ),
      ))!;
      final home = createHomeRelocationOutlook(
        client,
        openCache: () async => db,
      );
      final initial = await tester.runAsync(
        () => home.load(HomeLoadRequest.cacheAllowed),
      );
      expect(initial, isA<HomeLoaded>());
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HomeOutlookPage(home: home, onExploreMap: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Recent trend · 6 observations'), findsNWidgets(3));
      expect(
        find.text(
          'Reconstructed from current observations; historical revisions may affect this comparison.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Jul 2024'), findsWidgets);
      expect(find.textContaining('Dec 2024'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await client.dispose();
        await db.close();
      });
    },
  );
  testWidgets(
    'economic trend endpoint retains the newer GDP observation and current score',
    (tester) async {
      sqfliteFfiInit();
      final db = (await tester.runAsync(
        () => databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath),
      ))!;
      final payload = fullData();
      payload['datasets']['gdp_qtr_real_sa'].add({
        'date': '2025-01-01',
        'series': 'growth_qoq',
        'value': 0,
      });
      final client = (await tester.runAsync(
        () async => SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          httpClient: MockClient(
            (r) async => http.Response(jsonEncode(payload), 200, request: r),
          ),
        ),
      ))!;
      final home = createHomeRelocationOutlook(
        client,
        openCache: () async => db,
      );
      expect(
        await tester.runAsync(() => home.load(HomeLoadRequest.cacheAllowed)),
        isA<HomeLoaded>(),
      );
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HomeOutlookPage(home: home, onExploreMap: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp('Jan 2025: 32 / 100')),
        findsOneWidget,
      );
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await client.dispose();
        await db.close();
      });
    },
  );
}
