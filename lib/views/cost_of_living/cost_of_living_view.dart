import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../generated/app_localizations.dart';

import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/budget_provider.dart';
import '../../models/budget_scenario.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = Provider.of<LocationProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final currentScenario = budgetProvider.currentScenario;
    
    // Determine which locations to show
    String originName = locationProvider.mode == MapMode.comparison 
        ? (locationProvider.originName ?? l10n.kl)
        : (locationProvider.selectedName ?? l10n.kl);
    
    String destName = locationProvider.mode == MapMode.comparison
        ? (locationProvider.destinationName ?? l10n.jb)
        : l10n.jb; // Default if not in comparison

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleCost),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddScenarioDialog(context),
        icon: const Icon(Icons.add_chart_rounded),
        label: Text(l10n.newScenario),
        backgroundColor: AppColors.primaryBase,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                    child: DropdownButton<String>(
                      value: currentScenario.id,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: budgetProvider.scenarios.map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) budgetProvider.setCurrentScenario(v);
                      },
                    ),
                  ),
                  if (budgetProvider.scenarios.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                      onPressed: () => budgetProvider.deleteScenario(currentScenario.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Location Selector Bento
            BentoCard(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      l10n.locationSelection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.my_location_rounded, size: 16, color: AppColors.primaryBase),
                              const SizedBox(width: 8),
                              Expanded(child: Text(originName, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(Icons.swap_horiz_rounded, color: AppColors.primaryBase, size: 20),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primaryBase),
                              const SizedBox(width: 8),
                              Expanded(child: Text(destName, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hero Summary Card
            BentoCard(
              backgroundColor: AppColors.primaryContainer,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.purchasingPower,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBase,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: l10n.significantImprovement,
                        type: StatusType.success,
                        icon: Icons.trending_up_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '+15.2%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBase,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 8),
                          child: Text(
                            l10n.expectedQualityImprovement,
                            style: const TextStyle(color: AppColors.textSecondaryLight),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Expenditure Comparison Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.housingExpenditure,
                          style: const TextStyle(color: AppColors.textSecondaryLight),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        const Text('-22%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.success)),
                        const SizedBox(height: 4),
                        Text(l10n.monthlySaving('800'), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.foodPrices,
                          style: const TextStyle(color: AppColors.textSecondaryLight),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        const Text('-5%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.success)),
                        const SizedBox(height: 4),
                        Text(l10n.priceCatcherData, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
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

            // Budget Sliders
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.weightAdjustment, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _buildSliderItem(l10n.housing, currentScenario.housingWeight, (v) {
                    budgetProvider.updateCurrentScenario(housingWeight: v);
                  }),
                  _buildSliderItem(l10n.transport, currentScenario.transportWeight, (v) {
                    budgetProvider.updateCurrentScenario(transportWeight: v);
                  }),
                  _buildSliderItem(l10n.entertainment, currentScenario.entertainmentWeight, (v) {
                    budgetProvider.updateCurrentScenario(entertainmentWeight: v);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderItem(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${(value * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryBase,
          inactiveColor: AppColors.primaryContainer,
        ),
      ],
    );
  }
}
