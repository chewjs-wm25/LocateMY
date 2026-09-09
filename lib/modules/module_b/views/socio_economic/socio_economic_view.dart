import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:locate_my/core/app_colors.dart';
import 'package:locate_my/shared/widgets/bento_card.dart';
import 'package:locate_my/shared/widgets/status_badge.dart';
import 'package:locate_my/generated/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:locate_my/modules/module_a/location_api.dart';
import 'package:locate_my/modules/module_b/view_models/socio_economic/socio_economic_view_model.dart';
import 'package:locate_my/shared/widgets/analysis_location_selector.dart';

class SocioEconomicView extends StatefulWidget {
  const SocioEconomicView({super.key});

  @override
  State<SocioEconomicView> createState() => _SocioEconomicViewState();
}

class _SocioEconomicViewState extends State<SocioEconomicView> {
  late TextEditingController _incomeController;
  double? _income;

  @override
  void initState() {
    super.initState();
    _incomeController = TextEditingController();
    _incomeController.addListener(_onIncomeChanged);
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  void _onIncomeChanged() {
    final clean = _incomeController.text.replaceAll(',', '');
    final v = double.tryParse(clean);
    if ((v ?? -1) != (_income ?? -1)) {
      setState(() => _income = v);
    }
  }

  /// 触发加载：仅当该位置键尚未尝试加载时（幂等，不会死循环）。
  /// key 必须与 provider 内部 key 完全一致，否则数据已加载仍无法命中。
  void _ensureLoaded(
    SocioEconomicViewModel provider,
    LocationViewModel locationProvider,
  ) {
    final district = locationProvider.selectedName ?? 'Petaling';
    final lat = locationProvider.selectedLocation?.latitude;
    final lng = locationProvider.selectedLocation?.longitude;
    final key = _locKey(district, lat, lng);
    if (!provider.isLoading && provider.requestKey != key) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.loadSocioData(district: district, lat: lat, lng: lng);
      });
    }
  }

  static String _locKey(String district, double? lat, double? lng) {
    return '${district}|${lat?.toStringAsFixed(3) ?? 'na'}|${lng?.toStringAsFixed(3) ?? 'na'}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = Provider.of<LocationViewModel>(context);
    final socioProvider = Provider.of<SocioEconomicViewModel>(context);

    final districtLabel = locationProvider.selectedName ?? 'Petaling';
    final key = _locKey(
      districtLabel,
      locationProvider.selectedLocation?.latitude,
      locationProvider.selectedLocation?.longitude,
    );

    _ensureLoaded(socioProvider, locationProvider);

    final data = socioProvider.socioData;
    // 仅当数据键与当前位置键一致时才展示，避免切换位置时闪现旧地区数据。
    final showData = data != null && socioProvider.requestKey == key;
    final showError =
        !socioProvider.isLoading && data == null && socioProvider.error != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleSocioEconomic)),
      body: showError
          ? _buildError(context, l10n, socioProvider, districtLabel)
          : (socioProvider.isLoading || !showData)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AnalysisLocationSelector(),
                  const SizedBox(height: 16),
                  _buildIncomeHero(context, l10n, data, districtLabel),
                  const SizedBox(height: 16),
                  _buildStatGrid(context, l10n, data),
                  const SizedBox(height: 16),
                  _buildDistributionCurve(context, l10n, data),
                  const SizedBox(height: 16),
                  _buildIncomePosition(context, l10n, socioProvider, data),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildError(
    BuildContext context,
    AppLocalizations l10n,
    SocioEconomicViewModel provider,
    String district,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: AppColors.textMutedLight,
            ),
            const SizedBox(height: 12),
            Text(
              '$district：暂无社会经济数据',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              provider.error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                final lp = Provider.of<LocationViewModel>(
                  context,
                  listen: false,
                );
                provider.loadSocioData(
                  district: district,
                  lat: lp.selectedLocation?.latitude,
                  lng: lp.selectedLocation?.longitude,
                  force: true,
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeHero(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> data,
    String district,
  ) {
    final median = data['median_income'] as num?;
    final year = (data['year'] as String?)?.split('-').first ?? '';
    final shareB40 = (data['class_share_b40'] as num?)?.toDouble();
    final shareM40 = (data['class_share_m40'] as num?)?.toDouble();
    final shareT20 = (data['class_share_t20'] as num?)?.toDouble();
    final b40Ceiling = (data['b40_ceiling'] as num?)?.toDouble();
    final t20Floor = (data['t20_floor'] as num?)?.toDouble();
    final giniEstimated = data['gini_is_estimated'] == true;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  year.isNotEmpty
                      ? '${l10n.incomeClassDistribution} ($year) · $district'
                      : '${l10n.incomeClassDistribution} · $district',
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: giniEstimated ? l10n.dosmOfficialData : 'HIES 官方数据',
                type: giniEstimated ? StatusType.info : StatusType.success,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildClassIndicator(
                context,
                'B40',
                l10n.lowIncome,
                AppColors.warning,
                shareB40,
              ),
              _buildClassIndicator(
                context,
                'M40',
                l10n.middleClass,
                AppColors.primaryBase,
                shareM40,
              ),
              _buildClassIndicator(
                context,
                'T20',
                l10n.highIncome,
                AppColors.success,
                shareT20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 8),
          if (median != null)
            Text(
              '${l10n.medianIncome}: RM ${_fmt(median)}'
              '${year.isNotEmpty ? ' ($year)' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            )
          else
            Text(
              '暂无收入数据',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          if (b40Ceiling != null && t20Floor != null) ...[
            const SizedBox(height: 4),
            Text(
              'B40 门槛 ≤ RM ${_fmt(b40Ceiling)} · T20 门槛 ≥ RM ${_fmt(t20Floor)}（全国官方 HIES 口径）',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMutedLight,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            giniEstimated
                ? '基尼系数暂缺官方值，按收入分布推算（估算）'
                : '基尼系数来自 DOSM HIES 官方数据；阶层占比按官方门槛与该地区收入分布推算',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> data,
  ) {
    final rank = data['rank'];
    final total = data['total_districts'];
    final gini = data['gini_index'] as num?;
    final growth = data['income_growth_pct'] as num?;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BentoCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.leaderboard_rounded,
                  color: AppColors.accent,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.developmentRanking,
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  rank != null ? l10n.rankNumber(rank) : '—',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  total != null ? l10n.totalConstituencies(total) : '',
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
                const Icon(
                  Icons.pie_chart_rounded,
                  color: AppColors.primaryBase,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.giniCoefficient,
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  gini != null
                      ? '${gini.toStringAsFixed(3)}${data['gini_is_estimated'] == true ? '（估算）' : ''}'
                      : '—',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBase,
                  ),
                ),
                if (gini != null)
                  StatusBadge(
                    label: gini < 0.35
                        ? '较均衡'
                        : (gini < 0.45 ? l10n.moderate : '较悬殊'),
                    type: gini < 0.35
                        ? StatusType.success
                        : (gini < 0.45
                              ? StatusType.warning
                              : StatusType.danger),
                  ),
                if (data['gini_is_estimated'] != true &&
                    data['gini_source'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '官方口径（${data['gini_source'] == 'district' ? '县级' : (data['gini_source'] == 'state' ? '州级' : '全国')} HIES）',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textMutedLight,
                      ),
                    ),
                  ),
                if (growth != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '较前年 ${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 家庭月收入分布曲线：由真实收入中位数与 σ 拟合的对数正态密度。
  Widget _buildDistributionCurve(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> data,
  ) {
    final median = (data['median_income'] as num?)?.toDouble();
    final sigma = (data['sigma'] as num?)?.toDouble();
    final lnMedian = (data['ln_median'] as num?)?.toDouble();
    if (median == null || sigma == null || lnMedian == null || sigma <= 0) {
      return const SizedBox.shrink();
    }
    // 采样区间 [median/3, median*3]，覆盖大多数家庭
    final lo = math.log(median / 3);
    final hi = math.log(median * 3);
    final n = 40;
    final spots = <FlSpot>[];
    for (var i = 0; i <= n; i++) {
      final lnX = lo + (hi - lo) * i / n;
      final x = math.exp(lnX);
      final z = (lnX - lnMedian) / sigma;
      final pdf = math.exp(-0.5 * z * z) / (x * sigma * math.sqrt(2 * math.pi));
      spots.add(FlSpot(x, pdf));
    }
    // 中位数所在点做标记
    final medianPdf =
        math.exp(-0.5 * 0) / (median * sigma * math.sqrt(2 * math.pi));

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.incomeDistributionCurve,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Icon(
                Icons.show_chart_rounded,
                color: AppColors.textMutedLight,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '对数正态拟合曲线，σ 已按 HIES 官方基尼校准（非直接官方分布）',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: median / 3,
                maxX: median * 3,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primaryBaseAlternative,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBaseAlternative.withValues(
                            alpha: 0.25,
                          ),
                          AppColors.primaryBaseAlternative.withValues(
                            alpha: 0.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: [FlSpot(median, 0), FlSpot(median, medianPdf)],
                    isCurved: false,
                    color: AppColors.danger,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 3],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '红色虚线为中位数：RM ${_fmt(median)}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomePosition(
    BuildContext context,
    AppLocalizations l10n,
    SocioEconomicViewModel provider,
    Map<String, dynamic> data,
  ) {
    final median = data['median_income'] as num?;
    double? percentile;
    if (_income != null) {
      percentile = provider.incomePercentile(_income!);
    }
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.yourIncomePosition,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.monthlyHouseholdIncome,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBase,
            ),
            decoration: InputDecoration(
              prefixText: 'RM ',
              prefixStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBase,
              ),
              hintText: median != null ? '例如: ${median.round()}' : '输入月收入',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryBase,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (percentile != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: AppColors.primaryBase,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.incomeBetterThan(percentile.toStringAsFixed(0)),
                      style: const TextStyle(
                        color: AppColors.primaryBase,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (median != null && _income != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _income! > median
                    ? '高于该地区家庭收入中位数'
                    : '低于该地区家庭收入中位数 (RM ${median.round()})',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassIndicator(
    BuildContext context,
    String label,
    String desc,
    Color color,
    double? share,
  ) {
    final flex = share != null ? (share * 1000).round().clamp(1, 1000) : 1;
    return Expanded(
      flex: flex,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Container(height: 8, color: color.withValues(alpha: 0.2)),
          const SizedBox(height: 4),
          Text(
            share != null ? '${(share * 100).toStringAsFixed(0)}%' : desc,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(num v) {
    final s = v.round().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}
