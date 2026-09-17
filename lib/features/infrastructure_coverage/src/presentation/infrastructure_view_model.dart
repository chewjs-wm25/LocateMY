import 'package:flutter/foundation.dart';
import '../domain/infrastructure_models.dart';
import 'package:locatemy/features/map_location/map_location.dart';

enum InfrastructureLoadPolicy { cacheAllowed, refresh }

final class InfrastructureViewModel extends ChangeNotifier {
  InfrastructureLoadOutcome? _outcome;
  bool _loading = false;
  bool get loading => _loading;
  InfrastructureLoadOutcome? get outcome => _outcome;
  bool retainedPreviousResult = false;

  final ValidLocationReference location;
  DateTime analysisDate;

  InfrastructureViewModel({required this.location, required this.analysisDate});

  Future<void> load([InfrastructureLoadPolicy policy = InfrastructureLoadPolicy.cacheAllowed]) async {
    _loading = true;
    notifyListeners();

    // Lightweight placeholder behaviour: simulate no data available yet.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _outcome = InfrastructureUnavailable('Data not yet implemented');
    _loading = false;
    notifyListeners();
  }

  void changeLocation(ValidLocationReference location, DateTime date) {
    // simple setter for when parent widget updates
    // ignore: prefer_final_locals
    var _ = location;
    analysisDate = date;
    notifyListeners();
  }

  void dispose() {
    super.dispose();
  }
}
