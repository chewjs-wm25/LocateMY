import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/home_relocation_outlook/home_relocation_outlook.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('real authenticated Home RPC, model, durable cache and allow/deny permissions', () async {
    HttpOverrides.global = null;
    sqfliteFfiInit();
    final env = Platform.environment;
    final client = SupabaseClient(
      env['SUPABASE_URL']!,
      env['SUPABASE_PUBLISHABLE_KEY']!,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final anon = SupabaseClient(
      env['SUPABASE_URL']!,
      env['SUPABASE_PUBLISHABLE_KEY']!,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    final dir = await Directory.systemTemp.createTemp('locatemy-home-live-');
    final auth = createAuthenticationSession(client);
    try {
      expect(
        await auth.signIn(
          email: env['LOCATEMY_EMAIL']!,
          password: env['LOCATEMY_PASSWORD']!,
        ),
        isA<SignInSucceeded>(),
      );
      final snapshot = ((await createHomeRelocationOutlook(
        client,
        openCache: () async => db,
      ).load(HomeLoadRequest.refresh)) as HomeLoaded).snapshot;
      expect(snapshot.completeness, HomeCompleteness.complete);
      expect(snapshot.relocationTiming.score, inInclusiveRange(0, 100));
      expect(snapshot.costPressure.source.observedAt, DateTime.utc(2026, 7));
      expect(
        snapshot.employmentStability.source.observedAt,
        DateTime.utc(2026, 6),
      );
      expect(
        snapshot.relocationTiming.sources.where(
          (s) => s.datasetId == 'gdp_qtr_real_sa',
        ),
        isEmpty,
      ); // Official snapshot contains abs only; 70% remaining economic weight is valid.
      expect(snapshot.householdMedianIncome.surveyYear, 2024);
      await expectLater(
        anon.rpc('read_home_metrics'),
        throwsA(
          isA<PostgrestException>().having((e) => e.code, 'code', '42501'),
        ),
      );
      for (final id in [
        'cpi_headline_inflation',
        'lfs_month_sa',
        'economic_indicators',
        'gdp_qtr_real_sa',
        'hh_income',
      ]) {
        final field = id == 'gdp_qtr_real_sa'
            ? 'value'
            : id == 'hh_income'
            ? 'income_median'
            : id == 'cpi_headline_inflation'
            ? 'inflation_yoy'
            : id == 'lfs_month_sa'
            ? 'u_rate'
            : 'leading_diffusion';
        await expectLater(
          client.from(id).update({field: 0}).eq('date', '0001-01-01'),
          throwsA(
            isA<PostgrestException>().having((e) => e.code, 'code', '42501'),
          ),
        );
      }
      expect(await auth.signOut(), isA<SignOutSucceeded>());
      expect((await db.query('home_public_cache')).length, 1);
      stdout.writeln(
        'PASS: real RPC complete five cards; independent source dates; authenticated read; anonymous execute deny; five mirrors update deny; SDK signout; public cache retained.',
      );
    } finally {
      await client.dispose();
      await anon.dispose();
      await db.close();
      await dir.delete(recursive: true);
    }
  }, skip: Platform.environment['LOCATEMY_HOME_LIVE'] != '1');
}
