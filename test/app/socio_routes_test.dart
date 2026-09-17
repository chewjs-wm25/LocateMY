import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/features/socio_economic/socio_economic.dart';
import 'package:locatemy/l10n/app_localizations.dart';

import '../features/socio_economic/socio_economic_test.dart'
    show location, ReaderFixture, GeoFixture;
import 'analysis_routes_test.dart'
    show RecordingFacilities, RecordingTransportation;

void main() {
  for (final bool comparison in <bool>[false, true]) {
    testWidgets(
      'socio route preserves ${comparison ? 'A/B' : 'single'} location and returns to analysis menu',
      (WidgetTester tester) async {
        final SocioEconomic socio = createSocioEconomic(
          geographicContext: GeoFixture(),
          reader: ReaderFixture(),
        );
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LocationAnalysisMenu(
              location: location,
              locationB: comparison ? location : null,
              facilities: RecordingFacilities(),
              transportation: RecordingTransportation(),
              socio: socio,
            ),
          ),
        );
        await tester.ensureVisible(find.text('Socio-economic'));
        await tester.tap(find.text('Socio-economic'));
        await tester.pumpAndSettle();
        expect(find.byType(SocioEconomicPage), findsOneWidget);
        expect(find.text('RM 8,210'), findsWidgets);
        if (comparison) {
          await tester.scrollUntilVisible(
            find.text('A/B differences (B − A)'),
            400,
          );
          expect(find.text('A/B differences (B − A)'), findsOneWidget);
        }
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(LocationAnalysisMenu), findsOneWidget);
      },
    );
  }
}
