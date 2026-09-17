import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/public_transportation/public_transportation.dart';

void main() {
  test('official snapshot RPC preserves partial facts and enforces read-only access', () async {
    HttpOverrides.global = null;
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
    try {
      await client.auth.signInWithPassword(
        email: env['LOCATEMY_EMAIL']!,
        password: env['LOCATEMY_PASSWORD']!,
      );
      final PublicTransportation transportation = createPublicTransportation(
        SupabaseTransitReader(client),
      );
      final ValidLocationReference location = ValidLocationReference(
        locationId: 'official-sunway',
        point: const GeographicPoint(latitude: 3.0738, longitude: 101.6077),
        displayName: 'Sunway Mentari',
      );
      final TransitLoadOutcome outcome = await transportation.load(
        TransitRequest(
          location: location,
          analysisDate: DateTime(2026, 9, 17),
          policy: TransitLoadPolicy.refresh,
        ),
      );
      expect(outcome, isA<TransitIncomplete>());
      final TransitPartialSnapshot snapshot =
          (outcome as TransitIncomplete).snapshot;
      expect(snapshot.radiusMeters, 1500);
      expect(snapshot.feeds.length, 16);
      expect(snapshot.stations, isNotEmpty);
      expect(snapshot.uniqueStopCount, snapshot.stations.length);
      expect(snapshot.uniqueRouteCount, greaterThan(0));
      expect(snapshot.provenance.snapshotId, 'official-2026-09-17');
      expect(
        snapshot.provenance.referenceGridVersion,
        'utm-wgs84-1km-stopcatchment-v1',
      );
      expect(
        snapshot.feeds
            .where((FeedStatus feed) {
              return feed.availability == FeedAvailability.failed;
            })
            .single
            .feedId,
        'gtfs_static_prasarana_rapid_bus_kuantan',
      );
      final TransitLoadOutcome future = await transportation.load(
        TransitRequest(
          location: location,
          analysisDate: DateTime(2040, 1, 1),
          policy: TransitLoadPolicy.refresh,
        ),
      );
      expect(future, isA<TransitUnavailable>());
      expect(
        (future as TransitUnavailable).reason,
        TransitUnavailableReason.analysisDateOutsideServiceRange,
      );
      expect(future.feeds.length, 16);
      await expectLater(
        anon.rpc(
          'read_transit_analysis',
          params: <String, Object?>{
            'p_latitude': 3.0738,
            'p_longitude': 101.6077,
            'p_analysis_date': '2026-09-17',
          },
        ),
        throwsA(
          isA<PostgrestException>().having(
            (PostgrestException e) {
              return e.code;
            },
            'permission code',
            '42501',
          ),
        ),
      );
      for (final String table in <String>[
        'gtfs_feed_snapshots',
        'gtfs_stops',
        'gtfs_routes',
        'gtfs_service_dates',
        'gtfs_stop_service_links',
        'transit_reference_grid',
        'transit_evaluation_batches',
      ]) {
        await expectLater(
          client.from(table).insert(<String, Object?>{
            'snapshot_id': 'denied-transit-write',
          }),
          throwsA(
            isA<PostgrestException>().having(
              (PostgrestException e) {
                return e.code;
              },
              'permission code',
              '42501',
            ),
          ),
        );
        await expectLater(
          anon.from(table).select().limit(1),
          throwsA(
            isA<PostgrestException>().having(
              (PostgrestException e) {
                return e.code;
              },
              'permission code',
              '42501',
            ),
          ),
        );
      }
    } finally {
      await client.auth.signOut();
      await client.dispose();
      await anon.dispose();
    }
  }, skip: Platform.environment['LOCATEMY_TRANSIT_LIVE'] != '1');
}
