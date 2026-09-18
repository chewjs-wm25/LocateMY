import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'live GEO-001 resolves fixed samples, denies table access and recovers session',
    () async {
      HttpOverrides.global = null;
      final env = Platform.environment;
      final client = SupabaseClient(
        env['SUPABASE_URL']!,
        env['SUPABASE_PUBLISHABLE_KEY']!,
        authOptions: const AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.implicit,
        ),
      );
      final geo = createGeographicContext(client);
      GeographicContextRequest request(double lat, double lng) =>
          GeographicContextRequest(
            location: ValidLocationReference(
              locationId: 'map-validated-fixture',
              point: GeographicPoint(latitude: lat, longitude: lng),
            ),
            levels: GeographicLevel.values.toSet(),
          );
      final single = request(3.103135, 101.550947699441);
      try {
        expect(
          (await geo.resolve(single) as GeographicContextUnavailable).failure,
          GeographicContextFailure.scopeUnavailable,
        );
        await expectLater(
          client.rpc(
            'read_administrative_boundary_candidates',
            params: {'latitude': 3.103135, 'longitude': 101.550947699441},
          ),
          throwsA(
            isA<PostgrestException>().having((e) => e.code, 'code', '42501'),
          ),
        );
        for (final table in [
          'administrative_district_boundaries',
          'government_dataset_imports',
        ]) {
          await expectLater(
            client.from(table).select().limit(1),
            throwsA(
              isA<PostgrestException>().having((e) => e.code, 'code', '42501'),
            ),
          );
        }
        await client.auth.signInWithPassword(
          email: env['LOCATEMY_GEO_EMAIL']!,
          password: env['LOCATEMY_GEO_PASSWORD']!,
        );
        final result = await geo.resolve(single) as GeographicContextAvailable;
        final district =
            result.results[GeographicLevel.district] as GeographicLevelResolved;
        expect(district.area.stableId, '10_5');
        expect(district.area.name, 'Petaling');
        expect(
          district.provenance.sourceVersion,
          '21a78e98efd4cd9b022a27a1bf67d167076b7591',
        );
        expect(
          district.provenance.sourceSha256,
          '3edb1022b2de371bba6b7afb9802b6fc6d747c86dbcc40abf2374a9134f3c561',
        );
        expect(
          district.provenance.derivedGeometrySha256,
          '929e7ce03417d284972f6550820806d0a29179f532b1c6c77f6bf5473bc1cb7f',
        );
        expect(district.provenance.importedAt.isUtc, isTrue);
        final boundary = await geo.resolve(
          request(3.22238, 101.56576),
        ) as GeographicContextAvailable;
        expect(
          (boundary.results[GeographicLevel.district]
                  as GeographicLevelAmbiguous)
              .candidates
              .length,
          greaterThanOrEqualTo(2),
        );
        final island = await geo.resolve(
          request(2.297005, 104.120960241975),
        ) as GeographicContextAvailable;
        expect(
          island.results[GeographicLevel.district],
          isA<GeographicLevelResolved>(),
        );
        final empty = await geo.resolve(
          request(4.0, 109.0),
        ) as GeographicContextAvailable;
        expect(
          (empty.results[GeographicLevel.district] as GeographicLevelUnresolved)
              .failure,
          GeographicContextFailure.noCoverage,
        );
        for (final table in [
          'administrative_district_boundaries',
          'government_dataset_imports',
        ]) {
          await expectLater(
            client.from(table).select().limit(1),
            throwsA(
              isA<PostgrestException>().having((e) => e.code, 'code', '42501'),
            ),
          );
          await expectLater(
            client.from(table).insert(<String, dynamic>{}),
            throwsA(
              isA<PostgrestException>().having((e) => e.code, 'code', '42501'),
            ),
          );
          await expectLater(
            client
                .from(table)
                .update({'source_version': 'denied'})
                .eq('source_version', 'does-not-exist'),
            throwsA(
              isA<PostgrestException>().having((e) => e.code, 'code', '42501'),
            ),
          );
          await expectLater(
            client.from(table).delete().eq('source_version', 'does-not-exist'),
            throwsA(
              isA<PostgrestException>().having((e) => e.code, 'code', '42501'),
            ),
          );
        }
        await client.auth.signOut(scope: SignOutScope.local);
        expect(
          (await geo.resolve(single) as GeographicContextUnavailable).failure,
          GeographicContextFailure.scopeUnavailable,
        );
        await client.auth.signInWithPassword(
          email: env['LOCATEMY_GEO_EMAIL']!,
          password: env['LOCATEMY_GEO_PASSWORD']!,
        );
        expect(await geo.resolve(single), isA<GeographicContextAvailable>());
        stdout.writeln(
          'GEO_LIVE_PASS: single, boundary, island, noCoverage, authenticated RPC, anon RPC deny, base-table read/write deny, logout/recovery',
        );
      } finally {
        await client.auth.signOut(scope: SignOutScope.local);
        await client.dispose();
      }
    },
    skip: Platform.environment['LOCATEMY_GEO_LIVE'] != '1',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
