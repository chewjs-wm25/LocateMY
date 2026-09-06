import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../generated/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/analysis/transit_provider.dart';
import '../../widgets/mini_map.dart';
import 'package:latlong2/latlong.dart';
import '../app_shell.dart';

import '../../widgets/analysis_location_selector.dart';

class TransportationView extends StatelessWidget {
  const TransportationView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = Provider.of<LocationProvider>(context);
    final transitProvider = Provider.of<TransitProvider>(context);

    final latLng = locationProvider.selectedLocation ?? const LatLng(3.1390, 101.6869);
    final stops = transitProvider.nearbyStops;
    final isLoading = transitProvider.isLoading;

    // Trigger fetch
    if (stops.isEmpty && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        transitProvider.loadNearbyStops(latLng.latitude, latLng.longitude);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleTransport)),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AnalysisLocationSelector(),
            const SizedBox(height: 16),
            // Connectivity Score Bento
            BentoCard(
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
                      StatusBadge(label: l10n.highlyConvenient, type: StatusType.accent, icon: Icons.bolt_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        '72',
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: 0.72,
                                minHeight: 8,
                                backgroundColor: AppColors.accentContainer,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(l10n.betterThanKL('88'), style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Nearest Stations Bento
            Text(l10n.nearbyStations, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            BentoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: stops.map((stop) => Column(
                  children: [
                    _buildStationItem(
                      context,
                      stop['transit_type'] == 'Bus' ? Icons.directions_bus_rounded : Icons.train_rounded,
                      stop['stop_name'],
                      stop['transit_type'],
                      '${stop['distance_meters'].toInt()}m',
                      stop['transit_type'] == 'Bus' ? AppColors.success : AppColors.primaryBase,
                    ),
                    if (stops.indexOf(stop) != stops.length - 1)
                      const Divider(height: 1, color: AppColors.borderLight),
                  ],
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Heatmap Bento
            BentoCard(
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
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(l10n.viewDetails, style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MiniMap(
                    center: latLng,
                    onTap: () {
                      locationProvider.moveTo(latLng);
                      final appShellState = context.findAncestorStateOfType<AppShellState>();
                      if (appShellState != null) {
                        appShellState.onItemTapped(1);
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStationItem(BuildContext context, IconData icon, String name, String lines, String distance, Color color) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
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
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(distance, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBase)),
          Text(l10n.walking, style: const TextStyle(fontSize: 10, color: AppColors.textMutedLight)),
        ],
      ),
      onTap: () {},
    );
  }
}
