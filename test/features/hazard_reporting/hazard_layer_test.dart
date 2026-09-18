

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/hazard_reporting/hazard_reporting.dart';
import 'package:locatemy/features/map_location/map_location.dart';

void main() {
  test(
    'selected location bounds the query and excludes corners beyond 2 km',
    () async {
      final RadiusReports reports = RadiusReports();
      final LayerHost host = LayerHost();
      final HazardMapLayer layer = HazardMapLayer(reports, host);
      await layer.refresh(
        const HazardPageRequest(
          viewportVersion: 'radius',
          mapCenter: GeographicPoint(latitude: 3.5, longitude: 101.5),
          viewport: HazardViewport(
            GeographicPoint(latitude: 0, longitude: 99),
            GeographicPoint(latitude: 8, longitude: 120),
          ),
        ),
      );
      expect(
        reports.request!.viewport.southWest.latitude,
        closeTo(3.482, 0.001),
      );
      expect(
        reports.request!.viewport.northEast.longitude,
        closeTo(101.518, 0.001),
      );
      expect(
        layer.reports.map((HazardReport report) {
          return report.id.value;
        }),
        ['inside'],
      );
      expect(host.published.last.items.single.stableItemId, 'inside');
      layer.clear();
      expect(layer.reports, isEmpty);
      expect(host.published.last.visibility, MapLayerVisibility.hidden);
      layer.dispose();
    },
  );
  testWidgets(
    'opening a map without a selected location does not load hazards',
    (WidgetTester tester) async {
      final PagingReports reports = PagingReports();
      final ValueNotifier<HazardPageRequest?> viewport = ValueNotifier(null);
      final ValueNotifier<int> revision = ValueNotifier(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HazardMapPanel(
              hazards: reports,
              host: LayerHost(),
              viewport: viewport,
              revision: revision,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(reports.cursors, isEmpty);
      await tester.pumpWidget(const SizedBox());
      viewport.dispose();
      revision.dispose();
    },
  );
  testWidgets('all five hazard types reach the map with category metadata', (
    WidgetTester tester,
  ) async {
    final PagingReports reports = PagingReports();
    reports.allTypes = true;
    final LayerHost host = LayerHost();
    final ValueNotifier<HazardPageRequest?> current = ValueNotifier(
      const HazardPageRequest(
        viewportVersion: 'categories',
        viewport: HazardViewport(
          GeographicPoint(latitude: 3, longitude: 101),
          GeographicPoint(latitude: 4, longitude: 102),
        ),
      ),
    );
    final ValueNotifier<int> revision = ValueNotifier(0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HazardMapPanel(
            hazards: reports,
            host: host,
            viewport: current,
            revision: revision,
            child: const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      host.published.single.items.map((MapLayerItem item) {
        return item.markerKind;
      }).toSet(),
      <MapMarkerKind>{
        MapMarkerKind.hazardFlood,
        MapMarkerKind.hazardCrime,
        MapMarkerKind.hazardTraffic,
        MapMarkerKind.hazardInfrastructure,
        MapMarkerKind.hazardOther,
      },
    );
    for (final MapLayerItem item in host.published.single.items) {
      expect((item.intent as ProviderDefinedIntent).action, 'detail');
      expect(
        (item.intent as ProviderDefinedIntent).stableItemId,
        item.stableItemId,
      );
    }
    await tester.pumpWidget(const SizedBox());
    current.dispose();
    revision.dispose();
  });
  testWidgets('an expired cursor retries from a fresh first page', (
    WidgetTester tester,
  ) async {
    final PagingReports reports = PagingReports();
    reports.expiredCursor = true;
    final LayerHost host = LayerHost();
    final ValueNotifier<HazardPageRequest?> current = ValueNotifier(
      const HazardPageRequest(
        viewportVersion: 'page',
        viewport: HazardViewport(
          GeographicPoint(latitude: 3, longitude: 101),
          GeographicPoint(latitude: 4, longitude: 102),
        ),
      ),
    );
    final ValueNotifier<int> revision = ValueNotifier(0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HazardMapPanel(
            hazards: reports,
            host: host,
            viewport: current,
            revision: revision,
            child: const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load more hazards'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(reports.cursors, [null, 'one', null]);
    expect(find.text('1 hazards loaded'), findsNothing);
    expect(find.byTooltip('Refresh hazards'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    current.dispose();
    revision.dispose();
  });

  testWidgets(
    'stale map contribution preserves reports without an account failure',
    (WidgetTester tester) async {
      final PagingReports reports = PagingReports();
      final LayerHost host = LayerHost();
      host.rejection = MapLayerFailure.staleViewport;
      final ValueNotifier<HazardPageRequest?> current = ValueNotifier(
        const HazardPageRequest(
          viewportVersion: 'page',
          viewport: HazardViewport(
            GeographicPoint(latitude: 3, longitude: 101),
            GeographicPoint(latitude: 4, longitude: 102),
          ),
        ),
      );
      final ValueNotifier<int> revision = ValueNotifier(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HazardMapPanel(
              hazards: reports,
              host: host,
              viewport: current,
              revision: revision,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 hazards loaded'), findsNothing);
      expect(find.text('Retry'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      current.dispose();
      revision.dispose();
    },
  );

  testWidgets(
    'partial pages and later failure retain the successful map items',
    (WidgetTester tester) async {
      final PagingReports reports = PagingReports();
      final LayerHost host = LayerHost();
      final ValueNotifier<HazardPageRequest?> current = ValueNotifier(
        const HazardPageRequest(
          viewportVersion: 'page',
          viewport: HazardViewport(
            GeographicPoint(latitude: 3, longitude: 101),
            GeographicPoint(latitude: 4, longitude: 102),
          ),
        ),
      );
      final ValueNotifier<int> revision = ValueNotifier(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HazardMapPanel(
              hazards: reports,
              host: host,
              viewport: current,
              revision: revision,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(host.published.single.items.length, 1);
      await tester.tap(find.text('Load more hazards'));
      await tester.pumpAndSettle();
      expect(host.published.last.items.length, 2);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Load more hazards'));
      await tester.pumpAndSettle();
      expect(host.published.length, 2);
      expect(host.published.last.items.length, 2);
      expect(reports.cursors, [null, 'one', 'two']);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(reports.cursors, [null, 'one', 'two', 'two']);
      expect(host.published.last.items.length, 3);
      revision.value++;
      await tester.pumpAndSettle();
      expect(reports.cursors.last, isNull);
      expect(host.published.last.items.length, 1);
      await tester.pumpWidget(const SizedBox());
      current.dispose();
      revision.dispose();
    },
  );
  testWidgets('an older viewport never contributes over the newest map layer', (
    WidgetTester tester,
  ) async {
    final Completer<HazardPageOutcome> old = Completer<HazardPageOutcome>();
    final LayerReports reports = LayerReports(old.future);
    final LayerHost host = LayerHost();
    final ValueNotifier<HazardPageRequest?> current = ValueNotifier(null);
    final ValueNotifier<int> revision = ValueNotifier(0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HazardMapPanel(
            hazards: reports,
            host: host,
            viewport: current,
            revision: revision,
            child: const SizedBox(),
          ),
        ),
      ),
    );
    const HazardViewport viewport = HazardViewport(
      GeographicPoint(latitude: 3, longitude: 101),
      GeographicPoint(latitude: 4, longitude: 102),
    );
    current.value = const HazardPageRequest(
      viewportVersion: 'old',
      viewport: viewport,
    );
    await tester.pump();
    current.value = const HazardPageRequest(
      viewportVersion: 'new',
      viewport: viewport,
    );
    await tester.pump();
    old.complete(const HazardPageAvailable(HazardPage([], null, 'old')));
    await tester.pump();
    expect(
      host.published.map((MapLayerContribution item) {
        return item.viewportVersion;
      }),
      ['new'],
    );
    await tester.pumpWidget(const SizedBox());
    current.dispose();
    revision.dispose();
  });
}

final class LayerReports implements HazardReporting {
  final Future<HazardPageOutcome> old;
  LayerReports(Future<HazardPageOutcome> old) : old = old;
  @override
  Future<HazardPageOutcome> loadPublic(HazardPageRequest request) async {
    if (request.viewportVersion == 'old') {
      return old;
    }
    return HazardPageAvailable(
      HazardPage(const [], null, request.viewportVersion),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

final class LayerHost implements MapLayerHost {
  MapLayerFailure? rejection;
  final List<MapLayerContribution> published = [];
  @override
  Future<MapLayerContributionOutcome> contribute(
    MapLayerContribution contribution,
  ) async {
    published.add(contribution);
    if (rejection != null) {
      return MapLayerRejected(failure: rejection!);
    }
    return const MapLayerAccepted();
  }

  @override
  Future<MapLayerIntentOutcome> requestLongPress(GeographicPoint point) {
    throw UnimplementedError();
  }
}

final class PagingReports implements HazardReporting {
  bool expiredCursor = false;
  bool allTypes = false;
  final List<String?> cursors = [];
  HazardReport report(String id, {HazardType type = HazardType.flood}) {
    return HazardReport(
      id: HazardReportId(id),
      type: type,
      title: id,
      location: const GeographicPoint(latitude: 3.5, longitude: 101.5),
      status: HazardAuthorStatus.pending,
      reportedAt: DateTime.utc(2026),
      author: HazardAuthorView.other,
      vote: const HazardVoteState(HazardVote.none, 0, 0),
    );
  }

  @override
  Future<HazardPageOutcome> loadPublic(HazardPageRequest request) async {
    cursors.add(request.cursor);
    if (allTypes) {
      final List<HazardReport> reports = <HazardReport>[];
      for (final HazardType type in HazardType.values) {
        reports.add(report(type.name, type: type));
      }
      return HazardPageAvailable(
        HazardPage(reports, null, request.viewportVersion),
      );
    }
    if (request.cursor == null) {
      return HazardPageAvailable(
        HazardPage([report('one')], 'one', request.viewportVersion),
      );
    }
    if (request.cursor == 'one') {
      if (expiredCursor) {
        return const HazardPageUnavailable(HazardReadFailure.invalidViewport);
      }
      return HazardPagePartial(
        HazardPage([report('two')], 'two', request.viewportVersion),
        HazardReadFailure.retryableUnavailable,
      );
    }
    if (cursors.where((String? cursor) {
          return cursor == 'two';
        }).length ==
        1) {
      return const HazardPageUnavailable(
        HazardReadFailure.retryableUnavailable,
      );
    }
    return HazardPageAvailable(
      HazardPage([report('three')], null, request.viewportVersion),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

final class RadiusReports implements HazardReporting {
  HazardPageRequest? request;
  @override
  Future<HazardPageOutcome> loadPublic(HazardPageRequest request) async {
    this.request = request;
    final List<HazardReport> reports = <HazardReport>[];
    for (final String id in <String>['inside', 'corner', 'far']) {
      GeographicPoint point = const GeographicPoint(
        latitude: 3.51,
        longitude: 101.5,
      );
      if (id == 'corner') {
        point = const GeographicPoint(latitude: 3.515, longitude: 101.515);
      } else if (id == 'far') {
        point = const GeographicPoint(latitude: 3.53, longitude: 101.5);
      }
      reports.add(
        HazardReport(
          id: HazardReportId(id),
          type: HazardType.flood,
          title: id,
          location: point,
          status: HazardAuthorStatus.pending,
          reportedAt: DateTime.utc(2026),
          author: HazardAuthorView.other,
          vote: const HazardVoteState(HazardVote.none, 0, 0),
        ),
      );
    }
    return HazardPageAvailable(
      HazardPage(reports, null, request.viewportVersion),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
