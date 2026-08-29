import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../generated/app_localizations.dart';

import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';

class CrimeSecurityView extends StatelessWidget {
  const CrimeSecurityView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = Provider.of<LocationProvider>(context);
    String locationName = locationProvider.selectedName ?? l10n.cherasArea;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleSecurity)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            l10n.safetyMapLayer,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: locationName,
                          type: StatusType.info,
                          icon: Icons.location_city_rounded,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      image: DecorationImage(
                        image: NetworkImage('https://api.placeholder.com/400/220'),
                        fit: BoxFit.cover,
                        opacity: 0.5,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '[ flutter_map: OpenStreetMap ]',
                        style: TextStyle(color: AppColors.primaryBase, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Safety Rating Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: BentoCard(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.overallSafetyIndex,
                          style: const TextStyle(color: AppColors.textSecondaryLight),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text('82', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.success)),
                        Text(
                          l10n.betterThanNational('75'),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BentoCard(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.floodRiskLevel,
                          style: const TextStyle(color: AppColors.textSecondaryLight),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        StatusBadge(
                          label: l10n.lowRisk,
                          type: StatusType.success,
                          icon: Icons.water_drop_rounded,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.noFloodHistory,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                    child: const Center(
                      child: Text(
                        '[ fl_chart: LineChart ]',
                        style: TextStyle(color: AppColors.textMutedLight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Warning Banner
            BentoCard(
              backgroundColor: AppColors.dangerContainer,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.warningBanner,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500),
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
