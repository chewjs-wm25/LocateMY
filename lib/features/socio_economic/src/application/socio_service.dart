import '../../../cost_of_living_budget/cost_of_living_budget.dart';
// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import '../../../map_location/map_location.dart';
import '../../../../modules/geographic_context/geographic_context.dart';
import '../domain/socio_models.dart';
import '../domain/socio_input_rules.dart';

abstract interface class SocioInputsReader {
  Future<Map<String, Object?>> read(String state, String? district);
}

abstract interface class SocioPublicCache {
  Future<Map<String, Object?>?> read(String key);
  Future<void> write(String key, Map<String, Object?> payload);
}

final class SocioService implements SocioEconomic {
  final SocioInputRules _rules = const SocioInputRules();
  final GeographicContext _geo;
  final SocioInputsReader _reader;
  final CurrentBudgetReader? _budget;
  final SocioPublicCache? _cache;
  final Map<String, int> _generations = <String, int>{};
  SocioService(
    GeographicContext geo,
    SocioInputsReader reader,
    CurrentBudgetReader? budget,
    SocioPublicCache? cache,
  ) : _geo = geo,
      _reader = reader,
      _budget = budget,
      _cache = cache;

  @override
  Stream<void> get changes {
    if (_budget == null) {
      return const Stream<void>.empty();
    }
    return _budget
        .watchCurrent()
        .map((BudgetScenariosOutcome outcome) {
          if (outcome is BudgetScenariosAvailable) {
            final CurrentBudgetScenarioSnapshot current = outcome.current;
            if (current is CurrentBudgetScenarioAvailable) {
              return '${current.scenario.id}:${current.version}:${current.scenario.householdMonthlyIncomeRm}';
            }
            return 'none';
          }
          return 'unavailable';
        })
        .distinct()
        .map((String signature) {});
  }

  @override
  Future<SocioComparison> compare(
    ValidLocationReference a,
    ValidLocationReference b, {
    bool refresh = false,
  }) async {
    final BudgetScenariosOutcome budget = await _readBudget();
    final List<SocioAnalysis> results = await Future.wait(
      <Future<SocioAnalysis>>[
        _analyse(a, refresh, budget),
        _analyse(b, refresh, budget),
      ],
    );
    return SocioComparison(results[0], results[1]);
  }

  @override
  Future<SocioAnalysis> analyse(
    ValidLocationReference location, {
    bool refresh = false,
  }) {
    return _analyse(location, refresh, null);
  }

  Future<SocioAnalysis> _analyse(
    ValidLocationReference location,
    bool refresh,
    BudgetScenariosOutcome? budget,
  ) async {
    final String coordinate = _coordinateKey(location);
    final int generation = (_generations[coordinate] ?? 0) + 1;
    _generations[coordinate] = generation;
    GeographicContextOutcome context;
    try {
      context = await _geo.resolve(
        GeographicContextRequest(
          location: location,
          levels: const <GeographicLevel>{
            GeographicLevel.district,
            GeographicLevel.reportingState,
          },
        ),
      );
    } catch (_) {
      return _offlineScope(location, budget);
    }
    if (context is GeographicContextUnavailable &&
        context.failure == GeographicContextFailure.sourceUnavailable) {
      return _offlineScope(location, budget);
    }
    if (context is! GeographicContextAvailable) {
      return SocioAnalysis(
        location: location,
        failure: SocioFailure.geographyUnavailable,
      );
    }
    final GeographicLevelOutcome? stateResult =
        context.results[GeographicLevel.reportingState];
    final GeographicLevelOutcome? districtResult =
        context.results[GeographicLevel.district];
    if (stateResult is! GeographicLevelResolved) {
      return SocioAnalysis(
        location: location,
        failure: SocioFailure.geographyUnavailable,
      );
    }
    final String state = stateResult.area.name;
    String? district;
    if (districtResult is GeographicLevelResolved) {
      district = districtResult.area.name;
    }
    final String cacheKey =
        '$state:$district:${stateResult.provenance.sourceVersion}';
    Map<String, Object?>? data;
    if (!refresh) {
      data = await _cache?.read(cacheKey);
    }
    if (data == null) {
      bool fetched = false;
      try {
        data = await _reader.read(state, district);
        fetched = true;
      } catch (_) {
        data = await _cache?.read(cacheKey);
      }
      if (data == null) {
        return SocioAnalysis(
          location: location,
          state: state,
          district: district,
          boundaryVersion: stateResult.provenance.sourceVersion,
          failure: SocioFailure.sourceUnavailable,
        );
      }
      try {
        if (fetched && _generations[coordinate] == generation) {
          await _cache?.write(cacheKey, data);
          await _cache?.write(_coordinateKey(location), <String, Object?>{
            'state': state,
            'district': district,
            'boundary_version': stateResult.provenance.sourceVersion,
            'inputs': data,
          });
        }
      } catch (_) {
        /* A failed cache write does not discard real observations. */
      }
    }
    return _fromData(
      location,
      state,
      district,
      stateResult.provenance.sourceVersion,
      data,
      budget,
    );
  }

  String _coordinateKey(ValidLocationReference location) {
    return 'coordinate:${location.point.latitude}:${location.point.longitude}';
  }

