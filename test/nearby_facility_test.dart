import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:locate_my/models/nearby_facility.dart';

void main() {
  const center = LatLng(3.1390, 101.6869);

  Map<String, dynamic> osm({
    Map<String, dynamic>? tags,
    double lat = 3.1400,
    double lon = 101.6900,
  }) =>
      {'type': 'node', 'id': 1, 'lat': lat, 'lon': lon, 'tags': tags ?? const {}};

  group('NearbyFacility.fromOsmJson', () {
    test('node 直接取 lat/lon 并解析名称与类别', () {
      final f = NearbyFacility.fromOsmJson(
        osm(tags: const {'amenity': 'hospital', 'name': 'Test Hospital'}),
        center,
      );

      expect(f.name, 'Test Hospital');
      expect(f.type, 'hospital');
      expect(f.category, FacilityCategory.healthcare);
      expect(f.location.latitude, closeTo(3.1400, 1e-9));
      expect(f.location.longitude, closeTo(101.6900, 1e-9));
      expect(f.distance, greaterThan(0));
    });

    test('way 无 lat/lon 时使用 center 坐标', () {
      final f = NearbyFacility.fromOsmJson(
        {
          'type': 'way',
          'id': 9,
          'center': const {'lat': 3.1420, 'lon': 101.6920},
          'tags': const {'amenity': 'school', 'name': 'Test School'},
        },
        center,
      );

      expect(f.location.latitude, closeTo(3.1420, 1e-9));
      expect(f.location.longitude, closeTo(101.6920, 1e-9));
      expect(f.category, FacilityCategory.education);
    });

    test('名称回退链：name → operator → brand → 中文类型名', () {
      expect(
        NearbyFacility.fromOsmJson(
          osm(tags: const {'amenity': 'clinic', 'operator': 'Klinik Rakyat'}),
          center,
        ).name,
        'Klinik Rakyat',
      );
      expect(
        NearbyFacility.fromOsmJson(
          osm(tags: const {'shop': 'convenience', 'brand': '99 Speedmart'}),
          center,
        ).name,
        '99 Speedmart',
      );
      // 无任何名称字段时回退到可读中文（回归：不能显示 "Unnamed node"）。
      expect(
        NearbyFacility.fromOsmJson(
          osm(tags: const {'highway': 'bus_stop'}),
          center,
        ).name,
        '巴士站',
      );
    });

    test('类别归类：shop / railway / leisure / landuse', () {
      expect(
        NearbyFacility.fromOsmJson(
          osm(tags: const {'shop': 'supermarket'}),
          center,
        ).category,
        FacilityCategory.living,
      );
      expect(
        NearbyFacility.fromOsmJson(
          osm(tags: const {'railway': 'station'}),
          center,
        ).category,
        FacilityCategory.transport,
      );
      expect(
        NearbyFacility.fromOsmJson(
          osm(tags: const {'leisure': 'park'}),
          center,
        ).category,
        FacilityCategory.leisure,
      );
      expect(
        NearbyFacility.fromOsmJson(
          osm(tags: const {'landuse': 'industrial'}),
          center,
        ).category,
        FacilityCategory.risk,
      );
      expect(
        NearbyFacility.fromOsmJson(
          osm(tags: const {'amenity': 'place_of_worship'}),
          center,
        ).category,
        FacilityCategory.leisure,
      );
    });

    test('距离：远处要素距离大于近处要素', () {
      final near = NearbyFacility.fromOsmJson(
        osm(tags: const {'amenity': 'bank', 'name': 'Near'}, lat: 3.1395, lon: 101.6875),
        center,
      );
      final far = NearbyFacility.fromOsmJson(
        osm(tags: const {'amenity': 'bank', 'name': 'Far'}, lat: 3.1480, lon: 101.6950),
        center,
      );

      expect(far.distance, greaterThan(near.distance));
    });

    test('osmTag 记录主要键值', () {
      final f = NearbyFacility.fromOsmJson(
        osm(tags: const {'amenity': 'pharmacy', 'name': 'Farmasi'}),
        center,
      );
      expect(f.osmTag, 'amenity=pharmacy');
    });
  });
}
