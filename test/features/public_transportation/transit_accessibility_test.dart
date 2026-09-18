import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/public_transportation/public_transportation.dart';
import 'package:locatemy/l10n/app_localizations.dart';

import 'public_transportation_page_test.dart'
    show PendingReader, stationPayload;

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
        expect(find.textContaining('test-grid'), findsNothing);
        expect(find.textContaining('https://'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        semantics.dispose();
      },
    );
  }
}
