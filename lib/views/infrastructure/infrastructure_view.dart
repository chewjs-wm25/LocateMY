import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../generated/app_localizations.dart';

import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/analysis/infrastructure_provider.dart';
import '../../widgets/analysis_location_selector.dart';

class InfrastructureView extends StatelessWidget {
  const InfrastructureView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = Provider.of<LocationProvider>(context);
    final infraProvider = Provider.of<InfrastructureProvider>(context);

    final district = locationProvider.selectedName ?? 'Petaling';
    final infraData = infraProvider.infraData;
    final isLoading = infraProvider.isLoading;

    // Trigger fetch
    if (infraData == null && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        infraProvider.loadInfraData(district);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleInfrastructure)),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AnalysisLocationSelector(),
            const SizedBox(height: 16),
            // ICI Score Bento
            BentoCard(
              backgroundColor: AppColors.primaryBase,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.infrastructureCoverage} ($district)',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: (infraData?['ici_score'] ?? 0) > 80 ? l10n.excellent : l10n.good,
                        type: (infraData?['ici_score'] ?? 0) > 80 ? StatusType.success : StatusType.info
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    infraData?['ici_score']?.toStringAsFixed(1) ?? '85.4',
                    style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.iciDescription,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Service Grid
            Row(
              children: [
                _buildServiceItem(context, Icons.water_drop_rounded, l10n.waterSupply, '${infraData?['scores']?['water'] ?? 100}%', AppColors.info),
                const SizedBox(width: 12),
                _buildServiceItem(context, Icons.electric_bolt_rounded, l10n.electricNetwork, '${infraData?['scores']?['power'] ?? 99.9}%', AppColors.warning),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildServiceItem(context, Icons.local_hospital_rounded, l10n.medicalDensity, '${infraData?['scores']?['healthcare'] ?? 80}%', AppColors.danger),
                const SizedBox(width: 12),
                _buildServiceItem(context, Icons.school_rounded, l10n.educationalResources, '${infraData?['scores']?['education'] ?? 75}%', AppColors.success),
              ],
            ),
            const SizedBox(height: 16),

            // Weight Customizer
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.personalizedWeight, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _buildWeightSlider(l10n.medicalImportance, infraProvider.wHealth, (v) {
                    infraProvider.updateWeights(health: v);
                  }),
                  _buildWeightSlider(l10n.educationPriority, infraProvider.wEdu, (v) {
                    infraProvider.updateWeights(edu: v);
                  }),
                  _buildWeightSlider(l10n.commercialConvenience, infraProvider.wTransit, (v) {
                    infraProvider.updateWeights(transit: v);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, IconData icon, String label, String value, Color color) {
    return Expanded(
      child: BentoCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Slider(
          value: value,
          min: 0.1,
          max: 1.0,
          divisions: 9,
          onChanged: onChanged,
          activeColor: AppColors.primaryBase,
          inactiveColor: AppColors.primaryContainer,
          label: (value * 10).round().toString(),
        ),
      ],
    );
  }
}
