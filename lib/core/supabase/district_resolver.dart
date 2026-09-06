import 'package:latlong2/latlong.dart';
import 'supabase_client_manager.dart';

/// 将“地图上任意命名的位置”解析为数据库里真实存在的行政区名（及所在州），
/// 供社会经济 / 基础设施等分析报告页用作查询键。
///
/// 解析策略（优先级从高到低）：
/// 1. 若提供经纬度 → 调用 Supabase PostGIS RPC `match_police_district`
///    （police_districts_boundary 的行政区名与 hh_income_district 基本一致，
///     例如 Petaling / Gombak / W.P. Kuala Lumpur）。
/// 2. 否则若提供名称 → 规范化后与 hh_income_district 的真实县名做精确匹配；
///    再尝试常见别名映射（Kuala Lumpur → W.P. Kuala Lumpur 等）。
/// 3. 全部失败时回退到默认县 'Petaling'（保证界面有稳定数据源）。
class DistrictResolver {
  DistrictResolver({SupabaseClientManager? supabase})
      : _supabase = supabase ?? SupabaseClientManager();

  final SupabaseClientManager _supabase;

  /// 已知行政区集合缓存：district -> state（州全名，例如 Selangor）。
  Map<String, String>? _districts;

  /// 解析成功返回 {district, state}，解析失败返回 null。
  Future<Map<String, String>?> resolve({
    String? name,
    LatLng? latLng,
  }) async {
    final districts = await _loadDistricts();
    if (districts == null) return null;

    // 1) 坐标优先：RPC 匹配行政边界名（与 hh_income_district 命名一致）。
    if (latLng != null) {
      final matched = await _matchByCoordinates(latLng, districts);
      if (matched != null) return matched;
    }

    // 2) 名称匹配。
    if (name != null && name.trim().isNotEmpty) {
      final byName = _matchByName(name, districts);
      if (byName != null) return byName;
    }

    // 3) 兜底默认值（界面历史默认即 Petaling）。
    if (districts.containsKey('Petaling')) {
      return {'district': 'Petaling', 'state': districts['Petaling']!};
    }
    return null;
  }

  Future<Map<String, String>?> _matchByCoordinates(
    LatLng latLng,
    Map<String, String> districts,
  ) async {
    try {
      final result = await _supabase.rpc('match_police_district', params: {
        'lat': latLng.latitude,
        'lng': latLng.longitude,
      });
      if (result is List && result.isNotEmpty) {
        final raw = (result.first as Map).cast<String, dynamic>();
        final district = raw['name']?.toString().trim();
        if (district != null && district.isNotEmpty) {
          final state = districts[district] ?? _stateCodeToFull(raw['state']?.toString());
          if (districts.containsKey(district)) {
            return {'district': district, 'state': state ?? ''};
          }
          // 少数边界名与收入表拼写不一致（如 Larut Dan Matang），尝试就近匹配。
          final fuzzy = _fuzzyFind(district, districts);
          if (fuzzy != null) return fuzzy;
          return {'district': district, 'state': state ?? ''};
        }
      }
    } catch (e) {
      // RPC 不可用时降级到名称匹配。
      assert(() {
        // ignore: avoid_print
        print('DistrictResolver.match_police_district failed: $e');
        return true;
      }());
    }
    return null;
  }

  Map<String, String>? _matchByName(String name, Map<String, String> districts) {
    final norm = _normalize(name);
    // 精确匹配。
    for (final d in districts.keys) {
      if (_normalize(d) == norm) {
        return {'district': d, 'state': districts[d]!};
      }
    }
    // 包含匹配：输入名称内嵌真实县名（例如 “Petaling Jaya” → Petaling）。
    Map<String, String>? best;
    var bestLen = 0;
    for (final d in districts.keys) {
      final dn = _normalize(d);
      if (norm.contains(dn) && dn.length > bestLen) {
        best = {'district': d, 'state': districts[d]!};
        bestLen = dn.length;
      }
    }
    if (best != null) return best;
    // 常见别名（中英文城市名 → 行政县）。
    const aliases = {
      'Kuala Lumpur': 'W.P. Kuala Lumpur',
      '吉隆坡': 'W.P. Kuala Lumpur',
      'KL': 'W.P. Kuala Lumpur',
      'Putrajaya': 'W.P. Putrajaya',
      '布城': 'W.P. Putrajaya',
      'Labuan': 'W.P. Labuan',
      '纳闽': 'W.P. Labuan',
      'Johor Bahru': 'Johor Bahru',
      'JB': 'Johor Bahru',
      '新山': 'Johor Bahru',
      'George Town': 'Timur Laut',
      '乔治市': 'Timur Laut',
      'Ipoh': 'Kinta',
      '怡保': 'Kinta',
      'Kuching': 'Kuching',
      '古晋': 'Kuching',
      'Kota Kinabalu': 'Kota Kinabalu',
      '亚庇': 'Kota Kinabalu',
    };
    final alias = aliases[name.trim()];
    if (alias != null && districts.containsKey(alias)) {
      return {'district': alias, 'state': districts[alias]!};
    }
    return _fuzzyFind(name, districts);
  }

  Map<String, String>? _fuzzyFind(String district, Map<String, String> districts) {
    final target = _normalize(district);
    String? bestKey;
    var bestScore = 0;
    for (final d in districts.keys) {
      final dn = _normalize(d);
      var score = 0;
      if (dn == target) score = 1000;
      else if (dn.contains(target) || target.contains(dn)) score = target.length > dn.length ? dn.length : target.length;
      if (score > bestScore) {
        bestScore = score;
        bestKey = d;
      }
    }
    if (bestKey != null && bestScore > 2) {
      return {'district': bestKey, 'state': districts[bestKey]!};
    }
    return null;
  }

  Future<Map<String, String>?> _loadDistricts() async {
    if (_districts != null) return _districts;
    try {
      final rows = await _supabase.from('hh_income_district').select('state, district');
      final map = <String, String>{};
      for (final row in rows) {
        final d = (row['district'] as String?)?.trim();
        final s = (row['state'] as String?)?.trim();
        if (d != null && d.isNotEmpty) map[d] = s ?? '';
      }
      _districts = map;
      return map;
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('DistrictResolver load failed: $e');
        return true;
      }());
      return null;
    }
  }

  String _normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]'), '');

  static String? _stateCodeToFull(String? code) {
    switch (code) {
      case 'SGR': return 'Selangor';
      case 'JHR': return 'Johor';
      case 'KDH': return 'Kedah';
      case 'KTN': return 'Kelantan';
      case 'MLK': return 'Melaka';
      case 'NSN': return 'Negeri Sembilan';
      case 'PHG': return 'Pahang';
      case 'PRK': return 'Perak';
      case 'PLS': return 'Perlis';
      case 'PNG': return 'Pulau Pinang';
      case 'SBH': return 'Sabah';
      case 'SWK': return 'Sarawak';
      case 'TRG': return 'Terengganu';
      case 'KUL': return 'W.P. Kuala Lumpur';
      case 'LBN': return 'W.P. Labuan';
      case 'PJY': return 'W.P. Putrajaya';
      default: return null;
    }
  }
}
