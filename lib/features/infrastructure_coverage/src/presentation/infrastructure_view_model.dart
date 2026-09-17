import 'package:flutter/foundation.dart';
import '../domain/infrastructure_models.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import '../application/infrastructure_service.dart';

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
    if (_closed) return;

    _loading = true;
    notifyListeners();

    final int rev = ++_revision;

    final InfrastructureLoadOutcome? previous = _outcome;

    try {
      final InfrastructureLoadOutcome outcome = await _service.fetch(_location, _analysisDate, policy: policy);

      if (_closed || rev != _revision) return;

      // preserve a previous successful result on refresh failures
      if (policy == InfrastructureLoadPolicy.refresh) {
        if (outcome is InfrastructureUnavailable && previous is InfrastructureAvailable) {
          retainedPreviousResult = true;
          _outcome = previous;
        } else {
          retainedPreviousResult = false;
          _outcome = outcome;
        }
      } else {
        retainedPreviousResult = false;
        _outcome = outcome;
      }
    } catch (e) {
      // on error, preserve previous successful result if available
      if (_closed || rev != _revision) return;
      if (previous is InfrastructureAvailable) {
        retainedPreviousResult = true;
        _outcome = previous;
      } else {
        retainedPreviousResult = false;
        _outcome = InfrastructureUnavailable('Error retrieving data');
      }
    } finally {
      if (_closed || rev != _revision) return;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> changeLocation(ValidLocationReference location, DateTime date) async {
    _location = location;
    _analysisDate = date;
    _outcome = null;
    retainedPreviousResult = false;
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
