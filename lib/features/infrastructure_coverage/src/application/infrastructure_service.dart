// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/public_transportation/public_transportation.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';

import '../domain/infrastructure_models.dart';

abstract interface class InfrastructureInputsReader {
  Future<Map<String, Object?>> read(String state, String district);
}

abstract interface class InfrastructureWeightsStore {
  Future<InfrastructureWeightSettings> read();
  Future<void> save(InfrastructureWeightSettings weights);
}

abstract interface class InfrastructurePublicCache {
  Future<Map<String, Object?>?> read(String key);
  Future<void> write(String key, Map<String, Object?> payload);
}

final class InfrastructureService {
  final GeographicContext geo;
  final InfrastructureInputsReader reader;
  final PublicTransportation transportation;
  final InfrastructureWeightsStore weightsStore;
  final InfrastructurePublicCache? cache;
  final Map<String, int> _generations = <String, int>{};
  final Map<String, int> _cacheRevisions = <String, int>{};
  final Map<String, Future<void>> _cacheWrites = <String, Future<void>>{};
  int _requestRevision = 0;
  InfrastructureService({
    required GeographicContext geo,
    required InfrastructureInputsReader reader,
    required PublicTransportation transportation,
    required InfrastructureWeightsStore weightsStore,
    InfrastructurePublicCache? cache,
  }) : geo = geo,
       reader = reader,
       transportation = transportation,
       weightsStore = weightsStore,
       cache = cache;

  void _registerCacheRevision(String key, int revision) {
    if (revision > (_cacheRevisions[key] ?? 0)) {
      _cacheRevisions[key] = revision;
    }
  }

  Future<void> _writeCache(
    String key,
    Map<String, Object?> payload,
    int revision,
  ) async {
    final Future<void>? previous = _cacheWrites[key];
    final Future<void> write = _writeAfter(previous, key, payload, revision);
    _cacheWrites[key] = write;
    try {
      await write;
    } finally {
      if (identical(_cacheWrites[key], write)) {
        _cacheWrites.remove(key);
      }
    }
  }

  Future<void> _writeAfter(
    Future<void>? previous,
    String key,
    Map<String, Object?> payload,
    int revision,
  ) async {
    if (previous != null) {
      try {
        await previous;
      } catch (_) {
        /* A failed older write must not block a newer observation. */
      }
    }
    if (_cacheRevisions[key] != revision) {
      return;
    }
    // A newer write for this key queues behind an already in-flight write,
    // ensuring the old completion cannot subsequently overwrite the new data.
    await cache?.write(key, payload);
  }

  static InfrastructureCoverage evaluate(
    ValidLocationReference location,
    DateTime analysisDate,
    Map<String, double?> scores,
    InfrastructureWeightSettings weights, {
    String? state,
    String? district,
    Map<String, int> sourceYears = const <String, int>{},
    Map<String, int> populationYears = const <String, int>{},
    bool transitPartial = false,
    bool transitDistanceOnly = false,
  }) {
    if (!weights.valid) {
      throw ArgumentError('Priorities must be 1–10');
    }
    final List<InfrastructureCategoryScore> categories =
        <InfrastructureCategoryScore>[];
    final List<String> missing = <String>[];
    double numerator = 0;
    double denominator = 0;
    for (final String key in <String>[
      'water',
      'power',
      'health',
      'education',
      'transit',
    ]) {
      final double? value = scores[key];
      if (value != null && (!value.isFinite || value < 0 || value > 100)) {
        throw const FormatException('Invalid component');
      }
      double multiplier = 1;
      String zh = '';
      String en = '';
      switch (key) {
        case 'water':
          zh = '供水';
          en = 'Water';
          break;
        case 'power':
          zh = '供电';
          en = 'Electricity';
          break;
        case 'health':
          zh = '医疗';
          en = 'Healthcare';
          multiplier = weights.health / 5;
          break;
        case 'education':
          zh = '教育';
          en = 'Education';
          multiplier = weights.education / 5;
          break;
        case 'transit':
          zh = '公共交通';
          en = 'Public transportation';
          multiplier = weights.transit / 5;
          break;
      }
      categories.add(
        InfrastructureCategoryScore(
          key: key,
          labelZh: zh,
          labelEn: en,
          score: value,
          missing: value == null,
        ),
      );
      if (value == null) {
        missing.add(key);
      } else {
        numerator += value * multiplier;
        denominator += multiplier;
      }
    }
    int? score;
    if (missing.length <= 2) {
      score = (numerator / denominator).round();
    }
    return InfrastructureCoverage(
      score: score,
      transitPartial: transitPartial,
      transitDistanceOnly: transitDistanceOnly,
      location: location,
      analysisDate: analysisDate,
      weights: weights,
      categories: List<InfrastructureCategoryScore>.unmodifiable(categories),
      missingCategories: List<String>.unmodifiable(missing),
      state: state,
      district: district,
      sourceYears: Map<String, int>.unmodifiable(sourceYears),
      populationYears: Map<String, int>.unmodifiable(populationYears),
    );
  }

