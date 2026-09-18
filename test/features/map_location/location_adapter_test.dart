import 'dart:convert';
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:locatemy/features/map_location/map_location.dart';

void main() {
  for (final String failure in [
    'http',
    'timeout',
    'metadata',
    'emptyVersion',
  ]) {
    test('boundary $failure becomes typed unavailable and recovers', () async {
      bool outage = true;
      final SupabaseClient client = SupabaseClient(
        'https://example.test',
        'public',
        httpClient: MockClient((request) async {
          if (outage && failure == 'timeout') {
            throw TimeoutException('timeout');
          }
          return http.Response(
            jsonEncode(
              outage && failure == 'http'
                  ? {'code': '42501', 'message': 'denied'}
                  : [
                      {
                        'source_version': outage && failure == 'emptyVersion'
                            ? ' '
                            : 'v1',
                        'source_sha256': outage && failure == 'metadata'
                            ? 'bad'
                            : 'a' * 64,
                        'derived_geometry_sha256': 'b' * 64,
                      },
                    ],
            ),
            outage && failure == 'http' ? 403 : 200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      const GeographicPoint point = GeographicPoint(
        latitude: 3,
        longitude: 101,
      );
      await expectLater(
        validateLocationInMalaysia(client, point),
        throwsA(SavedLocationFailure.retryableUnavailable),
      );
      outage = false;
      expect(await validateLocationInMalaysia(client, point), isTrue);
      await client.dispose();
    });
  }
  test('Geoapify HTTP and malformed responses recover on retry', () async {
    int response = 0;
    final LocationSearch search = createLocationSearch(
      apiKey: 'test',
      client: MockClient((request) async {
        response++;
        return http.Response(
          response == 1
              ? 'unavailable'
              : response == 2
              ? '{}'
              : '{"features":[]}',
          response == 1 ? 503 : 200,
        );
      }),
    );
    expect(await search.search('Place'), isA<LocationSearchUnavailable>());
    expect(await search.search('Place'), isA<LocationSearchUnavailable>());
    expect(await search.search('Place'), isA<LocationSearchAvailable>());
  });
  test(
    'Geoapify requests Malaysia candidates and preserves coordinates',
    () async {
      final LocationSearch search = createLocationSearch(
        apiKey: 'test',
        client: MockClient((request) async {
          expect(request.url.queryParameters['filter'], 'countrycode:my');
          return http.Response(
            jsonEncode({
              'features': [
                {
                  'properties': {
                    'lat': 3.1,
                    'lon': 101.6,
                    'formatted': 'Place',
                  },
                },
              ],
            }),
            200,
          );
        }),
      );
      final LocationSearchAvailable result =
          await search.search('Place') as LocationSearchAvailable;
      expect(result.candidates.single.point.latitude, 3.1);
      expect(result.candidates.single.displayName, 'Place');
    },
  );
}
