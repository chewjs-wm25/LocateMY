import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

import 'package:locate_my/models/nearby_facility.dart';
import 'package:locate_my/repositories/facility_repository.dart';

/// 迷你但真实的 Overpass JSON 响应（node 带 lat/lon，way 带 center）。
/// 远端 clinic 距中心 > 2km，应被仓库精确半径过滤掉。
const String _okBody = '''
{
  "version": 0.6,
  "elements": [
    {
      "type": "node", "id": 1, "lat": 3.1400, "lon": 101.6900,
      "tags": {"amenity": "hospital", "name": "Test Hospital"}
    },
    {
      "type": "way", "id": 2,
      "center": {"lat": 3.1410, "lon": 101.6910},
      "tags": {"amenity": "school", "name": "Test School"}
    },
    {
      "type": "node", "id": 3, "lat": 3.1405, "lon": 101.6905,
      "tags": {"highway": "bus_stop"}
    },
    {
      "type": "node", "id": 4, "lat": 3.1500, "lon": 101.7100,
      "tags": {"amenity": "clinic", "name": "Far Clinic"}
    }
  ]
}
''';

const String _emptyBody = '{"version": 0.6, "elements": []}';

final LatLng _kl = const LatLng(3.1390, 101.6869); // KL Sentral 附近

void main() {
  group('FacilityRepository.getNearbyFacilities', () {
    test('HTTP 200：解析 node/way、按距离过滤与升序、无名要素友好回退', () async {
      final requested = <Uri>[];
      final repo = FacilityRepository(
        client: MockClient((request) async {
          requested.add(request.url);
          expect(request.body, contains('data='));
          return http.Response(_okBody, 200, headers: {'content-type': 'application/json'});
        }),
      );

      final results = await repo.getNearbyFacilities(_kl);

      // 远端 clinic（>2km）被精确过滤；剩下 hospital / school(way) / bus_stop。
      expect(results, hasLength(3));
      expect(requested, hasLength(1));
      expect(requested.single.host, FacilityRepository.overpassEndpoints.first
          .replaceFirst('https://', '')
          .split('/')
          .first);

      // 距离升序。
      for (var i = 1; i < results.length; i++) {
        expect(results[i].distance, greaterThanOrEqualTo(results[i - 1].distance));
      }
      expect(results.every((f) => f.distance <= FacilityRepository.defaultRadiusMeters), isTrue);

      // 元素类型解析。
      final hospital = results.firstWhere((f) => f.name == 'Test Hospital');
      expect(hospital.category, FacilityCategory.healthcare);
      expect(hospital.type, 'hospital');
      final school = results.firstWhere((f) => f.name == 'Test School');
      expect(school.category, FacilityCategory.education);
      // 无名巴士站回退为可读中文名。
      final busStop = results.firstWhere((f) => f.type == 'bus_stop');
      expect(busStop.name, '巴士站');
      expect(busStop.category, FacilityCategory.transport);
    });

    test('主端点 504 时自动回退到下一端点', () async {
      var calls = 0;
      final requestedHosts = <String>[];
      final repo = FacilityRepository(
        client: MockClient((request) async {
          calls++;
          requestedHosts.add(request.url.host);
          if (calls == 1) return http.Response('Gateway Timeout', 504);
          return http.Response(_okBody, 200);
        }),
      );

      final results = await repo.getNearbyFacilities(_kl);

      expect(results, isNotEmpty);
      expect(requestedHosts, hasLength(2));
      expect(requestedHosts[0],
          FacilityRepository.overpassEndpoints.first.replaceFirst('https://', '').split('/').first);
      expect(requestedHosts[1], isNot(requestedHosts[0]));
    });

    test('HTTP 200 且无元素 → 返回空列表（真实空，不抛异常）', () async {
      final repo = FacilityRepository(
        client: MockClient((request) async => http.Response(_emptyBody, 200)),
      );

      final results = await repo.getNearbyFacilities(_kl);

      expect(results, isEmpty);
    });

    test('全部端点失败（非 200）→ 抛出 FacilityLoadException 并含各端点原因', () async {
      final repo = FacilityRepository(
        client: MockClient((request) async => http.Response('boom', 500)),
      );

      await expectLater(
        repo.getNearbyFacilities(_kl),
        throwsA(isA<FacilityLoadException>()
            .having((e) => e.message, 'message', contains('HTTP 500'))),
      );
    });

    test('全部端点请求超时 → FacilityLoadException 注明超时', () async {
      final repo = FacilityRepository(
        client: MockClient((request) async => throw TimeoutException('slow')),
      );

      await expectLater(
        repo.getNearbyFacilities(_kl),
        throwsA(isA<FacilityLoadException>()
            .having((e) => e.message, 'message', contains('请求超时'))),
      );
    });

    test('网络连接异常 → FacilityLoadException 携带原因', () async {
      final repo = FacilityRepository(
        client: MockClient((request) async => throw http.ClientException('Connection refused')),
      );

      await expectLater(
        repo.getNearbyFacilities(_kl),
        throwsA(isA<FacilityLoadException>()
            .having((e) => e.message, 'message', contains('Connection refused'))),
      );
    });

    test('去重：node 与 way 同一设施（同类型/名称/约同坐标）只保留一条', () async {
      const duplicatedBody = '''
      {
        "elements": [
          {"type": "node", "id": 10, "lat": 3.1400, "lon": 101.6900,
           "tags": {"amenity": "bank", "name": "Maybank"}},
          {"type": "way", "id": 11,
           "center": {"lat": 3.1401, "lon": 101.6901},
           "tags": {"amenity": "bank", "name": "Maybank"}}
        ]
      }
      ''';
      final repo = FacilityRepository(
        client: MockClient((request) async => http.Response(duplicatedBody, 200)),
      );

      final results = await repo.getNearbyFacilities(_kl);

      expect(results, hasLength(1));
    });
  });

  group('FacilityRepository.overpassEndpoints', () {
    test('至少配置 2 个端点用于回退', () {
      expect(FacilityRepository.overpassEndpoints.length, greaterThanOrEqualTo(2));
      for (final url in FacilityRepository.overpassEndpoints) {
        expect(Uri.parse(url).scheme, 'https');
      }
    });
  });
}
