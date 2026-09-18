

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../map_location/map_location.dart';
import '../domain/socio_models.dart';

final class SocioViewModel extends ChangeNotifier {
  final SocioEconomic _service;
  final ValidLocationReference _a;
  final ValidLocationReference? _b;
  StreamSubscription<void>? _subscription;
  SocioAnalysis? a;
  SocioAnalysis? b;
  bool loading = false;
  bool failed = false;
  bool _disposed = false;
  int _generation = 0;
  SocioViewModel(
    SocioEconomic service,
    ValidLocationReference a,
    ValidLocationReference? b,
  ) : _service = service,
      _a = a,
      _b = b {
    _subscription = _service.changes.listen((_) {
      load();
    });
  }
  Future<void> load({bool refresh = false}) async {
    final int generation = ++_generation;
    loading = true;
    failed = false;
    notifyListeners();
    try {
      SocioAnalysis first;
      SocioAnalysis? second;
      if (_b == null) {
        first = await _service.analyse(_a, refresh: refresh);
      } else {
        final SocioComparison result = await _service.compare(
          _a,
          _b,
          refresh: refresh,
        );
        first = result.a;
        second = result.b;
      }
      if (_disposed || generation != _generation) {
        return;
      }
      if (first.failure != null && a != null) {
        failed = true;
        a = a?.withoutPosition();
      } else {
        a = first;
      }
      if (second?.failure != null && b != null) {
        failed = true;
        b = b?.withoutPosition();
      } else {
        b = second;
      }
    } catch (_) {
      if (_disposed || generation != _generation) {
        return;
      }
      failed = true;
      a = a?.withoutPosition();
      b = b?.withoutPosition();
    }
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _subscription?.cancel();
    super.dispose();
  }
}
