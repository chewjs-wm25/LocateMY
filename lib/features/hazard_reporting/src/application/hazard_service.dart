import 'dart:convert';
import 'dart:developer' as developer;

// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:locatemy/features/account_privacy/account_privacy.dart';

import '../domain/hazard_models.dart';

abstract interface class HazardStore {
  Future<HazardCreateOutcome> create(HazardCreateRequest request);
  Future<HazardPageOutcome> loadPublic(HazardPageRequest request);
  Future<HazardDetailOutcome> loadDetail(HazardReportId id);
  Future<MyHazardsOutcome> loadMine(HazardPageRequest request);
  Future<HazardStatusOutcome> changeMyStatus(HazardStatusRequest request);
  Future<HazardDeleteOutcome> deleteMine(HazardReportId id);
  Future<HazardVoteOutcome> vote(HazardVoteRequest request);
  Future<HazardNearbyCountOutcome> countPending(
    HazardNearbyCountRequest request,
  );
}

HazardReporting createHazardReporting({
  required HazardStore store,
  required AccountScopeSnapshot Function() readScope,
  void Function(Map<String, Object>)? diagnosticSink,
}) {
  return HazardService(store, readScope, diagnosticSink: diagnosticSink);
}

HazardRiskCounter createHazardRiskCounter({
  required HazardStore store,
  required AccountScopeSnapshot Function() readScope,
  void Function(Map<String, Object>)? diagnosticSink,
}) {
  return HazardService(store, readScope, diagnosticSink: diagnosticSink);
}

AccountPrivacyParticipant hazardPrivacyParticipant(HazardReporting reporting) {
  return reporting as HazardService;
}

