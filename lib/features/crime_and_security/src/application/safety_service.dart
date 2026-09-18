import 'dart:convert';
import 'dart:math' as math;

import 'package:locatemy/modules/geographic_context/geographic_context.dart';

import '../../crime_and_security.dart';
import '../data/crime_repository.dart';

final class SafetyService implements CrimeAndSecurity {
  final CrimeRepository repository;
  final GeographicContext geographicContext;
  static const String currentModelVersion = 'v1';

  const SafetyService({
    required this.repository,
    required this.geographicContext,
  });

  @override
  Future<SafetyLoadOutcome> load(SafetyRequest request) async {
    
    final geoOutcome = await geographicContext.resolve(
      GeographicContextRequest(
        location: request.location,
        levels: {GeographicLevel.reportingState},
      ),
    );

    if (geoOutcome is! GeographicContextAvailable) {
      if (geoOutcome is GeographicContextUnavailable) {
        if (geoOutcome.failure == GeographicContextFailure.noCoverage) {
          return const SafetyUnavailable(
            SafetyUnavailableReason.stateUnresolved,
          );
        }
        return const SafetyUnavailable(
          SafetyUnavailableReason.retryableUnavailable,
        );
      }
      return const SafetyUnavailable(SafetyUnavailableReason.stateUnresolved);
    }

    final stateOutcome = geoOutcome.results[GeographicLevel.reportingState];
    if (stateOutcome is! GeographicLevelResolved) {
      if (stateOutcome is GeographicLevelAmbiguous) {
        return const SafetyUnavailable(SafetyUnavailableReason.stateAmbiguous);
      }
      return const SafetyUnavailable(SafetyUnavailableReason.stateUnresolved);
    }

    final resolvedArea = stateOutcome.area;
    final reportingState = ReportingState(
      resolvedArea.reportingStateId,
      resolvedArea.reportingStateName,
    );
    final boundaryVersion = stateOutcome.provenance.sourceVersion;

    
    if (request.policy == SafetyLoadPolicy.cacheAllowed) {
      final cached = await repository.getCachedSafety(
        reportingState.stableId,
        currentModelVersion,
        boundaryVersion,
      );
      if (cached != null && !cached.isExpired) {
        
        
        
        try {
          
          
        } catch (_) {}
      }
    }

    
    final rawData = await repository.fetchCrimeData(reportingState.name);
    if (rawData.isEmpty) {
      return const SafetyUnavailable(SafetyUnavailableReason.sourceMissing);
    }

    
    final years = rawData
        .map((e) => int.tryParse(e.date.split('-')[0]) ?? 0)
        .where((y) => y > 0)
        .toSet()
        .toList();
    if (years.isEmpty) {
      return const SafetyUnavailable(SafetyUnavailableReason.incompleteYear);
    }
    final latestYear = years.reduce(math.max);

    
    final peerRows = await repository.fetchOtherStatesData(latestYear);
    if (peerRows.isEmpty) {
      return const SafetyUnavailable(SafetyUnavailableReason.sourceMissing);
    }

    
    final snapshot = _calculateSnapshot(
      request: request,
      reportingState: reportingState,
      latestYear: latestYear,
      rawData: rawData,
      peerRows: peerRows,
      boundaryVersion: boundaryVersion,
    );

    if (snapshot == null) {
      return const SafetyUnavailable(SafetyUnavailableReason.noValidCategory);
    }

    
    

    return snapshot.completeness == SafetyCompleteness.complete
        ? SafetyAvailable(snapshot)
        : SafetyPartiallyAvailable(snapshot);
  }

  @override
  Future<SafetyComparisonOutcome> compare(
    SafetyComparisonRequest request,
  ) async {
    final outcomeA = await load(request.a);
    final outcomeB = await load(request.b);

    if (outcomeA is SafetyAvailable && outcomeB is SafetyAvailable) {
      final snapshotA = outcomeA.snapshot;
      final snapshotB = outcomeB.snapshot;

      if (snapshotA.latestCompleteYearCount.year !=
          snapshotB.latestCompleteYearCount.year) {
        return SafetyIncomparable(
          outcomeA,
          outcomeB,
          SafetyComparisonReason.yearMismatch,
        );
      }
      if (snapshotA.provenance.boundaryVersion !=
          snapshotB.provenance.boundaryVersion) {
        return SafetyIncomparable(
          outcomeA,
          outcomeB,
          SafetyComparisonReason.provenanceMismatch,
        );
      }

      return SafetyComparable(snapshotA, snapshotB);
    }

    return SafetyIncomparable(
      outcomeA,
      outcomeB,
      SafetyComparisonReason.sideUnavailable,
    );
  }

