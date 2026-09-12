import '../../models/location.dart';

class NearbyFacility {
  const NearbyFacility({
    required this.name,
    required this.type,
    required this.distance,
  });

  final String name;
  final String type;
  final String distance;
}

class NearbyFacilityCategory {
  const NearbyFacilityCategory({
    required this.name,
    required this.facilities,
    required this.totalCount,
    this.queryComplete = true,
  });

  final String name;
  final List<NearbyFacility> facilities;
  final int totalCount;
  final bool queryComplete;

  bool get isUnknown => !queryComplete;
  bool get isCovered => queryComplete && totalCount > 0;
  bool get isNotCovered => queryComplete && totalCount == 0;
  NearbyFacility? get nearest => facilities.isEmpty ? null : facilities.first;
  int get remainingCount => totalCount - facilities.length;
}

class NearbyFacilitiesResult {
  const NearbyFacilitiesResult({required this.categories});

  static const categoryNames = [
    '医疗健康',
    '教育资源',
    '日常生活',
    '交通出行',
    '安全与服务',
    '休闲与绿地',
  ];

  final List<NearbyFacilityCategory> categories;

  bool get hasUnknownCoverage =>
      categories.any((category) => category.isUnknown);

  int get coveredCategoryCount =>
      categories.where((category) => category.isCovered).length;

  int get totalFacilityCount =>
      categories.fold(0, (total, category) => total + category.totalCount);

  List<String> get uncoveredCategoryNames => categories
      .where((category) => category.isNotCovered)
      .map((category) => category.name)
      .toList();

  String get coverageSummary {
    if (hasUnknownCoverage) return '周边设施覆盖情况暂不可确定';
    if (coveredCategoryCount == 0) return '2 公里内暂无已收录周边设施';
    if (coveredCategoryCount == categoryNames.length) {
      return '2 公里内覆盖全部 6 类';
    }

    final missing = uncoveredCategoryNames;
    final displayed = missing.take(2).join('、');
    final suffix = missing.length > 2 ? '等（共 ${missing.length} 类）' : '';
    return '2 公里内覆盖 $coveredCategoryCount/6 类 · 未覆盖：$displayed$suffix';
  }
}

class NearbyFacilitiesFixtures {
  static final _byPlace = <Place, NearbyFacilitiesResult>{
    Place.penang: const NearbyFacilitiesResult(
      categories: [
        NearbyFacilityCategory(
          name: '医疗健康',
          totalCount: 6,
          facilities: [
            NearbyFacility(name: '槟城中央诊所', type: '诊所', distance: '650 米'),
          ],
        ),
        NearbyFacilityCategory(
          name: '教育资源',
          totalCount: 4,
          facilities: [
            NearbyFacility(name: '乔治市社区学校', type: '学校', distance: '820 米'),
          ],
        ),
        NearbyFacilityCategory(
          name: '日常生活',
          totalCount: 10,
          facilities: [
            NearbyFacility(name: '湿巴刹与超市', type: '市场', distance: '430 米'),
          ],
        ),
        NearbyFacilityCategory(
          name: '交通出行',
          totalCount: 4,
          facilities: [
            NearbyFacility(name: 'KOMTAR 巴士站', type: '巴士站', distance: '540 米'),
          ],
        ),
        NearbyFacilityCategory(name: '安全与服务', totalCount: 0, facilities: []),
        NearbyFacilityCategory(
          name: '休闲与绿地',
          totalCount: 2,
          facilities: [
            NearbyFacility(name: '海滨步道', type: '公园', distance: '1.2 公里'),
          ],
        ),
      ],
    ),
    Place.kl: const NearbyFacilitiesResult(
      categories: [
        NearbyFacilityCategory(
          name: '医疗健康',
          totalCount: 8,
          facilities: [
            NearbyFacility(name: '吉隆坡中央诊所', type: '诊所', distance: '480 米'),
          ],
        ),
        NearbyFacilityCategory(
          name: '教育资源',
          totalCount: 5,
          facilities: [
            NearbyFacility(name: '市中心社区学校', type: '学校', distance: '700 米'),
          ],
        ),
        NearbyFacilityCategory(
          name: '日常生活',
          totalCount: 10,
          facilities: [
            NearbyFacility(name: '武吉免登商场', type: '商场', distance: '350 米'),
          ],
        ),
        NearbyFacilityCategory(
          name: '交通出行',
          totalCount: 4,
          facilities: [
            NearbyFacility(name: '武吉免登捷运站', type: '铁路车站', distance: '380 米'),
          ],
        ),
        NearbyFacilityCategory(
          name: '安全与服务',
          totalCount: 2,
          facilities: [
            NearbyFacility(name: '市中心邮局', type: '邮局', distance: '1.0 公里'),
          ],
        ),
        NearbyFacilityCategory(
          name: '休闲与绿地',
          totalCount: 2,
          facilities: [
            NearbyFacility(name: '城市公园', type: '公园', distance: '900 米'),
          ],
        ),
      ],
    ),
  };

  static NearbyFacilitiesResult forPlace(Place place) => _byPlace[place]!;
}
