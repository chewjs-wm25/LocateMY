import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../generated/app_localizations.dart';
import '../../providers/navigation_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 1. Hero Banner Card
          _buildHeroCard(context),
          const SizedBox(height: 16),

          // 2. Metric Square Row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: l10n.unemployment,
                    value: '3.3%',
                    trend: '-0.1%',
                    isPositive: true,
                    icon: Icons.work_outline_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: l10n.medianIncome,
                    value: 'RM 6,338',
                    trend: '+2.4%',
                    isPositive: true,
                    icon: Icons.payments_outlined,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Economic Growth Chart
          _buildGDPChartCard(context),
          const SizedBox(height: 16),

          // 4. Climate & Micro Info
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildClimateCard(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildMicroInfoCard(
                          context,
                          title: l10n.cpiInflation,
                          value: '1.8%',
                          type: StatusType.success,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildMicroInfoCard(
                          context,
                          title: l10n.oprRate,
                          value: '3.00%',
                          type: StatusType.info,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Start Explore Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Provider.of<NavigationProvider>(context, listen: false).setIndex(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBaseAlternative,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.startExploring, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BentoCard(
      height: 220,
      backgroundColor: AppColors.primaryBase,
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatusBadge(
                  label: l10n.favorablePeriod,
                  icon: Icons.check_circle_rounded,
                  type: StatusType.success,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.goodTimeToRelocate,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.stableInflationInfo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '7.5',
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text(l10n.indexLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String trend,
    required bool isPositive,
    required IconData icon,
  }) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textMutedDark, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            trend,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isPositive ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGDPChartCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BentoCard(
      height: 260,
      title: l10n.economicGrowth,
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const titles = ['2020', '2021', '2022', '2023', '2024'];
                    if (value.toInt() >= 0 && value.toInt() < titles.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(titles[value.toInt()], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  const FlSpot(0, 2.5),
                  const FlSpot(1, 3.1),
                  const FlSpot(2, 8.7),
                  const FlSpot(3, 3.7),
                  const FlSpot(4, 4.2),
                ],
                isCurved: true,
                color: AppColors.primaryBaseAlternative,
                barWidth: 4,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBaseAlternative.withValues(alpha: 0.2),
                      AppColors.primaryBaseAlternative.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClimateCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BentoCard(
      height: double.infinity, // 明确告知卡片占据全部可用高度，允许内部 Spacer 正常工作
      backgroundColor: AppColors.warningContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(
              label: l10n.interMonsoon,
              icon: Icons.wb_sunny_rounded,
              type: StatusType.warning,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.lowFloodRisk,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF92400E)),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.idealForMoving,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFFB45309)),
          ),
          const Spacer(),
          Text(
            l10n.nextPeak,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroInfoCard(BuildContext context, {required String title, required String value, required StatusType type}) {
    Color valueColor;
    switch (type) {
      case StatusType.success:
        valueColor = AppColors.success;
        break;
      case StatusType.warning:
        valueColor = AppColors.warning;
        break;
      case StatusType.danger:
        valueColor = AppColors.danger;
        break;
      case StatusType.info:
      default:
        valueColor = AppColors.primaryBaseAlternative;
        break;
    }

    return BentoCard(
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}
