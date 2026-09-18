import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locatemy/l10n/app_localizations.dart';

import '../domain/home_models.dart';
import 'home_view_model.dart';
import 'home_trend_chart.dart';
import 'home_visual_style.dart';

final class HomeOutlookPage extends StatefulWidget {
  final HomeRelocationOutlook home;
  final void Function() onExploreMap;
  const HomeOutlookPage({
    required this.home,
    required this.onExploreMap,
    super.key,
  });
  @override
  State<HomeOutlookPage> createState() => _HomeOutlookPageState();
}

final class _HomeOutlookPageState extends State<HomeOutlookPage> {
  late final HomeViewModel vm = HomeViewModel(widget.home, widget.onExploreMap);
  @override
  void initState() {
    super.initState();
    vm.initialize();
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: vm,
    builder: (context, _) {
      final l = AppLocalizations.of(context)!;
      final snapshot = vm.snapshot;
      final locale = Localizations.localeOf(context).toLanguageTag();
      Widget score(int value, {bool hero = false}) => Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$value',
              style: HomeVisualStyle.text(
                hero ? 52 : 22,
                color: hero ? Colors.white : HomeVisualStyle.ink,
                weight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: ' / 100',
              style: HomeVisualStyle.text(
                hero ? 15 : 12,
                color: hero ? HomeVisualStyle.heroUnit : HomeVisualStyle.muted,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
      Widget panel(List<Widget> contents) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HomeVisualStyle.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: contents
              .expand((w) => [w, const SizedBox(height: 8)])
              .toList(),
        ),
      );
      Widget macroCard(String title, MacroMetricCard c) => panel([
        Text(
          title,
          style: HomeVisualStyle.text(13, color: HomeVisualStyle.muted),
        ),
        if (c.score != null)
          score(c.score!)
        else
          Text(
            '${l.homeUnavailable}: ${l.homeReason(c.unavailableReason!.name)}',
            style: HomeVisualStyle.text(13),
          ),
        if (c.directionExplanation != null)
          Text(
            l.homeDirection(c.directionExplanation!.replaceAll('.', '_')),
            style: HomeVisualStyle.text(12, weight: FontWeight.w600),
          ),
        if (c.source.datasetId == 'cpi_headline_inflation')
          Text(
            l.homeCostDirection,
            style: HomeVisualStyle.text(11, color: HomeVisualStyle.muted),
          ),
        HomeTrendChart(
          vm.trendHistory.metrics[c.source.datasetId] ?? const [],
          compact: true,
        ),
      ]);
      Widget hero(HomeOutlookSnapshot s) {
        final timing = s.relocationTiming;
        final lead = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (timing.score != null)
              score(timing.score!, hero: true)
            else
              Text(
                '${l.homeUnavailable}: ${l.homeReason(timing.unavailableReason!.name)}',
                style: HomeVisualStyle.text(16, color: Colors.white),
              ),
            if (timing.status != null)
              Text(
                l.homeDirection(timing.status!.replaceAll('.', '_')),
                style: HomeVisualStyle.text(
                  16,
                  color: timing.status == 'timing.favorable'
                      ? HomeVisualStyle.heroSuccess
                      : HomeVisualStyle.heroUnit,
                  weight: FontWeight.w700,
                ),
              ),
          ],
        );
        final reasons = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final reason in timing.reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  l.homeDirection(reason.text.replaceAll('.', '_')),
                  style: HomeVisualStyle.text(13, color: Colors.white),
                ),
              ),
          ],
        );
        return Container(
          constraints: const BoxConstraints(minHeight: 208),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: HomeVisualStyle.hero,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.homeTiming,
                style: HomeVisualStyle.text(
                  13,
                  color: HomeVisualStyle.heroLabel,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) =>
                    MediaQuery.textScalerOf(context).scale(13) > 18 ||
                        constraints.maxWidth < 280
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [lead, const SizedBox(height: 12), reasons],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: lead),
                          const SizedBox(width: 16),
                          Expanded(flex: 3, child: reasons),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                l.homeNational,
                style: HomeVisualStyle.text(
                  12,
                  color: HomeVisualStyle.heroLabel,
                ),
              ),
            ],
          ),
        );
      }

      final refresh = TextButton.icon(
        key: const ValueKey('home-refresh'),
        onPressed: vm.busy || vm.remainingSeconds > 0 ? null : vm.refresh,
        style: TextButton.styleFrom(
          foregroundColor: HomeVisualStyle.primary,
          textStyle: HomeVisualStyle.text(13, weight: FontWeight.w600),
        ),
        icon: vm.busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh, size: 18),
        label: Text(l.homeRefresh),
      );
      return Material(
        color: HomeVisualStyle.canvas,
        child: SafeArea(
          child: RefreshIndicator(
            key: const ValueKey('home-pull-refresh'),
            onRefresh: vm.refresh,
            color: HomeVisualStyle.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) =>
                        MediaQuery.textScalerOf(context).scale(20) > 27
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.homeGreeting,
                                style: HomeVisualStyle.text(
                                  20,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: refresh,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.homeGreeting,
                                  style: HomeVisualStyle.text(
                                    20,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              refresh,
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  if (vm.remainingSeconds > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          l.homeCooling(vm.remainingSeconds),
                          style: HomeVisualStyle.text(
                            13,
                            color: HomeVisualStyle.muted,
                          ),
                        ),
                      ),
                    ),
                  if (vm.busy && snapshot == null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        l.homeLoading,
                        style: HomeVisualStyle.text(14),
                      ),
                    ),
                  if (vm.unavailable != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        '${l.homeUnavailable}: ${l.homeReason(vm.unavailable!.name)}',
                        style: HomeVisualStyle.text(14),
                      ),
                    ),
                    TextButton(onPressed: vm.refresh, child: Text(l.retry)),
                  ],
                  if (snapshot != null) ...[
                    if (snapshot.completeness == HomeCompleteness.partial)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          l.homePartial,
                          style: HomeVisualStyle.text(
                            13,
                            color: HomeVisualStyle.muted,
                          ),
                        ),
                      ),
                    hero(snapshot),
                    const SizedBox(height: 20),
                  ],
                  if (vm.navigationReason != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          l.homeNavigation(l.homeReason(vm.navigationReason!)),
                          style: HomeVisualStyle.text(13),
                        ),
                      ),
                    ),
                  FilledButton(
                    key: const ValueKey('home-explore'),
                    onPressed: vm.explore,
                    style: FilledButton.styleFrom(
                      backgroundColor: HomeVisualStyle.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: HomeVisualStyle.text(
                        15,
                        weight: FontWeight.w600,
                      ),
                    ),
                    child: Text(l.homeExplore),
                  ),
                  if (snapshot != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      l.homeIndicators,
                      style: HomeVisualStyle.text(18, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cost = macroCard(
                              l.homeCost,
                              snapshot.costPressure,
                            ),
                            employment = macroCard(
                              l.homeEmployment,
                              snapshot.employmentStability,
                            );
                        return constraints.maxWidth < 320 ||
                                MediaQuery.textScalerOf(context).scale(13) > 18
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  cost,
                                  const SizedBox(height: 16),
                                  employment,
                                ],
                              )
                            : IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: cost),
                                    const SizedBox(width: 16),
                                    Expanded(child: employment),
                                  ],
                                ),
                              );
                      },
                    ),
                    const SizedBox(height: 16),
                    macroCard(l.homeEconomy, snapshot.economicMomentum),
                    const SizedBox(height: 16),
                    panel([
                      Text(
                        l.homeIncome,
                        style: HomeVisualStyle.text(
                          13,
                          color: HomeVisualStyle.muted,
                        ),
                      ),
                      if (snapshot.householdMedianIncome.medianIncome != null)
                        Text(
                          l.homeIncomeAmount(
                            NumberFormat.decimalPattern(locale).format(
                              snapshot.householdMedianIncome.medianIncome,
                            ),
                            snapshot.householdMedianIncome.surveyYear
                                .toString(),
                          ),
                          style: HomeVisualStyle.text(
                            22,
                            weight: FontWeight.w700,
                          ),
                        )
                      else
                        Text(
                          '${l.homeUnavailable}: ${l.homeReason(snapshot.householdMedianIncome.unavailableReason!.name)}',
                          style: HomeVisualStyle.text(13),
                        ),
                    ]),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