  Future<InfrastructureLoadOutcome> summary(
    ValidLocationReference location,
    DateTime date,
  ) {
    return fetch(location, date);
  }

  Future<List<InfrastructureLoadOutcome>> compare(
    ValidLocationReference a,
    ValidLocationReference b,
    DateTime date, {
    InfrastructureLoadPolicy policy = InfrastructureLoadPolicy.cacheAllowed,
  }) {
    return Future.wait(<Future<InfrastructureLoadOutcome>>[
      fetch(a, date, policy: policy),
      fetch(b, date, policy: policy),
    ]);
  }

  Future<InfrastructureLoadOutcome> fetch(
    ValidLocationReference location,
    DateTime analysisDate, {
    InfrastructureLoadPolicy policy = InfrastructureLoadPolicy.cacheAllowed,
    InfrastructureWeightSettings weights = const InfrastructureWeightSettings(),
  }) async {
    final String key =
        'coordinate:${location.point.latitude}:${location.point.longitude}';
    final int revision = ++_requestRevision;
    _registerCacheRevision(key, revision);
    final int generation = (_generations[key] ?? 0) + 1;
    _generations[key] = generation;
    String? state;
    String? district;
    Map<String, Object?>? inputs;
    try {
      final GeographicContextOutcome context = await geo.resolve(
        GeographicContextRequest(
          location: location,
          levels: const <GeographicLevel>{
            GeographicLevel.reportingState,
            GeographicLevel.district,
          },
        ),
      );
      if (context is GeographicContextAvailable) {
        final GeographicLevelOutcome? s =
            context.results[GeographicLevel.reportingState];
        final GeographicLevelOutcome? d =
            context.results[GeographicLevel.district];
        if (s is GeographicLevelResolved && d is GeographicLevelResolved) {
          state = s.area.name;
          district = d.area.name;
        }
      } else if (context is GeographicContextUnavailable &&
          context.failure == GeographicContextFailure.sourceUnavailable) {
        final Map<String, Object?>? saved = await cache?.read(key);
        state = saved?['state'] as String?;
        district = saved?['district'] as String?;
        if (saved?['inputs'] is Map) {
          inputs = Map<String, Object?>.from(saved!['inputs'] as Map);
        }
      }
      if (state != null && district != null && inputs == null) {
        final String scope = '$state:$district';
        _registerCacheRevision(scope, revision);
        if (policy == InfrastructureLoadPolicy.cacheAllowed) {
          inputs = await cache?.read(scope);
        }
        if (inputs == null) {
          bool fetched = false;
          try {
            inputs = await reader.read(state, district);
            fetched = true;
          } catch (_) {
            inputs = await cache?.read(scope);
          }
          if (inputs != null && fetched && _generations[key] == generation) {
            try {
              await _writeCache(scope, inputs, revision);
              await _writeCache(key, <String, Object?>{
                'state': state,
                'district': district,
                'inputs': inputs,
              }, revision);
            } catch (_) {
              /* Readable observations survive cache write failure. */
            }
          }
        }
      }
      final _InfrastructureReadings readings = _InfrastructureReadings();
      final Map<String, double?> scores = readings.scores;
      if (inputs != null && state != null && district != null) {
        final _InfrastructureReadings observed = InfrastructureInputRules._read(
          inputs,
          state,
          district,
        );
        scores.addAll(observed.scores);
        readings.sourceYears.addAll(observed.sourceYears);
        readings.populationYears.addAll(observed.populationYears);
      }
      final TransitLoadOutcome transit = await transportation.load(
        TransitRequest(
          location: location,
          analysisDate: analysisDate,
          policy: policy == InfrastructureLoadPolicy.refresh
              ? TransitLoadPolicy.refresh
              : TransitLoadPolicy.cacheAllowed,
        ),
      );
      if (transit is TransitAvailable) {
        scores['transit'] = transit.snapshot.score?.value.toDouble();
      } else if (transit is TransitIncomplete) {
        scores['transit'] = transit.snapshot.score?.value.toDouble();
      }
      final InfrastructureCoverage result = evaluate(
        location,
        analysisDate,
        scores,
        weights,
        state: state,
        district: district,
        sourceYears: readings.sourceYears,
        populationYears: readings.populationYears,
        transitPartial: transit is TransitIncomplete,
        transitDistanceOnly:
            transit is TransitIncomplete && transit.snapshot.distanceOnly,
      );
      if (result.score == null) {
        return InfrastructurePartial(result);
      }
      return InfrastructureAvailable(result);
    } catch (_) {
      return const InfrastructureUnavailable(
        'Infrastructure data unavailable.',
      );
    }
  }
}

