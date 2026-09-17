import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/crime_security/crime_security.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('verified official crime inputs resolve actual states with authenticated read and write/anonymous deny', () async {
    HttpOverrides.global = null;
    sqfliteFfiInit();
    final Map<String, String> env = Platform.environment;
    final SupabaseClient client = SupabaseClient(
      env['SUPABASE_URL']!,
      env['SUPABASE_PUBLISHABLE_KEY']!,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final SupabaseClient anon = SupabaseClient(
      env['SUPABASE_URL']!,
      env['SUPABASE_PUBLISHABLE_KEY']!,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final Database db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    try {
      await client.auth.signInWithPassword(
        email: env['LOCATEMY_EMAIL']!,
        password: env['LOCATEMY_PASSWORD']!,
      );
      final Map<String, Object?> data = await SupabaseSafetyInputsReader(client)
          .readSafetyInputs();
      expect(data['verified'], true);
      expect(data['latest_complete_year'], 2023);
      final CrimeSecurity crime = createCrimeSecurity(
        geographicContext: createGeographicContext(client),
        reader: SupabaseSafetyInputsReader(client),
        database: db,
      );
      const ValidLocationReference a = ValidLocationReference(
        locationId: 'sunway',
        point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
        displayName: 'Sunway Mentari',
      );
      const ValidLocationReference b = ValidLocationReference(
        locationId: 'johor',
        point: GeographicPoint(latitude: 1.4927, longitude: 103.7414),
        displayName: 'Johor Bahru',
      );
      final SafetyAnalysis result = await crime.analyse(a, refresh: true);
      expect(result.reportingState, 'Selangor');
      expect(result.latestCount, 13739);
      expect(result.availability, SafetyAvailability.complete);
      expect(result.year, 2023);
      final SafetyComparison comparison = await crime.compare(a, b);
      expect(comparison.b.reportingState, 'Johor');
      expect(comparison.difference, isNotNull);
      await expectLater(
        anon.rpc('read_safety_inputs'),
        throwsA(
          isA<PostgrestException>().having(
            (PostgrestException e) {
              return e.code;
            },
            'permission',
            '42501',
          ),
        ),
      );
      for (final SupabaseClient caller in <SupabaseClient>[client, anon]) {
        await expectLater(
          caller.from('crime_district').insert(<String, Object?>{
            'date': '2023-01-01',
            'state': 'Denied',
            'district': 'Denied',
            'category': 'assault',
            'type': 'murder',
            'crimes': 0,
          }),
          throwsA(
            isA<PostgrestException>().having(
              (PostgrestException e) {
                return e.code;
              },
              'write deny',
              '42501',
            ),
          ),
        );
      }
      await expectLater(
        anon.from('crime_district').select().limit(1),
        throwsA(
          isA<PostgrestException>().having(
            (PostgrestException e) {
              return e.code;
            },
            'read deny',
            '42501',
          ),
        ),
      );
    } finally {
      await db.close();
      await client.auth.signOut();
      await client.dispose();
      await anon.dispose();
    }
  }, skip: Platform.environment['LOCATEMY_CRIME_LIVE'] != '1');
}
