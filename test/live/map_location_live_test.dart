import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'online saved locations persist and are restricted to their owner',
    () async {
      HttpOverrides.global = null;
      final Map<String, String> env = Platform.environment;
      SupabaseClient make() {
        return SupabaseClient(
          env['SUPABASE_URL']!,
          env['SUPABASE_PUBLISHABLE_KEY']!,
        );
      }

      final SupabaseClient client = make();
      final SupabaseClient other = make();
      String? createdId;
      try {
        await client.auth.signInWithPassword(
          email: env['LOCATEMY_EMAIL']!,
          password: env['LOCATEMY_PASSWORD']!,
        );
        await other.auth.signInWithPassword(
          email: env['LOCATEMY_OTHER_EMAIL']!,
          password: env['LOCATEMY_OTHER_PASSWORD']!,
        );
        final String accountId = client.auth.currentUser!.id;
        final LocationCoordinator map = createLocationCoordinator(
          accountId: accountId,
          validatePoint: (GeographicPoint point) {
            return validateLocationInMalaysia(client, point);
          },
          storage: createLocationStorage(client: client, accountId: accountId),
        );
        final LocationSelected selected = await map.select(
          const LocationSelectionRequest(
            role: LocationRole.single,
            point: GeographicPoint(latitude: 3.0738, longitude: 101.6072),
          ),
        ) as LocationSelected;
        final SavedLocationSaved saved = await map.save(
          SaveLocationRequest(
            location: selected.location,
            name: 'Issue31 smoke',
          ),
        ) as SavedLocationSaved;
        createdId = saved.savedLocation.id;
        final LocationStorage reopened = createLocationStorage(
          client: client,
          accountId: accountId,
        );
        expect(
          (await reopened.readRemote()).any((SavedRecord row) {
            return row.saved.id == createdId;
          }),
          true,
        );
        expect(
          await other
              .from('user_saved_locations')
              .select('id')
              .eq('id', createdId),
          isEmpty,
        );
        expect(
          await other
              .from('user_saved_locations')
              .update({'name': 'Forbidden'})
              .eq('id', createdId)
              .select('id'),
          isEmpty,
        );
        expect(
          await map.deleteSavedLocation(createdId),
          isA<SavedLocationSaved>(),
        );
        final SavedLocationsAvailable remaining =
            await map.loadSavedLocations() as SavedLocationsAvailable;
        expect(
          remaining.locations.any((SavedLocation row) {
            return row.id == createdId;
          }),
          false,
        );
      } finally {
        if (createdId != null) {
          await client
              .from('user_saved_locations')
              .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
              .eq('id', createdId)
              .isFilter('deleted_at', null);
        }
        await client.dispose();
        await other.dispose();
      }
    },
    skip: Platform.environment['LOCATEMY_MAP_LIVE'] != '1',
  );
}
