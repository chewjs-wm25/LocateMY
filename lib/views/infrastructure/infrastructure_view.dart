import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../generated/app_localizations.dart';

class InfrastructureView extends StatelessWidget {
  const InfrastructureView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleInfrastructure)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          l10n.infrastructureCoverage,
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(label: l10n.excellent, type: StatusType.success),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '85.4',
                    style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white),
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
                _buildServiceItem(context, Icons.water_drop_rounded, l10n.waterSupply, '100%', AppColors.info),
                const SizedBox(width: 12),
                _buildServiceItem(context, Icons.electric_bolt_rounded, l10n.electricNetwork, '99.9%', AppColors.warning),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildServiceItem(context, Icons.local_hospital_rounded, l10n.medicalDensity, l10n.high, AppColors.danger),
                const SizedBox(width: 12),
                _buildServiceItem(context, Icons.school_rounded, l10n.educationalResources, l10n.sufficient, AppColors.success),
              ],
            ),
            const SizedBox(height: 16),

            // Radar Chart Bento
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.iciRadarChart,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.radar_rounded, color: AppColors.primaryTint),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '[ fl_chart: RadarChart ]',
                        style: TextStyle(color: AppColors.textMutedLight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Weight Customizer
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.personalizedWeight, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _buildWeightSlider(l10n.medicalImportance, 0.8),
                  _buildWeightSlider(l10n.educationPriority, 0.6),
                  _buildWeightSlider(l10n.commercialConvenience, 0.4),
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

  Widget _buildWeightSlider(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Slider(
          value: value,
          onChanged: (v) {},
          activeColor: AppColors.primaryBase,
          inactiveColor: AppColors.primaryContainer,
        ),
      ],
    );
  }
}
