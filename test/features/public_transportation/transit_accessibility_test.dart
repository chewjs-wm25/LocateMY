import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/public_transportation/public_transportation.dart';
import 'package:locatemy/l10n/app_localizations.dart';

import 'public_transportation_page_test.dart'
    show PendingReader, stationPayload, RecordingTransitShell;
import 'transit_comparison_page_test.dart'
    show comparisonContext, comparisonSnapshot, PendingComparisonTransportation;

void main() {
  for (final String language in <String>['en', 'zh']) {
    testWidgets(
      '$language at 200% preserves all 35 markers, 30 nearest rows and textual selection',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() {
          return tester.binding.setSurfaceSize(null);
        });
        final SemanticsHandle semantics = tester.ensureSemantics();
        final PendingReader reader = PendingReader();
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (BuildContext context, Widget? child) {
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              );
            },
            home: PublicTransportationPage(
              transportation: createPublicTransportation(reader),
              location: const ValidLocationReference(
                locationId: 'many',
                displayName: 'Sunway Mentari · A long location name',
                point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
              ),
              analysisDate: DateTime(2026, 9, 17),
            ),
          ),
        );
        final Map<String, Object?> payload = stationPayload('first');
        payload['unique_stop_count'] = 35;
        payload['nearest_distance_m'] = 100;
        payload['stations'] = List<Map<String, Object?>>.generate(35, (
          int index,
        ) {
          final int distance = 100 + index * 10;
          return <String, Object?>{
            'feed_id': 'gtfs_static_ktmb',
            'stop_id': 'stop-$index',
            'name': 'Station $index · Bus',
            'latitude': 3.0738 + distance / 111195,
            'longitude': 101.6077,
            'station_type': 'bus',
            'distance_m': distance,
          };
        });
        reader.pending['many']!.complete(payload);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(
            const ValueKey<String>('transit-marker-gtfs_static_ktmb:stop-34'),
          ),
          120,
        );
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate((Widget widget) {
            return widget is IconButton &&
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'transit-marker-',
                );
          }),
          findsNWidgets(35),
        );
        await tester.tap(
          find.byKey(
            const ValueKey<String>('transit-marker-gtfs_static_ktmb:stop-34'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining(language == 'zh' ? '已选择：' : 'Selected:'),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.byKey(
            const ValueKey<String>('transit-station-gtfs_static_ktmb:stop-29'),
          ),
          200,
        );
        expect(
          find.byKey(
            const ValueKey<String>('transit-station-gtfs_static_ktmb:stop-30'),
          ),
          findsNothing,
        );
        await tester.scrollUntilVisible(find.textContaining('test-grid'), 200);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        semantics.dispose();
      },
    );
  }
  testWidgets(
    'late comparison after date/context replacement never publishes the old pair',
    (WidgetTester tester) async {
      final RecordingTransitShell shell = RecordingTransitShell();
      final PendingComparisonTransportation old =
          PendingComparisonTransportation();
      final PendingComparisonTransportation current =
          PendingComparisonTransportation();
      final Object oldIdentity = Object();
      final Object currentIdentity = Object();
      final AnalysisReturnContext oldA = comparisonContext(
        'old-A',
        LocationRole.locationA,
        oldIdentity,
      );
      final AnalysisReturnContext oldB = comparisonContext(
        'old-B',
        LocationRole.locationB,
        oldIdentity,
      );
      final AnalysisReturnContext a = comparisonContext(
        'current-A',
        LocationRole.locationA,
        currentIdentity,
      );
      final AnalysisReturnContext b = comparisonContext(
        'current-B',
        LocationRole.locationB,
        currentIdentity,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PublicTransportationComparisonPage(
            transportation: old,
            a: oldA,
            b: oldB,
            applicationShell: shell,
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PublicTransportationComparisonPage(
            transportation: current,
            a: a,
            b: b,
            applicationShell: shell,
          ),
        ),
      );
      current.pending.complete(
        TransitComparable(comparisonSnapshot(a, 68), comparisonSnapshot(b, 74)),
      );
      await tester.pumpAndSettle();
      old.pending.complete(
        TransitComparable(
          comparisonSnapshot(oldA, 10),
          comparisonSnapshot(oldB, 20),
        ),
      );
      await tester.pumpAndSettle();
      expect(shell.contributions, hasLength(1));
      expect(
        (shell.contributions.single
                as PublicTransportationComparisonContribution)
            .a,
        same(a),
      );
      expect(find.text('10'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
