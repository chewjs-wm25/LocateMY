// Explicit parameter types and initialization follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import '../../../account_privacy/account_privacy.dart';
import '../domain/location_models.dart';
import 'location_service.dart';
import 'location_storage.dart';

/// Process-owned registration; private services are created only for opened scopes.
class MapLocationRuntime implements AccountPrivacyParticipant {
  MapLocationRuntime({
    required AccountScopeSnapshot Function() readScope,
    required Future<bool> Function(GeographicPoint) validatePoint,
    required LocationStorage Function(String) storageForAccount,
  }) : readScope = readScope,
       validatePoint = validatePoint,
       storageForAccount = storageForAccount;
  final AccountScopeSnapshot Function() readScope;
  final Future<bool> Function(GeographicPoint) validatePoint;
  final LocationStorage Function(String) storageForAccount;
  LocationService? _service;
  LocationCoordinator get locations {
    final AccountScopeSnapshot current = readScope();
    if (current is! AccountScopeOpened) {
      throw StateError('Map scope is not open');
    }
    if (!identical(_service?.scope, current.scope)) {
      _service = LocationService(
        scope: current.scope,
        readScope: readScope,
        validatePoint: validatePoint,
        storage: storageForAccount(current.scope.accountId),
      );
    }
    return _service!;
  }

  @override
  AccountPrivacyParticipantId get participantId {
    return AccountPrivacyParticipantId.mapLocation;
  }

  @override
  Future<PrivateStateClearOutcome> clearPrivateState(AccountScope scope) async {
    if (_service?.scope.accountId == scope.accountId) {
      return _service!.clearPrivateState(scope);
    }
    try {
      await storageForAccount(scope.accountId).clearLocal();
      return PrivateStateCleared(participantId, scope);
    } catch (_) {
      return PrivateStateClearIncomplete(
        participantId,
        scope,
        PrivateStateClearFailure.localStoreUnavailable,
      );
    }
  }
}
