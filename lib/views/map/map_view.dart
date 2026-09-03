import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../generated/app_localizations.dart';
import '../../providers/location_provider.dart';
import '../cost_of_living/cost_of_living_view.dart';
import '../crime_security/crime_security_view.dart';
import '../socio_economic/socio_economic_view.dart';
import '../infrastructure/infrastructure_view.dart';
import '../transport/transportation_view.dart';
import '../../providers/hazard_provider.dart';
import '../../models/hazard_marker.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  bool _selectingOrigin = true;

  void _showAddHazardDialog(LatLng point) {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    HazardType selectedType = HazardType.other;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reportHazard),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: l10n.hazardTitle)),
            TextField(controller: descController, decoration: InputDecoration(labelText: l10n.hazardDescription)),
            DropdownButtonFormField<HazardType>(
              value: selectedType,
              items: HazardType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.name))).toList(),
              onChanged: (v) => selectedType = v!,
              decoration: InputDecoration(labelText: l10n.hazardType),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              context.read<HazardProvider>().createHazard(
                title: titleController.text,
                description: descController.text,
                location: point,
                type: selectedType,
              );
              Navigator.pop(context);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  void _showHazardDetail(HazardMarker hazard) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hazard.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(hazard.description),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up_outlined),
                  onPressed: () => context.read<HazardProvider>().voteHazard(hazard.id, true),
                ),
                Text('${hazard.upvotes}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.thumb_down_outlined),
                  onPressed: () => context.read<HazardProvider>().voteHazard(hazard.id, false),
                ),
                Text('${hazard.downvotes}'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    context.read<HazardProvider>().deleteHazard(hazard.id);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = Provider.of<LocationProvider>(context);
    final hazardProvider = Provider.of<HazardProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // 1. The Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(4.2105, 101.9758), // Center of Malaysia
              initialZoom: 6.0,
              onLongPress: (tapPosition, point) => _showAddHazardDialog(point),
              onTap: (tapPosition, point) {
                if (locationProvider.mode == MapMode.display) {
                  locationProvider.setSelectedLocation(point, "Selected Location");
                } else {
                  if (_selectingOrigin) {
                    locationProvider.setOriginLocation(point, "Origin");
                  } else {
                    locationProvider.setDestinationLocation(point, "Destination");
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.locatemy.assignment.app',
              ),
              MarkerLayer(
                markers: _buildMarkers(locationProvider, hazardProvider),
              ),
            ],
          ),

          // 2. Top-Left: Search Bar, Mode Switch & Selection Info
          Positioned(
            top: 60,
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
            top: 60,
            right: 16,
            child: Column(
              children: [
                _buildRoundButton(Icons.my_location, Colors.redAccent, () {
                  // Jump to KL Hazard Area
                  _mapController.move(const LatLng(3.1390, 101.6869), 13.0);
                }),
                const SizedBox(height: 12),
                _buildQuickAccessButtons(context, l10n),
              ],
            ),
          ),

          // 5. Bottom Selection Card (Optional but helpful)
          if (locationProvider.mode == MapMode.display && locationProvider.selectedLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildLocationInfoCard(locationProvider, l10n),
            ),

          // Add Hazard Fab
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.extended(
              onPressed: () {
                _showAddHazardDialog(_mapController.camera.center);
              },
              icon: const Icon(Icons.add_location_alt_rounded),
              label: Text(l10n.reportHazard),
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(LocationProvider provider, HazardProvider hazardProvider) {
    List<Marker> markers = [];
    final distance = const Distance();
    const double proximityThreshold = 5000; // 5km radius

    // Hazard Markers: Only show near selected locations
    for (var hazard in hazardProvider.hazards) {
      bool shouldShow = false;

      if (provider.mode == MapMode.display && provider.selectedLocation != null) {
        if (distance(hazard.location, provider.selectedLocation!) <= proximityThreshold) {
          shouldShow = true;
        }
      } else if (provider.mode == MapMode.comparison) {
        // Show if near either origin or destination
        if (provider.originLocation != null &&
            distance(hazard.location, provider.originLocation!) <= proximityThreshold) {
          shouldShow = true;
        }
        if (!shouldShow && provider.destinationLocation != null &&
            distance(hazard.location, provider.destinationLocation!) <= proximityThreshold) {
          shouldShow = true;
        }
      }

      if (shouldShow) {
        markers.add(Marker(
          point: hazard.location,
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _showHazardDetail(hazard),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _getHazardIcon(hazard.type),
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ));
      }
    }

    if (provider.mode == MapMode.display && provider.selectedLocation != null) {
      markers.add(Marker(
        point: provider.selectedLocation!,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ));
    } else if (provider.mode == MapMode.comparison) {
      if (provider.originLocation != null) {
        markers.add(Marker(
          point: provider.originLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
        ));
      }
      if (provider.destinationLocation != null) {
        markers.add(Marker(
          point: provider.destinationLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
        ));
      }
    }
    return markers;
  }

  IconData _getHazardIcon(HazardType type) {
    switch (type) {
      case HazardType.flood: return Icons.water_drop;
      case HazardType.crime: return Icons.warning;
      case HazardType.traffic: return Icons.traffic;
      case HazardType.infrastructure: return Icons.build;
      case HazardType.other: return Icons.help;
    }
  }

  Widget _buildModeSwitch(LocationProvider provider, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(30),
        selectedColor: Colors.white,
        fillColor: AppColors.primaryBase,
        color: AppColors.textPrimaryLight,
        constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
        isSelected: [
          provider.mode == MapMode.display,
          provider.mode == MapMode.comparison,
        ],
        onPressed: (index) {
          provider.setMode(index == 0 ? MapMode.display : MapMode.comparison);
        },
        children: [
          Text(l10n.displayMode),
          Text(l10n.comparisonMode),
        ],
      ),
    );
  }

  // Refined ToggleButtons with full text might be too wide, let's use icons or specific l10n
  // For now I'll use simple icons or short text.

  Widget _buildComparisonSelectors(LocationProvider provider, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Column(
        children: [
          _buildSelectButton(
            label: l10n.currentAddress,
            isActive: _selectingOrigin,
            isSelected: provider.originLocation != null,
            onTap: () => setState(() => _selectingOrigin = true),
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildSelectButton(
            label: l10n.newAddress,
            isActive: !_selectingOrigin,
            isSelected: provider.destinationLocation != null,
            onTap: () => setState(() => _selectingOrigin = false),
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectButton({
    required String label,
    required bool isActive,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(color: isActive ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: l10n.searchLocation,
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildQuickAccessButtons(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        _buildRoundButton(Icons.monetization_on, AppColors.primaryBase, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CostOfLivingView()));
        }),
        const SizedBox(height: 12),
        _buildRoundButton(Icons.security, Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CrimeSecurityView()));
        }),
        const SizedBox(height: 12),
        _buildRoundButton(Icons.analytics, Colors.purple, () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const SocioEconomicView()));
        }),
        const SizedBox(height: 12),
        _buildRoundButton(Icons.business, Colors.teal, () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const InfrastructureView()));
        }),
        const SizedBox(height: 12),
        _buildRoundButton(Icons.train, Colors.blue, () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportationView()));
        }),
      ],
    );
  }

  Widget _buildRoundButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Icon(icon, color: color),
      ),
    );
  }

  Widget _buildLocationInfoCard(LocationProvider provider, AppLocalizations l10n) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider.selectedName ?? "Selected Location", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text("${provider.selectedLocation!.latitude.toStringAsFixed(4)}, ${provider.selectedLocation!.longitude.toStringAsFixed(4)}",
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text(l10n.viewDetails),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
