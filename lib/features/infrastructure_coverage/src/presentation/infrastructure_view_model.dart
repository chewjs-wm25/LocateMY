import 'package:flutter/foundation.dart';
import '../domain/infrastructure_models.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import '../application/infrastructure_service.dart';

enum InfrastructureLoadPolicy { cacheAllowed, refresh }

final class InfrastructureViewModel extends ChangeNotifier {
  final InfrastructureService _service = const InfrastructureService();

  ValidLocationReference _location;
  DateTime _analysisDate;

  InfrastructureLoadOutcome? _outcome;
  bool _loading = false;
  bool get loading => _loading;
  InfrastructureLoadOutcome? get outcome => _outcome;
  bool retainedPreviousResult = false;

  ValidLocationReference get location => _location;
  DateTime get analysisDate => _analysisDate;

  int _revision = 0;
  bool _closed = false;

  InfrastructureViewModel({required ValidLocationReference location, required DateTime analysisDate})
      : _location = location,
        _analysisDate = analysisDate;

  Future<void> load([InfrastructureLoadPolicy policy = InfrastructureLoadPolicy.cacheAllowed]) async {
    _loading = true;
    notifyListeners();

    final int rev = ++_revision;

    final InfrastructureLoadOutcome outcome = await _service.fetch(_location, _analysisDate, policy: policy);

    if (_closed || rev != _revision) {
      // a later request superseded this one or the model was disposed; drop the result
      return;
    }

    _outcome = outcome;
    _loading = false;
    notifyListeners();
  }

  Future<void> changeLocation(ValidLocationReference location, DateTime date) async {
    _location = location;
    _analysisDate = date;
    _outcome = null;
    _revision++;
    if (!_closed) notifyListeners();
    await load(InfrastructureLoadPolicy.cacheAllowed);
  }

  @override
  void dispose() {
    _closed = true;
    _outcome = null;
    super.dispose();
  }
}
