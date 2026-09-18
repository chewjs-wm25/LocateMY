import 'package:sqflite/sqflite.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';

import '../../cost_of_living_budget.dart';
import '../data/cost_cache.dart';

abstract interface class CostPublicReader {
  Future<Map<String, Object?>> read(String state, String district);
}

final class CostPublicFailure implements Exception {
  final CostAnalysisFailure failure;
  const CostPublicFailure(CostAnalysisFailure failure) : failure = failure;
}

final class CostService implements CostOfLivingBudget {
  final GeographicContext _geo;
  final CostPublicReader _reader;
  final CurrentBudgetReader? _budget;
  final CostCache? _cache;
  CostService({
    required GeographicContext geographicContext,
    required CostPublicReader reader,
    CurrentBudgetReader? budget,
    Database? database,
    DateTime Function()? clock,
  }) : _geo = geographicContext,
       _reader = reader,
       _budget = budget,
       _cache = database == null
           ? null
           : CostCache(database, clock ?? DateTime.now);
  Future<GeographicContextAvailable?> _context(
    CostAnalysisRequest request,
  ) async {
    final GeographicContextOutcome result = await _geo.resolve(
      GeographicContextRequest(
        location: request.location,
        levels: const <GeographicLevel>{
          GeographicLevel.district,
          GeographicLevel.reportingState,
        },
      ),
    );
    if (result is GeographicContextAvailable &&
        result.results[GeographicLevel.district] is GeographicLevelResolved &&
        result.results[GeographicLevel.reportingState]
            is GeographicLevelResolved) {
      return result;
    }
    return null;
  }

