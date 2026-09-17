import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/l10n/app_localizations.dart';
import 'package:locatemy/features/hazard_reporting/hazard_reporting.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import 'hazard_reporting_service_test.dart' show RecordingHazardStore;

void main() {
  testWidgets(
    'successful vote remains authoritative when detail refresh fails',
    (WidgetTester tester) async {
      final PageReports reports = PageReports();
      await tester.pumpWidget(
        host(
          HazardDetailLoader(
            hazards: reports,
            id: reports.report.id,
            onChanged: () {},
            onDeleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      reports.failDetail = true;
      await tester.scrollUntilVisible(
        find.text('Support  0'),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Support  0'));
      await tester.pumpAndSettle();
      expect(find.text('Support  1'), findsOneWidget);
    },
  );

  testWidgets(
    'Penpot composer starts without a type and retains input on rejected submission',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: const [Locale('zh'), Locale('en')],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: HazardComposerPage(
              hazards: createHazardReporting(
                store: RecordingHazardStore(),
                currentAccountId: () {
                  return 'test';
                },
              ),
              request: (HazardType type, String title, String? description) {
                return HazardCreateRequest(
                  location: const ValidLocationReference(
                    locationId: 'map',
                    point: GeographicPoint(
                      latitude: 3.0738,
                      longitude: 101.6072,
                    ),
                  ),
                  type: type,
                  title: title,
                  description: description,
                );
              },
            ),
          ),
        ),
      );
      expect(find.text('隐患类型 *'), findsOneWidget);
      expect(
        tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).where((
          ChoiceChip chip,
        ) {
          return chip.selected;
        }),
        isEmpty,
      );
      await tester.enterText(find.byType(TextField).first, '人行道积水');
      await tester.scrollUntilVisible(
        find.text('发布隐患报告'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('发布隐患报告'));
      await tester.pump();
      expect(find.text('请选择隐患类型。'), findsOneWidget);
      expect(find.text('人行道积水'), findsOneWidget);
    },
  );
  testWidgets(
    'failed report refresh retains the last successful list and can retry',
    (WidgetTester tester) async {
      final PageReports reports = PageReports();
      await tester.pumpWidget(
        host(
          MyHazardsPage(
            hazards: reports,
            request: mineRequest,
            onOpen: (HazardReport report) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Water on sidewalk'), findsOneWidget);
      reports.offline = true;
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(find.text('Water on sidewalk'), findsOneWidget);
      expect(find.text('No reports yet.'), findsNothing);
      expect(
        find.textContaining('Previous content is retained'),
        findsOneWidget,
      );
      reports.offline = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Previous content is retained'), findsNothing);
    },
  );

  testWidgets(
    'delete cancellation preserves a report and confirmation removes it',
    (WidgetTester tester) async {
      final PageReports reports = PageReports();
      bool deleted = false;
      await tester.pumpWidget(
        host(
          HazardDetailLoader(
            hazards: reports,
            id: reports.report.id,
            onChanged: () {},
            onDeleted: () {
              deleted = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Delete'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        await reports.loadDetail(reports.report.id),
        isA<HazardDetailAvailable>(),
      );
      expect(deleted, false);
      await tester.ensureVisible(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(
        await reports.loadDetail(reports.report.id),
        isA<HazardDetailUnavailable>(),
      );
      expect(deleted, true);
    },
  );

  testWidgets(
    'selected vote can be withdrawn and resolved status can return to pending',
    (WidgetTester tester) async {
      final PageReports reports = PageReports();
      await tester.pumpWidget(
        host(
          HazardDetailLoader(
            hazards: reports,
            id: reports.report.id,
            onChanged: () {},
            onDeleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Support  0'),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Support  0'));
      await tester.pumpAndSettle();
      expect(find.text('Support  1'), findsOneWidget);
      await tester.tap(find.text('Withdraw vote'));
      await tester.pumpAndSettle();
      expect(find.text('Support  0'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Mark resolved'),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Mark resolved'));
      await tester.pumpAndSettle();
      expect(find.text('Resolved'), findsOneWidget);
      await tester.tap(find.text('Mark pending'));
      await tester.pumpAndSettle();
      expect(find.text('Pending'), findsOneWidget);
    },
  );

  for (final String locale in ['en', 'zh']) {
    testWidgets(
      '360dp and 200 percent text support all hazard pages in $locale',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final PageReports reports = PageReports();
        final List<Widget> pages = [
          HazardComposerPage(
            hazards: reports,
            location: const ValidLocationReference(
              locationId: 'map',
              point: GeographicPoint(latitude: 3.0738, longitude: 101.6072),
            ),
            request: (HazardType type, String title, String? description) {
              return HazardCreateRequest(
                location: const ValidLocationReference(
                  locationId: 'map',
                  point: GeographicPoint(latitude: 3.0738, longitude: 101.6072),
                ),
                type: type,
                title: title,
                description: description,
              );
            },
          ),
          MyHazardsPage(
            reports: [reports.report],
            onOpen: (HazardReport report) {},
          ),
          HazardDetailPage(
            report: reports.report,
            onVote: (HazardVote vote) async {},
            onDelete: () async {},
            onResolve: () async {},
          ),
        ];
        for (final Widget page in pages) {
          await tester.pumpWidget(host(page, locale: locale, large: true));
          await tester.pumpAndSettle();
          await tester.drag(find.byType(ListView).last, const Offset(0, -600));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}

const HazardPageRequest mineRequest = HazardPageRequest(
  viewportVersion: 'mine',
  viewport: HazardViewport(
    GeographicPoint(latitude: -90, longitude: -180),
    GeographicPoint(latitude: 90, longitude: 180),
  ),
);
Widget host(Widget child, {String locale = 'en', bool large = false}) {
  return MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(large ? 2 : 1)),
        child: child,
      ),
    ),
  );
}

final class PageReports implements HazardReporting {
  bool offline = false;
  bool failDetail = false;
  bool removed = false;
  HazardAuthorStatus status = HazardAuthorStatus.pending;
  HazardVote selected = HazardVote.none;
  HazardReport get report {
    return HazardReport(
      id: const HazardReportId('00000000-0000-0000-0000-000000000001'),
      type: HazardType.flood,
      title: 'Water on sidewalk',
      description: 'Water remains after rain.',
      location: const GeographicPoint(latitude: 3.0738, longitude: 101.6072),
      status: status,
      reportedAt: DateTime.utc(2026, 9, 17),
      author: HazardAuthorView.mine,
      vote: HazardVoteState(
        selected,
        selected == HazardVote.up ? 1 : 0,
        selected == HazardVote.down ? 1 : 0,
      ),
    );
  }

  @override
  Future<MyHazardsOutcome> loadMine(HazardPageRequest request) async {
    if (offline) {
      return const MyHazardsUnavailable(HazardReadFailure.retryableUnavailable);
    }
    return MyHazardsAvailable(
      HazardPage(removed ? [] : [report], null, request.viewportVersion),
    );
  }

  @override
  Future<HazardDetailOutcome> loadDetail(HazardReportId id) async {
    if (failDetail) {
      return const HazardDetailUnavailable(
        HazardReadFailure.retryableUnavailable,
      );
    }
    if (removed) {
      return const HazardDetailUnavailable(HazardReadFailure.notFound);
    }
    return HazardDetailAvailable(report);
  }

  @override
  Future<HazardDeleteOutcome> deleteMine(HazardReportId id) async {
    removed = true;
    return HazardDeleted(id);
  }

  @override
  Future<HazardVoteOutcome> vote(HazardVoteRequest request) async {
    selected = request.vote;
    return HazardVoteChanged(request.id, report.vote);
  }

  @override
  Future<HazardStatusOutcome> changeMyStatus(
    HazardStatusRequest request,
  ) async {
    status = request.status;
    return HazardStatusChanged(report);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
