// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:locatemy/features/account_privacy/account_privacy.dart';

import 'hazard_service.dart';
import '../domain/hazard_models.dart';

final class HazardReportingRuntime implements AccountPrivacyParticipant {
  final HazardStore _store;
  final AccountScopeSnapshot Function() _readScope;
  AccountScope? _scope;
  HazardService? _service;
  HazardReportingRuntime({
    required HazardStore store,
    required AccountScopeSnapshot Function() readScope,
  }) : _store = store,
       _readScope = readScope;
  HazardReporting get reporting {
    final AccountScopeSnapshot current = _readScope();
    if (current is! AccountScopeOpened) {
      throw StateError('Hazard scope is not open');
    }
    if (!identical(_scope, current.scope)) {
      _scope = current.scope;
      _service = HazardService(_store, _readScope);
    }
    return _service!;
  }

  HazardRiskCounter get counter {
    return reporting as HazardRiskCounter;
  }

  @override
  AccountPrivacyParticipantId get participantId {
    return AccountPrivacyParticipantId.hazardReporting;
  }

  @override
  Future<PrivateStateClearOutcome> clearPrivateState(AccountScope scope) async {
    if (_scope?.accountId == scope.accountId && _service != null) {
      await _service!.clearPrivateState(scope);
      _service = null;
      _scope = null;
    }
    return PrivateStateCleared(participantId, scope);
  }
}