final class HazardService
    implements HazardReporting, HazardRiskCounter, AccountPrivacyParticipant {
  final HazardStore _store;
  final AccountScopeSnapshot Function() _readScope;
  final void Function(Map<String, Object>)? _diagnosticSink;
  int _serial = 0;
  int _generation = 0;
  AccountScope? _boundScope;
  HazardService(
    HazardStore store,
    AccountScopeSnapshot Function() readScope, {
    void Function(Map<String, Object>)? diagnosticSink,
  }) : _store = store,
       _readScope = readScope,
       _diagnosticSink = diagnosticSink {
    final AccountScopeSnapshot initial = readScope();
    if (initial is AccountScopeOpened) {
      _boundScope = initial.scope;
    }
  }

  @override
  AccountPrivacyParticipantId get participantId {
    return AccountPrivacyParticipantId.hazardReporting;
  }

  @override
  Future<PrivateStateClearOutcome> clearPrivateState(AccountScope scope) async {
    _generation++;
    return PrivateStateCleared(participantId, scope);
  }

  String _resultName(Object? result) {
    if (result is HazardCreateRejected) {
      return result.failure.name;
    }
    if (result is HazardPageUnavailable) {
      return result.failure.name;
    }
    if (result is HazardPagePartial) {
      return 'partial';
    }
    if (result is HazardDetailUnavailable) {
      return result.failure.name;
    }
    if (result is MyHazardsUnavailable) {
      return result.failure.name;
    }
    if (result is HazardStatusRejected) {
      return result.failure.name;
    }
    if (result is HazardDeleteRejected) {
      return result.failure.name;
    }
    if (result is HazardVoteRejected) {
      return result.failure.name;
    }
    if (result is HazardNearbyCountUnavailable) {
      return result.failure.name;
    }
    return 'success';
  }

  Future<T> _guard<T>(
    Future<T> Function() operation,
    T unavailable,
    T retryable,
    String event,
  ) async {
    final Stopwatch timer = Stopwatch();
    timer.start();
    final int serial = ++_serial;
    final AccountScopeSnapshot before = _readScope();
    T result = unavailable;
    if (before is AccountScopeOpened && identical(before.scope, _boundScope)) {
      final int generation = _generation;
      try {
        result = await operation();
      } catch (_) {
        result = retryable;
      }
      final AccountScopeSnapshot after = _readScope();
      if (generation != _generation ||
          after is! AccountScopeOpened ||
          !identical(before.scope, after.scope)) {
        result = unavailable;
      }
    }
    timer.stop();
    String duration = 'over1s';
    if (timer.elapsedMilliseconds < 100) {
      duration = 'under100ms';
    } else if (timer.elapsedMilliseconds < 1000) {
      duration = 'under1s';
    }
    final Map<String, Object> diagnostic = {
      'event': event,
      'feature': 'hazard_reporting',
      'result': _resultName(result),
      'duration_bucket': duration,
      'correlation_id': 'hazard-$serial',
    };
    try {
      if (_diagnosticSink != null) {
        _diagnosticSink(diagnostic);
      } else {
        developer.log(jsonEncode(diagnostic), name: 'locatemy');
      }
    } catch (_) {
      /* Diagnostics never change a business outcome. */
    }
    return result;
  }

  @override
  Future<HazardCreateOutcome> create(HazardCreateRequest request) {
    return _guard(
      () async {
        final String title = request.title.trim();
        if (title.isEmpty) {
          return const HazardCreateRejected(HazardWriteFailure.emptyTitle);
        }
        if (title.runes.length > 120) {
          return const HazardCreateRejected(HazardWriteFailure.titleTooLong);
        }
        if (request.description != null &&
            request.description!.runes.length > 2000) {
          return const HazardCreateRejected(
            HazardWriteFailure.descriptionTooLong,
          );
        }
        if (request.location.locationId.isEmpty ||
            !_validLocation(
              request.location.point.latitude,
              request.location.point.longitude,
            )) {
          return const HazardCreateRejected(HazardWriteFailure.invalidLocation);
        }
        return _store.create(
          HazardCreateRequest(
            location: request.location,
            type: request.type,
            title: title,
            description: request.description,
          ),
        );
      },
      const HazardCreateRejected(HazardWriteFailure.scopeUnavailable),
      const HazardCreateRejected(HazardWriteFailure.retryableUnavailable),
      'hazard.create.completed',
    );
  }

  @override
  Future<HazardPageOutcome> loadPublic(HazardPageRequest request) {
    return _guard(
      () async {
        if (!_validViewport(request)) {
          return const HazardPageUnavailable(HazardReadFailure.invalidViewport);
        }
        return _store.loadPublic(request);
      },
      const HazardPageUnavailable(HazardReadFailure.scopeUnavailable),
      const HazardPageUnavailable(HazardReadFailure.retryableUnavailable),
      'hazard.public_page.completed',
    );
  }

  @override
  Future<HazardDetailOutcome> loadDetail(HazardReportId id) {
    return _guard(
      () {
        return _store.loadDetail(id);
      },
      const HazardDetailUnavailable(HazardReadFailure.scopeUnavailable),
      const HazardDetailUnavailable(HazardReadFailure.retryableUnavailable),
      'hazard.detail.completed',
    );
  }

  @override
  Future<MyHazardsOutcome> loadMine(HazardPageRequest request) {
    return _guard(
      () async {
        if (!_validViewport(request)) {
          return const MyHazardsUnavailable(HazardReadFailure.invalidViewport);
        }
        return _store.loadMine(request);
      },
      const MyHazardsUnavailable(HazardReadFailure.scopeUnavailable),
      const MyHazardsUnavailable(HazardReadFailure.retryableUnavailable),
      'hazard.mine.completed',
    );
  }

  @override
  Future<HazardStatusOutcome> changeMyStatus(HazardStatusRequest request) {
    return _guard(
      () {
        return _store.changeMyStatus(request);
      },
      const HazardStatusRejected(HazardWriteFailure.scopeUnavailable),
      const HazardStatusRejected(HazardWriteFailure.retryableUnavailable),
      'hazard.status.completed',
    );
  }

  @override
  Future<HazardDeleteOutcome> deleteMine(HazardReportId id) {
    return _guard(
      () {
        return _store.deleteMine(id);
      },
      const HazardDeleteRejected(HazardWriteFailure.scopeUnavailable),
      const HazardDeleteRejected(HazardWriteFailure.retryableUnavailable),
      'hazard.delete.completed',
    );
  }

  @override
  Future<HazardVoteOutcome> vote(HazardVoteRequest request) {
    return _guard(
      () {
        return _store.vote(request);
      },
      const HazardVoteRejected(HazardWriteFailure.scopeUnavailable),
      const HazardVoteRejected(HazardWriteFailure.retryableUnavailable),
      'hazard.vote.completed',
    );
  }

  @override
  Future<HazardNearbyCountOutcome> countPending(
    HazardNearbyCountRequest request,
  ) {
    return _guard(
      () async {
        if (request.propertyLocation.locationId.trim().isEmpty ||
            !_validLocation(
              request.propertyLocation.point.latitude,
              request.propertyLocation.point.longitude,
            )) {
          return const HazardNearbyCountUnavailable(
            HazardNearbyCountFailure.invalidLocation,
          );
        }
        return _store.countPending(request);
      },
      const HazardNearbyCountUnavailable(
        HazardNearbyCountFailure.scopeUnavailable,
      ),
      const HazardNearbyCountUnavailable(
        HazardNearbyCountFailure.retryableUnavailable,
      ),
      'hazard.nearby_count.completed',
    );
  }

  bool _validViewport(HazardPageRequest request) {
    final double south = request.viewport.southWest.latitude;
    final double west = request.viewport.southWest.longitude;
    final double north = request.viewport.northEast.latitude;
    final double east = request.viewport.northEast.longitude;
    return request.viewportVersion.isNotEmpty &&
        _validLocation(south, west) &&
        _validLocation(north, east) &&
        south <= north &&
        west <= east;
  }

  bool _validLocation(double latitude, double longitude) {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}
