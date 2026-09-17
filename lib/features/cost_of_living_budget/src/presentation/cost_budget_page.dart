import 'package:flutter/material.dart';
import 'package:locatemy/features/home_relocation_outlook/src/presentation/home_visual_style.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/l10n/language_controller.dart';

import '../../cost_of_living_budget.dart';

class CostBudgetPage extends StatefulWidget {
  final ValidLocationReference location;
  final CostOfLivingBudget service;
  final Object? returnContext;

  const CostBudgetPage({
    required this.location,
    required this.service,
    this.returnContext,
    super.key,
  });

  @override
  State<CostBudgetPage> createState() => _CostBudgetPageState();
}

class _CostBudgetPageState extends State<CostBudgetPage> {
  CostAnalysisOutcome? _outcome;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    final outcome = await widget.service.analyse(
      CostAnalysisRequest(
        location: widget.location,
        refreshPolicy: CostRefreshPolicy.cacheAllowed,
      ),
    );
    if (!mounted) return;
    setState(() {
      _outcome = outcome;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeVisualStyle.canvas,
      appBar: AppBar(
        backgroundColor: HomeVisualStyle.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Cost of living & budget',
          style: HomeVisualStyle.text(20, weight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: const [LanguageButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Material(color: HomeVisualStyle.canvas, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_outcome is CostAnalysisUnavailable) {
      final reason = (_outcome as CostAnalysisUnavailable).failure;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Unavailable: ${reason.name}',
            style: HomeVisualStyle.text(15, color: HomeVisualStyle.muted),
          ),
        ),
      );
    }

    if (_outcome is! CostAnalysisAvailable &&
        _outcome is! CostAnalysisPartial) {
      return Center(
        child: Text(
          'No cost data available',
          style: HomeVisualStyle.text(15, color: HomeVisualStyle.muted),
        ),
      );
    }

    final analysis = (_outcome is CostAnalysisAvailable)
        ? (_outcome as CostAnalysisAvailable).analysis
        : (_outcome as CostAnalysisPartial).analysis;

    final double totalSpend = analysis.observedSpend12 ?? 0;
    final double scenarioSpend = analysis.scenarioSpend12 ?? 0;
    final double costIndex = analysis.costIndex ?? 0;
    final double? burden =
        analysis.locationBudgetBurden ?? analysis.personalBudgetBurden;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HomeVisualStyle.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.location.displayName ?? analysis.location.locationId,
                  style: HomeVisualStyle.text(
                    20,
                    weight: FontWeight.w700,
                    color: HomeVisualStyle.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'RM ${costIndex.toStringAsFixed(1)}',
                        style: HomeVisualStyle.text(
                          32,
                          weight: FontWeight.w700,
                          color: HomeVisualStyle.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F1FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Cost index',
                        style: HomeVisualStyle.text(
                          11,
                          weight: FontWeight.w600,
                          color: HomeVisualStyle.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MetricRow(
                  label: 'Observed spend / 12 mo',
                  value: 'RM ${totalSpend.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _MetricRow(
                  label: 'Scenario spend / 12 mo',
                  value: 'RM ${scenarioSpend.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _MetricRow(
                  label: 'Budget burden',
                  value: burden == null ? '—' : '${burden.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HomeVisualStyle.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price basket',
                  style: HomeVisualStyle.text(
                    18,
                    weight: FontWeight.w700,
                    color: HomeVisualStyle.ink,
                  ),
                ),
                const SizedBox(height: 12),
                ...analysis.items.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final CostItem item = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: index == analysis.items.length - 1
                          ? null
                          : Border(
                              bottom: BorderSide(color: HomeVisualStyle.border),
                            ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.name,
                            style: HomeVisualStyle.text(
                              14,
                              color: HomeVisualStyle.ink,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.localPrice == null
                                ? '—'
                                : 'RM ${item.localPrice!.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: HomeVisualStyle.text(
                              14,
                              color: HomeVisualStyle.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.observedSpend == null
                                ? '—'
                                : 'RM ${item.observedSpend!.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: HomeVisualStyle.text(
                              14,
                              color: HomeVisualStyle.ink,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: HomeVisualStyle.text(14, color: HomeVisualStyle.muted),
        ),
        Text(value, style: HomeVisualStyle.text(14, weight: FontWeight.w700)),
      ],
    );
  }
}