final class InfrastructureInputRules {
  static List<Map<String, Object?>> _rows(Object? value) {
    final List<Map<String, Object?>> result = <Map<String, Object?>>[];
    if (value is! List) {
      return result;
    }
    for (final Object? raw in value) {
      if (raw is Map) {
        result.add(Map<String, Object?>.from(raw));
      }
    }
    return result;
  }

  static double? _number(Object? value) {
    if (value is! num || !value.isFinite || value < 0) {
      return null;
    }
    return value.toDouble();
  }

  static int? _year(Map<String, Object?> row) {
    final Object? date = row['date'];
    if (date is! String) {
      return null;
    }
    return DateTime.tryParse(date)?.year;
  }

  static _InfrastructureAggregate? _aggregate(
    List<Map<String, Object?>> rows,
    String state,
    String district,
    String field, {
    bool both = false,
    int? year,
  }) {
    final Set<DateTime> dates = <DateTime>{};
    for (final Map<String, Object?> row in rows) {
      if (row['state'] != state ||
          row['district'] != district ||
          (both && row['sex'] != 'both')) {
        continue;
      }
      final Object? date = row['date'];
      if (date is String) {
        final DateTime? parsed = DateTime.tryParse(date);
        if (parsed != null && (year == null || parsed.year == year)) {
          dates.add(parsed);
        }
      }
    }
    final List<DateTime> sorted = dates.toList();
    sorted.sort((DateTime a, DateTime b) {
      return b.compareTo(a);
    });
    for (final DateTime date in sorted) {
      double total = 0;
      bool valid = true;
      bool observed = false;
      for (final Map<String, Object?> row in rows) {
        if (row['state'] != state ||
            row['district'] != district ||
            (both && row['sex'] != 'both') ||
            row['date'] != date.toIso8601String().substring(0, 10)) {
          continue;
        }
        final double? value = _number(row[field]);
        if (value == null) {
          valid = false;
          break;
        }
        total += value;
        observed = true;
      }
      if (valid && observed) {
        return _InfrastructureAggregate(date.year, total);
      }
    }
    return null;
  }

  static _InfrastructureAggregate? _population(
    List<Map<String, Object?>> population,
    String state,
    String district,
    int year,
  ) {
    int? best;
    double? value;
    for (final Map<String, Object?> row in population) {
      final int? y = _year(row);
      final double? p = _number(row['population']);
      if (row['state'] == state &&
          row['district'] == district &&
          row['sex'] == 'both' &&
          row['age'] == 'overall' &&
          row['ethnicity'] == 'overall' &&
          y != null &&
          y <= year &&
          year - y <= 2 &&
          p != null &&
          p > 0 &&
          (best == null || y > best)) {
        best = y;
        value = p;
      }
    }
    if (best == null || value == null) {
      return null;
    }
    return _InfrastructureAggregate(best, value * 1000);
  }

  static Set<String> _districts(List<Map<String, Object?>> rows) {
    final Set<String> result = <String>{};
    for (final Map<String, Object?> row in rows) {
      if (row['state'] is String &&
          row['district'] is String &&
          row['district'] != 'All Districts' &&
          row['district'] != 'All') {
        result.add('${row['state']}|${row['district']}');
      }
    }
    return result;
  }

  static double? _percentile(double? target, List<double> reference) {
    if (target == null || reference.isEmpty) {
      return null;
    }
    int below = 0;
    for (final double value in reference) {
      if (value <= target) {
        below++;
      }
    }
    return below / reference.length * 100;
  }

