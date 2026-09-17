// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/safety_models.dart';

final class SafetyViewModel extends ChangeNotifier {
  final CrimeSecurity _crime;
  final ValidLocationReference location;
  final ValidLocationReference? locationB;
  SafetyComparison? comparison;
  bool swapped = false;
  bool loading = false;
  SafetyAnalysis? analysis;
  bool _disposed = false;
  int _generation = 0;
  String filter = 'all';
  SafetyViewModel(
    CrimeSecurity crime,
    ValidLocationReference location, {
    ValidLocationReference? locationB,
  }) : _crime = crime,
       location = location,
       locationB = locationB;
  Future<void> load({bool refresh = false}) async {
    final int generation = ++_generation;
    loading = true;
    notifyListeners();
    SafetyAnalysis result;
    SafetyComparison? compared;
    final ValidLocationReference? second = locationB;
    if (second == null) {
      result = await _crime.analyse(location, refresh: refresh);
    } else {
      compared = await _crime.compare(location, second, refresh: refresh);
      result = compared.a;
    }
    if (_disposed || generation != _generation) {
      return;
    }
    analysis = result;
    comparison = compared;
    loading = false;
    if (!result.trends.containsKey(filter)) {
      filter = 'all';
    }
    notifyListeners();
  }

  void swap() {
    swapped = !swapped;
    notifyListeners();
  }

  void select(String filter) {
    this.filter = filter;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