  Future<SocioAnalysis> _offlineScope(
    ValidLocationReference location,
    BudgetScenariosOutcome? budget,
  ) async {
    final Map<String, Object?>? snapshot = await _cache?.read(
      _coordinateKey(location),
    );
    if (snapshot == null ||
        snapshot['state'] is! String ||
        snapshot['boundary_version'] is! String ||
        snapshot['inputs'] is! Map) {
      return SocioAnalysis(
        location: location,
        failure: SocioFailure.sourceUnavailable,
      );
    }
    return _fromData(
      location,
      snapshot['state'] as String,
      snapshot['district'] as String?,
      snapshot['boundary_version'] as String,
      Map<String, Object?>.from(snapshot['inputs'] as Map),
      budget,
    );
  }

  Future<SocioAnalysis> _fromData(
    ValidLocationReference location,
    String state,
    String? district,
    String boundaryVersion,
    Map<String, Object?> data,
    BudgetScenariosOutcome? budget,
  ) async {
    SocioReading? income;
    SocioReading? gini;
    Object? giniRows;
    Object? incomeRows;
    if (district != null) {
      incomeRows = data['income_district'];
      income = _rules.reading(incomeRows, state, district, 'income_median');
      gini = _rules.reading(data['gini_district'], state, district, 'gini');
      giniRows = data['gini_district'];
    }
    if (income == null) {
      incomeRows = data['income_state'];
      income = _rules.reading(incomeRows, state, null, 'income_median');
    }
    if (gini == null) {
      gini = _rules.reading(data['gini_state'], state, null, 'gini');
      giniRows = data['gini_state'];
    }
    final SocioPercentiles latestPercentiles = _rules.percentiles(
      data['percentiles'],
    );
    Set<int>? commonYears;
    if (income != null) {
      commonYears = _rules.years(
        incomeRows,
        state,
        income.district,
        'income_median',
      );
    }
    if (gini != null) {
      final Set<int> giniYears = _rules.years(
        giniRows,
        state,
        gini.district,
        'gini',
      );
      if (commonYears == null) {
        commonYears = giniYears;
      } else {
        commonYears = commonYears.intersection(giniYears);
      }
    }
    if (latestPercentiles.observations.isNotEmpty ||
        latestPercentiles.structure != null) {
      final Set<int> percentileYears = <int>{};
      final Set<int> observedYears = <int>{};
      final Object? raw = data['percentiles'];
      if (raw is List) {
        for (final Object? row in raw) {
          if (row is! Map || row['date'] is! String) {
            continue;
          }
          final DateTime? date = DateTime.tryParse(row['date'] as String);
          if (date != null) {
            observedYears.add(date.year);
          }
        }
        for (final int year in observedYears) {
          final SocioPercentiles yearData = _rules.percentiles(
            raw,
            surveyYear: year,
          );
          if ((latestPercentiles.observations.isEmpty ||
                  yearData.observations.isNotEmpty) &&
              (latestPercentiles.structure == null ||
                  yearData.structure != null)) {
            percentileYears.add(year);
          }
        }
      }
      if (commonYears == null) {
        commonYears = percentileYears;
      } else {
        commonYears = commonYears.intersection(percentileYears);
      }
    }
    int? commonYear;
    if (commonYears != null) {
      for (final int year in commonYears) {
        if (commonYear == null || year > commonYear) {
          commonYear = year;
        }
      }
    }
    if (commonYear != null) {
      if (income != null) {
        income = _rules.reading(
          incomeRows,
          state,
          income.district,
          'income_median',
          year: commonYear,
        );
      }
      if (gini != null) {
        gini = _rules.reading(
          giniRows,
          state,
          gini.district,
          'gini',
          year: commonYear,
        );
      }
    }
    double? change;
    if (gini != null) {
      final SocioReading? previous = _rules.reading(
        giniRows,
        state,
        gini.district,
        'gini',
        year: gini.year - 1,
      );
      if (previous != null) {
        change = gini.value - previous.value;
      }
    }
    final SocioPercentiles percentiles = _rules.percentiles(
      data['percentiles'],
    );
    return SocioAnalysis(
      position: await _position(latestPercentiles, budget),
      distribution: latestPercentiles.medians,
      completeDistributionYear: latestPercentiles.year,
      distributionYear: percentiles.curveYear,
      distributionPoints: percentiles.observations,
      structure: percentiles.structure,
      location: location,
      state: state,
      district: district,
      boundaryVersion: boundaryVersion,
      income: income,
      gini: gini,
      giniChange: change,
    );
  }

  Future<BudgetScenariosOutcome> _readBudget() async {
    try {
      return await _budget?.readCurrent() ??
          const BudgetScenariosUnavailable(
            BudgetScenarioFailure.scopeUnavailable,
          );
    } catch (_) {
      return const BudgetScenariosUnavailable(
        BudgetScenarioFailure.retryableUnavailable,
      );
    }
  }

  Future<IncomePosition?> _position(
    SocioPercentiles distribution,
    BudgetScenariosOutcome? snapshot,
  ) async {
    if (_budget == null ||
        distribution.medians.length != 100 ||
        distribution.year == null) {
      return null;
    }
    final BudgetScenariosOutcome outcome = snapshot ?? await _readBudget();
    if (outcome is! BudgetScenariosAvailable ||
        outcome.current is! CurrentBudgetScenarioAvailable) {
      return null;
    }
    final CurrentBudgetScenarioAvailable current =
        outcome.current as CurrentBudgetScenarioAvailable;
    final double? income = current.scenario.householdMonthlyIncomeRm;
    if (income == null || !income.isFinite || income < 0) {
      return null;
    }
    return _rules.position(distribution, income);
  }
}
