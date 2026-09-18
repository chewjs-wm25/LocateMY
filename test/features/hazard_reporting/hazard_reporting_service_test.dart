import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/hazard_reporting/hazard_reporting.dart';
import 'package:locatemy/features/map_location/map_location.dart';

void main() {
  const ValidLocationReference location = ValidLocationReference(
    locationId: 'valid-location',
    point: GeographicPoint(latitude: 3.0738, longitude: 101.6072),
  );

  test('nearby count rejects an empty location reference id', () async {
    final HazardRiskCounter counter = createHazardRiskCounter(
      store: RecordingHazardStore(),
      currentAccountId: () {
        return 'test';
      },
    );
    final HazardNearbyCountOutcome outcome = await counter.countPending(
      const HazardNearbyCountRequest(
        ValidLocationReference(
          locationId: '',
          point: GeographicPoint(latitude: 3.0738, longitude: 101.6072),
        ),
      ),
    );
    expect(
      (outcome as HazardNearbyCountUnavailable).failure,
      HazardNearbyCountFailure.invalidLocation,
    );
  });

  test('closed account cannot submit a report', () async {
    final HazardReporting hazards = createHazardReporting(
      store: RecordingHazardStore(),
      currentAccountId: () {
        return null;
      },
    );
    final HazardCreateOutcome outcome = await hazards.create(
      const HazardCreateRequest(
        location: location,
        type: HazardType.flood,
        title: 'Flooded walkway',
      ),
    );
    expect(
      (outcome as HazardCreateRejected).failure,
      HazardWriteFailure.scopeUnavailable,
    );
  });

  test(
    'create rejects whitespace-only titles without calling remote storage',
    () async {
      final RecordingHazardStore store = RecordingHazardStore();
      final HazardReporting hazards = createHazardReporting(
        store: store,
        currentAccountId: () {
          return 'test';
        },
      );

      final HazardCreateOutcome outcome = await hazards.create(
        const HazardCreateRequest(
          location: location,
          type: HazardType.flood,
          title: '   ',
        ),
      );

      expect(outcome, isA<HazardCreateRejected>());
      expect(
        (outcome as HazardCreateRejected).failure,
        HazardWriteFailure.emptyTitle,
      );
      expect(store.createCalls, 0);
    },
  );

  test('closing account discards a late detail response', () async {
    String? current = 'a';
    final Completer<HazardDetailOutcome> pending =
        Completer<HazardDetailOutcome>();
    final RecordingHazardStore store = RecordingHazardStore(
      detail: pending.future,
    );
    final HazardReporting hazards = createHazardReporting(
      store: store,
      currentAccountId: () {
        return current;
      },
    );
    final Future<HazardDetailOutcome> response = hazards.loadDetail(
      const HazardReportId('report'),
    );
    current = null;
    pending.complete(const HazardDetailUnavailable(HazardReadFailure.notFound));
    expect(
      (await response as HazardDetailUnavailable).failure,
      HazardReadFailure.scopeUnavailable,
    );
  });

  test(
    'a retained service cannot read private reports after account switch',
    () async {
      String? accountId = 'a';
      final HazardReporting hazards = createHazardReporting(
        store: RecordingHazardStore(),
        currentAccountId: () {
          return accountId;
        },
      );
      accountId = 'b';
      final HazardDetailOutcome result = await hazards.loadDetail(
        const HazardReportId('a-report'),
      );
      expect(
        (result as HazardDetailUnavailable).failure,
        HazardReadFailure.scopeUnavailable,
      );
    },
  );

  test(
    'diagnostics identify outcomes without report content, ids or coordinates',
    () async {
      final List<Map<String, Object>> events = [];
      final HazardReporting hazards = createHazardReporting(
        store: RecordingHazardStore(),
        currentAccountId: () {
          return 'private-account';
        },
        diagnosticSink: (Map<String, Object> event) {
          events.add(event);
        },
      );
      await hazards.loadDetail(
        const HazardReportId('private-report-3.0738-101.6072'),
      );
      expect(events.single['event'], 'hazard.detail.completed');
      expect(events.single['result'], 'notFound');
      expect(events.single.keys.toSet(), {
        'event',
        'feature',
        'result',
        'duration_bucket',
        'correlation_id',
      });
      expect(events.single.toString(), isNot(contains('private-report')));
      expect(events.single.toString(), isNot(contains('private-account')));
    },
  );

  test('nearby count preserves complete availability and radius', () async {
    final RecordingHazardStore store = RecordingHazardStore(
      nearby: HazardNearbyCountAvailable(1, 2000, DateTime.utc(2026, 9, 17)),
    );
    final HazardRiskCounter counter = createHazardRiskCounter(
      store: store,
      currentAccountId: () {
        return 'test';
      },
    );

    final HazardNearbyCountOutcome outcome = await counter.countPending(
      const HazardNearbyCountRequest(location),
    );

    expect(outcome, isA<HazardNearbyCountAvailable>());
    expect((outcome as HazardNearbyCountAvailable).count, 1);
    expect(outcome.radiusMeters, 2000);
  });
}

final class RecordingHazardStore implements HazardStore {
  int createCalls = 0;
  final HazardNearbyCountOutcome nearby;
  final Future<HazardDetailOutcome>? detail;

  RecordingHazardStore({this.detail, HazardNearbyCountOutcome? nearby})
    : nearby =
          nearby ??
          const HazardNearbyCountUnavailable(
            HazardNearbyCountFailure.retryableUnavailable,
          );

  @override
  Future<HazardCreateOutcome> create(HazardCreateRequest request) async {
    createCalls++;
    throw UnimplementedError();
  }

  @override
  Future<HazardNearbyCountOutcome> countPending(
    HazardNearbyCountRequest request,
  ) async => nearby;

  @override
  Future<HazardDeleteOutcome> deleteMine(HazardReportId id) =>
      throw UnimplementedError();
  @override
  Future<HazardDetailOutcome> loadDetail(HazardReportId id) {
    return detail ??
        Future.value(const HazardDetailUnavailable(HazardReadFailure.notFound));
  }

  @override
  Future<MyHazardsOutcome> loadMine(HazardPageRequest request) =>
      throw UnimplementedError();
  @override
  Future<HazardPageOutcome> loadPublic(HazardPageRequest request) =>
      throw UnimplementedError();
  @override
  Future<HazardStatusOutcome> changeMyStatus(HazardStatusRequest request) =>
      throw UnimplementedError();
  @override
  Future<HazardVoteOutcome> vote(HazardVoteRequest request) =>
      throw UnimplementedError();
}
