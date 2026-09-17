// Explicit constructor initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../application/infrastructure_service.dart';
import '../domain/infrastructure_models.dart';

final class InfrastructureViewModel extends ChangeNotifier {
  final InfrastructureService _service = const InfrastructureService();

  ValidLocationReference _location;
  DateTime _analysisDate;
  InfrastructureWeightSettings _weights = const InfrastructureWeightSettings();

  InfrastructureLoadOutcome? _outcome;
  bool _loading = false;
  bool _retainedPreviousResult = false;
  bool _closed = false;
  int _revision = 0;

  InfrastructureViewModel({
    required ValidLocationReference location,
    required DateTime analysisDate,
  }) : _location = location,
       _analysisDate = analysisDate;

  bool get loading => _loading;
  bool get retainedPreviousResult => _retainedPreviousResult;
  InfrastructureLoadOutcome? get outcome => _outcome;
  ValidLocationReference get location => _location;
  DateTime get analysisDate => _analysisDate;
  InfrastructureWeightSettings get weights => _weights;

  Future<void> load([
    InfrastructureLoadPolicy policy = InfrastructureLoadPolicy.cacheAllowed,
  ]) async {
    if (_closed) {
      return;
    }

    final InfrastructureLoadOutcome? previous = _outcome;
    final int revision = ++_revision;
    _loading = true;
    notifyListeners();

    try {
      final InfrastructureLoadOutcome result = await _service.fetch(
        _location,
        _analysisDate,
        policy: policy,
        weights: _weights,
      );
      if (_closed || revision != _revision) {
        return;
      }

      if (policy == InfrastructureLoadPolicy.refresh &&
          previous is InfrastructureAvailable &&
          result is InfrastructureUnavailable) {
        _retainedPreviousResult = true;
        _outcome = previous;
      } else {
        _retainedPreviousResult = false;
        _outcome = result;
      }
    } catch (_) {
      if (_closed || revision != _revision) {
        return;
      }
      if (previous is InfrastructureAvailable) {
        _retainedPreviousResult = true;
        _outcome = previous;
      } else {
        _retainedPreviousResult = false;
        _outcome = const InfrastructureUnavailable(
          'Infrastructure data could not be read. Refresh to retry.',
        );
      }
    } finally {
      if (!_closed && revision == _revision) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> changeLocation(
    ValidLocationReference location,
    DateTime analysisDate,
  ) async {
    _location = location;
    _analysisDate = analysisDate;
    _outcome = null;
    _retainedPreviousResult = false;
    if (!_closed) {
      notifyListeners();
    }
    await load(InfrastructureLoadPolicy.cacheAllowed);
  }

  Future<void> updateWeights({
    int? health,
    int? education,
    int? transit,
  }) async {
    _weights = InfrastructureWeightSettings(
      health: health ?? _weights.health,
      education: education ?? _weights.education,
      transit: transit ?? _weights.transit,
    );
    if (!_closed) {
      notifyListeners();
    }
    await load(InfrastructureLoadPolicy.refresh);
  }

  @override
  void dispose() {
    _closed = true;
    ++_revision;
    _outcome = null;
    super.dispose();
  }
}