  SafetySnapshot? _calculateSnapshot({
    required SafetyRequest request,
    required ReportingState reportingState,
    required int latestYear,
    required List<RawCrimeData> rawData,
    required List<String> peerRows,
    required String boundaryVersion,
  }) {
    
    final currentYearData = rawData
        .where((e) => e.date.startsWith(latestYear.toString()))
        .toList();

    
    int assaultCrimes = 0;
    int propertyCrimes = 0;
    for (final e in currentYearData) {
      if (e.category.toLowerCase() == 'assault') assaultCrimes += e.crimes;
      if (e.category.toLowerCase() == 'property') propertyCrimes += e.crimes;
    }

    
    final peerStats = <String, Map<String, int>>{};
    for (final rowJson in peerRows) {
      final data = jsonDecode(rowJson);
      final state = data['state'] as String;
      final category = (data['category'] as String).toLowerCase();
      final crimes = data['crimes'] as int;

      peerStats.putIfAbsent(state, () => {'assault': 0, 'property': 0});
      if (category == 'assault' || category == 'property') {
        peerStats[state]![category] =
            (peerStats[state]![category] ?? 0) + crimes;
      }
    }

    
    final assaultPercentile = _calculatePercentile(
      targetCrimes: assaultCrimes,
      allCrimes: peerStats.values.map((s) => s['assault'] ?? 0).toList()
        ..add(assaultCrimes),
    );
    final propertyPercentile = _calculatePercentile(
      targetCrimes: propertyCrimes,
      allCrimes: peerStats.values.map((s) => s['property'] ?? 0).toList()
        ..add(propertyCrimes),
    );

    
    double riskScore = 0;
    double totalWeight = 0;
    bool hasAssault =
        assaultCrimes > 0 ||
        peerStats.values.any((s) => (s['assault'] ?? 0) > 0);
    bool hasProperty =
        propertyCrimes > 0 ||
        peerStats.values.any((s) => (s['property'] ?? 0) > 0);

    if (hasAssault) {
      riskScore += 0.6 * assaultPercentile;
      totalWeight += 0.6;
    }
    if (hasProperty) {
      riskScore += 0.4 * propertyPercentile;
      totalWeight += 0.4;
    }

    if (totalWeight == 0) return null;

    final finalScore = (100 - (riskScore / totalWeight)).clamp(0, 100).round();

    
    final trendPoints = _generateTrend(rawData, request.filter, latestYear);

    return SafetySnapshot(
      location: request.location,
      state: reportingState,
      score: SafetyScore(finalScore),
      latestCompleteYearCount: AnnualCrimeCount(
        assaultCrimes + propertyCrimes,
        latestYear,
      ),
      trend: SafetyTrend(request.filter, trendPoints),
      availableFilters: [
        const AllCrimeTrend(),
        const CategoryTrend(CrimeCategory.assault),
        const CategoryTrend(CrimeCategory.property),
      ],
      freshness: SafetyFreshness.fresh,
      completeness: (hasAssault && hasProperty)
          ? SafetyCompleteness.complete
          : SafetyCompleteness.partial,
      provenance: SafetyProvenance(
        source: 'Official Malaysia Crime Statistics (data.gov.my)',
        modelVersion: currentModelVersion,
        boundaryVersion: boundaryVersion,
      ),
    );
  }

  double _calculatePercentile({
    required int targetCrimes,
    required List<int> allCrimes,
  }) {
    if (allCrimes.isEmpty) return 0;

    final targetX = math.log(1 + targetCrimes);
    final allX = allCrimes.map((c) => math.log(1 + c)).toList();

    int smallerOrEqual = 0;
    for (final x in allX) {
      if (x <= targetX) smallerOrEqual++;
    }

    return 100 * smallerOrEqual / allX.length;
  }

  List<AnnualCrimePoint> _generateTrend(
    List<RawCrimeData> rawData,
    SafetyTrendFilter filter,
    int latestYear,
  ) {
    final points = <AnnualCrimePoint>[];
    for (int y = latestYear - 4; y <= latestYear; y++) {
      int count = 0;
      final yearData = rawData.where((e) => e.date.startsWith(y.toString()));

      for (final e in yearData) {
        bool matches = false;
        if (filter is AllCrimeTrend) {
          matches = true;
        } else if (filter is CategoryTrend) {
          matches =
              e.category.toLowerCase() == filter.category.name.toLowerCase();
        } else if (filter is TypeTrend) {
          matches = e.type == filter.type;
        }

        if (matches) count += e.crimes;
      }
      points.add(AnnualCrimePoint(y, count));
    }
    return points;
  }
}
