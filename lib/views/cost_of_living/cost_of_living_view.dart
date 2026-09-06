import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../generated/app_localizations.dart';

import '../../widgets/analysis_location_selector.dart';

import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/budget_provider.dart';
// import '../../models/budget_scenario.dart';

class CostOfLivingView extends StatelessWidget {
  const CostOfLivingView({super.key});

  void _showAddScenarioDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newScenario),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: l10n.scenarioName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              context.read<BudgetProvider>().addScenario(controller.text);
              Navigator.pop(context);
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  void _showEditScenarioDialog(BuildContext context, String id, String currentName) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editScenario),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: l10n.scenarioName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              context.read<BudgetProvider>().renameScenario(id, controller.text);
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
    final locationProvider = Provider.of<LocationProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final currentScenario = budgetProvider.currentScenario;
    final comparison = budgetProvider.comparisonData;
    final isLoading = budgetProvider.isLoading;
    
    String originName = locationProvider.mode == MapMode.comparison 
        ? (locationProvider.originName ?? l10n.kl)
        : (locationProvider.selectedName ?? l10n.kl);
    
    String destName = locationProvider.mode == MapMode.comparison
        ? (locationProvider.destinationName ?? l10n.jb)
        : l10n.jb;

    // Trigger fetch if not loaded or location changed
    if (comparison == null && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        budgetProvider.fetchComparison(originName, destName);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleCost),
      ),
      body: isLoading 
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
                  const Icon(Icons.psychology_rounded, color: AppColors.primaryBase),
                  const SizedBox(width: 12),
                  Expanded(
                    child: currentScenario == null 
                        ? const Text('No Scenarios')
                        : DropdownButton<String>(
                            value: currentScenario.id,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: budgetProvider.scenarios.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            )).toList(),
                            onChanged: (v) {
                              if (v != null) budgetProvider.setCurrentScenario(v);
                            },
                          ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryBase),
                    onPressed: () => _showAddScenarioDialog(context),
                    tooltip: l10n.newScenario,
                  ),
                  if (currentScenario != null) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondaryLight),
                      onPressed: () => _showEditScenarioDialog(context, currentScenario.id, currentScenario.name),
                      tooltip: l10n.edit,
                    ),
                    if (budgetProvider.scenarios.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () => budgetProvider.deleteScenario(currentScenario.id),
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
                        label: (comparison?['is_improvement'] ?? true) ? l10n.significantImprovement : l10n.expenseIncrease,
                        type: (comparison?['is_improvement'] ?? true) ? StatusType.success : StatusType.danger,
                        icon: (comparison?['is_improvement'] ?? true) ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'RM ${comparison?['base_budget']?.toStringAsFixed(0) ?? "5,000"} → RM ${comparison?['equivalent_budget']?.toStringAsFixed(0) ?? "4,250"}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBase,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.lifestyleComparisonText(destName, comparison?['purchasing_power_change']?.toStringAsFixed(1) ?? '15.2', l10n.less, originName),
                    style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Interactive Budget Editor
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.budgetTranslation,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.edit_note_rounded, color: AppColors.textMutedLight),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (comparison != null)
                    ... (comparison['categories'] as List).map((cat) => Column(
                      children: [
                        _buildBudgetInputRow(cat['name'], cat['origin'], cat['target'], context),
                        const Divider(height: 24),
                      ],
                    )).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Micro-Price Insight (5km Geofence)
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: Text(l10n.viewStores, style: const TextStyle(fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.realTimePriceComparison,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                  ),
                  const SizedBox(height: 16),
                  if (comparison != null)
                    ... (comparison['micro_prices'] as List).map((item) => 
                        _buildPriceItem(item['item_name'], 'RM ${(item['price'] * 1.1).toStringAsFixed(2)}', 'RM ${item['price'].toStringAsFixed(2)}', true)
                    ).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Chart Placeholder with Bento Styling
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.expenditureComparison,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Icon(Icons.bar_chart_rounded, color: AppColors.textMutedLight),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '[ fl_chart: BarChart Placeholder ]',
                        style: TextStyle(color: AppColors.textMutedLight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetInputRow(String label, double originVal, double targetVal, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(l10n.monthly, style: const TextStyle(fontSize: 10, color: AppColors.textMutedLight)),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: TextFormField(
            initialValue: originVal.toStringAsFixed(0),
            decoration: const InputDecoration(
              prefixText: 'RM ',
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textMutedLight),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubLight,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'RM ${targetVal.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBase),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceItem(String name, String originPrice, String targetPrice, bool isCheaper) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
          Row(
            children: [
              Text(originPrice, style: const TextStyle(fontSize: 13, decoration: TextDecoration.lineThrough, color: AppColors.textMutedLight)),
              const SizedBox(width: 12),
              Text(
                targetPrice,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCheaper ? AppColors.success : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(width: 4),
              if (isCheaper)
                const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.success)
            ],
          ),
        ],
      ),
    );
  }
}
