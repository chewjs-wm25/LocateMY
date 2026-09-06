/// 跨数据源县名匹配工具。
///
/// 各上游表(Data.gov.my / DOSM / MoH / MOE)对同一个行政县的写法并不统一:
///   - 括号后缀: 'Petaling (Subang Jaya)'、'Timur Laut (Georgetown)'
///   - 联邦直辖区前缀: 'W.P. Kuala Lumpur' vs 'Kuala Lumpur'
///   - 缩略/并县: 'S.P. Selatan' vs 'Seberang Perai Selatan';'Tatau/Sebauh' vs 'Tatau'
///   - 用字/拆分差异: 'Ulu Langat' vs 'Hulu Langat';'Petaling' → 'Petaling Perdana/Utama'
///
/// 本工具把"查询县名"(DistrictResolver 解析结果)与"行内县名"(上游表)做宽松匹配,
/// 全部为纯函数,便于单元测试。匹配语义(行名 = 上游表里的名称):
///   1. 规范化(小写、去掉标点、去连接词 dan/and/the/of、去掉 W.P. 前缀词)后完全相等;
///   2. 行名以查询名为前缀(带括号后缀 / 拆县名 / 并县条目 / 州以下同名);
///   3. 查询名完整出现在行名中(并县条目里的组成县,如 'Sebauh' ∈ 'Tatau/Sebauh'),
///      要求查询名长度 ≥ 5 以避免误匹配;
///   4. 已知别名归一(缩写 S.P.* → Seberang Perai *、Ulu/Hulu、Kulaijaya/Kulai 等)。
///
/// 注意:不做"行名是查询名前缀"的反向匹配 —— 例如 'Sibu' 是 'Siburan' 的前缀,
/// 但两者是不同的县,反向规则会把不相关的县误当成子县聚合。
library;

class DistrictMatcher {
  const DistrictMatcher._();

  /// 纯函数:查询县名 [query] 是否可能对应行内县名 [row]。
  static bool matches(String query, String row) {
    final q = canonical(query);
    final r = canonical(row);
    if (q.isEmpty || r.isEmpty) return false;
    if (q == r) return true;
    // 行名是查询名的"扩展"(括号后缀 / 拆县名 / 并县条目)。
    if (r.startsWith(q) && q.length >= 3) return true;
    // 并县条目中的组成县(如 'Sebauh' ∈ 'Tatau/Sebauh')。
    if (q.length >= 5 && r.contains(q)) return true;
    return false;
  }

  /// 过滤并规范化后的比较键(仅测试/调试用)。
  static String canonical(String name) {
    final words = name
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    // 去连接词(整词级别安全,不会破坏 'Bandar' 之类的内嵌字母)。
    final kept = <String>[];
    for (final w in words) {
      if (_connectors.contains(w)) continue;
      kept.add(w);
    }
    // 去掉行首的联邦直辖区前缀词 w/p('W.P. Kuala Lumpur' → 'Kuala Lumpur')。
    if (kept.length >= 2 && kept[0] == 'w' && kept[1] == 'p') {
      kept.removeRange(0, 2);
    }
    final joined = kept.join('');
    return _aliases[joined] ?? joined;
  }

  static const Set<String> _connectors = {'dan', 'and', 'the', 'of'};

  /// 归一(小写去标点、去前缀/连接词)后的已知别名。
  /// 目标拼写以对应表中最常见的写法为准。
  static const Map<String, String> _aliases = {
    // Penang Seberang Perai 缩写 (DOSM 简写 vs MoH/MOE 全称)。
    'spselatan': 'seberangperaiselatan',
    'sptengah': 'seberangperaitengah',
    'sputara': 'seberangperaiutara',
    // DOSM(新) vs 传统拼写。
    'ululangat': 'hululangat',
    'uluserlangor': 'huluserlangor',
    // DOSM 'Kulai' vs MoH 'Kulaijaya'。
    'kulaijaya': 'kulai',
    // MOE PPD 写法 vs 行政区写法。
    'jpwpputrajaya': 'putrajaya',
    'jpwplabuan': 'labuan',
  };
}
