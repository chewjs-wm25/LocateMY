import 'dart:convert';

import 'package:locatemy/features/map_location/map_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/property_inspection/property_inspection.dart';

import 'package:locatemy/l10n/app_localizations.dart';

import 'property_service_test.dart'
    show MemoryPropertyStore, UnavailablePropertyRisk;

void main() {
  testWidgets(
    'empty cloud portfolio shows add and recycle bin without fabricated records',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PropertyInspectionPortfolioPage(
            service: PropertyInspectionService(
              store: MemoryPropertyStore(),
              risk: UnavailablePropertyRisk(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No property inspections yet.'), findsOneWidget);
      expect(find.text('New inspection'), findsOneWidget);
      expect(find.text('Recycle bin'), findsOneWidget);
    },
  );
  testWidgets(
    'photo reservation failure retains selected bytes for visible current-page retry',
    (WidgetTester tester) async {
      final ReservationFailStore store = ReservationFailStore();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PropertyInspectionFormPage(
            service: PropertyInspectionService(
              store: store,
              risk: UnavailablePropertyRisk(),
            ),
            photoPicker: OnePhotoPicker(),
            location: const ValidLocationReference(
              locationId: 'a',
              point: GeographicPoint(latitude: 3, longitude: 101),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).at(0), 'House');
      await tester.enterText(find.byType(TextField).at(1), '1');
      await tester.enterText(find.byType(TextField).at(2), 'Street');
      await tester.scrollUntilVisible(
        find.text('Choose from gallery'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save inspection'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save inspection'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Retry selected photos'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Retry selected photos'), findsOneWidget);
    },
  );
}

class ReservationFailStore extends MemoryPropertyStore {
  @override
  Future<PropertyPhoto> reservePhoto(String inspectionId) async {
    throw const PropertyFailure('network');
  }
}

class OnePhotoPicker implements PropertyPhotoPicker {
  @override
  Future<PropertyPickedPhoto?> pick(PropertyPhotoSource source) async {
    return PropertyPickedPhoto(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aHtcAAAAASUVORK5CYII=',
      ),
    );
  }
}
