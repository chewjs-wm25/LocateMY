import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../generated/app_localizations.dart';

class TransportationView extends StatelessWidget {
  const TransportationView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleTransport)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                children: [
                  _buildStationItem(
                    context,
                    Icons.train_rounded,
                    'KL Sentral',
                    'MRT / LRT / KTM',
                    '350m',
                    AppColors.primaryBase,
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  _buildStationItem(
                    context,
                    Icons.directions_bus_rounded,
                    'Brickfields Stop',
                    'RapidKL 770, 772',
                    '150m',
                    AppColors.success,
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  _buildStationItem(
                    context,
                    Icons.directions_walk_rounded,
                    l10n.pedestrianBridge,
                    'Nu Sentral Link',
                    '400m',
                    AppColors.info,
                  ),
                ],
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
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubLight,
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: NetworkImage('https://api.placeholder.com/400/180'),
                        fit: BoxFit.cover,
                        opacity: 0.3,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.map_rounded, color: AppColors.accent, size: 40),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mode Distribution
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.commuteModeDistribution, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 20),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '[ fl_chart: PieChart (Rail vs Bus vs Car) ]',
                        style: TextStyle(color: AppColors.textMutedLight),
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
