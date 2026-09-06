import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_colors.dart';
import '../../models/nearby_facility.dart';
import '../../providers/nearby_facilities_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';

import '../../widgets/analysis_location_selector.dart';

class NearbyFacilitiesView extends StatefulWidget {
  const NearbyFacilitiesView({super.key});

  @override
  State<NearbyFacilitiesView> createState() => _NearbyFacilitiesViewState();
}

class _NearbyFacilitiesViewState extends State<NearbyFacilitiesView> {
  LatLng? _lastLoadedLocation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = context.watch<LocationProvider>().selectedLocation;
    if (location != null && location != _lastLoadedLocation) {
      _lastLoadedLocation = location;
      context.read<NearbyFacilitiesProvider>().loadNearbyFacilities(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
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
      body: Consumer<NearbyFacilitiesProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AnalysisLocationSelector(),
                const SizedBox(height: 16),
                _buildCategorySection(
                  title: '医疗健康 (Healthcare)',
                  icon: Icons.local_hospital_rounded,
                  color: const Color(0xFFEF4444),
                  facilities: provider.facilities.where((f) => f.category == FacilityCategory.healthcare).toList(),
                  hardcodedData: [
                    'KKM 官方医院名录覆盖',
                    '突发疾病救治便利度: 极高',
                  ],
                ),
                const SizedBox(height: 16),
                _buildCategorySection(
                  title: '教育资源 (Education)',
                  icon: Icons.school_rounded,
                  color: const Color(0xFF2563EB),
                  facilities: provider.facilities.where((f) => f.category == FacilityCategory.education).toList(),
                  hardcodedData: [
                    'KPM 官方学校名录对接',
                    '学区房决策参考评分: 8.5/10',
                  ],
                ),
                const SizedBox(height: 16),
                _buildCategorySection(
                  title: '日常生活 (Living & Amenities)',
                  icon: Icons.shopping_basket_rounded,
                  color: const Color(0xFF10B981),
                  facilities: provider.facilities.where((f) => f.category == FacilityCategory.living).toList(),
                  hardcodedData: [
                    '品牌超市 (Lotus\'s, Jaya Grocer) 覆盖',
                    '社区便利店 (99 Speedmart) 密集',
                  ],
                ),
                const SizedBox(height: 16),
                _buildCategorySection(
                  title: '交通出行 (Transport)',
                  icon: Icons.train_rounded,
                  color: const Color(0xFF06B6D4),
                  facilities: provider.facilities.where((f) => f.category == FacilityCategory.transport).toList(),
                  hardcodedData: [
                    '交通部 (MOT) 站点数据实时接入',
                    '无车族/通勤族刚需匹配',
                  ],
                ),
                const SizedBox(height: 16),
                _buildCategorySection(
                  title: '安全与服务 (Safety & Services)',
                  icon: Icons.security_rounded,
                  color: const Color(0xFFF59E0B),
                  facilities: provider.facilities.where((f) => f.category == FacilityCategory.safety).toList(),
                  hardcodedData: [
                    'PDRM 警区划分及犯罪率指数同步',
                    '消防局 (BOMBA) 部署数据',
                  ],
                ),
                const SizedBox(height: 16),
                _buildCategorySection(
                  title: '灾害与环境风险 (Risk)',
                  icon: Icons.warning_rounded,
                  color: Colors.brown,
                  facilities: provider.facilities.where((f) => f.category == FacilityCategory.risk).toList(),
                  hardcodedData: [
                    'JPS 水利局历史水灾高风险区评估',
                    '工厂噪音与废气污染隔离分析',
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required IconData icon,
    required Color color,
    required List<NearbyFacility> facilities,
    required List<String> hardcodedData,
  }) {
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
          const SizedBox(height: 16),
          // 政府数据补充 / 硬编码考量点
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Surface Sub
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: hardcodedData.map((text) => Padding(
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
              child: Center(child: Text('当前半径 2km 内未发现相关设施', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))),
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
      'bank': '银行',
      'atm': 'ATM',
      'station': '车站',
      'bus_stop': '巴士站',
      'police': '警局',
      'fire_station': '消防局',
      'post_office': '邮局',
      'park': '公园',
      'place_of_worship': '宗教场所',
    };
    return map[type] ?? type;
  }
}
