import 'package:latlong2/latlong.dart';

enum FacilityCategory {
  healthcare,
  education,
  living,
  transport,
  safety,
  leisure,
  risk,
}

class NearbyFacility {
  final String name;
  final String type;
  final FacilityCategory category;
  final LatLng location;
  final double distance; // in meters
  final String? osmTag;
  final Map<String, dynamic>? metadata;

  NearbyFacility({
    required this.name,
    required this.type,
    required this.category,
    required this.location,
    required this.distance,
    this.osmTag,
    this.metadata,
  });

  factory NearbyFacility.fromOsmJson(Map<String, dynamic> json, LatLng center) {
    final tags = json['tags'] as Map<String, dynamic>? ?? {};
    final name = _displayName(tags);
    final lat = json['lat'] ?? json['center']?['lat'];
    final lon = json['lon'] ?? json['center']?['lon'];
    final location = LatLng(lat, lon);
    
    // Calculate distance (simplified for now, or use a proper tool)
    const distanceCalculator = Distance();
    final distance = distanceCalculator.as(LengthUnit.Meter, center, location);

    return NearbyFacility(
      name: name,
      type: _determineType(tags),
      category: _determineCategory(tags),
      location: location,
      distance: distance.toDouble(),
      osmTag: _getMainTag(tags),
      metadata: tags,
    );
  }

  /// 展示名回退链：name → operator → brand → 中文类型名。
  /// OSM 中大量要素（如巴士站）没有 name，旧实现回退成
  /// "Unnamed node/way"，不可读，这里给出可读的兜底。
  static String _displayName(Map<String, dynamic> tags) {
    for (final key in const ['name', 'operator', 'brand']) {
      final value = tags[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return _friendlyTypeName(tags);
  }

  static String _friendlyTypeName(Map<String, dynamic> tags) {
    final type = _determineType(tags);
    const friendly = {
      'hospital': '医院',
      'clinic': '诊所',
      'doctors': '诊所',
      'dentist': '牙科诊所',
      'pharmacy': '药房',
      'school': '学校',
      'university': '大学',
      'college': '学院',
      'kindergarten': '幼儿园',
      'childcare': '托儿所',
      'bank': '银行',
      'atm': 'ATM',
      'marketplace': '市场',
      'food_court': '熟食中心',
      'restaurant': '餐厅',
      'fast_food': '快餐店',
      'cafe': '咖啡馆',
      'fuel': '加油站',
      'supermarket': '超市',
      'convenience': '便利店',
      'mall': '商场',
      'bus_stop': '巴士站',
      'bus_station': '公交总站',
      'station': '车站',
      'halt': '铁路小站',
      'tram_stop': '电车站',
      'ferry_terminal': '渡轮码头',
      'toll_booth': '收费站',
      'charging_station': '充电站',
      'police': '警局',
      'fire_station': '消防局',
      'post_office': '邮局',
      'place_of_worship': '宗教场所',
      'library': '图书馆',
      'community_centre': '社区中心',
      'cinema': '电影院',
      'theatre': '剧院',
      'townhall': '市政厅',
      'park': '公园',
      'garden': '花园',
      'sports_centre': '运动中心',
      'fitness_centre': '健身中心',
      'industrial': '工业区',
    };
    return friendly[type] ?? (type == 'Facility' ? '设施' : type);
  }

  static FacilityCategory _determineCategory(Map<String, dynamic> tags) {
    if (tags.containsKey('amenity')) {
      final amenity = tags['amenity'];
      if (['hospital', 'clinic', 'doctors', 'dentist', 'pharmacy'].contains(amenity)) return FacilityCategory.healthcare;
      if (['school', 'university', 'college', 'kindergarten', 'childcare'].contains(amenity)) return FacilityCategory.education;
      if (['bank', 'atm', 'marketplace', 'food_court', 'restaurant'].contains(amenity)) return FacilityCategory.living;
      if (['police', 'fire_station', 'post_office'].contains(amenity)) return FacilityCategory.safety;
      if (['place_of_worship'].contains(amenity)) return FacilityCategory.leisure;
      if (['bus_station', 'ferry_terminal', 'charging_station'].contains(amenity)) return FacilityCategory.transport;
    }
    if (tags.containsKey('shop')) {
      final shop = tags['shop'];
      if (['supermarket', 'convenience', 'mall', 'pharmacy'].contains(shop)) return FacilityCategory.living;
    }
    if (tags.containsKey('railway') || tags.containsKey('station')) return FacilityCategory.transport;
    if (tags.containsKey('leisure')) {
      final leisure = tags['leisure'];
      if (['park', 'garden', 'sports_centre', 'fitness_centre'].contains(leisure)) return FacilityCategory.leisure;
    }
    if (tags.containsKey('landuse') && tags['landuse'] == 'industrial') return FacilityCategory.risk;
    if (tags.containsKey('highway')) {
      final highway = tags['highway'];
      if (['bus_stop', 'motorway_junction'].contains(highway)) return FacilityCategory.transport;
    }
    if (tags.containsKey('barrier') && tags['barrier'] == 'toll_booth') return FacilityCategory.transport;
    
    return FacilityCategory.living; // Default
  }

  static String _determineType(Map<String, dynamic> tags) {
    return tags['amenity'] ?? tags['shop'] ?? tags['railway'] ?? tags['leisure'] ?? tags['highway'] ?? 'Facility';
  }

  static String? _getMainTag(Map<String, dynamic> tags) {
    if (tags.containsKey('amenity')) return 'amenity=${tags['amenity']}';
    if (tags.containsKey('shop')) return 'shop=${tags['shop']}';
    if (tags.containsKey('railway')) return 'railway=${tags['railway']}';
    if (tags.containsKey('leisure')) return 'leisure=${tags['leisure']}';
    return null;
  }
}
