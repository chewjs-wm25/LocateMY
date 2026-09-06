import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../generated/app_localizations.dart';

import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/analysis/infrastructure_provider.dart';
import '../../widgets/analysis_location_selector.dart';

class InfrastructureView extends StatelessWidget {
  const InfrastructureView({super.key});

  void _ensureLoaded(
    InfrastructureProvider provider,
    LocationProvider locationProvider,
  ) {
    final district = locationProvider.selectedName ?? 'Petaling';
    final selected = locationProvider.selectedLocation;
    final key = _locKey(district, selected?.latitude, selected?.longitude);
    if (!provider.isLoading && provider.requestKey != key) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.loadInfraData(
          district: district,
          lat: selected?.latitude,
          lng: selected?.longitude,
        );
      });
    }
  }

  /// 与 provider 内部 key 完全一致（无坐标时为 'na'）。
  static String _locKey(String district, double? lat, double? lng) {
    return '${district}|${lat?.toStringAsFixed(3) ?? 'na'}|${lng?.toStringAsFixed(3) ?? 'na'}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = Provider.of<LocationProvider>(context);
    final infraProvider = Provider.of<InfrastructureProvider>(context);

    final district = locationProvider.selectedName ?? 'Petaling';
    final infraData = infraProvider.infraData;
    final isLoading = infraProvider.isLoading;

    _ensureLoaded(infraProvider, locationProvider);

    final scores = infraData?['scores'] as Map<String, dynamic>?;
    final iciScore = infraProvider.weightedIciScore ??
        (infraData?['ici_score'] as num?)?.toDouble();

    final key = _locKey(
      district,
      locationProvider.selectedLocation?.latitude,
      locationProvider.selectedLocation?.longitude,
    );
    final showData = infraData != null && infraProvider.requestKey == key;
    final showError =
        !isLoading && infraData == null && infraProvider.error != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleInfrastructure)),
      body: showError
          ? _buildError(context, l10n, infraProvider, district)
          : (isLoading || !showData)
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AnalysisLocationSelector(),
                          const SizedBox(height: 16),
                          _buildIciHero(context, l10n, district, iciScore),
                          const SizedBox(height: 16),
                          _buildServiceGrid(context, l10n, scores),
                          const SizedBox(height: 16),
                          _buildWeightCard(context, l10n, infraProvider, scores),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildError(BuildContext context, AppLocalizations l10n,
      InfrastructureProvider provider, String district) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.textMutedLight),
            const SizedBox(height: 12),
            Text('$district：暂无基础设施数据',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              provider.error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                final lp = Provider.of<LocationProvider>(context, listen: false);
                provider.loadInfraData(
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

  Widget _buildIciHero(BuildContext context, AppLocalizations l10n,
      String district, double? iciScore) {
    final display = iciScore?.toStringAsFixed(1) ?? '—';
    return BentoCard(
      backgroundColor: AppColors.primaryBase,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${l10n.infrastructureCoverage} ($district)',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (iciScore != null)
                StatusBadge(
                  label: iciScore > 80 ? l10n.excellent : l10n.good,
                  type: iciScore > 80 ? StatusType.success : StatusType.info,
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            display,
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.iciDescription,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String? _scoreText(Map<String, dynamic>? scores, String key) {
    final v = scores?[key];
    if (v is num) return '${v.toStringAsFixed(1)}%';
    return null;
  }

  Widget _buildServiceGrid(
      BuildContext context, AppLocalizations l10n, Map<String, dynamic>? scores) {
    return Column(
      children: [
        Row(
          children: [
            _buildServiceItem(
                context, Icons.water_drop_rounded, l10n.waterSupply,
                _scoreText(scores, 'water'), AppColors.info),
            const SizedBox(width: 12),
            _buildServiceItem(
                context, Icons.electric_bolt_rounded, l10n.electricNetwork,
                _scoreText(scores, 'power'), AppColors.warning),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildServiceItem(
                context, Icons.local_hospital_rounded, l10n.medicalDensity,
                _scoreText(scores, 'healthcare'), AppColors.danger),
            const SizedBox(width: 12),
            _buildServiceItem(
                context, Icons.school_rounded, l10n.educationalResources,
                _scoreText(scores, 'education'), AppColors.success),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceItem(BuildContext context, IconData icon, String label,
      String? value, Color color) {
    return Expanded(
      child: BentoCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                  Text(value ?? '—',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCard(BuildContext context, AppLocalizations l10n,
      InfrastructureProvider provider, Map<String, dynamic>? scores) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.personalizedWeight, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _buildWeightSlider(l10n.medicalImportance, provider.wHealth, (v) {
            provider.updateWeights(health: v);
          }, scores?['healthcare']),
          _buildWeightSlider(l10n.educationPriority, provider.wEdu, (v) {
            provider.updateWeights(edu: v);
          }, scores?['education']),
          _buildWeightSlider(l10n.commercialConvenience, provider.wTransit, (v) {
            provider.updateWeights(transit: v);
          }, scores?['transit']),
          const SizedBox(height: 8),
          Text(
            'ICI (等权重计算): ${provider.weightedIciScore?.toStringAsFixed(1) ?? '—'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSlider(String label, double value, ValueChanged<double> onChanged, Object? raw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              raw is num ? '${raw.toStringAsFixed(1)}分' : '',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0.1,
          max: 1.0,
          divisions: 9,
          onChanged: onChanged,
          activeColor: AppColors.primaryBase,
          inactiveColor: AppColors.primaryContainer,
          label: (value * 10).round().toString(),
        ),
      ],
    );
  }
}
