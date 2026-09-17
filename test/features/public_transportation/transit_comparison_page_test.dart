// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import 'package:locatemy/features/public_transportation/public_transportation.dart';

const List<List<String>> expectedTestFeeds = <List<String>>[
  <String>['gtfs_static_ktmb', 'https://example.com/ktmb'],
];

void main() {
  testWidgets(
    'refresh failure preserves the previous pair and readable recovery',
    (WidgetTester tester) async {
      final AnalysisReturnContext a = comparisonContext(
        'Mentari',
        LocationRole.locationA,
      );
      final AnalysisReturnContext b = comparisonContext(
        'Subang',
        LocationRole.locationB,
      );
      final SequenceComparisonTransportation provider =
          SequenceComparisonTransportation(
            TransitComparable(
              comparisonSnapshot(a, 68),
              comparisonSnapshot(b, 74),
            ),
          );
      await tester.pumpWidget(
        MaterialApp(
          home: PublicTransportationComparisonPage(
            transportation: provider,
            a: a,
            b: b,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();
      expect(find.text('68'), findsOneWidget);
      expect(find.text('74'), findsOneWidget);
      expect(
        find.text('Refresh failed. Previous results remain visible.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'comparison presents both canonical scores using one compare request without choosing a winner',
    (WidgetTester tester) async {
      final PendingComparisonTransportation transportation =
          PendingComparisonTransportation();
      final AnalysisReturnContext a = comparisonContext(
        'Mentari',
        LocationRole.locationA,
      );
      final AnalysisReturnContext b = comparisonContext(
        'Subang',
        LocationRole.locationB,
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
      expect(find.textContaining('Snapshot'), findsNothing);
      expect(find.textContaining('Reference grid'), findsNothing);
      expect(find.textContaining('https://'), findsNothing);
      expect(find.text('Sources'), findsNothing);
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

AnalysisReturnContext comparisonContext(String id, LocationRole role) {
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
  );
}

TransitSnapshot comparisonSnapshot(AnalysisReturnContext context, int score) {
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
          availability: FeedAvailability.usable,
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
