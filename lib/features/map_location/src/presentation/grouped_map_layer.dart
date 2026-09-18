// Explicit constructor types follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../l10n/app_localizations.dart';
import '../domain/location_models.dart';

/// Groups dense overlays in screen space without discarding provider data.
class GroupedMapLayer extends StatelessWidget {
  final List<MapLayerItem> items;
  final MapController controller;
  final void Function(MapLayerIntent) onSelected;

  const GroupedMapLayer({
    required List<MapLayerItem> items,
    required MapController controller,
    required void Function(MapLayerIntent) onSelected,
    super.key,
  }) : items = items,
       controller = controller,
       onSelected = onSelected;

  String _provider(MapLayerItem item) {
    final MapLayerIntent intent = item.intent;
    if (intent is ProviderDefinedIntent) {
      return intent.providerId;
    }
    return '';
  }

  String _name(String provider, AppLocalizations l10n) {
    switch (provider) {
      case 'nearby-facilities':
        return l10n.mapFacilityLayer;
      case 'hazard-reporting':
        return l10n.mapHazardLayer;
      case 'public-transportation':
        return l10n.mapTransitLayer;
      default:
        return l10n.mapLayers;
    }
  }

  IconData _icon(String provider, MapMarkerKind kind) {
    switch (kind) {
      case MapMarkerKind.facilityHealth:
        return Icons.local_hospital_outlined;
      case MapMarkerKind.facilityEducation:
        return Icons.school_outlined;
      case MapMarkerKind.facilityDailyLiving:
        return Icons.shopping_basket_outlined;
      case MapMarkerKind.facilityTransport:
        return Icons.directions_bus_outlined;
      case MapMarkerKind.facilityLeisureGreen:
        return Icons.park_outlined;
      case MapMarkerKind.hazardFlood:
        return Icons.flood_outlined;
      case MapMarkerKind.hazardCrime:
        return Icons.gpp_bad_outlined;
      case MapMarkerKind.hazardTraffic:
        return Icons.car_crash_outlined;
      case MapMarkerKind.hazardInfrastructure:
        return Icons.construction_outlined;
      case MapMarkerKind.hazardOther:
        return Icons.report_problem_outlined;
      case MapMarkerKind.generic:
        break;
    }
    switch (provider) {
      case 'nearby-facilities':
        return Icons.storefront;
      case 'hazard-reporting':
        return Icons.warning_amber_rounded;
      case 'public-transportation':
        return Icons.directions_transit;
      default:
        return Icons.place;
    }
  }

  Color _color(String provider) {
    if (provider == 'hazard-reporting') {
      return const Color(0xFFB54708);
    }
    if (provider == 'nearby-facilities') {
      return const Color(0xFF027A48);
    }
    return const Color(0xFF155EEF);
  }

  String _pointLabel(MapLayerItem item, AppLocalizations l10n) {
    final String category = _category(item.markerKind, l10n);
    final String name = _name(_provider(item), l10n);
    String label = name;
    if (category.isNotEmpty) {
      label = '$name · $category';
    }
    return '$label: ${l10n.mapLayerPoint(item.point.latitude.toStringAsFixed(5), item.point.longitude.toStringAsFixed(5))}';
  }

  String _category(MapMarkerKind kind, AppLocalizations l10n) {
    if (kind == MapMarkerKind.generic) {
      return '';
    }
    const List<String> english = <String>[
      '',
      'Health',
      'Education',
      'Daily living',
      'Transport',
      'Leisure and green space',
      'Flood',
      'Crime',
      'Traffic',
      'Infrastructure',
      'Other',
    ];
    const List<String> chinese = <String>[
      '',
      '医疗健康',
      '教育资源',
      '日常生活',
      '交通出行',
      '休闲与绿地',
      '水灾',
      '治安',
      '交通',
      '基础设施',
      '其他',
    ];
    if (l10n.localeName.startsWith('zh')) {
      return chinese[kind.index];
    }
    return english[kind.index];
  }

