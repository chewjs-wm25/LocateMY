import 'package:flutter/foundation.dart';
import '../domain/infrastructure_models.dart';
import 'package:locatemy/features/map_location/map_location.dart';

enum InfrastructureLoadPolicy { cacheAllowed, refresh }

final class InfrastructureViewModel extends ChangeNotifier {
  ValidLocationReference _location;
  DateTime _analysisDate;

  InfrastructureLoadOutcome? _outcome;
  bool _loading = false;
  bool get loading => _loading;
  InfrastructureLoadOutcome? get outcome => _outcome;
  bool retainedPreviousResult = false;

  ValidLocationReference get location => _location;
  DateTime get analysisDate => _analysisDate;

  InfrastructureViewModel({required ValidLocationReference location, required DateTime analysisDate})
      : _location = location,
        _analysisDate = analysisDate;

  Future<void> load([InfrastructureLoadPolicy policy = InfrastructureLoadPolicy.cacheAllowed]) async {
    _loading = true;
    notifyListeners();

    // Lightweight placeholder behaviour: simulate no data available yet.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _outcome = InfrastructureUnavailable('Data not yet implemented');
    _loading = false;
    notifyListeners();
  }

  Future<void> changeLocation(ValidLocationReference location, DateTime date) async {
    _location = location;
    _analysisDate = date;
    _outcome = null;
    notifyListeners();
    await load(InfrastructureLoadPolicy.cacheAllowed);
  }

  @override
  void dispose() {
    _outcome = null;
    super.dispose();
  }
}