  Future<Map<String, Object?>> _read(
    AdministrativeArea district,
    CostRefreshPolicy policy,
  ) async {
    final String key =
        'cost-basket-v1|${district.reportingStateName}|${district.name}';
    if (policy == CostRefreshPolicy.cacheAllowed) {
      final Map<String, Object?>? cached = await _cache?.read(key);
      if (cached != null) {
        return cached;
      }
    }
    Map<String, Object?> result;
    try {
      result = await _reader.read(district.reportingStateName, district.name);
    } catch (_) {
      final Map<String, Object?>? cached = await _cache?.read(key);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
    try {
      await _cache?.write(key, result);
    } catch (_) {
      
    }
    return result;
  }

  Future<BudgetScenario?> _current() async {
    final BudgetScenariosOutcome? outcome = await _budget?.readCurrent();
    if (outcome is BudgetScenariosAvailable &&
        outcome.current is CurrentBudgetScenarioAvailable) {
      return (outcome.current as CurrentBudgetScenarioAvailable).scenario;
    }
    return null;
  }

  @override
  Future<CostAnalysisOutcome> analyse(CostAnalysisRequest request) async {
    return _analyse(request, await _current());
  }

  Future<CostAnalysisOutcome> _analyse(
    CostAnalysisRequest request,
    BudgetScenario? current,
  ) async {
    try {
      final GeographicContextAvailable? context = await _context(request);
      if (context == null) {
        return const CostAnalysisUnavailable(
          CostAnalysisFailure.geographicContextUnavailable,
        );
      }
      final AdministrativeArea district =
          (context.results[GeographicLevel.district] as GeographicLevelResolved)
              .area;
      final AdministrativeArea state =
          (context.results[GeographicLevel.reportingState]
                  as GeographicLevelResolved)
              .area;
      final Map<String, Object?> raw = await _read(
        district,
        request.refreshPolicy,
      );
      if (raw['basket_version'] != 'cost-basket-v1') {
        return const CostAnalysisUnavailable(
          CostAnalysisFailure.incompatibleMetadata,
        );
      }
      final List<Map<String, dynamic>> baseline = <Map<String, dynamic>>[];
      for (final Object? row in raw['baseline'] as List) {
        baseline.add(Map<String, dynamic>.from(row as Map));
      }
      final Map<int, double> expected = <int, double>{
        1: 2,
        16: 2,
        118: 3,
        224: 4,
        272: 4,
        904: 0.5,
        918: 2,
        1589: 1,
        1605: 1,
        1645: 1,
        1541: 1,
      };
      final Map<int, Map<String, dynamic>> byCode =
          <int, Map<String, dynamic>>{};
      double base = 0;
      if (baseline.length != 11) {
        return const CostAnalysisUnavailable(
          CostAnalysisFailure.incompatibleMetadata,
        );
      }
      bool complete = true;
      for (final Map<String, dynamic> row in baseline) {
        final int code = (row['item_code'] as num).toInt();
        if (byCode.containsKey(code) ||
            !expected.containsKey(code) ||
            _amount(row['quantity']) != expected[code]) {
          return const CostAnalysisUnavailable(
            CostAnalysisFailure.incompatibleMetadata,
          );
        }
        byCode[code] = row;
        final double? price = _amount(row['national_price']);
        final double quantity = _amount(row['quantity'])!;
        final String unit = (row['unit'] as String).replaceAll('+-', '±');
        if (price == null || unit != row['expected_unit']) {
          complete = false;
        } else {
          base += quantity * price;
        }
      }
      final Map<String, double> spends = <String, double>{};
      final Map<String, double> nationalSpends = <String, double>{};
      final Map<int, List<double>> prices = <int, List<double>>{};
      final Map<int, int> premises = <int, int>{};
      final Map<int, int> records = <int, int>{};
      final Map<int, List<DateTime>> months = <int, List<DateTime>>{};
      final Set<int> indexedItems = <int>{};
      for (final Object? value in raw['months'] as List) {
        final Map<String, dynamic> row = Map<String, dynamic>.from(
          value as Map,
        );
        final int code = (row['item_code'] as num).toInt();
        final Map<String, dynamic>? item = byCode[code];
        final double? price = _amount(row['price']);
        if (item == null || price == null) {
          continue;
        }
        final String month = row['month'] as String;
        final double quantity = _amount(item['quantity'])!;
        final double? nationalPrice = _amount(item['national_price']);
        if (nationalPrice != null) {
          spends[month] = (spends[month] ?? 0) + quantity * price;
          nationalSpends[month] =
              (nationalSpends[month] ?? 0) + quantity * nationalPrice;
          indexedItems.add(code);
        }
        prices
            .putIfAbsent(code, () {
              return <double>[];
            })
            .add(price);
        months
            .putIfAbsent(code, () {
              return <DateTime>[];
            })
            .add(DateTime.parse(month));
        premises[code] =
            (premises[code] ?? 0) + (row['premises'] as num).toInt();
        records[code] = (records[code] ?? 0) + (row['records'] as num).toInt();
      }
      double? observed;
      if (spends.isNotEmpty) {
        observed = _average(spends.values);
      }
      double? coverage;
      if (base > 0 && nationalSpends.isNotEmpty) {
        final List<double> monthCoverage = <double>[];
        for (final double nationalSpend in nationalSpends.values) {
          monthCoverage.add(nationalSpend / base);
        }
        coverage = _average(monthCoverage);
      }
      final bool quality =
          spends.length >= 6 && coverage != null && coverage >= 0.8;
      double? index;
      if (nationalSpends.isNotEmpty) {
        final List<double> monthlyIndexes = <double>[];
        for (final String month in spends.keys) {
          final double? nationalSpend = nationalSpends[month];
          if (nationalSpend != null && nationalSpend > 0) {
            monthlyIndexes.add(100 * spends[month]! / nationalSpend);
          }
        }
        if (monthlyIndexes.isNotEmpty) {
          index = _average(monthlyIndexes);
        }
      }
      double? scenario;
      double? personal;
      double? location;
      final List<CostAvailabilityGap> gaps = <CostAvailabilityGap>[];
      if (!complete) {
        gaps.add(CostAvailabilityGap.baselineIncomplete);
      }
      if (!quality) {
        gaps.add(CostAvailabilityGap.lowCoverage);
      }
      if (current?.housingExpenseRm == null) {
        gaps.add(CostAvailabilityGap.missingHousingInput);
      }
      if (current?.transportExpenseRm == null) {
        gaps.add(CostAvailabilityGap.missingTransportInput);
      }
      if (current?.monthlyNetIncomeRm == null ||
          current!.monthlyNetIncomeRm! <= 0) {
        gaps.add(CostAvailabilityGap.missingNetIncomeInput);
      }
      if (observed != null &&
          current?.housingExpenseRm != null &&
          current?.transportExpenseRm != null) {
        scenario =
            observed +
            (current!.additionalLivingExpenseRm ?? 0) +
            current.housingExpenseRm! +
            current.transportExpenseRm!;
        if (current.monthlyNetIncomeRm != null &&
            current.monthlyNetIncomeRm! > 0) {
          personal = 100 * scenario / current.monthlyNetIncomeRm!;
        }
        final double? income = _amount(raw['district_income']);
        if (income != null && income > 0) {
          location = 100 * scenario / income;
        }
      }
      final List<CostItem> items = <CostItem>[];
      for (final Map<String, dynamic> row in baseline) {
        final int code = (row['item_code'] as num).toInt();
        final List<double>? local = prices[code];
        double? price;
        if (local != null && local.isNotEmpty) {
          price = _average(local);
        }
        final double quantity = _amount(row['quantity'])!;
        items.add(
          CostItem(
            itemCode: code.toString(),
            name: row['name'] as String,
            unit: row['unit'] as String,
            monthlyQuantity: quantity,
            localPrice: price,
            observedSpend: price == null ? null : quantity * price,
            premiseCount: premises[code] ?? 0,
            recordCount: records[code] ?? 0,
            months: List<DateTime>.unmodifiable(months[code] ?? <DateTime>[]),
          ),
        );
      }
      final CostAnalysis analysis = CostAnalysis(
        location: request.location,
        district: district,
        reportingState: state,
        basketVersion: 'cost-basket-v1',
        modelVersion: 'cost-model-v1',
        sourceDate: DateTime.parse(raw['source_date'] as String),
        observedSpend12: observed,
        scenarioSpend12: scenario,
        costIndex: index,
        personalBudgetBurden: personal,
        locationBudgetBurden: location,
        items: List<CostItem>.unmodifiable(items),
        coverage: coverage,
        availableMonths: spends.length,
        indexedItemCount: indexedItems.length,
        isPartialBasket: !complete || !quality,
        currentScenarioId: current?.id,
      );
      if (!complete || !quality) {
        return CostAnalysisPartial(
          analysis,
          List<CostAvailabilityGap>.unmodifiable(gaps),
        );
      }
      return CostAnalysisAvailable(analysis);
    } catch (error) {
      if (error is CostPublicFailure) {
        return CostAnalysisUnavailable(error.failure);
      }
      return const CostAnalysisUnavailable(
        CostAnalysisFailure.retryableUnavailable,
      );
    }
  }

  @override
  Future<CostComparisonOutcome> compare(CostComparisonRequest request) async {
    if (request.locationA.point.latitude == request.locationB.point.latitude &&
        request.locationA.point.longitude ==
            request.locationB.point.longitude) {
      return const CostComparisonUnavailable(
        CostAnalysisFailure.sameComparisonPoint,
      );
    }
    final BudgetScenario? current = await _current();
    final List<CostAnalysisOutcome> results = await Future.wait(
      <Future<CostAnalysisOutcome>>[
        _analyse(
          CostAnalysisRequest(
            location: request.locationA,
            refreshPolicy: request.refreshPolicy,
          ),
          current,
        ),
        _analyse(
          CostAnalysisRequest(
            location: request.locationB,
            refreshPolicy: request.refreshPolicy,
          ),
          current,
        ),
      ],
    );
    CostAnalysis? analysis(CostAnalysisOutcome result) {
      if (result is CostAnalysisAvailable) {
        return result.analysis;
      }
      if (result is CostAnalysisPartial) {
        return result.analysis;
      }
      return null;
    }

    final CostAnalysis? a = analysis(results[0]);
    final CostAnalysis? b = analysis(results[1]);
    if (a == null || b == null) {
      return const CostComparisonUnavailable(
        CostAnalysisFailure.sourceUnavailable,
      );
    }
    final bool comparable =
        a.costIndex != null &&
        b.costIndex != null &&
        a.basketVersion == b.basketVersion &&
        a.sourceDate == b.sourceDate;
    final CostComparison value = CostComparison(
      analysisA: a,
      analysisB: b,
      comparable: comparable,
    );
    if (!comparable) {
      return CostComparisonPartial(value, const <CostAvailabilityGap>[
        CostAvailabilityGap.notComparable,
      ]);
    }
    return CostComparisonAvailable(value);
  }

  double? _amount(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! num || !value.toDouble().isFinite || value < 0) {
      throw const FormatException('Invalid cost input');
    }
    return value.toDouble();
  }

  double _average(Iterable<double> values) {
    double total = 0;
    int count = 0;
    for (final double value in values) {
      total += value;
      count++;
    }
    return total / count;
  }
}
