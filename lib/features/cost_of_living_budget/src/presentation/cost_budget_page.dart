import 'package:flutter/material.dart';
import 'package:locatemy/features/map_location/map_location.dart';

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
      appBar: AppBar(
        title: const Text('Cost of living & budget'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_outcome is CostAnalysisUnavailable) {
      final reason = (_outcome as CostAnalysisUnavailable).failure;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unavailable: ${reason.name}'),
        ),
      );
    }

    if (_outcome is! CostAnalysisAvailable && _outcome is! CostAnalysisPartial) {
      return const Center(child: Text('No cost data available'));
    }

    final analysis = (_outcome is CostAnalysisAvailable)
        ? (_outcome as CostAnalysisAvailable).analysis
        : (_outcome as CostAnalysisPartial).analysis;

    final totalSpend = analysis.observedSpend12 ?? 0;
    final scenarioSpend = analysis.scenarioSpend12 ?? 0;
    final costIndex = analysis.costIndex ?? 0;
    final burden = analysis.locationBudgetBurden ?? analysis.personalBudgetBurden ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analysis.location.displayName ?? analysis.location.locationId,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cost index'),
                      Text('${costIndex.toStringAsFixed(1)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Observed spend / 12 mo'),
                      Text('RM ${totalSpend.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Scenario spend / 12 mo'),
                      Text('RM ${scenarioSpend.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Budget burden'),
                      Text('${burden.toStringAsFixed(1)}%'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price basket',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...analysis.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(item.name),
                          ),
                          Expanded(
                            child: Text(
                              item.localPrice == null
                                  ? '—'
                                  : 'RM ${item.localPrice!.toStringAsFixed(2)}',
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.observedSpend == null
                                  ? '—'
                                  : 'RM ${item.observedSpend!.toStringAsFixed(2)}',
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
