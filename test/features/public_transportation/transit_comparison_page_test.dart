// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import 'public_transportation_page_test.dart' show RecordingTransitShell;

import 'public_transportation_test.dart' show expectedTestFeeds;

import 'package:locatemy/features/public_transportation/public_transportation.dart';

void main() {
  testWidgets(
    'comparison shows a visible stale warning while keeping both scores and source dates',
    (WidgetTester tester) async {
      final Object identity = Object();
      final AnalysisReturnContext a = comparisonContext(
        'Mentari',
        LocationRole.locationA,
        identity,
      );
      final AnalysisReturnContext b = comparisonContext(
        'Subang',
        LocationRole.locationB,
        identity,
      );
      final PendingComparisonTransportation provider =
          PendingComparisonTransportation();
      await tester.pumpWidget(
        MaterialApp(
          home: PublicTransportationComparisonPage(
            transportation: provider,
            a: a,
            b: b,
          ),
        ),
      );
      provider.pending.complete(
        TransitComparable(
          comparisonSnapshot(a, 68, stale: true),
          comparisonSnapshot(b, 74),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Data may be outdated; the coverage reading remains available.',
        ),
        findsOneWidget,
      );
      expect(find.text('68'), findsOneWidget);
    },
  );

  testWidgets(
    'refresh failure preserves the previous pair, canonical publication and readable recovery',
    (WidgetTester tester) async {
      final Object identity = Object();
      final AnalysisReturnContext a = comparisonContext(
        'Mentari',
        LocationRole.locationA,
        identity,
      );
      final AnalysisReturnContext b = comparisonContext(
        'Subang',
        LocationRole.locationB,
        identity,
      );
      final SequenceComparisonTransportation provider =
          SequenceComparisonTransportation(
            TransitComparable(
              comparisonSnapshot(a, 68),
              comparisonSnapshot(b, 74),
            ),
          );
      final RecordingTransitShell shell = RecordingTransitShell();
      await tester.pumpWidget(
        MaterialApp(
          home: PublicTransportationComparisonPage(
            transportation: provider,
            a: a,
            b: b,
            applicationShell: shell,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        (shell.contributions.single
                as PublicTransportationComparisonContribution)
            .a,
        same(a),
      );
      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();
      expect(find.text('68'), findsOneWidget);
      expect(find.text('74'), findsOneWidget);
      expect(
        find.text('Refresh failed. Previous results remain visible.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(
        (shell.intents.single as ReturnToMapIntent).returnContext,
        same(a),
      );
    },
  );

  testWidgets(
    'comparison presents both canonical scores using one compare request without choosing a winner',
    (WidgetTester tester) async {
      final PendingComparisonTransportation transportation =
          PendingComparisonTransportation();
      final Object identity = Object();
      final AnalysisReturnContext a = comparisonContext(
        'Mentari',
        LocationRole.locationA,
        identity,
      );
      final AnalysisReturnContext b = comparisonContext(
        'Subang',
        LocationRole.locationB,
        identity,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PublicTransportationComparisonPage(
            transportation: transportation,
            a: a,
            b: b,
          ),
        ),
      );
      transportation.pending.complete(
        TransitComparable(comparisonSnapshot(a, 68), comparisonSnapshot(b, 74)),
      );
      await tester.pumpAndSettle();
      expect(transportation.calls, 1);
      expect(transportation.request!.a.location, same(a.location));
      expect(transportation.request!.b.analysisDate, b.analysisDate);
      expect(find.text('68'), findsOneWidget);
      expect(find.text('74'), findsOneWidget);
      expect(find.text('Comparable coverage readings'), findsOneWidget);
      expect(find.textContaining('winner'), findsNothing);
      await tester.tap(find.byTooltip('Swap display order'));
      await tester.pumpAndSettle();
      expect(transportation.calls, 1);
      expect(
        tester.getTopLeft(find.text('Subang')).dy,
        lessThan(tester.getTopLeft(find.text('Mentari')).dy),
      );
    },
  );
}

AnalysisReturnContext comparisonContext(
  String id,
  LocationRole role,
  Object identity,
) {
  return AnalysisReturnContext(
    location: ValidLocationReference(
      locationId: id,
      displayName: id,
      point: GeographicPoint(
        latitude: role == LocationRole.locationA ? 3.0738 : 3.0838,
        longitude: 101.6077,
      ),
    ),
    role: role,
    analysisDate: DateTime(2026, 9, 17),
    originalRequestIdentity: identity,
  );
}

TransitSnapshot comparisonSnapshot(
  AnalysisReturnContext context,
  int score, {
  bool stale = false,
}) {
  return TransitSnapshot(
    location: context.location,
    analysisDate: context.analysisDate,
    radiusMeters: 1500,
    stations: <TransitStation>[
      TransitStation(
        feedId: 'gtfs_static_ktmb',
        stopId: 'station',
        name: 'Mentari BRT',
        point: GeographicPoint(
          latitude: context.location.point.latitude + 180 / 111195,
          longitude: context.location.point.longitude,
        ),
        type: TransitStationType.bus,
        distanceMeters: 180,
      ),
    ],
    uniqueStopCount: 1,
    nearestDistanceMeters: 180,
    uniqueRouteCount: 1,
    serviceOutcome: TransitServiceOutcome.served,
    score: TransitScore(score),
    feeds: <FeedStatus>[
      for (final List<String> feed in expectedTestFeeds)
        FeedStatus(
          feedId: feed[0],
          sourceId: feed[0],
          sourceUrl: Uri.parse(feed[1]),
          capturedAt: DateTime.utc(2026, 8, 1),
          availability: stale && feed[0] == 'gtfs_static_ktmb'
              ? FeedAvailability.stale
              : FeedAvailability.usable,
          reason: null,
        ),
    ],
    provenance: TransitProvenance(
      snapshotId: 'test-snapshot',
      referenceGridVersion: 'test-grid',
      generatedAt: DateTime.utc(2026, 9, 17),
    ),
  );
}

final class PendingComparisonTransportation implements PublicTransportation {
  final Completer<TransitComparisonOutcome> pending =
      Completer<TransitComparisonOutcome>();
  int calls = 0;
  TransitComparisonRequest? request;
  @override
  Future<TransitComparisonOutcome> compare(TransitComparisonRequest request) {
    calls++;
    this.request = request;
    return pending.future;
  }

  @override
  Future<TransitLoadOutcome> load(TransitRequest request) {
    throw StateError(
      'The comparison page must consume canonical compare facts',
    );
  }
}

final class SequenceComparisonTransportation implements PublicTransportation {
  final TransitComparisonOutcome first;
  int calls = 0;
  SequenceComparisonTransportation(TransitComparisonOutcome first)
    : first = first;
  @override
  Future<TransitComparisonOutcome> compare(
    TransitComparisonRequest request,
  ) async {
    if (++calls == 1) {
      return first;
    }
    throw StateError('Controlled external failure');
  }

  @override
  Future<TransitLoadOutcome> load(TransitRequest request) {
    throw StateError('Unexpected load');
  }
}
