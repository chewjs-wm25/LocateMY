import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/app_colors.dart';

/// 地图卡片右上角悬浮的圆形小按钮（风格与主地图 Quick Access 按钮一致）。
class MiniMapAction {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback? onTap;
  final Color activeColor;

  const MiniMapAction({
    required this.icon,
    required this.tooltip,
    this.active = false,
    this.onTap,
    this.activeColor = AppColors.primaryBase,
  });
}

/// 分析页内嵌的交互式小地图。
///
/// 相比旧版静态预览，支持：
/// - [interactive]=true 时允许在地图上拖拽/缩放，并可点击 [markers] 中的图标；
/// - [polygons] / [circles]：渲染警区边界、覆盖半径等图层；
/// - [actions]：右上角悬浮图标按钮（图层开关等）。
///
/// 兼容旧调用（仅 center/zoom/onTap/height），默认仍为静态预览行为。
class MiniMap extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  final VoidCallback? onTap;
  final double height;
  final bool interactive;
  final bool showCenterMarker;
  final List<Polygon<Object>> polygons;
  final List<CircleMarker<Object>> circles;
  final List<MiniMapAction> actions;
  final double maxZoom;

  const MiniMap({
    super.key,
    required this.center,
    this.zoom = 13.0,
    this.markers = const [],
    this.onTap,
    this.height = 200,
    this.interactive = false,
    this.showCenterMarker = true,
    this.polygons = const [],
    this.circles = const [],
    this.actions = const [],
    this.maxZoom = 17,
  });

  @override
  Widget build(BuildContext context) {
    // interactive 时由地图自己消化手势，不再整卡拦截点击跳主地图；
    // 非 interactive（静态预览）保留整卡 onTap。
    final VoidCallback? cardTap = interactive ? null : onTap;
    return GestureDetector(
      onTap: cardTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                maxZoom: maxZoom,
                interactionOptions: InteractionOptions(
                  flags: interactive
                      ? InteractiveFlag.all & ~InteractiveFlag.rotate
                      : InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.locatemy.assignment.app',
                ),
                if (polygons.isNotEmpty)
                  PolygonLayer<Object>(polygons: polygons),
                if (circles.isNotEmpty)
                  CircleLayer<Object>(circles: circles),
                MarkerLayer(
                  markers: [
                    if (showCenterMarker)
                      Marker(
                        point: center,
                        width: 40,
                        height: 40,
                        alignment: Alignment.bottomCenter,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.danger,
                          size: 30,
                        ),
                      ),
                    ...markers,
                  ],
                ),
              ],
            ),
            // 右上角图层操作按钮列
            if (actions.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  children: [
                    for (final action in actions) ...[
                      _buildActionButton(action),
                      if (action != actions.last) const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            // 保留“跳到主地图”入口（interactive 时也保留，便于全屏查看）
            if (onTap != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fullscreen, size: 16, color: AppColors.primaryBase),
                        SizedBox(width: 4),
                        Text(
                          '查看主地图',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBase,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(MiniMapAction action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: action.active
                ? action.activeColor
                : AppColors.surfaceLight.withValues(alpha: 0.95),
            shape: BoxShape.circle,
            border: Border.all(
              color: action.active ? action.activeColor : AppColors.borderLight,
              width: 1.0,
            ),
            boxShadow: AppColors.cardShadow,
          ),
          child: Icon(
            action.icon,
            color: action.active ? Colors.white : AppColors.textMutedLight,
            size: 20,
          ),
        ),
      ),
    );
  }
}
