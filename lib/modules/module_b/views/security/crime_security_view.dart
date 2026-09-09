import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:locate_my/core/app_colors.dart';
import 'package:locate_my/shared/widgets/bento_card.dart';
import 'package:locate_my/shared/widgets/status_badge.dart';
import 'package:locate_my/shared/widgets/mini_map.dart';
import 'package:locate_my/generated/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:locate_my/modules/module_a/location_api.dart';
import 'package:locate_my/modules/module_a/hazard_api.dart';
import 'package:locate_my/modules/module_b/view_models/property/property_view_model.dart';
import 'package:locate_my/modules/module_b/view_models/security/security_view_model.dart';
import 'package:locate_my/modules/module_b/repositories/security/security_repository.dart';
import 'package:locate_my/app/views/app_shell.dart';

import 'package:locate_my/shared/widgets/analysis_location_selector.dart';

import 'package:locate_my/modules/module_b/views/property/add_property_screen.dart';

import 'package:locate_my/modules/module_b/models/property/property_inspection.dart';
import 'package:locate_my/modules/module_b/views/property/property_detail_screen.dart';
import 'package:locate_my/modules/module_b/views/property/property_archive_screen.dart';

class CrimeSecurityView extends StatelessWidget {
  const CrimeSecurityView({super.key});

