// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../application/hazard_service.dart';
import '../domain/hazard_models.dart';

HazardStore createSupabaseHazardStore(SupabaseClient client) {
  return SupabaseHazardStore(client);
}

final class SupabaseHazardStore implements HazardStore {
  final SupabaseClient _client;
  SupabaseHazardStore(SupabaseClient client) : _client = client;

  Future<dynamic> _rpc(String name, {required Map<String, dynamic> params}) {
    return _client
        .rpc(name, params: params)
        .timeout(const Duration(seconds: 20));
  }

  HazardReport _report(dynamic value) {
    final Map<String, dynamic> row = Map<String, dynamic>.from(value as Map);
    final Map<String, dynamic> votes = Map<String, dynamic>.from(
      row['vote'] as Map,
    );
    return HazardReport(
      id: HazardReportId(row['id'] as String),
      type: HazardType.values.byName(row['type'] as String),
      title: row['title'] as String,
      description: row['description'] as String?,
      location: GeographicPoint(
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
      ),
      status: HazardAuthorStatus.values.byName(row['status'] as String),
      reportedAt: DateTime.parse(row['reported_at'] as String),
      author: HazardAuthorView.values.byName(row['author'] as String),
      vote: _voteState(votes),
    );
  }

  HazardVoteState _voteState(Map<String, dynamic> votes) {
    if (votes['upvotes'] is! int ||
        votes['downvotes'] is! int ||
        (votes['upvotes'] as int) < 0 ||
        (votes['downvotes'] as int) < 0) {
      throw const FormatException('Invalid aggregate counts');
    }
    return HazardVoteState(
      HazardVote.values.byName(votes['mine'] as String),
      votes['upvotes'] as int,
      votes['downvotes'] as int,
    );
  }

  HazardWriteFailure _writeFailure(Object error) {
    if (error is PostgrestException) {
      switch (error.code) {
        case 'PT401':
        case 'PGRST301':
        case 'PGRST302':
          return HazardWriteFailure.authenticationRequired;
        case '42501':
          return HazardWriteFailure.permissionDenied;
        case 'P0002':
          return HazardWriteFailure.notFound;
        case '23503':
          return HazardWriteFailure.notFound;
        case '23505':
        case '40001':
        case '40P01':
          return HazardWriteFailure.conflict;
        case '22023':
        case '22P02':
        case '23514':
          return HazardWriteFailure.invalidLocation;
      }
    }
    return HazardWriteFailure.retryableUnavailable;
  }

  HazardReadFailure _readFailure(Object error) {
    final HazardWriteFailure failure = _writeFailure(error);
    if (failure == HazardWriteFailure.authenticationRequired ||
        failure == HazardWriteFailure.permissionDenied) {
      return HazardReadFailure.authenticationRequired;
    }
    if (failure == HazardWriteFailure.notFound) {
      return HazardReadFailure.notFound;
    }
    if (failure == HazardWriteFailure.invalidLocation) {
      return HazardReadFailure.invalidViewport;
    }
    return HazardReadFailure.retryableUnavailable;
  }

  @override
  Future<HazardCreateOutcome> create(HazardCreateRequest request) async {
    try {
      final dynamic row = await _rpc(
        'hazard_create',
        params: {
          'p_type': request.type.name,
          'p_title': request.title,
          'p_description': request.description,
          'p_latitude': request.location.point.latitude,
          'p_longitude': request.location.point.longitude,
        },
      );
      return HazardCreated(_report(row));
    } catch (error) {
      return HazardCreateRejected(_writeFailure(error));
    }
  }

  @override
  Future<HazardDetailOutcome> loadDetail(HazardReportId id) async {
    try {
      return HazardDetailAvailable(
        _report(await _rpc('hazard_detail', params: {'p_id': id.value})),
      );
    } catch (error) {
      return HazardDetailUnavailable(_readFailure(error));
    }
  }

  @override
  Future<HazardPageOutcome> loadPublic(HazardPageRequest request) async {
    try {
      return await _page(request, false);
    } catch (error) {
      return HazardPageUnavailable(_readFailure(error));
    }
  }

