// Explicit constructors follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/facility_models.dart';
import 'facility_text.dart';

/// Projects the provider's original snapshot without querying or recomputing it.
final class NearbyFacilitiesSummaryCard extends StatelessWidget {
  final NearbyFacilitiesSummaryContribution contribution;
  const NearbyFacilitiesSummaryCard({
    required NearbyFacilitiesSummaryContribution contribution,
    super.key,
  }) : contribution = contribution;
  @override
  Widget build(BuildContext context) {
    return _Snapshot(
      location: contribution.location,
      outcome: contribution.outcome,
    );
  }
}

final class NearbyFacilitiesComparisonCard extends StatelessWidget {
  final NearbyFacilitiesComparisonContribution contribution;
  const NearbyFacilitiesComparisonCard({
    required NearbyFacilitiesComparisonContribution contribution,
    super.key,
  }) : contribution = contribution;
  @override
  Widget build(BuildContext context) {
    final FacilityText text = FacilityText(context);
    final FacilityComparisonOutcome outcome = contribution.outcome;
    FacilityAnalysisOutcome a;
    FacilityAnalysisOutcome b;
    String status;
    if (outcome is FacilityComparisonAvailable) {
      a = FacilityAnalysisAvailable(analysis: outcome.comparison.locationA);
      b = FacilityAnalysisAvailable(analysis: outcome.comparison.locationB);
      status = text.pick(
        'A/B 可比较 · 同半径与分类版本',
        'A/B comparable · same radius and mapping',
      );
    } else if (outcome is FacilityComparisonNotComparable) {
      a = outcome.locationA;
      b = outcome.locationB;
      status =
          "${text.pick('无法比较', 'Not comparable')}: ${text.comparisonFailure(outcome.failure)}";
    } else {
      final FacilityComparisonUnavailable unavailable =
          outcome as FacilityComparisonUnavailable;
      a = FacilityAnalysisUnavailable(failure: unavailable.failure);
      b = a;
      status = text.failure(unavailable.failure);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(status),
        const Text('A'),
        _Snapshot(location: contribution.locationA, outcome: a),
        const Text('B'),
        _Snapshot(location: contribution.locationB, outcome: b),
      ],
    );
  }
}

final class _Snapshot extends StatelessWidget {
  final ValidLocationReference location;
  final FacilityAnalysisOutcome outcome;
  const _Snapshot({
    required ValidLocationReference location,
    required FacilityAnalysisOutcome outcome,
  }) : location = location,
       outcome = outcome;
  @override
  Widget build(BuildContext context) {
    final FacilityText text = FacilityText(context);
    final List<Widget> details = <Widget>[
      Text(location.displayName ?? text.pick('所选地点', 'Selected location')),
    ];
    final FacilityAnalysisOutcome snapshot = outcome;
    if (snapshot is FacilityAnalysisAvailable) {
      final FacilityAnalysis analysis = snapshot.analysis;
      int covered = 0;
      bool complete = analysis.categories.length == 5;
      for (final FacilityCategoryResult category in analysis.categories) {
        if (category.state == FacilityCategoryState.unknown) {
          complete = false;
        }
        if (category.state == FacilityCategoryState.covered) {
          covered += 1;
        }
        details.add(
          Text(
            '${text.category(category.category)}: ${category.count ?? (category.state == FacilityCategoryState.completeEmpty ? 0 : text.pick('数量未知', 'Count unknown'))}',
          ),
        );
      }
      if (complete) {
        details.insert(
          1,
          Text('${text.pick('范围内覆盖', 'Category coverage')} $covered / 5'),
        );
      }
      details.add(
        Text(
          '${analysis.radiusMetres} m · ${analysis.mappingVersion} · ${analysis.dataState == FacilityDataState.cached ? text.pick('缓存结果', 'Cached result') : text.pick('实时查询', 'Live result')}',
        ),
      );
      details.add(
        Text(
          '${text.pick('查询时间', 'Queried at')}: ${analysis.observedAt.toLocal().toIso8601String()}',
        ),
      );
      details.add(
        SelectableText(
          '${analysis.attribution.source}\n${analysis.attribution.copyrightUrl}',
        ),
      );
    } else {
      final FacilityAnalysisUnavailable unavailable =
          snapshot as FacilityAnalysisUnavailable;
      details.add(Text(text.failure(unavailable.failure)));
      details.add(Text(text.pick('查询时间：不可用', 'Queried at: unavailable')));
      details.add(
        const SelectableText(
          '© OpenStreetMap contributors\nhttps://www.openstreetmap.org/copyright',
        ),
      );
    }
    details.add(
      TextButton(
        onPressed: () async {
          final Uri url = Uri.parse('https://www.openstreetmap.org/copyright');
          try {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } catch (_) {
            /* The selectable URL remains available. */
          }
        },
        child: Text(
          text.pick('查看 OpenStreetMap 版权', 'OpenStreetMap copyright'),
        ),
      ),
    );
    details.add(
      Text(
        text.pick(
          '未收录不代表现实中不存在；不提供详情或路线。',
          'Missing records do not prove absence; details and routes are unavailable.',
        ),
      ),
    );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: details,
      ),
    );
  }
}
