

import 'package:flutter/foundation.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../application/infrastructure_service.dart';
import '../domain/infrastructure_models.dart';

final class InfrastructureViewModel extends ChangeNotifier {
  final InfrastructureService _service;
  ValidLocationReference _location;
  DateTime _analysisDate;
  InfrastructureWeightSettings _weights = const InfrastructureWeightSettings();
  InfrastructureWeightSettings _saved = const InfrastructureWeightSettings();
  InfrastructureLoadOutcome? _outcome;
  bool _loading = false;
  bool _closed = false;
  bool _saving = false;
  bool _weightsLoaded = false;
  bool _weightsFailed = false;
  bool _saveFailed = false;
  bool _retained = false;
  int _revision = 0;
  InfrastructureViewModel({
    required InfrastructureService service,
    required ValidLocationReference location,
    required DateTime analysisDate,
  }) : _service = service,
       _location = location,
       _analysisDate = analysisDate;
  bool get loading {
    return _loading;
  }

  bool get saving {
    return _saving;
  }

  bool get weightsLoaded {
    return _weightsLoaded;
  }

  bool get weightsFailed {
    return _weightsFailed;
  }

  bool get saveFailed {
    return _saveFailed;
  }

  bool get preview {
    return !_weights.same(_saved);
  }

  bool get retainedPreviousResult {
    return _retained;
  }

  InfrastructureLoadOutcome? get outcome {
    return _outcome;
  }

  ValidLocationReference get location {
    return _location;
  }

  DateTime get analysisDate {
    return _analysisDate;
  }

  InfrastructureWeightSettings get weights {
    return _weights;
  }

  Future<void> readWeights() async {
    try {
      final InfrastructureWeightSettings result = await _service.weightsStore
          .read();
      if (_closed) {
        return;
      }
      _saved = result;
      _weights = result;
      _weightsLoaded = true;
      _weightsFailed = false;
      _recalculate();
    } catch (_) {
      if (_closed) {
        return;
      }
      _weightsFailed = true;
    }
    notifyListeners();
  }

  Future<void> load([
    InfrastructureLoadPolicy policy = InfrastructureLoadPolicy.cacheAllowed,
  ]) async {
    if (_closed) {
      return;
    }
    final int revision = ++_revision;
    final InfrastructureLoadOutcome? previous = _outcome;
    _loading = true;
    notifyListeners();
    final InfrastructureLoadOutcome result = await _service.fetch(
      _location,
      _analysisDate,
      policy: policy,
      weights: _weights,
    );
    if (_closed || revision != _revision) {
      return;
    }
    _retained = false;
    if (result is InfrastructureUnavailable &&
        (previous is InfrastructureAvailable ||
            previous is InfrastructurePartial)) {
      _outcome = previous;
      _retained = true;
    } else {
      _outcome = result;
    }
    _recalculate();
    _loading = false;
    notifyListeners();
  }

  void _recalculate() {
    final InfrastructureLoadOutcome? current = _outcome;
    InfrastructureCoverage? snapshot;
    if (current is InfrastructureAvailable) {
      snapshot = current.snapshot;
    }
    if (current is InfrastructurePartial) {
      snapshot = current.snapshot;
    }
    if (snapshot == null) {
      return;
    }
    final Map<String, double?> values = <String, double?>{};
    for (final InfrastructureCategoryScore category in snapshot.categories) {
      values[category.key] = category.score;
    }
    final InfrastructureCoverage recalculated = InfrastructureService.evaluate(
      _location,
      _analysisDate,
      values,
      _weights,
      state: snapshot.state,
      district: snapshot.district,
      sourceYears: snapshot.sourceYears,
      populationYears: snapshot.populationYears,
      transitPartial: snapshot.transitPartial,
      transitDistanceOnly: snapshot.transitDistanceOnly,
    );
    if (recalculated.score == null) {
      _outcome = InfrastructurePartial(recalculated);
    } else {
      _outcome = InfrastructureAvailable(recalculated);
    }
  }

  Future<void> updateWeights({
    int? health,
    int? education,
    int? transit,
  }) async {
    if (_closed || !_weightsLoaded || _saving) {
      return;
    }
    final InfrastructureWeightSettings next = InfrastructureWeightSettings(
      health: health ?? _weights.health,
      education: education ?? _weights.education,
      transit: transit ?? _weights.transit,
    );
    if (!next.valid) {
      return;
    }
    _weights = next;
    _saveFailed = false;
    _recalculate();
    notifyListeners();
  }

  void restoreWeights() {
    if (_closed || _saving) {
      return;
    }
    _weights = _saved;
    _saveFailed = false;
    _recalculate();
    notifyListeners();
  }

  Future<void> saveWeights() async {
    if (_closed || _saving || !_weightsLoaded || !preview) {
      return;
    }
    final InfrastructureWeightSettings draft = _weights;
    _saving = true;
    _saveFailed = false;
    notifyListeners();
    try {
      await _service.weightsStore.save(draft);
      if (_closed) {
        return;
      }
      _saved = draft;
    } catch (_) {
      if (_closed) {
        return;
      }
      _saveFailed = true;
    }
    if (!_closed) {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> changeLocation(
    ValidLocationReference location,
    DateTime date,
  ) async {
    if (_closed) {
      return;
    }
    _location = location;
    _analysisDate = date;
    _outcome = null;
    _retained = false;
    await load();
  }

  @override
  void dispose() {
    _closed = true;
    ++_revision;
    super.dispose();
  }
}
