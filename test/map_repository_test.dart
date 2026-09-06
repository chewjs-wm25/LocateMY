import 'package:flutter_test/flutter_test.dart';
import 'package:locate_my/repositories/map_repository.dart';

void main() {
  group('MapRepository.parseHazardMarker', () {
    test('解析 Supabase PostGIS 返回的 GeoJSON location（真实抓包格式）', () {
      // 从真实 Supabase REST 响应截取：location 是 GeoJSON 对象，
      // coordinates = [经度, 纬度]
      final json = {
        'id': 'eec0849c-9b2f-49b0-a504-b8d070036400',
        'user_id': 'e9ddb699-c590-4af7-b09a-ab9f5a48b7f9',
        'hazard_type': 'flood',
        'title': 'Flood',
        'description': 'YEs',
        'district': null,
        'location': {
          'type': 'Point',
          'crs': {
            'type': 'name',
            'properties': {'name': 'EPSG:4326'},
          },
          'coordinates': [101.64092550987878, 3.214787460169993],
        },
        'status': 'pending',
        'report_time': '2026-09-06T13:21:29.051362+00:00',
      };

      final hazard = MapRepository.parseHazardMarker(json);

      expect(hazard.location.latitude, closeTo(3.214787460169993, 1e-9));
      expect(hazard.location.longitude, closeTo(101.64092550987878, 1e-9));
      expect(hazard.type.name, 'flood');
      expect(hazard.id, 'eec0849c-9b2f-49b0-a504-b8d070036400');
      expect(hazard.createdBy, 'e9ddb699-c590-4af7-b09a-ab9f5a48b7f9');
    });

    test('解析 GeoJSON 时必须落在马来西亚范围内（回归：坐标不能被写成 0,0）', () {
      final json = {
        'id': '1',
        'title': 'Road',
        'location': {
          'type': 'Point',
          'coordinates': [101.9758, 4.2105], // 马来西亚中心
        },
        'hazard_type': 'traffic',
      };

      final hazard = MapRepository.parseHazardMarker(json);

      expect(hazard.location.latitude, 4.2105);
      expect(hazard.location.longitude, 101.9758);
      expect(hazard.location.latitude, isNot(0.0));
      expect(hazard.location.longitude, isNot(0.0));
    });

    test('解析 "POINT(lng lat)" 文本格式', () {
      final json = {
        'id': '2',
        'title': 'Flood spot',
        'location': 'POINT(101.6409 3.2148)',
        'hazard_type': 'flood',
      };

      final hazard = MapRepository.parseHazardMarker(json);

      expect(hazard.location.latitude, closeTo(3.2148, 1e-9));
      expect(hazard.location.longitude, closeTo(101.6409, 1e-9));
    });

    test('解析带 SRID 前缀的 "SRID=4326;POINT(lng lat)" 文本格式', () {
      final json = {
        'id': '3',
        'title': 'Crime',
        'location': 'SRID=4326;POINT(101.7 3.1)',
        'hazard_type': 'crime',
      };

      final hazard = MapRepository.parseHazardMarker(json);

      expect(hazard.location.latitude, closeTo(3.1, 1e-9));
      expect(hazard.location.longitude, closeTo(101.7, 1e-9));
    });

    test('解析带 lat/lng 键的普通对象', () {
      final json = {
        'id': '4',
        'title': 'Other',
        'location': {'lat': 3.2, 'lng': 101.8},
        'hazard_type': 'other',
      };

      final hazard = MapRepository.parseHazardMarker(json);

      expect(hazard.location.latitude, closeTo(3.2, 1e-9));
      expect(hazard.location.longitude, closeTo(101.8, 1e-9));
    });

    test('解析顶层 latitude/longitude 键（旧结构兼容）', () {
      final json = {
        'id': '5',
        'title': 'Legacy',
        'latitude': 5.0,
        'longitude': 100.0,
        'hazard_type': 'infrastructure',
      };

      final hazard = MapRepository.parseHazardMarker(json);

      expect(hazard.location.latitude, closeTo(5.0, 1e-9));
      expect(hazard.location.longitude, closeTo(100.0, 1e-9));
    });
  });
}
