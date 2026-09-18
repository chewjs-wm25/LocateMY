import 'dart:convert';

import 'public_transportation_test.dart' show servedPayload;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/public_transportation/public_transportation.dart';

void main() {
  test(
    'real SDK sends the explicit scope and recovers after an HTTP failure',
    () async {
      int calls = 0;
      final List<http.Request> sent = <http.Request>[];
      final SupabaseClient client = SupabaseClient(
        'https://example.test',
        'test-key',
        httpClient: MockClient((http.Request request) async {
          calls++;
          sent.add(request);
          if (calls == 2) {
            return http.Response(
              '{"message":"permission denied","code":"42501"}',
              403,
              headers: <String, String>{'content-type': 'application/json'},
              request: request,
            );
          }
          final Map<String, Object?> payload = servedPayload();
          payload.addAll(<String, Object?>{
            'analysis_date': '2026-09-17',
            'latitude': 3.0738,
            'longitude': 101.6077,
            'transit_score': calls == 1 ? 68 : 69,
          });
          return http.Response(
            jsonEncode(payload),
            200,
            headers: <String, String>{'content-type': 'application/json'},
            request: request,
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final PublicTransportation transportation = createPublicTransportation(
        SupabaseTransitReader(client),
      );
      final TransitRequest request = TransitRequest(
        location: ValidLocationReference(
          locationId: 'sunway',
          point: const GeographicPoint(latitude: 3.0738, longitude: 101.6077),
        ),
        analysisDate: DateTime(2026, 9, 17),
        policy: TransitLoadPolicy.refresh,
      );
      final TransitLoadOutcome first = await transportation.load(request);
      expect(sent.first.url.path, '/rest/v1/rpc/read_transit_analysis');
      expect(jsonDecode(sent.first.body), <String, Object?>{
        'p_latitude': 3.0738,
        'p_longitude': 101.6077,
        'p_analysis_date': '2026-09-17',
        'p_refresh': true,
      });
      expect(
        first,
        isA<TransitAvailable>(),
        reason: first is TransitUnavailable ? first.reason.name : null,
      );
      expect(await transportation.load(request), same(first));
      final TransitAvailable recovered =
          (await transportation.load(request)) as TransitAvailable;
      expect(recovered.snapshot.score!.value, 69);
      expect(calls, 3);
      await client.dispose();
    },
  );

  test(
    'malformed successful RPC is sourceUnverifiable, not a transport outage',
    () async {
      final SupabaseClient client = SupabaseClient(
        'https://example.test',
        'test-key',
        httpClient: MockClient((http.Request request) async {
          return http.Response(
            jsonEncode(<Object?>[]),
            200,
            headers: <String, String>{'content-type': 'application/json'},
            request: request,
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final PublicTransportation transportation = createPublicTransportation(
        SupabaseTransitReader(client),
      );
      final TransitLoadOutcome outcome = await transportation.load(
        TransitRequest(
          location: ValidLocationReference(
            locationId: 'sunway',
            point: const GeographicPoint(latitude: 3.0738, longitude: 101.6077),
          ),
          analysisDate: DateTime(2026, 9, 17),
          policy: TransitLoadPolicy.refresh,
        ),
      );
      expect(outcome, isA<TransitUnavailable>());
      expect(
        (outcome as TransitUnavailable).reason,
        TransitUnavailableReason.sourceUnverifiable,
      );
      await client.dispose();
    },
  );
}
