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

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  bool _selectingOrigin = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // 1. The Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(4.2105, 101.9758), // Center of Malaysia
              initialZoom: 6.0,
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
                markers: _buildMarkers(locationProvider),
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
            child: _buildQuickAccessButtons(context, l10n),
          ),

          // 5. Bottom Selection Card (Optional but helpful)
          if (locationProvider.mode == MapMode.display && locationProvider.selectedLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildLocationInfoCard(locationProvider, l10n),
            ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(LocationProvider provider) {
    List<Marker> markers = [];
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
