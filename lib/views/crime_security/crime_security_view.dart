import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../generated/app_localizations.dart';

import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/analysis/security_provider.dart';
import '../../widgets/mini_map.dart';
import 'package:latlong2/latlong.dart';
import '../app_shell.dart';

import '../../widgets/analysis_location_selector.dart';

import '../property/add_property_screen.dart';

import '../../models/property_inspection.dart';
import '../property/property_detail_screen.dart';
import '../property/property_archive_screen.dart';

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
    final locationProvider = Provider.of<LocationProvider>(context);
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final securityProvider = Provider.of<SecurityProvider>(context);
    
    final latLng = locationProvider.selectedLocation ?? const LatLng(3.1390, 101.6869);
    final securityData = securityProvider.securityData;
    final isLoading = securityProvider.isLoading;

    // Trigger fetch if not loaded
    if (securityData == null && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        securityProvider.loadSecurityData(latLng.latitude, latLng.longitude);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleSecurity),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddProperty(context),
        icon: const Icon(Icons.add_home_work_rounded),
        label: Text(l10n.addProperty),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Inspection Portfolio
            if (propertyProvider.inspections.isNotEmpty) ...[
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
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMutedDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...propertyProvider.inspections.take(3).map((property) => BentoCard(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: InkWell(
                  onTap: () => _navigateToDetail(context, property),
                  child: Row(
                    children: [
                      if (property.hasFloodHistory)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 16),
                        ),
                      Expanded(
                        child: Text(
                          property.name, 
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (property.securityScore != null)
                        StatusBadge(
                          label: property.securityScore!.toString(),
                          type: property.securityScore! >= 7 ? StatusType.success : StatusType.warning,
                        ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMutedDark),
                    ],
                  ),
                ),
              )),
              if (propertyProvider.inspections.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    'and ${propertyProvider.inspections.length - 3} more properties...',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark, fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 8),
            ],

            const AnalysisLocationSelector(),
            const SizedBox(height: 16),

            // Map Bento
            BentoCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${l10n.safetyMapLayer} (${securityData?['district_name'] ?? ""})',
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: MiniMap(
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Safety Rating Grid
            BentoCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.overallSafetyIndex,
                    style: const TextStyle(color: AppColors.textSecondaryLight),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    securityData?['security_score']?.toString() ?? '8.2', 
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold, 
                      color: (securityData?['security_score'] ?? 8.0) > 8 ? AppColors.success : AppColors.warning
                    )
                  ),
                  Text(
                    l10n.betterThanNational('75'),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Crime Type Chips
            Text(l10n.crimeTypeFocus, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text(l10n.violentCrime),
                  selected: true,
                  onSelected: (b) {},
                  selectedColor: AppColors.primaryContainer,
                  checkmarkColor: AppColors.primaryBase,
                ),
                FilterChip(
                  label: Text(l10n.propertyCrime),
                  selected: false,
                  onSelected: (b) {},
                ),
                FilterChip(
                  label: Text(l10n.cyberFraud),
                  selected: false,
                  onSelected: (b) {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Crime Trend Chart
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.crimeTrend, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Text('2019 - 2023', style: TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '[ fl_chart: LineChart ]',
                            style: TextStyle(color: AppColors.textMutedLight),
                          ),
                          if (securityData != null)
                            Text(
                              'Data for ${securityData['district_name']} loaded',
                              style: const TextStyle(fontSize: 10, color: AppColors.textMutedLight),
                            ),
                        ],
                      ),
                    ),
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
}
