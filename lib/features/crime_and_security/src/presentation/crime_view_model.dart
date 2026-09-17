import 'package:flutter/foundation.dart';
import 'package:locatemy/features/map_location/src/domain/location_models.dart';
import '../domain/safety_models.dart';

sealed class CrimeUiState {
  const CrimeUiState();
}

final class CrimeLoading extends CrimeUiState {
  const CrimeLoading();
}

final class CrimeError extends CrimeUiState {
  final SafetyUnavailableReason reason;
  const CrimeError(this.reason);
}

final class CrimeLoaded extends CrimeUiState {
  final SafetySnapshot snapshot;
  const CrimeLoaded(this.snapshot);
}

final class CrimeViewModel extends ChangeNotifier {
  final CrimeAndSecurity service;
  final ValidLocationReference initialLocation;

  CrimeUiState _state = const CrimeLoading();
  CrimeUiState get state => _state;

  CrimeViewModel({
    required this.service,
    required this.initialLocation,
  });

  Future<void> load({SafetyLoadPolicy policy = SafetyLoadPolicy.cacheAllowed}) async {
    _state = const CrimeLoading();
    notifyListeners();

    final outcome = await service.load(
      SafetyRequest(
        location: initialLocation,
        policy: policy,
        filter: const AllCrimeTrend(),
      ),
    );

    if (outcome is SafetyAvailable) {
      _state = CrimeLoaded(outcome.snapshot);
    } else if (outcome is SafetyPartiallyAvailable) {
      _state = CrimeLoaded(outcome.snapshot);
    } else if (outcome is SafetyUnavailable) {
      _state = CrimeError(outcome.reason);
    }
    notifyListeners();
  }

  Future<void> updateFilter(SafetyTrendFilter filter) async {
    if (_state is! CrimeLoaded) return;

    final outcome = await service.load(
      SafetyRequest(
        location: initialLocation,
        policy: SafetyLoadPolicy.cacheAllowed,
        filter: filter,
      ),
    );

    if (outcome is SafetyAvailable) {
      _state = CrimeLoaded(outcome.snapshot);
    } else if (outcome is SafetyPartiallyAvailable) {
      _state = CrimeLoaded(outcome.snapshot);
    }
    notifyListeners();
  }
}