  static double? _densityScore(
    List<Map<String, Object?>> rows,
    List<Map<String, Object?>> population,
    String state,
    String district,
    String field,
    double scale,
    _InfrastructureReadings readings,
    String component,
  ) {
    final _InfrastructureAggregate? target = _aggregate(
      rows,
      state,
      district,
      field,
    );
    if (target == null) {
      return null;
    }
    readings.sourceYears[component] = target.year;
    final _InfrastructureAggregate? people = _population(
      population,
      state,
      district,
      target.year,
    );
    if (people == null) {
      return null;
    }
    readings.populationYears[component == 'schools' ? 'education' : component] =
        people.year;
    final List<double> reference = <double>[];
    for (final String pair in _districts(rows)) {
      final List<String> parts = pair.split('|');
      final _InfrastructureAggregate? count = _aggregate(
        rows,
        parts[0],
        parts[1],
        field,
        year: target.year,
      );
      final _InfrastructureAggregate? pop = _population(
        population,
        parts[0],
        parts[1],
        target.year,
      );
      if (count != null && pop != null) {
        reference.add(count.value / pop.value * scale);
      }
    }
    return _percentile(target.value / people.value * scale, reference);
  }

  static Map<String, double?> scores(
    Map<String, Object?> input,
    String state,
    String district,
  ) {
    return _read(input, state, district).scores;
  }

  static _InfrastructureReadings _read(
    Map<String, Object?> input,
    String state,
    String district,
  ) {
    final _InfrastructureReadings readings = _InfrastructureReadings();
    final Map<String, double?> result = readings.scores;
    for (final String field in <String>['piped_water', 'electricity']) {
      int? latestYear;
      double? latestValue;
      for (final Map<String, Object?> row in _rows(input['amenities'])) {
        final int? year = _year(row);
        final double? value = _number(row[field]);
        if (row['state'] == state &&
            row['district'] == district &&
            year != null &&
            value != null &&
            value <= 100 &&
            (latestYear == null || year > latestYear)) {
          latestYear = year;
          latestValue = value;
        }
      }
      final String component = field == 'piped_water' ? 'water' : 'power';
      result[component] = latestValue;
      if (latestYear != null) {
        readings.sourceYears[component] = latestYear;
      }
    }
    final List<Map<String, Object?>> population = _rows(input['population']);
    final List<Map<String, Object?>> beds = _rows(input['beds']);
    final List<Map<String, Object?>> schools = _rows(input['schools']);
    final List<Map<String, Object?>> teachers = _rows(input['teachers']);
    final List<Map<String, Object?>> students = _rows(input['enrolment']);
    result['health'] = _densityScore(
      beds,
      population,
      state,
      district,
      'beds',
      1000,
      readings,
      'health',
    );
    final double? schoolScore = _densityScore(
      schools,
      population,
      state,
      district,
      'schools',
      10000,
      readings,
      'schools',
    );
    final _InfrastructureAggregate? teacher = _aggregate(
      teachers,
      state,
      district,
      'teachers',
      both: true,
    );
    final _InfrastructureAggregate? student = _aggregate(
      students,
      state,
      district,
      'students',
      both: true,
    );
    if (teacher != null) {
      readings.sourceYears['teachers'] = teacher.year;
    }
    if (student != null) {
      readings.sourceYears['enrolment'] = student.year;
    }
    if (schoolScore != null &&
        teacher != null &&
        student != null &&
        student.value > 0) {
      final List<double> reference = <double>[];
      for (final String pair in _districts(teachers)) {
        final List<String> parts = pair.split('|');
        final _InfrastructureAggregate? t = _aggregate(
          teachers,
          parts[0],
          parts[1],
          'teachers',
          both: true,
          year: teacher.year,
        );
        final _InfrastructureAggregate? e = _aggregate(
          students,
          parts[0],
          parts[1],
          'students',
          both: true,
          year: student.year,
        );
        if (t != null && e != null && e.value > 0) {
          reference.add(t.value / e.value * 100);
        }
      }
      final double? resourceScore = _percentile(
        teacher.value / student.value * 100,
        reference,
      );
      if (resourceScore != null) {
        result['education'] = (schoolScore + resourceScore) / 2;
      }
    }
    return readings;
  }
}

final class _InfrastructureAggregate {
  final int year;
  final double value;
  const _InfrastructureAggregate(int year, double value)
    : year = year,
      value = value;
}

final class _InfrastructureReadings {
  final Map<String, double?> scores = <String, double?>{};
  final Map<String, int> sourceYears = <String, int>{};
  final Map<String, int> populationYears = <String, int>{};
}