  void _navigateToAddProperty(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
    );
  }

  void _navigateToArchive(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PropertyArchiveScreen()),
    );
  }

  void _navigateToDetail(BuildContext context, PropertyInspection inspection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailScreen(inspection: inspection),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = Provider.of<LocationViewModel>(context);
    final propertyViewModel = Provider.of<PropertyViewModel>(context);
    final securityProvider = Provider.of<SecurityViewModel>(context);

    final latLng =
        locationProvider.selectedLocation ?? const LatLng(3.1390, 101.6869);
    final securityData = securityProvider.securityData;
    final isLoading = securityProvider.isLoading;

    // Trigger fetch if not loaded (幂等：同一坐标只请求一次)
    final locationKey =
        '${latLng.latitude.toStringAsFixed(3)}_${latLng.longitude.toStringAsFixed(3)}';
    if (!isLoading && securityProvider.requestKey != locationKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        securityProvider.loadSecurityData(latLng.latitude, latLng.longitude);
      });
    }

    final showError =
        !isLoading &&
        securityProvider.requestKey == locationKey &&
        securityData == null &&
        securityProvider.error != null;
    final hasCurrentData =
        securityData != null && securityProvider.requestKey == locationKey;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleSecurity)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddProperty(context),
        icon: const Icon(Icons.add_home_work_rounded),
        label: Text(l10n.addProperty),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
      ),
      body: showError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 44,
                      color: AppColors.textMutedLight,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '该位置暂无治安数据',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      securityProvider.error ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => securityProvider.loadSecurityData(
                        latLng.latitude,
                        latLng.longitude,
                        force: true,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              ),
            )
          : (isLoading || !hasCurrentData)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Inspection Portfolio
                  if (propertyViewModel.inspections.isNotEmpty) ...[
                    InkWell(
                      onTap: () => _navigateToArchive(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Text(
                              l10n.propertyPortfolio,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.textMutedDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...propertyViewModel.inspections
                        .take(3)
                        .map(
                          (property) => BentoCard(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: InkWell(
                              onTap: () => _navigateToDetail(context, property),
                              child: Row(
                                children: [
                                  if (property.hasFloodHistory)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Icon(
                                        Icons.warning_amber_rounded,
                                        color: AppColors.danger,
                                        size: 16,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      property.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (property.securityScore != null)
                                    StatusBadge(
                                      label: property.securityScore!.toString(),
                                      type: property.securityScore! >= 7
                                          ? StatusType.success
                                          : StatusType.warning,
                                    ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: AppColors.textMutedDark,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    if (propertyViewModel.inspections.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          'and ${propertyViewModel.inspections.length - 3} more properties...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMutedDark,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],

                  const AnalysisLocationSelector(),
                  const SizedBox(height: 16),

                  // Map Bento（可交互：警区边界图层 + 附近众包隐患标记）
                  _SafetyMapCard(
                    latLng: latLng,
                    districtName:
                        securityData['district_name']?.toString() ?? '',
                    securityScore: (securityData['security_score'] as num?)
                        ?.toDouble(),
                    onOpenMainMap: () {
                      locationProvider.moveTo(latLng);
                      final appShellState = context
                          .findAncestorStateOfType<AppShellState>();
                      if (appShellState != null) {
                        appShellState.onItemTapped(1);
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Safety Rating Grid
                  BentoCard(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.overallSafetyIndex,
                          style: const TextStyle(
                            color: AppColors.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          securityData['security_score'] is num
                              ? (securityData['security_score'] as num)
                                    .toStringAsFixed(1)
                              : '—',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color:
                                (securityData['security_score'] as num? ??
                                        8.0) >
                                    8
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                        Text(
                          securityData['district_name'] != null
                              ? '${securityData['district_name']} · 最近一年罪案 ${securityData['total_crimes'] ?? '—'} 宗'
                              : '',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Crime Type Chips（分类来自真实 crime_stats，非写死）
                  _CrimeTrendCard(securityData: securityData, l10n: l10n),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

/// 治安趋势卡：分类选择 chip + 真实 fl_chart 折线图。
/// 数据全部来自 SecurityRepository 返回的 trend / trend_by_category，
/// 年份范围与折线点都由数据库决定。
class _CrimeTrendCard extends StatefulWidget {
  final Map<String, dynamic> securityData;
  final AppLocalizations l10n;

  const _CrimeTrendCard({required this.securityData, required this.l10n});

  @override
  State<_CrimeTrendCard> createState() => _CrimeTrendCardState();
}

class _CrimeTrendCardState extends State<_CrimeTrendCard> {
  String? _selectedCategory; // null = 全部

  @override
  void initState() {
    super.initState();
    _selectedCategory = null;
  }

  List<Map<String, dynamic>> get _series {
    final trend = widget.securityData['trend'] as List? ?? [];
    if (_selectedCategory == null) {
      return trend.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    final byCategory = (widget.securityData['trend_by_category'] as Map?)
        ?.cast<String, dynamic>();
    final series = byCategory?[_selectedCategory] as List? ?? [];
    return series.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  String _categoryLabel(String key) {
    switch (key) {
      case 'assault':
        return widget.l10n.violentCrime;
      case 'property':
        return widget.l10n.propertyCrime;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final breakdown =
        (widget.securityData['category_breakdown'] as Map?)
            ?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final series = _series;
    final years = series
        .map((e) => e['year']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    final maxValue = series.fold<int>(0, (p, e) {
      final v = (e['crimes'] as num?)?.toInt() ?? 0;
      return v > p ? v : p;
    });

    return BentoCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.crimeTypeFocus,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            // 分类 chips：先“全部”，再是 DB 里真实出现的分类。
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('全部'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                  selectedColor: AppColors.primaryContainer,
                  checkmarkColor: AppColors.primaryBase,
                ),
                ...breakdown.keys.map((key) {
                  final count = breakdown[key];
                  return FilterChip(
                    label: Text('${_categoryLabel(key)} ($count)'),
                    selected: _selectedCategory == key,
                    onSelected: (_) => setState(() => _selectedCategory = key),
                    selectedColor: AppColors.primaryContainer,
                    checkmarkColor: AppColors.primaryBase,
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.crimeTrend,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  years.isEmpty ? '' : '${years.first} - ${years.last}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceSubLight,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
              child: series.isEmpty || maxValue == 0
                  ? const Center(
                      child: Text(
                        '该地区暂无犯罪统计数据',
                        style: TextStyle(
                          color: AppColors.textMutedLight,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i >= 0 && i < years.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      years[i],
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 0,
                        maxY: (maxValue * 1.2).toDouble().clamp(
                          maxValue.toDouble(),
                          double.infinity,
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: series
                                .asMap()
                                .entries
                                .map(
                                  (e) => FlSpot(
                                    e.key.toDouble(),
                                    (e.value['crimes'] as num).toDouble(),
                                  ),
                                )
                                .toList(),
                            isCurved: true,
                            color: AppColors.primaryBaseAlternative,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryBaseAlternative.withValues(
                                    alpha: 0.25,
                                  ),
                                  AppColors.primaryBaseAlternative.withValues(
                                    alpha: 0.0,
                                  ),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 治安页“可交互地图卡”：
/// - 默认叠加真实警区边界（police_districts_boundary，颜色随安全评分）；
/// - 右上角图标可切换“警区边界”与“10km 内众包隐患”图层；
/// - 隐患点可直接点击查看详情；
/// - 地图本身支持拖拽/缩放，右上角仍保留跳回主地图入口。
class _SafetyMapCard extends StatefulWidget {
  final LatLng latLng;
  final String districtName;
  final double? securityScore;
  final VoidCallback onOpenMainMap;

  const _SafetyMapCard({
    required this.latLng,
    required this.districtName,
    required this.securityScore,
    required this.onOpenMainMap,
  });

  @override
  State<_SafetyMapCard> createState() => _SafetyMapCardState();
}

class _SafetyMapCardState extends State<_SafetyMapCard> {
  bool _showBoundary = true;
  bool _showHazards = false;

  List<Polygon<Object>>? _boundaryPolygons;

  @override
  void initState() {
    super.initState();
    _loadBoundary();
  }

  Future<void> _loadBoundary() async {
    if (widget.districtName.isEmpty) return;
    final boundary = await SecurityRepository().fetchPoliceDistrictBoundary(
      widget.districtName,
    );
    if (!mounted) return;
    final geom = boundary?['boundary_geom'];
    if (geom is Map<String, dynamic>) {
      final (fill, stroke) = _boundaryColors(widget.securityScore);
      setState(() {
        _boundaryPolygons = _geoJsonToPolygons(geom, fill, stroke);
      });
    }
  }

  (Color, Color) _boundaryColors(double? score) {
    if (score == null)
      return (AppColors.info.withValues(alpha: 0.10), AppColors.info);
    if (score >= 8) {
      return (AppColors.success.withValues(alpha: 0.10), AppColors.success);
    }
    if (score >= 6) {
      return (AppColors.warning.withValues(alpha: 0.12), AppColors.warning);
    }
    return (AppColors.danger.withValues(alpha: 0.10), AppColors.danger);
  }

  List<HazardMarker> _nearbyHazards(HazardViewModel provider) {
    const double threshold = 10000; // 10km，与主地图口径一致
    final center = widget.latLng;
    final distance = const Distance();
    return provider.hazards
        .where((h) => distance.distance(h.location, center) <= threshold)
        .toList();
  }

  List<Marker> _hazardMarkers(List<HazardMarker> hazards) {
    return hazards
        .map(
          (h) => Marker(
            key: ValueKey('safety_hazard_${h.id}'),
            point: h.location,
            width: 34,
            height: 34,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => _showHazardSheet(h),
              child: Container(
                decoration: BoxDecoration(
                  color: h.type.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: h.type.color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(h.type.icon, color: Colors.white, size: 16),
              ),
            ),
          ),
        )
        .toList();
  }

  void _showHazardSheet(HazardMarker hazard) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hazard.type.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hazard.type.icon,
                    color: hazard.type.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hazard.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '众包隐患 · ${hazard.type.name.toUpperCase()} · 位于所选位置 10km 内',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMutedLight,
              ),
            ),
            if (hazard.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                hazard.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hazardProvider = Provider.of<HazardViewModel>(context);
    final hazards = _nearbyHazards(hazardProvider);

    final polygons = _showBoundary
        ? (_boundaryPolygons ?? const <Polygon<Object>>[])
        : const <Polygon<Object>>[];

    return BentoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${l10n.safetyMapLayer} (${widget.districtName.isEmpty ? '' : widget.districtName})',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.securityScore != null) ...[
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: widget.securityScore! >= 8 ? '安全' : '关注',
                    type: widget.securityScore! >= 8
                        ? StatusType.success
                        : StatusType.warning,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: MiniMap(
              center: widget.latLng,
              zoom: 11.5,
              height: 240,
              interactive: true,
              onTap: widget.onOpenMainMap,
              polygons: polygons,
              markers: _showHazards ? _hazardMarkers(hazards) : const [],
              actions: [
                MiniMapAction(
                  icon: Icons.map_outlined,
                  tooltip: '警区边界',
                  active: _showBoundary,
                  activeColor: _boundaryColors(widget.securityScore).$2,
                  onTap: () => setState(() => _showBoundary = !_showBoundary),
                ),
                MiniMapAction(
                  icon: Icons.warning_amber_rounded,
                  tooltip: '众包隐患',
                  active: _showHazards,
                  activeColor: AppColors.warning,
                  onTap: () => setState(() => _showHazards = !_showHazards),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Icon(
                  _showBoundary && polygons.isNotEmpty
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 13,
                  color: _showBoundary && polygons.isNotEmpty
                      ? AppColors.success
                      : AppColors.textMutedLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '警区边界 (PDRM) · 10km 内 ${hazards.length} 个众包隐患'
                    '${_showBoundary && polygons.isEmpty && widget.districtName.isNotEmpty ? '（边界加载中/暂缺）' : ''}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMutedLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 把 PostgREST 返回的 GeoJSON 几何（Polygon/MultiPolygon）转成 flutter_map
/// 多边形列表；坐标数组顺序恒为 [经度, 纬度]，转 LatLng 时需交换。
List<Polygon<Object>> _geoJsonToPolygons(
  Map<String, dynamic> geom,
  Color fill,
  Color stroke,
) {
  final result = <Polygon<Object>>[];
  final type = geom['type'];
  final raw = geom['coordinates'];

  List<dynamic> polygonsCoords;
  if (type == 'Polygon' && raw is List) {
    polygonsCoords = [raw];
  } else if (type == 'MultiPolygon' && raw is List) {
    polygonsCoords = raw.cast<dynamic>();
  } else {
    return result;
  }

  for (final polygonRaw in polygonsCoords) {
    if (polygonRaw is! List || polygonRaw.isEmpty) continue;
    final rings = polygonRaw.cast<List<dynamic>>();
    if (rings.isEmpty) continue;
    final outerRaw = rings.first;
    if (outerRaw.length < 3) continue;

    List<LatLng> toPoints(List<dynamic> ring) {
      return ring
          .whereType<List<dynamic>>()
          .where((c) => c.length >= 2)
          .map(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();
    }

    final outer = toPoints(outerRaw);
    if (outer.length < 3) continue;
    final holes = rings
        .skip(1)
        .map(toPoints)
        .where((h) => h.length >= 3)
        .toList();
    result.add(
      Polygon<Object>(
        points: outer,
        holePointsList: holes.isEmpty ? null : holes,
        color: fill,
        borderColor: stroke,
        borderStrokeWidth: 1.6,
      ),
    );
  }
  return result;
}
