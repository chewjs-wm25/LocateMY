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

  static InfrastructureCoverage evaluate(
    ValidLocationReference location,
    DateTime analysisDate,
    Map<String, double?> scores,
    InfrastructureWeightSettings weights, {
    String? state,
    String? district,
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
      location: location,
      analysisDate: analysisDate,
      weights: weights,
      categories: List<InfrastructureCategoryScore>.unmodifiable(categories),
      missingCategories: List<String>.unmodifiable(missing),
      state: state,
      district: district,
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
              await cache?.write(scope, inputs);
              await cache?.write(key, <String, Object?>{
                'state': state,
                'district': district,
                'inputs': inputs,
              });
            } catch (_) {
              /* Readable observations survive cache write failure. */
            }
          }
        }
      }
      final Map<String, double?> scores = <String, double?>{};
      if (inputs != null && state != null && district != null) {
        scores.addAll(InfrastructureInputRules.scores(inputs, state, district));
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
      }
      final InfrastructureCoverage result = evaluate(
        location,
        analysisDate,
        scores,
        weights,
        state: state,
        district: district,
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

  static List<Map<String, Object?>> _latest(
    List<Map<String, Object?>> rows,
    String state,
    String district,
  ) {
    int? year;
    for (final Map<String, Object?> row in rows) {
      final int? y = _year(row);
      if (row['state'] == state &&
          row['district'] == district &&
          y != null &&
          (year == null || y > year)) {
        year = y;
      }
    }
    final List<Map<String, Object?>> result = <Map<String, Object?>>[];
    for (final Map<String, Object?> row in rows) {
      if (row['state'] == state &&
          row['district'] == district &&
          _year(row) == year) {
        result.add(row);
      }
    }
    return result;
  }

  static double? _population(
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
    // Official population_district values are in thousands of persons.
    if (value == null) {
      return null;
    }
    return value * 1000;
  }

  static double? _sum(
    List<Map<String, Object?>> rows,
    String field, {
    bool both = false,
  }) {
    double total = 0;
    bool observed = false;
    for (final Map<String, Object?> row in rows) {
      if (both && row['sex'] != 'both') {
        continue;
      }
      final double? value = _number(row[field]);
      if (value == null) {
        return null;
      }
      total += value;
      observed = true;
    }
    if (!observed) {
      return null;
    }
    return total;
  }

  static double? _density(
    List<Map<String, Object?>> rows,
    List<Map<String, Object?>> population,
    String state,
    String district,
    int year,
    String field,
    double scale,
  ) {
    final List<Map<String, Object?>> same = <Map<String, Object?>>[];
    for (final Map<String, Object?> row in rows) {
      if (row['state'] == state &&
          row['district'] == district &&
          _year(row) == year) {
        same.add(row);
      }
    }
    final double? count = _sum(same, field);
    final double? people = _population(population, state, district, year);
    if (count == null || people == null) {
      return null;
    }
    return count / people * scale;
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

  static Map<String, double?> scores(
    Map<String, Object?> input,
    String state,
    String district,
  ) {
    final Map<String, double?> result = <String, double?>{};
    final List<Map<String, Object?>> amenities = _rows(input['amenities']);
    for (final String field in <String>['piped_water', 'electricity']) {
      int? latestYear;
      double? latestValue;
      for (final Map<String, Object?> row in amenities) {
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
      result[field == 'piped_water' ? 'water' : 'power'] = latestValue;
    }
    final List<Map<String, Object?>> population = _rows(input['population']);
    final List<Map<String, Object?>> beds = _rows(input['beds']);
    final List<Map<String, Object?>> schools = _rows(input['schools']);
    final List<Map<String, Object?>> teachers = _rows(input['teachers']);
    final List<Map<String, Object?>> students = _rows(input['enrolment']);
    for (final String kind in <String>['health', 'education']) {
      final List<Map<String, Object?>> rows = kind == 'health' ? beds : schools;
      final List<Map<String, Object?>> selected = _latest(
        rows,
        state,
        district,
      );
      if (selected.isEmpty) {
        continue;
      }
      final int? year = _year(selected.first);
      if (year == null) {
        continue;
      }
      final Set<String> districts = <String>{};
      for (final Map<String, Object?> row in rows) {
        if (_year(row) == year &&
            row['district'] != 'All Districts' &&
            row['district'] != 'All' &&
            row['state'] is String &&
            row['district'] is String) {
          districts.add('${row['state']}|${row['district']}');
        }
      }
      final List<double> densityReference = <double>[];
      final List<double> ratioReference = <double>[];
      double? targetDensity;
      double? targetRatio;
      for (final String pair in districts) {
        final List<String> parts = pair.split('|');
        final String s = parts[0];
        final String d = parts[1];
        final double? density = _density(
          rows,
          population,
          s,
          d,
          year,
          kind == 'health' ? 'beds' : 'schools',
          kind == 'health' ? 1000 : 10000,
        );
        double? ratio;
        if (kind == 'education') {
          final List<Map<String, Object?>> t = <Map<String, Object?>>[];
          final List<Map<String, Object?>> e = <Map<String, Object?>>[];
          for (final Map<String, Object?> r in teachers) {
            if (r['state'] == s && r['district'] == d && _year(r) == year) {
              t.add(r);
            }
          }
          for (final Map<String, Object?> r in students) {
            if (r['state'] == s && r['district'] == d && _year(r) == year) {
              e.add(r);
            }
          }
          final double? tc = _sum(t, 'teachers', both: true);
          final double? ec = _sum(e, 'students', both: true);
          if (tc != null && ec != null && ec > 0) {
            ratio = tc / ec * 100;
          }
        }
        if (density != null) {
          densityReference.add(density);
        }
        if (ratio != null) {
          ratioReference.add(ratio);
        }
        if (s == state && d == district) {
          targetDensity = density;
          targetRatio = ratio;
        }
      }
      final double? densityScore = _percentile(targetDensity, densityReference);
      if (kind == 'health') {
        result[kind] = densityScore;
      } else {
        final double? ratioScore = _percentile(targetRatio, ratioReference);
        if (densityScore != null && ratioScore != null) {
          result[kind] = (densityScore + ratioScore) / 2;
        }
      }
    }
    return result;
  }
}
