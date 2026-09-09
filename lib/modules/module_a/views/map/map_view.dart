import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:locate_my/core/app_colors.dart';
import 'package:locate_my/generated/app_localizations.dart';
import 'package:locate_my/app/navigation/app_route_names.dart';
import 'package:locate_my/modules/module_a/view_models/map/location_view_model.dart';
import 'package:locate_my/modules/module_a/views/infrastructure/infrastructure_view.dart';
import 'package:locate_my/modules/module_a/views/infrastructure/nearby_facilities_view.dart';
import 'package:locate_my/modules/module_a/views/transport/transportation_view.dart';
import 'package:locate_my/modules/module_a/view_models/map/hazard_view_model.dart';
import 'package:locate_my/modules/module_a/models/map/hazard_marker.dart';
import 'package:locate_my/modules/module_a/repositories/map/geoapify_repository.dart';
import 'package:locate_my/modules/module_a/models/map/geo_suggestion.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  bool _selectingOrigin = true;
  bool _showHazards = true;

  /// 对比模式下，底部详情卡当前展示哪一侧地点（true=原地址，false=新地址）。
  /// 由最近一次地图落点/收藏选择决定。
  bool _comparisonCardShowsOrigin = true;
  final GeoapifyRepository _geoapifyRepository = GeoapifyRepository();
  final SuggestionsController<GeoSuggestion> _suggestionsController =
      SuggestionsController<GeoSuggestion>();

  // Malaysia bounds
  // (范围判断统一由 LocationViewModel.isWithinMalaysia 提供，此处不再保留副本)

  void _showAddHazardDialog(LatLng point) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = context.read<LocationViewModel>();

    if (!locationProvider.isWithinMalaysia(point)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.outOfMalaysiaRange)));
      return;
    }

    final titleController = TextEditingController();
    final descController = TextEditingController();
    HazardType selectedType = HazardType.other;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 12,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.reportHazard,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.hazardType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: HazardType.values.map((type) {
                    final isSelected = selectedType == type;
                    final color = type.color;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () => setModalState(() => selectedType = type),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.1)
                                : AppColors.surfaceSubLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? color : AppColors.borderLight,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                type.icon,
                                color: isSelected
                                    ? color
                                    : AppColors.textMutedLight,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? color
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              _buildBentoInput(
                controller: titleController,
                label: l10n.hazardTitle,
                hint: "What happened here?",
                icon: Icons.title_rounded,
              ),
              const SizedBox(height: 16),
              _buildBentoInput(
                controller: descController,
                label: l10n.hazardDescription,
                hint: "Add more details...",
                icon: Icons.description_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      context.read<HazardViewModel>().createHazard(
                        title: titleController.text,
                        description: descController.text,
                        location: point,
                        type: selectedType,
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedType.color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.add,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceSubLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMutedLight),
              prefixIcon: Icon(icon, color: AppColors.primaryBase, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showHazardDetail(HazardMarker hazard) {
    final l10n = AppLocalizations.of(context)!;
    final color = hazard.type.color;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(hazard.type.icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hazard.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hazard.type.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                hazard.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildVoteButton(
                  icon: Icons.thumb_up_rounded,
                  count: hazard.upvotes,
                  color: AppColors.success,
                  onTap: () => context.read<HazardViewModel>().voteHazard(
                    hazard.id,
                    true,
                  ),
                ),
                const SizedBox(width: 12),
                _buildVoteButton(
                  icon: Icons.thumb_down_rounded,
                  count: hazard.downvotes,
                  color: AppColors.danger,
                  onTap: () => context.read<HazardViewModel>().voteHazard(
                    hazard.id,
                    false,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    context.read<HazardViewModel>().deleteHazard(hazard.id);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: Text(l10n.cancel),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaveLocationDialog(LatLng location, String? initialName) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: initialName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saveLocation),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: l10n.locationName,
            hintText: l10n.enterLocationName,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                context.read<LocationViewModel>().addSavedLocation(
                  nameController.text,
                  location,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved: ${nameController.text}')),
                );
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  void _showSavedLocationsDialog() {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = context.read<LocationViewModel>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.savedLocations),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (locationProvider.savedLocations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(l10n.noSavedLocations),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: locationProvider.savedLocations.length,
                      itemBuilder: (context, index) {
                        final loc = locationProvider.savedLocations[index];
                        return ListTile(
                          title: Text(loc.name),
                          subtitle: Text(
                            "${loc.location.latitude.toStringAsFixed(4)}, ${loc.location.longitude.toStringAsFixed(4)}",
                          ),
                          onTap: () {
                            locationProvider.setSelectedLocation(
                              loc.location,
                              loc.name,
                            );
                            locationProvider.moveTo(loc.location, zoom: 15.0);
                            Navigator.pop(context);
                          },
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              locationProvider.removeSavedLocation(loc.id);
                              setDialogState(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = Provider.of<LocationViewModel>(context);
    final hazardProvider = Provider.of<HazardViewModel>(context);
    final safeTop = MediaQuery.of(context).padding.top;

    // 对比模式详情卡目标：当前激活侧（原地址/新地址）已落点则显示
    final comparisonTarget = locationProvider.mode == MapMode.comparison
        ? _activeComparisonTarget(locationProvider)
        : null;

    return Material(
      color: AppColors.backgroundLight,
      child: Stack(
        children: [
          // 1. The Map
          FlutterMap(
            mapController: locationProvider.mapController,
            options: MapOptions(
              initialCenter: const LatLng(
                4.2105,
                101.9758,
              ), // Center of Malaysia
              initialZoom: 6.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onLongPress: (tapPosition, point) => _showAddHazardDialog(point),
              onTap: (tapPosition, point) {
                // Close search suggestions and keyboard
                _suggestionsController.close();
                FocusScope.of(context).unfocus();

                // Handle closing analysis report
                if (locationProvider.isAnalysisReportOpen) {
                  locationProvider.setAnalysisReportOpen(false);
                }

                if (!locationProvider.isWithinMalaysia(point)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.outOfMalaysiaRange)),
                  );
                  return;
                }

                if (locationProvider.mode == MapMode.display) {
                  locationProvider.setSelectedLocation(
                    point,
                    "Selected Location",
                  );
                } else {
                  if (_selectingOrigin) {
                    locationProvider.setOriginLocation(point, "Origin");
                    _comparisonCardShowsOrigin = true;
                  } else {
                    locationProvider.setDestinationLocation(
                      point,
                      "Destination",
                    );
                    _comparisonCardShowsOrigin = false;
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.locatemy.assignment.app',
              ),
              // 对比模式：用一条线连接原地址与新地址
              if (locationProvider.mode == MapMode.comparison &&
                  locationProvider.originLocation != null &&
                  locationProvider.destinationLocation != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [
                        locationProvider.originLocation!,
                        locationProvider.destinationLocation!,
                      ],
                      strokeWidth: 4,
                      color: AppColors.primaryBaseAlternative,
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),
              MarkerLayer(
                key: ValueKey(
                  'map_markers_${locationProvider.selectedLocation}_${locationProvider.originLocation}_${locationProvider.destinationLocation}_${hazardProvider.hazards.length}_$_showHazards',
                ),
                markers: [
                  if (_showHazards)
                    ..._buildHazardMarkers(locationProvider, hazardProvider),
                  ..._buildLocationMarkers(locationProvider),
                ],
              ),
            ],
          ),

          // 2. Top-Left: Search Bar, Mode Switch & Selection Info
          Positioned(
            top: safeTop + 16,
            left: 16,
            right: 80, // Leave room for quick access buttons
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(l10n),
                const SizedBox(height: 12),
                _buildModeSwitch(locationProvider, l10n),
                const SizedBox(height: 12),
                if (locationProvider.mode == MapMode.comparison)
                  _buildComparisonSelectors(locationProvider, l10n),
              ],
            ),
          ),

          // 4. Top-Right: Quick Access Buttons
          Positioned(
            top: safeTop + 16,
            right: 16,
            child: Column(
              children: [
                _buildRoundButton(
                  icon: Icons.refresh_rounded,
                  iconColor: AppColors.primaryBase,
                  onTap: () {
                    context.read<HazardViewModel>().refreshHazards();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("正在从 Supabase 同步最新的隐患数据..."),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  tooltip: "同步最新隐患数据",
                ),
                const SizedBox(height: 12),
                _buildRoundButton(
                  icon: Icons.bookmarks_rounded,
                  iconColor: AppColors.primaryBase,
                  onTap: _showSavedLocationsDialog,
                  tooltip: l10n.savedLocations,
                ),
                const SizedBox(height: 12),
                _buildRoundButton(
                  icon: _showHazards
                      ? Icons.warning_amber_rounded
                      : Icons.warning_amber_outlined,
                  iconColor: _showHazards
                      ? AppColors.primaryBase
                      : AppColors.textMutedLight,
                  onTap: () => setState(() => _showHazards = !_showHazards),
                  tooltip: "隐患图层",
                ),
                const SizedBox(height: 24),
                _buildQuickAccessButtons(context, l10n),
              ],
            ),
          ),

          // 5. Bottom Selection UI (Flexible)
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'map_add_hazard_fab',
                  onPressed: () {
                    final targetPoint =
                        locationProvider.selectedLocation ??
                        locationProvider.mapController.camera.center;
                    _showAddHazardDialog(targetPoint);
                  },
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: Text(l10n.reportHazard),
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
                if (locationProvider.mode == MapMode.display &&
                    locationProvider.selectedLocation != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailCard(
                    locationProvider: locationProvider,
                    l10n: l10n,
                    location: locationProvider.selectedLocation!,
                    name: locationProvider.selectedName,
                    fallbackTitle: 'Selected Location',
                    typeIcon: Icons.location_on_rounded,
                    typeColor: AppColors.danger,
                    onClear: locationProvider.clearSelection,
                  ),
                ] else if (comparisonTarget != null) ...[
                  const SizedBox(height: 16),
                  _buildComparisonDetailCard(
                    locationProvider: locationProvider,
                    l10n: l10n,
                    target: comparisonTarget,
                  ),
                ],
              ],
            ),
          ),

          // 6. Analysis Panel (Persistent)
          if (locationProvider.isAnalysisReportOpen) ...[
            // Dimmed background/Scrim that intercepts taps to close
            Positioned.fill(
              child: GestureDetector(
                onTap: () => locationProvider.setAnalysisReportOpen(false),
                child: Container(color: Colors.black.withValues(alpha: 0.2)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: MediaQuery.of(context).size.width * 0.75,
              child: _buildAnalysisPanel(context, l10n),
            ),
          ],
        ],
      ),
    );
  }

  List<Marker> _buildHazardMarkers(
    LocationViewModel provider,
    HazardViewModel hazardProvider,
  ) {
    List<Marker> markers = [];
    final distance = const Distance();
    const double proximityThreshold = 10000; // 10km

    for (var hazard in hazardProvider.hazards) {
      bool shouldShow = false;
      if (provider.mode == MapMode.display &&
          provider.selectedLocation != null) {
        if (distance.distance(hazard.location, provider.selectedLocation!) <=
            proximityThreshold) {
          shouldShow = true;
        }
      } else if (provider.mode == MapMode.comparison) {
        if (provider.originLocation != null &&
            distance.distance(hazard.location, provider.originLocation!) <=
                proximityThreshold) {
          shouldShow = true;
        }
        if (!shouldShow &&
            provider.destinationLocation != null &&
            distance.distance(hazard.location, provider.destinationLocation!) <=
                proximityThreshold) {
          shouldShow = true;
        }
      }

      if (shouldShow) {
        final color = hazard.type.color;
        markers.add(
          Marker(
            key: ValueKey('hazard_${hazard.id}'),
            point: hazard.location,
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => _showHazardDetail(hazard),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(hazard.type.icon, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        );
      }
    }
    return markers;
  }

  List<Marker> _buildLocationMarkers(LocationViewModel provider) {
    List<Marker> markers = [];

    // Selected Location (Display Mode)
    if (provider.mode == MapMode.display && provider.selectedLocation != null) {
      markers.add(
        Marker(
          key: const ValueKey('selected_location_marker'),
          point: provider.selectedLocation!,
          width: 60,
          height: 60,
          alignment: Alignment.bottomCenter,
          child: _buildRobustPin(AppColors.primaryBase, Icons.location_on),
        ),
      );
    }

    // Comparison Mode Markers
    // 徽章以坐标点为中心放置，确保连线端点从图标中心穿过
    if (provider.mode == MapMode.comparison) {
      if (provider.originLocation != null) {
        markers.add(
          Marker(
            key: const ValueKey('origin_marker'),
            point: provider.originLocation!,
            width: 50,
            height: 50,
            alignment: Alignment.center,
            child: _buildRobustPin(AppColors.primaryBase, Icons.home),
          ),
        );
      }
      if (provider.destinationLocation != null) {
        markers.add(
          Marker(
            key: const ValueKey('destination_marker'),
            point: provider.destinationLocation!,
            width: 50,
            height: 50,
            alignment: Alignment.center,
            child: _buildRobustPin(AppColors.accent, Icons.flag),
          ),
        );
      }
    }

    return markers;
  }

  Widget _buildRobustPin(Color color, IconData icon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        ),
        // White border circle
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: Icon(icon, color: color, size: 20)),
        ),
      ],
    );
  }

  Widget _buildModeSwitch(LocationViewModel provider, AppLocalizations l10n) {
    final isDisplayMode = provider.mode == MapMode.display;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeOption(
            l10n.displayMode,
            isDisplayMode,
            () => provider.setMode(MapMode.display),
          ),
          _buildModeOption(
            l10n.comparisonMode,
            !isDisplayMode,
            () => provider.setMode(MapMode.comparison),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBase : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  // Refined ToggleButtons with full text might be too wide, let's use icons or specific l10n
  // For now I'll use simple icons or short text.

  void _showLocationPicker(bool isOrigin) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = context.read<LocationViewModel>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.selectSavedLocation,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (locationProvider.savedLocations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l10n.noSavedLocations),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: locationProvider.savedLocations.length,
                  itemBuilder: (context, index) {
                    final loc = locationProvider.savedLocations[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.bookmark,
                        color: AppColors.primaryBase,
                      ),
                      title: Text(loc.name),
                      onTap: () {
                        if (isOrigin) {
                          locationProvider.setOriginLocation(
                            loc.location,
                            loc.name,
                          );
                          _comparisonCardShowsOrigin = true;
                        } else {
                          locationProvider.setDestinationLocation(
                            loc.location,
                            loc.name,
                          );
                          _comparisonCardShowsOrigin = false;
                        }
                        locationProvider.moveTo(loc.location, zoom: 15.0);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.map_outlined, color: AppColors.accent),
              title: Text(l10n.pickOnMap),
              onTap: () {
                setState(() => _selectingOrigin = isOrigin);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSelectors(
    LocationViewModel provider,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
        boxShadow: AppColors.cardShadow,
      ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSelectButton(
              label: provider.originName ?? l10n.currentAddress,
              isActive: _selectingOrigin,
              isSelected: provider.originLocation != null,
              onTap: () => _showLocationPicker(true),
              onClear: () => provider.setOriginLocation(null, null),
              color: AppColors.primaryBase,
            ),
            const SizedBox(height: 10),
            _buildSelectButton(
              label: provider.destinationName ?? l10n.newAddress,
              isActive: !_selectingOrigin,
              isSelected: provider.destinationLocation != null,
              onTap: () => _showLocationPicker(false),
              onClear: () => provider.setDestinationLocation(null, null),
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectButton({
    required String label,
    required bool isActive,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
    VoidCallback? onClear,
  }) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withValues(alpha: 0.08)
                    : AppColors.surfaceSubLight,
                border: Border.all(
                  color: isActive ? color : AppColors.borderLight,
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: isSelected ? color : AppColors.textMutedLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isActive
                            ? AppColors.textPrimaryLight
                            : AppColors.textSecondaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isSelected) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: onClear,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: AppColors.textMutedLight,
          ),
        ],
      ],
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    final locationProvider = Provider.of<LocationViewModel>(
      context,
      listen: false,
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
        boxShadow: AppColors.cardShadow,
      ),
      child: TypeAheadField<GeoSuggestion>(
        suggestionsController: _suggestionsController,
        suggestionsCallback: (search) =>
            _geoapifyRepository.getSuggestions(search),
        builder: (context, controller, focusNode) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: l10n.searchLocation,
              hintStyle: const TextStyle(color: AppColors.textMutedLight),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primaryBase,
              ),
              suffixIcon: ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, value, child) {
                  if (controller.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      controller.clear();
                      locationProvider.clearSelection();
                    },
                  );
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          );
        },
        itemBuilder: (context, suggestion) {
          return ListTile(
            leading: const Icon(Icons.location_on_outlined, size: 20),
            title: Text(
              suggestion.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              suggestion.label,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
        onSelected: (suggestion) {
          if (!locationProvider.isWithinMalaysia(suggestion.location)) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.outOfMalaysiaRange)));
            return;
          }
          if (locationProvider.mode == MapMode.display) {
            locationProvider.setSelectedLocation(
              suggestion.location,
              suggestion.name,
            );
          } else {
            if (_selectingOrigin) {
              locationProvider.setOriginLocation(
                suggestion.location,
                suggestion.name,
              );
            } else {
              locationProvider.setDestinationLocation(
                suggestion.location,
                suggestion.name,
              );
            }
          }
          locationProvider.moveTo(suggestion.location, zoom: 15.0);
        },
      ),
    );
  }

  Widget _buildQuickAccessButtons(BuildContext context, AppLocalizations l10n) {
    final locationProvider = Provider.of<LocationViewModel>(context);
    final hasSelection =
        locationProvider.selectedLocation != null ||
        locationProvider.originLocation != null ||
        locationProvider.destinationLocation != null;

    return Column(
      children: [
        _buildRoundButton(
          icon: Icons.location_off,
          iconColor: hasSelection ? AppColors.danger : AppColors.textMutedLight,
          onTap: hasSelection ? () => locationProvider.clearSelection() : null,
          tooltip: l10n.clearSelection,
          enabled: hasSelection,
        ),
        const SizedBox(height: 12),
        _buildRoundButton(
          icon: Icons.analytics,
          iconColor: locationProvider.isAnalysisReportOpen
              ? Colors.white
              : Colors.purple,
          backgroundColor: locationProvider.isAnalysisReportOpen
              ? Colors.purple
              : AppColors.surfaceLight,
          onTap: () => locationProvider.setAnalysisReportOpen(
            !locationProvider.isAnalysisReportOpen,
          ),
          tooltip: l10n.analysisReport,
        ),
      ],
    );
  }

  Widget _buildAnalysisPanel(BuildContext context, AppLocalizations l10n) {
    return Material(
      elevation: 16,
      child: Container(
        color: AppColors.surfaceLight,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 40, bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.primaryBase.withValues(alpha: 0.08),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics,
                          size: 48,
                          color: AppColors.primaryBase,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.analysisReport,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBase,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context
                          .read<LocationViewModel>()
                          .setAnalysisReportOpen(false),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.monetization_on_rounded,
                    color: AppColors.success,
                    title: l10n.costOfLiving,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouteNames.costOfLiving,
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.security_rounded,
                    color: AppColors.warning,
                    title: l10n.crimeSecurity,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouteNames.crimeSecurity,
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.analytics_rounded,
                    color: Colors.purple,
                    title: l10n.socioEconomic,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouteNames.socioEconomic,
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.business_rounded,
                    color: AppColors.info,
                    title: l10n.infrastructure,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InfrastructureView(),
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.near_me_rounded,
                    color: Colors.blueAccent,
                    title: '周边设施 (OSM)',
                    onTap: () {
                      final provider = context.read<LocationViewModel>();
                      if (provider.selectedLocation != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NearbyFacilitiesView(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请先在地图上选择一个地点')),
                        );
                      }
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.train_rounded,
                    color: AppColors.primaryBaseAlternative,
                    title: l10n.transportation,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransportationView(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback? onTap,
    Color? backgroundColor,
    String? tooltip,
    bool enabled = true,
  }) {
    return Tooltip(
      message: (enabled && tooltip != null) ? tooltip : "",
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          customBorder: const CircleBorder(),
          child: Opacity(
            opacity: enabled ? 1.0 : 0.6,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor ?? AppColors.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight, width: 1.0),
                boxShadow: enabled ? AppColors.cardShadow : null,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  /// 对比模式详情卡的目标地点：当前激活侧（原地址/新地址）且已落地。
  _ComparisonTarget? _activeComparisonTarget(LocationViewModel provider) {
    if (_comparisonCardShowsOrigin) {
      final origin = provider.originLocation;
      if (origin == null) return null;
      return _ComparisonTarget(
        location: origin,
        name: provider.originName,
        isOrigin: true,
      );
    }
    final destination = provider.destinationLocation;
    if (destination == null) return null;
    return _ComparisonTarget(
      location: destination,
      name: provider.destinationName,
      isOrigin: false,
    );
  }

  /// 通用“地点详情卡”：展示地点名与坐标，支持一键保存为收藏地点。
  Widget _buildDetailCard({
    required LocationViewModel locationProvider,
    required AppLocalizations l10n,
    required LatLng location,
    required String? name,
    required String fallbackTitle,
    required IconData typeIcon,
    required Color typeColor,
    required VoidCallback onClear,
  }) {
    final bool isSaved = locationProvider.isLocationSaved(location);
    // 点击地图产生的默认名（Selected Location/Origin/Destination）视为未命名
    final bool isGenericName =
        name == null || name.isEmpty || _isGenericLocationName(name);
    final String title = isGenericName ? fallbackTitle : name;
    final String? saveInitialName = isGenericName ? null : name;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textSecondaryLight,
                ),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Icon(
                isSaved ? Icons.bookmark_rounded : typeIcon,
                color: isSaved ? AppColors.primaryBase : typeColor,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}",
            style: const TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 14,
            ),
          ),
          if (!isSaved) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showSaveLocationDialog(location, saveInitialName),
                icon: const Icon(Icons.bookmark_add_rounded),
                label: Text(l10n.saveLocation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBase,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 对比模式：展示当前激活侧（原地址或新地址）的地点详情卡。
  Widget _buildComparisonDetailCard({
    required LocationViewModel locationProvider,
    required AppLocalizations l10n,
    required _ComparisonTarget target,
  }) {
    return _buildDetailCard(
      locationProvider: locationProvider,
      l10n: l10n,
      location: target.location,
      name: target.name,
      fallbackTitle: target.isOrigin ? l10n.currentAddress : l10n.newAddress,
      typeIcon: target.isOrigin ? Icons.home_rounded : Icons.flag_rounded,
      typeColor: target.isOrigin ? AppColors.primaryBase : AppColors.accent,
      onClear: () {
        if (target.isOrigin) {
          locationProvider.setOriginLocation(null, null);
        } else {
          locationProvider.setDestinationLocation(null, null);
        }
      },
    );
  }

  bool _isGenericLocationName(String name) =>
      name == 'Selected Location' || name == 'Origin' || name == 'Destination';
}

/// 对比模式下地图两端点中的其中一侧（原地址或新地址）。
class _ComparisonTarget {
  const _ComparisonTarget({
    required this.location,
    required this.name,
    required this.isOrigin,
  });

  final LatLng location;
  final String? name;

  /// true = 原地址 (Origin)，false = 新地址 (Destination)
  final bool isOrigin;
}