  MapMarkerKind _groupKind(_MarkerGroup group) {
    final MapMarkerKind first = group.items.first.markerKind;
    for (final MapLayerItem item in group.items) {
      if (item.markerKind != first) {
        return MapMarkerKind.generic;
      }
    }
    return first;
  }

  void _openGroup(
    BuildContext context,
    _MarkerGroup group,
    MapCamera camera,
    AppLocalizations l10n,
  ) {
    if (camera.zoom < 18) {
      controller.move(
        camera.screenOffsetToLatLng(group.center),
        (camera.zoom + 2).clamp(0.0, 18.0),
      );
      return;
    }
    // Co-located points remain individually accessible at the closest zoom.
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: group.items.length,
            itemBuilder: (BuildContext rowContext, int index) {
              final MapLayerItem item = group.items[index];
              return ListTile(
                leading: Icon(
                  _icon(group.provider, item.markerKind),
                  color: _color(group.provider),
                ),
                title: Text(_pointLabel(item, l10n)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onSelected(item.intent);
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reading the inherited camera regroups points on pan, zoom and resize.
    final MapCamera camera = MapCamera.of(context);
    final AppLocalizations l10n =
        AppLocalizations.of(context) ??
        lookupAppLocalizations(Localizations.localeOf(context));
    final Rect visible = (Offset.zero & camera.nonRotatedSize).inflate(48);
    final Map<String, _MarkerGroup> groups = <String, _MarkerGroup>{};
    const double cellSize = 96;
    for (final MapLayerItem item in items) {
      final LatLng point = LatLng(item.point.latitude, item.point.longitude);
      final Offset screen = camera.latLngToScreenOffset(point);
      if (!visible.contains(screen)) {
        continue;
      }
      final String provider = _provider(item);
      final int column = (screen.dx / cellSize).floor();
      final int row = (screen.dy / cellSize).floor();
      final String key = '$provider:$column:$row';
      final _MarkerGroup group = groups.putIfAbsent(key, () {
        return _MarkerGroup(provider);
      });
      group.add(item, screen);
    }
    final List<Marker> markers = <Marker>[];
    for (final _MarkerGroup group in groups.values) {
      final Color color = _color(group.provider);
      if (group.items.length == 1) {
        final MapLayerItem item = group.items.single;
        markers.add(
          Marker(
            point: LatLng(item.point.latitude, item.point.longitude),
            width: 48,
            height: 48,
            child: IconButton(
              tooltip: _pointLabel(item, l10n),
              padding: EdgeInsets.zero,
              onPressed: () {
                onSelected(item.intent);
              },
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(color: Color(0x26000000), blurRadius: 6),
                  ],
                ),
                child: Icon(
                  _icon(group.provider, item.markerKind),
                  color: color,
                  size: 21,
                ),
              ),
            ),
          ),
        );
      } else {
        markers.add(
          Marker(
            point: camera.screenOffsetToLatLng(group.center),
            width: 52,
            height: 48,
            child: Semantics(
              button: true,
              excludeSemantics: true,
              label: l10n.mapLayerCluster(
                _name(group.provider, l10n),
                group.items.length,
              ),
              onTap: () {
                _openGroup(context, group, camera, l10n);
              },
              child: Tooltip(
                excludeFromSemantics: true,
                message: l10n.mapLayerCluster(
                  _name(group.provider, l10n),
                  group.items.length,
                ),
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: BorderSide(color: color, width: 2),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      _openGroup(context, group, camera, l10n);
                    },
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              _icon(group.provider, _groupKind(group)),
                              color: color,
                              size: 18,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${group.items.length}',
                              // Map symbols keep a fixed size; the tooltip exposes
                              // the full localized count to assistive technology.
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return MarkerLayer(rotate: true, markers: markers);
  }
}

class _MarkerGroup {
  final String provider;
  final List<MapLayerItem> items = <MapLayerItem>[];
  Offset _sum = Offset.zero;

  _MarkerGroup(String provider) : provider = provider;

  void add(MapLayerItem item, Offset screen) {
    items.add(item);
    _sum += screen;
  }

  Offset get center {
    return _sum / items.length.toDouble();
  }
}
