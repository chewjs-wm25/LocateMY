import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:locate_my/core/app_colors.dart';
import 'package:locate_my/shared/widgets/bento_card.dart';
import 'package:locate_my/shared/widgets/status_badge.dart';
import 'package:locate_my/generated/app_localizations.dart';

import 'package:locate_my/shared/widgets/analysis_location_selector.dart';

import 'package:provider/provider.dart';
import 'package:locate_my/modules/module_a/location_api.dart';
import 'package:locate_my/modules/module_b/view_models/cost_of_living/budget_view_model.dart';

// import 'package:locate_my/modules/module_b/models/cost_of_living/budget_scenario.dart';

class CostOfLivingView extends StatelessWidget {
  const CostOfLivingView({super.key});

  void _showAddScenarioDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newScenario),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n.scenarioName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<BudgetViewModel>().addScenario(controller.text);
              Navigator.pop(context);
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  void _showEditScenarioDialog(
    BuildContext context,
    String id,
    String currentName,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editScenario),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n.scenarioName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<BudgetViewModel>().renameScenario(
                id,
                controller.text,
              );
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = Provider.of<LocationViewModel>(context);
    final budgetProvider = Provider.of<BudgetViewModel>(context);
    final currentScenario = budgetProvider.currentScenario;
    final comparison = budgetProvider.comparisonData;
    final isLoading = budgetProvider.isLoading;

    String originName = locationProvider.mode == MapMode.comparison
        ? (locationProvider.originName ?? l10n.kl)
        : (locationProvider.selectedName ?? l10n.kl);

    String destName = locationProvider.mode == MapMode.comparison
        ? (locationProvider.destinationName ?? l10n.jb)
        : l10n.jb;

    // Trigger fetch if not loaded (幂等：同一组地区只请求一次)
    final fetchKey = '$originName|$destName';
    if (!isLoading && budgetProvider.requestKey != fetchKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        budgetProvider.fetchComparison(originName, destName);
      });
    }

    final hasCurrent =
        comparison != null && budgetProvider.requestKey == fetchKey;
    final showError =
        !isLoading &&
        budgetProvider.requestKey == fetchKey &&
        comparison == null &&
        budgetProvider.error != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleCost)),
      body: showError
          ? Center(
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
                      '$originName → $destName：暂无生活开销数据',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      budgetProvider.error ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => budgetProvider.fetchComparison(
                        originName,
                        destName,
                        force: true,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              ),
            )
          : (isLoading || !hasCurrent)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scenario Selector
                  BentoCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.psychology_rounded,
                          color: AppColors.primaryBase,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: currentScenario == null
                              ? const Text('No Scenarios')
                              : DropdownButton<String>(
                                  value: currentScenario.id,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: budgetProvider.scenarios
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s.id,
                                          child: Text(
                                            s.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null)
                                      budgetProvider.setCurrentScenario(v);
                                  },
                                ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: AppColors.primaryBase,
                          ),
                          onPressed: () => _showAddScenarioDialog(context),
                          tooltip: l10n.newScenario,
                        ),
                        if (currentScenario != null) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.textSecondaryLight,
                            ),
                            onPressed: () => _showEditScenarioDialog(
                              context,
                              currentScenario.id,
                              currentScenario.name,
                            ),
                            tooltip: l10n.edit,
                          ),
                          if (budgetProvider.scenarios.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.danger,
                              ),
                              onPressed: () => budgetProvider.deleteScenario(
                                currentScenario.id,
                              ),
                              tooltip: l10n.delete,
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const AnalysisLocationSelector(),
                  const SizedBox(height: 16),

                  // Hero Summary Card - Lifestyle Translation
                  BentoCard(
                    backgroundColor: AppColors.primaryContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.purchasingPower,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBase,
                                fontSize: 16,
                              ),
                            ),
                            StatusBadge(
                              label: (comparison['is_improvement'] ?? true)
                                  ? l10n.significantImprovement
                                  : l10n.expenseIncrease,
                              type: (comparison['is_improvement'] ?? true)
                                  ? StatusType.success
                                  : StatusType.danger,
                              icon: (comparison['is_improvement'] ?? true)
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if ((comparison['base_budget'] as num?) != null)
                          Text(
                            'RM ${_moneyFmt(comparison['base_budget'])} → RM ${_moneyFmt(comparison['equivalent_budget'])}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBase,
                            ),
                          )
                        else
                          _BudgetConverter(
                            originCpi: comparison['origin_cpi'],
                            targetCpi: comparison['target_cpi'],
                          ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.lifestyleComparisonText(
                            destName,
                            (comparison['budget_diff_pct'] as num?)
                                    ?.toStringAsFixed(1) ??
                                '0.0',
                            (comparison['is_improvement'] ?? false)
                                ? l10n.less
                                : l10n.more,
                            originName,
                          ),
                          style: const TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CPI 与预算平移摘要
                  BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.budgetTranslation,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _buildCpiRow(
                          '${comparison['origin_district'] ?? originName} (${comparison['origin_state'] ?? '-'})',
                          comparison['origin_cpi'],
                          Icons.location_on_rounded,
                          AppColors.primaryBase,
                        ),
                        const Divider(height: 20),
                        _buildCpiRow(
                          '${comparison['target_district'] ?? destName} (${comparison['target_state'] ?? '-'})',
                          comparison['target_cpi'],
                          Icons.flag_rounded,
                          AppColors.accent,
                        ),
                        const Divider(height: 20),
                        if ((comparison['base_budget'] as num?) != null)
                          Text(
                            'RM ${_moneyFmt(comparison['base_budget'])} 预算在新地区等值于 RM ${_moneyFmt(comparison['equivalent_budget'])}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondaryLight,
                            ),
                          )
                        else
                          Text(
                            '输入当前月支出预算即可实时换算等效预算（依据两地最新 CPI）',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Micro-Price Insight（真实 PriceCatcher 均价）
                  BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                l10n.microPriceInsight,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.map_outlined, size: 16),
                              label: Text(
                                l10n.viewStores,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.realTimePriceComparison,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (comparison['micro_prices'] is List &&
                            (comparison['micro_prices'] as List).isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '目标地区暂无已收录的商品均价',
                              style: TextStyle(
                                color: AppColors.textMutedLight,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ...(comparison['micro_prices'] as List)
                              .take(8)
                              .map(
                                (item) => _buildPriceItem(
                                  (item as Map)['item_name']?.toString() ?? '—',
                                  _priceFmt(item['price']),
                                  true,
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 物价对比图（PriceCatcher 真实均价，同商品两地对齐）
                  _PriceComparisonChart(
                    originPrices:
                        comparison['origin_prices'] as List? ?? const [],
                    targetPrices:
                        comparison['micro_prices'] as List? ?? const [],
                    title: l10n.expenditureComparison,
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildCpiRow(String label, Object? index, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(
          index is num ? 'CPI ${index.toStringAsFixed(1)}' : '暂无 CPI',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _priceFmt(Object? v) {
    final num? n = v is num ? v : double.tryParse(v?.toString() ?? '');
    if (n == null) return '—';
    return n.toStringAsFixed(2);
  }

  String _moneyFmt(Object? v) {
    final num? n = v is num ? v : double.tryParse(v?.toString() ?? '');
    if (n == null) return '—';
    return n.round().toString();
  }

  Widget _buildPriceItem(String name, String targetPrice, bool isCheaper) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
          Row(
            children: [
              Text(
                'RM $targetPrice',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 两地物价对比图：取两端都收录的同名商品（PriceCatcher 真实均价），
/// 用 fl_chart 分组柱状图并排显示；无相同商品时给出说明而不展示假数据。
class _PriceComparisonChart extends StatelessWidget {
  final List<dynamic> originPrices;
  final List<dynamic> targetPrices;
  final String title;

  const _PriceComparisonChart({
    required this.originPrices,
    required this.targetPrices,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final originByName = <String, double>{};
    for (final raw in originPrices) {
      final m = raw as Map;
      final name = m['item_name']?.toString();
      final price = m['price'];
      if (name == null || price is! num) continue;
      originByName[name] = price.toDouble();
    }
    final rows = <({String name, double origin, double target})>[];
    for (final raw in targetPrices) {
      final m = raw as Map;
      final name = m['item_name']?.toString();
      final price = m['price'];
      if (name == null || price is! num) continue;
      final o = originByName[name];
      if (o != null) {
        rows.add((name: name, origin: o, target: price.toDouble()));
      }
    }
    rows.sort((a, b) => b.origin.compareTo(a.origin));

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(
                Icons.bar_chart_rounded,
                color: AppColors.textMutedLight,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '两地暂无相同商品均价可对比（数据源：KPDN PriceCatcher）',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMutedLight,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else ...[
            const SizedBox(height: 8),
            _buildLegend(),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
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
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= rows.length)
                            return const SizedBox.shrink();
                          final name = rows[i].name;
                          final short = name.length > 12
                              ? '${name.substring(0, 11)}…'
                              : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              short,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF64748B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < rows.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 3,
                        barRods: [
                          BarChartRodData(
                            toY: rows[i].origin,
                            width: 8,
                            color: AppColors.primaryBase.withValues(
                              alpha: 0.55,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                          BarChartRodData(
                            toY: rows[i].target,
                            width: 8,
                            color: AppColors.accent.withValues(alpha: 0.85),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ],
                      ),
                  ],
                  maxY:
                      rows
                          .map((e) => e.origin > e.target ? e.origin : e.target)
                          .reduce((a, b) => a > b ? a : b) *
                      1.15,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(AppColors.primaryBase.withValues(alpha: 0.55), '现居地'),
        const SizedBox(width: 16),
        _dot(AppColors.accent, '目标地'),
      ],
    );
  }

  Widget _dot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// 预算平移换算器：由用户输入“现居地月支出”，
/// 用数据库返回的两地真实 CPI 比例实时计算目标地等效预算。
/// 不含任何写死的默认金额。
class _BudgetConverter extends StatefulWidget {
  final Object? originCpi;
  final Object? targetCpi;

  const _BudgetConverter({this.originCpi, this.targetCpi});

  @override
  State<_BudgetConverter> createState() => _BudgetConverterState();
}

class _BudgetConverterState extends State<_BudgetConverter> {
  final TextEditingController _controller = TextEditingController();
  double? _budget;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final v = double.tryParse(value.replaceAll(',', ''));
    if (v != _budget) setState(() => _budget = v);
  }

  @override
  Widget build(BuildContext context) {
    final origin = (widget.originCpi as num?)?.toDouble();
    final target = (widget.targetCpi as num?)?.toDouble();
    final ratio = (origin != null && target != null && origin > 0)
        ? target / origin
        : null;

    double? equivalent;
    if (ratio != null && _budget != null && _budget! > 0) {
      equivalent = _budget! * ratio;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: _onChanged,
          decoration: InputDecoration(
            prefixText: 'RM ',
            hintText: '输入当前月支出',
            filled: true,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBase,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          equivalent != null
              ? '等效预算: RM ${equivalent.round()}'
              : '输入预算后将按真实 CPI 换算等效预算',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
