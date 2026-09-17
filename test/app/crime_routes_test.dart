import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/features/crime_security/crime_security.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/l10n/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../features/crime_security/crime_security_test.dart'
    show sunway, ReaderFixture, GeoFixture;
import 'analysis_routes_test.dart'
    show RecordingFacilities, RecordingTransportation;

void main() {
  sqfliteFfiInit();
  for (final bool comparison in <bool>[false, true]) {
    testWidgets(
      'ordinary crime ${comparison ? 'A/B' : 'single'} route preserves inputs and map-return callback',
      (WidgetTester tester) async {
        final Database db = await databaseFactoryFfiNoIsolate.openDatabase(
          inMemoryDatabasePath,
        );
        final CrimeSecurity crime = createCrimeSecurity(
          geographicContext: GeoFixture(),
          reader: ReaderFixture(),
          database: db,
        );
        const ValidLocationReference b = ValidLocationReference(
          locationId: 'b',
          point: GeographicPoint(latitude: 1.5, longitude: 103.7),
          displayName: 'Johor',
        );
        ValidLocationReference? returned;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LocationAnalysisMenu(
              location: sunway,
              locationB: comparison ? b : null,
              facilities: RecordingFacilities(),
              transportation: RecordingTransportation(),
              crime: crime,
              onShowMap: (ValidLocationReference location) {
                returned = location;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Not implemented yet'), findsNWidgets(3));
        await tester.tap(find.text('Crime and security'));
        await tester.pumpAndSettle();
        expect(find.byType(CrimeSecurityPage), findsOneWidget);
        if (comparison) {
          await tester.scrollUntilVisible(find.text('B · Johor'), 250);
          expect(find.text('B · Johor'), findsOneWidget);
        } else {
          await tester.tap(find.byTooltip('Main map'));
          expect(returned, sunway);
        }
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(LocationAnalysisMenu), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await db.close();
      },
    );
  }
}
