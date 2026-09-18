import 'dart:async';
import 'dart:convert';

import 'package:locatemy/features/map_location/map_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/property_inspection/property_inspection.dart';

import 'package:locatemy/l10n/app_localizations.dart';

import 'property_service_test.dart'
    show MemoryPropertyStore, UnavailablePropertyRisk;

void main() {
  testWidgets('choosing a new location uses its place name', (
    WidgetTester tester,
  ) async {
    final ValidLocationReference selected = ValidLocationReference(
      locationId: 'new-location',
      point: const GeographicPoint(latitude: 3.14, longitude: 101.69),
      displayName: 'Taman Tasik Titiwangsa',
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PropertyInspectionFormPage(
          service: PropertyInspectionService(
            store: MemoryPropertyStore(),
            risk: UnavailablePropertyRisk(),
          ),
          location: const ValidLocationReference(
            locationId: 'initial-location',
            point: GeographicPoint(latitude: 3, longitude: 101),
          ),
          chooseLocation: (BuildContext context) async {
            return selected;
          },
        ),
      ),
    );

    expect(find.widgetWithText(TextField, 'Place name'), findsOneWidget);
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    final TextField field = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Place name'),
    );
    expect(field.controller!.text, 'Taman Tasik Titiwangsa');
  });

  testWidgets('saved notice translates when active locale changes', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<Locale> locale = ValueNotifier<Locale>(
      const Locale('en'),
    );
    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: locale,
        builder: (BuildContext context, Locale value, Widget? child) {
          return MaterialApp(
            locale: value,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PropertyInspectionFormPage(
              service: PropertyInspectionService(
                store: MemoryPropertyStore(),
                risk: UnavailablePropertyRisk(),
              ),
              location: const ValidLocationReference(
                locationId: 'a',
                point: GeographicPoint(latitude: 3, longitude: 101),
              ),
            ),
          );
        },
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), 'House');
    await tester.enterText(find.byType(TextField).at(1), '1');
    await tester.enterText(find.byType(TextField).at(2), 'Street');
    await tester.scrollUntilVisible(
      find.text('Save inspection'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save inspection'));
    await tester.pumpAndSettle();
    expect(find.text('Inspection saved online.'), findsOneWidget);
    locale.value = const Locale('zh');
    await tester.pumpAndSettle();
    expect(find.text('实勘已在线保存。'), findsOneWidget);
    expect(find.text('Inspection saved online.'), findsNothing);
  });

  testWidgets(
    'detail photo reservation failure retains current selection for retry',
    (WidgetTester tester) async {
      final PropertyInspectionService service = PropertyInspectionService(
        store: ReservationFailStore(),
        risk: UnavailablePropertyRisk(),
      );
      final PropertyInspectionRecord record = await service.save(
        const PropertyInspectionDraft(
          name: 'House',
          address: 'Street',
          price: 1,
          location: ValidLocationReference(
            locationId: 'a',
            point: GeographicPoint(latitude: 3, longitude: 101),
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PropertyInspectionDetailPage(
            service: service,
            id: record.id,
            photoPicker: OnePhotoPicker(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Choose from gallery'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Retry selected photos'),
        -300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 20,
      );
      expect(find.text('Retry selected photos'), findsOneWidget);
    },
  );

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
  testWidgets('disposed portfolio ignores late cloud response', (
    WidgetTester tester,
  ) async {
    final LateStore store = LateStore();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PropertyInspectionPortfolioPage(
          service: PropertyInspectionService(
            store: store,
            risk: UnavailablePropertyRisk(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    store.response.complete(<PropertyInspectionRecord>[]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final String language in <String>['en', 'zh']) {
    testWidgets(
      '$language online save failure retains input and 320dp 200% page remains usable',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 700));
        addTearDown(() {
          return tester.binding.setSurfaceSize(null);
        });
        final SaveFailStore store = SaveFailStore();
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
            home: PropertyInspectionFormPage(
              service: PropertyInspectionService(
                store: store,
                risk: UnavailablePropertyRisk(),
              ),
              location: const ValidLocationReference(
                locationId: 'a',
                point: GeographicPoint(latitude: 3, longitude: 101),
              ),
            ),
          ),
        );
        final List<String> labels = language == 'zh'
            ? <String>['房产名称', '价格（RM）', '地点名称']
            : <String>['Property name', 'Price (RM)', 'Place name'];
        final List<String> inputs = <String>['House', '1', 'Street'];
        for (int i = 0; i < 3; i++) {
          final Finder field = find.widgetWithText(TextField, labels[i]);
          await tester.scrollUntilVisible(
            field,
            250,
            scrollable: find.byType(Scrollable).first,
            maxScrolls: 30,
          );
          await tester.enterText(field, inputs[i]);
          await tester.pump();
        }
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        final String save = language == 'zh' ? '保存实勘' : 'Save inspection';
        await tester.scrollUntilVisible(
          find.text(save),
          300,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 30,
        );
        await tester.ensureVisible(find.text(save));
        await tester.pumpAndSettle();
        await tester.tap(find.text(save));
        await tester.pumpAndSettle();
        expect(
          find.text(
            language == 'zh' ? '在线操作失败，当前输入已保留，请重试。' : 'Online operation failed. Your current input is retained; retry.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        store.fail = false;
        await tester.scrollUntilVisible(
          find.text(save),
          250,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 30,
        );
        await tester.ensureVisible(find.text(save));
        await tester.pumpAndSettle();
        await tester.tap(find.text(save));
        await tester.pumpAndSettle();
        expect(
          find.text(language == 'zh' ? '实勘详情' : 'Inspection details'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
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

class LateStore extends MemoryPropertyStore {
  final Completer<List<PropertyInspectionRecord>> response =
      Completer<List<PropertyInspectionRecord>>();
  @override
  Future<List<PropertyInspectionRecord>> list({bool deleted = false}) {
    return response.future;
  }
}

class SaveFailStore extends MemoryPropertyStore {
  bool fail = true;
  @override
  Future<PropertyInspectionRecord> save(
    PropertyInspectionDraft draft,
    PropertyRiskSnapshot snapshot, {
    String? id,
  }) async {
    if (fail) {
      throw const PropertyFailure('network');
    }
    return super.save(draft, snapshot, id: id);
  }
}
