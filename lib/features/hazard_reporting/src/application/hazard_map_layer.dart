// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/hazard_models.dart';

final class HazardMapLayer extends ChangeNotifier {
  final HazardReporting _reports;
  final MapLayerHost _host;
  HazardPageRequest? _request;
  int _generation = 0;
  bool _disposed = false;
  bool _retryMore = false;
  bool loading = false;
  HazardReadFailure? failure;
  String? nextCursor;
  List<HazardReport> reports = const [];
  HazardMapLayer(HazardReporting reports, MapLayerHost host)
    : _reports = reports,
      _host = host;
  Future<void> refresh(HazardPageRequest request, {bool more = false}) async {
    if (more && (loading || nextCursor == null)) {
      return;
    }
    final int generation = ++_generation;
    final bool newViewport =
        _request?.viewportVersion != request.viewportVersion;
    _request = request;
    if (newViewport) {
      reports = const [];
      nextCursor = null;
    }
    _retryMore = more;
    loading = true;
    failure = null;
    notifyListeners();
    HazardPageOutcome outcome;
    try {
      outcome = await _reports.loadPublic(
        HazardPageRequest(
          viewportVersion: request.viewportVersion,
          viewport: request.viewport,
          cursor: more ? nextCursor : null,
        ),
      );
    } catch (_) {
      outcome = const HazardPageUnavailable(
        HazardReadFailure.retryableUnavailable,
      );
    }
    if (_disposed || generation != _generation) {
      return;
    }
    loading = false;
    HazardPage? page;
    if (outcome is HazardPageAvailable) {
      page = outcome.page;
    } else if (outcome is HazardPagePartial) {
      page = outcome.page;
      failure = outcome.failure;
    } else {
      failure = (outcome as HazardPageUnavailable).failure;
    }
    if (page != null && page.viewportVersion == request.viewportVersion) {
      final List<HazardReport> updated = [];
      if (more) {
        updated.addAll(reports);
      }
      for (final HazardReport report in page.reports) {
        updated.removeWhere((HazardReport previous) {
          return previous.id.value == report.id.value;
        });
        updated.add(report);
      }
      reports = List.unmodifiable(updated);
      nextCursor = page.nextCursor;
      final List<MapLayerItem> items = [];
      for (final HazardReport report in reports) {
        items.add(
          MapLayerItem(
            stableItemId: report.id.value,
            point: report.location,
            markerKind: _markerKind(report.type),
            intent: ProviderDefinedIntent(
              providerId: 'hazard-reporting',
              action: 'detail',
              stableItemId: report.id.value,
            ),
          ),
        );
      }
      final MapLayerContributionOutcome contribution = await _host.contribute(
        MapLayerContribution(
          providerId: 'hazard-reporting',
          layerId: 'public-hazards',
          viewportVersion: request.viewportVersion,
          visibility: MapLayerVisibility.visible,
          items: items,
        ),
      );
      if (_disposed || generation != _generation) {
        return;
      }
      if (contribution is MapLayerRejected) {
        switch (contribution.failure) {
          case MapLayerFailure.staleViewport:
            // The host moved ahead; the next viewport request replaces this page.
            break;
          case MapLayerFailure.scopeUnavailable:
            failure = HazardReadFailure.scopeUnavailable;
          case MapLayerFailure.unauthenticated:
            failure = HazardReadFailure.authenticationRequired;
          case MapLayerFailure.invalidContribution:
          case MapLayerFailure.invalidCoordinate:
          case MapLayerFailure.outsideMalaysia:
            failure = HazardReadFailure.invalidViewport;
        }
      }
    } else if (page != null) {
      failure = HazardReadFailure.invalidViewport;
    }
    if (failure == HazardReadFailure.scopeUnavailable ||
        failure == HazardReadFailure.authenticationRequired) {
      reports = const [];
      nextCursor = null;
    }
    notifyListeners();
  }

  Future<void> retry() async {
    final HazardPageRequest? request = _request;
    if (request != null) {
      await refresh(
        request,
        more: _retryMore && failure != HazardReadFailure.invalidViewport,
      );
    }
  }

  MapMarkerKind _markerKind(HazardType type) {
    switch (type) {
      case HazardType.flood:
        return MapMarkerKind.hazardFlood;
      case HazardType.crime:
        return MapMarkerKind.hazardCrime;
      case HazardType.traffic:
        return MapMarkerKind.hazardTraffic;
      case HazardType.infrastructure:
        return MapMarkerKind.hazardInfrastructure;
      case HazardType.other:
        return MapMarkerKind.hazardOther;
    }
  }

  Future<void> more() async {
    final HazardPageRequest? request = _request;
    if (request != null) {
      await refresh(request, more: true);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
