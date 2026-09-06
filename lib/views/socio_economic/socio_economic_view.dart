import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../generated/app_localizations.dart';

import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/analysis/socio_economic_provider.dart';
import '../../widgets/analysis_location_selector.dart';

class SocioEconomicView extends StatefulWidget {
  const SocioEconomicView({super.key});

  @override
  State<SocioEconomicView> createState() => _SocioEconomicViewState();
}

class _SocioEconomicViewState extends State<SocioEconomicView> {
  late TextEditingController _incomeController;
  double _income = 8500;
  int _percentile = 68;

  @override
  void initState() {
    super.initState();
    _incomeController = TextEditingController(text: '8,500');
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  void _updateIncome(String value) {
    final cleanValue = value.replaceAll(',', '');
    final newIncome = double.tryParse(cleanValue) ?? 0;
    setState(() {
      _income = newIncome;
      _percentile = ((newIncome / 20000) * 100).clamp(0, 99).toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = Provider.of<LocationProvider>(context);
    final socioProvider = Provider.of<SocioEconomicProvider>(context);

    final district = locationProvider.selectedName ?? 'Petaling';
    final socioData = socioProvider.socioData;
    final isLoading = socioProvider.isLoading;

    // Trigger fetch
    if (socioData == null && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        socioProvider.loadSocioData(district);
      });
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleSocioEconomic)),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AnalysisLocationSelector(),
            const SizedBox(height: 16),
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
                          '${l10n.incomeClassDistribution} ($district)',
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
                        Text(l10n.rankNumber(socioData?['rank']?.toString() ?? '5'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(
                          l10n.totalConstituencies(socioData?['total_districts']?.toString() ?? '20'),
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
                        Text(
                          socioData?['gini_index']?.toString() ?? '0.407', 
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBase)
                        ),
                        StatusBadge(label: l10n.moderate, type: StatusType.warning),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Interactive Income Position
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.yourIncomePosition, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Text(l10n.monthlyHouseholdIncome, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBase),
                    decoration: InputDecoration(
                      prefixText: 'RM ',
                      prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBase),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: isDarkMode ? AppColors.surfaceSubDark : AppColors.surfaceSubLight,
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
                        borderSide: const BorderSide(color: AppColors.primaryBase, width: 1.5),
                      ),
                    ),
                    onChanged: _updateIncome,
                  ),
                  const SizedBox(height: 16),
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
                            l10n.incomeBetterThan(_percentile.toString()),
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
