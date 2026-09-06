import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/mini_map.dart';
import '../../generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/location_provider.dart';
import '../../providers/analysis/transit_provider.dart';
import '../app_shell.dart';

import '../../widgets/analysis_location_selector.dart';

class TransportationView extends StatefulWidget {
  const TransportationView({super.key});

  @override
  State<TransportationView> createState() => _TransportationViewState();
}

class _TransportationViewState extends State<TransportationView> {
  /// 站点图层开关（默认显示真实站点图标）。
  bool _showStops = true;

  /// 当前选中的站点（地图上高亮 + 底部信息条展示）。
  Map<String, dynamic>? _selectedStop;

  void _ensureLoaded(TransitProvider provider, LocationProvider locationProvider) {
    final latLng = locationProvider.selectedLocation ?? const LatLng(3.1390, 101.6869);
    final key = '${latLng.latitude}_${latLng.longitude}';
    if (!provider.isLoading && provider.requestKey != key) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.loadNearbyStops(latLng.latitude, latLng.longitude);
      });
    }
  }

  void _selectStop(Map<String, dynamic> stop) {
    setState(() => _selectedStop = stop);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = Provider.of<LocationProvider>(context);
    final transitProvider = Provider.of<TransitProvider>(context);

    final latLng = locationProvider.selectedLocation ?? const LatLng(3.1390, 101.6869);
    final stops = transitProvider.nearbyStops;
    final isLoading = transitProvider.isLoading;

    _ensureLoaded(transitProvider, locationProvider);

    final key =
        '${latLng.latitude.toStringAsFixed(3)}_${latLng.longitude.toStringAsFixed(3)}';
    final hasDataForKey = transitProvider.requestKey == key && transitProvider.hasLoaded;
    final showError = !isLoading &&
        transitProvider.error != null &&
        transitProvider.requestKey == key;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleTransport)),
      body: showError
          ? _buildError(context, l10n, transitProvider, latLng)
          : (isLoading || !hasDataForKey)
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AnalysisLocationSelector(),
                      const SizedBox(height: 16),
                      _buildConnectivityCard(context, l10n, stops, latLng),
                      const SizedBox(height: 16),
                      _buildStationsCard(context, l10n, stops, latLng),
                      const SizedBox(height: 16),
                      _buildMapCard(context, l10n, stops, latLng, locationProvider),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError(BuildContext context, AppLocalizations l10n,
      TransitProvider provider, LatLng latLng) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.textMutedLight),
            const SizedBox(height: 12),
            const Text('该位置暂无公交站点数据', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              provider.error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  provider.loadNearbyStops(latLng.latitude, latLng.longitude, force: true),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 连通性评分由真实站点数据派生：1.5km 内 60 个站点视为满分（与 ICI 同口径）。
  double _scoreFor(List<Map<String, dynamic>> stops) {
    if (stops.isEmpty) return 0;
    final s = (stops.length * (100 / 60)).clamp(0.0, 100.0);
    return s;
  }

  Widget _buildConnectivityCard(BuildContext context, AppLocalizations l10n,
      List<Map<String, dynamic>> stops, LatLng latLng) {
    final score = _scoreFor(stops);
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.connectivityScore,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: score >= 70 ? l10n.highlyConvenient : '一般',
                type: score >= 70 ? StatusType.accent : StatusType.warning,
                icon: score >= 70 ? Icons.bolt_rounded : null,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                score.toStringAsFixed(0),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (score / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppColors.accentContainer,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stops.isEmpty
                          ? '半径 1.5km 内暂无站点'
                          : '半径 1.5km 内找到 ${stops.length} 个站点',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStationsCard(BuildContext context, AppLocalizations l10n,
      List<Map<String, dynamic>> stops, LatLng latLng) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.nearbyStations, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        BentoCard(
          padding: EdgeInsets.zero,
          child: stops.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('附近暂无已收录站点',
                        style: TextStyle(color: AppColors.textMutedLight, fontSize: 13)),
                  ),
                )
              : Column(
                  children: List.generate(stops.length, (index) {
                    final stop = stops[index];
                    final isBus =
                        (stop['transit_type']?.toString() ?? '').toLowerCase().contains('bus');
                    final stopId = stop['stop_id']?.toString() ?? 'stop_$index';
                    final isSelected = _selectedStop != null &&
                        _selectedStop!['stop_id']?.toString() == stopId;
                    return Column(
                      children: [
                        _buildStationItem(
                          context,
                          l10n,
                          isBus ? Icons.directions_bus_rounded : Icons.train_rounded,
                          stop['stop_name']?.toString() ?? '未知站点',
                          _transitLabel(stop['transit_type']?.toString() ?? ''),
                          '${(stop['distance_meters'] as num).toInt()}m',
                          isBus ? AppColors.success : AppColors.primaryBase,
                          isSelected: isSelected,
                          onTap: () => _selectStop(stop),
                        ),
                        if (index != stops.length - 1)
                          const Divider(height: 1, color: AppColors.borderLight),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }

  String _transitLabel(String raw) {
    // 真实值如 'Rapid Rail KL (MRT/LRT/Monorail)' / 'Rapid Bus KL'
    if (raw.toLowerCase().contains('bus')) return 'Bus';
    return 'Rail';
  }

  /// 真实站点是否可当作图标标到地图（transit_repository 已带经纬度）。
  bool _isBusStop(Map<String, dynamic> stop) =>
      (stop['transit_type']?.toString() ?? '').toLowerCase().contains('bus');

  List<Marker> _stopMarkers(List<Map<String, dynamic>> stops) {
    return stops.map((stop) {
      final lat = (stop['latitude'] as num?)?.toDouble();
      final lng = (stop['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final isBus = _isBusStop(stop);
      final color = isBus ? AppColors.success : AppColors.primaryBase;
      final stopId = stop['stop_id']?.toString() ?? '';
      final isSelected = _selectedStop != null &&
          _selectedStop!['stop_id']?.toString() == stopId;
      return Marker(
        key: ValueKey('stop_marker_$stopId'),
        point: LatLng(lat, lng),
        width: isSelected ? 40 : 32,
        height: isSelected ? 40 : 32,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => _selectStop(stop),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : color,
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? color.withValues(alpha: 0.7)
                      : color.withValues(alpha: 0.35),
                  blurRadius: isSelected ? 10 : 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isBus ? Icons.directions_bus_rounded : Icons.train_rounded,
              color: Colors.white,
              size: isSelected ? 20 : 16,
            ),
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  Widget _buildMapCard(BuildContext context, AppLocalizations l10n,
      List<Map<String, dynamic>> stops, LatLng latLng,
      LocationProvider locationProvider) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.trafficDensityHeatmap,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // 真实站点总数徽章（替代原空实现的“查看详情”按钮）
              StatusBadge(
                label: '${stops.length} 站',
                type: _showStops ? StatusType.accent : StatusType.info,
                icon: _showStops ? Icons.directions_transit_rounded : Icons.visibility_off_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          MiniMap(
            center: latLng,
            height: 260,
            interactive: true,
            onTap: () {
              locationProvider.moveTo(latLng);
              final appShellState = context.findAncestorStateOfType<AppShellState>();
              if (appShellState != null) {
                appShellState.onItemTapped(1);
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            // 淡圈标注 1.5km 站点搜索半径（与评分口径一致）
            circles: [
              CircleMarker<Object>(
                point: latLng,
                radius: 1500,
                useRadiusInMeter: true,
                color: AppColors.accent.withValues(alpha: 0.05),
                borderColor: AppColors.accent.withValues(alpha: 0.45),
                borderStrokeWidth: 1.2,
              ),
            ],
            markers: _showStops ? _stopMarkers(stops) : const [],
            actions: [
              MiniMapAction(
                icon: Icons.directions_transit_rounded,
                tooltip: '站点图层',
                active: _showStops,
                activeColor: AppColors.primaryBaseAlternative,
                onTap: () => setState(() => _showStops = !_showStops),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 选中站点信息条 / 操作提示
          _buildSelectionBar(context, stops),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(BuildContext context, List<Map<String, dynamic>> stops) {
    final selected = _selectedStop;
    if (selected != null) {
      final isBus = _isBusStop(selected);
      final color = isBus ? AppColors.success : AppColors.primaryBase;
      final distanceM = (selected['distance_meters'] as num?)?.toDouble() ?? 0;
      final walkMin = (distanceM / 80).ceil();
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(isBus ? Icons.directions_bus_rounded : Icons.train_rounded,
                color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected['stop_name']?.toString() ?? '未知站点',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_transitLabel(selected['transit_type']?.toString() ?? '')} · 距离 ${distanceM.toInt()}m · 步行约 $walkMin 分钟',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => setState(() => _selectedStop = null),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    }
    // 未选中时：提示可点击列表或地图图标
    return Row(
      children: [
        const Icon(Icons.touch_app_rounded,
            size: 14, color: AppColors.textMutedLight),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _showStops && stops.isNotEmpty
                ? '点击站点图标或上方列表查看距离与步行时间'
                : (stops.isEmpty
                    ? '1.5km 范围内暂无已收录站点'
                    : '已隐藏站点图层，点击右上角图标恢复'),
            style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
          ),
        ),
      ],
    );
  }

  Widget _buildStationItem(BuildContext context, AppLocalizations l10n,
      IconData icon, String name, String lines, String distance, Color color,
      {required bool isSelected, required VoidCallback onTap}) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: color.withValues(alpha: 0.08),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(lines, style: const TextStyle(fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(distance,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBase)),
          const SizedBox(width: 4),
          Text(l10n.walking, style: const TextStyle(fontSize: 10, color: AppColors.textMutedLight)),
          if (isSelected) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle_rounded, color: AppColors.primaryBase, size: 18),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
