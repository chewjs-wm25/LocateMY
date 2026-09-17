import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locatemy/features/infrastructure_coverage/infrastructure_coverage.dart';
import 'package:locatemy/features/public_transportation/public_transportation.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';

void main() {
  test('real infrastructure RPC canonical transit and private priorities allow deny restore', () async {
    HttpOverrides.global = null;
    final Map<String, String> env = Platform.environment;
    SupabaseClient client() {
      return SupabaseClient(
        env['SUPABASE_URL']!,
        env['SUPABASE_PUBLISHABLE_KEY']!,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
    }

    final SupabaseClient a = client();
    final SupabaseClient b = client();
    final SupabaseClient anon = client();
    Map<String, dynamic>? original;
    try {
      await a.auth.signInWithPassword(
        email: env['LOCATEMY_EMAIL']!,
        password: env['LOCATEMY_PASSWORD']!,
      );
      await b.auth.signInWithPassword(
        email: env['LOCATEMY_OTHER_EMAIL']!,
        password: env['LOCATEMY_OTHER_PASSWORD']!,
      );
      final String id = a.auth.currentUser!.id;
      expect((await SupabaseInfrastructureWeightsStore(b).read()).health, 5);
      original = await a
          .from('user_ici_preferences')
          .select('health,education,transit,updated_at')
          .eq('user_id', id)
          .maybeSingle();
      final SupabaseInfrastructureWeightsStore store =
          SupabaseInfrastructureWeightsStore(a);
      await store.save(
        const InfrastructureWeightSettings(
          health: 1,
          education: 10,
          transit: 5,
        ),
      );
      expect((await store.read()).health, 1);
      expect(
        await b.from('user_ici_preferences').select('health').eq('user_id', id),
        isEmpty,
      );
      await expectLater(
        b.from('user_ici_preferences').insert(<String, Object?>{
          'user_id': id,
          'health': 2,
          'education': 2,
          'transit': 2,
        }),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        a
            .from('user_ici_preferences')
            .update(<String, Object?>{'health': 0})
            .eq('user_id', id),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        a
            .from('user_ici_preferences')
            .update(<String, Object?>{'user_id': b.auth.currentUser!.id})
            .eq('user_id', id),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        anon.rpc(
          'read_infrastructure_inputs',
          params: <String, Object?>{
            'p_state': 'Selangor',
            'p_district': 'Petaling',
          },
        ),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        anon.from('user_ici_preferences').select('health'),
        throwsA(isA<PostgrestException>()),
      );
      const ValidLocationReference location = ValidLocationReference(
        locationId: 'qa',
        point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
      );
      final PublicTransportation transit = createPublicTransportation(
        SupabaseTransitReader(a),
      );
      final InfrastructureService service = createInfrastructureCoverage(
        geographicContext: createGeographicContext(a),
        reader: SupabaseInfrastructureInputsReader(a),
        transportation: transit,
        weightsStore: store,
      );
      final InfrastructureLoadOutcome outcome = await service.fetch(
        location,
        DateTime(2026, 9, 17),
        policy: InfrastructureLoadPolicy.refresh,
      );
      expect(outcome, isA<InfrastructureAvailable>());
      final InfrastructureCoverage snapshot =
          (outcome as InfrastructureAvailable).snapshot;
      expect(snapshot.state, 'Selangor');
      expect(snapshot.district, 'Petaling');
      expect(snapshot.score, isNotNull);
      final TransitLoadOutcome canonical = await transit.load(
        TransitRequest(
          location: location,
          analysisDate: DateTime(2026, 9, 17),
          policy: TransitLoadPolicy.refresh,
        ),
      );
      if (canonical is TransitAvailable) {
        expect(
          snapshot.categories.last.score,
          canonical.snapshot.score?.value.toDouble(),
        );
      }
      expect(snapshot.categories[2].score, isNull);
      expect(snapshot.categories[3].score, isNull);
      final List<InfrastructureLoadOutcome> comparison = await service.compare(
        location,
        location,
        DateTime(2026, 9, 17),
      );
      expect(
        (comparison[0] as InfrastructureAvailable).snapshot.weights.health,
        5,
      );
      await a.auth.signOut();
      await expectLater(store.read(), throwsStateError);
      await a.auth.signInWithPassword(
        email: env['LOCATEMY_OTHER_EMAIL']!,
        password: env['LOCATEMY_OTHER_PASSWORD']!,
      );
      expect((await SupabaseInfrastructureWeightsStore(a).read()).health, 5);
      await expectLater(store.read(), throwsStateError);
      await a.auth.signOut();
    } finally {
      if (a.auth.currentUser == null) {
        await a.auth.signInWithPassword(
          email: env['LOCATEMY_EMAIL']!,
          password: env['LOCATEMY_PASSWORD']!,
        );
      }
      final String id = a.auth.currentUser!.id;
      if (original == null) {
        await a.from('user_ici_preferences').delete().eq('user_id', id);
      } else {
        await a.from('user_ici_preferences').update(original).eq('user_id', id);
      }
      await a.dispose();
      await b.dispose();
      await anon.dispose();
    }
  }, skip: Platform.environment['LOCATEMY_INFRASTRUCTURE_LIVE'] != '1');
}