  Future<HazardPageOutcome> _page(HazardPageRequest request, bool mine) async {
    final dynamic data = await _rpc(
      'hazard_page',
      params: {
        'p_mine': mine,
        'p_south': request.viewport.southWest.latitude,
        'p_west': request.viewport.southWest.longitude,
        'p_north': request.viewport.northEast.latitude,
        'p_east': request.viewport.northEast.longitude,
        'p_cursor': request.cursor,
      },
    );
    final Map<String, dynamic> value = Map<String, dynamic>.from(data as Map);
    final List<HazardReport> reports = [];
    bool incomplete = false;
    for (final dynamic row in value['reports'] as List) {
      try {
        reports.add(_report(row));
      } catch (_) {
        incomplete = true;
      }
    }
    final HazardPage page = HazardPage(
      List.unmodifiable(reports),
      value['next_cursor'] as String?,
      request.viewportVersion,
    );
    if (incomplete) {
      return HazardPagePartial(page, HazardReadFailure.incompletePage);
    }
    return HazardPageAvailable(page);
  }

  @override
  Future<MyHazardsOutcome> loadMine(HazardPageRequest request) async {
    try {
      final HazardPageOutcome outcome = await _page(request, true);
      if (outcome is HazardPageAvailable) {
        return MyHazardsAvailable(outcome.page);
      }
      return const MyHazardsUnavailable(HazardReadFailure.retryableUnavailable);
    } catch (error) {
      return MyHazardsUnavailable(_readFailure(error));
    }
  }

  @override
  Future<HazardStatusOutcome> changeMyStatus(
    HazardStatusRequest request,
  ) async {
    try {
      return HazardStatusChanged(
        _report(
          await _rpc(
            'hazard_status',
            params: {'p_id': request.id.value, 'p_status': request.status.name},
          ),
        ),
      );
    } catch (error) {
      return HazardStatusRejected(_writeFailure(error));
    }
  }

  @override
  Future<HazardDeleteOutcome> deleteMine(HazardReportId id) async {
    try {
      final dynamic deleted = await _rpc(
        'hazard_delete',
        params: {'p_id': id.value},
      );
      if (deleted != true) {
        return const HazardDeleteRejected(HazardWriteFailure.notFound);
      }
      return HazardDeleted(id);
    } catch (error) {
      return HazardDeleteRejected(_writeFailure(error));
    }
  }

  @override
  Future<HazardVoteOutcome> vote(HazardVoteRequest request) async {
    try {
      final dynamic data = await _rpc(
        'hazard_vote',
        params: {'p_id': request.id.value, 'p_vote': request.vote.name},
      );
      final Map<String, dynamic> value = Map<String, dynamic>.from(data as Map);
      return HazardVoteChanged(request.id, _voteState(value));
    } catch (error) {
      return HazardVoteRejected(_writeFailure(error));
    }
  }

  @override
  Future<HazardNearbyCountOutcome> countPending(
    HazardNearbyCountRequest request,
  ) async {
    try {
      final dynamic data = await _rpc(
        'hazard_pending_count',
        params: {
          'p_latitude': request.propertyLocation.point.latitude,
          'p_longitude': request.propertyLocation.point.longitude,
        },
      );
      final Map<String, dynamic> value = Map<String, dynamic>.from(data as Map);
      if (value['complete'] != true ||
          value['radius_meters'] != 2000 ||
          value['count'] is! int ||
          (value['count'] as int) < 0) {
        return const HazardNearbyCountUnavailable(
          HazardNearbyCountFailure.partialResult,
        );
      }
      return HazardNearbyCountAvailable(
        value['count'] as int,
        2000,
        DateTime.parse(value['counted_at'] as String),
      );
    } catch (error) {
      final HazardWriteFailure failure = _writeFailure(error);
      if (failure == HazardWriteFailure.authenticationRequired ||
          failure == HazardWriteFailure.permissionDenied) {
        return const HazardNearbyCountUnavailable(
          HazardNearbyCountFailure.authenticationRequired,
        );
      }
      if (failure == HazardWriteFailure.invalidLocation) {
        return const HazardNearbyCountUnavailable(
          HazardNearbyCountFailure.invalidLocation,
        );
      }
      return const HazardNearbyCountUnavailable(
        HazardNearbyCountFailure.retryableUnavailable,
      );
    }
  }
}
