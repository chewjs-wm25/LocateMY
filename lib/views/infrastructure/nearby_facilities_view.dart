import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../models/nearby_facility.dart';
import '../../providers/nearby_facilities_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';

import '../../widgets/analysis_location_selector.dart';

/// 周边设施 (OSM) 评估页。
///
/// 数据链路修复后的状态约定：
/// - 加载失败（Overpass 全端点不可用 / 网络错误）→ 错误卡 + 重试，绝不伪装成"无设施"；
/// - 正常返回但为空 → 整页空态（注明 OSM 收录局限）；
/// - 成功 → 顶部统计 + 各分类设施卡片（个别分类为空仅该类显示空提示）。
class NearbyFacilitiesView extends StatefulWidget {
  const NearbyFacilitiesView({super.key});

  @override
  State<NearbyFacilitiesView> createState() => _NearbyFacilitiesViewState();
}

class _NearbyFacilitiesViewState extends State<NearbyFacilitiesView> {
  static String _locationKey(LatLng? location) {
    if (location == null) return '';
    return '${location.latitude.toStringAsFixed(3)}|${location.longitude.toStringAsFixed(3)}';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = context.watch<LocationProvider>().selectedLocation;
    final provider = context.read<NearbyFacilitiesProvider>();
    if (location == null || provider.isLoading) return;
    // 幂等触发：同坐标成功/失败后不重复自动请求（重试交给按钮 force）。
    final key = _locationKey(location);
    if (provider.requestKey != key) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<NearbyFacilitiesProvider>().loadNearbyFacilities(location);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final provider = context.watch<NearbyFacilitiesProvider>();
    final locationName = locationProvider.selectedName ?? '已选地点';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('周边设施评估', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(locationName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AnalysisLocationSelector(),
          ),
          Expanded(child: _buildContent(provider, locationProvider)),
        ],
      ),
    );
  }

  Widget _buildContent(
    NearbyFacilitiesProvider provider,
    LocationProvider locationProvider,
  ) {
    final location = locationProvider.selectedLocation;

    if (location == null) {
      return const Center(
        child: Text('请先在地图上选择一个地点', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
      );
    }

    final key = _locationKey(location);
    final current = provider.requestKey == key;

    // 加载中：保持选择器可见，内容区转圈。
    if (provider.isLoading && !provider.hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    // 失败（当前地点）：错误卡 + 重试。
    if (current && provider.error != null && !provider.hasLoaded) {
      return _buildError(provider, location);
    }

    // 真实空结果（Overpass 200 但无元素）。
    if (current && provider.hasLoaded && provider.facilities.isEmpty) {
      return _buildEmpty(provider, location);
    }

    // 尚未加载到当前地点数据（如刚切换且未触发成功）→ 空壳提示。
    if (!current || (!provider.hasLoaded && provider.error == null)) {
      return const Center(
        child: Text('正在准备数据…', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
      );
    }

    final facilities = provider.facilities;
    final coveredCategories = <FacilityCategory>{for (final f in facilities) f.category};
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryBar(facilities.length, coveredCategories.length),
          const SizedBox(height: 16),
          _buildCategorySection(
            title: '医疗健康 (Healthcare)',
            icon: Icons.local_hospital_rounded,
            color: const Color(0xFFEF4444),
            facilities: facilities.where((f) => f.category == FacilityCategory.healthcare).toList(),
          ),
          const SizedBox(height: 16),
          _buildCategorySection(
            title: '教育资源 (Education)',
            icon: Icons.school_rounded,
            color: const Color(0xFF2563EB),
            facilities: facilities.where((f) => f.category == FacilityCategory.education).toList(),
          ),
          const SizedBox(height: 16),
          _buildCategorySection(
            title: '日常生活 (Living & Amenities)',
            icon: Icons.shopping_basket_rounded,
            color: const Color(0xFF10B981),
            facilities: facilities.where((f) => f.category == FacilityCategory.living).toList(),
          ),
          const SizedBox(height: 16),
          _buildCategorySection(
            title: '交通出行 (Transport)',
            icon: Icons.train_rounded,
            color: const Color(0xFF06B6D4),
            facilities: facilities.where((f) => f.category == FacilityCategory.transport).toList(),
          ),
          const SizedBox(height: 16),
          _buildCategorySection(
            title: '安全与服务 (Safety & Services)',
            icon: Icons.security_rounded,
            color: const Color(0xFFF59E0B),
            facilities: facilities.where((f) => f.category == FacilityCategory.safety).toList(),
          ),
          const SizedBox(height: 16),
          _buildCategorySection(
            title: '休闲与绿地 (Leisure & Parks)',
            icon: Icons.park_rounded,
            color: const Color(0xFF8B5CF6),
            facilities: facilities.where((f) => f.category == FacilityCategory.leisure).toList(),
          ),
          const SizedBox(height: 16),
          _buildCategorySection(
            title: '灾害与环境风险 (Risk)',
            icon: Icons.warning_rounded,
            color: Colors.brown,
            facilities: facilities.where((f) => f.category == FacilityCategory.risk).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            '数据源：OpenStreetMap Overpass（实时抓取）· 搜索半径 2km。'
            '仅收录 OSM 上已标记的设施，实际收录与更新可能滞后。',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.6),
          ),
        ],
      ),
    );
  }

  /// 顶部统计条：证明当前地点确实拉到真实数据。
  Widget _buildSummaryBar(int total, int categoryCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '已从 OSM 获取 $total 个设施点，覆盖 $categoryCount 类设施',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(NearbyFacilitiesProvider provider, LatLng location) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text('周边设施 (OSM) 加载失败', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              provider.error ?? '',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context
                  .read<NearbyFacilitiesProvider>()
                  .loadNearbyFacilities(location, force: true),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(NearbyFacilitiesProvider provider, LatLng location) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 44, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text('该位置 2km 半径内暂无已收录设施',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 6),
            const Text(
              '数据来自 OpenStreetMap，该区域可能确实设施稀疏，'
              '也可能是 OSM 尚未收录。可切换其它地点或稍后重试。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<NearbyFacilitiesProvider>()
                  .loadNearbyFacilities(location, force: true),
              icon: const Icon(Icons.refresh),
              label: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required IconData icon,
    required Color color,
    required List<NearbyFacility> facilities,
  }) {
    // 由真实 POI 数据推导的概况（最近距离 / 覆盖类别），替代写死的描述。
    final nearest = facilities.isEmpty
        ? null
        : facilities.reduce((a, b) => a.distance < b.distance ? a : b);
    final typeCounts = <String, int>{};
    for (final f in facilities) {
      typeCounts[f.type] = (typeCounts[f.type] ?? 0) + 1;
    }
    final summaryLines = <String>[
      if (nearest != null)
        '最近：${nearest.name} · ${nearest.distance.toInt()}m',
      if (typeCounts.isNotEmpty) '覆盖 ${typeCounts.length} 种类型',
    ];
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              StatusBadge(
                label: '${facilities.length} 个点',
                type: _getStatusTypeFromColor(color),
              ),
            ],
          ),
          if (summaryLines.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), // Surface Sub
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: summaryLines.map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF475569)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
          if (facilities.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('实时 POI (OSM)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
            const SizedBox(height: 8),
            ...facilities.take(3).map((f) => _buildMiniFacilityItem(f)),
            if (facilities.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('以及其他 ${facilities.length - 3} 个地点...', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
              ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('该类别 2km 半径内暂无已收录设施',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniFacilityItem(NearbyFacility facility) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(facility.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                Text(
                  '${_getTypeName(facility.type)} • ${facility.distance.toInt()}m',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFE2E8F0)),
        ],
      ),
    );
  }

  StatusType _getStatusTypeFromColor(Color color) {
    if (color == const Color(0xFFEF4444)) return StatusType.danger;
    if (color == const Color(0xFF10B981)) return StatusType.success;
    if (color == const Color(0xFFF59E0B)) return StatusType.warning;
    return StatusType.info;
  }

  String _getTypeName(String type) {
    final map = {
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
      'mall': '商场',
      'supermarket': '超市',
      'convenience': '便利店',
      'marketplace': '市场',
      'food_court': '熟食中心',
      'restaurant': '餐厅',
      'fast_food': '快餐店',
      'cafe': '咖啡馆',
      'fuel': '加油站',
      'bank': '银行',
      'atm': 'ATM',
      'station': '车站',
      'halt': '铁路小站',
      'tram_stop': '电车站',
      'bus_stop': '巴士站',
      'bus_station': '公交总站',
      'ferry_terminal': '渡轮码头',
      'toll_booth': '收费站',
      'charging_station': '充电站',
      'police': '警局',
      'fire_station': '消防局',
      'post_office': '邮局',
      'park': '公园',
      'garden': '花园',
      'sports_centre': '运动中心',
      'fitness_centre': '健身中心',
      'library': '图书馆',
      'community_centre': '社区中心',
      'cinema': '电影院',
      'theatre': '剧院',
      'townhall': '市政厅',
      'place_of_worship': '宗教场所',
      'industrial': '工业区',
    };
    return map[type] ?? type;
  }
}
