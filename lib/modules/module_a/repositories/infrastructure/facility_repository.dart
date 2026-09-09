import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:locate_my/modules/module_a/models/infrastructure/nearby_facility.dart';

/// 周边设施 (OSM) 数据源加载失败（所有 Overpass 端点均不可用 / 返回错误）。
///
/// 与“真实空结果”不同：空结果表示 Overpass 正常返回但半径内没有元素，
/// 此时仓库返回 `[]` 而不抛异常，由调用方自行区分。
class FacilityLoadException implements Exception {
  final String message;

  const FacilityLoadException(this.message);

  @override
  String toString() => message;
}

/// 周边设施 (POI) 数据仓库：通过 OSM Overpass API 拉取选中地点周边的设施。
class FacilityRepository {
  /// 依次尝试的 Overpass 公共端点。
  ///
  /// 公共实例经常排队超时（实测 overpass-api.de 对相同查询 3 次里 2 次
  /// 返回 HTTP 504），因此按顺序回退到其它实例，全部失败才抛异常。
  static const List<String> overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
    'https://overpass.osm.jp/api/interpreter',
  ];

  /// 默认搜索半径（米），与视图展示口径保持一致。
  static const double defaultRadiusMeters = 2000;

  /// 请求 UA：Overpass 官方建议语义化标识，同时规避公共端点对
  /// 空 UA / 通用 Dart UA 返回 HTTP 406 的拒绝策略。
  static const String _userAgent =
      'LocateMY/1.0 (Malaysia relocation assistant; overpass client)';

  /// 单个端点的请求超时。略小于 Overpass 服务端 [timeout:25]，
  /// 让主端点超时后能尽快回退到下一个实例。
  /// 实测城市中心 2km 查询成功时约需 9~10s，超时需留足余量。
  static const Duration _endpointTimeout = Duration(seconds: 15);

  /// 解析后按距离排序保留的 POI 上限（UI 只需各分类最近若干）。
  static const int _maxFacilities = 500;

  final http.Client _client;

  FacilityRepository({http.Client? client}) : _client = client ?? http.Client();

  /// 获取距 [location] 不超过 [radius] 米的周边设施，按距离升序返回。
  ///
  /// - Overpass 正常返回但半径内无元素 → 返回 `[]`（真实空）。
  /// - 所有端点失败（网络 / 超时 / 非 200）→ 抛出 [FacilityLoadException]，
  ///   错误信息含各端点失败原因，供界面提示与重试。
  Future<List<NearbyFacility>> getNearbyFacilities(
    LatLng location, {
    double radius = defaultRadiusMeters,
  }) async {
    final query = _buildQuery(location, radius);
    final failures = <String>[];

    for (final endpoint in overpassEndpoints) {
      try {
        final response = await _client
            .post(
              Uri.parse(endpoint),
              headers: const {'User-Agent': _userAgent},
              body: {'data': query},
            )
            .timeout(_endpointTimeout);

        if (response.statusCode == 200) {
          return _parseFacilities(response.body, location, radius);
        }
        failures.add('$endpoint → HTTP ${response.statusCode}');
      } on TimeoutException {
        failures.add('$endpoint → 请求超时');
      } catch (e) {
        failures.add('$endpoint → $e');
      }
    }

    throw FacilityLoadException(
      'OSM 周边设施数据源不可用（${failures.join('；')}）。请检查网络后重试。',
    );
  }

  /// 高价值 amenity 白名单（正则，锚定整值）。
  ///
  /// 旧实现直接抓全部 `["amenity"]`，会把垃圾箱(waste_basket)、长椅、
  /// 停车位等对搬家决策无意义的要素成百上千地拉回来——既撑爆响应、
  /// 加剧主端点超时(504)，也淹没真正有用的设施。这里只保留评估相关类型。
  static const String _amenityPattern =
      r'^(hospital|clinic|doctors|dentist|pharmacy|'
      r'school|university|college|kindergarten|childcare|'
      r'bank|atm|marketplace|food_court|restaurant|fast_food|cafe|'
      r'police|fire_station|post_office|place_of_worship|'
      r'charging_station|bus_station|ferry_terminal|fuel|'
      r'library|community_centre|cinema|theatre|townhall)$';

  /// 构造 Overpass QL 查询：半径内各类高价值 amenity / 常见 shop /
  /// 车站巴士站 / 休闲绿地 / 工业用地，node 与 way 都覆盖（way 输出 center）。
  String _buildQuery(LatLng location, double radius) {
    final lat = location.latitude;
    final lng = location.longitude;
    return '''
      [out:json][timeout:25];
      (
        nwr(around:$radius, $lat, $lng)["amenity"~"$_amenityPattern"];
        node(around:$radius, $lat, $lng)["shop"~"supermarket|convenience|mall|pharmacy"];
        way(around:$radius, $lat, $lng)["shop"~"supermarket|convenience|mall|pharmacy"];
        nwr(around:$radius, $lat, $lng)["railway"~"station|halt|tram_stop"];
        node(around:$radius, $lat, $lng)["highway"="bus_stop"];
        node(around:$radius, $lat, $lng)["barrier"="toll_booth"];
        nwr(around:$radius, $lat, $lng)["leisure"~"park|garden|sports_centre|fitness_centre"];
        nwr(around:$radius, $lat, $lng)["landuse"="industrial"];
      );
      out center;
    ''';
  }

  List<NearbyFacility> _parseFacilities(
    String body,
    LatLng location,
    double radius,
  ) {
    final data = json.decode(body) as Map<String, dynamic>;
    final elements = data['elements'] as List<dynamic>? ?? const [];

    final facilities = <NearbyFacility>[];
    for (final element in elements) {
      if (element is! Map<String, dynamic>) continue;
      // node 自带 lat/lon；way/relation 经 "out center" 输出 center。
      final center = element['center'];
      final lat =
          element['lat'] ??
          (center is Map<String, dynamic> ? center['lat'] : null);
      final lon =
          element['lon'] ??
          (center is Map<String, dynamic> ? center['lon'] : null);
      if (lat is! num || lon is! num) continue;

      final facility = NearbyFacility.fromOsmJson(element, location);
      // around 按元素几何匹配，其 center 可能略超出半径，客户端精确过滤一次。
      if (facility.distance > radius) continue;
      facilities.add(facility);
    }

    facilities.sort((a, b) => a.distance.compareTo(b.distance));
    // 去重：同一设施可能同时存在 node 与 way 两个元素，按
    // 类型+类别+名称+约 111m 网格去重，避免列表里出现重复行。
    final seen = <String>{};
    final deduped = <NearbyFacility>[];
    for (final f in facilities) {
      final key =
          '${f.type}|${f.category}|${f.name}|'
          '${f.location.latitude.toStringAsFixed(3)}|${f.location.longitude.toStringAsFixed(3)}';
      if (seen.add(key)) deduped.add(f);
      if (deduped.length >= _maxFacilities) break;
    }
    return deduped;
  }
}
