import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:locate_my/models/nearby_facility.dart';
import 'package:locate_my/providers/nearby_facilities_provider.dart';
import 'package:locate_my/repositories/facility_repository.dart';

NearbyFacility _facility(String name, double lat, double lng) => NearbyFacility(
      name: name,
      type: 'hospital',
      category: FacilityCategory.healthcare,
      location: LatLng(lat, lng),
      distance: 100,
    );

class _FakeRepository extends FacilityRepository {
  _FakeRepository(this.handler);

  final Future<List<NearbyFacility>> Function(LatLng location) handler;
  int calls = 0;

  @override
  Future<List<NearbyFacility>> getNearbyFacilities(
    LatLng location, {
    double radius = FacilityRepository.defaultRadiusMeters,
  }) {
    calls++;
    return handler(location);
  }
}

void main() {
  const kl = LatLng(3.1390, 101.6869);
  const penang = LatLng(5.4141, 100.3288);
  final list = [_facility('Test Hospital', 3.14, 101.69)];

  group('NearbyFacilitiesProvider', () {
    test('成功：数据缓存，同坐标再次 load 不重复请求', () async {
      final repo = _FakeRepository((location) async => list);
      final provider = NearbyFacilitiesProvider(repository: repo);

      await provider.loadNearbyFacilities(kl);

      expect(provider.facilities, hasLength(1));
      expect(provider.hasLoaded, isTrue);
      expect(provider.error, isNull);
      expect(provider.requestKey, isNotNull);

      // 幂等：未 force 的同坐标调用不再发请求。
      await provider.loadNearbyFacilities(kl);
      expect(repo.calls, 1);

      // force 会重新请求并刷新缓存。
      await provider.loadNearbyFacilities(kl, force: true);
      expect(repo.calls, 2);
      expect(provider.hasLoaded, isTrue);
    });

    test('失败：暴露 error、不缓存，未 force 的同 key 不自动重试', () async {
      var fail = true;
      final repo = _FakeRepository((location) async {
        if (fail) throw const FacilityLoadException('端点不可用');
        return list;
      });
      final provider = NearbyFacilitiesProvider(repository: repo);

      await provider.loadNearbyFacilities(kl);

      expect(provider.error, contains('端点不可用'));
      expect(provider.hasLoaded, isFalse);
      expect(provider.facilities, isEmpty);
      expect(repo.calls, 1);

      // 失败后同坐标自动 load 不会重试（等用户点按钮）。
      await provider.loadNearbyFacilities(kl);
      expect(repo.calls, 1);

      // force 重试成功后状态复位。
      fail = false;
      await provider.loadNearbyFacilities(kl, force: true);
      expect(repo.calls, 2);
      expect(provider.hasLoaded, isTrue);
      expect(provider.error, isNull);
    });

    test('切换坐标：自动加载新地点数据', () async {
      final loaded = <String>[];
      final repo = _FakeRepository((location) async {
        loaded.add('${location.latitude},${location.longitude}');
        return list;
      });
      final provider = NearbyFacilitiesProvider(repository: repo);

      await provider.loadNearbyFacilities(kl);
      await provider.loadNearbyFacilities(penang);

      expect(loaded, hasLength(2));
      expect(provider.requestKey, contains('5.414|100.329'));
      expect(provider.hasLoaded, isTrue);
    });

    test('clear：重置全部状态，允许同地点重新加载', () async {
      final repo = _FakeRepository((location) async => list);
      final provider = NearbyFacilitiesProvider(repository: repo);

      await provider.loadNearbyFacilities(kl);
      provider.clear();

      expect(provider.facilities, isEmpty);
      expect(provider.requestKey, isNull);
      expect(provider.hasLoaded, isFalse);

      await provider.loadNearbyFacilities(kl);
      expect(repo.calls, 2);
      expect(provider.facilities, hasLength(1));
    });
  });
}
