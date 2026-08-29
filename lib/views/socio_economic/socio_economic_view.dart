import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../generated/app_localizations.dart';

class SocioEconomicView extends StatelessWidget {
  const SocioEconomicView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleSocioEconomic)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income Class Hero Card
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.incomeClassDistribution,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(label: l10n.dosmOfficialData, type: StatusType.info),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildClassIndicator(context, 'B40', l10n.lowIncome, AppColors.warning, 0.4),
                      _buildClassIndicator(context, 'M40', l10n.middleClass, AppColors.primaryBase, 0.4),
                      _buildClassIndicator(context, 'T20', l10n.highIncome, AppColors.success, 0.2),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: 8),
                  Text(
                    l10n.m40HigherThanAverage('3.5'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ranking and Gini Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: BentoCard(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.leaderboard_rounded, color: AppColors.accent, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          l10n.developmentRanking,
                          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(l10n.rankNumber('5'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(
                          l10n.totalConstituencies('20'),
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
                        const Icon(Icons.pie_chart_rounded, color: AppColors.primaryBase, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          l10n.giniCoefficient,
                          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text('0.407', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBase)),
                        StatusBadge(label: l10n.moderate, type: StatusType.warning),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Income Distribution Chart
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.incomeDistributionCurve, style: Theme.of(context).textTheme.titleMedium),
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
                        '[ fl_chart: Distribution LineChart ]',
                        style: TextStyle(color: AppColors.textMutedLight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Interactive Income Position
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.yourIncomePosition, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(l10n.monthlyHouseholdIncome)),
                      const SizedBox(width: 8),
                      const Text('RM 8,500', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBase)),
                    ],
                  ),
                  Slider(
                    value: 8500,
                    min: 0,
                    max: 30000,
                    onChanged: (v) {},
                    activeColor: AppColors.primaryBase,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: AppColors.primaryBase, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.incomeBetterThan('68'),
                            style: const TextStyle(color: AppColors.primaryBase, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
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

  Widget _buildClassIndicator(BuildContext context, String label, String desc, Color color, double flex) {
    return Expanded(
      flex: (flex * 100).toInt(),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Container(height: 8, color: color.withValues(alpha: 0.2)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.textMutedLight)),
        ],
      ),
    );
  }
}
