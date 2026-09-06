import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../generated/app_localizations.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/home_provider.dart';
import '../../models/home_stats.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, _) {
        final stats = homeProvider.stats;

        if (homeProvider.isLoading && stats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (stats == null && !homeProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.textMutedLight),
                const SizedBox(height: 16),
                Text(homeProvider.error ?? '无法获取数据', style: const TextStyle(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => homeProvider.loadStats(force: true),
                  child: const Text('重试加载'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => homeProvider.loadStats(force: true),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. Hero Banner Card (搬迁指数)
                _buildHeroCard(context, stats!),
                const SizedBox(height: 16),

                // 2. Metric Square Row (失业率 & 收入)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: l10n.unemployment,
                          value: stats.unemploymentRate != null ? '${stats.unemploymentRate}%' : null,
                          trend: stats.unemploymentTrend != null 
                              ? '${stats.unemploymentTrend! >= 0 ? "+" : ""}${stats.unemploymentTrend!.toStringAsFixed(1)}%' 
                              : null,
                          isPositive: (stats.unemploymentTrend ?? 0) <= 0,
                          icon: Icons.work_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: l10n.medianIncome,
                          value: stats.medianIncome != null ? 'RM ${NumberFormat("#,###").format(stats.medianIncome)}' : null,
                          trend: stats.incomeTrend != null 
                              ? '${stats.incomeTrend! >= 0 ? "+" : ""}${stats.incomeTrend!.toStringAsFixed(1)}%' 
                              : null,
                          isPositive: (stats.incomeTrend ?? 0) >= 0,
                          icon: Icons.payments_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Economic Growth Chart (GDP)
                _buildGDPChartCard(context, stats),
                const SizedBox(height: 16),

                // 4. Micro Info Row (通胀 & OPR)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildMicroInfoCard(
                          context,
                          title: l10n.cpiInflation,
                          value: stats.inflationRate != null ? '${stats.inflationRate!.toStringAsFixed(1)}%' : null,
                          type: (stats.inflationRate ?? 5.0) < 3.0 ? StatusType.success : StatusType.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMicroInfoCard(
                          context,
                          title: l10n.oprRate,
                          value: stats.oprRate != null ? '${stats.oprRate!.toStringAsFixed(2)}%' : null,
                          type: StatusType.info,
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
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(BuildContext context, HomeStats stats) {
    final l10n = AppLocalizations.of(context)!;
    final index = stats.relocationIndex;

    if (index == null) {
      return BentoCard(
        height: 220,
        backgroundColor: AppColors.textMutedLight,
        child: const Center(child: Text('搬迁指数计算中...', style: TextStyle(color: Colors.white))),
      );
    }

    final isFavorable = index >= 6.0;

    return BentoCard(
      height: 220,
      backgroundColor: isFavorable ? AppColors.primaryBase : const Color(0xFF64748B),
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
                  label: isFavorable ? l10n.favorablePeriod : '中性建议',
                  icon: isFavorable ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  type: isFavorable ? StatusType.success : StatusType.info,
                ),
                const SizedBox(height: 12),
                Text(
                  isFavorable ? l10n.goodTimeToRelocate : '建议持币观望',
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
                  isFavorable ? l10n.stableInflationInfo : '当前宏观数据波动，建议谨慎考虑大笔开支。',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                if (stats.isIciFallback)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 12, color: Colors.white.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          'ICI 数据暂缺，指数基于国家基准值计算',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
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
                    Text(
                      index.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
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
    required String? value,
    required String? trend,
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
          if (value != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
              ),
            )
          else
            const Text('暂无数据', style: TextStyle(fontSize: 14, color: AppColors.textMutedLight)),
          const SizedBox(height: 12),
          if (trend != null)
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

  Widget _buildGDPChartCard(BuildContext context, HomeStats stats) {
    final l10n = AppLocalizations.of(context)!;
    final trend = stats.gdpTrend;

    return BentoCard(
      height: 260,
      title: l10n.economicGrowth,
      child: SizedBox(
        height: 180,
        child: (trend == null || trend.isEmpty) 
          ? const Center(child: Text('数据获取失败', style: TextStyle(color: AppColors.textMutedLight)))
          : LineChart(
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
                        final index = value.toInt();
                        if (index >= 0 && index < trend.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(trend[index].year, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
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
                    spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
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

  Widget _buildMicroInfoCard(BuildContext context, {required String title, required String? value, required StatusType type}) {
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
          if (value != null)
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor))
          else
            const Text('-', style: TextStyle(color: AppColors.textMutedLight)),
        ],
      ),
    );
  }
}
