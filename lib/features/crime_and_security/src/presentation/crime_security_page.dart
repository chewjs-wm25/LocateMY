import 'package:flutter/material.dart';
import 'package:locatemy/l10n/app_localizations.dart';
import 'package:locatemy/features/map_location/src/domain/location_models.dart';

import '../domain/safety_models.dart';
import 'crime_view_model.dart';
import 'safety_trend_chart.dart';

class CrimeSecurityPage extends StatefulWidget {
  final ValidLocationReference location;
  final CrimeAndSecurity service;
  final Object? returnContext;

  const CrimeSecurityPage({
    required this.location,
    required this.service,
    this.returnContext,
    super.key,
  });

  @override
  State<CrimeSecurityPage> createState() => _CrimeSecurityPageState();
}

class _CrimeSecurityPageState extends State<CrimeSecurityPage> {
  late CrimeViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = CrimeViewModel(
      service: widget.service,
      initialLocation: widget.location,
    );
    vm.load();
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(l.crimeSafetyIndex),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(
            context,
            CrimeReturnToMapIntent(
              location: widget.location,
              returnContext: widget.returnContext,
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final state = vm.state;
          if (state is CrimeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CrimeError) {
            return _buildError(l, state.reason);
          }
          if (state is CrimeLoaded) {
            return _buildContent(l, state.snapshot);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildError(AppLocalizations l, SafetyUnavailableReason reason) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            reason == SafetyUnavailableReason.stateUnresolved
                ? l.crimeStateUnresolved
                : l.crimeUnavailable,
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => vm.load(policy: SafetyLoadPolicy.refresh),
            child: Text(l.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l, SafetySnapshot snapshot) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIndexCard(l, snapshot),
          const SizedBox(height: 16),
          _buildTrendCard(l, snapshot),
          const SizedBox(height: 24),
          _buildActions(l),
        ],
      ),
    );
  }

  Widget _buildIndexCard(AppLocalizations l, SafetySnapshot snapshot) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              snapshot.state.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: snapshot.score.value / 100,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xFFEAF2FF),
                    color: const Color(0xFF155EEF),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${snapshot.score.value}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const Text(
                      '/ 100',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${l.crimeAnnualCases}: ${snapshot.latestCompleteYearCount.value}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF667085)),
            ),
            if (snapshot.completeness == SafetyCompleteness.partial)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l.crimePartialData,
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              l.crimeSourceYear(snapshot.latestCompleteYearCount.year),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(AppLocalizations l, SafetySnapshot snapshot) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.crimeTrendTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCategoryChips(l, snapshot),
            const SizedBox(height: 16),
            SafetyTrendChart(trend: snapshot.trend),
            const SizedBox(height: 8),
            Text(
              l.crimeTrendNote,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(AppLocalizations l, SafetySnapshot snapshot) {
    return Wrap(
      spacing: 8,
      children: snapshot.availableFilters.map((filter) {
        final isSelected =
            snapshot.trend.filter.runtimeType == filter.runtimeType &&
            (filter is! CategoryTrend ||
                (snapshot.trend.filter as CategoryTrend).category ==
                    filter.category);

        String label = '';
        if (filter is AllCrimeTrend) label = l.crimeCategoryAll;
        if (filter is CategoryTrend) {
          label = filter.category == CrimeCategory.assault
              ? l.crimeCategoryAssault
              : l.crimeCategoryProperty;
        }

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => vm.updateFilter(filter),
          selectedColor: const Color(0xFFEAF2FF),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF155EEF) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions(AppLocalizations l) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () => Navigator.maybePop(
            context,
            PropertyArchiveIntent(returnContext: widget.returnContext),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Center(child: Text(l.crimeViewPortfolio)),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => Navigator.maybePop(
            context,
            PropertyAddIntent(returnContext: widget.returnContext),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF155EEF),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Center(child: Text(l.crimeAddProperty)),
        ),
      ],
    );
  }
}
