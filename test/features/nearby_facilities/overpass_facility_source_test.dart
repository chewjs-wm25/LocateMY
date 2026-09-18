import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/nearby_facilities/nearby_facilities.dart';

void main() {
  test('a diagnostic remark never turns a partial empty response into complete empty', () async {
    final OverpassFacilitySource source = createOverpassFacilitySource(
      MockClient((http.Request request) async {
        return http.Response('{"remark":"Query timed out","elements":[]}', 200);
      }),
    );
    final OverpassFacilityOutcome outcome = await source.query(
      const OverpassFacilityQuery(
        centre: GeographicPoint(latitude: 3, longitude: 101),
        radiusMetres: 2000,
        mappingVersion: 'osm-facility-v1',
      ),
    );
    expect(outcome, isA<OverpassFacilityPartial>());
  });
  test('invalid OSM coordinates are rejected instead of becoming covered facilities', () async {
    final OverpassFacilitySource source = createOverpassFacilitySource(
      MockClient((http.Request request) async {
        return http.Response(
          '{"elements":[{"type":"node","id":1,"lat":91,"lon":101,"tags":{"amenity":"clinic"}}]}',
          200,
        );
      }),
    );
    final OverpassFacilityOutcome outcome = await source.query(
      const OverpassFacilityQuery(
        centre: GeographicPoint(latitude: 3, longitude: 101),
        radiusMetres: 2000,
        mappingVersion: 'osm-facility-v1',
      ),
    );
    expect(
      (outcome as OverpassFacilityFailed).failure,
      OverpassFailure.invalidPayload,
    );
  });

  test(
    'requests identify the app without sending account information',
    () async {
      final OverpassFacilitySource source = createOverpassFacilitySource(
        MockClient((http.Request request) async {
          expect(
            request.headers['user-agent'],
            'LocateMY/1.0 (https://github.com/chewjs-wm25/LocateMY)',
          );
          expect(request.headers.containsKey('authorization'), isFalse);
          return http.Response('{"elements":[]}', 200);
        }),
      );
      expect(
        await source.query(
          const OverpassFacilityQuery(
            centre: GeographicPoint(latitude: 3, longitude: 101),
            radiusMetres: 2000,
            mappingVersion: 'osm-facility-v1',
          ),
        ),
        isA<OverpassFacilityComplete>(),
      );
    },
  );
  test('Node coordinates and Way/Relation representative centres retain their OSM identities', () async {
    final OverpassFacilitySource source = createOverpassFacilitySource(
      MockClient((http.Request request) async {
        expect(
          Uri.splitQueryString(request.body)['data'],
          contains('nwr(around:2000'),
        );
        return http.Response(
          '{"elements":[{"type":"node","id":1,"lat":3,"lon":101,"tags":{"amenity":"clinic"}},{"type":"way","id":1,"center":{"lat":3.001,"lon":101},"tags":{"amenity":"school"}},{"type":"relation","id":1,"center":{"lat":3.002,"lon":101},"tags":{"leisure":"park"}}]}',
          200,
        );
      }),
    );
    final OverpassFacilityComplete result = await source.query(
      const OverpassFacilityQuery(
        centre: GeographicPoint(latitude: 3, longitude: 101),
        radiusMetres: 2000,
        mappingVersion: 'osm-facility-v1',
      ),
    ) as OverpassFacilityComplete;
    expect(
      result.elements.map((OverpassElement item) {
        return item.elementType;
      }),
      <String>['node', 'way', 'relation'],
    );
    expect(result.elements[1].representativePoint.latitude, 3.001);
    expect(result.elements[2].representativePoint.latitude, 3.002);
  });
  test('HTTP rate limit, malformed payload, timeout and network failure have distinct typed results', () async {
    const OverpassFacilityQuery query = OverpassFacilityQuery(
      centre: GeographicPoint(latitude: 3, longitude: 101),
      radiusMetres: 2000,
      mappingVersion: 'osm-facility-v1',
    );
    final List<http.Client> clients = <http.Client>[
      MockClient((http.Request request) async {
        return http.Response('limit', 429);
      }),
      MockClient((http.Request request) async {
        return http.Response('{', 200);
      }),
      MockClient((http.Request request) async {
        throw TimeoutException('external timeout');
      }),
      MockClient((http.Request request) async {
        throw http.ClientException('external network unavailable');
      }),
    ];
    final List<OverpassFailure> expected = <OverpassFailure>[
      OverpassFailure.rateLimited,
      OverpassFailure.invalidPayload,
      OverpassFailure.timeout,
      OverpassFailure.networkUnavailable,
    ];
    for (int index = 0; index < clients.length; index += 1) {
      final OverpassFacilityOutcome outcome =
          await createOverpassFacilitySource(clients[index]).query(query);
      expect((outcome as OverpassFacilityFailed).failure, expected[index]);
    }
  });
}
